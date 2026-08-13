<template>
    <b-modal ref="my-modal" :title="modal_title" @hidden="$emit('modalClose')" size="lg" scrollable no-close-on-backdrop no-fade static>
        <div slot="modal-footer">
            <b-button variant="primary" @click="$refs['dummy_submit'].click()" :disabled="isLoading">Save
                <b-spinner v-if="isLoading" small label="Spinning"></b-spinner>
            </b-button>
            <b-button variant="secondary" @click="hideModal">Cancel</b-button>
        </div>
        <form ref="my-form" @submit.prevent="saveRecord">
            <div class="row">
                <!-- Profile Image -->
                <div class="col-md-12 mb-3">
                    <div class="form-group text-center">
                        <label for="profile_image">Profile Image</label>
                        <input type="file" name="profile_image" id="profile_image" v-on:change="handleFileUploadProfile" ref="file_profile" class="file-input" accept="image/*" />
                        <div class="file-input-div bg-gray-100" @click="$refs.file_profile.click()" style="max-width: 200px; margin: 0 auto;">
                            <template v-if="deliveryBoys.profile_image_url">
                                <img class="custom-image" :src="deliveryBoys.profile_image_url" style="max-width: 150px; max-height: 150px;" />
                            </template>
                            <template v-else>
                                <label><i class="fa fa-user-circle fa-4x"></i></label>
                                <label>{{ __('click_to_upload') }}</label>
                            </template>
                        </div>
                    </div>
                </div>

                <!-- Name -->
                <div class="col-md-6">
                    <div class="form-group">
                        <label for="name">Name <span class="text-danger">*</span></label>
                        <input type="text" name="name" id="name" v-model="deliveryBoys.name" class="form-control" placeholder="Enter name" required>
                    </div>
                </div>

                <!-- Email -->
                <div class="col-md-6">
                    <div class="form-group">
                        <label for="email">Email</label>
                        <input type="email" name="email" id="email" v-model="deliveryBoys.email" class="form-control" placeholder="Enter email">
                    </div>
                </div>

                <!-- Date of Birth -->
                <div class="col-md-6">
                    <div class="form-group">
                        <label for="dob">Date Of Birth</label>
                        <input type="date" name="dob" id="dob" v-model="deliveryBoys.dob" class="form-control" placeholder="Enter date of birth" @input="validateDateOfBirth">
                        <span v-if="dobError" class="text-danger small">{{ dobError }}</span>
                    </div>
                </div>

                <!-- City -->
                <div class="col-md-6">
                    <div class="form-group">
                        <label for="city_name">City <span class="text-danger">*</span></label>
                        <multiselect v-model="city"
                                     :options="cities"
                                     @select="onCitySelect"
                                     placeholder="Select & Search City"
                                     label="name"
                                     track-by="id" id="city_name" required>
                            <template slot="singleLabel" slot-scope="props">
                                <span class="option__title">{{ props.option.name }}</span>
                            </template>
                            <template slot="option" slot-scope="props">
                                <div class="option__desc">
                                    <span class="option__title">{{ props.option.formatted_address }}</span>
                                </div>
                            </template>
                        </multiselect>
                    </div>
                </div>

                <!-- Address -->
                <div class="col-md-6">
                    <div class="form-group">
                        <label for="address">Address <span class="text-danger">*</span></label>
                        <textarea name="address" id="address" v-model="deliveryBoys.address" rows="3" class="form-control" placeholder="Enter address" required></textarea>
                    </div>
                </div>

                <!-- Latitude & Longitude -->
                <div class="col-md-3">
                    <div class="form-group">
                        <label for="latitude">Latitude</label>
                        <input type="number" step="any" name="latitude" id="latitude" v-model="deliveryBoys.latitude" class="form-control" placeholder="e.g. 19.0760">
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="form-group">
                        <label for="longitude">Longitude</label>
                        <input type="number" step="any" name="longitude" id="longitude" v-model="deliveryBoys.longitude" class="form-control" placeholder="e.g. 72.8777">
                    </div>
                </div>

                <!-- Vehicle -->
                <div class="col-md-6">
                    <div class="form-group">
                        <label for="vehicle_id">Vehicle</label>
                        <multiselect v-model="vehicle"
                                     :options="vehicles"
                                     @select="onVehicleSelect"
                                     placeholder="Select Vehicle"
                                     label="name"
                                     track-by="id" id="vehicle_id">
                            <template slot="singleLabel" slot-scope="props">
                                <img v-if="props.option.image_url" :src="props.option.image_url" style="width: 24px; height: 24px; margin-right: 8px;">
                                <span class="option__title">{{ props.option.name }}</span>
                            </template>
                            <template slot="option" slot-scope="props">
                                <div class="option__desc d-flex align-items-center">
                                    <img v-if="props.option.image_url" :src="props.option.image_url" style="width: 32px; height: 32px; margin-right: 8px;">
                                    <span class="option__title">{{ props.option.name }}</span>
                                </div>
                            </template>
                        </multiselect>
                    </div>
                </div>

                <!-- Store Locations (Multi-select) -->
                <div class="col-md-6">
                    <div class="form-group">
                        <label for="store_locations">Store Locations</label>
                        <multiselect v-model="selectedStoreLocations"
                                     :options="storeLocations"
                                     :multiple="true"
                                     :close-on-select="false"
                                     :clear-on-select="false"
                                     :preserve-search="true"
                                     placeholder="Select Store Locations"
                                     label="name"
                                     track-by="id" id="store_locations">
                            <template slot="tag" slot-scope="{ option, remove }">
                                <span class="multiselect__tag">
                                    <span>{{ option.name }}</span>
                                    <i class="multiselect__tag-icon" @click="remove(option)"></i>
                                </span>
                            </template>
                            <template slot="option" slot-scope="props">
                                <div class="option__desc">
                                    <span class="option__title">{{ props.option.name }}</span>
                                    <span class="option__small text-muted"> - {{ props.option.address }}</span>
                                </div>
                            </template>
                        </multiselect>
                    </div>
                </div>

                <!-- Driving License -->
                <div class="col-md-6">
                    <div class="form-group">
                        <label for="driving_license">Driving License</label>
                        <input type="file" name="driving_license" id="driving_license" v-on:change="handleFileUploadLicense" ref="file_license" class="file-input" />
                        <div class="file-input-div bg-gray-100" @click="$refs.file_license.click()" @drop="dropFileUploadLicense" @dragover="$dragoverFile" @dragleave="$dragleaveFile">
                            <template v-if="deliveryBoys.driving_license && deliveryBoys.driving_license.name">
                                <label>Selected: {{ deliveryBoys.driving_license.name }}</label>
                            </template>
                            <template v-else>
                                <label><i class="fa fa-cloud-upload-alt fa-2x"></i></label>
                                <label>{{ __('drop_files_here_or_click_to_upload') }}</label>
                            </template>
                        </div>
                        <div class="row mt-2" v-if="deliveryBoys.driving_license_url">
                            <div v-if="isImage(deliveryBoys.driving_license_url)" class="col-md-3">
                                <img class="custom-image" :src="deliveryBoys.driving_license_url" title="Driving License" alt="Driving License"/>
                            </div>
                            <div v-else class="col-md-3">
                                <a target="_blank" :href="deliveryBoys.driving_license_url" class="badge bg-success"><i class="fa fa-eye"></i> View</a>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- National Identity Card -->
                <div class="col-md-6">
                    <div class="form-group">
                        <label for="national_identity_card">National Identity Card</label>
                        <input type="file" name="national_identity_card" id="national_identity_card" v-on:change="handleFileUploadCard" ref="file_card" class="file-input" />
                        <div class="file-input-div bg-gray-100" @click="$refs.file_card.click()" @drop="dropFileUploadCard" @dragover="$dragoverFile" @dragleave="$dragleaveFile">
                            <template v-if="deliveryBoys.national_identity_card && deliveryBoys.national_identity_card.name">
                                <label>Selected: {{ deliveryBoys.national_identity_card.name }}</label>
                            </template>
                            <template v-else>
                                <label><i class="fa fa-cloud-upload-alt fa-2x"></i></label>
                                <label>{{ __('drop_files_here_or_click_to_upload') }}</label>
                            </template>
                        </div>
                        <div class="row mt-2" v-if="deliveryBoys.national_identity_card_url">
                            <div v-if="isImage(deliveryBoys.national_identity_card_url)" class="col-md-3">
                                <img class="custom-image" :src="deliveryBoys.national_identity_card_url" title="National Identity Card" alt="National Identity Card"/>
                            </div>
                            <div v-else class="col-md-3">
                                <a target="_blank" :href="deliveryBoys.national_identity_card_url" class="badge bg-success"><i class="fa fa-eye"></i> View</a>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Bank Details Section -->
                <div class="col-md-12 mt-3">
                    <h5 class="border-bottom pb-2">Bank Details</h5>
                </div>

                <!-- Bank Name -->
                <div class="col-md-6">
                    <div class="form-group">
                        <label for="bank_name">Bank Name</label>
                        <input type="text" name="bank_name" id="bank_name" v-model="deliveryBoys.bank_name" class="form-control" placeholder="Enter bank name">
                    </div>
                </div>

                <!-- Account Holder Name -->
                <div class="col-md-6">
                    <div class="form-group">
                        <label for="account_name">Account Holder Name</label>
                        <input type="text" name="account_name" id="account_name" v-model="deliveryBoys.account_name" class="form-control" placeholder="Enter account holder name">
                    </div>
                </div>

                <!-- Account Number -->
                <div class="col-md-6">
                    <div class="form-group">
                        <label for="bank_account_number">Account Number</label>
                        <input type="text" name="bank_account_number" id="bank_account_number" v-model="deliveryBoys.bank_account_number" class="form-control" placeholder="Enter account number">
                    </div>
                </div>

                <!-- IFSC Code -->
                <div class="col-md-6">
                    <div class="form-group">
                        <label for="ifsc_code">IFSC Code</label>
                        <input type="text" name="ifsc_code" id="ifsc_code" v-model="deliveryBoys.ifsc_code" class="form-control" placeholder="Enter IFSC code">
                    </div>
                </div>

                <!-- Other Payment Information -->
                <div class="col-md-12">
                    <div class="form-group">
                        <label for="other_payment_info">Other Payment Information</label>
                        <textarea name="other_payment_info" id="other_payment_info" v-model="deliveryBoys.other_payment_information" rows="2" class="form-control" placeholder="e.g. UPI ID, PayTM number"></textarea>
                    </div>
                </div>
            </div>
            <button ref="dummy_submit" style="display:none;"></button>
        </form>
    </b-modal>
