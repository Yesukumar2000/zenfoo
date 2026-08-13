<template>
    <div class="chat-wrapper">
        <!-- Chat Header -->
        <div class="chat-header d-flex align-items-center justify-content-between p-3">
            <div class="d-flex align-items-center">
                <div class="avatar-circle me-2">
                    <i class="fa fa-user"></i>
                </div>
                <div>
                    <h6 class="mb-0">{{ customerName || 'Customer' }}</h6>
                    <small class="text-muted">ID: {{ customerId }}</small>
                </div>
            </div>
            <div class="d-flex align-items-center">
                <span v-if="isConnected" class="badge bg-success me-2">
                    <i class="fa fa-circle me-1" style="font-size: 8px;"></i> Live
                </span>
                <span v-else class="badge bg-warning me-2">
                    <i class="fa fa-circle me-1" style="font-size: 8px;"></i> Connecting...
                </span>
                <button class="btn btn-sm btn-outline-primary" @click="reconnect" :disabled="isLoading">
                    <i class="fa fa-refresh" :class="{ 'fa-spin': isLoading }"></i>
                </button>
            </div>
        </div>

        <!-- Chat Messages Area -->
        <div class="chat-messages" ref="chatMessages">
            <div v-if="isLoading" class="text-center py-5">
                <b-spinner></b-spinner>
                <p class="text-muted mt-2">Loading messages...</p>
            </div>

            <div v-else-if="messages.length === 0" class="text-center py-5">
                <i class="fa fa-comments fa-3x text-muted mb-3"></i>
                <p class="text-muted">No messages yet. Start a conversation!</p>
            </div>

            <div v-else class="messages-wrapper p-3">
                <div v-for="(msg, index) in messages" :key="index" class="message-row" :class="{ 'message-sent': msg.sender === 'admin', 'message-received': msg.sender === 'customer' }">
                    <div class="message-bubble" :class="{ 'sent': msg.sender === 'admin', 'received': msg.sender === 'customer' }">
                        <div class="message-content">{{ msg.message }}</div>
                        <div class="message-time">
                            <small>{{ msg.time_display || formatTime(msg.time) }}</small>
                            <i v-if="msg.sender === 'admin'" class="fa fa-check ms-1" :class="{ 'text-primary': msg.read }"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Chat Input Area -->
        <div class="chat-input p-3">
            <div class="input-group">
                <input
                    type="text"
                    class="form-control"
                    v-model="newMessage"
                    placeholder="Type a message..."
                    @keyup.enter="sendMessage"
                    :disabled="isSending"
                />
                <button
                    class="btn btn-primary"
                    @click="sendMessage"
                    :disabled="!newMessage.trim() || isSending"
                >
                    <i class="fa" :class="isSending ? 'fa-spinner fa-spin' : 'fa-paper-plane'"></i>
                </button>
            </div>
        </div>
    </div>
</template>

<script>
import { subscribeToCustomerChatMessages } from '../../../services/FirebaseService';

