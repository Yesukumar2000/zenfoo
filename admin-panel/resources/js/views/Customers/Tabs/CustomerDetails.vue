<template>
    <div>
        <div class="row">
            <div class="col-12">
                <div v-if="isLoading" class="text-center py-5">
                    <b-spinner></b-spinner>
                    <p>{{ __('loading') }}...</p>
                </div>
                <div v-else>
                    <form @submit.prevent="updateCustomer">
                        <div class="row">
                            <div class="col-md-6">
                                <div class="form-group mb-3">
                                    <label for="name" class="form-label">{{ __('name') }}</label>
                                    <input
                                        type="text"
                                        class="form-control"
                                        id="name"
                                        v-model="form.name"
                                        :placeholder="__('enter_name')"
                                    />
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="form-group mb-3">
                                    <label for="email" class="form-label">{{ __('email') }}</label>
                                    <input
                                        type="email"
                                        class="form-control"
                                        id="email"
                                        v-model="form.email"
                                        :placeholder="__('enter_email')"
                                    />
                                    <small v-if="errors.email" class="text-danger">{{ errors.email }}</small>
                                </div>
                            </div>
                        </div>
                        <div class="row">
                            <div class="col-md-6">
                                <div class="form-group mb-3">
                                    <label for="mobile" class="form-label">{{ __('mobile_no') }}</label>
                                    <input
                                        type="text"
                                        class="form-control"
                                        id="mobile"
                                        v-model="form.mobile"
                                        :placeholder="__('enter_mobile')"
                                    />
                                    <small v-if="errors.mobile" class="text-danger">{{ errors.mobile }}</small>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="form-group mb-3">
                                    <label for="status" class="form-label">{{ __('status') }}</label>
                                    <select class="form-control form-select" id="status" v-model="form.status">
                                        <option value="1">{{ __('active') }}</option>
                                        <option value="0">{{ __('deactive') }}</option>
                                    </select>
                                </div>
                            </div>
                        </div>
                        <!-- <div class="row">
                            <div class="col-md-6">
                                <div class="form-group mb-3">
                                    <label class="form-label">{{ __('balance') }}</label>
                                    <input
                                        type="text"
                                        class="form-control"
                                        :value="customer ? customer.balance : '-'"
                                        disabled
                                    />
                                    <small class="text-muted">Balance cannot be edited directly</small>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="form-group mb-3">
                                    <label class="form-label">{{ __('orders') }}</label>
                                    <input
                                        type="text"
                                        class="form-control"
                                        :value="customer ? customer.orders_count : '0'"
                                        disabled
                                    />
                                </div>
                            </div>
                        </div>
                        <div class="row">
                            <div class="col-md-6">
                                <div class="form-group mb-3">
                                    <label class="form-label">{{ __('referral_code') }}</label>
                                    <input
                                        type="text"
                                        class="form-control"
                                        :value="customer ? customer.referral_code : '-'"
                                        disabled
                                    />
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="form-group mb-3">
                                    <label class="form-label">{{ __('registered_at') }}</label>
                                    <input
                                        type="text"
                                        class="form-control"
                                        :value="customer ? formatDate(customer.created_at) : '-'"
                                        disabled
                                    />
                                </div>
                            </div>
                        </div> -->
                        <div class="row mt-3">
                            <div class="col-12">
                                <button type="submit" class="btn btn-primary" :disabled="isSaving">
                                    {{ __('save') }}
                                </button>
                                <!-- <button
                                    type="button"
                                    class="btn btn-secondary ms-2"
                                    @click="resetForm"
                                    :disabled="isSaving"
                                >
                                    <i class="fa fa-undo me-1"></i> {{ __('reset') }}
                                </button> -->
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
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
            isSaving: false,
            customer: null,
            form: {
                name: '',
                email: '',
                mobile: '',
                status: 1
            },
            errors: {
                email: '',
                mobile: ''
            }
        }
    },
    created() {
        this.loadCustomer();
    },
    watch: {
        customerId: function() {
            this.loadCustomer();
        }
    },
    methods: {
        fixMobile(mobile) {
            if (!mobile) return '';
            let num = Number(mobile);
            if (num < 0) {
                num = num + 4294967296;
            }
            return String(num);
        },
        loadCustomer() {
            this.isLoading = true;
            this.errors = { email: '', mobile: '' };

            axios.get(this.$apiUrl + '/customers/' + this.customerId)
                .then((response) => {
                    this.isLoading = false;
                    if (response.data.status === 1) {
                        this.customer = response.data.data;
                        this.form = {
                            name: this.customer.name || '',
                            email: this.customer.email || '',
                            mobile: this.fixMobile(this.customer.mobile) || '',
                            status: this.customer.status
                        };
                    } else {
                        this.showError(response.data.message || 'Failed to load customer');
                    }
                })
                .catch((error) => {
                    this.isLoading = false;
                    console.error('Error fetching customer:', error);
                    this.showError('Failed to load customer details');
                });
        },
        updateCustomer() {
            this.isSaving = true;
            this.errors = { email: '', mobile: '' };

            axios.post(this.$apiUrl + '/customers/' + this.customerId + '/update', this.form)
                .then((response) => {
                    this.isSaving = false;
                    if (response.data.status === 1) {
                        this.customer = response.data.data;
                        this.showMessage('success', response.data.message || 'Customer updated successfully');
                    } else {
                        // Check for specific error messages
                        if (response.data.message && response.data.message.includes('Email')) {
                            this.errors.email = response.data.message;
                        } else if (response.data.message && response.data.message.includes('Mobile')) {
                            this.errors.mobile = response.data.message;
                        } else {
                            this.showError(response.data.message || 'Failed to update customer');
                        }
                    }
                })
                .catch((error) => {
                    this.isSaving = false;
                    console.error('Error updating customer:', error);
                    this.showError('Failed to update customer');
                });
        },
        resetForm() {
            if (this.customer) {
                this.form = {
                    name: this.customer.name || '',
                    email: this.customer.email || '',
                    mobile: this.fixMobile(this.customer.mobile) || '',
                    status: this.customer.status
                };
            }
            this.errors = { email: '', mobile: '' };
        },
        formatDate(date) {
            if (!date) return '-';
            return new Date(date).toLocaleString();
        }
    }
};
</script>

<style scoped>
.form-label {
    font-weight: 500;
}
</style>