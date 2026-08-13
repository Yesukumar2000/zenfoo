<template>
    <div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>Chatting with Customers</h3>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">Customer Messages</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/dashboard" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to Dashboard
                    </router-link>
                </div>
            </div>

            <section class="section">
                <div class="card">
                    <div class="card-header">
                        <h4 class="card-title">Customer Messages</h4>
                    </div>
                    <div class="card-body">
                        <div class="text-center py-5">
                            <i class="fa fa-comments fa-5x text-muted mb-4"></i>
                            <h4>Chatting with Customers</h4>
                            <p class="text-muted">This feature is coming soon. You will be able to chat with customers here.</p>
                        </div>
                    </div>
                </div>
            </section>
        </div>
    </div>
</template>

<script>
export default {
    name: "CustomerMessages",
    data() {
        return {
            // Data will be added later
        };
    },
    created() {
        // Initialization logic will be added later
    },
    methods: {
        // Methods will be added later
    }
};
</script>

<style scoped>
.fa-comments {
    color: #6c757d;
}
</style>
