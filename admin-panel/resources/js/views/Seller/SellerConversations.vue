<template>
    <div>
        <div v-if="isLoading && messages.length === 0" class="text-center py-5">
            <b-spinner variant="primary" label="Loading..."></b-spinner>
            <p class="mt-2">Loading conversations...</p>
        </div>
        <div v-else>
            <div class="row">
                <!-- Chat Container -->
                <div class="col-12">
                    <div class="chat-container">
                        <!-- Chat Header -->
                        <div class="chat-header d-flex justify-content-between align-items-center">
                            <div class="d-flex align-items-center">
                                <div class="chat-avatar me-3">
                                    <img v-if="sellerInfo && sellerInfo.logo" :src="sellerInfo.logo_url || sellerInfo.logo" alt="Seller" class="rounded-circle">
                                    <div v-else class="avatar-placeholder rounded-circle">
                                        <i class="fa fa-store"></i>
                                    </div>
                                </div>
                                <div>
                                    <h5 class="mb-0">{{ sellerInfo ? sellerInfo.name : 'Seller' }}</h5>
                                    <small class="text-muted">{{ sellerInfo ? sellerInfo.email : '' }}</small>
                                </div>
                            </div>
                            <div class="d-flex align-items-center">
                                <span class="badge bg-info me-2" v-if="unreadCount > 0">
                                    {{ unreadCount }} unread
                                </span>
                                <!-- <button class="btn btn-sm btn-outline-primary me-2" @click="markAllAsRead" :disabled="unreadCount === 0" v-b-tooltip.hover title="Mark all as read">
                                    <i class="fa fa-check-double"></i>
                                </button> -->
                                <button class="btn btn-sm btn-outline-secondary" @click="getMessages" v-b-tooltip.hover title="Refresh">
                                    <i class="fa fa-refresh" :class="{ 'fa-spin': isLoading }"></i>
                                </button>
                            </div>
                        </div>

                        <!-- Chat Messages -->
                        <div class="chat-messages" ref="chatMessages">
                            <div v-if="messages.length === 0 && !isLoading" class="text-center py-5">
                                <i class="fa fa-comments fa-3x text-muted mb-3"></i>
                                <p class="text-muted">No messages yet. Start a conversation!</p>
                            </div>

                            <div v-for="(message, index) in messages" :key="message.id" class="message-wrapper" :class="getMessageClass(message)">
                                <div class="message" :class="getMessageBubbleClass(message)">
                                    <div class="message-content">
                                        <p class="mb-1">{{ message.message }}</p>
                                        <!-- Attachment -->
                                        <div v-if="message.attachment" class="message-attachment mt-2">
                                            <a :href="getAttachmentUrl(message.attachment)" target="_blank" class="attachment-link">
                                                <i class="fa fa-paperclip me-1"></i>
                                                <span>View Attachment</span>
                                            </a>
                                        </div>
                                    </div>
                                    <div class="message-meta">
                                        <small class="text-muted">
                                            {{ formatDateTime(message.created_at) }}
                                            <span v-if="message.sender_type === 'admin'" class="ms-1">
                                                <i v-if="message.read_at" class="fa fa-check-double text-primary" v-b-tooltip.hover title="Read"></i>
                                                <i v-else class="fa fa-check text-muted" v-b-tooltip.hover title="Sent"></i>
                                            </span>
                                        </small>
                                    </div>
                                </div>
                                <div class="message-sender">
                                    <small>{{ message.sender_type === 'admin' ? 'Admin' : 'Seller' }}</small>
                                </div>
                            </div>

                            <!-- Load More -->
                            <div v-if="hasMoreMessages" class="text-center py-3">
                                <button class="btn btn-sm btn-outline-primary" @click="loadMoreMessages" :disabled="isLoadingMore">
                                    <b-spinner v-if="isLoadingMore" small></b-spinner>
                                    <span v-else>Load More Messages</span>
                                </button>
                            </div>
                        </div>

                        <!-- Chat Input -->
                        <div class="chat-input">
                            <form @submit.prevent="sendMessage" class="d-flex align-items-end">
                                <div class="flex-grow-1 me-2">
                                    <textarea
                                        v-model="newMessage"
                                        class="form-control"
                                        rows="2"
                                        placeholder="Type your message..."
                                        @keydown.enter.exact.prevent="sendMessage"
                                        @keydown.enter.shift.exact="newLine"
                                        :disabled="isSending"
                                    ></textarea>
                                </div>
                                <div class="d-flex flex-column">
                                    <!-- Attachment Button -->
                                    <label class="btn btn-sm btn-outline-secondary mb-2" v-b-tooltip.hover title="Attach file">
                                        <i class="fa fa-paperclip"></i>
                                        <input type="file" ref="attachmentInput" @change="handleAttachment" class="d-none" accept="image/*,.pdf,.doc,.docx">
                                    </label>
                                    <!-- Send Button -->
                                    <button type="submit" class="btn btn-primary btn-sm" :disabled="isSending || (!newMessage.trim() && !attachment)">
                                        <b-spinner v-if="isSending" small></b-spinner>
                                        <i v-else class="fa fa-paper-plane"></i>
                                    </button>
                                </div>
                            </form>
                            <!-- Attachment Preview -->
                            <div v-if="attachment" class="attachment-preview mt-2">
                                <div class="d-flex align-items-center justify-content-between bg-light p-2 rounded">
                                    <div class="d-flex align-items-center">
                                        <i class="fa fa-file me-2"></i>
                                        <span class="text-truncate" style="max-width: 200px;">{{ attachment.name }}</span>
                                        <small class="text-muted ms-2">({{ formatFileSize(attachment.size) }})</small>
                                    </div>
                                    <button type="button" class="btn btn-sm btn-outline-danger" @click="removeAttachment">
                                        <i class="fa fa-times"></i>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import moment from "moment";
