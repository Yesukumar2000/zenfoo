<template>
    <div class="customer-chat">
        <ChatBox
            :orderId="orderId"
            chatType="customer"
            title="Customer Support"
            headerIcon="fas fa-user"
            headerColor="#435971"
        />
    </div>
</template>

<script>
import ChatBox from './ChatBox.vue';

export default {
    name: 'CustomerChat',
    components: {
        ChatBox
    },
    props: {
        orderId: {
            type: [String, Number],
            required: true
        }
    }
};
</script>

<style scoped>
.customer-chat {
    height: 100%;
}
</style>
