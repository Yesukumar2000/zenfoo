<template>
    <div>
        <div class="page-heading">

            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3 v-if="this.$roleDeliveryBoy === this.login_user.role.name" >
                        {{ __('my_profile') }}
                    </h3>
                    <h3 v-else>
                        <template v-if="id">{{ __('edit') }}</template>
                        <template v-else>{{ __('create') }}</template>
                        {{ __('delivery_boy') }}
                    </h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">

                                <router-link to="/delivery_boy" v-if="this.$roleDeliveryBoy === this.login_user.role.name" >{{ __('dashboard') }}</router-link>
                                <router-link to="/dashboard" v-else >{{ __('dashboard') }}</router-link>
                            </li>
                            <template v-if="this.$roleDeliveryBoy === this.login_user.role.name">
                                <li class="breadcrumb-item" aria-current="page">{{ __('my_profile') }}</li>
                            </template>
                            
                            <template v-else>

                                <li class="breadcrumb-item" aria-current="page">
                                    <router-link to="/delivery_boys">{{ __('manage_delivery_boy') }}</router-link>
                                </li>

                                <li class="breadcrumb-item active" aria-current="page">
                                    <template v-if="id">{{ __('edit') }}</template>
                                    <template v-else>{{ __('create') }}</template>
                                    {{ __('delivery_boy') }}
                                </li>
                            </template>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3" v-if="this.$roleDeliveryBoy !== this.login_user.role.name">
                <div class="col-12">
                    <router-link to="/delivery_boys" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <div class="row">
                <div class="col-12 col-md-12 order-md-1 order-last">
                    <form ref="my-form" @submit.prevent="saveRecord">
                    <div class="card">
                        <div class="card-header" v-if="this.$roleDeliveryBoy !== this.login_user.role.name">
                            <h4>{{ __('delivery_boy') }}</h4>
                            <span class="pull-right">
                                <router-link to="/delivery_boys" class="btn btn-primary" v-b-tooltip.hover  title="View Delivery boys">{{ __('view_delivery_boys') }}</router-link>
                            </span>
                        </div>
                        <div class="card-body">
                        <label><span class="text-danger text-xs">*</span> {{ __('required_fields') }}</label>
                        <div class="divider"><div class="divider-text">{{ __('new_delivery_boy_register_form') }}</div></div>
                        <div class="row">
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="name">{{ __('name') }}<span class="text-danger text-xs">*</span></label>
                                    <input type="text" name="name" id="name" v-model="deliveryBoys.name" required class="form-control" placeholder="Enter name.">
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="dob">{{ __('date_of_birth') }} <span class="text-danger text-xs">*</span></label>
                                    <input type="date" name="dob" id="dob" v-model="deliveryBoys.dob" class="form-control" placeholder="Enter date of birth" @input="validateDateOfBirth">
                                    <span v-if="dobvalidationError" class="error">{{ dobvalidationError }}</span>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="mobile">{{ __('mobile') }}<span class="text-danger text-xs">*</span></label>
                                    <input type="number" name="mobile" id="mobile" v-model="deliveryBoys.mobile" class="form-control" placeholder="Enter mobile no." @input="validateMobileNumber">
                                    <span v-if="mobilevalidationError" class="error">{{ mobilevalidationError }}</span>
                                </div>
                            </div>

                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="email">{{ __('email') }}</label>
                                    <input type="text" name="email" id="email" v-model="deliveryBoys.email" class="form-control" placeholder="Enter email id.">
                                </div>
                            </div>

                            <div class="col-md-4">
                                <label for="city_name"> Select Or Search Zone<span class="text-danger text-xs">*</span></label>
                                <multiselect v-model="city"
                                             :options="cities"
                                             @close="setCityId"
                                             placeholder="Select & Search Zone"
                                             label="name"
                                             track-by="name" id="city_name" required>
                                    <template slot="singleLabel" slot-scope="props">
                                                        <span class="option__desc">
                                                            <span class="option__title">{{ props.option.name }}</span>
                                                        </span>
                                    </template>
                                    <template slot="option" slot-scope="props">
                                        <div class="option__desc">
                                                            <span class="option__title">{{
                                                                    props.option.formatted_address
                                                                }}</span>
                                        </div>
                                    </template>
                                </multiselect>
                            </div>

                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="vehicle_id">Vehicle</label>
                                    <select name="vehicle_id" id="vehicle_id" v-model="deliveryBoys.vehicle_id" class="form-control form-select">
                                        <option value="">Select</option>
                                        <option v-for="vehicle in vehicles" :key="vehicle.id" :value="vehicle.id">{{ vehicle.name }}</option>
                                    </select>
                                </div>
                            </div>

                            <div class="col-md-12">
                                <div class="form-group">
                                    <label for="google_address">Search Location (Google Maps)</label>
                                    <input
                                        type="text"
                                        id="google_address"
                                        ref="google_address"
                                        class="form-control"
                                        placeholder="Search for a location..."
                                    />
                                    <small class="text-muted">Search and select a location to auto-fill address, latitude, and longitude</small>
                                </div>
                            </div>

                            <div class="col-md-12">
                                <div class="form-group">
                                    <label for="address"> {{ __('address') }}<span class="text-danger text-xs">*</span></label>
                                    <textarea name="address" id="address" v-model="deliveryBoys.address" rows='3' class="form-control" placeholder="Enter address"></textarea>
                                </div>
                            </div>

                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="latitude">Latitude</label>
                                    <input type="number" step="any" name="latitude" id="latitude" v-model="deliveryBoys.latitude" class="form-control" placeholder="Enter latitude" readonly>
                                </div>
                            </div>

                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="longitude">Longitude</label>
                                    <input type="number" step="any" name="longitude" id="longitude" v-model="deliveryBoys.longitude" class="form-control" placeholder="Enter longitude" readonly>
                                </div>
                            </div>

                            <div class="col-md-4">
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
                                    </multiselect>
                                </div>
                            </div>

                            <!-- Profile Image -->
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="profile_image">Profile Image</label>
                                    <input type="file" accept="image/*" name="profile_image" id="profile_image" @change="handleFileUpload('profile_image', 'profile_image')" ref="profile_image" class="form-control" />
                                    <div class="row mt-2" v-if="deliveryBoys.profile_image_url">
                                        <div class="col-md-6">
                                            <img class="custom-image" :src="deliveryBoys.profile_image_url" title='Profile Image' alt='Profile Image' style="max-width: 100%; height: auto;"/>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Bank Details Section -->
                            <div class="col-md-12 mt-3">
                                <div class="divider"><div class="divider-text">Bank Details</div></div>
                            </div>

                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="bank_name">Bank Name</label>
                                    <input type="text" name="bank_name" id="bank_name" v-model="deliveryBoys.bank_name" class="form-control" placeholder="Enter bank name">
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="account_holder_name">Account Holder Name</label>
                                    <input type="text" name="account_holder_name" id="account_holder_name" v-model="deliveryBoys.account_holder_name" class="form-control" placeholder="Enter account holder name">
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="account_number">Account Number</label>
                                    <input type="text" name="account_number" id="account_number" v-model="deliveryBoys.account_number" class="form-control" placeholder="Enter account number" @input="validateAccountNumber">
                                    <span v-if="account_numbervalidationError" class="error">{{ account_numbervalidationError }}</span>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="ifsc_code">IFSC Code</label>
                                    <input type="text" name="ifsc_code" id="ifsc_code" v-model="deliveryBoys.ifsc_code" class="form-control" placeholder="Enter bank's IFSC code">
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="bank_passbook_image">Bank Passbook Image</label>
                                    <input type="file" accept="image/*" name="bank_passbook_image" id="bank_passbook_image" @change="handleFileUpload('bank_passbook_image', 'bank_passbook_image')" ref="bank_passbook_image" class="form-control" />
                                    <div class="row mt-2" v-if="deliveryBoys.bank_passbook_image_url">
                                        <div class="col-md-6">
                                            <img class="custom-image" :src="deliveryBoys.bank_passbook_image_url" title='Bank Passbook' alt='Bank Passbook' style="max-width: 100%; height: auto;"/>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Documents Section -->
                            <div class="col-md-12 mt-3">
                                <div class="divider"><div class="divider-text">Documents</div></div>
                            </div>

                            <!-- Driving License -->
                            <div class="col-md-12 mt-2">
                                <h6>Driving License</h6>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="driving_license_number">Driving License Number</label>
                                    <input type="text" name="driving_license_number" id="driving_license_number" v-model="deliveryBoys.driving_license_number" class="form-control" placeholder="Enter driving license number">
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="driving_license_front">Driving License Front</label>
                                    <input type="file" accept="image/*" name="driving_license_front" id="driving_license_front" @change="handleFileUpload('driving_license_front', 'driving_license_front')" ref="driving_license_front" class="form-control" />
                                    <div class="row mt-2" v-if="deliveryBoys.driving_license_front_url">
                                        <div class="col-md-6">
                                            <img class="custom-image" :src="deliveryBoys.driving_license_front_url" title='DL Front' alt='DL Front' style="max-width: 100%; height: auto;"/>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="driving_license_back">Driving License Back</label>
                                    <input type="file" accept="image/*" name="driving_license_back" id="driving_license_back" @change="handleFileUpload('driving_license_back', 'driving_license_back')" ref="driving_license_back" class="form-control" />
                                    <div class="row mt-2" v-if="deliveryBoys.driving_license_back_url">
                                        <div class="col-md-6">
                                            <img class="custom-image" :src="deliveryBoys.driving_license_back_url" title='DL Back' alt='DL Back' style="max-width: 100%; height: auto;"/>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- RC (Registration Certificate) -->
                            <div class="col-md-12 mt-2">
                                <h6>RC (Registration Certificate)</h6>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="rc_number">RC Number</label>
                                    <input type="text" name="rc_number" id="rc_number" v-model="deliveryBoys.rc_number" class="form-control" placeholder="Enter RC number">
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="rc_front">RC Front</label>
                                    <input type="file" accept="image/*" name="rc_front" id="rc_front" @change="handleFileUpload('rc_front', 'rc_front')" ref="rc_front" class="form-control" />
                                    <div class="row mt-2" v-if="deliveryBoys.rc_front_url">
                                        <div class="col-md-6">
                                            <img class="custom-image" :src="deliveryBoys.rc_front_url" title='RC Front' alt='RC Front' style="max-width: 100%; height: auto;"/>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="rc_back">RC Back</label>
                                    <input type="file" accept="image/*" name="rc_back" id="rc_back" @change="handleFileUpload('rc_back', 'rc_back')" ref="rc_back" class="form-control" />
                                    <div class="row mt-2" v-if="deliveryBoys.rc_back_url">
                                        <div class="col-md-6">
                                            <img class="custom-image" :src="deliveryBoys.rc_back_url" title='RC Back' alt='RC Back' style="max-width: 100%; height: auto;"/>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Aadhar -->
                            <div class="col-md-12 mt-2">
                                <h6>Aadhar Card</h6>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="aadhar_number">Aadhar Number</label>
                                    <input type="text" name="aadhar_number" id="aadhar_number" v-model="deliveryBoys.aadhar_number" class="form-control" placeholder="Enter Aadhar number" maxlength="12">
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="aadhar_front">Aadhar Front</label>
                                    <input type="file" accept="image/*" name="aadhar_front" id="aadhar_front" @change="handleFileUpload('aadhar_front', 'aadhar_front')" ref="aadhar_front" class="form-control" />
                                    <div class="row mt-2" v-if="deliveryBoys.aadhar_front_url">
                                        <div class="col-md-6">
                                            <img class="custom-image" :src="deliveryBoys.aadhar_front_url" title='Aadhar Front' alt='Aadhar Front' style="max-width: 100%; height: auto;"/>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="aadhar_back">Aadhar Back</label>
                                    <input type="file" accept="image/*" name="aadhar_back" id="aadhar_back" @change="handleFileUpload('aadhar_back', 'aadhar_back')" ref="aadhar_back" class="form-control" />
                                    <div class="row mt-2" v-if="deliveryBoys.aadhar_back_url">
                                        <div class="col-md-6">
                                            <img class="custom-image" :src="deliveryBoys.aadhar_back_url" title='Aadhar Back' alt='Aadhar Back' style="max-width: 100%; height: auto;"/>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- PAN Card -->
                            <div class="col-md-12 mt-2">
                                <h6>PAN Card</h6>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="pan_number">PAN Number</label>
                                    <input type="text" name="pan_number" id="pan_number" v-model="deliveryBoys.pan_number" class="form-control" placeholder="Enter PAN number" maxlength="10">
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="pan_front">PAN Front</label>
                                    <input type="file" accept="image/*" name="pan_front" id="pan_front" @change="handleFileUpload('pan_front', 'pan_front')" ref="pan_front" class="form-control" />
                                    <div class="row mt-2" v-if="deliveryBoys.pan_front_url">
                                        <div class="col-md-6">
                                            <img class="custom-image" :src="deliveryBoys.pan_front_url" title='PAN Front' alt='PAN Front' style="max-width: 100%; height: auto;"/>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="pan_back">PAN Back</label>
                                    <input type="file" accept="image/*" name="pan_back" id="pan_back" @change="handleFileUpload('pan_back', 'pan_back')" ref="pan_back" class="form-control" />
                                    <div class="row mt-2" v-if="deliveryBoys.pan_back_url">
                                        <div class="col-md-6">
                                            <img class="custom-image" :src="deliveryBoys.pan_back_url" title='PAN Back' alt='PAN Back' style="max-width: 100%; height: auto;"/>
                                        </div>
                                    </div>
                                </div>
                            </div>

                        </div>


                        </div>
                        <div class="card-footer">
                            <template v-if="deliveryBoys.id">
                                <b-button type="submit" variant="primary" :disabled="isLoading"> {{ __('update') }}
                                    <b-spinner v-if="isLoading" small label="Spinning"></b-spinner>
                                </b-button>
                            </template>
                            <template v-else>
                                <b-button type="submit" variant="primary" :disabled="isLoading">{{ __('save') }}
                                    <b-spinner v-if="isLoading" small label="Spinning"></b-spinner>
                                </b-button>

                                <button v-if="this.$roleDeliveryBoy !== this.login_user.role.name" type="reset" class="btn btn-danger">{{ __('clear') }}</button>
                                <button v-else type="button" class="btn btn-danger" @click="$router.go(-1)">{{ __('back') }}</button>
                            </template>
                        </div>
                    </div>
                    </form>
                </div>
            </div>
        </div>


    </div>
