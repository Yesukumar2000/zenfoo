<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>
                        <template v-if="clone">
                            {{ __('clone') }}
                        </template>
                        <template v-else-if="id">
                            {{ __('edit') }}
                        </template>
                        <template v-else>
                            {{ __('create') }}
                        </template>
                        {{ __('product') }}
                    </h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                             <!-- Conditionally render breadcrumb item based on the current route -->
                            <li class="breadcrumb-item" v-if="isSellerRoute">
                                <router-link to="/seller/dashboard">{{ __('dashboard') }}</router-link>
                            </li>
                            <li class="breadcrumb-item" v-else>
                                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
                            </li>
                                                    <!-- Conditionally render breadcrumb item based on the current route -->
                            <li class="breadcrumb-item" v-if="isSellerRoute">
                                <router-link to="/seller/manage_products">{{ __('manage_products') }}</router-link>
                            </li>
                            <li class="breadcrumb-item" v-else>
                                <router-link :to="manageProductsPath">{{__('manage_products') }}</router-link>
                            </li>

                            <li class="breadcrumb-item active" aria-current="page">
                                 <template v-if="clone">
                                    {{ __('clone') }}
                                </template>
                                <template v-else-if="id">
                                    {{ __('edit') }}
                                </template>
                                <template v-else>
                                    {{ __('create') }}
                                </template>
                                {{ __('product') }}
                            </li>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link v-if="isSellerRoute" to="/seller/manage_products" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                    <router-link v-else :to="manageProductsPath" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <div class="row">
                <div class="col-12 col-md-12 order-md-1 order-last" id="mymodal">
                    <form ref="my-form" @submit.prevent="saveRecord" @keydown.enter="$event.preventDefault()">
                        <div class="card">
                            <div class="card-header">
                                <h4><template v-if="clone">{{ __('clone') }}</template><template v-else-if="id">{{ __('edit') }}</template><template v-else>{{ __('create') }}</template> {{ __('product') }}</h4>
                                <span class="pull-right">
                                    <template v-if="$roleSeller == login_user.role.name">
                                        <router-link to="/seller/manage_products" class="btn btn-primary" v-b-tooltip.hover title="Manage Product">{{ __('manage_products') }}</router-link>
                                    </template>
                                    <template v-else>
                                        <router-link :to="manageProductsPath" class="btn btn-primary" v-b-tooltip.hover title="Manage Product">{{ __('manage_products') }}</router-link>
                                    </template>
                                </span>
                            </div>
                            <div class="card-body">

                                <label><span class="text-danger text-xs">*</span> {{__('required_fields')}}</label>
                                <!-- <div class="divider"><div class="divider-text">{{__('add_product_form')}}</div></div> -->

                                <div class="row">
                                    <div class="col-md-6">
                                        <label>{{ __('product_name') }}
                                            <i class="text-danger">*</i>
                                        </label>
                                        <input type="text" class="form-control" :placeholder="__('enter_product_name')" v-model="name" v-on:keyup="createSlug" required>
                                    </div>
                                    
                                    
                                    <!-- <div class="col-md-6">
                                        <label>
                                            {{ __('slug') }}
                                            <i class="text-danger">*</i>
                                        </label>
                                        <input type="text" class="form-control" :placeholder="__('enter_product_slug')" v-model="slug" readonly>
                                    </div> -->

                                    <template v-if="this.$roleSeller == login_user.role.name">
                                        <input type="hidden" v-model="seller_id">
                                    </template>
                                    <template v-else-if="store_id == 15">
                                        <div class="col-md-6">
                                            <label class="control-label" for="seller_id">{{ __('seller') }}
                                                <i class="text-danger">*</i>
                                            </label>
                                            <select id="seller_id" name="seller_id" class="form-control form-select"
                                                    v-model="seller_id" required @change="getSellerCategories(); getSeller()">
                                                <option value="">{{ __('select_seller') }}</option>
                                                <option v-for="seller in sellers" :value="seller.id">{{ seller.name }}
                                                </option>
                                            </select>
                                        </div>
                                    </template>
                                    <!-- Tax dropdown hidden — tax_id hardcoded to 5 -->
                                    <!-- <div class="col-md-6">
                                        <label for="tax_id" class="control-label">{{ __('tax') }}</label>
                                        <select id="tax_id" name="tax_id" class="form-control form-select"
                                                v-model="tax_id">
                                            <option value="0">Select Tax</option>
                                            <option v-for="tax in taxes" :value="tax.id">{{ tax.title }} ({{ tax.percentage }} %)</option>
                                        </select>
                                    </div> -->
                                  <!-- Tags (optional) hidden
                                  <div class="col-md-6">
                                    <div class="form-group">
                                    <label for="tags" class="control-label">{{ __('tags') }} ( {{ __('these_tags_help_you_in_search_result') }} )</label>

                                            <Select2 v-model="tag_ids"
                             placeholder="Select Tags"
                             no-add-on-enter
                             :options="tagsOptions"
                             separator=" ,;"
                             :settings="{ tags: true,
                                multiple: true,
                                width: '100%',
                                dropdownParent: '#mymodal',
                                tokenSeparators: [',', ';'],
                                placeholder: __('enter_product_tag'), }" />
                                    </div>
                                </div>
                                  -->
                                    <!-- <div class="col-md-6">
                                        <div class="form-group mt-3">
                                            <button
                                                type="button"
                                                class="btn btn-outline-primary mt-2"
                                                @click="generateDescription"
                                                >
                                                {{ __('generate_description_with_ai') }}
                                            </button>
                                        </div>
                                    </div> -->
                                    <!-- <div class="col-md-6">
                                        <div class="form-group mt-3">
                                            <label>
                                                <input type="checkbox" v-model="useCustomPrompt" />
                                                {{ __('use_custom_prompt') }}
                                            </label>
                                        </div>
                                    </div> -->

                                        <!-- <div class="form-group mt-2" v-if="useCustomPrompt">
                                        <label>{{ __('custom_prompt') }}</label>
                                        <textarea
                                            class="form-control"
                                            v-model="customPrompt"
                                            rows="3"
                                            placeholder="e.g. Write a fun and engaging description focusing on features and benefits"
                                        ></textarea>
                                        </div> -->

                                    <div class="col-md-12">
                                        <div class="form-group">
                                            <label>{{ __('description') }} <i class="text-danger">*</i></label>
                                            <!-- <editor
                                                :placeholder="__('enter_product_description')"
                                                v-model="description"

                                                :init="{
                                                    height:400,
                                                    plugins: this.$editorPlugins ,
                                                    toolbar: this.$editorToolbar,
                                                    font_size_formats: this.$editorFont_size_formats,
                                                   }"
                                            /> -->
                                            <textarea
                                                class="form-control"
                                                v-model="description"
                                                :placeholder="__('enter_product_description')"
                                                rows="10"
                                                required
                                            ></textarea>
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>{{ __('main_image')}} <i class="text-danger">*</i></label>
                                            <input type="file" name="image" accept="image/*" ref="file_image" v-on:change="fileImage" class="file-input">

                                            <div class="file-input-div bg-gray-100" @click="$refs.file_image.click()" @drop="dropFile" @dragover="$dragoverFile" @dragleave="$dragleaveFile" >
                                                <template v-if="main_image_name == ''">
                                                    <label><i class="fa fa-cloud-upload-alt fa-2x"></i></label>
                                                    <label>{{ __('drop_files_here_or_click_to_upload') }}</label>
                                                </template>
                                                <template v-else>
                                                    <label>Selected file name:- {{ main_image_name }}</label>
                                                </template>
                                            </div>
                                            <!-- <span class="text text-primary"> *Please choose square image of larger than 350px*350px &amp; smaller than 550px*550px.</span> -->
                                            <p v-if="mainImageerror" class="error">{{ mainImageerror }}</p>

                                            <div class="row" v-if="main_image_path">
                                                <div class="col-md-4">
                                                    <img class="custom-image" :src="main_image_path" title='Main Image' alt='Main Image'/>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    <!-- Other Images -->
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label for="other_images">{{ __('other_images_of_the_product') }}</label>

                                            <input type="file" name="other_images[]" accept="image/*" id="other_images" v-on:change="otherImage" multiple="" ref="file_other_images" class="file-input">

                                            <div class="file-input-div bg-gray-100" @click="$refs.file_other_images.click()" @drop="dropFileOtherImage" @dragover="$dragoverFile" @dragleave="$dragleaveFile">
                                                <template v-if="images.length === 0 ">
                                                    <label><i class="fa fa-cloud-upload-alt fa-2x"></i></label>
                                                    <label>{{ __('drop_files_here_or_click_to_upload') }}</label>
                                                </template>
                                                <template v-else>
                                                    <template v-if="images.length === 1 ">
                                                        <label>Selected file name:- {{ images[0].name }}</label>
                                                    </template>
                                                    <template v-else>
                                                        <label>{{ images.length }} files Selected</label>
                                                        <span><small v-for="image in images">{{ image.name }}, </small></span>
                                                    </template>
                                                </template>
                                            </div>
                                            <p v-if="otherImageerror" class="error">{{ otherImageerror }}</p>

                                            <div class="row" v-if="images && images.length !== 0">
                                                <h6 class="mt-3">Seleted Other Image List.</h6>
                                                <div class="col-md-4 image-container" v-if="images.length !== 0" v-for="(image, index) in images">
                                                    <img class="img-thumbnail custom-image" :src="image.url" title='Selected Other Image' alt='Selected Other Image'/>
                                                    <button type="button" @click="removeOtherImage(images.indexOf(image))" class="btn btn-sm btn-danger btn-remove"> <i class="fa fa-times-circle"></i> </button>
                                                </div>
                                            </div>

                                            <div class="row" v-if="other_images && other_images.length !== 0">
                                                <h6 class="mt-3">Uploaded Other Image List.</h6>
                                                <div class="col-md-4 image-container" v-if="other_images.length !== 0" v-for="(image, index) in other_images">
                                                    <img class="img-thumbnail custom-image" :src="$mediaUrl(image.image)" title='Other Image' alt='Other Image'/>
                                                    <button type="button" @click="deleteImage(index, image.id, true)" class="btn btn-sm btn-danger btn-remove"> <i class="fa fa-times-circle"></i> </button>
                                                </div>
                                            </div>

                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- <div class="card">
                            <div class="card-header">
                                <h4>{{__('seo_settings')}}</h4>
                            </div>
                            <div class="card-body">
                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>{{ __('meta_title') }} </label>
                                            <input type="text" class="form-control" v-model="meta_title" :placeholder="__('enter_meta_title')">
                                        </div>
                                        <div class="form-group">
                                            <label>{{ __('meta_keywords') }} </label>
                                            <input type="text" class="form-control" v-model="meta_keywords" :placeholder="__('enter_meta_keywords')">
                                        </div>
                                        <div class="form-group">
                                            <label>{{ __('schema_markup') }} </label>
                                            <input type="text" class="form-control" v-model="schema_markup" :placeholder="__('enter_schema_markup')">
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>{{ __('meta_description') }} </label>
                                            <textarea type="text" class="form-control" v-model="meta_description" :placeholder="__('enter_meta_description')" rows="4"></textarea>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div> -->

                        <div class="card">
                            <div class="card-header">
                                <h4>Product Variants</h4>
                            </div>
                            <div class="card-body">
                                <div class="col-md-12">
                                    <div class="row">
                                        <div class="form-group col-md-6">
                                            <label>{{ __('type') }} <i class="text-danger">*</i></label><br>
                                            <b-form-radio-group
                                                v-model="type"
                                                :options="[
                                                        { text: ' Packet', 'value': 'packet' },
                                                        { text: ' Loose', 'value': 'loose' },
                                                        ]"
                                                buttons button-variant="outline-primary"
                                            ></b-form-radio-group>
                         
                                        </div>
                                        <div class="form-group col-md-6">
                                            <label class="control-label">{{ __('stock_limit') }} <i class="text-danger">*</i></label><br>
                                            <b-form-radio-group
                                                v-model="is_unlimited_stock"
                                                :options="[
                                                            { text: ' Limited', 'value': 0 },
                                                            { text: ' Unlimited', 'value': 1 },
                                                        ]"
                                                buttons
                                                button-variant="outline-primary"
                                            ></b-form-radio-group>
                                        </div>
                                    </div>
                                </div>

                                <div id="packate_div" class="list-group-item" v-if="type === 'packet'" v-for="(input,k) in inputs" :key="k">
                                    <div class="row">
                                        <div class="col-md-4">
                                            <div class="form-group">
                                                <label>{{ __('measurement') }}
                                                    <i class="text-danger">*</i>
                                                </label>
                                                <input type="number" step="any" min="0" class="form-control" placeholder="0"
                                                       v-model="input.packet_measurement">
                                            </div>
                                        </div>

                                        <div class="col-md-4">
                                            <div class="form-group">
                                                <label>{{ __('price') }} ( {{ $currency }} )
                                                 <i class="text-danger">*</i>
                                                </label>
                                                <input type="number"  min="0" step="any" class="form-control" placeholder="0.00"
                                                       v-model="input.packet_price" required>
                                            </div>
                                        </div>
                                        <div class="col-md-4">
                                            <div class="form-group">
                                                <label>{{__('discounted_price')}} ( {{ $currency }} )</label>
                                                <input type="number" min="0" step="any" class="form-control" placeholder="0.00"
                                                       v-model="input.discounted_price" @input="validateDiscountedPrice(input)">
                                                       <span v-if="input.validationErrorDiscountedPrice" class="error">{{ input.validationErrorDiscountedPrice }}</span>
                                            </div>
                                        </div>
                                        <div class="col-md-4" v-if="is_unlimited_stock!=1">
                                            <div class="form-group">
                                                <label>{{ __('stock') }}
                                                    <i class="text-danger">*</i>
                                                </label> 
                                                <input type="number" step="any" min="0" class="form-control" placeholder="0"
                                                       name="packate_stock[]" v-model="input.packet_stock">
                                            </div>
                                        </div>
                                        <div class="col-md-4">
                                            <div class="form-group">
                                                <label>{{ __('unit') }}
                                                 <i class="text-danger">*</i>
                                                </label>
                                                <select class="form-control form-select" @change="changeUnits()" v-model="input.packet_stock_unit_id">
                                                    <option value="">{{ __('select_unit') }}</option>

                                                    <option v-for="(unit,key) in units" :value="unit.id">{{ unit.short_code }}</option>
                                                </select>
                                            </div>
                                        </div>
                                        <div class="col-md-4">
                                            <div class="form-group">
                                                <label>{{ __('status') }}
                                                 <i class="text-danger">*</i>
                                                </label>
                                                <select class="form-control form-select" v-model="input.packet_status" required>
                                                    <option value="">{{ __('select_status') }}</option>
                                                    <option value="1">{{ __('available') }}</option>
                                                    <option value="0">{{ __('sold_out') }}</option>
                                                </select>
                                            </div>
                                        </div>
                                        <div class="col-md-12 hidden">
                                            <div class="form-group">
                                                <label>{{ __('variant_images') }}</label>
                                                <input type="file" accept="image/*" :ref="'packet_variant_images_'+k " multiple class="file-input"
                                                       v-on:change="variantImagesChanges(k)" >

                                                <div class="file-input-div bg-gray-100" @click="$refs['packet_variant_images_' + k][0].click()" @dragover="$dragoverFile" @dragleave="$dragleaveFile" >
                                                    <label><i class="fa fa-cloud-upload-alt fa-2x"></i></label>
                                                    <label>{{ __('drop_files_here_or_click_to_upload') }}</label>
                                                </div>

                                                <span class="text text-primary">Please choose square image of larger than 350px*350px &amp; smaller than 550px*550px.</span>
                                                <p v-if="variantImageerror" class="error">{{ variantImageerror }}</p>
                                                <div class="row">
                                                    <div class="col-md-2 image-container" v-for="(image, index) in variantImages[k]">
                                                        <img class="img-thumbnail custom-image" :src="image.url" title='Selected Variant Image' alt='Selected Variant Image'/>
                                                    </div>
                                                </div>

                                                <div class="row">
                                                    <div class="col-md-2 image-container" v-if="input.images.length !== 0" v-for="(image, index) in input.images">
                                                        <img class="img-thumbnail custom-image" :src="$mediaUrl(image.image)" title='Variant Image' alt='Variant Image'/>
                                                        <button type="button" @click="deleteImage(index, image.id, false, k)" class="btn btn-sm btn-danger btn-remove"> <i class="fa fa-times-circle"></i> </button>
                                                    </div>
                                                </div>

                                            </div>
                                        </div>



                                        <div class="col-md-12 text-end" v-if="k === 0">
                                            <a style="cursor: pointer;" class="btn btn-primary" v-b-tooltip.hover title="Add variant of product" @click="addRow">
                                                <i class="fa fa-plus-square"></i> {{ __('add_variant') }}
                                            </a>
                                        </div>
                                        <div class="col-md-12 text-end" v-if="k !== 0">
                                            <a style="cursor: pointer;" class="btn btn-danger" v-b-tooltip.hover title="Remove variant of product" @click="remove(k)">
                                                <i class="fa fa-times"></i> {{ __('remove_variant') }}
                                            </a>
                                        </div>

                                    </div>
                                </div>

                                <div id="loose_div" v-if="type === 'loose'">
                                    <div class="list-group-item" v-for="(input,k) in inputs" :key="k">
                                        <div class="row">
                                            <div class="col-md-4">
                                                <div class="form-group loose_div">
                                                    <label>{{ __('measurement') }}</label> <i class="text-danger">*</i>


                                                    <b-input-group class="mb-2">
                                                        <input type="number" step="any" min="0" class="form-control" placeholder="0" v-model="input.loose_measurement">
                                                    </b-input-group>



                                                </div>
                                            </div>

                                            <div class="col-md-4">
                                                <div class="form-group loose_div">
                                                    <label>{{ __('price') }} ( {{ $currency }} ):</label> <i class="text-danger">*</i>
                                                    <input type="number" step="any" min="0" class="form-control" placeholder="0.00"
                                                           v-model="input.loose_price" required>
                                                </div>
                                            </div>
                                            <div class="col-md-4">
                                                <div class="form-group loose_div">
                                                    <label for="discounted_price">{{ __('discounted_price') }} ( {{ $currency }} ):</label>
                                                    <input type="number" step="any"  min="0" class="form-control" placeholder="0.00" id="discounted_price"
                                                           v-model="input.loose_discounted_price" @input="validateDiscountedPriceLoose(input)">
                                                    <span v-if="input.validationErrorDiscountedPriceLoose" class="error">{{ input.validationErrorDiscountedPriceLoose }}</span>
                                                </div>
                                            </div>
                                            <div class="col-md-4" v-if="is_unlimited_stock!=1">
                                                <div class="form-group loose_div">
                                                    <label>{{ __('stock') }} </label> <i class="text-danger">*</i>
                                                    <input type="number" step="any" min="0" class="form-control" placeholder="0" v-model="input.loose_stock">
                                                </div>
                                            </div>
                                            <div class="col-md-4">
                                                <div class="form-group loose_div">
                                                    <label>{{ __('unit') }} <i class="text-danger">*</i></label>
                                                    <select class="form-control form-select" v-model="input.loose_stock_unit_id">
                                                        <option value="">{{ __('select_unit') }}</option>
                                                        <option v-for="(unit,key) in units" :value="unit.id">{{ unit.short_code }}</option>
                                                    </select>
                                                </div>
                                            </div>
                                            <div class="col-md-4">
                                                <div class="form-group loose_div">
                                                    <label>{{ __('status') }} <i class="text-danger">*</i></label>
                                                    <select class="form-control form-select" v-model="input.loose_status">
                                                        <option value="">{{ __('select_status') }}</option>
                                                        <option value="1">{{ __('available') }}</option>
                                                        <option value="0">{{ __('sold_out') }}</option>
                                                    </select>
                                                </div>
                                            </div>
                                            <div class="col-md-12 hidden">
                                                <div class="form-group loose_div">
                                                    <label>{{ __('variant_images') }}</label>