import axios from "axios";
import Auth from '../../Auth.js';

export default {
    name: 'SellerConversations',
    props: {
        sellerId: {
            type: [String, Number],
            required: true
        }
    },
    data() {
        return {
            isLoading: false,
            isLoadingMore: false,
            isSending: false,
            messages: [],
            sellerInfo: null,
            unreadCount: 0,
            newMessage: '',
            attachment: null,

            // Pagination
            currentPage: 1,
            perPage: 20,
            totalMessages: 0,
            hasMoreMessages: false,

            // Auto-refresh timer
            refreshTimer: null
        }
    },
    created() {
        this.getSellerInfo();
        this.getMessages();
        this.getUnreadCount();

        // Auto-refresh every 30 seconds
        this.refreshTimer = setInterval(() => {
            this.getMessages(true);
            this.getUnreadCount();
        }, 30000);
    },
    beforeDestroy() {
        if (this.refreshTimer) {
            clearInterval(this.refreshTimer);
        }
    },
    methods: {
        getSellerInfo() {
            axios.get(this.$apiUrl + '/seller/view/' + this.sellerId)
                .then((response) => {
                    if (response.data.status === 1) {
                        this.sellerInfo = response.data.data.seller;
                    }
                })
                .catch((error) => {
                    console.error('Error fetching seller info:', error);
                });
        },

        getMessages(silent = false) {
            if (!silent) {
                this.isLoading = true;
            }

            const params = {
                conversation_type: 'seller',
                participant_id: this.sellerId,
                per_page: this.perPage,
                page: 1
            };

            axios.get(this.$apiUrl + '/messages/conversation', { params })
                .then((response) => {
                    if (response.data.status === 1) {
                        this.messages = response.data.data.messages;
                        this.totalMessages = response.data.data.pagination.total;
                        this.hasMoreMessages = response.data.data.pagination.current_page < response.data.data.pagination.last_page;
                        this.currentPage = 1;

                        if (response.data.data.participant) {
                            this.sellerInfo = response.data.data.participant;
                        }

                        // Scroll to bottom on initial load
                        if (!silent) {
                            this.$nextTick(() => {
                                this.scrollToBottom();
                            });
                        }
                    }
                    this.isLoading = false;
                })
                .catch((error) => {
                    this.isLoading = false;
                    console.error('Error fetching messages:', error);
                    if (!silent) {
                        this.showError('Failed to load messages');
                    }
                });
        },

        loadMoreMessages() {
            this.isLoadingMore = true;
            const nextPage = this.currentPage + 1;

            const params = {
                conversation_type: 'seller',
                participant_id: this.sellerId,
                per_page: this.perPage,
                page: nextPage
            };

            axios.get(this.$apiUrl + '/messages/conversation', { params })
                .then((response) => {
                    if (response.data.status === 1) {
                        // Prepend older messages
                        this.messages = [...response.data.data.messages, ...this.messages];
                        this.currentPage = nextPage;
                        this.hasMoreMessages = response.data.data.pagination.current_page < response.data.data.pagination.last_page;
                    }
                    this.isLoadingMore = false;
                })
                .catch((error) => {
                    this.isLoadingMore = false;
                    console.error('Error loading more messages:', error);
                });
        },

        getUnreadCount() {
            const params = {
                conversation_type: 'seller',
                participant_id: this.sellerId,
                reader_type: 'admin'
            };

            axios.get(this.$apiUrl + '/messages/unread-count', { params })
                .then((response) => {
                    if (response.data.status === 1) {
                        this.unreadCount = response.data.data.unread_count;
                    }
                })
                .catch((error) => {
                    console.error('Error fetching unread count:', error);
                });
        },

        sendMessage() {
            if (!this.newMessage.trim() && !this.attachment) {
                return;
            }

            this.isSending = true;

            const formData = new FormData();
            formData.append('conversation_type', 'seller');
            formData.append('participant_id', this.sellerId);
            formData.append('sender_type', 'admin');
            formData.append('sender_id', Auth.user.id);
            formData.append('message', this.newMessage.trim() || '(Attachment)');

            if (this.attachment) {
                formData.append('attachment', this.attachment);
            }

            axios.post(this.$apiUrl + '/messages/send', formData, {
                headers: {
                    'Content-Type': 'multipart/form-data'
                }
            })
                .then((response) => {
                    if (response.data.status === 1) {
                        // Add new message to the list
                        this.messages.push(response.data.data);
                        this.newMessage = '';
                        this.attachment = null;
                        if (this.$refs.attachmentInput) {
                            this.$refs.attachmentInput.value = '';
                        }

                        // Scroll to bottom
                        this.$nextTick(() => {
                            this.scrollToBottom();
                        });

                        this.showSuccess('Message sent successfully!');
                    } else {
                        this.showError(response.data.message || 'Failed to send message');
                    }
                    this.isSending = false;
                })
                .catch((error) => {
                    this.isSending = false;
                    console.error('Error sending message:', error);
                    if (error.response && error.response.data && error.response.data.message) {
                        this.showError(error.response.data.message);
                    } else {
                        this.showError('Failed to send message');
                    }
                });
        },

        markAllAsRead() {
            const data = {
                conversation_type: 'seller',
                participant_id: this.sellerId,
                reader_type: 'admin'
            };

            axios.post(this.$apiUrl + '/messages/mark-conversation-as-read', data)
                .then((response) => {
                    if (response.data.status === 1) {
                        this.unreadCount = 0;
                        // Update read_at for all messages from seller
                        this.messages = this.messages.map(msg => {
                            if (msg.sender_type === 'seller' && !msg.read_at) {
                                return { ...msg, read_at: new Date().toISOString() };
                            }
                            return msg;
                        });
                        this.showSuccess('All messages marked as read');
                    }
                })
                .catch((error) => {
                    console.error('Error marking as read:', error);
                    this.showError('Failed to mark messages as read');
                });
        },

        handleAttachment(event) {
            const file = event.target.files[0];
            if (file) {
                // Check file size (5MB max)
                if (file.size > 5 * 1024 * 1024) {
                    this.showError('File size must be less than 5MB');
                    return;
                }
                this.attachment = file;
            }
        },

        removeAttachment() {
            this.attachment = null;
            if (this.$refs.attachmentInput) {
                this.$refs.attachmentInput.value = '';
            }
        },

        getMessageClass(message) {
            return message.sender_type === 'admin' ? 'message-sent' : 'message-received';
        },

        getMessageBubbleClass(message) {
            return message.sender_type === 'admin' ? 'message-bubble-sent' : 'message-bubble-received';
        },

        getAttachmentUrl(attachment) {
            if (!attachment) return '';
            if (attachment.startsWith('http')) {
                return attachment;
            }
            return this.$baseUrl + '/storage/' + attachment;
        },

        formatDateTime(dateTime) {
            if (!dateTime) return '';
            const msgDate = moment(dateTime);
            const today = moment().startOf('day');
            const yesterday = moment().subtract(1, 'days').startOf('day');

            if (msgDate.isSame(today, 'day')) {
                return 'Today ' + msgDate.format('hh:mm A');
            } else if (msgDate.isSame(yesterday, 'day')) {
                return 'Yesterday ' + msgDate.format('hh:mm A');
            } else {
                return msgDate.format('DD MMM YYYY hh:mm A');
            }
        },

        formatFileSize(bytes) {
            if (bytes === 0) return '0 Bytes';
            const k = 1024;
            const sizes = ['Bytes', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
        },

        scrollToBottom() {
            if (this.$refs.chatMessages) {
                this.$refs.chatMessages.scrollTop = this.$refs.chatMessages.scrollHeight;
            }
        },

        newLine(event) {
            this.newMessage += '\n';
        },

        showSuccess(message) {
            if (this.$toast) {
                this.$toast.success(message);
            } else if (this.showMessage) {
                this.showMessage('success', message);
            }
        },

        showError(message) {
            if (this.$toast) {
                this.$toast.error(message);
            } else if (this.showMessage) {
                this.showMessage('error', message);
            }
        }
    }
}
</script>

<style scoped>
.chat-container {
    display: flex;
    flex-direction: column;
    height: 600px;
    border: 1px solid #e0e0e0;
    border-radius: 10px;
    overflow: hidden;
    background-color: #fff;
}

.chat-header {
    padding: 15px 20px;
    background-color: #f8f9fa;
    border-bottom: 1px solid #e0e0e0;
}

.chat-avatar img,
.avatar-placeholder {
    width: 45px;
    height: 45px;
    object-fit: cover;
}

.avatar-placeholder {
    background-color: #9AC444;
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.2rem;
}

.chat-messages {
    flex: 1;
    overflow-y: auto;
    padding: 20px;
    background-color: #f5f5f5;
}

.message-wrapper {
    margin-bottom: 15px;
    display: flex;
    flex-direction: column;
}

.message-wrapper.message-sent {
    align-items: flex-end;
}

.message-wrapper.message-received {
    align-items: flex-start;
}

.message {
    max-width: 70%;
    padding: 10px 15px;
    border-radius: 15px;
    word-wrap: break-word;
}

.message-bubble-sent {
    background-color: #9AC444;
    color: white;
    border-bottom-right-radius: 5px;
}

.message-bubble-received {
    background-color: #fff;
    color: #333;
    border: 1px solid #e0e0e0;
    border-bottom-left-radius: 5px;
}

.message-content p {
    margin: 0;
    white-space: pre-wrap;
}

.message-meta {
    margin-top: 5px;
    text-align: right;
}

.message-bubble-sent .message-meta small {
    color: rgba(255, 255, 255, 0.8);
}

.message-sender {
    margin-top: 3px;
    padding: 0 5px;
}

.message-sender small {
    color: #888;
    font-size: 11px;
}

.message-attachment {
    padding: 8px 12px;
    background-color: rgba(255, 255, 255, 0.2);
    border-radius: 8px;
}

.message-bubble-received .message-attachment {
    background-color: rgba(0, 0, 0, 0.05);
}

.attachment-link {
    color: inherit;
    text-decoration: none;
    display: flex;
    align-items: center;
}

.attachment-link:hover {
    text-decoration: underline;
}

.chat-input {
    padding: 15px 20px;
    background-color: #fff;
    border-top: 1px solid #e0e0e0;
}

.chat-input textarea {
    resize: none;
    border-radius: 20px;
    padding: 10px 15px;
}

.chat-input textarea:focus {
    box-shadow: none;
    border-color: #9AC444;
}

.attachment-preview {
    font-size: 0.875rem;
}

/* Scrollbar styling */
.chat-messages::-webkit-scrollbar {
    width: 6px;
}

.chat-messages::-webkit-scrollbar-track {
    background: #f1f1f1;
}

.chat-messages::-webkit-scrollbar-thumb {
    background: #c1c1c1;
    border-radius: 3px;
}

.chat-messages::-webkit-scrollbar-thumb:hover {
    background: #a1a1a1;
}

/* Dark theme support */
.theme-dark .chat-container {
    background-color: #1e1e1e;
    border-color: #333;
}

.theme-dark .chat-header {
    background-color: #2d2d2d;
    border-color: #333;
}

.theme-dark .chat-messages {
    background-color: #252525;
}

.theme-dark .message-bubble-received {
    background-color: #2d2d2d;
    color: #e0e0e0;
    border-color: #444;
}

.theme-dark .chat-input {
    background-color: #1e1e1e;
    border-color: #333;
}

.theme-dark .chat-input textarea {
    background-color: #2d2d2d;
    color: #e0e0e0;
    border-color: #444;
}
</style>