<template>
    <div>
        <div class="page-heading">

            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3 v-if="this.$roleSeller === this.login_user.role.name" >
                        {{__('my_profile')}}
                    </h3>
                    <h3 v-else>
                        <template v-if="id">{{__('edit')}}</template>
                        <template v-else>{{__('create')}}</template>
                        {{__('seller')}}
                    </h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/seller" v-if="this.$roleSeller === this.login_user.role.name" >{{__('dashboard')}}</router-link>
                                <router-link to="/dashboard" v-else>{{__('dashboard')}}</router-link>
                            </li>
                            <template v-if="this.$roleSeller === this.login_user.role.name" >
                                <li class="breadcrumb-item" aria-current="page">{{__('my_profile')}}</li>
                            </template>
                            <template v-else>

                                <li class="breadcrumb-item" aria-current="page">
                                    <router-link to="/sellers">{{__('manage_sellers')}}</router-link>
                                </li>

                                <li class="breadcrumb-item active" aria-current="page">
                                    <template v-if="id">{{__('edit')}}</template>
                                    <template v-else>{{__('create')}}</template>
                                    {{__('seller')}}
                                </li>
                            </template>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3" v-if="this.$roleSeller !== this.login_user.role.name">
                <div class="col-12">
                    <router-link to="/sellers" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <div class="row">
                <div class="col-12 col-md-12 order-md-1 order-last">
                    <form ref="my-form" @submit.prevent="saveRecord">
                        <div class="card">
                            <div class="card-header">
                                <h4>{{__('seller_information')}} </h4>
                                <span class="pull-right"  v-if="this.$roleSeller !== this.login_user.role.name">
                                    <router-link to="/sellers" class="btn btn-primary" v-b-tooltip.hover title="Manage Seller">{{__('manage_seller')}}</router-link>
                                </span>
                            </div>
                            <div class="card-body">
                                <label><span class="text-danger text-xs">*</span> {{__('required_fields')}}.</label>
                                <div class="divider" v-if="this.$roleSeller !== this.login_user.role.name"><div class="divider-text">{{__('new_seller_register_form')}}</div></div>
                                <div class="row">
                                    <div class="form-group col-md-4">
                                        <div class="form-group">
                                            <label>{{__('name')}} <i class="text-danger">*</i></label>
                                            <input type="text" class="form-control" v-model="name"
                                                   placeholder="Enter name." @focus="onInputFocus" @blur="onInputBlur">
                                        </div>
                                    </div>
                                    <div class="form-group col-md-4">
                                        <div class="form-group">
                                            <label>{{__('email')}} <i class="text-danger">*</i></label>
                                            <input type="email" class="form-control" v-model="email"
                                                   placeholder="Enter email." @focus="onInputFocus" @blur="onInputBlur">
                                        </div>
                                    </div>

                                    <div class="form-group col-md-4">
                                        <div class="form-group">
                                            <label>Mobile <i class="text-danger">*</i></label>
                                            <input
                                                type="text"
                                                class="form-control"
                                                v-model="mobile"
                                                placeholder="Enter mobile number"
                                                maxlength="10"
                                                inputmode="numeric"
                                                pattern="[0-9]{10}"
                                                required
                                                @input="mobile = mobile.replace(/\D/g, '').slice(0, 10)"
                                            >
                                        </div>
                                    </div>

                                    <div class="form-group col-md-4" v-if="this.$roleSeller !== this.login_user.role.name">
                                        <div class="form-group">
                                            <label>{{__('password')}} <i v-if="!id" class="text-danger">*</i></label>
                                            <div class="input-group">
                                                <input :type="showPassword ? 'text' : 'password'"  class="form-control" v-model="password" placeholder="Enter password.">
                                                <button type="button" v-on:click="showPassword = !showPassword" class="btn btn-primary font-bold">
                                                    <i v-if="showPassword" class="fa fa-eye-slash" aria-hidden="true"></i>
                                                    <i v-else class="fa fa-eye" aria-hidden="true"></i>
                                                </button>
                                            </div>

                                        </div>
                                    </div>

                                    <div class="form-group col-md-4" v-if="this.$roleSeller !== this.login_user.role.name">
                                        <div class="form-group">
                                            <label>{{__('confirm_password')}}<i v-if="!id" class="text-danger">*</i></label>
                                            <div class="input-group">
                                                <input :type="showConfirmPassword ? 'text' : 'password'" class="form-control" v-model="confirm_password" placeholder="Enter confirm password.">
                                                <button type="button" v-on:click="showConfirmPassword = !showConfirmPassword" class="btn btn-primary font-bold">
                                                    <i v-if="showConfirmPassword" class="fa fa-eye-slash" aria-hidden="true"></i>
                                                    <i v-else class="fa fa-eye" aria-hidden="true"></i>
                                                </button>
                                            </div>
                                        </div>
                                    </div>

                                </div>
                            </div>
                        </div>

                        <div class="card">
                            <div class="card-header">
                                <h4> {{__('store_information')}}</h4>
                            </div>
                            <div class="card-body">
                                <div class="row">

                                    <div class="form-group col-md-4">
                                        <div class="form-group">
                                            <label>{{__('store_name')}} <i class="text-danger">*</i></label>
                                            <input type="text" class="form-control" v-model="store_name"
                                                   placeholder="Enter store name.">
                                        </div>
                                    </div>

                                    <div class="form-group col-md-4">
                                        <div class="form-group">
                                            <label>Select Store <i class="text-danger">*</i></label>
                                            <Select2 v-model="store_id"
                                                     placeholder="Select Store"
                                                     :options="stores_options"/>
                                        </div>
                                    </div>

                                    <!-- <div class="form-group col-md-4">
                                        <div class="form-group">
                                            <label>{{__('store_url')}} <i class="text-danger">*</i></label>
                                            <input type="text" class="form-control" v-model="store_url"
                                                   placeholder="Enter store URL.">
                                        </div>
                                    </div> -->

                                    <!-- <div class="form-group col-md-6">
                                        <div class="form-group">
                                            <label>{{__('category_ids')}} <small>( Ex : 100,205, 360 )</small></label>
                                            <Select2 v-model="categories_ids"
                                                     placeholder="select categories"
                                                     :options="categories_options"
                                                     :settings="{ multiple: 'multiple'}"/>
                                        </div>
                                    </div> -->

                                    <!-- <div class="form-group col-md-6">
                                        <div class="form-group">
                                            <label>{{__('city')}}</label>
                                            <Select2 v-model="city_id"
                                                     placeholder="Select City"
                                                     :options="cities_options"
                                                     :settings="{ multiple: 'multiple'}"/>
                                        </div>
                                    </div> -->

                                    <div class="form-group col-md-4">
                                        <div class="form-group">
                                            <label>Address<i class="text-danger">*</i></label>
                                            <input type="text" class="form-control" v-model="store_location"
                                                   placeholder="Enter store location.">
                                        </div>
                                    </div>

                                    <div class="form-group col-md-4">
                                        <div class="form-group">
                                            <label>Store City<i class="text-danger">*</i></label>
                                            <input type="text" class="form-control" v-model="store_city"
                                                   placeholder="Enter store city.">
                                        </div>
                                    </div>

                                    <!-- <div class="form-group col-md-4">
                                        <div class="form-group">
                                            <label>{{__('tax_name')}} <i class="text-danger">*</i></label>
                                            <input type="text" class="form-control" v-model="tax_name"
                                                   placeholder="Enter tax name.">
                                        </div>
                                    </div> -->

                                    <div class="form-group col-md-4">
                                        <div class="form-group">
                                            <label>Gst Number(Optional)</label>
                                            <input type="text" class="form-control" v-model="tax_number"
                                                   placeholder="Enter tax number.">
                                        </div>
                                    </div>

                                    <div class="form-group col-md-4">
                                        <div class="form-group">
                                            <label>{{__('pan_number')}} <i class="text-danger">*</i></label>
                                            <input
                                                type="text"
                                                class="form-control"
                                                v-model="pan_number"
                                                placeholder="Enter PAN number"
                                                maxlength="10"
                                                style="text-transform: uppercase"
                                                required
                                                @input="pan_number = pan_number.toUpperCase().replace(/[^A-Z0-9]/g, '')"
                                            />

                                        </div>
                                    </div>

                                    <div class="form-group col-md-4">
                                        <div class="form-group">
                                            <label>Fssai Number <i class="text-danger">*</i></label>
                                            <input type="text" class="form-control" v-model="fssai_number"
                                                   placeholder="Enter FSSAI number." required>
                                        </div>
                                    </div>

                                    <div class="form-group col-md-4">
                                        <div class="form-group">
                                            <label>Aadhar Number <i class="text-danger">*</i></label>

                                            <input
                                                type="text"
                                                class="form-control"
                                                v-model="aadhar_number"
                                                placeholder="Enter Aadhar number"
                                                maxlength="12"
                                                inputmode="numeric"
                                                pattern="[0-9]{12}"
                                                required
                                                @input="aadhar_number = aadhar_number.replace(/\D/g, '').slice(0, 12)"
                                            >

                                        </div>
                                    </div>

                                    <!-- <div class="form-group col-md-4">
                                        <div class="form-group">
                                            <label>{{__('category_name')}}</label>
                                            <input type="text" class="form-control" v-model="category_name"
                                                   placeholder="Enter category name.">
                                        </div>
                                    </div> -->

                                    <!-- <div class="form-group col-md-4" v-if="this.$roleSeller !== this.login_user.role.name">
                                        <label>{{__('commission')}}</label>
                                        <input type="number" class="form-control" v-model="commission"
                                               placeholder="Enter commission (%)" @input="validateCommission">

                                        <p v-if="commissionvalidationError" class="error">{{ commissionvalidationError }}</p>
                                        <span class="text text-success font-size-13">
                                            <a href="javascript:void(0)" @click="commissionRule = true"
                                               title="How it works">How seller commission works?</a>
                                        </span>
                                    </div> -->


                                    <br>
                                    <div class="form-group col-md-4">
                                        <div class="form-group">
                                            <label> {{__('national_identity_card')}}<i v-if="!id" class="text-danger">*</i></label>
                                            <input type="file" class="file-input" accept="image/*,application/pdf,.doc,.docx" ref="file_national_id_card" v-if="this.$roleSeller !== this.login_user.role.name" v-on:change="handleFileNationalIdCard">
                                            <div class="file-input-div bg-gray-100" v-if="this.$roleSeller !== this.login_user.role.name" @click="$refs.file_national_id_card.click()" @drop="dropFileNationalIdCard" @dragover="$dragoverFile" @dragleave="$dragleaveFile">
                                                <template v-if="national_id_card && national_id_card.name !== ''">
                                                    <label>Selected file name:- {{__('selected_file_name')}}{{ national_id_card.name }}</label>
                                                </template>
                                                <template v-else>
                                                    <label><i class="fa fa-cloud-upload-alt fa-2x"></i></label>
                                                    <label>{{ __('drop_files_here_or_click_to_upload') }}</label>
                                                </template>
                                            </div>
                                            <div class="row" v-if="national_id_card_url">
                                                <div v-if="isImage(national_id_card_url)" class="col-md-2">
                                                    <img class="custom-image" :src="national_id_card_url" title='Identity Card' alt='Identity Card'/>
                                                </div>
                                                <div v-else class="col-md-2 mt-2">
                                                    <a target="_blank" :href="national_id_card_url" class="badge bg-success"> <i class="fa fa-eye"></i> Identity Card</a>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="form-group col-md-4">
                                        <div class="form-group">
                                            <label> {{__('address_proof')}}<i v-if="!id" class="text-danger">*</i></label>
                                            <input type="file" class="file-input" accept="image/*,application/pdf,.doc,.docx"  ref="file_address_proof" v-if="this.$roleSeller !== this.login_user.role.name" v-on:change="handleFileAddressProof">
                                            <div class="file-input-div bg-gray-100" v-if="this.$roleSeller !== this.login_user.role.name" @click="$refs.file_address_proof.click()" @drop="dropFileAddressProof" @dragover="$dragoverFile" @dragleave="$dragleaveFile">
                                                <template v-if="address_proof_name == '' ">
                                                    <label><i class="fa fa-cloud-upload-alt fa-2x"></i></label>
                                                    <label>{{ __('drop_files_here_or_click_to_upload') }}</label>
                                                </template>
                                                <template v-else>
                                                    <label>{{__('selected_file_name')}} {{ address_proof_name }}</label>
                                                </template>
                                            </div>
                                            <div class="row" v-if="address_proof_url">
                                                <div  v-if="isImage(address_proof_url)"  class="col-md-2">
                                                    <img class="custom-image" :src="address_proof_url" title='Address Proof' alt='Address Proof'/>
                                                </div>
                                                <div v-else class="col-md-2 mt-2">
                                                    <a target="_blank" :href="address_proof_url" class="badge bg-success"> <i class="fa fa-eye"></i> Address Proof</a>
                                                </div>
                                            </div>

                                        </div>
                                    </div>

                                    <div class="form-group col-md-4">
                                        <div class="form-group">
                                            <label> Pan Image <i v-if="!id" class="text-danger">*</i></label>
                                            <input type="file" class="file-input" accept="image/*,application/pdf" ref="file_pan_img" v-on:change="handleFilePanImg">
                                            <div class="file-input-div bg-gray-100" @click="$refs.file_pan_img.click()" @drop="dropFilePanImg" @dragover="$dragoverFile" @dragleave="$dragleaveFile">
                                                <template v-if="pan_img && pan_img.name !== ''">
                                                    <label>{{__('selected_file_name')}}{{ pan_img.name }}</label>
                                                </template>
                                                <template v-else>
                                                    <label><i class="fa fa-cloud-upload-alt fa-2x"></i></label>
                                                    <label>{{ __('drop_files_here_or_click_to_upload') }}</label>
                                                </template>
                                            </div>
                                            <div class="row" v-if="pan_img_url">
                                                <div v-if="isImage(pan_img_url)" class="col-md-2">
                                                    <img class="custom-image" :src="pan_img_url" title='PAN Image' alt='PAN Image'/>
                                                </div>
                                                <div v-else class="col-md-2 mt-2">
                                                    <a target="_blank" :href="pan_img_url" class="badge bg-success"> <i class="fa fa-eye"></i> PAN Image</a>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    <div class="form-group col-md-4">
                                        <div class="form-group">
                                            <label> Fssai Image <i class="text-danger">*</i></label>
                                            <input type="file" class="file-input" accept="image/*,application/pdf" ref="file_fssai_img" v-on:change="handleFileFssaiImg">
                                            <div class="file-input-div bg-gray-100" @click="$refs.file_fssai_img.click()" @drop="dropFileFssaiImg" @dragover="$dragoverFile" @dragleave="$dragleaveFile">
                                                <template v-if="fssai_img && fssai_img.name !== ''">
                                                    <label>{{__('selected_file_name')}}{{ fssai_img.name }}</label>
                                                </template>
                                                <template v-else>
                                                    <label><i class="fa fa-cloud-upload-alt fa-2x"></i></label>
                                                    <label>{{ __('drop_files_here_or_click_to_upload') }}</label>
                                                </template>
                                            </div>
                                            <div class="row" v-if="fssai_img_url">
                                                <div v-if="isImage(fssai_img_url)" class="col-md-2">
                                                    <img class="custom-image" :src="fssai_img_url" title='FSSAI Image' alt='FSSAI Image'/>
                                                </div>
                                                <div v-else class="col-md-2 mt-2">
                                                    <a target="_blank" :href="fssai_img_url" class="badge bg-success"> <i class="fa fa-eye"></i> FSSAI Image</a>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    <div class="form-group col-md-4">
                                        <div class="form-group">
                                            <label for="logo"> {{__('logo')}} <i v-if="!id" class="text-danger">*</i></label>
                                            <input type="file" accept="image/*" id="logo" class="file-input" ref="file_store_logo" v-on:change="handleFileStoreLogo">
                                            <div class="file-input-div bg-gray-100" @click="$refs.file_store_logo.click()" @drop="dropFileStoreLogo" @dragover="$dragoverFile" @dragleave="$dragleaveFile">
                                                <template v-if="store_logo && store_logo.name !== ''">
                                                    <label>{{__('selected_file_name')}}{{ store_logo.name }}</label>
                                                </template>
                                                <template v-else>
                                                    <label><i class="fa fa-cloud-upload-alt fa-2x"></i></label>
                                                    <label>{{ __('drop_files_here_or_click_to_upload') }}</label>
                                                </template>
                                            </div>
                                            <div class="row" v-if="store_logo_url">
                                                <div class="col-md-2">
                                                    <img class="custom-image" :src="store_logo_url" title='Store Logo' alt='Store Logo'/>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    <!-- Store Images (Multiple) -->
                                    <div class="form-group col-md-12">
                                        <div class="form-group">
                                            <label> Store Images <i v-if="!id" class="text-danger">*</i></label>
                                            <input type="file" class="file-input" accept="image/*,application/pdf" ref="file_store_images" multiple v-on:change="handleFileStoreImages">
                                            <div class="file-input-div bg-gray-100" @click="$refs.file_store_images.click()" @drop="dropFileStoreImages" @dragover="$dragoverFile" @dragleave="$dragleaveFile">
                                                <template v-if="store_images && store_images.length > 0">
                                                    <label>{{__('selected_file_name')}} {{ store_images.length }} files selected</label>
                                                </template>
                                                <template v-else>
                                                    <label><i class="fa fa-cloud-upload-alt fa-2x"></i></label>
                                                    <label>{{ __('drop_files_here_or_click_to_upload') }} (Multiple)</label>
                                                </template>
                                            </div>
                                            <div class="row mt-2" v-if="store_images_urls && store_images_urls.length > 0">
                                                <div v-for="(url, index) in store_images_urls" :key="index" class="col-md-2 mb-2">
                                                    <div class="position-relative">
                                                        <img v-if="isImage(url)" class="custom-image" :src="url" :title="'Store Image ' + (index + 1)" :alt="'Store Image ' + (index + 1)"/>
                                                        <a v-else target="_blank" :href="url" class="badge bg-success"> <i class="fa fa-eye"></i> Store Image {{ index + 1 }}</a>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    <div class="col-md-12" v-if="id && this.$roleSeller !== this.login_user.role.name">
                                        <div class="row">
                                            <div class="form-group col-md-5">
                                                <label class="control-label"> {{__('status')}} <i class="text-danger">*</i></label><br>
                                                <b-form-radio-group
                                                    v-model="status"
                                                    :options="[
                                                    { text: ' Registered', 'value': 0 },
                                                    { text: ' Approved', 'value': 1 },
                                                    { text: ' Not-Approved', 'value': 2 },
                                                    { text: ' Deactive', 'value': 3 },
                                                ]"
                                                    buttons
                                                    button-variant="outline-primary"
                                                    required
                                                ></b-form-radio-group>
                                            </div>
                                            <div v-if="[2,3].includes(status)" class="form-group col-md-4">

                                                <label for="remark">Remark <i class="text-danger">*</i></label>
                                                <div class="form-floating">
                                                    <textarea class="form-control" name="remark" id="remark" required v-model="remark" placeholder="Add a remark of this status..." spellcheck="true"></textarea>
                                                    <label for="remark">Add a remark of this status...</label>
                                                </div>

                                            </div>
                                        </div>
                                    </div>

                                    <div class="form-group col-md-12">
                                        <div class="form-group">
                                            <label>Store Description <i class="text-danger">*</i></label>
                                            <textarea class="form-control" v-model="store_description" rows="5" placeholder="Enter store description"></textarea>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="card">
                            <div class="card-header">
                                <h4> {{__('store_location_information')}}</h4>
                            </div>
                            <div class="card-body">
                                <div class="row">
                                    <!-- <div class="form-group col-md-6">
                                        <div class="form-group">
                                            <label> {{__('lat_long')}} <i class="text-danger">*</i></label>
                                            <input type="text" class="form-control" v-model="lat_long" placeholder="Enter lat,long (e.g., 17.4486,78.3908)">
                                            <small class="text-muted">Format: latitude,longitude</small>
                                        </div>
                                    </div> -->

                                    <div class="form-group col-md-6">
                                        <label for="location">{{__('search_location')}} <i class="text-danger">*</i></label>
                                        <div class="input-group">
                                            <GmapAutocomplete type="search" class="form-control" placeholder="Search your location on map." required
                                                              ref="locationAutocomplete"
                                                              @place_changed="setPlace"
                                                              :options="{ fields: ['formatted_address', 'geometry', 'name'], strictBounds: false}"
                                                              id="location">
                                            </GmapAutocomplete>

                                            <b-button type="button" variant="primary" class="search_location_btn" v-b-tooltip.hover title="Add current location" @click="getCurrentLocation">
                                                <svg xmlns="http://www.w3.org/2000/svg" height="48px" viewBox="0 0 24 24" width="48px" fill="#FFFFFF">
                                                    <title>current-location</title>
                                                    <path d="M0 0h24v24H0V0z" fill="none"/><path d="M12 8c-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4-1.79-4-4-4zm8.94 3c-.46-4.17-3.77-7.48-7.94-7.94V1h-2v2.06C6.83 3.52 3.52 6.83 3.06 11H1v2h2.06c.46 4.17 3.77 7.48 7.94 7.94V23h2v-2.06c4.17-.46 7.48-3.77 7.94-7.94H23v-2h-2.06zM12 19c-3.87 0-7-3.13-7-7s3.13-7 7-7 7 3.13 7 7-3.13 7-7 7z"/>
                                                </svg>
                                            </b-button>
                                        </div>
                                        <span class="text text-primary font-size-13"> {{__('search_your_seller_name_and_you_will_get_the_location_points_latitude_longitude_below')}}</span>
                                    </div>

                                    <div class="col-md-12 mb-3">
                                        <div v-if="formatted_address" class="text-danger">{{__('draf_and_click_marker_to_your_shop_proper_location')}}</div>
                                        <div id="map" style="position: relative; overflow: hidden;">
                                            <GmapMap
                                                :center="center"
                                                :zoom="13"
                                                :mapTypeControl=true
                                                style="width: 100%; height: 400px; margin-top: 20px"
                                                ref="mapRef"
                                                @click="handleMapClick"
                                            >
                                                <GmapMarker
                                                    :key="index"
                                                    v-for="(m, index) in markers"
                                                    :position="m.position"
                                                    :clickable="true"
                                                    :draggable="true"
                                                    @drag="updateCoordinates"
                                                    @click="updateCoordinates"
                                                />
                                                <!--                                                    @click="center = m.position"-->
                                                <gmap-info-window
                                                    :options="{
                                                                  maxWidth: 300,
                                                                  pixelOffset: { width: 0, height: -35 }
                                                                }"
                                                    :position="infoWindow.position"
                                                    :opened="infoWindow.open"
                                                    @closeclick="infoWindow.open=false">
                                                    <div v-html="infoWindow.template"></div>
                                                </gmap-info-window>
                                            </GmapMap>
                                        </div>
                                        <div v-if="formatted_address">
                                            <span class="title font-weight-bolder"><b>{{
                                                    place_name
                                                }}</b> - {{ formatted_address }}</span>
                                        </div>
                                    </div>



                                </div>
                            </div>
                           
                        </div>

                        <div class="card">
                            <!-- <div class="card-header">
                                <h4>{{__('other_setting')}}</h4>
                            </div> -->
                            <div class="card-body">
                                <div class="row">
                                    <!-- <div class="form-group col-md-3">
                                        <div class="form-group">
                                            <label class="control-label"> {{__('require_product_approval')}}</label><br>
                                            <b-form-radio-group
                                                v-model="require_products_approval"
                                                :options="[
                                                                { text: ' Yes', 'value': 1 },
                                                                { text: ' No', 'value': 0 },
                                                            ]"
                                                buttons
                                                button-variant="outline-primary"
                                                required
                                            ></b-form-radio-group>
                                        </div>
                                    </div> -->
                                    <!-- <div class="form-group col-md-3">
                                        <div class="form-group">
                                            <label class="control-label"> {{__('view_customer_details')}}</label><br>
                                            <b-form-radio-group
                                                v-model="customer_privacy"
                                                :options="[
                                                                { text: ' Yes', 'value': 1 },
                                                                { text: ' No', 'value': 0 },
                                                            ]"
                                                buttons
                                                button-variant="outline-primary"
                                                required
                                            ></b-form-radio-group>
                                        </div>
                                    </div> -->
                                    
                                    <div class="form-group col-md-3" v-if="store_settings.self_pickup_mode == 1">
                                        <div class="form-group">
                                            <label class="control-label"> {{__('self_pickup_mode')}}</label><br>
                                            <b-form-radio-group
                                                v-model="self_pickup_mode"
                                                :options="[
                                                                { text: ' Yes', 'value': 1 },
                                                                { text: ' No', 'value': 0 },
                                                            ]"
                                                buttons
                                                button-variant="outline-primary"
                                                required
                                            ></b-form-radio-group>
                                        </div>
                                    </div>
                                    
                                </div>
                                
                                <!-- Self Pickup Configuration Section -->
                                <div v-if="store_settings.self_pickup_mode == 1 && self_pickup_mode == 1" class="row mt-4">
                                    <div class="col-12">
                                        <h5 class="text-primary">{{__('self_pickup_configuration')}}</h5>
                                    </div>
                                    
                                    <!-- Map Section for Pickup Location -->
                                    <div class="form-group col-md-12">
                                        <div class="row">
                                            <!-- Left Side - Map Only (50%) -->
                                            <div class="col-md-6">
                                                <!-- Map View -->
                                                <div class="form-group">
                                                    <div id="pickup_map" style="position: relative; overflow: hidden;">
                                                        <GmapMap
                                                            :zoom="13"
                                                            :center="pickupCenter"
                                                            :mapTypeControl=true
                                                            style="width: 100%; height: 400px; margin-top: 5px"
                                                            ref="pickupMapRef"
                                                        >
                                                            <GmapMarker
                                                                :key="index"
                                                                v-for="(m, index) in pickupMarkers"
                                                                :position="google && m.position"
                                                                @click="pickupCenter = m.position"
                                                                :clickable="true"
                                                                :draggable="true"
                                                                @dragend="onPickupMarkerDragEnd"
                                                            />
                                                            <gmap-info-window
                                                                :options="{
                                                                      maxWidth: 300,
                                                                      pixelOffset: { width: 0, height: -35 }
                                                                    }"
                                                                :position="pickupInfoWindow.position"
                                                                :opened="pickupInfoWindow.open"
                                                                @closeclick="pickupInfoWindow.open=false">
                                                                <div v-html="pickupInfoWindow.template"></div>
                                                            </gmap-info-window>
                                                        </GmapMap>
                                                    </div>
                                                </div>
                                            </div>
                                            
                                            <!-- Right Side - All Details (50%) -->
                                            <div class="col-md-6">
                                                <!-- Search Input -->
                                                <div class="form-group">
                                                    <label for="pickup_city_name">{{ __('search_location') }}</label>
                                                    <GmapAutocomplete type="search" class="form-control"
                                                                      placeholder="Search Pickup Location on map."
                                                                      @place_changed="setPickupPlace"
                                                                      :options="{ fields: ['address_components','formatted_address', 'geometry', 'name','place_id','plus_code','types'], strictBounds: false }"
                                                                      id="pickup_city_name">
                                                    </GmapAutocomplete>
                                                    <!-- <input type="hidden" v-model="pickup_formatted_address"> -->
                                                    <span class="text text-primary">{{ __('search_your_pickup_location_and_to_find_coordinates') }}</span>
                                                </div>
                                                
                                                <!-- Pickup Store Address -->
                                                <div class="form-group">
                                                    <label>{{__('pickup_store_address')}} <i class="text-danger">*</i></label>
                                                    <textarea class="form-control" v-model="pickup_store_address" 
                                                              rows="2" :placeholder="__('enter_pickup_store_address')"></textarea>
                                                </div>
                                                
                                                <!-- Coordinates -->
                                                <div class="form-group">
                                                    <label for="pickup_latitude">{{ __('latitude') }} <span class="text-danger text-sm">*</span></label>
                                                    <input type="text" class="form-control" name="pickup_latitude" id="pickup_latitude"
                                                           v-model="pickup_latitude" placeholder="Enter Latitude." required readonly>
                                                </div>
                                                
                                                <div class="form-group">
                                                    <label for="pickup_longitude">{{ __('longitude') }}<span class="text-danger text-sm">*</span></label>
                                                    <input type="text" class="form-control" name="pickup_longitude" id="pickup_longitude"
                                                           v-model="pickup_longitude" placeholder="Enter Longitude." required readonly>
                                                </div>
                                                
                                                <!-- Store Timings -->
                                                <div class="form-group">
                                                    <label>{{__('store_timings')}} <i class="text-danger">*</i></label>
                                                    <div class="row">
                                                        <div class="col-md-6">
                                                            <label class="form-label">{{__('opening_time')}}</label>
                                                            <input type="time" class="form-control" v-model="storeTimings.opening_time" required>
                                                        </div>
                                                        <div class="col-md-6">
                                                            <label class="form-label">{{__('closing_time')}}</label>
                                                            <input type="time" class="form-control" v-model="storeTimings.closing_time" required>
                                                        </div>
                                                    </div>
                                                    <small class="text-muted">{{__('store_timings_description')}}</small>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="card-footer">
                                <template v-if="id">
                                    <b-button type="submit" variant="primary" :disabled="isLoading">  {{__('update')}}
                                        <b-spinner v-if="isLoading" small label="Spinning"></b-spinner>
                                    </b-button>
                                </template>
                                <template v-else>
                                    <b-button type="submit" variant="primary" :disabled="isLoading"> {{__('save')}}
                                        <b-spinner v-if="isLoading" small label="Spinning"></b-spinner>
                                    </b-button>
                                    <button type="button" class="btn btn-danger" @click="clearForm()"> {{__('clear')}}</button>
                                </template>
                            </div>
                        </div>

                    </form>
                </div>
            </div>
        </div>
        <!-- Commission Rule Modal-->
        <b-modal v-model="commissionRule" size="lg" title="How commission (Admin commission) will get credited?">
            <b-container fluid>
                <ol>
                   
                    <li>
                        Formula for commision (Admin commission) is <b>Sub total (Excluding delivery charge) / 100 * 
                        commission percentage</b>
                    </li>
                    <li>
                        For example sub total is 1378 and commission is 20% then 1378 / 100 X 20 = 275.6 so 1378
                        - 275.6 = 1102.4 will get credited into seller's wallet.
                    </li>
                    <li>
                       275.6  is commission for Admin and 1102.4 is earning of seller .
                    </li>
                    <li>
                        If Order status is delivered then only seller will get earning.
                    </li>
                    <li>
                        Ex - 1. Order placed on 11-Aug-21 and product return days are set to 0 so 11-Aug + 0 days =
                        11-Aug seller earning will get credited when admin is logged in admin panel.
                    </li>
                    <li>
                        Ex - 2. Order placed on 11-Aug-21 and product return days are set to 7 so 11-Aug + 7 days =
                        18-Aug seller earning will get credited when admin is logged in admin panel.
                    </li>
                    
                </ol>
            </b-container>
            <template #modal-footer>
                <b-button variant="secondary" size="sm" class="float-right" @click="commissionRule=false">Close
                </b-button>
            </template>
        </b-modal>
    </div>
