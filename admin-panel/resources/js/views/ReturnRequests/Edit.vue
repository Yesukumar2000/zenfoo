<template>
    <b-modal ref="my-modal" :title="modal_title" @hidden="$emit('modalClose')" no-fade static size="lg">
        <div slot="modal-footer">
            <b-button variant="primary" @click="$refs['dummy_submit'].click()" :disabled="isLoading">{{ __('save') }}
                <b-spinner v-if="isLoading" small label="Spinning"></b-spinner>
            </b-button>
            <b-button variant="secondary" @click="hideModal">{{ __('cancel') }}</b-button>
        </div>
        <form ref="my-form" @submit.prevent="saveRecord">
            <div class="row">
                <div class="col-md-12">
                    <div class="form-group">
                        <label class="form-label fw-bold mb-3">{{ __('status') }} <span class="text-danger">*</span></label>
                        
                        <!-- Seller Statuses (role_id: 3) - Only show Pending, Delivery Boy Assigned, Approve, Reject -->
                        <div v-if="login_user.role_id == 3" class="row g-2">
                            <div class="col-lg-3 col-md-4 col-sm-6 mb-2">
                                <div class="card h-100 border-2" 
                                     :class="returnRequest.status == '1' ? 'border-warning bg-warning bg-opacity-10' : 'border-light'"
                                     @click="returnRequest.status = '1'">
                                    <div class="card-body text-center d-flex flex-column justify-content-center align-items-center p-3">
                                        <div class="mb-2 fs-4">&#8635;</div>
                                        <div class="fw-bold small">{{ __('pending') }}</div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-lg-3 col-md-4 col-sm-6 mb-2">
                                <div class="card h-100 border-2" 
                                     :class="returnRequest.status == '4' ? 'border-info bg-info bg-opacity-10' : 'border-light'"
                                     @click="returnRequest.status = '4'">
                                    <div class="card-body text-center d-flex flex-column justify-content-center align-items-center p-3">
                                        <div class="mb-2 fs-4">&#128100;</div>
                                        <div class="fw-bold small">{{ __('delivery_boy_assigned') }}</div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-lg-3 col-md-4 col-sm-6 mb-2">
                                <div class="card h-100 border-2" 
                                     :class="returnRequest.status == '2' ? 'border-success bg-success bg-opacity-10' : 'border-light'"
                                     @click="returnRequest.status = '2'">
                                    <div class="card-body text-center d-flex flex-column justify-content-center align-items-center p-3">
                                        <div class="mb-2 fs-4">&#9989;</div>
                                        <div class="fw-bold small">{{ __('approve') }}</div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-lg-3 col-md-4 col-sm-6 mb-2">
                                <div class="card h-100 border-2" 
                                     :class="returnRequest.status == '3' ? 'border-danger bg-danger bg-opacity-10' : 'border-light'"
                                     @click="returnRequest.status = '3'">
                                    <div class="card-body text-center d-flex flex-column justify-content-center align-items-center p-3">
                                        <div class="mb-2 fs-4">&#10060;</div>
                                        <div class="fw-bold small">{{ __('reject') }}</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Delivery Boy Statuses (role_id: 4) - Only show Out for Pickup, Received from Customer, Return to Seller, Cancelled -->
                        <div v-else-if="login_user.role_id == 4" class="row g-2">
                            <div class="col-lg-3 col-md-4 col-sm-6 mb-2">
                                <div class="card h-100 border-2" 
                                     :class="returnRequest.status == '5' ? 'border-primary bg-primary bg-opacity-10' : 'border-light'"
                                     @click="returnRequest.status = '5'">
                                    <div class="card-body text-center d-flex flex-column justify-content-center align-items-center p-3">
                                        <div class="mb-2 fs-4">&#128666;</div>
                                        <div class="fw-bold small">{{ __('out_for_pickup') }}</div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-lg-3 col-md-4 col-sm-6 mb-2">
                                <div class="card h-100 border-2" 
                                     :class="returnRequest.status == '6' ? 'border-secondary bg-secondary bg-opacity-10' : 'border-light'"
                                     @click="returnRequest.status = '6'">
                                    <div class="card-body text-center d-flex flex-column justify-content-center align-items-center p-3">
                                        <div class="mb-2 fs-4">&#128230;</div>
                                        <div class="fw-bold small">{{ __('received_from_customer') }}</div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-lg-3 col-md-4 col-sm-6 mb-2">
                                <div class="card h-100 border-2" 
                                     :class="returnRequest.status == '8' ? 'border-dark bg-dark bg-opacity-10' : 'border-light'"
                                     @click="returnRequest.status = '8'">
                                    <div class="card-body text-center d-flex flex-column justify-content-center align-items-center p-3">
                                        <div class="mb-2 fs-4">&#127980;</div>
                                        <div class="fw-bold small">{{ __('return_to_seller') }}</div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-lg-3 col-md-4 col-sm-6 mb-2">
                                <div class="card h-100 border-2" 
                                     :class="returnRequest.status == '7' ? 'border-danger bg-danger bg-opacity-10' : 'border-light'"
                                     @click="returnRequest.status = '7'">
                                    <div class="card-body text-center d-flex flex-column justify-content-center align-items-center p-3">
                                        <div class="mb-2 fs-4">&#128683;</div>
                                        <div class="fw-bold small">{{ __('cancelled') }}</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <!-- All Other Roles (not 3 and not 4) - Show all statuses -->
                        <div v-else class="row g-2">
                            <div class="col-lg-3 col-md-4 col-sm-6 mb-2">
                                <div class="card h-100 border-2" 
                                     :class="returnRequest.status == '1' ? 'border-warning bg-warning bg-opacity-10' : 'border-light'"
                                     @click="returnRequest.status = '1'">
                                    <div class="card-body text-center d-flex flex-column justify-content-center align-items-center p-3">
                                        <div class="mb-2 fs-4">&#8635;</div>
                                        <div class="fw-bold small">{{ __('pending') }}</div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-lg-3 col-md-4 col-sm-6 mb-2">
                                <div class="card h-100 border-2" 
                                     :class="returnRequest.status == '4' ? 'border-info bg-info bg-opacity-10' : 'border-light'"
                                     @click="returnRequest.status = '4'">
                                    <div class="card-body text-center d-flex flex-column justify-content-center align-items-center p-3">
                                        <div class="mb-2 fs-4">&#128100;</div>
                                        <div class="fw-bold small">{{ __('delivery_boy_assigned') }}</div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-lg-3 col-md-4 col-sm-6 mb-2">
                                <div class="card h-100 border-2" 
                                     :class="returnRequest.status == '5' ? 'border-primary bg-primary bg-opacity-10' : 'border-light'"
                                     @click="returnRequest.status = '5'">
                                    <div class="card-body text-center d-flex flex-column justify-content-center align-items-center p-3">
                                        <div class="mb-2 fs-4">&#128666;</div>
                                        <div class="fw-bold small">{{ __('out_for_pickup') }}</div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-lg-3 col-md-4 col-sm-6 mb-2">
                                <div class="card h-100 border-2" 
                                     :class="returnRequest.status == '6' ? 'border-secondary bg-secondary bg-opacity-10' : 'border-light'"
                                     @click="returnRequest.status = '6'">
                                    <div class="card-body text-center d-flex flex-column justify-content-center align-items-center p-3">
                                        <div class="mb-2 fs-4">&#128230;</div>
                                        <div class="fw-bold small">{{ __('received_from_customer') }}</div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-lg-3 col-md-4 col-sm-6 mb-2">
                                <div class="card h-100 border-2" 
                                     :class="returnRequest.status == '8' ? 'border-dark bg-dark bg-opacity-10' : 'border-light'"
                                     @click="returnRequest.status = '8'">
                                    <div class="card-body text-center d-flex flex-column justify-content-center align-items-center p-3">
                                        <div class="mb-2 fs-4">&#127980;</div>
                                        <div class="fw-bold small">{{ __('return_to_seller') }}</div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-lg-3 col-md-4 col-sm-6 mb-2">
                                <div class="card h-100 border-2" 
                                     :class="returnRequest.status == '2' ? 'border-success bg-success bg-opacity-10' : 'border-light'"
                                     @click="returnRequest.status = '2'">
                                    <div class="card-body text-center d-flex flex-column justify-content-center align-items-center p-3">
                                        <div class="mb-2 fs-4">&#9989;</div>
                                        <div class="fw-bold small">{{ __('approve') }}</div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-lg-3 col-md-4 col-sm-6 mb-2">
                                <div class="card h-100 border-2" 
                                     :class="returnRequest.status == '3' ? 'border-danger bg-danger bg-opacity-10' : 'border-light'"
                                     @click="returnRequest.status = '3'">
                                    <div class="card-body text-center d-flex flex-column justify-content-center align-items-center p-3">
                                        <div class="mb-2 fs-4">&#10060;</div>
                                        <div class="fw-bold small">{{ __('reject') }}</div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-lg-3 col-md-4 col-sm-6 mb-2">
                                <div class="card h-100 border-2" 
                                     :class="returnRequest.status == '7' ? 'border-danger bg-danger bg-opacity-10' : 'border-light'"
                                     @click="returnRequest.status = '7'">
                                    <div class="card-body text-center d-flex flex-column justify-content-center align-items-center p-3">
                                        <div class="mb-2 fs-4">&#128683;</div>
                                        <div class="fw-bold small">{{ __('cancelled') }}</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <input type="hidden" v-model="returnRequest.order_id">

                    <!-- Show delivery boy assignment only if user is not delivery boy and status is Delivery Boy Assigned -->
                    <div class="form-group mt-4" v-if="returnRequest.status == 4 && login_user.role_id != 4">
                        <label for="delivery_boy_id" class="form-label fw-bold">{{ __('assign_delivery_boy') }} <span class="text-danger">*</span></label>
                        <select id="delivery_boy_id" name="delivery_boy_id" class="form-control form-select" v-model="returnRequest.delivery_boy_id" required>
                            <option value="">{{ __('select_delivery_boy') }}</option>
                            <option v-for="boy in deliveryBoys" :value="boy.id">{{ boy.name }}</option>
                        </select>
                    </div>

                    <!-- Show cancellation reason only if status is Cancelled -->
                    <div class="form-group mt-4" v-if="returnRequest.status == 7">
                        <label for="cancellation_reason" class="form-label fw-bold">{{ __('cancellation_reason') }} <span class="text-danger">*</span></label>
                        <textarea name="cancellation_reason" id="cancellation_reason" v-model="returnRequest.cancellation_reason" class="form-control" placeholder="Enter cancellation reason" rows="3" required></textarea>
                    </div>
                </div>
                
                <div class="col-md-12 mt-4">
                    <div class="form-group">
                        <label for="remark" class="form-label fw-bold">{{ __('remark') }}</label>
                        <textarea name="remark" id="remark" v-model="returnRequest.remark" class="form-control" placeholder="Enter Remark" rows="3"></textarea>
                    </div>
                </div>
            </div>
            <button ref="dummy_submit" style="display:none;" ></button>
        </form>
    </b-modal>
