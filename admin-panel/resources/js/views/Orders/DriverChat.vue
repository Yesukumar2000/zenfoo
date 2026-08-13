<template>
    <div class="driver-chat">
        <ChatBox
            :orderId="orderId"
            chatType="driver"
            title="Driver Support"
            headerIcon="fas fa-motorcycle"
            headerColor="#f0ad4e"
        />
    </div>
</template>

<script>
import ChatBox from './ChatBox.vue';

export default {
    name: 'DriverChat',
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
.driver-chat {
    height: 100%;
}
</style>
