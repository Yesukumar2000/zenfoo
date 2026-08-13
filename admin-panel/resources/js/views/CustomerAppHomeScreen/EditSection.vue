<template>
    <b-modal ref="my-modal" :title="modal_title" @hidden="$emit('modalClose')" scrollable no-close-on-backdrop no-fade static size="md">
        <div slot="modal-footer">
            <b-button variant="primary" @click="$refs['dummy_submit'].click()" :disabled="isLoading">Save
                <b-spinner v-if="isLoading" small label="Spinning"></b-spinner>
            </b-button>
            <b-button variant="secondary" @click="hideModal">Cancel</b-button>
        </div>
        <form ref="my-form" @submit.prevent="saveRecord">
            <div class="row">
                <div class="col-md-12">
                    <div class="form-group">
                        <label>Name <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" required v-model="name" placeholder="Enter section name">
                    </div>
                </div>

                <div class="col-md-12">
                    <div class="form-group">
                        <label>Order</label>
                        <input type="number" class="form-control" v-model="order" placeholder="Enter display order" min="0">
                        <small class="text-muted">Lower numbers appear first</small>
                    </div>
                </div>
            </div>
            <button type="submit" ref="dummy_submit" style="display:none"></button>
        </form>
    </b-modal>
</template>

<script>
export default {
    props: ['record'],
    data() {
        return {
            modal_title: 'Add Section',
            id: null,
            name: '',
            order: 0,
            isLoading: false,
        }
    },
    mounted() {
        this.$refs['my-modal'].show();

        if (this.record !== true) {
            this.modal_title = 'Edit Section';
            this.id = this.record.id;
            this.name = this.record.name;
            this.order = this.record.order;
        }
    },
    methods: {
        hideModal() {
            this.$refs['my-modal'].hide();
        },
        saveRecord() {
            this.isLoading = true;

            let formData = new FormData();
            formData.append('name', this.name);
            formData.append('order', this.order || 0);

            let url = this.$apiUrl + '/products/customer-app-sections/save';

            if (this.id) {
                url = this.$apiUrl + '/products/customer-app-sections/update';
                formData.append('id', this.id);
            }

            axios.post(url, formData)
                .then((response) => {
                    this.isLoading = false;
                    if (response.data.status === 1) {
                        this.showMessage('success', response.data.message);
                        this.$emit('recordSaved');
                        this.hideModal();
                    } else {
                        this.showMessage('error', response.data.message);
                    }
                })
                .catch((error) => {
                    this.isLoading = false;
                    console.error('Error saving section:', error);
                    this.showMessage('error', error.response?.data?.message || 'Failed to save section');
                });
        }
    }
}
</script>

<style scoped>
.form-group {
    margin-bottom: 1rem;
}
</style>