</template>

<script>
import axios from 'axios';
import Multiselect from "vue-multiselect";

export default {
    props: ['record'],
    components: {
        Multiselect,
    },
    data: function() {
        return {
            isLoading: false,
            dobError: null,

            // Dropdown data
            city: null,
            cities: [],
            vehicle: null,
            vehicles: [],
            selectedStoreLocations: [],
            storeLocations: [],

            // Form data
            deliveryBoys: {
                id: this.record ? this.record.id : null,
                admin_id: this.record ? this.record.admin_id : null,
                name: this.record ? this.record.name : "",
                email: this.record ? (this.record.email || (this.record.admin ? this.record.admin.email : "")) : "",
                dob: this.record ? this.record.dob : "",
                address: this.record ? this.record.address : "",
                latitude: this.record ? this.record.latitude : "",
                longitude: this.record ? this.record.longitude : "",
                city_id: this.record ? this.record.city_id : "",
                vehicle_id: this.record ? this.record.vehicle_id : "",
                profile_image: "",
                profile_image_url: this.record ? this.record.profile_image_url : "",
                driving_license: "",
                driving_license_url: this.record && this.record.driving_license ? this.$mediaUrl(this.record.driving_license) : "",
                national_identity_card: "",
                national_identity_card_url: this.record && this.record.national_identity_card ? this.$mediaUrl(this.record.national_identity_card) : "",
                bank_name: this.record ? this.record.bank_name : "",
                account_name: this.record ? this.record.account_name : "",
                bank_account_number: this.record ? this.record.bank_account_number : "",
                ifsc_code: this.record ? this.record.ifsc_code : "",
                other_payment_information: this.record ? this.record.other_payment_information : "",
            }
        };
    },
    created: function() {
        this.getCities();
        this.getVehicles();
        this.getStoreLocations();
    },
    computed: {
        modal_title: function() {
            let title = this.deliveryBoys.id ? "Edit" : "Add";
            title += " Delivery Boy";
            return title;
        },
    },
    methods: {
        showModal() {
            this.$refs['my-modal'].show();
        },
        hideModal() {
            this.$refs['my-modal'].hide();
        },

        // File upload handlers
        handleFileUploadProfile() {
            this.deliveryBoys.profile_image = this.$refs.file_profile.files[0];
            this.deliveryBoys.profile_image_url = URL.createObjectURL(this.deliveryBoys.profile_image);
        },
        handleFileUploadLicense() {
            this.deliveryBoys.driving_license = this.$refs.file_license.files[0];
            this.deliveryBoys.driving_license_url = URL.createObjectURL(this.deliveryBoys.driving_license);
        },
        dropFileUploadLicense(event) {
            event.preventDefault();
            this.$refs.file_license.files = event.dataTransfer.files;
            this.handleFileUploadLicense();
            event.currentTarget.classList.add('bg-gray-100');
            event.currentTarget.classList.remove('bg-green-300');
        },
        handleFileUploadCard() {
            this.deliveryBoys.national_identity_card = this.$refs.file_card.files[0];
            this.deliveryBoys.national_identity_card_url = URL.createObjectURL(this.deliveryBoys.national_identity_card);
        },
        dropFileUploadCard(event) {
            event.preventDefault();
            this.$refs.file_card.files = event.dataTransfer.files;
            this.handleFileUploadCard();
            event.currentTarget.classList.add('bg-gray-100');
            event.currentTarget.classList.remove('bg-green-300');
        },

        // Validation
        validateDateOfBirth() {
            const selectedDate = new Date(this.deliveryBoys.dob);
            const currentDate = new Date();
            if (selectedDate > currentDate) {
                this.dobError = "Date of Birth cannot be in the future.";
            } else {
                this.dobError = null;
            }
        },

        // Fetch data
        getCities() {
            axios.get(this.$apiUrl + '/cities')
                .then((response) => {
                    this.cities = response.data.data;
                    if (this.deliveryBoys.city_id) {
                        this.city = this.cities.find(item => item.id === this.deliveryBoys.city_id);
                    }
                });
        },
        getVehicles() {
            axios.get(this.$apiUrl + '/vehicles')
                .then((response) => {
                    this.vehicles = response.data.data;
                    if (this.deliveryBoys.vehicle_id) {
                        this.vehicle = this.vehicles.find(item => item.id === this.deliveryBoys.vehicle_id);
                    }
                });
        },
        getStoreLocations() {
            axios.get(this.$apiUrl + '/store_locations')
                .then((response) => {
                    this.storeLocations = response.data.data;
                    // Set selected store locations if editing
                    if (this.record && this.record.store_locations) {
                        const selectedIds = this.record.store_locations.map(sl => sl.id);
                        this.selectedStoreLocations = this.storeLocations.filter(sl => selectedIds.includes(sl.id));
                    }
                });
        },

        // Select handlers
        onCitySelect(selectedCity) {
            this.deliveryBoys.city_id = selectedCity ? selectedCity.id : "";
        },
        onVehicleSelect(selectedVehicle) {
            this.deliveryBoys.vehicle_id = selectedVehicle ? selectedVehicle.id : "";
        },

        // Save
        saveRecord: function() {
            let vm = this;
            this.isLoading = true;

            let formData = new FormData();

            // Basic fields
            if (this.deliveryBoys.id) formData.append('id', this.deliveryBoys.id);
            if (this.deliveryBoys.admin_id) formData.append('admin_id', this.deliveryBoys.admin_id);
            formData.append('name', this.deliveryBoys.name || '');
            formData.append('email', this.deliveryBoys.email || '');
            formData.append('dob', this.deliveryBoys.dob || '');
            formData.append('address', this.deliveryBoys.address || '');
            formData.append('latitude', this.deliveryBoys.latitude || '');
            formData.append('longitude', this.deliveryBoys.longitude || '');
            formData.append('city_id', this.deliveryBoys.city_id || '');
            formData.append('vehicle_id', this.deliveryBoys.vehicle_id || '');

            // Store location IDs (array)
            const storeLocationIds = this.selectedStoreLocations.map(sl => sl.id);
            storeLocationIds.forEach((id) => {
                formData.append('store_location_ids[]', id);
            });

            // Bank details
            formData.append('bank_name', this.deliveryBoys.bank_name || '');
            formData.append('account_name', this.deliveryBoys.account_name || '');
            formData.append('bank_account_number', this.deliveryBoys.bank_account_number || '');
            formData.append('ifsc_code', this.deliveryBoys.ifsc_code || '');
            formData.append('other_payment_information', this.deliveryBoys.other_payment_information || '');

            // Files
            if (this.deliveryBoys.profile_image) {
                formData.append('profile_image', this.deliveryBoys.profile_image);
            }
            if (this.deliveryBoys.driving_license) {
                formData.append('driving_license', this.deliveryBoys.driving_license);
            }
            if (this.deliveryBoys.national_identity_card) {
                formData.append('national_identity_card', this.deliveryBoys.national_identity_card);
            }

            let url = this.$apiUrl + '/delivery_boys/save';
            if (this.deliveryBoys.id) {
                url = this.$apiUrl + '/delivery_boys/update';
            }

            axios.post(url, formData, {
                headers: {
                    'Content-Type': 'multipart/form-data'
                }
            }).then(res => {
                let data = res.data;
                if (data.status === 1) {
                    this.$eventBus.$emit('deliveryBoysSaved', data.message);
                    this.hideModal();
                } else {
                    vm.showError(data.message);
                    vm.isLoading = false;
                }
            }).catch(error => {
                vm.isLoading = false;
                if (error.request.statusText) {
                    this.showError(error.request.statusText);
                } else if (error.message) {
                    this.showError(error.message);
                } else {
                    this.showError("Something went wrong!");
                }
            });
        }
    },
    mounted() {
        this.showModal();
    }
}
</script>

<style scoped>
@import "../../../../node_modules/vue-multiselect/dist/vue-multiselect.min.css";
</style>
