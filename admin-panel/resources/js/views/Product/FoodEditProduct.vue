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
                        Food Product
                    </h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
                            </li>
                            <li class="breadcrumb-item">
                                <router-link to="/food_products">Food Products</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">
                                <template v-if="clone">{{ __('clone') }}</template>
                                <template v-else-if="id">{{ __('edit') }}</template>
                                <template v-else>{{ __('create') }}</template>
                                Food Product
                            </li>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/food_products" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <div class="row">
                <div class="col-12 col-md-12 order-md-1 order-last" id="mymodal">
                    <form ref="my-form" @submit.prevent="saveRecord" @keydown.enter="$event.preventDefault()">
                        <div class="card">
                            <div class="card-header">
                                <h4>
                                    <template v-if="clone">{{ __('clone') }}</template>
                                    <template v-else-if="id">{{ __('edit') }}</template>
                                    <template v-else>{{ __('create') }}</template>
                                    Food Product
                                </h4>
                                <span class="pull-right">
                                    <router-link to="/food_products" class="btn btn-primary" v-b-tooltip.hover title="Food Products">Food Products</router-link>
                                </span>
                            </div>
                            <div class="card-body">

                                <label><span class="text-danger text-xs">*</span> {{__('required_fields')}}</label>

                                <div class="row">
                                    <div class="col-md-6">
                                        <label>{{ __('product_name') }}
                                            <i class="text-danger">*</i>
                                        </label>
                                        <input type="text" class="form-control" :placeholder="__('enter_product_name')" v-model="name" v-on:keyup="createSlug" required>
                                    </div>

                                    <!-- Seller dropdown — always shown for admin, hidden for seller role -->
                                    <template v-if="this.$roleSeller == login_user.role.name">
                                        <input type="hidden" v-model="seller_id">
                                    </template>
                                    <template v-else>
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
                                    <!-- Brands hidden -->
                                    <!-- <div class="col-md-6">
                                        <div class="form-group">
                                            <label>{{ __('brands') }}</label>
                                            <multiselect v-model="brand"
                                                         :options="brands"
                                                         :placeholder="__('select_and_search_brands')"
                                                         label="name"
                                                         track-by="name" required>
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
                                    </div> -->

                                    <div class="col-md-12">
                                        <div class="form-group">
                                            <label>{{ __('description') }} <i class="text-danger">*</i></label>
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
                                            <p v-if="mainImageerror" class="error">{{ mainImageerror }}</p>

                                            <div class="row" v-if="main_image_path">
                                                <div class="col-md-4">
                                                    <img class="custom-image" :src="main_image_path" title='Main Image' alt='Main Image'/>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    <!-- Other Images hidden -->
                                    <!-- <div class="col-md-6">
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
                                    </div> -->
                                </div>
                            </div>
                        </div>

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
                                            <div class="col-md-12 hidden">
                                                <div class="form-group loose_div">
                                                    <label>{{ __('variant_images') }}</label>
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

                                <div class="row mt-3" id="loose_stock_div" v-if="type === 'loose'">
                                    <div class="col-md-4">
                                        <div class="form-group" v-if="is_unlimited_stock!=1">
                                            <label>{{ __('stock') }} </label> <i class="text-danger">*</i>
                                            <input type="number" step="any" min="0" class="form-control" v-model="loose_stock"><br>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <div class="form-group">
                                            <label>{{ __('unit') }} </label>
                                             <i class="text-danger">*</i>
                                            <select class="form-control form-select" name="loose_stock_unit_id" v-model="loose_stock_unit_id">
                                                <option value="">{{ __('select_unit') }}</option>
                                                <option v-for="(unit,key) in units" :value="unit.id">{{ unit.short_code }}</option>
                                            </select>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <div class="form-group">
                                            <label>{{ __('status') }} </label>
                                             <i class="text-danger">*</i>
                                            <select name="status" class="form-control form-select" v-model="status">
                                                <option value="">{{ __('select_status') }}</option>
                                                <option value="1">{{ __('available') }}</option>
                                                <option value="0">{{ __('sold_out') }}</option>
                                            </select>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Product Settings -->
                        <div class="card">
                            <div class="card-header">
                                <h4>{{__('product_settings')}}</h4>
                            </div>
                            <div class="card-body">
                                <div class="row">

                                    <!-- Store is always Food (store_id=15) — hidden field -->
                                    <input type="hidden" v-model="store_id">

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
                                <b-button type="submit" @keydown.enter.native="saveRecord" variant="primary" :disabled="isLoading"> {{ __('save') }}
                                    <b-spinner v-if="isLoading" small label="Spinning"></b-spinner>
                                </b-button>
                                <button type="reset" class="btn btn-danger">{{ __('clear') }}</button>
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
import axios from "axios";
import Multiselect from 'vue-multiselect'
import Select2 from "v-select2-component";
import Auth from '../../Auth.js';