</template>
<script>
import {VuejsDatatableFactory} from 'vuejs-datatable';
import axios from "axios";
import Select2 from 'v-select2-component';

import Multiselect from 'vue-multiselect';
import {gmapApi} from 'vue2-google-maps';
import Editor from '@tinymce/tinymce-vue';

import Auth from '../../Auth.js';

export default {
    components: {
        VuejsDatatableFactory,
        Select2,
        Multiselect,
        'editor': Editor
    },
    data: function () {
        return {
            login_user: Auth.user,

            isLoading: false,
            center: {lat: 0, lng: 0},
            map:"",
            drawingManager:"",

            currentPlace: null,
            markers: [],
            place_name: "",
            formatted_address: "",
            infoWindow: {
                position: {lat: 0, lng: 0},
                open: false,
                template: ''
            },
            city: "",
            cities: [],
            stores: [],

            // Seller Information
            name: "",
            email: "",
            mobile: "",
            store_url: "-",
            password: "",
            showPassword: false,
            confirm_password: "",
            showConfirmPassword: false,

            // Store Information
            store_name: "",
            store_id: "",
            city_id: [],
            categories_ids: [],
            store_location: "",
            store_city: "",
            tax_name: "Gst",
            tax_number: "",
            pan_number: "",
            fssai_number: "",
            aadhar_number: "",
            category_name: "",
            commission: "",
            store_description: "",

            // Location
            lat_long: "",
            latitude: "",
            longitude: "",

            // File uploads
            store_logo: "",
            store_logo_url: "",
            national_id_card: "",
            national_id_card_url: "",
            national_id_card_name: "",
            address_proof: "",
            address_proof_url: "",
            address_proof_name: "",
            pan_img: "",
            pan_img_url: "",
            fssai_img: "",
            fssai_img_url: "",
            store_images: [],
            store_images_urls: [],

            // Other
            categories: [],
            id: null,
            admin_id: null,
            record: null,
            status: 0,
            remark: "",

            commissionRule: false,
            commissionvalidationError: null,
            isFormLoaded: false,
            isUserTyping: false,

            // Settings
            require_products_approval: 0,
            view_order_otp: 0,
            assign_delivery_boy: 0,
            change_order_status_delivered: 0,

            // Self Pickup fields
            self_pickup_mode: 0,
            pickup_store_address: "",
            pickup_latitude: "",
            pickup_longitude: "",
            pickup_store_timings: "",

            // Pickup map properties
            pickupCenter: {lat: 0, lng: 0},
            pickupMarkers: [],
            pickupInfoWindow: {
                position: {lat: 0, lng: 0},
                open: false,
                template: ''
            },
            pickupCurrentPlace: null,

            // Store timings (single time range)
            storeTimings: {
                opening_time: '09:00',
                closing_time: '18:00'
            },

            // Store settings for watcher
            store_settings: {
                one_seller_cart: 0,
                self_pickup_mode: 0
            }
        }
    },
    watch: {
        // Auto-disable self pickup when one seller cart is turned off
        'store_settings.one_seller_cart'(newValue) {
            if (newValue == 0) {
                this.self_pickup_mode = 0;
            }
        }
    },
    created: function () {
        this.getCategories();
        this.getCities();
        this.getStores();
        this.getSellerCommission();
        this.getStoreSettings();

        this.id = this.$route.params.id;
        if(this.$roleSeller === this.login_user.role.name){
            this.id = this.login_user.seller.id;
        }

        if (this.id) {
            this.getSeller();
        }
    },
    computed: {
        categories_options: function () {
            var temp = [];
            if(this.categories.length !== 0 ) {
                this.categories.forEach(category => {
                    //Only Main Categories
                    if (category.parent_id == 0) {
                        temp.push({id: category.id, text: category.name})
                    }
                });
            }
            return temp;
        },
        cities_options: function () {
            var temp = [];
            if(this.cities.length !== 0 ) {
                this.cities.forEach(city => {
                        temp.push({id: city.id, text: city.name +'-'+ city.zone})
                });
            }
            return temp;
        },
        stores_options: function () {
            var temp = [];
            if(this.stores.length !== 0 ) {
                this.stores.forEach(store => {
                    temp.push({id: store.id, text: store.name})
                });
            }
            return temp;
        },
        google: gmapApi
    },
    methods: {

         async initMap() {
            if (!window.google || !google.maps) {
                console.error("Google Maps API is not loaded.");
                return;
            }

            // Initialize Drawing Manager if not already initialized
            if (!this.drawingManager) {
                this.drawingManager = new google.maps.drawing.DrawingManager({
                    drawingMode: null,
                    drawingControl: true,
                    drawingControlOptions: {
                        position: google.maps.ControlPosition.TOP_CENTER,
                        drawingModes: ['marker', 'circle', 'polygon', 'polyline', 'rectangle']
                    },
                    markerOptions: { draggable: true },
                    circleOptions: {
                        fillColor: '#ffff00',
                        fillOpacity: 0.5,
                        strokeWeight: 2,
                        clickable: false,
                        editable: true,
                        zIndex: 1
                    }
                });

                this.drawingManager.setMap(this.$refs.gmap.$mapObject);
            }
        },
        
        getCities() {
            this.isLoading = true
            axios.get(this.$apiUrl + '/cities')
                .then((response) => {
                    this.isLoading = false
                    let data = response.data;
                    this.cities = data.data
                }).catch(error => {
                this.isLoading = false;
                if (error?.request?.statusText) {
                    this.showError(error.request.statusText);
                }else if (error.message) {
                    this.showError(error.message);
                } else {
                    this.showError(__('something_went_wrong'));
                }
            });
        },
        getCategories() {

            this.isLoading = true
            axios.get(this.$apiUrl + '/categories/main')
                .then((response) => {
                    this.isLoading = false
                    let data = response.data;
                    this.categories = data.data;
                }).catch(error => {
                this.isLoading = false;
                if (error?.request?.statusText) {
                    this.showError(error.request.statusText);
                }else if (error.message) {
                    this.showError(error.message);
                } else {
                    this.showError(__('something_went_wrong'));
                }
            });
        },
        getSellerCommission() {
            axios.get(this.$sellerApiUrl + '/seller_commission')
                .then((response) => {
                    let data = response.data;
                    this.commission = data.data.value;
                });
        },
        
        getStoreSettings() {
            axios.get(this.$apiUrl + '/store_settings')
                .then((response) => {
                    let data = response.data.data;
                    this.store_settings = data.store_settingsObject;

                    // Load store settings values
                    data.store_settings.forEach((item) => {
                        if (item.variable === 'one_seller_cart') {
                            this.store_settings.one_seller_cart = (item.value === '1') ? 1 : 0;
                        }
                        if (item.variable === 'self_pickup_mode') {
                            this.store_settings.self_pickup_mode = (item.value === '1') ? 1 : 0;
                        }
                    });
                });
        },

        getStores() {
            axios.get(this.$apiUrl + '/get-all-stores-data')
                .then((response) => {
                    // API returns array directly, not wrapped in data.data
                    this.stores = Array.isArray(response.data) ? response.data : (response.data.data || []);
                }).catch(error => {
                    if (error?.request?.statusText) {
                        this.showError(error.request.statusText);
                    } else if (error.message) {
                        this.showError(error.message);
                    }
                });
        },

        setPlace(place) {
            this.currentPlace = place;
            this.addMarker()
        },
        addMarker() {
            if (this.currentPlace) {
                const lat = this.currentPlace.geometry.location.lat();
                const lng = this.currentPlace.geometry.location.lng();
                const marker = {
                    lat: lat,
                    lng: lng,
                    draggable: true,
                };
                this.markers.push({position: marker});
                this.center = marker;

                this.latitude = lat;
                this.longitude = lng;
                this.lat_long = `${lat},${lng}`;

                this.place_name = this.currentPlace.name;
                this.formatted_address = this.currentPlace.formatted_address;

                this.infoWindow.position = {lat: lat, lng: lng}
                this.infoWindow.template = `<b>${this.place_name}</b><br>${this.formatted_address}`
                this.infoWindow.open = true;
                this.currentPlace = null;
            }
        },

        async getCurrentLocation() {
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(
                    async (position) => {
                        this.latitude = position.coords.latitude;
                        this.longitude = position.coords.longitude;
                        this.lat_long = `${this.latitude},${this.longitude}`;
                        await this.mapConfig({ lat: this.latitude, lng: this.longitude });
                    },
                    (error) => {
                        this.showError("Geolocation is not supported or permission denied.");
                        console.error(error);
                    }
                );
            } else {
                this.showError("Geolocation is not supported by this browser.");
            }
        },
        async handleMapClick(event) {
            const latLng = {
                lat: event.latLng.lat(),
                lng: event.latLng.lng()
            };
            this.latitude = latLng.lat;
            this.longitude = latLng.lng;
            await this.mapConfig(latLng);
        },
        async mapConfig(latlng) {
        if (!window.google || !google.maps) return;

        const geocoder = new google.maps.Geocoder();
        geocoder.geocode({ location: latlng }, (results, status) => {
            if (status === "OK" && results[1]) {
                const clickedPlace = results[1];
                const addressArr = clickedPlace.formatted_address.split(",");
                
                this.street = addressArr[0] + " " + (addressArr[1] || "");
                this.place_name = addressArr[1] || "";
                this.formatted_address = clickedPlace.formatted_address;

                this.infoWindow = {
                    position: { lat: this.latitude, lng: this.longitude },
                    template: `<b>${this.place_name}</b><br>${this.formatted_address}`,
                    open: true
                };

                // Update markers
                const marker = {
                    position: { lat: this.latitude, lng: this.longitude },
                    draggable: true
                };
                this.markers = [marker];
                this.center = marker.position;

            } else {
                console.warn("No results found or geocoder failed:", status);
            }
        });
    },


        updateCoordinates(location) {
            this.handleMapClick(location);
        },
        setCityId() {
            this.state = this.city.state;
            this.city_id = this.city.id;
        },
        // Turn "1,2", 1, [1,2] or [{id: 1}] into ["1","2"] for the multi selects.
        toIdList(value) {
            if (value === null || value === undefined || value === "") {
                return [];
            }
            const list = Array.isArray(value) ? value : String(value).split(",");
            return list
                .map(item => String(item && item.id !== undefined ? item.id : item).trim())
                .filter(item => item !== "");
        },
        handleFileStoreLogo() {
            this.store_logo = this.$refs.file_store_logo.files[0];
            this.store_logo_url = URL.createObjectURL(this.store_logo);
        },
        dropFileStoreLogo(event) {
            event.preventDefault();
            this.$refs.file_store_logo.files = event.dataTransfer.files;
            this.handleFileStoreLogo(); // Trigger the onChange event manually
            // Clean up
            event.currentTarget.classList.add('bg-gray-100');
            event.currentTarget.classList.remove('bg-green-300');
        },

        handleFileNationalIdCard() {
            this.national_id_card = this.$refs.file_national_id_card.files[0];
            this.national_id_card_url = URL.createObjectURL(this.national_id_card);
        },

        dropFileNationalIdCard(event) {
            event.preventDefault();
            this.$refs.file_national_id_card.files = event.dataTransfer.files;
            this.handleFileNationalIdCard(); // Trigger the onChange event manually
            // Clean up
            event.currentTarget.classList.add('bg-gray-100');
            event.currentTarget.classList.remove('bg-green-300');
        },

        handleFileAddressProof() {
            this.address_proof = this.$refs.file_address_proof.files[0];
            this.address_proof_url = URL.createObjectURL(this.address_proof);
            this.address_proof_name = this.address_proof.name;
        },
        dropFileAddressProof(event) {
            event.preventDefault();
            this.$refs.file_address_proof.files = event.dataTransfer.files;
            this.handleFileAddressProof();
            event.currentTarget.classList.add('bg-gray-100');
            event.currentTarget.classList.remove('bg-green-300');
        },

        // PAN Image handlers
        handleFilePanImg() {
            this.pan_img = this.$refs.file_pan_img.files[0];
            this.pan_img_url = URL.createObjectURL(this.pan_img);
        },
        dropFilePanImg(event) {
            event.preventDefault();
            this.$refs.file_pan_img.files = event.dataTransfer.files;
            this.handleFilePanImg();
            event.currentTarget.classList.add('bg-gray-100');
            event.currentTarget.classList.remove('bg-green-300');
        },

        // FSSAI Image handlers
        handleFileFssaiImg() {
            this.fssai_img = this.$refs.file_fssai_img.files[0];
            this.fssai_img_url = URL.createObjectURL(this.fssai_img);
        },
        dropFileFssaiImg(event) {
            event.preventDefault();
            this.$refs.file_fssai_img.files = event.dataTransfer.files;
            this.handleFileFssaiImg();
            event.currentTarget.classList.add('bg-gray-100');
            event.currentTarget.classList.remove('bg-green-300');
        },

        // Store Images (Multiple) handlers
        handleFileStoreImages() {
            this.store_images = Array.from(this.$refs.file_store_images.files);
            this.store_images_urls = this.store_images.map(file => URL.createObjectURL(file));
        },
        dropFileStoreImages(event) {
            event.preventDefault();
            this.$refs.file_store_images.files = event.dataTransfer.files;
            this.handleFileStoreImages();
            event.currentTarget.classList.add('bg-gray-100');
            event.currentTarget.classList.remove('bg-green-300');
        },

        // Helper to check if URL is an image
        isImage(url) {
            if (!url) return false;
            const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
            const ext = url.split('.').pop().toLowerCase();
            return imageExtensions.includes(ext);
        },

        validateCommission() {
          if (this.commission < 1 || this.commission > 100) {
                this.commissionvalidationError = "Percentage must be between 1 and 100.";
                this.commission = null;
            } else {
                this.commissionvalidationError = null;
            }
        },
        validateAccountNumber() {
          if (this.account_number < 0) {
                this.account_numbervalidationError = "Account Number must be numeric value.";
                this.account_number= null;
            } else {
                this.account_numbervalidationError = null;
            }
        },
        
        clearForm() {
            // Reset all form fields
            this.name = "";
            this.email = "";
            this.mobile = "";
            this.store_url = "";
            this.password = "";
            this.confirm_password = "";
            this.store_name = "";
            this.street = "";
            this.pincode_id = "";
            this.city_id = [];
            this.categories_ids = [];
            this.state = "";
            this.remark = "";
            this.account_number = "";
            this.ifsc_code = "";
            this.bank_name = "";
            this.account_name = "";
            this.commission = "";
            this.tax_name = "";
            this.tax_number = "";
            this.pan_number = "";
            this.latitude = "";
            this.longitude = "";
            this.store_description = "";
            this.require_products_approval = 0;
            // this.customer_privacy = 0;
            this.view_order_otp = 0;
            this.assign_delivery_boy = 0;
            this.change_order_status_delivered = 0;
            this.status = 0;
            this.store_logo = "";
            this.store_logo_url = "";
            this.national_id_card = "";
            this.national_id_card_url = "";
            this.national_id_card_name = "";
            this.address_proof = "";
            this.address_proof_url = "";
            this.address_proof_name = "";
            this.place_name = "";
            this.formatted_address = "";
            this.markers = [];
            this.infoWindow.open = false;
            
            // Reset validation errors
            this.mobilevalidationError = null;
            this.commissionvalidationError = null;
            this.account_numbervalidationError = null;
            
            // Reset form loaded flag
            this.isFormLoaded = false;
        },
        
        onInputFocus() {
            // Set flag when user starts typing
            this.isUserTyping = true;
        },
        
        onInputBlur() {
            // Reset flag when user stops typing (with a small delay)
            setTimeout(() => {
                this.isUserTyping = false;
            }, 1000);
        },
        getSeller() {
            // Prevent multiple calls and form refilling
            if (this.isFormLoaded || this.isUserTyping) {
                return;
            }

            axios.get(this.$apiUrl + '/sellers/edit/' + this.id)
                .then((response) => {
                    this.isLoading = false
                    let data = response.data;
                    if (data.status === 1) {
                        // Set flag to prevent refilling
                        this.isFormLoaded = true;

                        this.record = data.data
                        this.admin_id = this.record.admin?.id ?? this.record.admin_id;
                        this.name = this.record.admin?.username ?? this.record.name;
                        this.email = this.record.admin?.email ?? this.record.email;
                        this.mobile = this.record.mobile || "";

                        this.store_url = this.record.store_url;
                        this.password = "";
                        this.confirm_password = "";

                        // Store Information
                        this.store_name = this.record.store_name;
                        this.store_id = this.record.store_id;
                        // city_id / categories may arrive as a comma separated
                        // string, a bare number (city_id is a bigint column on
                        // some databases) or already as an array, so normalise
                        // instead of calling split() blindly.
                        this.city_id = this.toIdList(this.record.city_id);
                        this.categories_ids = this.toIdList(this.record.categories);
                        this.store_location = this.record.store_location || "";
                        this.store_city = this.record.store_city || "";
                        this.tax_name = this.record.tax_name;
                        this.tax_number = this.record.tax_number;
                        this.pan_number = this.record.pan_number;
                        this.fssai_number = this.record.fssai_number || "";
                        this.aadhar_number = this.record.aadhar_number || "";
                        this.category_name = this.record.category_name || "";
                        this.commission = this.record.commission;
                        this.store_description = this.record.store_description;
                        this.remark = this.record.remark;
                        this.status = this.record.status;

                        // Location - Parse lat_long string to get latitude and longitude
                        this.lat_long = this.record.lat_long ? String(this.record.lat_long) : "";

                        // Parse lat_long string (format: "latitude,longitude")
                        if (this.lat_long && this.lat_long.includes(',')) {
                            const [lat, lng] = this.lat_long.split(',');
                            this.latitude = parseFloat(lat.trim());
                            this.longitude = parseFloat(lng.trim());
                        } else {
                            // Fallback to separate fields if available
                            this.latitude = this.record.latitude;
                            this.longitude = this.record.longitude;

                            // If lat_long is empty but we have separate lat/long, combine them
                            if (!this.lat_long && this.latitude && this.longitude) {
                                this.lat_long = `${this.latitude},${this.longitude}`;
                            }
                        }

                        this.place_name = this.record.place_name;
                        this.formatted_address = this.record.formatted_address;

                        // Settings
                        this.require_products_approval = this.record.require_products_approval || 0;
                        this.view_order_otp = this.record.view_order_otp;
                        this.assign_delivery_boy = this.record.assign_delivery_boy;
                        this.change_order_status_delivered = this.record.change_order_status_delivered;
                        
                        // Self Pickup fields
                        this.self_pickup_mode = this.record.self_pickup_mode || 0;
                        this.pickup_store_address = this.record.pickup_store_address || "";
                        this.pickup_latitude = this.record.pickup_latitude || "";
                        this.pickup_longitude = this.record.pickup_longitude || "";
                        
                        // Load store timings
                        if (this.record.pickup_store_timings) {
                            try {
                                const parsedTimings = JSON.parse(this.record.pickup_store_timings);
                                // Handle both old array format and new object format
                                if (Array.isArray(parsedTimings)) {
                                    // Convert old format to new format (use first day's timings)
                                    const firstDay = parsedTimings.find(day => day.is_open);
                                    if (firstDay) {
                                        this.storeTimings = {
                                            opening_time: firstDay.opening_time || '09:00',
                                            closing_time: firstDay.closing_time || '18:00'
                                        };
                                    }
                                } else {
                                    this.storeTimings = parsedTimings;
                                }
                            } catch (e) {
                                console.log('Error parsing store timings:', e);
                            }
                        }
                        
                        // Set pickup map marker if coordinates exist
                        if (this.pickup_latitude && this.pickup_longitude) {
                            this.pickupCenter = {
                                lat: parseFloat(this.pickup_latitude),
                                lng: parseFloat(this.pickup_longitude)
                            };
                            this.pickupMarkers = [{
                                position: {
                                    lat: parseFloat(this.pickup_latitude),
                                    lng: parseFloat(this.pickup_longitude)
                                }
                            }];
                            this.pickupInfoWindow.position = {
                                lat: parseFloat(this.pickup_latitude),
                                lng: parseFloat(this.pickup_longitude)
                            };
                            this.pickupInfoWindow.template = `<b>Pickup Location</b><br>${this.pickup_store_address}`;
                        }
                        
                        // File URLs - Use URL accessors from backend to handle both relative and absolute paths
                        this.store_logo_url = this.record.logo_url || "";
                        this.national_id_card_url = this.record.national_identity_card_url || "";
                        this.address_proof_url = this.record.address_proof_url || "";
                        this.pan_img_url = this.record.pan_img_url || "";
                        this.fssai_img_url = this.record.fssai_img_url || "";

                        // Store images - Use URL accessor from backend
                        this.store_images_urls = this.record.store_images_urls || [];

                        // Set map marker
                        if (this.latitude && this.longitude) {
                            const lat = parseFloat(this.latitude);
                            const lng = parseFloat(this.longitude);
                            const marker = {
                                lat: lat,
                                lng: lng,
                                draggable: true,
                            }
                            this.markers.push({position: marker});
                            this.center = marker;

                            // Use store_location and store_city as fallbacks for info window
                            const displayName = this.place_name || this.store_name || 'Store Location';
                            const displayAddress = this.formatted_address || `${this.store_location}, ${this.store_city}`;

                            this.infoWindow.position = {lat: lat, lng: lng}
                            this.infoWindow.template = `<b>${displayName}</b><br>${displayAddress}`
                            this.infoWindow.open = true;

                            // Set the location autocomplete input value
                            this.$nextTick(() => {
                                if (this.$refs.locationAutocomplete && this.$refs.locationAutocomplete.$el) {
                                    this.$refs.locationAutocomplete.$el.value = displayAddress;
                                }
                            });
                        }

                    } else {
                        this.showError(data.message);
                        setTimeout(() => {
                            this.$router.back();
                        }, 1000);
                    }
                }).catch(error => {
                    this.isLoading = false;
                    if (error?.request?.statusText) {
                        this.showError(error.request.statusText);
                    }else if (error.message) {
                        this.showError(error.message);
                    } else {
                        this.showError(__('something_went_wrong'));
                    }
                });
        },
        saveRecord: function () {
            this.isLoading = true;
            let vm = this;
            let formData = new FormData();

            // Check if we're editing (update) or creating (new)
            const isEditing = !!this.id;

            if (isEditing) {
                // UPDATE MODE: Only append fields that have values
                // This ensures only provided fields are updated in the database

                if (this.name) formData.append('name', this.name);
                if (this.email) formData.append('email', this.email);
                if (this.mobile) formData.append('mobile', this.mobile);
                if (this.password) {
                    formData.append('password', this.password);
                    formData.append('confirm_password', this.confirm_password);
                }
                if (this.store_name) formData.append('store_name', this.store_name);
                if (this.store_id) formData.append('store_id', this.store_id);
                if (this.store_url) formData.append('store_url', this.store_url);
                if (this.store_description) formData.append('store_description', this.store_description);
                if (this.lat_long) formData.append('lat_long', this.lat_long);
                if (this.store_location) formData.append('store_location', this.store_location);
                if (this.store_city) formData.append('store_city', this.store_city);
                if (this.tax_name) formData.append('tax_name', this.tax_name);
                formData.append('tax_number', this.tax_number || '');
                if (this.categories_ids) formData.append('categories_ids', this.categories_ids);
                if (this.city_id) formData.append('city_id', this.city_id);
                if (this.pan_number) formData.append('pan_number', this.pan_number);
                if (this.commission) formData.append('commission', this.commission);
                if (this.fssai_number) formData.append('fssai_number', this.fssai_number);
                if (this.aadhar_number) formData.append('aadhar_number', this.aadhar_number);
                if (this.category_name) formData.append('category_name', this.category_name);
                formData.append('status', this.status);
                if (this.remark) formData.append('remark', this.remark);

            } else {
                // CREATE MODE: Append all required fields for new registration
                formData.append('name', this.name);
                formData.append('email', this.email);
                formData.append('mobile', this.mobile);
                formData.append('password', this.password);
                formData.append('confirm_password', this.confirm_password);
                formData.append('store_name', this.store_name);
                formData.append('store_id', this.store_id);
                formData.append('store_url', this.store_url);
                formData.append('store_description', this.store_description);
                formData.append('lat_long', this.lat_long);
                formData.append('store_location', this.store_location);
                formData.append('store_city', this.store_city);
                formData.append('tax_name', this.tax_name);
                formData.append('tax_number', this.tax_number);

                // Optional/Nullable fields for create
                if (this.categories_ids) formData.append('categories_ids', this.categories_ids);
                if (this.city_id) formData.append('city_id', this.city_id);
                if (this.pan_number) formData.append('pan_number', this.pan_number);
                if (this.commission) formData.append('commission', this.commission);
                if (this.fssai_number) formData.append('fssai_number', this.fssai_number);
                if (this.aadhar_number) formData.append('aadhar_number', this.aadhar_number);
                if (this.category_name) formData.append('category_name', this.category_name);
            }

            // File uploads - Only append if new files are selected
            if (this.national_id_card && this.national_id_card instanceof File) {
                formData.append('national_id_card', this.national_id_card);
            }
            if (this.store_logo && this.store_logo instanceof File) {
                formData.append('store_logo', this.store_logo);
            }
            if (this.pan_img && this.pan_img instanceof File) {
                formData.append('pan_img', this.pan_img);
            }
            if (this.fssai_img && this.fssai_img instanceof File) {
                formData.append('fssai_img', this.fssai_img);
            }

            // Store images (multiple files)
            if (this.store_images && this.store_images.length > 0) {
                this.store_images.forEach((file, index) => {
                    formData.append('store_images[]', file);
                });
            }

            // File uploads - Optional
            if (this.address_proof && this.address_proof instanceof File) {
                formData.append('address_proof', this.address_proof);
            }

            // Use different API endpoints for create vs update
            let url;
            if (isEditing) {
                url = this.$apiUrl + '/seller/update-seller-from-admin/' + this.id;
            } else {
                url = this.$apiUrl + '/seller/post-registration-data-dev-from-admin';
            }

            axios.post(url, formData, {
                headers: {
                    'Content-Type': 'multipart/form-data'
                }
            }).then(res => {
                let data = res.data;
                if (data.status === 1) {
                    setTimeout(
                        function () {
                            vm.$swal.close();
                            if(vm.$roleSeller === vm.login_user.role.name){
                                vm.$router.push({path: '/seller/profile'})
                            }else{
                                vm.$router.push({path: '/sellers'})
                            }
                            vm.isLoading = false;
                            vm.showMessage("success", data.message);
                        }, 2000);
                } else {
                    vm.showError(data.message);
                    vm.isLoading = false;
                }
            }).catch(error => {
                if (error?.request?.statusText) {
                    this.showError(error.request.statusText);
                } else if (error.message) {
                    this.showError(error.message);
                } else {
                    this.showError(__('something_went_wrong'));
                }
                vm.isLoading = false;
            });
        },
        
        // Self Pickup methods (similar to EditCity.vue)
        setPickupPlace(place) {
            this.pickupCurrentPlace = place;
            this.addPickupMarker();
        },
        
        addPickupMarker() {
            if (this.pickupCurrentPlace) {
                const marker = {
                    lat: this.pickupCurrentPlace.geometry.location.lat(),
                    lng: this.pickupCurrentPlace.geometry.location.lng(),
                };
                this.pickupMarkers = [{position: marker}];
                this.pickupCenter = marker;
                this.pickup_latitude = this.pickupCurrentPlace.geometry.location.lat();
                this.pickup_longitude = this.pickupCurrentPlace.geometry.location.lng();
                
                // Auto-fill the pickup store address with the full formatted address
                this.pickup_store_address = this.pickupCurrentPlace.formatted_address;
                
                this.pickupInfoWindow.position = {lat: this.pickup_latitude, lng: this.pickup_longitude};
                this.pickupInfoWindow.template = `<b>${this.pickupCurrentPlace.name}</b><br>${this.pickup_store_address}`;
                this.pickupInfoWindow.open = true;
                this.pickupCurrentPlace = null;
            }
        },
        
        onPickupMarkerDragEnd(event) {
            const lat = event.latLng.lat();
            const lng = event.latLng.lng();
            
            this.pickup_latitude = lat.toString();
            this.pickup_longitude = lng.toString();
            
            // Update marker position
            this.pickupMarkers = [{
                position: { lat: lat, lng: lng }
            }];
            
            // Update info window
            this.pickupInfoWindow.position = { lat: lat, lng: lng };
            this.pickupInfoWindow.template = `<b>Selected Location</b><br>Lat: ${lat.toFixed(6)}, Lng: ${lng.toFixed(6)}`;
            this.pickupInfoWindow.open = true;
        }
    },
    mounted() {
    this.$refs.mapRef.$mapPromise.then((map) => {
      this.map = map;

      // Set initial map center
      const defaultCenter = {
        lat: parseFloat(this.city.latitude) || 17.4486,
        lng: parseFloat(this.city.longitude) || 78.3908,
      };
      this.center = defaultCenter;
      this.markers = [{ position: defaultCenter }];
      this.infoWindow = {
        position: defaultCenter,
        template: `<b>${this.city.name || "Default City"}</b><br>${this.city.formatted_address || "Address"}`,
        open: true,
      };

      // ✅ Wait for the Drawing library before initializing
      const waitForDrawingLib = setInterval(() => {
        if (window.google && google.maps && google.maps.drawing) {
          clearInterval(waitForDrawingLib);
          this.initDrawingManager(); // initialize drawing
          if (this.city.boundary_points) {
            this.setMapOverlay(); // restore previous shapes
          }
        }
      }, 300);
    });
  },
};
</script>
<style scoped>
@import "../../../../node_modules/vue-multiselect/dist/vue-multiselect.min.css";
</style>