<!--                                                @drop="dropFileStoreLogo"               -->
                                                    <input type="file" accept="image/*" :ref="'loose_variant_images_'+k " multiple  class="file-input" v-on:change="variantImagesChanges(k)" @dragover="$dragoverFile" @dragleave="$dragleaveFile">
                                                    <div class="file-input-div bg-gray-100" @click="$refs['loose_variant_images_' + k][0].click()">
                                                        <label><i class="fa fa-cloud-upload-alt fa-2x"></i></label>
                                                        <label>{{ __('drop_files_here_or_click_to_upload') }}</label>
                                                    </div>


                                                    <span class="text text-primary">Please choose square image
                                                        of larger than 350px*350px &amp; smaller than
                                                        550px*550px.</span>


                                                    <div class="row">
                                                        <div class="col-md-2 image-container" v-if="input.loose_images.length !== 0" v-for="(image, index) in input.loose_images">
                                                            <img class="img-thumbnail custom-image" :src="$mediaUrl(image.image)" title='Variant Image' alt='Variant Image'/>
                                                            <button type="button" @click="deleteImage(index, image.id, false, k)" class="btn btn-sm btn-danger btn-remove"> <i class="fa fa-times-circle"></i> </button>
                                                        </div>
                                                    </div>

                                                    <div class="row">
                                                        <div class="col-md-4 image-container" v-if="variantImages[k].length !== 0" v-for="(image, index) in variantImages[k]">
                                                            <img class="img-thumbnail custom-image" :src="image.url" title='Selected Variant Image' alt='Selected Variant Image'/>
                                                        </div>
                                                    </div>

                                                </div>
                                            </div>


                                            <div class="col-md-12 text-end" v-if="k === 0">
                                                <a style="cursor: pointer;" class="btn btn-primary" v-b-tooltip.hover title="Add variant of product" @click="addRow">
                                                    <i class="fa fa-plus-square"></i> {{ __('add_variant') }}
                                                </a>
                                            </div>
                                            <div class="col-md-12 text-end" v-if="k !== 0">
                                                <a style="cursor: pointer;" class="btn btn-danger" v-b-tooltip.hover title="Remove variant of product" @click="remove(k)">
                                                    <i class="fa fa-times"></i> {{ __('remove_variant') }}
                                                </a>
                                            </div>
                                        </div>
                                    </div>
                                </div>


                            </div>
                        </div>


                        <div class="card">
                            <div class="card-header">
                                <h4>{{__('product_settings')}}</h4>
                            </div>
                            <div class="card-body">
                                <div class="row">

                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>{{ __('store') }} <i class="text-danger">*</i></label>

                                            <select class="form-control form-select" v-model="store_id"
                                                    v-html="storeOptions">
                                            </select>


                                        </div>
                                    </div>


                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>Category Group</label>

                                            <select class="form-control form-select" v-model="category_group_id"
                                                    v-html="categoryGroupOptions">
                                            </select>


                                        </div>
                                    </div>


                                    
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>Sub Category Group</label>

                                            <select class="form-control form-select" v-model="sub_category_group_id"
                                                    v-html="subCategoryGroupOptions">
                                            </select>


                                        </div>
                                    </div>

                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>{{ __('category') }} </label>

                                            <select class="form-control form-select" v-model="category_id"
                                                    v-html="categoryOptions">
                                            </select>


                                        </div>
                                    </div>

                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>{{ __('brands') }}</label>
                                            <multiselect v-model="brand"
                                                         :options="brands"
                                                         :placeholder="__('select_and_search_brands')"
                                                         label="name"
                                                         track-by="name">
                                                <template slot="singleLabel" slot-scope="props">
                                                    <span class="option__desc">
                                                        <span class="option__title">{{ props.option.name }}</span>
                                                    </span>
                                                </template>
                                                <template slot="option" slot-scope="props">
                                                    <div class="option__desc">
                                                        <span class="option__small">
                                                            <img style="height: 25px; " class="option__image" :src="props.option.image_url" alt="Brand Logo">
                                                        </span>
                                                        <span class="option__title">{{ props.option.name }}</span>
                                                    </div>
                                                </template>
                                            </multiselect>
                                        </div>
                                    </div>

                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>{{ __('food_type') }} <i class="text-danger">*</i></label><br>
                                            <b-form-radio-group
                                                v-model="product_type"
                                                :options="[
                                                    { text: ' Veg', 'value': '1' },
                                                    { text: ' Non-Veg', 'value': '2' },
                                                ]"
                                                buttons
                                                button-variant="outline-primary"
                                            ></b-form-radio-group>
                                        </div>
                                    </div>
                                    <!-- Skin / Skinless - For meat stores only -->
                                    <div class="col-md-6" v-if="isMeatStore">
                                        <div class="form-group">
                                            <label>Skin / Skinless</label><br>
                                            <b-form-radio-group
                                                v-model="is_skinned_one"
                                                :options="[
                                                    { text: ' Skinless', 'value': 0 },
                                                    { text: ' Skin', 'value': 1 },
                                                ]"
                                                buttons
                                                button-variant="outline-primary"
                                            ></b-form-radio-group>
                                        </div>
                                    </div>

                                    <!-- Fish Store Specific Fields -->
                                    <div class="col-md-6" v-if="store_id == 19">
                                        <div class="form-group">
                                            <label>Cleaned / Not Cleaned</label><br>
                                            <b-form-radio-group
                                                v-model="is_cleaned"
                                                :options="[
                                                    { text: ' Not Cleaned', 'value': 0 },
                                                    { text: ' Cleaned', 'value': 1 },
                                                ]"
                                                buttons
                                                button-variant="outline-primary"
                                            ></b-form-radio-group>
                                        </div>
                                    </div>

                                    <div class="col-md-6" v-if="store_id == 19">
                                        <div class="form-group">
                                            <label>Before Cleaning Weight</label>
                                            <input
                                                type="text"
                                                class="form-control"
                                                v-model="before_cleaning_weight"
                                                placeholder="e.g., 1 kg, 500g, 1.5 kg"
                                            >
                                            <small class="text-muted">Weight before cleaning (e.g., 1 kg)</small>
                                        </div>
                                    </div>

                                    <div class="col-md-6" v-if="store_id == 19">
                                        <div class="form-group">
                                            <label>After Cleaning Weight <i class="text-danger" v-if="is_cleaned == 1">*</i></label>
                                            <input
                                                type="text"
                                                class="form-control"
                                                v-model="after_cleaning_weight"
                                                placeholder="e.g., 10kg, 500g, 1.5 kg"
                                            >
                                            <small class="text-muted">Enter weight with unit (e.g., 10kg, 500g, 1.5 kg)</small>
                                        </div>
                                    </div>

                                    <div class="col-md-6" v-if="store_id == 19">
                                        <div class="form-group">
                                            <label>Pieces</label>
                                            <input
                                                type="text"
                                                class="form-control"
                                                v-model="pieces"
                                                placeholder="e.g., 7-11, 8, 10-12"
                                            >
                                            <small class="text-muted">Number or range of pieces (e.g., 7-11)</small>
                                        </div>
                                    </div>

                                    <!-- Video Upload - For all meat products -->
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>Product Video (Optional)</label>

                                            <!-- Display existing video if editing and no new upload -->
                                            <div v-if="existing_video_url && video_file_name == ''" class="mb-3 p-3 border rounded bg-light d-flex justify-content-between align-items-center">
                                                <div>
                                                    <i class="fa fa-video text-primary me-2"></i>
                                                    <span class="text-muted">Video uploaded</span>
                                                </div>
                                                <div>
                                                    <a :href="existing_video_url" target="_blank" class="btn btn-sm btn-info me-2">
                                                        <i class="fa fa-external-link-alt"></i> Open in New Tab
                                                    </a>
                                                    <button type="button" class="btn btn-sm btn-danger" @click="removeExistingVideo">
                                                        <i class="fa fa-trash"></i> Remove
                                                    </button>
                                                </div>
                                            </div>

                                            <!-- Upload new video -->
                                            <input
                                                type="file"
                                                name="video"
                                                accept="video/*"
                                                ref="file_video"
                                                v-on:change="handleVideoUpload"
                                                class="file-input"
                                            >

                                            <div class="file-input-div bg-gray-100" @click="$refs.file_video.click()">
                                                <template v-if="video_file_name == '' && !existing_video_url">
                                                    <i class="fa fa-video fa-3x text-muted mb-2"></i>
                                                    <p class="text-muted mb-0">Click to upload video or drag & drop</p>
                                                    <small class="text-muted">Supported formats: MP4, MOV, AVI, WebM (Max: 50MB)</small>
                                                </template>
                                                <template v-else-if="video_file_name == '' && existing_video_url">
                                                    <i class="fa fa-upload fa-2x text-primary mb-2"></i>
                                                    <p class="text-primary mb-0">Click to replace current video</p>
                                                </template>
                                                <template v-else>
                                                    <i class="fa fa-video fa-3x text-success mb-2"></i>
                                                    <p class="text-success mb-0"><strong>New video selected:</strong> {{ video_file_name }}</p>
                                                    <button type="button" class="btn btn-sm btn-danger mt-2" @click.stop="cancelNewVideoUpload">
                                                        <i class="fa fa-times"></i> Cancel Upload
                                                    </button>
                                                </template>
                                            </div>

                                            <small class="text-danger" v-if="videoError">{{ videoError }}</small>
                                        </div>
                                    </div>
                                    <!-- Manufacturer & Made In hidden -->
                                    <!-- <div class="col-md-6">
                                        <div class="form-group">
                                            <label>{{ __('manufacturer') }} </label>
                                            <input type="text" class="form-control" v-model="manufacturer" :placeholder="__('enter_manufacturer')">
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>{{ __('made_in') }}</label>
                                            <multiselect v-model="made_in"
                                                         :options="countries"
                                                         :placeholder="__('select_and_search_country_name')"
                                                         label="name"
                                                         track-by="name" required>
                                                <template slot="singleLabel" slot-scope="props">
                                                            <span class="option__desc">
                                                                <span class="option__title">{{ props.option.name }}</span>
                                                            </span>
                                                </template>
                                                <template slot="option" slot-scope="props">
                                                    <div class="option__desc">
                                                        <span class="option__title">{{ props.option.name }}</span>
                                                        <span class="option__small">[{{ props.option.code }}]</span>
                                                    </div>
                                                </template>
                                            </multiselect>
                                        </div>
                                    </div> -->


                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label for="return_day">{{ __('fssai_lic_no') }}</label>
                                            <input type="text" class="form-control" :placeholder="__('fssai_lic_no')" v-model="fssai_lic_no" @input="validateFSSAINumber">
                                            <p style="color:red" v-if="validationMessage">{{ validationMessage }}</p>
                                            <p style="color:green" v-else-if="isValid">FSSAI License Number is valid!</p>

                                        </div>
                                    </div>

                                    
                                    <div class="col-md-12">
                                        <div class="row">
                                            <!-- Barcode hidden -->
                                            <!-- <div class="col-md-6">
                                                <div class="form-group">
                                                    <label for="barcode">{{ __('barcode') }}</label>
                                                    <input type="text" class="form-control" :placeholder="__('barcode')" v-model="barcode" @input="validateBarcode">
                                                    <p style="color:red" v-if="validationBarcodeMessage">{{ validationBarcodeMessage }}</p>
                                                </div>
                                            </div> -->

                                            
                                            <div class="col-md-6">
                                                <div class="form-group">
                                                    <label>{{ __('total_allowed_quantity') }}  </label>
                                                    <input type="number" min="0" class="form-control" v-model="max_allowed_quantity">
                                                    <span class="text text-primary">{{ __('keep_blank_if_no_such_limit') }}</span>
                                                </div>
                                            </div>

                                            

                                        </div>
                                    </div>

                                    
                                    <div class="col-md-12">
                                        <div class="row">
                                            <div class="col-md-6">
                                                <div class="row">
                                                    <div class="col-md-6">
                                                        <div class="form-group">
                                                            <label>{{ __('is_cancelable') }}</label><br>
                                                            <b-form-radio-group
                                                                v-model="cancelable_status"
                                                                :options="[
                                                                                { text: ' No', 'value': 0 },
                                                                                { text: ' Yes', 'value': 1 },
                                                                            ]"
                                                                buttons
                                                                button-variant="outline-primary"
                                                            ></b-form-radio-group>
                                                        </div>
                                                    </div>
                                                    <div class="col-md-6" id="till-status" v-if="cancelable_status===1">
                                                    <div class="form-group">
                                                        <label for="till_status">{{ __('till_which_status') }}
                                                        <i class="text-danger">*</i>
                                                        </label>
                                                        <br>
                                                        <select id="till_status" class="form-control form-select" v-model="till_status">
                                                            <option value="">{{ __('select_order_statue') }}</option>
                                                            <option v-for="status in order_status" :value="status.id">{{ status.status }}
                                                            </option>
                                                        </select>
                                                    </div>
                                                </div>
                                            </div>
                                            </div>

                                            
                                            <!-- COD Allowed hidden — hardcoded to 1 (Yes) -->
                                            <!-- <div class="col-md-6">
                                                <div class="form-group">
                                                    <label>{{__('is_cod_allowed')}}</label><br>
                                                    <b-form-radio-group
                                                        v-model="cod_allowed_status"
                                                        :options="[
                                                                { text: ' No', 'value': 0 },
                                                                { text: ' Yes', 'value': 1 },
                                                            ]"
                                                        buttons
                                                        button-variant="outline-primary"
                                                    ></b-form-radio-group>
                                                </div>
                                            </div> -->
                                        </div>
                                    </div>

                                    
                                    <div class="col-md-6">
                                        <template v-if="this.$roleSeller == login_user.role.name">
                                            <input type="hidden" v-model="is_approved">

                                        </template>
                                        <template v-else>
                                            <div class="form-group">
                                                <label class="control-label">{{ __('product_status') }}</label><br>
                                                <div id="status" class="btn-group">
                                                    <label class="btn btn-primary" data-toggle-class="btn-primary"
                                                           data-toggle-passive-class="btn-default">
                                                        <input type="radio" v-model="is_approved" value="1"> Approved
                                                    </label>
                                                    <label class="btn btn-danger" data-toggle-class="btn-danger"
                                                           data-toggle-passive-class="btn-default">
                                                        <input type="radio" v-model="is_approved" value="0">
                                                        Not-Approved
                                                    </label>
                                                </div>
                                            </div>
                                        </template>
                                    </div>
                                    
                                    <div class="col-md-6">
                                        <div class="row">

                                            <div class="col-md-6">
                                                <div class="form-group">
                                                    <label>{{ __('is_returnable') }}</label><br>
                                                    <b-form-radio-group
                                                        v-model="return_status"
                                                        :options="[
                                                                { text: ' No', 'value': 0 },
                                                                { text: ' Yes', 'value': 1 },
                                                            ]"
                                                        buttons
                                                        button-variant="outline-primary"
                                                        required
                                                    ></b-form-radio-group>
                                                </div>
                                            </div>
                                            <div class="col-md-4" id="return_day" v-if="return_status == 1">
                                                <div class="form-group">
                                                    <label for="return_day">{{ __('max_return_days') }} </label>
                                                    <input type="number" step="any" min="0" class="form-control" :placeholder="__('number_of_days_to_return')" v-model="return_days">
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    
                                </div>
                            </div>
                            <div class="card-footer">
                                <b-button type="submit"  @keydown.enter.native="saveRecord" variant="primary" :disabled="isLoading"> {{ __('save') }}
                                    <b-spinner v-if="isLoading" small label="Spinning"></b-spinner>
                                </b-button>
                                <!-- <button type="reset" class="btn btn-danger">{{ __('clear') }}</button> -->
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</template>
<script>
import Vue from 'vue';
// import InputTag from 'vue-input-tag';
import axios from "axios";
import Multiselect from 'vue-multiselect'
import Select2 from "v-select2-component";
import Editor from '@tinymce/tinymce-vue';
import Auth from '../../Auth.js';
export default {
    // register the component
     props: ['id', 'clone', 'record'],
    components: {  Multiselect,Select2, 'editor': Editor },
    data: function () {
        return {
            login_user: Auth.user,
            isLoading:false,

            name: '',
            slug: '',
            seller_id: 0,
            tags: [],
            tag_ids: '',
            tagSuggestions: [],
            brand:null,
            tax_id: 5,
            type: 'packet',
            category_id: '',
            product_type: '1', // 1 = Veg, 2 = Non-Veg
            manufacturer: '',
            made_in: '',
            tag: '',
            fssai_lic_no: '',

            return_status: 0,
            return_days: 0,
            cancelable_status: 0,
            till_status: "",
            cod_allowed_status: 1,
            max_allowed_quantity: 0,
            description: '',
            require_products_approval: 0,
            is_approved: 1,
            loose_stock: 0,
            loose_stock_unit_id: "",
            status: 1,
            is_unlimited_stock:0,
            is_skinned_one:0,
            is_cleaned:0,
            before_cleaning_weight: null,
            after_cleaning_weight: null,
            pieces: null,
            video_url: null,
            video_file: null,
            video_file_name: '',
            existing_video_url: '',
            videoError: null,
            tax_included_in_price:0,
            pincode_ids_exc: null,

            sellers: null,
            taxes: null,
            units: [],
            brands: [],
            countries: [],

            categories: null,
            order_status: null,

            inputs: [{'name': '','packet_status':'','packet_stock_unit_id':''}],

            image: null,
            main_image_path:"",
            main_image_name:"",


            other_images: null,
            images:[],
            variantImages : {},
            id: null,
            record: null,
            deleteImageIds:[],
            loggedUser: Auth.user,
            validationMessage: '',
            isValid: '',
            isBarcodeValid:'',
            input:[],
            mainImageerror: null,
            otherImageerror: null,
            variantImageerror: null,
            barcode: "",
            meta_title: "",
            meta_keywords: "",
            schema_markup: "",
            meta_description: "",
            validationBarcodeMessage:"",
            name: '',
            description: '',
            useCustomPrompt: false,
            customPrompt: '',
            loading: false,
            textGenKey: '',

            stores: [],
            store_id: "",
            storeOptions: "<option value=''>--Select Store--</option>",

            category_group_id: "",
            categoryGroupOptions: "<option value=''>--Select Category Group--</option>",
            
            sub_category_group_id: "",
            subCategoryGroupOptions: "<option value=''>--Select Sub Category Group--</option>",
            
            
            categoryOptions: "<option value=''>--Select Category--</option>",

            categoryTypes: [],
            categoryTypeOptions: "<option value=''>--Select Type--</option>",
            hasCategoryTypes: false,
            pendingProductType: null,

        }
    },

    computed: {
        isSellerRoute() {
        // Use this.$route to access the current route
        return this.$route.path.startsWith('/seller/');
        },
        manageProductsPath() {
            return this.store_id ? `/manage_products?store_id=${this.store_id}` : '/manage_products';
        },
        tagsOptions() {
      return this.tags.length ? this.tags.map(tag => ({ id: tag.id, text: tag.name })) : [];
    },
    selectedTags() {
    return this.tags.filter(tag => this.tag_ids.includes(tag.id));
  },
        isMeatStore() {
            // Check if the selected store is a meat store
            if (!this.store_id || !this.stores.length) return false;
            const selectedStore = this.stores.find(store => store.id == this.store_id);
            return selectedStore ? selectedStore.is_meat == 1 : false;
        },


    },

    // created: function () {
    //     this.id = this.$route.params.id;
    //     this.clone = this.$route.params.clone;

    //     this.getSellers();
    //     this.getTaxes();
    //     this.getUnits();
    //     this.getBrands();
    //     this.getStores();
    //     // this.getCategoryGroups();

    //     this.getCountries();
    //     this.getTags();
    //     this.getOrderStatus();
    //     this.getTextGenKey();
    //     if(this.$roleSeller == this.login_user.role.name){
    //         this.seller_id = this.login_user.seller.id;
    //         this.getSeller();
    //         this.getSellerCategories();
    //     }
    //     if (this.id) {
    //         this.getProduct();
    //     }

    // },

    created: async function () {
        this.id = this.$route.params.id;
        this.clone = this.$route.params.clone;

        await Promise.all([
            this.getSellers(),
            this.getTaxes(),
            this.getUnits(),
            this.getBrands(),
            this.getStores(),
            this.getCountries(),
            this.getTags(),
            this.getOrderStatus(),
            this.getTextGenKey(),
        ]);

        if (this.id) {
            await this.getProduct();
        } else {
            // Check if store_id is in the query parameters and set it
            const storeIdFromQuery = this.$route.query.store_id;
            if (storeIdFromQuery) {
                this.store_id = storeIdFromQuery;
                // Explicitly load category groups for the selected store
                await this.getCategoryGroups(storeIdFromQuery);
            }
        }

        if (this.$roleSeller == this.login_user.role.name) {
            this.seller_id = this.login_user.seller.id;
            await this.getSeller();
            await this.getSellerCategories();
        }
    },

    methods: {
        async generateDescription() {
            if (!this.name) {
                this.showMessage("error", "Please enter the product name.");
                return;
            }

            if (!this.textGenKey) {
                this.showMessage("error", "Text generation API key is not configured");
                return;
            }

            const prompt = this.useCustomPrompt && this.customPrompt.trim()
            ? `${this.customPrompt} for product: ${this.name}. Output raw HTML only, no explanatory text, no code blocks, no images.`
            : `Generate a detailed product description for ${this.name} formatted for TinyMCE editor.
            Structure: Start with <strong>Product Overview</strong>, then multiple <p> paragraphs describing features and benefits.
            Include <strong>Key Features</strong> with <ul><li> bullet points.
            Add <strong>Benefits</strong> section with more <p> content.
            Use <strong> for emphasis, <em> for highlights.
            Important: no code blocks, no markdown syntax, no explanatory text.`; 

        try {
        this.loading = true;

        const response = await fetch(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" + this.textGenKey,
            {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                contents: [{ parts: [{ text: prompt }] }]
            })
            }
        );

        const data = await response.json();

        if (data?.candidates?.[0]?.content?.parts?.[0]?.text) {
            this.description = data.candidates[0].content.parts[0].text;
        } else {
            this.showMessage("error", "Failed to generate description.");
        }
        } catch (error) {
        console.error("Gemini API Error:", error);
        this.showMessage("error", "An error occurred while generating the description.");
        } finally {
        this.loading = false;
        }
    },

    getStores() {
        this.isLoading = true;
        return axios.get(this.$apiUrl + '/get-all-stores-data')
            .then((response) => {
                this.isLoading = false;
                this.stores = response.data;

                this.storeOptions = `<option value="">--Select Store--</option>`;
                this.stores.forEach(store => {
                    // Exclude store with id 17
                    if (store.id != 17) {
                        this.storeOptions += `<option value="${store.id}">${store.name}</option>`;
                    }
                });
            })
            .catch((error) => {
                this.isLoading = false;
                console.error("Store fetch error", error);
            });
    },
    

    



    getCategoryGroups(storeId) {
        this.isLoading = true;

        axios.get(this.$apiUrl + '/get-data-based-on-store-selection', {
            params: { store_id: storeId }
        })
        .then((response) => {
            this.isLoading = false;

            let data = response.data.data;

            this.categoryGroupOptions = `<option value="">--Select Category Group--</option>`;

            data.forEach(group => {
                this.categoryGroupOptions += `<option value="${group.id}">${group.name}</option>`;
            });
        })
        .catch(error => {
            this.isLoading = false;
            console.error("Failed to load category groups", error);
        });
    },


    

    
    getSubCategories(group_id) {
        if (!group_id) return;
        this.isLoading = true;

        axios.get(this.$apiUrl + '/get-data-based-on-category-selection', {
            params: { category_group_id: group_id }
        })
        .then((response) => {
            this.isLoading = false;

            let data = response.data.data || [];

            this.subCategoryGroupOptions = `<option value="">--Select Sub Category Group--</option>`;

            data.forEach(group => {
                this.subCategoryGroupOptions += `<option value="${group.id}">${group.name}</option>`;
            });
        })
        .catch(error => {
            this.isLoading = false;
            console.error("Failed to load category groups", error);
        });
    },

    

    getCategoriesUsingCategoryGroup(group_id) {
        if (!group_id) return;
        this.isLoading = true;

        axios.get(this.$apiUrl + '/get-data-based-on-sub-category-selection', {
            params: { sub_category_group_id: group_id }
        })
        .then((response) => {
            this.isLoading = false;

            let data = response.data.data || [];

            this.categoryOptions = `<option value="">--Select Category Group--</option>`;

            data.forEach(group => {
                this.categoryOptions += `<option value="${group.id}">${group.name}</option>`;
            });
        })
        .catch(error => {
            this.isLoading = false;
            console.error("Failed to load category groups", error);
        });
    },

    getCategoryTypes(categoryId) {
        this.isLoading = true;
        this.hasCategoryTypes = false;

        axios.get(this.$apiUrl + '/categories/types', {
            params: { category_id: categoryId }
        })
        .then((response) => {
            this.isLoading = false;

            let data = response.data.data;
            this.categoryTypes = data;
            this.hasCategoryTypes = data && data.length > 0;

            this.categoryTypeOptions = `<option value="">--Select Type--</option>`;

            data.forEach(type => {
                this.categoryTypeOptions += `<option value="${type.id}">${type.name}</option>`;
            });

            // Set pending product type if exists (for edit mode)
            if (this.pendingProductType !== null) {
                this.product_type = this.pendingProductType;
                this.pendingProductType = null;
            }
        })
        .catch(error => {
            this.isLoading = false;
            this.hasCategoryTypes = false;
            console.error("Failed to load category types", error);
        });
    },

    createSlug() {
        if (this.name !== "") {
            this.slug = this.name
                .normalize("NFD") // Normalize Unicode
                .replace(/[\u0300-\u036f]/g, '') // Remove diacritics
                .replace(/[^\p{L}\p{N}\s-]/gu, '') // Keep letters, numbers, spaces, and hyphens (any language)
                .trim()
                .replace(/\s+/g, '-') // Replace spaces with '-'
                .toLowerCase();
        }
    },

        fetchTags(query) {
            if (query.length > 1) {
                axios.get(this.$apiUrl + '/products/tags', {
                params: { search: query }
                })
                .then(response => {
                this.tagSuggestions = response.data;
                })
                .catch(error => {
                console.error(error);
                });
            }
        },
        addRow() {
            if(this.type === 'packet') {
                this.inputs.push({'name': '','packet_status':'','packet_stock_unit_id':''})
            }else{
                this.inputs.push({'name': '', 'loose_stock_unit_id': '', 'loose_status': ''})
            }
        },
        remove(index) {
            let variant_id = (this.inputs[index].id)?this.inputs[index].id:"";
            if (this.id && variant_id !== ""){
                this.$swal.fire({
                    title: "Are you Sure?",
                    text: "You want be able to revert this",
                    confirmButtonText: "Yes, Sure",
                    cancelButtonText: "Cancel",
                    icon: 'warning',
                    showCancelButton: true,
                    confirmButtonColor: '#9AC444',
                    cancelButtonColor: '#d33',
                }).then(result => {
                    if (result.value) {
                        let postData = {
                            id: variant_id
                        }
                        axios.post(this.$apiUrl + '/products/delete', postData)
                            .then((response) => {
                                let data = response.data;
                                this.inputs.splice(index, 1)
                                this.showSuccess(data.message)
                            });
                    }
                });
            } else{
                this.inputs.splice(index, 1)
            }
        },

        dropFile(event) {
            event.preventDefault();
            this.$refs.file_image.files = event.dataTransfer.files;
            this.fileImage(); // Trigger the onChange event manually
            // Clean up
            event.currentTarget.classList.add('bg-gray-100');
            event.currentTarget.classList.remove('bg-green-300');
        },

        fileImage() {
            const file = this.$refs.file_image.files[0];

            // Reset previous error message
            this.mainImageerror = null;

            // Check if a file was selected
            if (!file) return;

            // Perform image validation
            const validTypes = ["image/jpeg", "image/png", "image/jpg", "image/gif", "image/webp"];
            if (!validTypes.includes(file.type)) {
                this.mainImageerror = "Invalid file type. Please upload a JPEG, PNG, JPG,  GIF or WEBP image.";
                this.main_image_path ="";
                this.main_image_name = "";
                return;
            }

            const maxSize = 2 * 1024 * 1024; // 2MB
            if (file.size > maxSize) {
                this.mainImageerror = "File size exceeds the maximum allowed limit (2MB).";
                this.main_image_path = "";
                this.main_image_name = "";
                return;
            }

            // Create a URL for the uploaded image and display it
            this.imageUrl = URL.createObjectURL(file);
            this.image = this.$refs.file_image.files[0];
            this.main_image_path = URL.createObjectURL(this.image);
            this.main_image_name = this.image.name;
        },
        dropFileOtherImage(event){
            event.preventDefault();
            this.$refs.file_other_images.files = event.dataTransfer.files;
            this.otherImage(); // Trigger the onChange event manually
            // Clean up
            event.currentTarget.classList.add('bg-gray-100');
            event.currentTarget.classList.remove('bg-green-300');
        },
        removeOtherImage(index){
            this.images.splice(index, 1);
        },

        otherImage() {
            this.images = [];
            const files = this.$refs.file_other_images.files;

            for (let i = 0; i < files.length; i++) {
                const file = files[i];

                // Check if the file is an image (you can extend the list of allowed file types)
                if (!file.type.startsWith('image/')) {
                    this.otherImageerror = "Invalid file type. Please upload a JPEG, PNG, JPG,  GIF or WEBP image.";
                    file = "";
                }else{
                    let image = {};
                    image.url = URL.createObjectURL(file);
                    image.name = file.name;
                    image.file = file; // Store the actual file object
                    this.images.push(image);
                }



            }
        },

        handleVideoUpload() {
            const file = this.$refs.file_video.files[0];

            // Reset previous error message
            this.videoError = null;

            // Check if a file was selected
            if (!file) return;

            // Perform video validation
            const validTypes = ["video/mp4", "video/quicktime", "video/x-msvideo", "video/webm", "video/avi", "video/mov"];
            if (!validTypes.includes(file.type)) {
                this.videoError = "Invalid file type. Please upload MP4, MOV, AVI, or WebM video.";
                this.video_file_name = "";
                this.video_file = null;
                return;
            }

            const maxSize = 50 * 1024 * 1024; // 50MB
            if (file.size > maxSize) {
                this.videoError = "File size exceeds the maximum allowed limit (50MB).";
                this.video_file_name = "";
                this.video_file = null;
                return;
            }

            // Store the video file
            this.video_file = file;
            this.video_file_name = file.name;
            this.existing_video_url = ''; // Clear existing video when new one is uploaded
        },

        // Cancel newly selected video (before saving)
        cancelNewVideoUpload() {
            this.video_file = null;
            this.video_file_name = '';
            this.videoError = null;
            if (this.$refs.file_video) {
                this.$refs.file_video.value = '';
            }
        },

        // Remove existing video from database
        removeExistingVideo() {
            if (confirm('Are you sure you want to remove this video?')) {
                this.existing_video_url = '';
                this.video_url = null;
                this.video_file = null;
                this.video_file_name = '';
                this.videoError = null;
                if (this.$refs.file_video) {
                    this.$refs.file_video.value = '';
                }
            }
        },

        variantImagesChanges(index) {
            let tempImages = [];
            Vue.set(this.variantImages, index, []);

            if (this.type === 'packet') {
                const validExtensions = ['jpg', 'jpeg', 'png', 'gif']; // Add more valid extensions as needed
                const maxSizeInBytes = 5 * 1024 * 1024; // 5 MB (adjust the size limit as needed)

                for (var i = 0; i < this.$refs['packet_variant_images_' + index][0].files.length; i++) {
                let image = {};
                let file = this.$refs['packet_variant_images_' + index][0].files[i];
                let extension = file.name.split('.').pop().toLowerCase();

                // Check if the file extension is valid
                if (!validExtensions.includes(extension)) {
                    this.variantImageerror = "Invalid file type. Please upload a JPEG, PNG, JPG,  GIF or WEBP image.";
                    return; // Skip this file and proceed to the next one
                }

                // Check if the file size is within the allowed limit
                if (file.size > maxSizeInBytes) {
                    this.variantImageerror = "File size exceeds the limit of 5 MB.";
                    return; // Skip this file and proceed to the next one
                }

                image.url = URL.createObjectURL(file);
                image.name = file.name;
                tempImages.push(image);
                Vue.set(this.variantImages, index, tempImages);
                }
            } else {
                for (var i = 0; i < this.$refs['loose_variant_images_' + index][0].files.length; i++) {
                let image = {};
                let file = this.$refs['loose_variant_images_' + index][0].files[i];
                image.url = URL.createObjectURL(file);
                image.name = file.name;
                tempImages.push(image);
                Vue.set(this.variantImages, index, tempImages);
                }
            }
        },

        

        getSellerCategories(){
            if (this.seller_id !== 0 && this.seller_id !== ""){
                this.isLoading = true;
                let param = {
                    "seller_id": this.seller_id
                }
                axios.get(this.$apiUrl + '/categories/seller_categories',{
                    params: param
                }).then((response) => {
                    this.isLoading = false
                    let data = response.data;
                    this.categoryOptionsSeller = `<option value="">--Select Category--</option>` + data
                });
            }
        },


        getSeller(){
            if (this.seller_id !== 0 && this.seller_id !== "" && !this.id ){
                this.isLoading = true;
                let param = {
                    "seller_id": this.seller_id
                }
                axios.get(this.$apiUrl + '/sellers/edit/'+this.seller_id,{
                    params: param
                }).then((response) => {
                    this.isLoading = false,
                    this.require_products_approval = response.data.data.require_products_approval;
                    this.is_approved= this.require_products_approval == 0 ? 1 : 0;
                });
            }
        },
        getCategories() {
            this.isLoading = true
            axios.get(this.$apiUrl + '/categories/options')
                .then((response) => {
                    this.isLoading = false
                    let data = response.data;
                    this.categoryOptions = `<option value="">--Select Category--</option>` + data

                });
        },
        getSellers() {
            this.isLoading = true
            return axios.get(this.$apiUrl + '/sellers')
                .then((response) => {
                    this.isLoading = false
                    let data = response.data;
                    this.sellers = data.data
                });
        },
        getTaxes() {
            this.isLoading = true
            return axios.get(this.$apiUrl + '/products/taxes')
                .then((response) => {
                    this.isLoading = false
                    let data = response.data;
                    this.taxes = data.data
                });
        },
        getUnits() {
            this.isLoading = true
            return axios.get(this.$apiUrl + '/units/get')
                .then((response) => {
                    this.isLoading = false
                    let data = response.data;
                    this.units = data.data
                });
        },
        getBrands() {
            this.isLoading = true;
            const params = {};
            if (this.store_id)    params.store_id    = this.store_id;
            // Only filter by store_id, not category_id
            return axios.get(this.$apiUrl + '/products/brands/get', { params })
                .then((response) => {
                    this.isLoading = false;
                    this.brands = response.data.data || [];
                    // Re-validate selected brand still exists in filtered list
                    if (this.brand && !this.brands.find(b => b.id === this.brand.id)) {
                        this.brand = null;
                    }
                });
        },
        getCountries() {
            this.isLoading = true
            return axios.get(this.$apiUrl + '/countries/active')
                .then((response) => {
                    this.isLoading = false
                    let data = response.data;
                    this.countries = data.data
                });
        },
        getTags() {
            this.isLoading = true
            return axios.get(this.$apiUrl + '/products/tags')
                .then((response) => {
                    this.isLoading = false
                    let data = response.data;
                    this.tags = data.data
                });
        },

        getOrderStatus() {
            this.isLoading = true
            return axios.get(this.$apiUrl + '/order_statuses').then((response) => {
                    this.isLoading = false
                    let data = response.data;
                    const allowedStatusIds = [2, 3];
                    this.order_status = data.data.filter(status => allowedStatusIds.includes(status.id));
                });
        },
        getTextGenKey() {
            // Get the text generation API key from store settings
            return axios.get(this.$apiUrl + '/store_settings')
                .then((response) => {
                    let data = response.data.data;
                    if (data.store_settings) {
                        data.store_settings.forEach((item) => {
                            if (item.variable === 'text_gen_key') {
                                this.textGenKey = item.value;
                            }
                        });
                    }
                })
                .catch((error) => {
                    console.error('Error fetching text generation key:', error);
                });
        },
        validateFSSAINumber() {
            const fssaiRegex = /^[0-9]{14}$/;

            if (fssaiRegex.test(this.fssai_lic_no)) {
                this.validationMessage = '';
                 this.isValid = true;
            } else {
                this.validationMessage = 'Invalid FSSAI Number.';
                 this.isValid = false;
            }
        },
        validateBarcode() {
            const barcodePattern = /^[A-Za-z0-9-]+$/;

            if (barcodePattern.test(this.barcode)) {
                this.validationBarcodeMessage = '';
                 this.isBarcodeValid = true;
            } else {
                this.validationBarcodeMessage = 'Invalid Barcode Number.';
                 this.isBarcodeValid = false;
            }
        },
        validateDiscountedPrice(input) {
            const discountedPrice = parseFloat(input.discounted_price);
            const actualPrice = parseFloat(input.packet_price);
            if (discountedPrice >= actualPrice) {
                input.validationErrorDiscountedPrice = "Discounted Price must be less than Actual Price";
                input.discounted_price = null;
            } else {
                input.validationErrorDiscountedPrice = null;
            }
        },
        validateDiscountedPriceLoose(input) {
            const discountedPrice = parseFloat(input.loose_discounted_price);
            const actualPrice = parseFloat(input.loose_price);
            if (discountedPrice >= actualPrice) {
                input.validationErrorDiscountedPriceLoose = "Discounted Price must be less than Actual Price";
                input.loose_discounted_price = null;
            } else {
                input.validationErrorDiscountedPriceLoose = null;
            }
        },
        async getProduct() {
            this.isLoading = true;

            try {
                const response = await axios.get(this.$apiUrl + '/products/edit/' + this.id);
                let data = response.data;
                if (data.status === 1) {
                    this.record = data.data

                    this.store_id = this.record.store_id;
                    this.getCategoryGroups(this.store_id);

                    this.category_group_id = this.record.category_group_id;
                    this.getSubCategories(this.category_group_id);

                    this.sub_category_group_id = this.record.sub_category_group_id;
                    this.getCategoriesUsingCategoryGroup(this.sub_category_group_id);

                    this.category_id = this.record.category_id;

                    // Load brands for this store and category before setting the brand
                    await this.getBrands();

                    this.name = this.record.name;
                    this.slug = this.record.slug;
                    this.barcode = this.record.barcode;
                    if(this.clone){
                       this.name = '';
                       this.slug = '';
                        this.barcode = '';
                    }

                    // Handle null seller_id for admin-managed store products
                    this.seller_id = this.record.seller_id || 0;
                    this.getSellerCategories();
                    this.getSeller();

                    this.tag_ids =this.record.tags.map(item => item.id);

                    this.tax_id = 5; // hardcoded — tax dropdown hidden

                    this.brand = (this.brands || []).find((item) => {
                        return item.id === this.record.brand_id;
                    });

                        this.type = this.record.type;

                        // this.category_id = this.record.category_id;

                        // Set product type (1 = Veg, 2 = Non-Veg) from indicator column
                        this.product_type = this.record.indicator ? String(this.record.indicator) : '1';
                        this.manufacturer = this.record.manufacturer;


                        // Handle made_in as either country ID or country name
                        this.made_in = (this.countries || []).find((item) => {
                            return item.id == this.record.made_in || item.name == this.record.made_in;
                        });

                        this.tax_included_in_price = this.record.tax_included_in_price;

                        this.return_status = this.record.return_status;
                        this.return_days = this.record.return_days;
                        this.cancelable_status = this.record.cancelable_status;

                        this.till_status = this.record.till_status;
                        this.cod_allowed_status = 1; // hardcoded — COD always allowed
                        this.max_allowed_quantity = this.record.total_allowed_quantity;
                        this.description = this.record.description;
                        this.is_approved = this.record.is_approved;
                        this.status = this.record.status;
                        this.is_unlimited_stock = this.record.is_unlimited_stock;
                        this.is_skinned_one = this.record.is_skinned_one ?? 0;
                        this.is_cleaned = this.record.is_cleaned ?? 0;
                        this.before_cleaning_weight = this.record.before_cleaning_weight ?? null;
                        this.after_cleaning_weight = this.record.after_cleaning_weight ?? null;
                        this.pieces = this.record.pieces ?? null;
                        // Load existing video
                        if (this.record.video_url) {
                            this.existing_video_url = this.$mediaUrl(this.record.video_url);
                            this.video_url = this.record.video_url;
                        }
                        this.main_image_path = this.$mediaUrl(this.record.image);
                        this.other_images = this.record.images;
                        this.fssai_lic_no = this.record.fssai_lic_no;
                        this.image = this.record.image;
                        this.meta_title = this.record.meta_title;
                        this.meta_keywords = this.record.meta_keywords;
                        this.schema_markup = this.record.schema_markup;
                        this.meta_description = this.record.meta_description;

                        let vm = this;
                        if (this.type == 'packet') {
                            this.inputs = [];
                            this.record.variants.forEach(function (item) {
                                var variantData = {
                                    'id': (item.id)?item.id:"",
                                    'packet_measurement': item.measurement,
                                    'packet_price': item.price,
                                    'discounted_price': item.discounted_price,
                                    'packet_stock': item.stock,
                                    'packet_stock_unit_id': item.stock_unit_id,
                                    'packet_status': item.status,
                                    'images': item.images,
                                };
                                vm.inputs.push(variantData);
                            });
                        }

                        if (this.type == 'loose') {

                            this.inputs = [];
                            this.record.variants.forEach(function (item) {
                                var variantData = {
                                    'id': (item.id)?item.id:"",
                                    'loose_measurement': item.measurement,
                                    'loose_custom_title': item.custom_title??"",
                                    'loose_price': item.price,
                                    'loose_discounted_price': item.discounted_price,
                                    'loose_stock': item.stock,
                                    'loose_stock_unit_id': item.stock_unit_id,
                                    'loose_status': item.status,
                                    'loose_images': item.images,
                                };
                                vm.inputs.push(variantData);
                            });
                        }
                } else {
                    this.showError(data.message);
                    setTimeout(() => {
                        this.$router.back();
                    }, 1000);
                }
            } catch (error) {
                this.isLoading = false;
                if (error.message) {
                    this.showError(error.message);
                } else {
                    this.showError("Something went wrong!");
                }
            }
        },

        afterSaveRedirect(storeId) {
            this.$router.push({path: `/manage_products?store_id=${storeId}`});
        },

        saveRecord: function () {
            // Validate fish store cleaning fields
            if (this.store_id == 19 && this.is_cleaned == 1) {
                if (!this.after_cleaning_weight || this.after_cleaning_weight.trim() === '') {
                    this.$toast.error('After cleaning weight is required when fish is cleaned');
                    return;
                }
            }

            this.isLoading = true;
            let vm = this;
            let formData = new FormData();
            if (this.id) {
                formData.append('id', this.id);
                formData.append('deleteImageIds', JSON.stringify(this.deleteImageIds));
            }
            formData.append('name', this.name);
            formData.append('slug', this.slug);
            formData.append('seller_id', this.seller_id);
            formData.append('tag_ids', this.tag_ids);
            formData.append('tax_id', this.tax_id);
            formData.append('brand_id', this.brand ? this.brand.id : 0);
            formData.append('description', this.description);
            formData.append('type', this.type);
            formData.append('is_unlimited_stock', this.is_unlimited_stock);
            formData.append('is_skinned_one', this.is_skinned_one);
            formData.append('is_cleaned', this.is_cleaned);
            formData.append('before_cleaning_weight', this.before_cleaning_weight || '');
            formData.append('after_cleaning_weight', this.after_cleaning_weight || '');
            formData.append('pieces', this.pieces || '');

            // Append video file if uploaded, otherwise keep existing video_url
            if (this.video_file) {
                formData.append('video', this.video_file);
            } else if (this.video_url) {
                formData.append('existing_video_url', this.video_url);
            }

            formData.append('fssai_lic_no', this.fssai_lic_no);
            formData.append('barcode', this.barcode);
            formData.append('meta_title', this.meta_title);
            formData.append('meta_keywords', this.meta_keywords);
            formData.append('schema_markup', this.schema_markup);
            formData.append('meta_description', this.meta_description);

            /*packet*/
            if (this.type === 'packet') {
                for (let i = 0; i < this.inputs.length; i++) {

                    formData.append('variant_id[]', (this.inputs[i].id)?this.inputs[i].id:"");
                    formData.append('packet_measurement[]', this.inputs[i].packet_measurement);

                    formData.append('packet_price[]', (this.inputs[i].packet_price != undefined) ? this.inputs[i].packet_price : 0);
                    formData.append('discounted_price[]', (this.inputs[i].discounted_price != undefined) ? this.inputs[i].discounted_price : 0);
                    formData.append('packet_stock[]', (this.inputs[i].packet_stock != undefined) ? this.inputs[i].packet_stock : 0);
                    formData.append('packet_stock_unit_id[]', (this.inputs[i].packet_stock_unit_id != undefined) ? this.inputs[i].packet_stock_unit_id : 0);
                    formData.append('packet_status[]', (this.inputs[i].packet_status != undefined) ? this.inputs[i].packet_status : 0);



                    for (var j = 0; j < this.$refs['packet_variant_images_' + i][0].files.length; j++) {
                        let file = this.$refs['packet_variant_images_' + i][0].files[j];
                        formData.append('packet_variant_images_' + i + '[]', file);
                    }
                }
            }

            /*loose*/
            if (this.type === 'loose') {
                for (let i = 0; i < this.inputs.length; i++) {
                    formData.append('variant_id[]', (this.inputs[i].id)?this.inputs[i].id:"");
                    formData.append('loose_measurement[]', this.inputs[i].loose_measurement);
                    formData.append('loose_custom_title[]', this.inputs[i].loose_custom_title);

                    formData.append('loose_price[]', (this.inputs[i].loose_price != undefined) ? this.inputs[i].loose_price : 0);
                    formData.append('loose_discounted_price[]', (this.inputs[i].loose_discounted_price != undefined) ? this.inputs[i].loose_discounted_price : 0);
                    formData.append('loose_stock[]', (this.inputs[i].loose_stock != undefined) ? this.inputs[i].loose_stock : 0);
                    formData.append('loose_stock_unit_id[]', (this.inputs[i].loose_stock_unit_id != undefined) ? this.inputs[i].loose_stock_unit_id : 0);
                    formData.append('loose_status[]', (this.inputs[i].loose_status != undefined) ? this.inputs[i].loose_status : 1);

                    for (var j = 0; j < this.$refs['loose_variant_images_' + i][0].files.length; j++) {
                        let file = this.$refs['loose_variant_images_' + i][0].files[j];
                        formData.append('loose_variant_images_' + i + '[]', file);
                    }
                }
            }

            formData.append('category_id', this.category_id);
            formData.append('sub_category_group_id', this.sub_category_group_id);
            formData.append('store_id', this.store_id);
            formData.append('category_group_id', this.category_group_id);


            formData.append('product_type', this.product_type);
            formData.append('manufacturer', this.manufacturer);

            formData.append('made_in', this.made_in ? this.made_in.id : 0);

            formData.append('shipping_type', this.shipping_type);

            formData.append('pincode_ids_exc', this.pincode_ids_exc);

            formData.append('return_status', this.return_status);
            formData.append('return_days', this.return_days);
            formData.append('cancelable_status', this.cancelable_status);
            formData.append('till_status', this.till_status);
            formData.append('cod_allowed_status', this.cod_allowed_status);
            formData.append('max_allowed_quantity', this.max_allowed_quantity);

            formData.append('is_approved', this.is_approved);
            formData.append('tax_included_in_price', this.tax_included_in_price);
            formData.append('image', this.image);
            // Other Images - Use files from images array to maintain correct indexing
            for (var i = 0; i < this.images.length; i++) {
                let file = this.images[i].file;
                formData.append('other_images[]', file);
            }

            let url = this.$apiUrl + '/products/save';
            if (this.clone) {

                url = this.$apiUrl + '/products/save';
            }else if (this.id) {
                url = this.$apiUrl + '/products/update';
            }

            axios.post(url, formData, {
                headers: {
                    'Content-Type': 'multipart/form-data'
                }
            }).then(res => {
                let data = res.data;

                if (data.status === 1) {

                    this.showMessage("success", data.message);

                    let returnedStoreId = res.data.store_id;

                    console.log("store_id = ", returnedStoreId);
                    console.log("res.data.data = ", res.data.store_id);

                    setTimeout(
                        function () {
                            vm.$swal.close();
                            vm.isLoading = false;
                            if(vm.loggedUser?.role?.name==="Seller"){
                                vm.$router.push({path: '/seller/manage_products'});
                            }else{
                                vm.afterSaveRedirect(returnedStoreId);
                            }



                        }, 2000);
                } else {
                    vm.showError(data.message);
                    vm.isLoading = false;
                }
            }).catch(error => {
                vm.isLoading = false;
                this.showError("Something went wrong!");
            });
        },
        deleteImage(index, id, productImage, key = ""){
            this.$swal.fire({
                title: "Are you Sure?",
                text: "You want be able to revert this",
                confirmButtonText: "Yes, Sure",
                cancelButtonText: "Cancel",
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#9AC444',
                cancelButtonColor: '#d33',
            }).then(result => {
                if (result.value) {
                    this.deleteImageIds.push(id);
                    if(productImage){
                        this.other_images.splice(index, 1);
                    }else{
                        if(this.type === 'packet' ){
                            this.inputs[key].images.splice(index, 1);
                        }else{
                            this.inputs[key].loose_images.splice(index, 1);
                        }
                    }
                }
            });
        },
        changeUnits: function () {
        }
    },

    watch: {
        '$route.query.store_id': {
            handler(newStoreId) {
                if (newStoreId && !this.id) {
                    this.store_id = newStoreId;
                }
            },
            immediate: true
        },
        store_id(newVal) {
            if (newVal) {
                this.getCategoryGroups(newVal);
            } else {
                this.categoryGroupOptions = "<option value=''>--Select Category Group--</option>";
            }
            this.getBrands();
        },
        category_group_id(newVal) {
            if (newVal) {
                this.getSubCategories(newVal);
            } else {
                this.subCategoryGroupOptions = "<option value=''>--Select Sub Category Group--</option>";
            }
        },
        sub_category_group_id(newVal) {
            if (newVal) {
                this.getCategoriesUsingCategoryGroup(newVal);
            } else {
                this.categoryOptions = "<option value=''>--Select Sub Category Group--</option>";
            }
        },

    }

};
</script>
<style scoped>
@import "../../../../node_modules/vue-multiselect/dist/vue-multiselect.min.css";
</style>

<style scoped>
    #mymodal .row > [class^="col-"] {
        padding: 10px 15px;       /* inner padding for each field */
    }

    #mymodal .form-group {
        margin-bottom: 15px;      /* spacing between form groups */
    }

    #mymodal label {
        margin-bottom: 5px;       /* small space under labels */
        display: block;
    }

    #mymodal .row {
        row-gap: 20px;            /* vertical spacing between rows */
    }
</style>