</template>

<script>
import axios from 'axios';
import Auth from '../../Auth.js';

export default {
    props: ['record'],
    data : function(){
        return {
            isLoading: false,
            login_user: Auth.user,
            deliveryBoys:'',
            delivery_boy_id:'',
            returnRequest:{
                id: this.record ? this.record.id : null ,
                status: this.record ? this.record.status : "" ,
                order_id: this.record ? this.record.order_id : "" ,
                delivery_boy_id:  this.record ? this.record.delivery_boy_id : 0 ,
                remark: this.record ? this.record.remarks : "" ,
                cancellation_reason: this.record ? this.record.cancellation_reason : "" ,
            },
        };
    },
    computed: {
        modal_title: function(){
            let title = this.returnRequest.id ? "Edit" : "Add" ;
            title += " Return Request";
            return title;
        },
    },
    methods: {
        showModal() {
            this.$refs['my-modal'].show();
            this.getOrder();
        },
        hideModal() {
            this.$refs['my-modal'].hide()
        },

        getOrder() {
            this.isLoading = true
         
            axios.get(this.$apiUrl + '/orders/view/' + this.record.order_id)
                .then((response) => {
              
                    this.isLoading = false
                    let data = response.data;
                    if (data.status === 1) {
                        this.deliveryBoys = response.data.data.deliveryBoys;
                    } else {
                        this.showError(data.message);
                        setTimeout(() => {
                            this.$router.back();
                        }, 1000);
                    }
                }).catch(error => {
                this.isLoading = false;
                if (error.request.statusText) {
                    this.showError(error.request.statusText);
                }else if (error.message) {
                    this.showError(error.message);
                } else {
                    this.showError("Something went wrong!");
                }
            });
        },

        saveRecord: function(){
            let vm = this;
            this.isLoading = true;
            let formObject = this.returnRequest;
            let formData = new FormData();
            for(let key in formObject){
                formData.append(key, formObject[key]);
            }
            
            // Determine API endpoint based on user role
            let url = this.$apiUrl + '/return_requests/update';
            if (this.login_user.role_id == 3) { // Seller
                url = this.$apiUrl + '/seller/return_request_status_update';
            } else if (this.login_user.role_id == 4) { // Delivery Boy
                url = this.$apiUrl + '/delivery_boy/return_request_status_update';
            }
            // Admin (role_id 1, 2) uses default /return_requests/update
            
            axios.post(url, formData).then(res => {
                let data = res.data;
                if (data.status === 1) {
                    this.$eventBus.$emit('returnRequestSaved', data.message);
                    this.hideModal();
                }else{
                    vm.showError(data.message);
                    vm.isLoading = false;
                }
            }).catch(error => {
                vm.isLoading = false;
                if (error.request.statusText) {
                    this.showError(error.request.statusText);
                }else if (error.message) {
                    this.showError(error.message);
                } else {
                    this.showError("Something went wrong!");
                }
            });
        }

    },
    mounted(){
        this.showModal();
    }
}
</script>