export default {
    components: { Multiselect, Select2 },
    data: function () {
        return {
            login_user: Auth.user,
            isLoading: false,

            name: '',
            slug: '',
            seller_id: 0,
            tags: [],
            tag_ids: '',
            tagSuggestions: [],
            brand: null,
            tax_id: 5,
            type: 'packet',
            category_id: '',
            product_type: '1',
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
            is_unlimited_stock: 0,
            tax_included_in_price: 0,
            pincode_ids_exc: null,

            sellers: null,
            taxes: null,
            units: [],
            brands: [],
            countries: [],
            categories: null,
            order_status: null,

            inputs: [{ 'name': '', 'packet_status': '', 'packet_stock_unit_id': '' }],

            image: null,
            main_image_path: "",
            main_image_name: "",
            other_images: null,
            images: [],
            variantImages: {},
            id: null,
            record: null,
            deleteImageIds: [],
            loggedUser: Auth.user,
            validationMessage: '',
            isValid: '',
            isBarcodeValid: '',
            input: [],
            mainImageerror: null,
            otherImageerror: null,
            variantImageerror: null,
            barcode: "",
            meta_title: "",
            meta_keywords: "",
            schema_markup: "",
            meta_description: "",
            validationBarcodeMessage: "",

            // Food store is always store_id = 15
            store_id: 15,

            categoryOptions: "<option value=''>--Select Category--</option>",

        }
    },

    computed: {
        isSellerRoute() {
            return this.$route.path.startsWith('/seller/');
        },
        tagsOptions() {
            return this.tags.length ? this.tags.map(tag => ({ id: tag.id, text: tag.name })) : [];
        },
        selectedTags() {
            return this.tags.filter(tag => this.tag_ids.includes(tag.id));
        },
    },

    created: async function () {
        this.id = this.$route.params.id;
        this.clone = this.$route.params.clone;

        await Promise.all([
            this.getSellers(),
            this.getTaxes(),
            this.getUnits(),
            this.getBrands(),
            this.getCountries(),
            this.getTags(),
            this.getOrderStatus(),
        ]);

        if (this.id) {
            await this.getProduct();
        }

        if (this.$roleSeller == this.login_user.role.name) {
            this.seller_id = this.login_user.seller.id;
            await this.getSeller();
            await this.getSellerCategories();
        }
    },

    methods: {
        getSellerCategories() {
            if (this.seller_id !== 0 && this.seller_id !== "") {
                this.isLoading = true;
                axios.get(this.$apiUrl + '/food-products/seller-categories', {
                    params: { seller_id: this.seller_id }
                }).then((response) => {
                    this.isLoading = false;
                    let categories = response.data.data;
                    let options = `<option value="">--Select Category--</option>`;
                    categories.forEach(cat => {
                        options += `<option value="${cat.id}">${cat.name}</option>`;
                    });
                    this.categoryOptions = options;
                });
            } else {
                this.categoryOptions = "<option value=''>--Select Category--</option>";
            }
        },

        getSeller() {
            if (this.seller_id !== 0 && this.seller_id !== "" && !this.id) {
                this.isLoading = true;
                return axios.get(this.$apiUrl + '/sellers/edit/' + this.seller_id)
                    .then((response) => {
                        this.isLoading = false;
                        this.require_products_approval = response.data.data.require_products_approval;
                        this.is_approved = this.require_products_approval == 0 ? 1 : 0;
                    });
            }
        },

        // Only fetches sellers for Food store (store_id = 15)
        getSellers() {
            this.isLoading = true;
            return axios.get(this.$apiUrl + '/sellers', { params: { store_id: 15 } })
                .then((response) => {
                    this.isLoading = false;
                    this.sellers = response.data.data;
                });
        },

        getTaxes() {
            this.isLoading = true;
            return axios.get(this.$apiUrl + '/products/taxes')
                .then((response) => {
                    this.isLoading = false;
                    this.taxes = response.data.data;
                });
        },

        getUnits() {
            this.isLoading = true;
            return axios.get(this.$apiUrl + '/units/get')
                .then((response) => {
                    this.isLoading = false;
                    this.units = response.data.data;
                });
        },

        getBrands() {
            this.isLoading = true;
            return axios.get(this.$apiUrl + '/products/brands/get')
                .then((response) => {
                    this.isLoading = false;
                    this.brands = response.data.data || [];
                });
        },

        getCountries() {
            this.isLoading = true;
            return axios.get(this.$apiUrl + '/countries/active')
                .then((response) => {
                    this.isLoading = false;
                    this.countries = response.data.data;
                });
        },

        getTags() {
            this.isLoading = true;
            return axios.get(this.$apiUrl + '/products/tags')
                .then((response) => {
                    this.isLoading = false;
                    this.tags = response.data.data;
                });
        },

        getOrderStatus() {
            this.isLoading = true;
            return axios.get(this.$apiUrl + '/order_statuses').then((response) => {
                this.isLoading = false;
                const allowedStatusIds = [2, 3];
                this.order_status = response.data.data.filter(status => allowedStatusIds.includes(status.id));
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

        createSlug() {
            if (this.name !== "") {
                this.slug = this.name
                    .normalize("NFD")
                    .replace(/[\u0300-\u036f]/g, '')
                    .replace(/[^\p{L}\p{N}\s-]/gu, '')
                    .trim()
                    .replace(/\s+/g, '-')
                    .toLowerCase();
            }
        },

        addRow() {
            if (this.type === 'packet') {
                this.inputs.push({ 'name': '', 'packet_status': '', 'packet_stock_unit_id': '' });
            } else {
                this.inputs.push({ 'name': '' });
            }
        },

        remove(index) {
            let variant_id = (this.inputs[index].id) ? this.inputs[index].id : "";
            if (this.id && variant_id !== "") {
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
                        axios.post(this.$apiUrl + '/products/delete', { id: variant_id })
                            .then((response) => {
                                this.inputs.splice(index, 1);
                                this.showSuccess(response.data.message);
                            });
                    }
                });
            } else {
                this.inputs.splice(index, 1);
            }
        },

        dropFile(event) {
            event.preventDefault();
            this.$refs.file_image.files = event.dataTransfer.files;
            this.fileImage();
            event.currentTarget.classList.add('bg-gray-100');
            event.currentTarget.classList.remove('bg-green-300');
        },

        fileImage() {
            const file = this.$refs.file_image.files[0];
            this.mainImageerror = null;
            if (!file) return;
            const validTypes = ["image/jpeg", "image/png", "image/jpg", "image/gif", "image/webp"];
            if (!validTypes.includes(file.type)) {
                this.mainImageerror = "Invalid file type. Please upload a JPEG, PNG, JPG, GIF or WEBP image.";
                this.main_image_path = "";
                this.main_image_name = "";
                return;
            }
            const maxSize = 2 * 1024 * 1024;
            if (file.size > maxSize) {
                this.mainImageerror = "File size exceeds the maximum allowed limit (2MB).";
                this.main_image_path = "";
                this.main_image_name = "";
                return;
            }
            this.image = this.$refs.file_image.files[0];
            this.main_image_path = URL.createObjectURL(this.image);
            this.main_image_name = this.image.name;
        },

        dropFileOtherImage(event) {
            event.preventDefault();
            this.$refs.file_other_images.files = event.dataTransfer.files;
            this.otherImage();
            event.currentTarget.classList.add('bg-gray-100');
            event.currentTarget.classList.remove('bg-green-300');
        },

        removeOtherImage(index) {
            this.images.splice(index, 1);
        },

        otherImage() {
            this.images = [];
            const files = this.$refs.file_other_images.files;
            for (let i = 0; i < files.length; i++) {
                const file = files[i];
                if (!file.type.startsWith('image/')) {
                    this.otherImageerror = "Invalid file type. Please upload a JPEG, PNG, JPG, GIF or WEBP image.";
                } else {
                    let image = {};
                    image.url = URL.createObjectURL(file);
                    image.name = file.name;
                    image.file = file;
                    this.images.push(image);
                }
            }
        },

        variantImagesChanges(index) {
            let tempImages = [];
            Vue.set(this.variantImages, index, []);
            if (this.type === 'packet') {
                const validExtensions = ['jpg', 'jpeg', 'png', 'gif'];
                const maxSizeInBytes = 5 * 1024 * 1024;
                for (var i = 0; i < this.$refs['packet_variant_images_' + index][0].files.length; i++) {
                    let image = {};
                    let file = this.$refs['packet_variant_images_' + index][0].files[i];
                    let extension = file.name.split('.').pop().toLowerCase();
                    if (!validExtensions.includes(extension)) {
                        this.variantImageerror = "Invalid file type.";
                        return;
                    }
                    if (file.size > maxSizeInBytes) {
                        this.variantImageerror = "File size exceeds the limit of 5 MB.";
                        return;
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

        deleteImage(index, id, isOtherImage, variantIndex) {
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
                    axios.post(this.$apiUrl + '/products/delete_image', { id: id })
                        .then((response) => {
                            if (isOtherImage) {
                                this.other_images.splice(index, 1);
                            } else {
                                this.inputs[variantIndex].images.splice(index, 1);
                            }
                            this.showSuccess(response.data.message);
                        });
                }
            });
        },

        getProduct() {
            this.isLoading = true;
            return axios.get(this.$apiUrl + '/products/edit/' + this.id)
                .then((response) => {
                    let data = response.data;
                    if (data.status === 1) {
                        this.record = data.data;

                        this.store_id = 15; // Always food store

                        this.seller_id = this.record.seller_id || 0;
                        this.getSellerCategories();
                        this.getSeller();

                        this.category_id = this.record.category_id;
                        this.name = this.record.name;
                        this.slug = this.record.slug;
                        this.barcode = this.record.barcode;

                        if (this.clone) {
                            this.name = '';
                            this.slug = '';
                            this.barcode = '';
                        }

                        this.tag_ids = (this.record.tags || []).map(item => item.id);
                        this.tax_id = 5; // hardcoded — tax dropdown hidden

                        this.brand = (this.brands || []).find((item) => item.id === this.record.brand_id);

                        this.type = this.record.type;
                        this.product_type = this.record.indicator ? String(this.record.indicator) : '1';
                        this.manufacturer = this.record.manufacturer;

                        this.made_in = (this.countries || []).find((item) =>
                            item.id == this.record.made_in || item.name == this.record.made_in
                        );

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
                                vm.inputs.push({
                                    'id': item.id ? item.id : "",
                                    'packet_measurement': item.measurement,
                                    'packet_price': item.price,
                                    'discounted_price': item.discounted_price,
                                    'packet_stock': item.stock,
                                    'packet_stock_unit_id': item.stock_unit_id,
                                    'packet_status': item.status,
                                    'images': item.images,
                                });
                            });
                        }

                        if (this.type == 'loose') {
                            let loose_stock = 0;
                            let loose_stock_unit_id = 0;
                            let status = 0;
                            this.inputs = [];
                            this.record.variants.forEach(function (item) {
                                vm.inputs.push({
                                    'id': item.id ? item.id : "",
                                    'loose_measurement': item.measurement,
                                    'loose_custom_title': item.custom_title ?? "",
                                    'loose_price': item.price,
                                    'loose_discounted_price': item.discounted_price,
                                    'packet_stock': item.stock,
                                    'loose_images': item.images,
                                });
                                loose_stock = item.stock;
                                loose_stock_unit_id = item.stock_unit_id;
                                status = item.status;
                            });
                            this.loose_stock = loose_stock;
                            this.loose_stock_unit_id = loose_stock_unit_id;
                            this.status = status;
                        }
                    } else {
                        this.showError(data.message);
                        setTimeout(() => { this.$router.back(); }, 1000);
                    }
                })
                .catch(error => {
                    this.isLoading = false;
                    this.showError(error.message || "Something went wrong!");
                });
        },

        afterSaveRedirect() {
            this.$router.push({ path: '/food_products' });
        },

        saveRecord: function () {
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
            formData.append('fssai_lic_no', this.fssai_lic_no);
            formData.append('barcode', this.barcode);
            formData.append('meta_title', this.meta_title);
            formData.append('meta_keywords', this.meta_keywords);
            formData.append('schema_markup', this.schema_markup);
            formData.append('meta_description', this.meta_description);

            if (this.type === 'packet') {
                for (let i = 0; i < this.inputs.length; i++) {
                    formData.append('variant_id[]', this.inputs[i].id ? this.inputs[i].id : "");
                    formData.append('packet_measurement[]', this.inputs[i].packet_measurement);
                    formData.append('packet_price[]', this.inputs[i].packet_price != undefined ? this.inputs[i].packet_price : 0);
                    formData.append('discounted_price[]', this.inputs[i].discounted_price != undefined ? this.inputs[i].discounted_price : 0);
                    formData.append('packet_stock[]', this.inputs[i].packet_stock != undefined ? this.inputs[i].packet_stock : 0);
                    formData.append('packet_stock_unit_id[]', this.inputs[i].packet_stock_unit_id != undefined ? this.inputs[i].packet_stock_unit_id : 0);
                    formData.append('packet_status[]', this.inputs[i].packet_status != undefined ? this.inputs[i].packet_status : 0);

                    for (var j = 0; j < this.$refs['packet_variant_images_' + i][0].files.length; j++) {
                        formData.append('packet_variant_images_' + i + '[]', this.$refs['packet_variant_images_' + i][0].files[j]);
                    }
                }
            }

            if (this.type === 'loose') {
                for (let i = 0; i < this.inputs.length; i++) {
                    formData.append('variant_id[]', this.inputs[i].id ? this.inputs[i].id : "");
                    formData.append('loose_measurement[]', this.inputs[i].loose_measurement);
                    formData.append('loose_custom_title[]', this.inputs[i].loose_custom_title);
                    formData.append('loose_price[]', this.inputs[i].loose_price != undefined ? this.inputs[i].loose_price : 0);
                    formData.append('loose_discounted_price[]', this.inputs[i].loose_discounted_price != undefined ? this.inputs[i].loose_discounted_price : 0);
                    formData.append('packet_stock[]', this.inputs[i].packet_stock != undefined ? this.inputs[i].packet_stock : 0);

                    for (var j = 0; j < this.$refs['loose_variant_images_' + i][0].files.length; j++) {
                        formData.append('loose_variant_images_' + i + '[]', this.$refs['loose_variant_images_' + i][0].files[j]);
                    }
                }
                formData.append('loose_stock', this.loose_stock);
                formData.append('loose_stock_unit_id', this.loose_stock_unit_id);
                formData.append('status', this.status);
            }

            formData.append('loose_stock', this.loose_stock != undefined ? this.loose_stock : 0);
            formData.append('loose_stock_unit_id', this.loose_stock_unit_id != undefined ? this.loose_stock_unit_id : 0);
            formData.append('status', this.status != undefined ? this.status : 0);

            formData.append('category_id', this.category_id);
            formData.append('store_id', this.store_id); // always 15

            formData.append('product_type', this.product_type);
            formData.append('manufacturer', this.manufacturer);
            formData.append('made_in', this.made_in ? this.made_in.id : 0);
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

            for (var i = 0; i < this.images.length; i++) {
                formData.append('other_images[]', this.images[i].file);
            }

            let url = this.id ? this.$apiUrl + '/products/update' : this.$apiUrl + '/products/save';
            if (this.clone) url = this.$apiUrl + '/products/save';

            axios.post(url, formData, {
                headers: { 'Content-Type': 'multipart/form-data' }
            }).then(res => {
                let data = res.data;
                if (data.status === 1) {
                    this.showMessage("success", data.message);
                    setTimeout(function () {
                        vm.$swal.close();
                        vm.isLoading = false;
                        vm.afterSaveRedirect();
                    }, 1500);
                } else {
                    this.isLoading = false;
                    this.showError(data.message);
                }
            }).catch(error => {
                this.isLoading = false;
                this.showError(error.message || "Something went wrong!");
            });
        },
    },

};
</script>

<style scoped>
@import "../../../../node_modules/vue-multiselect/dist/vue-multiselect.min.css";
</style>

<style scoped>
    #mymodal .row > [class^="col-"] {
        padding: 10px 15px;
    }
    #mymodal .form-group {
        margin-bottom: 15px;
    }
</style>
