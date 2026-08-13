<template>
    <section class="section">
        <div class="row mb-3">
            <div class="col-md-3">
                <div class="card cursor-pointer" @click="filterByStatus('')">
                    <div class="card-body">
                        <h6 class="text-muted">Total Pre Orders</h6>
                        <h3 class="text-primary">{{ stats.total || 0 }}</h3>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card cursor-pointer" @click="filterByStatus('12')">
                    <div class="card-body">
                        <h6 class="text-muted">Pending</h6>
                        <h3 class="text-warning">{{ stats.pending || 0 }}</h3>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card cursor-pointer" @click="filterByStatus('2')">
                    <div class="card-body">
                        <h6 class="text-muted">Processed</h6>
                        <h3 class="text-success">{{ stats.processed || 0 }}</h3>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card">
                    <div class="card-body">
                        <h6 class="text-muted">Next Process Date</h6>
                        <h6 class="text-info">{{ stats.next_process_date || 'N/A' }}</h6>
                    </div>
                </div>
            </div>
        </div>
    </section>
</template>

<script>
export default {
    name: 'StatsCards',
    props: {
        stats: {
            type: Object,
            default: () => ({
                total: 0,
                pending: 0,
                processed: 0,
                next_process_date: null
            })
        }
    },
    methods: {
        filterByStatus(status) {
            // Navigate to the appropriate route based on status
            if (!status || status === '') {
                // All orders - stay on current route or go to /preorders
                this.$router.push('/preorders').catch(() => {});
            } else {
                // Navigate with status query parameter
                this.$router.push(`/preorders?status=${status}`).catch(() => {});
            }
        }
    }
}
</script>

<style scoped>
.card {
    box-shadow: 0 0 10px rgba(0,0,0,0.05);
    transition: transform 0.2s;
}
.card.cursor-pointer:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 15px rgba(0,0,0,0.1);
    cursor: pointer;
}
</style>