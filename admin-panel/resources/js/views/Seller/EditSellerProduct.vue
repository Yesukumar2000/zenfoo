<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>
                        <template v-if="id">
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
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
                            </li>
                            <li class="breadcrumb-item">
                                <router-link to="/sellers">{{ __('sellers') }}</router-link>
                            </li>
                            <li class="breadcrumb-item">
                                <router-link :to="'/sellers/products?seller_id=' + seller_id">{{ __('products') }}</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">
                                <template v-if="id">{{ __('edit') }}</template>
                                <template v-else>{{ __('create') }}</template>
                                {{ __('product') }}
                            </li>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link :to="'/sellers/products?seller_id=' + seller_id" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <div class="row">
                <div class="col-12 col-md-12 order-md-1 order-last" id="mymodal">
                    <form ref="my-form" @submit.prevent="saveRecord" @keydown.enter="$event.preventDefault()">
                        <div class="card">
                            <div class="card-header">
                                <h4><template v-if="id">{{ __('edit') }}</template><template v-else>{{ __('create') }}</template> {{ __('product') }}</h4>
                                <span class="pull-right">
                                    <router-link :to="'/sellers/products?seller_id=' + seller_id" class="btn btn-primary" v-b-tooltip.hover title="Back to Products">{{ __('back') }}</router-link>
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
                                    <div class="col-md-6">
                                        <label>
                                            {{ __('slug') }}
                                            <i class="text-danger">*</i>
                                        </label>
                                        <input type="text" class="form-control" :placeholder="__('enter_product_slug')" v-model="slug" readonly>
                                    </div>
                                    <input type="hidden" v-model="seller_id">
                                    <div class="col-md-6">
                                        <label for="tax_id" class="control-label">{{ __('tax') }}</label>
                                        <select id="tax_id" name="tax_id" class="form-control form-select"
                                                v-model="tax_id">
                                            <option value="0">Select Tax</option>
                                            <option v-for="tax in taxes" :value="tax.id">{{ tax.title }} ({{ tax.percentage }} %)</option>
                                        </select>
                                    </div>
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
                                            <label>Category Group <i class="text-danger">*</i></label>

                                            <select class="form-control form-select" v-model="category_group_id"
                                                    v-html="categoryGroupOptions">
                                            </select>


                                        </div>
                                    </div>



                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>Sub Category Group <i class="text-danger">*</i></label>

                                            <select class="form-control form-select" v-model="sub_category_group_id"
                                                    v-html="subCategoryGroupOptions">
                                            </select>


                                        </div>
                                    </div>

                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>{{ __('category') }} <i class="text-danger">*</i></label>

                                            <select class="form-control form-select" v-model="category_id"
                                                    v-html="categoryOptions">
                                            </select>


                                        </div>
                                    </div>

                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>{{ __('product_type') }} </label>
                                            <select class="form-control form-select" v-model="product_type">
                                                <option value="">{{ __('select_type') }}</option>
                                                <option value="1">Veg</option>
                                                <option value="2">Non Veg</option>
                                            </select>
                                        </div>
                                    </div>
                                    <div class="col-md-6">
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


                                    </div>


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
                                            <div class="col-md-6">
                                                <div class="form-group">
                                                    <label for="barcode">{{ __('barcode') }}</label>
                                                    <input type="text" class="form-control" :placeholder="__('barcode')" v-model="barcode" @input="validateBarcode">
                                                    <p style="color:red" v-if="validationBarcodeMessage">{{ validationBarcodeMessage }}</p>
                                                    <p style="color:green" v-else-if="isBarcodeValid">Barcode is valid!</p>

                                                </div>
                                            </div>


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


                                            <div class="col-md-6">
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
                                            </div>
                                        </div>
                                    </div>


                                    <div class="col-md-6">
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
    props: ['id', 'record'],
    components: {  Multiselect, Select2 },
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
            tax_id: 0,
            type: 'packet',
            category_id: '',
            product_type: '',
            manufacturer: '',
            made_in: '',
            tag: '',
            fssai_lic_no: '',

            return_status: 0,
            return_days: 0,
            cancelable_status: 0,
            till_status: "",
            cod_allowed_status: 0,
            max_allowed_quantity: 0,
            description: '',
            require_products_approval: 0,
            is_approved: 1,
            loose_stock: 0,
            loose_stock_unit_id: "",
            status: 1,
            is_unlimited_stock:0,
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
            validationBarcodeMessage:"",

            stores: [],
            store_id: "",
            storeOptions: "<option value=''>--Select Store--</option>",

            category_group_id: "",
            categoryGroupOptions: "<option value=''>--Select Category Group--</option>",

            sub_category_group_id: "",
            subCategoryGroupOptions: "<option value=''>--Select Sub Category Group--</option>",

            categoryOptions: "<option value=''>--Select Category--</option>",
        }
    },

    computed: {
        tagsOptions() {
            return this.tags.length ? this.tags.map(tag => ({ id: tag.id, text: tag.name })) : [];
        },
        selectedTags() {
            return this.tags.filter(tag => this.tag_ids.includes(tag.id));
        },
    },

    created: async function () {
        this.id = this.$route.params.id;
        this.seller_id = this.$route.query.seller_id;

        // Get store_id from URL if provided (for create mode)
        if (this.$route.query.store_id) {
            this.store_id = this.$route.query.store_id;
        }

        await Promise.all([
            this.getTaxes(),
            this.getUnits(),
            this.getStores(),
            this.getCountries(),
            this.getTags(),
            this.getOrderStatus(),
        ]);

        // Load brands based on store_id if available
        if (this.store_id) {
            await this.getBrands(this.store_id);
        } else {
            await this.getBrands();
        }

        if (this.id) {
            await this.getProduct();
        }
    },

    methods: {
        getStores() {
            this.isLoading = true;
            axios.get(this.$apiUrl + '/get-all-stores-data')
                .then((response) => {
                    this.isLoading = false;
                    this.stores = response.data;

                    this.storeOptions = `<option value="">--Select Store--</option>`;
                    this.stores.forEach(store => {
                        this.storeOptions += `<option value="${store.id}">${store.name}</option>`;
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
            this.isLoading = true;

            axios.get(this.$apiUrl + '/get-data-based-on-category-selection', {
                params: { category_group_id: group_id }
            })
            .then((response) => {
                this.isLoading = false;

                let data = response.data.data;

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
            this.isLoading = true;

            axios.get(this.$apiUrl + '/get-data-based-on-sub-category-selection', {
                params: { sub_category_group_id: group_id }
            })
            .then((response) => {
                this.isLoading = false;

                let data = response.data.data;

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
            if(this.type === 'packet') {
                this.inputs.push({'name': '','packet_status':'','packet_stock_unit_id':''})
            }else{
                this.inputs.push({'name': ''})
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
                this.mainImageerror = "Invalid file type. Please upload a JPEG, PNG, JPG,  GIF or WEBP image.";
                this.main_image_path ="";
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

            this.imageUrl = URL.createObjectURL(file);
            this.image = this.$refs.file_image.files[0];
            this.main_image_path = URL.createObjectURL(this.image);
            this.main_image_name = this.image.name;
        },
        dropFileOtherImage(event){
            event.preventDefault();
            this.$refs.file_other_images.files = event.dataTransfer.files;
            this.otherImage();
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

                if (!file.type.startsWith('image/')) {
                    this.otherImageerror = "Invalid file type. Please upload a JPEG, PNG, JPG,  GIF or WEBP image.";
                }else{
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
                        this.variantImageerror = "Invalid file type. Please upload a JPEG, PNG, JPG,  GIF or WEBP image.";
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
        getBrands(storeId = null) {
            this.isLoading = true
            let params = {};
            if (storeId) {
                params.store_id = storeId;
            }
            return axios.get(this.$apiUrl + '/products/brands/get', { params })
                .then((response) => {
                    this.isLoading = false
                    let data = response.data;
                    this.brands = data.data
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

                    this.name = this.record.name;
                    this.slug = this.record.slug;
                    this.barcode = this.record.barcode;

                    this.seller_id = this.record.seller_id;

                    this.tag_ids = this.record.tags.map(item => item.id);

                    this.tax_id = this.record.tax_id;

                    // Load brands for this store before setting the brand
                    await this.getBrands(this.store_id);

                    this.brand = (this.brands || []).find((item) => {
                        return item.id === this.record.brand_id;
                    });

                    this.type = this.record.type;

                    this.product_type = this.record.indicator ?? "";
                    this.manufacturer = this.record.manufacturer;

                    this.made_in = (this.countries || []).find((item) => {
                        return item.id == this.record.made_in;
                    });

                    this.tax_included_in_price = this.record.tax_included_in_price;

                    this.return_status = this.record.return_status;
                    this.return_days = this.record.return_days;
                    this.cancelable_status = this.record.cancelable_status;

                    this.till_status = this.record.till_status;
                    this.cod_allowed_status = this.record.cod_allowed;
                    this.max_allowed_quantity = this.record.total_allowed_quantity;
                    this.description = this.record.description;
                    this.is_approved = this.record.is_approved;
                    this.status = this.record.status;
                    this.is_unlimited_stock = this.record.is_unlimited_stock;
                    this.main_image_path = this.$mediaUrl(this.record.image);
                    this.other_images = this.record.images;
                    this.fssai_lic_no = this.record.fssai_lic_no;
                    this.image = this.record.image;

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

                        let loose_stock = 0;
                        let loose_stock_unit_id = 0;
                        let status = 0;

                        this.inputs = [];
                        this.record.variants.forEach(function (item) {
                            var variantData = {
                                'id': (item.id)?item.id:"",
                                'loose_measurement': item.measurement,
                                'loose_custom_title': item.custom_title??"",
                                'loose_price': item.price,
                                'loose_discounted_price': item.discounted_price,
                                'packet_stock': item.stock,
                                'loose_images': item.images,
                            };
                            vm.inputs.push(variantData);
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

            if (this.type === 'loose') {
                for (let i = 0; i < this.inputs.length; i++) {
                    formData.append('variant_id[]', (this.inputs[i].id)?this.inputs[i].id:"");
                    formData.append('loose_measurement[]', this.inputs[i].loose_measurement);
                    formData.append('loose_custom_title[]', this.inputs[i].loose_custom_title);

                    formData.append('loose_price[]', (this.inputs[i].loose_price != undefined) ? this.inputs[i].loose_price : 0);
                    formData.append('loose_discounted_price[]', (this.inputs[i].loose_discounted_price != undefined) ? this.inputs[i].loose_discounted_price : 0);
                    formData.append('packet_stock[]', (this.inputs[i].packet_stock != undefined) ? this.inputs[i].packet_stock : 0);

                    for (var j = 0; j < this.$refs['loose_variant_images_' + i][0].files.length; j++) {
                        let file = this.$refs['loose_variant_images_' + i][0].files[j];
                        formData.append('loose_variant_images_' + i + '[]', file);
                    }
                }
                formData.append('loose_stock', this.loose_stock);
                formData.append('loose_stock_unit_id', this.loose_stock_unit_id);
                formData.append('status', this.status);
            }


            formData.append('loose_stock', (this.loose_stock != undefined) ? this.loose_stock : 0);
            formData.append('loose_stock_unit_id', (this.loose_stock_unit_id != undefined) ? this.loose_stock_unit_id : 0);
            formData.append('status', (this.status != undefined) ? this.status : 0);

            formData.append('category_id', this.category_id);
            formData.append('sub_category_group_id', this.sub_category_group_id);
            formData.append('store_id', this.store_id);
            formData.append('category_group_id', this.category_group_id);

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
                let file = this.images[i].file;
                formData.append('other_images[]', file);
            }

            let url = this.$apiUrl + '/products/save';
            if (this.id) {
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

                    setTimeout(
                        function () {
                            vm.$swal.close();
                            vm.isLoading = false;
                            // Redirect back to seller products list
                            vm.$router.push({path: '/sellers/products', query: { seller_id: vm.seller_id }});
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
        store_id(newVal) {
            if (newVal) {
                this.getCategoryGroups(newVal);
                this.getBrands(newVal);
                // Reset brand selection when store changes
                this.brand = null;
            } else {
                this.categoryGroupOptions = "<option value=''>--Select Category Group--</option>";
                this.brands = [];
                this.brand = null;
            }
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
        padding: 10px 15px;
    }

    #mymodal .form-group {
        margin-bottom: 15px;
    }

    #mymodal label {
        margin-bottom: 5px;
        display: block;
    }

    #mymodal .row {
        row-gap: 20px;
    }
</style>
