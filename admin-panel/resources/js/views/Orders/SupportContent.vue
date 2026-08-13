<template>
    <div class="support-content">
        <div class="chat-container">
            <!-- Chat Header -->
            <div class="chat-header" :style="{ backgroundColor: headerColor }">
                <div class="d-flex align-items-center">
                    <div class="chat-avatar">
                        <i :class="headerIcon"></i>
                    </div>
                    <div class="chat-header-info">
                        <h6 class="mb-0 text-white">{{ headerTitle }} Support</h6>
                        <small class="text-white-50">Order #{{ orderId }}</small>
                    </div>
                </div>
                <div class="chat-header-actions">
                    <span v-if="unreadCount > 0" class="badge bg-danger">{{ unreadCount }} unread</span>
                    <button class="btn btn-sm btn-light ms-2" @click="refreshMessages" :disabled="isLoading">
                        <i class="fas fa-sync-alt" :class="{ 'fa-spin': isLoading }"></i>
                    </button>
                </div>
            </div>

            <!-- Chat Messages Area -->
            <div class="chat-messages" ref="chatMessages">
                <!-- Loading State -->
                <div v-if="isLoading && messages.length === 0" class="text-center py-5">
                    <b-spinner variant="primary" label="Loading..."></b-spinner>
                    <p class="mt-2 text-muted">Loading messages...</p>
                </div>

                <!-- No Messages -->
                <div v-else-if="messages.length === 0" class="text-center py-5">
                    <div class="empty-chat-icon">
                        <i :class="headerIcon"></i>
                    </div>
                    <p class="mt-3 text-muted">No messages yet.</p>
                    <p class="text-muted small">Start a conversation with the {{ supportType }}.</p>
                </div>

                <!-- Messages List -->
                <div v-else class="messages-wrapper">
                    <div v-for="(message, index) in messages" :key="message.id || index"
                         class="message-item"
                         :class="getMessageClass(message)">
                        <div class="message-bubble">
                            <div class="message-sender" v-if="message.sender_type !== 'admin'">
                                {{ message.sender_name }}
                            </div>
                            <div class="message-content">{{ message.message }}</div>
                            <div class="message-meta">
                                <span class="message-time">{{ formatTime(message.timestamp) }}</span>
                                <span v-if="message.sender_type === 'admin'" class="message-status">
                                    <i class="fas" :class="message.read ? 'fa-check-double text-info' : 'fa-check'"></i>
                                </span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Chat Input Area -->
            <div class="chat-input-area">
                <div class="input-group">
                    <textarea
                        class="form-control"
                        v-model="newMessage"
                        placeholder="Type a message..."
                        rows="1"
                        @keydown.enter.exact.prevent="sendMessage"
                        @input="autoResize"
                        ref="messageInput"
                        :disabled="isSending"
                    ></textarea>
                    <button
                        class="btn btn-send"
                        :style="{ backgroundColor: headerColor }"
                        @click="sendMessage"
                        :disabled="!newMessage.trim() || isSending"
                    >
                        <i v-if="isSending" class="fas fa-spinner fa-spin"></i>
                        <i v-else class="fas fa-paper-plane"></i>
                    </button>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import axios from "axios";