</template>
<script>
import {VuejsDatatableFactory} from 'vuejs-datatable';
import axios from "axios";
import Select2 from 'v-select2-component';
import Multiselect from 'vue-multiselect';

import Auth from '../../Auth.js';

export default {
    components: {
        VuejsDatatableFactory,
        Select2,
        Multiselect,
    },
    data: function () {
        return {
            login_user: Auth.user,

            isLoading: false,

            record:null,
            city: "",
            cities: [],
            id: null,
            deliveryBoys:{
                id: null ,
                admin_id: "",

                name: "",
                dob: "",
                mobile: "",
                email: "",

                // Profile and location
                profile_image: null,
                profile_image_url: "",
                latitude: "",
                longitude: "",

                // Bank details
                ifsc_code: "",
                bank_name: "",
                account_number: "",
                account_holder_name: "",
                bank_passbook_image: null,
                bank_passbook_image_url: "",

                city_id: "",
                vehicle_id: "",
                address: "",

                // Driving License
                driving_license_number: "",
                driving_license_front: null,
                driving_license_front_url: "",
                driving_license_back: null,
                driving_license_back_url: "",

                // RC (Registration Certificate)
                rc_number: "",
                rc_front: null,
                rc_front_url: "",
                rc_back: null,
                rc_back_url: "",

                // Aadhar
                aadhar_number: "",
                aadhar_front: null,
                aadhar_front_url: "",
                aadhar_back: null,
                aadhar_back_url: "",

                // PAN
                pan_number: "",
                pan_front: null,
                pan_front_url: "",
                pan_back: null,
                pan_back_url: "",
            },

            selectedStoreLocations: [],
            vehicles: [],
            storeLocations: [],
            mobilevalidationError: null,
            dobvalidationError: null,
            account_numbervalidationError: null,
            googleMapsApiKey: 'AIzaSyDLVwCSkXWOjo49WNNwx7o0DSwomoFvbP0',
            autocomplete: null
        };
    },
    created: function () {

        this.id = this.$route.params.id;
        if(this.$roleDeliveryBoy === this.login_user.role.name){
            this.id = this.login_user.delivery_boy.id;
        }
        if (this.id) {
            this.deliveryBoys.id = this.id;
            this.getDeliveryBoy();
        }
        this.getCities();
        this.getVehicles();
        this.getStoreLocations();
        this.loadGoogleMapsScript();
    },
    mounted() {
        // Google Maps autocomplete will be initialized after script loads
    },
    methods: {
        loadGoogleMapsScript() {
            // Check if script already loaded
            if (window.google && window.google.maps) {
                this.initAutocomplete();
                return;
            }

            // Load Google Maps script
            const script = document.createElement('script');
            script.src = `https://maps.googleapis.com/maps/api/js?key=${this.googleMapsApiKey}&libraries=places`;
            script.async = true;
            script.defer = true;
            script.onload = () => {
                this.initAutocomplete();
            };
            document.head.appendChild(script);
        },
        initAutocomplete() {
            this.$nextTick(() => {
                if (!this.$refs.google_address) return;

                this.autocomplete = new window.google.maps.places.Autocomplete(
                    this.$refs.google_address,
                    {
                        types: ['establishment', 'geocode'],
                        fields: ['formatted_address', 'geometry', 'name', 'address_components']
                    }
                );

                this.autocomplete.addListener('place_changed', this.handlePlaceSelect);
            });
        },
        handlePlaceSelect() {
            const place = this.autocomplete.getPlace();

            if (!place.geometry) {
                this.showError("No details available for the selected location");
                return;
            }

            // Set address
            this.deliveryBoys.address = place.formatted_address || '';

            // Set latitude and longitude
            this.deliveryBoys.latitude = place.geometry.location.lat();
            this.deliveryBoys.longitude = place.geometry.location.lng();
        },
        handleFileUpload(fieldName, refName) {
            const file = this.$refs[refName].files[0];
            if (!file) return;

            // Validate file type
            const validTypes = ['image/jpeg', 'image/png', 'image/jpg', 'image/gif', 'image/webp'];
            if (!validTypes.includes(file.type)) {
                this.showError("Invalid file type. Please upload a JPEG, PNG, JPG, GIF, or WEBP image.");
                return;
            }

            // Validate file size (5MB max)
            const maxSize = 5 * 1024 * 1024;
            if (file.size > maxSize) {
                this.showError("File size exceeds the maximum allowed limit (5MB).");
                return;
            }

            this.deliveryBoys[fieldName] = file;
            this.deliveryBoys[fieldName + '_url'] = URL.createObjectURL(file);
        },
          validateDateOfBirth() {
            const selectedDate = new Date(this.deliveryBoys.dob);
            const currentDate = new Date();
            if (selectedDate > currentDate) {
                this.dobvalidationError = "Date of Birth cannot be in the future.";
                this.deliveryBoys.dob = null;
            } else {
                this.dobvalidationError = null;
            }
        },
        validateMobileNumber() {
          if (this.deliveryBoys.mobile < 0) {
                this.mobilevalidationError = "Mobile Number must be numeric value.";
                this.deliveryBoys.mobile = null;
            } else {
                this.mobilevalidationError = null;
            }
        },
        validateAccountNumber() {
          if (this.deliveryBoys.bank_account_number < 1) {
                this.account_numbervalidationError = "Account Number must be numeric value.";
                this.deliveryBoys.bank_account_number = null;
            } else {
                this.account_numbervalidationError = null;
            }
        },
        getVehicles() {
            axios.get(this.$apiUrl + '/vehicles')
                .then((response) => {
                    let data = response.data;
                    if (data.status === 1) {
                        this.vehicles = data.data;
                    }
                });
        },
        getStoreLocations() {
            axios.get(this.$apiUrl + '/store-locations')
                .then((response) => {
                    let data = response.data;
                    if (data.status === 1) {
                        this.storeLocations = data.data;

                        // Set selected store locations if editing and record is already loaded
                        if (this.record && this.record.store_locations) {
                            this.setSelectedStoreLocations();
                        }
                    }
                });
        },
        setSelectedStoreLocations() {
            if (!this.record || !this.record.store_locations) return;

            // Map the record's store_locations to match the multiselect format
            this.selectedStoreLocations = this.record.store_locations.map(sl => {
                // Find the full store location object from storeLocations array
                const fullLocation = this.storeLocations.find(loc => loc.id === sl.id);
                return fullLocation || sl;
            });
        },
        getCities() {
            this.isLoading = true
            axios.get(this.$apiUrl + '/cities')
                .then((response) => {
                    this.isLoading = false
                    let data = response.data;
                    this.cities = data.data

                    if(this.deliveryBoys.id && this.record?.city_id){
                        this.city = this.cities.filter((item) => {
                            return item.id === this.record.city_id;
                        });
                    }
                });
        },
        setCityId() {
            this.deliveryBoys.city_id = this.city.id;
        },

        getDeliveryBoy(){
            axios.get(this.$apiUrl + '/delivery_boys/edit/' + this.id)
                .then((response) => {
                    this.isLoading = false
                    let data = response.data;
                    if (data.status === 1) {
                        this.record = data.data

                        this.deliveryBoys.id = this.record ? this.record.id : null;
                        this.deliveryBoys.admin_id = this.record ? this.record.admin_id : "";

                        this.deliveryBoys.name = this.record ? this.record.name : "";
                        this.deliveryBoys.dob = this.record ? this.record.dob : "";
                        this.deliveryBoys.mobile = this.record ? this.record.mobile : "";
                        this.deliveryBoys.email = this.record ? this.record.email : "";

                        // Profile and location
                        this.deliveryBoys.profile_image_url = this.record ? this.record.profile_image : "";
                        this.deliveryBoys.latitude = this.record ? this.record.latitude : "";
                        this.deliveryBoys.longitude = this.record ? this.record.longitude : "";

                        this.city = this.cities.filter((item) => {
                            return item.id === this.record.city_id;
                        });
                        this.deliveryBoys.city_id = this.record ? this.record.city_id : "";
                        this.deliveryBoys.vehicle_id = this.record ? this.record.vehicle_id : "";

                        this.deliveryBoys.address = this.record ? this.record.address : "";

                        // Store locations
                        if (this.record?.store_locations) {
                            this.selectedStoreLocations = this.record.store_locations;
                        }

                        // Documents
                        const doc = this.record?.documents;
                        if (doc) {
                            // Driving License
                            this.deliveryBoys.driving_license_number = doc.driving_license_number || "";
                            this.deliveryBoys.driving_license_front_url = doc.driving_license_front_path || "";
                            this.deliveryBoys.driving_license_back_url = doc.driving_license_back_path || "";

                            // RC
                            this.deliveryBoys.rc_number = doc.rc_number || "";
                            this.deliveryBoys.rc_front_url = doc.rc_front_path || "";
                            this.deliveryBoys.rc_back_url = doc.rc_back_path || "";

                            // Aadhar
                            this.deliveryBoys.aadhar_number = doc.aadhar_number || "";
                            this.deliveryBoys.aadhar_front_url = doc.aadhar_front_path || "";
                            this.deliveryBoys.aadhar_back_url = doc.aadhar_back_path || "";

                            // PAN
                            this.deliveryBoys.pan_number = doc.pan_number || "";
                            this.deliveryBoys.pan_front_url = doc.pan_front_path || "";
                            this.deliveryBoys.pan_back_url = doc.pan_back_path || "";

                            // Bank details
                            this.deliveryBoys.bank_name = doc.bank_name || "";
                            this.deliveryBoys.account_holder_name = doc.account_holder_name || "";
                            this.deliveryBoys.account_number = doc.account_number || "";
                            this.deliveryBoys.ifsc_code = doc.ifsc_code || "";
                            this.deliveryBoys.bank_passbook_image_url = doc.bank_passbook_image_path || "";
                        }

                    }else{
                        this.showError(data.message);
                        setTimeout(() => {
                            this.$router.back();
                        }, 1000);
                    }
                }).catch(error => {
                this.isLoading = false;
                if (error.request?.statusText) {
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
            let formData = new FormData();

            // Basic fields
            if (this.deliveryBoys.id) {
                formData.append('id', this.deliveryBoys.id);
            }
            formData.append('name', this.deliveryBoys.name || '');
            formData.append('email', this.deliveryBoys.email || '');
            formData.append('mobile', this.deliveryBoys.mobile || '');
            formData.append('dob', this.deliveryBoys.dob || '');
            formData.append('address', this.deliveryBoys.address || '');
            formData.append('latitude', this.deliveryBoys.latitude || '');
            formData.append('longitude', this.deliveryBoys.longitude || '');
            formData.append('city_id', this.deliveryBoys.city_id || '');
            formData.append('vehicle_id', this.deliveryBoys.vehicle_id || '');

            // Profile image
            if (this.deliveryBoys.profile_image) {
                formData.append('profile_image', this.deliveryBoys.profile_image);
            }

            // Store locations
            if (this.selectedStoreLocations && this.selectedStoreLocations.length > 0) {
                this.selectedStoreLocations.forEach((location, index) => {
                    formData.append(`store_location_ids[${index}]`, location.id);
                });
            }

            // Driving License
            formData.append('driving_license_number', this.deliveryBoys.driving_license_number || '');
            if (this.deliveryBoys.driving_license_front) {
                formData.append('driving_license_front', this.deliveryBoys.driving_license_front);
            }
            if (this.deliveryBoys.driving_license_back) {
                formData.append('driving_license_back', this.deliveryBoys.driving_license_back);
            }

            // RC
            formData.append('rc_number', this.deliveryBoys.rc_number || '');
            if (this.deliveryBoys.rc_front) {
                formData.append('rc_front', this.deliveryBoys.rc_front);
            }
            if (this.deliveryBoys.rc_back) {
                formData.append('rc_back', this.deliveryBoys.rc_back);
            }

            // Aadhar
            formData.append('aadhar_number', this.deliveryBoys.aadhar_number || '');
            if (this.deliveryBoys.aadhar_front) {
                formData.append('aadhar_front', this.deliveryBoys.aadhar_front);
            }
            if (this.deliveryBoys.aadhar_back) {
                formData.append('aadhar_back', this.deliveryBoys.aadhar_back);
            }

            // PAN
            formData.append('pan_number', this.deliveryBoys.pan_number || '');
            if (this.deliveryBoys.pan_front) {
                formData.append('pan_front', this.deliveryBoys.pan_front);
            }
            if (this.deliveryBoys.pan_back) {
                formData.append('pan_back', this.deliveryBoys.pan_back);
            }

            // Bank Details
            formData.append('bank_name', this.deliveryBoys.bank_name || '');
            formData.append('account_holder_name', this.deliveryBoys.account_holder_name || '');
            formData.append('account_number', this.deliveryBoys.account_number || '');
            formData.append('ifsc_code', this.deliveryBoys.ifsc_code || '');
            if (this.deliveryBoys.bank_passbook_image) {
                formData.append('bank_passbook_image', this.deliveryBoys.bank_passbook_image);
            }

            let url = this.$apiUrl + '/delivery_boys/save';
            if(this.deliveryBoys.id){
                url = this.$apiUrl + '/delivery_boys/update';
            }
            axios.post(url, formData, {
                headers: {
                    'Content-Type': 'multipart/form-data'
                }
            }).then(res => {
                let data = res.data;
                if (data.status === 1) {
                    this.showMessage("success", data.message);
                    setTimeout(
                        function () {
                            vm.$swal.close();
                            if(vm.$roleDeliveryBoy !== vm.login_user.role.name){
                                vm.$router.push({path: '/delivery_boys'});
                            } else {
                                vm.getDeliveryBoy();
                            }
                        }, 2000);
                }else{
                    vm.showError(data.message);
                    vm.isLoading = false;
                }
            }).catch(error => {
                vm.isLoading = false;
                if (error.request?.statusText) {
                    this.showError(error.request?.statusText);
                }else if (error.message) {
                    this.showError(error.message);
                } else {
                    this.showError("Something went wrong!");
                }
            });
        }
    }
};
</script>
<style scoped>
@import "../../../../node_modules/vue-multiselect/dist/vue-multiselect.min.css";
</style>