export default {
    props: {
        customerId: {
            type: [String, Number],
            required: true
        }
    },
    data() {
        return {
            isLoading: false,
            isSending: false,
            isConnected: false,
            messages: [],
            newMessage: '',
            customerName: '',
            customer: null,
            unsubscribe: null,
            isInitialLoad: true
        }
    },
    created() {
        this.initializeChat();
    },
    beforeDestroy() {
        // Unsubscribe from Firestore listener when component is destroyed
        this.stopListening();
    },
    watch: {
        customerId: function() {
            this.stopListening();
            this.isInitialLoad = true;
            this.initializeChat();
        }
    },
    methods: {
        async initializeChat() {
            this.isLoading = true;
            this.isConnected = false;

            try {
                // Initialize chat in Firestore via API
                await axios.post(this.$apiUrl + '/customer-chat/initialize', {
                    customer_id: this.customerId
                });

                // Fetch customer details
                await this.fetchCustomerDetails();

                // Start real-time listener
                await this.startListening();

            } catch (error) {
                console.error('Error initializing chat:', error);
                this.showError('Failed to initialize chat. Please refresh.');
            }

            this.isLoading = false;
        },

        async fetchCustomerDetails() {
            try {
                const response = await axios.get(this.$apiUrl + '/customer-chat/' + this.customerId + '/messages?limit=1');
                if (response.data.status === 1 && response.data.data.customer) {
                    this.customer = response.data.data.customer;
                    this.customerName = this.customer.name || '';
                }
            } catch (error) {
                console.error('Error fetching customer details:', error);
            }
        },

        async startListening() {
            try {
                // Subscribe to real-time messages from Firestore
                this.unsubscribe = await subscribeToCustomerChatMessages(
                    this.customerId,
                    (messages, error) => {
                        if (error) {
                            console.error('Firestore listener error:', error);
                            this.isConnected = false;
                            return;
                        }

                        this.isConnected = true;
                        const previousCount = this.messages.length;
                        this.messages = messages;

                        // Mark as read when new messages arrive
                        if (messages.length > 0) {
                            this.markAsRead();
                        }

                        // Scroll to bottom
                        if (this.isInitialLoad) {
                            this.scrollToBottom(false);
                            this.isInitialLoad = false;
                        } else if (messages.length > previousCount) {
                            this.scrollToBottom(true);
                        }
                    }
                );

                this.isConnected = true;
            } catch (error) {
                console.error('Error starting Firestore listener:', error);
                this.isConnected = false;
                // Fallback to API polling if Firestore fails
                this.fallbackToPolling();
            }
        },

        stopListening() {
            if (this.unsubscribe) {
                this.unsubscribe();
                this.unsubscribe = null;
            }
            this.isConnected = false;
        },

        async reconnect() {
            this.stopListening();
            this.isInitialLoad = true;
            await this.initializeChat();
        },

        fallbackToPolling() {
            // If Firestore real-time fails, fall back to API polling
            console.warn('Falling back to API polling...');
            this.loadMessagesViaApi();
        },

        async loadMessagesViaApi() {
            try {
                const response = await axios.get(this.$apiUrl + '/customer-chat/' + this.customerId + '/messages');
                if (response.data.status === 1) {
                    this.messages = response.data.data.messages || [];
                    if (response.data.data.customer) {
                        this.customer = response.data.data.customer;
                        this.customerName = this.customer.name || '';
                    }
                    this.scrollToBottom(false);
                }
            } catch (error) {
                console.error('Error loading messages via API:', error);
            }
        },

        async markAsRead() {
            try {
                await axios.post(this.$apiUrl + '/customer-chat/mark-read', {
                    customer_id: this.customerId
                });
            } catch (error) {
                // Silent fail for mark as read
            }
        },

        async sendMessage() {
            if (!this.newMessage.trim() || this.isSending) return;

            this.isSending = true;
            const messageText = this.newMessage.trim();
            this.newMessage = '';

            try {
                const response = await axios.post(this.$apiUrl + '/customer-chat/send', {
                    customer_id: this.customerId,
                    message: messageText
                });

                if (response.data.status === 1) {
                    // Message will be added via real-time listener
                    // Just scroll to bottom
                    this.scrollToBottom(true);
                } else {
                    this.showError(response.data.message || 'Failed to send message');
                    this.newMessage = messageText;
                }
            } catch (error) {
                console.error('Error sending message:', error);
                this.showError('Failed to send message');
                this.newMessage = messageText;
            }

            this.isSending = false;
        },

        scrollToBottom(smooth = false) {
            setTimeout(() => {
                const container = this.$refs.chatMessages;
                if (container) {
                    if (smooth) {
                        container.scrollTo({
                            top: container.scrollHeight,
                            behavior: 'smooth'
                        });
                    } else {
                        container.scrollTop = container.scrollHeight;
                    }
                }
            }, 100);
        },

        formatTime(timestamp) {
            if (!timestamp) return '';

            let date;

            // Handle Firestore Timestamp object (has toDate method)
            if (timestamp.toDate && typeof timestamp.toDate === 'function') {
                date = timestamp.toDate();
            }
            // Handle Firestore Timestamp as plain object (has seconds property)
            else if (timestamp.seconds) {
                date = new Date(timestamp.seconds * 1000);
            }
            // Handle regular date string or Date object
            else {
                date = new Date(timestamp);
            }

            return date.toLocaleTimeString('en-US', {
                hour: 'numeric',
                minute: '2-digit',
                hour12: true
            });
        }
    }
};
</script>