export default {
    name: 'SupportContent',
    props: {
        orderId: {
            type: [String, Number],
            required: true
        },
        supportType: {
            type: String,
            required: true,
            validator: (value) => ['customer', 'seller', 'driver'].includes(value)
        }
    },
    data() {
        return {
            isLoading: false,
            isSending: false,
            messages: [],
            newMessage: '',
            unreadCount: 0,
            refreshInterval: null
        };
    },
    computed: {
        headerTitle() {
            const titles = {
                customer: 'Customer',
                seller: 'Seller',
                driver: 'Driver'
            };
            return titles[this.supportType] || 'Support';
        },
        headerIcon() {
            const icons = {
                customer: 'fas fa-user',
                seller: 'fas fa-store',
                driver: 'fas fa-motorcycle'
            };
            return icons[this.supportType] || 'fas fa-headset';
        },
        headerColor() {
            const colors = {
                customer: '#435971',
                seller: '#9AC444',
                driver: '#f0ad4e'
            };
            return colors[this.supportType] || '#435971';
        }
    },
    watch: {
        supportType: {
            immediate: true,
            handler() {
                this.fetchMessages();
            }
        },
        orderId: {
            handler() {
                this.fetchMessages();
            }
        }
    },
    mounted() {
        // Auto-refresh messages every 10 seconds
        this.refreshInterval = setInterval(() => {
            this.fetchMessages(true);
        }, 10000);
    },
    beforeDestroy() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }
    },
    methods: {
        fetchMessages(silent = false) {
            if (!silent) {
                this.isLoading = true;
            }
            this.messages = [];

            axios.get(this.$apiUrl + '/order-chat/messages', {
                params: {
                    order_id: this.orderId,
                    chat_type: this.supportType
                }
            }).then((response) => {
                this.isLoading = false;
                if (response.data.status === 1) {
                    this.messages = response.data.data || [];
                    this.scrollToBottom();
                    this.markUnreadAsRead();
                    this.updateUnreadCount();
                }
            }).catch((error) => {
                this.isLoading = false;
                console.error('Error fetching messages:', error);
            });
        },

        refreshMessages() {
            this.fetchMessages();
        },

        sendMessage() {
            if (!this.newMessage.trim() || this.isSending) {
                return;
            }

            this.isSending = true;

            axios.post(this.$apiUrl + '/order-chat/send', {
                order_id: this.orderId,
                chat_type: this.supportType,
                message: this.newMessage.trim()
            }).then((response) => {
                this.isSending = false;
                if (response.data.status === 1) {
                    // Add the new message to the list
                    this.messages.push(response.data.data);
                    this.newMessage = '';
                    this.scrollToBottom();
                    this.resetTextarea();
                } else {
                    this.showError(response.data.message || 'Failed to send message');
                }
            }).catch((error) => {
                this.isSending = false;
                console.error('Error sending message:', error);
                this.showError('Failed to send message. Please try again.');
            });
        },

        markUnreadAsRead() {
            // Find unread messages sent to admin
            const unreadIds = this.messages
                .filter(m => !m.read && m.recipient_type === 'admin')
                .map(m => m.id);

            if (unreadIds.length > 0) {
                axios.post(this.$apiUrl + '/order-chat/mark-read', {
                    order_id: this.orderId,
                    chat_type: this.supportType,
                    message_ids: unreadIds
                }).then(() => {
                    // Update local message read status
                    this.messages.forEach(m => {
                        if (unreadIds.includes(m.id)) {
                            m.read = true;
                        }
                    });
                }).catch((error) => {
                    console.error('Error marking messages as read:', error);
                });
            }
        },

        updateUnreadCount() {
            axios.get(this.$apiUrl + '/order-chat/unread-count', {
                params: {
                    order_id: this.orderId,
                    chat_type: this.supportType
                }
            }).then((response) => {
                if (response.data.status === 1) {
                    this.unreadCount = response.data.data.unread_count || 0;
                }
            }).catch((error) => {
                console.error('Error fetching unread count:', error);
            });
        },

        getMessageClass(message) {
            return {
                'message-sent': message.sender_type === 'admin',
                'message-received': message.sender_type !== 'admin'
            };
        },

        formatTime(timestamp) {
            if (!timestamp) return '';

            try {
                const date = new Date(timestamp);
                const now = new Date();
                const isToday = date.toDateString() === now.toDateString();

                if (isToday) {
                    return date.toLocaleTimeString('en-US', {
                        hour: '2-digit',
                        minute: '2-digit',
                        hour12: true
                    });
                } else {
                    return date.toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit',
                        hour12: true
                    });
                }
            } catch (e) {
                return timestamp;
            }
        },

        scrollToBottom() {
            this.$nextTick(() => {
                const container = this.$refs.chatMessages;
                if (container) {
                    container.scrollTop = container.scrollHeight;
                }
            });
        },

        autoResize(event) {
            const textarea = event.target;
            textarea.style.height = 'auto';
            textarea.style.height = Math.min(textarea.scrollHeight, 120) + 'px';
        },

        resetTextarea() {
            this.$nextTick(() => {
                const textarea = this.$refs.messageInput;
                if (textarea) {
                    textarea.style.height = 'auto';
                }
            });
        },

        showError(message) {
            if (this.$toasted) {
                this.$toasted.error(message);
            } else {
                alert(message);
            }
        }
    }
};
</script>

<style scoped>
.support-content {
    height: 100%;
}

.chat-container {
    display: flex;
    flex-direction: column;
    height: 500px;
    border: 1px solid #dee2e6;
    border-radius: 10px;
    overflow: hidden;
    background-color: #f5f5f5;
}

.chat-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 12px 16px;
    color: white;
}

.chat-avatar {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background-color: rgba(255, 255, 255, 0.2);
    display: flex;
    align-items: center;
    justify-content: center;
    margin-right: 12px;
}

.chat-avatar i {
    font-size: 18px;
}

.chat-header-info h6 {
    font-weight: 600;
}

.chat-header-actions {
    display: flex;
    align-items: center;
}

.chat-messages {
    flex: 1;
    overflow-y: auto;
    padding: 16px;
    background: linear-gradient(135deg, #e8f0fe 0%, #f0f4f8 100%);
}

.empty-chat-icon {
    width: 80px;
    height: 80px;
    border-radius: 50%;
    background-color: #dee2e6;
    display: flex;
    align-items: center;
    justify-content: center;
    margin: 0 auto;
}

.empty-chat-icon i {
    font-size: 36px;
    color: #adb5bd;
}

.messages-wrapper {
    display: flex;
    flex-direction: column;
    gap: 8px;
}

.message-item {
    display: flex;
    max-width: 75%;
}

.message-item.message-sent {
    align-self: flex-end;
    margin-left: auto;
}

.message-item.message-received {
    align-self: flex-start;
}

.message-bubble {
    padding: 8px 12px;
    border-radius: 12px;
    position: relative;
    word-wrap: break-word;
}

.message-sent .message-bubble {
    background-color: #dcf8c6;
    border-bottom-right-radius: 4px;
}

.message-received .message-bubble {
    background-color: #ffffff;
    border-bottom-left-radius: 4px;
    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
}

.message-sender {
    font-size: 11px;
    font-weight: 600;
    color: #128C7E;
    margin-bottom: 2px;
}

.message-content {
    font-size: 14px;
    line-height: 1.4;
    color: #303030;
    white-space: pre-wrap;
}

.message-meta {
    display: flex;
    justify-content: flex-end;
    align-items: center;
    gap: 4px;
    margin-top: 4px;
}

.message-time {
    font-size: 11px;
    color: #667781;
}

.message-status {
    font-size: 12px;
    color: #667781;
}

.message-status .fa-check-double.text-info {
    color: #53bdeb !important;
}

.chat-input-area {
    padding: 12px;
    background-color: #f0f2f5;
    border-top: 1px solid #e9ecef;
}

.chat-input-area .input-group {
    display: flex;
    align-items: flex-end;
    gap: 8px;
}

.chat-input-area textarea {
    flex: 1;
    border-radius: 20px;
    padding: 10px 16px;
    border: 1px solid #dee2e6;
    resize: none;
    max-height: 120px;
    min-height: 42px;
}

.chat-input-area textarea:focus {
    border-color: #9AC444;
    box-shadow: none;
}

.btn-send {
    width: 42px;
    height: 42px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    border: none;
    flex-shrink: 0;
}

.btn-send:hover {
    opacity: 0.9;
    color: white;
}

.btn-send:disabled {
    opacity: 0.5;
    cursor: not-allowed;
}

/* Scrollbar styling */
.chat-messages::-webkit-scrollbar {
    width: 6px;
}

.chat-messages::-webkit-scrollbar-track {
    background: transparent;
}

.chat-messages::-webkit-scrollbar-thumb {
    background-color: rgba(0, 0, 0, 0.2);
    border-radius: 3px;
}

.chat-messages::-webkit-scrollbar-thumb:hover {
    background-color: rgba(0, 0, 0, 0.3);
}
</style>