<style>
.chat-wrapper {
    height: 450px;
    display: flex;
    flex-direction: column;
    background-color: #fff;
    border: 1px solid #e0e0e0;
    border-radius: 8px;
    overflow: hidden;
}

.chat-header {
    background-color: #f8f9fa;
    border-bottom: 1px solid #e0e0e0;
    flex-shrink: 0;
}

.chat-input {
    background-color: #fff;
    border-top: 1px solid #e0e0e0;
    flex-shrink: 0;
}

.chat-header h6 {
    color: #333;
}

.avatar-circle {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background-color: #9AC444;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #fff;
}

.chat-messages {
    flex: 1;
    overflow-y: auto;
    background-color: #f5f5f5;
}

.messages-wrapper {
    display: flex;
    flex-direction: column;
    gap: 8px;
}

.message-row {
    display: flex;
    width: 100%;
}

.message-row.message-sent {
    justify-content: flex-end;
}

.message-row.message-received {
    justify-content: flex-start;
}

.message-bubble {
    max-width: 70%;
    padding: 8px 12px;
    border-radius: 8px;
    position: relative;
    word-wrap: break-word;
}

.message-bubble.sent {
    background-color: #9AC444;
    color: #fff;
    border-top-right-radius: 0;
}

.message-bubble.received {
    background-color: #fff;
    color: #333;
    border: 1px solid #e0e0e0;
    border-top-left-radius: 0;
}

.message-content {
    font-size: 14px;
    line-height: 1.4;
}

.message-bubble.sent .message-content {
    color: #fff;
}

.message-bubble.received .message-content {
    color: #333;
}

.message-time {
    text-align: right;
    margin-top: 4px;
    font-size: 11px;
}

.message-bubble.sent .message-time {
    color: rgba(255, 255, 255, 0.8);
}

.message-bubble.received .message-time {
    color: #667781;
}

.chat-input .form-control {
    border-radius: 20px;
    padding-left: 15px;
}

.chat-input .form-control:focus {
    box-shadow: none;
    border-color: #9AC444;
}

.chat-input .btn {
    border-radius: 50%;
    width: 40px;
    height: 40px;
    padding: 0;
    margin-left: 8px;
}

/* Scrollbar styling */
.chat-messages::-webkit-scrollbar {
    width: 6px;
}

.chat-messages::-webkit-scrollbar-track {
    background: #f1f1f1;
}

.chat-messages::-webkit-scrollbar-thumb {
    background-color: #c1c1c1;
    border-radius: 3px;
}

.chat-messages::-webkit-scrollbar-thumb:hover {
    background-color: #a1a1a1;
}

/* Dark theme support */
.theme-dark .chat-wrapper {
    background-color: #1e1e1e;
    border-color: #333;
}

.theme-dark .chat-header {
    background-color: #2d2d2d;
    border-color: #333;
}

.theme-dark .chat-header h6 {
    color: #e0e0e0;
}

.theme-dark .chat-messages {
    background-color: #252525;
}

.theme-dark .message-bubble.received {
    background-color: #2d2d2d;
    color: #e0e0e0;
    border-color: #444;
}

.theme-dark .message-bubble.received .message-content {
    color: #e0e0e0;
}

.theme-dark .message-bubble.received .message-time {
    color: #999;
}

.theme-dark .chat-input {
    background-color: #1e1e1e;
    border-color: #333;
}

.theme-dark .chat-input .form-control {
    background-color: #2d2d2d;
    color: #e0e0e0;
    border-color: #444;
}

.theme-dark .chat-input .form-control::placeholder {
    color: #888;
}

.theme-dark .chat-messages::-webkit-scrollbar-track {
    background: #252525;
}

.theme-dark .chat-messages::-webkit-scrollbar-thumb {
    background-color: #444;
}
</style>
