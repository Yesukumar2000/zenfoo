<template>
    <div :class="{ 'fullscreen-pos': isFullscreenMode }">
        <div v-if="isFullscreenMode" class="fullscreen-header">
            <div class="container-fluid">
                <div class="row">
                    <div class="col-md-12">
                        <div class="d-flex align-items-center justify-content-between">
                            <button class="btn btn-primary me-3 mt-1" @click="confirmExit">
                                <i class="fas fa-arrow-left"></i> Exit POS
                            </button>
                            <h5>POS Billing</h5>
                            <h5>{{ storeName }}</h5>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Tab System - Insert after header -->
        <div v-if="isFullscreenMode" class="pos-tabs-container mb-3">
            <div class="container-fluid">
                <div class="row">
                    <div class="col-lg-8">
                        <div class="d-flex align-items-center">
                            <div class="w-100">
                                <div class="pos-tabs-wrapper d-flex">
                                    <button
                                        v-for="(tab, index) in tabs"
                                        :key="index"
                                        class="pos-tab"
                                        :class="{ 'active': activeTabIndex === index && !viewingPreviousOrder }"
                                        @click="switchTab(index)"
                                    >
                                        <span>Bill {{ index + 1 }}</span>
                                        <span v-if="tabs.length > 1" class="pos-tab-close" @click.stop="closeTab(index)">×</span>
                                    </button>
                                    <button
                                        v-if="tabs.length < 5"
                                        class="btn btn-sm btn-outline-primary ms-2"
                                        @click="addNewTab"
                                    >
                                        <i class="fas fa-plus"></i>Hold Bill & Create Another
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-4 d-flex justify-content-end align-items-center">
                        <button
                            v-if="previousOrders.length > 0"
                            class="btn"
                            :class="{ 'btn-primary': viewingPreviousOrder, 'btn-outline-primary': !viewingPreviousOrder }"
                            @click="togglePreviousBill">
                            <i class="fas fa-receipt"></i> Previous Bill
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <div class="page-heading" v-if="!isFullscreenMode">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>{{ __('point_of_sale') }}</h3>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item">
                                    <router-link to="/seller/dashboard">{{ __('dashboard') }}</router-link>
                                </li>
                                <li class="breadcrumb-item active" aria-current="page">{{ __('point_of_sale') }}</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>
        </div>

        <div class="row">
            <!-- Left Side: Product Selection -->
            <div class="col-lg-8 col-12">
                <div class="card">
                    <div class="card-header d-flex justify-content-between">
                        <h4>{{ __('products') }}</h4>
                        <div class="d-flex">
                            <!-- Category Filter -->
                            <div class="me-2">
                                <select class="form-select" style="min-width: 200px;" v-model="selectedCategory" @change="getProducts">
                                    <option value="">{{ __('all_categories') }}</option>
                                    <option v-for="category in categories" :key="category.id" :value="category.id">
                                        {{ category.name }}
                                    </option>
                                </select>
                            </div>

                            <!-- Search Input -->
                            <div class="input-group">
                                <input
                                    type="text"
                                    class="form-control"
                                    v-model="searchTerm"
                                    placeholder="Search products"
                                    @input="debounceSearch"
                                >
                            </div>
                        </div>
                    </div>
                    <div class="card-body">
                        <!-- Loading Spinner -->
                        <div v-if="loading" class="text-center p-5">
                            <div class="spinner-border" role="status">
                                <span class="visually-hidden">Loading...</span>
                            </div>
                        </div>

                        <!-- No Products Found -->
                        <div v-else-if="products.length === 0" class="text-center p-5">
                            <p class="mb-0">{{ __('no_products_found') }}</p>
                        </div>

                        <!-- Products Grid -->
                        <div v-else class="row g-3">
                            <div v-for="product in products" :key="product.id" class="col-md-3 col-6">
                                <div class="product-card">
                                    <div class="product-image" @click="navigateToProduct(product.id)">
                                        <img :src="product.image_url" :alt="product.name" class="img-fluid">
                                    </div>
                                    <div class="product-info">
                                        <!-- Product title with variant info row -->
                                        <div class="product-name-measure-row d-flex align-items-baseline mb-2">
                                            <h5 class="product-title mb-0" @click="navigateToProduct(product.id)">{{ product.name }}</h5>

                                            <!-- Single variant display next to name -->
                                            <div v-if="product.variants && product.variants.length === 1" class="single-variant ms-2">
                                                <span class="variant-info">{{ product.variants[0].measurement }} {{ product.variants[0].measurement_unit_name }}</span>
                                            </div>

                                            <!-- Multiple variants dropdown next to name -->
                                            <div v-else-if="product.variants && product.variants.length > 1" class="ms-2">
                                                <select class="form-select form-select-sm mini-select short-select" v-model="product.selectedVariantId">
                                                    <option
                                                        v-for="variant in product.variants"
                                                        :key="variant.id"
                                                        :value="variant.id"
                                                    >
                                                        {{ variant.measurement }} {{ variant.measurement_unit_name }}
                                                    </option>
                                                </select>
                                            </div>
                                        </div>

                                        <!-- Price and add button row - Multiple variants -->
                                        <div v-if="product.variants && product.variants.length > 1" class="product-actions">
                                            <div class="d-flex justify-content-between align-items-center">
                                                <div class="product-price mb-0">
                                                    <template v-if="getSelectedVariant(product)">
                                                        <span v-if="getSelectedVariant(product).discounted_price > 0" class="discounted">
                                                            {{ $currency }} {{ getSelectedVariant(product).discounted_price }}
                                                            <small class="original-price">{{ $currency }} {{ getSelectedVariant(product).price }}</small>
                                                        </span>
                                                        <span v-else>
                                                            {{ $currency }} {{ getSelectedVariant(product).price }}
                                                        </span>
                                                    </template>
                                                </div>
                                                <!-- Show Out of Stock or Add to Cart button based on stock availability -->
                                                <div v-if="isProductOutOfStock(product)" class="out-of-stock">
                                                    <span class="badge bg-danger">{{ __('out_of_stock') }}</span>
                                                </div>
                                                <button
                                                    v-else
                                                    class="btn btn-primary btn-sm"
                                                    @click.stop="addSelectedVariantToCart(product)"
                                                >
                                                     {{ __('add_to_cart') }}
                                                </button>
                                            </div>
                                        </div>

                                        <!-- Price and add button row - Single variant -->
                                        <div v-else-if="product.variants && product.variants.length === 1" class="product-actions">
                                            <div class="d-flex justify-content-between align-items-center">
                                                <div class="product-price mb-0">
                                                    <span v-if="product.variants[0].discounted_price > 0" class="discounted">
                                                        {{ $currency }} {{ product.variants[0].discounted_price }}
                                                        <small class="original-price">{{ $currency }} {{ product.variants[0].price }}</small>
                                                    </span>
                                                    <span v-else>
                                                        {{ $currency }} {{ product.variants[0].price }}
                                                    </span>
                                                </div>
                                                <div v-if="isProductOutOfStock(product)" class="out-of-stock">
                                                    <span class="badge bg-danger">{{ __('out_of_stock') }}</span>
                                                </div>
                                                <button
                                                    v-else
                                                    class="btn btn-primary btn-sm"
                                                    @click.stop="addVariantToCart(product, product.variants[0])"
                                                >
                                                    {{ __('add_to_cart') }}
                                                </button>
                                            </div>
                                        </div>

                                        <div v-else class="product-actions">
                                            <div class="d-flex justify-content-between align-items-center">
                                                <div class="product-price mb-0">
                                                    <span class="text-muted">{{ __('no_variants') }}</span>
                                                </div>
                                                <div class="out-of-stock">
                                                    <span class="badge bg-danger">{{ __('out_of_stock') }}</span>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Pagination -->
                        <div class="d-flex justify-content-between align-items-center mt-4">
                            <div class="d-flex align-items-center">
                                <span>{{ __('show') }}</span>
                                <select class="form-select form-select-sm mx-2" v-model="perPage" @change="changePerPage">
                                    <option value="9">9</option>
                                    <option value="12">12</option>
                                    <option value="24">24</option>
                                    <option value="36">36</option>
                                </select>
                                <span>{{ __('per_page') }}</span>
                            </div>
                            <ul class="pagination pagination-primary">
                                <li class="page-item" :class="{ disabled: currentPage === 1 }">
                                    <a class="page-link" href="#" @click.prevent="changePage(currentPage - 1)">
                                        <span aria-hidden="true">&laquo;</span>
                                    </a>
                                </li>
                                <li v-for="page in paginationRange" :key="page" class="page-item" :class="{ active: page === currentPage }">
                                    <a class="page-link" href="#" @click.prevent="changePage(page)">{{ page }}</a>
                                </li>
                                <li class="page-item" :class="{ disabled: currentPage === totalPages }">
                                    <a class="page-link" href="#" @click.prevent="changePage(currentPage + 1)">
                                        <span aria-hidden="true">&raquo;</span>
                                    </a>
                                </li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>

            <div class="col-lg-4 col-12">
                <!-- Discount and Additional Charge Buttons above Cart -->
                <div class="d-flex justify-content-between mb-3">
                    <button class="btn btn-primary" @click="showDiscountModal" :disabled="cart.length === 0">
                        <i class="fas fa-percentage me-1"></i>{{ __('add_discount') }}
                    </button>
                    <button class="btn btn-primary" @click="showAdditionalChargeModal" :disabled="cart.length === 0">
                        <i class="fas fa-plus-circle me-1"></i>{{ __('add_additional_charges') }}
                    </button>
                </div>

                <div class="card mb-4">
                    <div class="card-header">
                        <h4>{{ __('customer') }} Details</h4>
                    </div>
                    <div class="card-body">
                        <div class="row mb-3">
                            <div class="col-8">
                                <div class="search-select">
                                    <input
                                        type="text"
                                        class="form-control"
                                        v-model="customerSearchTerm"
                                        @input="searchCustomers"
                                        placeholder="Search customer"
                                    />
                                    <div class="search-results" v-if="showCustomerResults && filteredUsers.length > 0">
                                        <div class="search-option" @click="selectCashSale()">
                                            {{ __('cash_sale') }}
                                        </div>
                                        <div
                                            v-for="user in filteredUsers"
                                            :key="user.id + '-' + user.user_type"
                                            class="search-option"
                                            @click="selectUser(user)"
                                        >
                                            {{ user.name }}
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-4">
                                <button class="btn btn-primary w-100" @click="showRegisterModal">
                                    {{ __('register_user') }}
                                </button>
                            </div>
                        </div>

                        <!-- <div v-if="selectedUser" class="user-details d-flex justify-content-around flex-wrap">
                            <div class="mb-3">
                                <strong>{{ __('name') }}:</strong> {{ selectedUser.name }}
                            </div>
                            <div v-if="selectedUser.mobile" class="mb-3">
                                <strong>{{ __('mobile') }}:</strong> {{ selectedUser.mobile | mobileMask }}
                            </div>
                            <div v-if="selectedUser.email" class="mb-3">
                                <strong>{{ __('email') }}:</strong> {{ selectedUser.email | emailMask }}
                            </div>
                        </div>
                        <div v-else class="user-details d-flex justify-content-center mb-3">
                            <div class="text-muted">
                                {{ __('cash_sale') }}
                            </div>
                        </div> -->
                    </div>
                </div>
                <!-- Cart -->
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h4>{{ __('cart') }}</h4>
                        <button v-if="cart.length > 0" class="btn btn-sm btn-outline-danger" @click="clearCart">
                            {{ __('clear_cart') }}
                        </button>
                    </div>
                    <div class="card-body">
                        <div v-if="cart.length === 0" class="text-center p-4">
                            <p>{{ __('cart_empty') }}</p>
                        </div>
                        <div v-else>
                            <div class="cart-items">
                                <div class="cart-item" v-for="(item, index) in cart" :key="index">
                                    <div class="item-image">
                                        <img :src="item.image || '/assets/img/placeholder.png'" :alt="item.name" class="img-fluid rounded">
                                    </div>
                                    <div class="item-details">
                                        <h5>{{ item.name }}</h5>
                                        <p class="variant-info">
                                            <strong>{{ item.variant ? `${item.variant.measurement} ${item.variant.measurement_unit_name}` : item.variant_name }}</strong>
                                        </p>
                                        <div class="price">
                                            {{ $currency }} {{ item.price }}
                                        </div>
                                    </div>
                                    <div class="item-quantity">
                                        <div class="input-group">
                                            <button class="btn btn-outline-secondary" @click="decreaseQuantity(index)">-</button>
                                            <input type="number" class="form-control text-center" v-model="item.quantity" min="1" @change="updateCartItem(index)" >
                                            <button class="btn btn-outline-secondary" @click="increaseQuantity(index, item)">+</button>
                                        </div>
                                    </div>
                                    <div class="item-total">
                                        {{ $currency }} {{ (item.price * item.quantity).toFixed(2) }}
                                    </div>
                                    <div class="item-actions">
                                        <button class="btn btn-danger btn-sm" @click="removeFromCart(index)">
                                            <i class="bi bi-trash"></i>
                                        </button>
                                    </div>
                                </div>
                            </div>

                            <div class="cart-summary mt-4">
                                <div class="d-flex justify-content-between mb-2">
                                    <span>{{ __('subtotal') }}:</span>
                                    <span>{{ $currency }} {{ calculateSubtotal().toFixed(2) }}</span>
                                </div>

                                <!-- Display discount if applied -->
                                <div v-if="discount.amount > 0 || discount.percentage > 0" class="d-flex justify-content-between mb-2 text-danger">
                                    <span>{{ __('discount') }}:</span>
                                    <span>-{{ $currency }} {{ calculateDiscountAmount().toFixed(2) }}</span>
                                </div>

                                <!-- Display additional charges if any -->
                                <div v-for="(charge, index) in additionalCharges" :key="index" class="d-flex justify-content-between mb-2">
                                    <span>{{ charge.charge_name }}:</span>
                                    <span>{{ $currency }} {{ parseFloat(charge.amount).toFixed(2) }}</span>
                                </div>

                                <div class="d-flex justify-content-between mb-2 pt-2 border-top fw-bold">
                                    <span>{{ __('total') }}:</span>
                                    <span>{{ $currency }} {{ calculateFinalTotal().toFixed(2) }}</span>
                                </div>
                            </div>

                            <div class="mt-4">
                                <div class="mb-3">
                                    <label for="paymentMethod" class="form-label">{{ __('select_payment_method') }}</label>
                                    <select id="paymentMethod" class="form-select" v-model="paymentMethod">
                                        <option value="cash">{{ __('cash') }}</option>
                                        <option value="upi">{{ __('upi') }}</option>
                                        <option value="card">{{ __('card_payment') }}</option>
                                    </select>
                                </div>

                                <div class="d-flex gap-2">
                                    <button
                                        class="btn btn-outline-primary flex-grow-1"
                                        @click="placeOrderAndPrint"
                                        :disabled="cart.length === 0"
                                    >
                                        <i class="fas fa-print me-1"></i> {{ __('save_and_print_bill') }}
                                    </button>

                                    <button
                                        class="btn btn-primary flex-grow-1"
                                        @click="placeOrder(false)"
                                        :disabled="cart.length === 0"
                                    >
                                        {{ __('place_order') }}
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </div>

        <!-- Register User Modal -->
        <div class="modal fade" id="registerUserModal" tabindex="-1" aria-labelledby="registerUserModalLabel" aria-hidden="true">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title" id="registerUserModalLabel">{{ __('register_new_customer') }}</h5>
                        <button type="button" class="btn-close" @click="closeRegisterModal"></button>
                    </div>
                    <div class="modal-body">
                        <div class="mb-3">
                            <label for="name" class="form-label">{{ __('name') }} *</label>
                            <input type="text" class="form-control" id="name" v-model="newUser.name" required>
                        </div>
                        <div class="mb-3">
                            <label for="mobile" class="form-label">{{ __('mobile') }}</label>
                            <input type="number" class="form-control" id="mobile" v-model="newUser.mobile">
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" @click="closeRegisterModal">{{ __('cancel') }}</button>
                        <button type="button" class="btn btn-primary" @click="registerUser">{{ __('register') }}</button>
                    </div>
                </div>
            </div>
        </div>

        <!-- Product Details Modal -->
        <div class="modal fade" id="productDetailsModal" tabindex="-1" aria-labelledby="productDetailsModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title" id="productDetailsModalLabel">{{ selectedProduct ? selectedProduct.name : '' }}</h5>
                        <button type="button" class="btn-close" @click="closeProductDetailsModal"></button>
                    </div>
                    <div class="modal-body" v-if="selectedProduct">
                        <div class="row">
                            <div class="col-md-5">
                                <img :src="selectedProduct.image_url" :alt="selectedProduct.name" class="img-fluid rounded">
                            </div>
                            <div class="col-md-7">
                                <h4>{{ selectedProduct.name }}</h4>
                                <p>{{ selectedProduct.description }}</p>

                                <div class="form-group mt-3" v-if="selectedProduct.variants && selectedProduct.variants.length > 0">
                                    <label for="variant" class="form-label">{{ __('variant') }}</label>
                                    <select id="variant" class="form-select" v-model="selectedVariant">
                                        <option v-for="variant in selectedProduct.variants" :key="variant.id" :value="variant">
                                            {{ variant.measurement }} {{ variant.measurement_unit_name }}
                                            - {{ $currency }} {{ variant.discounted_price > 0 ? variant.discounted_price : variant.price }}
                                        </option>
                                    </select>
                                </div>

                                <div class="mt-3">
                                    <label for="quantity" class="form-label">{{ __('quantity') }}</label>
                                    <div class="input-group">
                                        <button class="btn btn-outline-secondary" @click="productQuantity > 1 ? productQuantity-- : 1">-</button>
                                        <input type="number" class="form-control text-center" id="quantity" v-model="productQuantity" min="1">
                                        <button class="btn btn-outline-secondary" @click="productQuantity++">+</button>
                                    </div>
                                </div>

                                <div class="mt-4">
                                    <button class="btn btn-primary" @click="addToCart">
                                        {{ __('add_to_cart') }}
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Add Discount Modal -->
        <div class="modal fade" id="discountModal" tabindex="-1" aria-labelledby="discountModalLabel" aria-hidden="true">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title" id="discountModalLabel">{{ __('add_discount') }}</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <div class="mb-3">
                            <label for="discountPercentage" class="form-label">{{ __('discount_percentage') }}</label>
                            <div class="input-group">
                                <input
                                    type="number"
                                    class="form-control"
                                    id="discountPercentage"
                                    v-model.number="discount.percentage"
                                    min="0"
                                    max="100"
                                    step="1"
                                    @input="validateDiscountInput('percentage', $event)"
                                >
                                <span class="input-group-text">%</span>
                            </div>
                            <small class="text-muted">{{ __('subtotal') }}: {{ $currency }} {{ calculateSubtotal().toFixed(2) }}</small>
                        </div>
                        <div class="mb-3">
                            <label for="discountAmount" class="form-label">{{ __('discount_amount') }}</label>
                            <div class="input-group">
                                <span class="input-group-text">{{ $currency }}</span>
                                <input
                                    type="number"
                                    class="form-control"
                                    id="discountAmount"
                                    v-model.number="discount.amount"
                                    min="0"
                                    :max="calculateSubtotal()"
                                    step="0.01"
                                    @input="validateDiscountInput('amount', $event)"
                                >
                            </div>
                            <small class="text-muted">{{ __('discount_amount_not_exceed_total') }}</small>
                        </div>
                        <p class="mb-0 text-info">
                            <i class="fas fa-info-circle me-1"></i>
                            {{ __('discount_info_message') }}
                        </p>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">{{ __('cancel') }}</button>
                        <button type="button" class="btn btn-danger" @click="clearDiscount">{{ __('clear_discount') }}</button>
                        <button type="button" class="btn btn-primary" @click="applyDiscount">{{ __('apply_discount') }}</button>
                    </div>
                </div>
            </div>
        </div>

        <!-- Add Additional Charge Modal -->
        <div class="modal fade" id="additionalChargeModal" tabindex="-1" aria-labelledby="additionalChargeModalLabel" aria-hidden="true">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title" id="additionalChargeModalLabel">{{ __('add_additional_charges') }}</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <div v-for="(charge, index) in tempAdditionalCharges" :key="index" class="mb-3">
                            <div class="row mb-2">
                                <div class="col-12">
                                    <div class="d-flex justify-content-between align-items-center">
                                        <label class="form-label">{{ __('charge') }} #{{ index + 1 }}</label>
                                        <button v-if="index > 0" type="button" class="btn btn-sm btn-outline-danger" @click="removeAdditionalCharge(index)">
                                            <i class="fas fa-trash me-1"></i>{{ __('remove') }}
                                        </button>
                                    </div>
                                </div>
                            </div>
                            <div class="row g-2">
                                <div class="col-md-6">
                                    <label for="chargeName" class="form-label">{{ __('charge_name') }}</label>
                                    <input type="text" class="form-control" placeholder="Enter Charge Name" v-model="charge.charge_name" required>
                                    <div v-if="chargeErrors[index] && chargeErrors[index].name" class="text-danger mt-1">{{ chargeErrors[index].name }}</div>
                                </div>
                                <div class="col-md-6">
                                    <label for="chargeAmount" class="form-label">{{ __('amount') }}</label>
                                    <div class="input-group">
                                        <span class="input-group-text">{{ $currency }}</span>
                                        <input type="number" class="form-control" v-model="charge.amount" min="0" step="0.01" required>
                                    </div>
                                    <div v-if="chargeErrors[index] && chargeErrors[index].amount" class="text-danger mt-1">{{ chargeErrors[index].amount }}</div>
                                </div>
                            </div>
                        </div>

                        <button type="button" class="btn btn-outline-success w-100 mt-2" @click.stop.prevent="addNewCharge">
                            <i class="fas fa-plus me-1"></i>{{ __('add_another_charge') }}
                        </button>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">{{ __('cancel') }}</button>
                        <button type="button" class="btn btn-danger" @click="clearAdditionalCharges">{{ __('clear_all_charges') }}</button>
                        <button type="button" class="btn btn-primary" @click="applyAdditionalCharges">{{ __('apply_charges') }}</button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    data() {
        return {
            // Products
            products: [],
            categories: [],
            selectedCategory: '',
            searchTerm: '',
            loading: false,
            searchTimeout: null,

            // Pagination
            currentPage: 1,
            perPage: 12,
            paginationInfo: {
                total: 0,
                from: 0,
                to: 0,
                last_page: 1
            },

            // Users
            users: [],
            filteredUsers: [],
            customerSearchTerm: '',
            showCustomerResults: false,
            searchTimeout: null,
            showRegisterUserModal: false,
            newUser: {
                name: '',
                mobile: ''
            },

            // Tab System Data
            tabs: [{
                id: 'tab-' + Date.now(),
            cart: [],
                selectedUser: null,
                discount: {
                    percentage: 0,
                    amount: 0
                },
                additionalCharges: [],
                paymentMethod: 'cash'
            }],
            activeTabIndex: 0,

            // Product details
            showProductDetailsModal: false,
            selectedProduct: null,
            selectedVariant: null,
            productQuantity: 1,
            isFullscreenMode: false,

            // For modals
            discountModal: null,
            additionalChargeModal: null,
            registerUserModal: null,
            productDetailsModal: null,

            // For validation
            chargeErrors: [],

            // Previous bills
            previousOrders: [],
            viewingPreviousOrder: false,
            currentViewingOrder: null,

            // New property to store previous bill data separately from tabs
            previousOrderData: {
                cart: [],
                selectedUser: null,
                discount: {
                    percentage: 0,
                    amount: 0
                },
                additionalCharges: [],
                paymentMethod: 'cash'
            },

            // Temporary variables for modal data
            tempAdditionalCharges: [],
            previousActiveTabIndex: 0,
            storeName: '', // Add this property to store the fetched store name
        }
    },
    computed: {
        totalPages() {
            return this.paginationInfo.last_page;
        },
        paginationRange() {
            const range = [];
            for (let i = 1; i <= this.totalPages; i++) {
                range.push(i);
            }
            return range;
        },

        // Add missing getActiveTab computed property
        getActiveTab() {
            if (this.viewingPreviousOrder) {
                return this.previousOrderData;
            }
            return this.tabs[this.activeTabIndex];
        },

        // Reactive cart data linked to current tab
        cart: {
            get() {
                if (this.viewingPreviousOrder) {
                    return this.previousOrderData.cart;
                }
                return this.tabs[this.activeTabIndex].cart;
            },
            set(value) {
                if (this.viewingPreviousOrder) {
                    this.previousOrderData.cart = value;
                } else {
                    this.tabs[this.activeTabIndex].cart = value;
                }
            }
        },

        selectedUser: {
            get() {
                if (this.viewingPreviousOrder) {
                    return this.previousOrderData.selectedUser;
                }
                return this.tabs[this.activeTabIndex].selectedUser;
            },
            set(value) {
                if (this.viewingPreviousOrder) {
                    this.previousOrderData.selectedUser = value;
                } else {
                    this.tabs[this.activeTabIndex].selectedUser = value;
                }
            }
        },

        discount: {
            get() {
                if (this.viewingPreviousOrder) {
                    return this.previousOrderData.discount;
                }
                return this.tabs[this.activeTabIndex].discount;
            },
            set(value) {
                if (this.viewingPreviousOrder) {
                    this.previousOrderData.discount = value;
                } else {
                    this.tabs[this.activeTabIndex].discount = value;
                }
            }
        },

        additionalCharges: {
            get() {
                if (this.viewingPreviousOrder) {
                    return this.previousOrderData.additionalCharges;
                }
                return this.tabs[this.activeTabIndex].additionalCharges;
            },
            set(value) {
                if (this.viewingPreviousOrder) {
                    this.previousOrderData.additionalCharges = value;
                } else {
                    this.tabs[this.activeTabIndex].additionalCharges = value;
                }
            }
        },

        paymentMethod: {
            get() {
                if (this.viewingPreviousOrder) {
                    return this.previousOrderData.paymentMethod;
                }
                return this.tabs[this.activeTabIndex].paymentMethod;
            },
            set(value) {
                if (this.viewingPreviousOrder) {
                    this.previousOrderData.paymentMethod = value;
                } else {
                    this.tabs[this.activeTabIndex].paymentMethod = value;
                }
            }
        }
    },
    created() {
        this.getCategories();
        this.getProducts();
        this.getUsers();
        this.loadTabsFromStorage();
        this.loadPreviousOrders();
        this.fetchStoreName(); // Add this line to fetch the store name

        // Initialize fullscreen mode
        this.isFullscreenMode = true;
    },
    mounted() {
        // Initialize Bootstrap modals properly after DOM is updated
        this.$nextTick(() => {
            // First check if bootstrap is available
            if (typeof bootstrap !== 'undefined') {
                this.discountModal = new bootstrap.Modal(document.getElementById('discountModal'));
                this.additionalChargeModal = new bootstrap.Modal(document.getElementById('additionalChargeModal'));
                this.registerUserModal = new bootstrap.Modal(document.getElementById('registerUserModal'));
                this.productDetailsModal = new bootstrap.Modal(document.getElementById('productDetailsModal'));
            }

            // Configure toastr for better appearance
            if (typeof toastr !== 'undefined') {
                toastr.options = {
                    "closeButton": true,
                    "debug": false,
                    "newestOnTop": true,
                    "progressBar": true,
                    "positionClass": "toast-top-right",
                    "preventDuplicates": false,
                    "onclick": null,
                    "showDuration": "300",
                    "hideDuration": "1000",
                    "timeOut": "3000",
                    "extendedTimeOut": "1000",
                    "showEasing": "swing",
                    "hideEasing": "linear",
                    "showMethod": "fadeIn",
                    "hideMethod": "fadeOut"
                };
            }

            // Add click event listener to close customer dropdown when clicking outside
            document.addEventListener('click', this.handleClickOutside);
        });
    },
    beforeDestroy() {
        this.saveTabsToStorage();
        // Remove event listener when component is destroyed
        document.removeEventListener('click', this.handleClickOutside);
    },
    methods: {
        // Add this method to handle closing the dropdown when clicking outside
        handleClickOutside(event) {
            const searchSelect = this.$el.querySelector('.search-select');
            if (searchSelect && !searchSelect.contains(event.target)) {
                this.showCustomerResults = false;
            }
        },

        // Category Methods
        getCategories() {
            axios.get('/api/seller/pos/categories')
                .then(response => {
                    if (response.data.status) {
                        this.categories = response.data.data;
                    }
                })
                .catch(error => {
                    this.$swal.fire({
                        title: this.__('error'),
                        text: this.__('something_went_wrong'),
                        icon: 'error'
                    });
                });
        },

        // Product Methods
        getProducts() {
            this.loading = true;
            const params = {
                page: this.currentPage,
                per_page: this.perPage
            };

            if (this.selectedCategory) {
                params.category_id = this.selectedCategory;
            }

            if (this.searchTerm.trim() !== '') {
                params.search = this.searchTerm.trim();
            }

            axios.get('/api/seller/pos/products', { params })
                .then(response => {
                    this.loading = false;
                    if (response.data.status) {
                        const products = response.data.data;

                        // Initialize selectedVariantId for each product
                        products.forEach(product => {
                            if (product.variants && product.variants.length > 0) {
                                product.selectedVariantId = product.variants[0].id;
                            }
                        });

                        this.products = products;
                        this.paginationInfo = {
                            total: response.data.meta.total,
                            from: response.data.meta.from || 0,
                            to: response.data.meta.to || 0,
                            last_page: response.data.meta.last_page || 1
                        };
                    }
                })
                .catch(error => {
                    this.loading = false;
                    this.$swal.fire({
                        title: this.__('error'),
                        text: this.__('something_went_wrong'),
                        icon: 'error'
                    });
                });
        },

        changePage(page) {
            if (page < 1 || page > this.totalPages) return;
            this.currentPage = page;
            this.getProducts();
        },

        viewProductDetails(product) {
            this.selectedProduct = product;
            this.productQuantity = 1;
            if (product.variants && product.variants.length > 0) {
                this.selectedVariant = product.variants[0];
            }

            // Show the modal using bootstrap
            if (this.productDetailsModal) {
                this.productDetailsModal.show();
            }
        },

        // User Methods
        getUsers() {
            // We'll load a smaller initial set just to populate the dropdown faster
            axios.get('/api/seller/pos/users', { params: { limit: 20 } })
                .then(response => {
                    if (response.data.status) {
                        this.users = response.data.data;
                    }
                })
                .catch(error => {
                    console.error('Error fetching users:', error);
                });
        },

        userSelected() {
            // Any additional logic when a user is selected
        },

        showRegisterModal() {
            if (this.registerUserModal) {
                this.registerUserModal.show();
            }
        },

        registerUser() {
            if (!this.newUser.name) {
                this.$swal.fire({
                    title: this.__('error'),
                    text: this.__('name_is_required'),
                    icon: 'error'
                });
                return;
            }

            axios.post('/api/seller/pos/register_user', {
                name: this.newUser.name,
                mobile: this.newUser.mobile
            })
            .then(response => {
                if (response.data.status) {
                    this.$swal.fire({
                        title: this.__('success'),
                        text: this.__('user_registered_successfully'),
                        icon: 'success'
                    });

                    // Add the new user to the list and select them
                    this.users.unshift(response.data.data);
                    this.selectedUser = response.data.data;

                    // Reset form and close modal
                    this.newUser = { name: '', mobile: '' };
                    this.closeRegisterModal();
                }
            })
            .catch(error => {
                this.$swal.fire({
                    title: this.__('error'),
                    text: error.response?.data?.message || this.__('something_went_wrong'),
                    icon: 'error'
                });
            });
        },

        // Cart Methods
        addToCart() {
            if (!this.selectedProduct || !this.selectedVariant) {
                this.$swal.fire({
                    title: this.__('error'),
                    text: this.__('select_product_and_variant'),
                    icon: 'error'
                });
                return;
            }

            const price = this.selectedVariant.discounted_price > 0
                ? this.selectedVariant.discounted_price
                : this.selectedVariant.price;

            const cartItem = {
                product_id: this.selectedProduct.id,
                product_variant_id: this.selectedVariant.id,
                name: this.selectedProduct.name,
                variant_name: `${this.selectedVariant.measurement} ${this.selectedVariant.measurement_unit_name}`,
                price: price,
                quantity: this.productQuantity,
                image: this.selectedProduct.image_url,
                variant: this.selectedVariant // Store the full variant object for reference
            };

            // Check if item is already in cart
            const existingIndex = this.cart.findIndex(item =>
                item.product_id === cartItem.product_id &&
                item.product_variant_id === cartItem.product_variant_id
            );

            if (existingIndex !== -1) {
                // Update existing item
                this.cart[existingIndex].quantity += this.productQuantity;
            } else {
                // Add new item
                this.cart.push(cartItem);
            }

            // Close modal
            this.closeProductDetailsModal();

            this.$swal.fire({
                title: this.__('success'),
                text: this.__('item_added_to_cart'),
                icon: 'success',
                timer: 1500,
                showConfirmButton: false
            });
        },

        removeFromCart(index) {
            this.cart.splice(index, 1);
            this.saveTabsToStorage();
        },

                                increaseQuantity(index, item) {
            // For unlimited stock products, just increase quantity
            if (item.is_unlimited_stock) {
                item.quantity += 1;
                this.saveTabsToStorage();
                return;
            }

            // For limited stock products, check stock
            if (item.quantity >= item.variant.stock) {
                toastr.error(this.__('not_enough_stock_available'));
                return;
            }

            // Check max stock limit if applicable
            if (item.max_stock && item.quantity >= item.max_stock) {
                toastr.error(this.__('not_enough_stock_available'));
                return;
            }

            item.quantity += 1;
            this.saveTabsToStorage();
        },

        decreaseQuantity(index) {
            if (this.cart[index].quantity > 1) {
                this.cart[index].quantity--;
                this.saveTabsToStorage();
            }
        },

                                updateCartItem(index) {
            const item = this.cart[index];

            // Ensure quantity is at least 1
            if (item.quantity < 1) {
                item.quantity = 1;
                this.saveTabsToStorage();
                return;
            }

            // Skip stock validation for unlimited stock products
            if (!item.is_unlimited_stock) {
                // Check stock availability
                if (item.quantity > item.variant.stock) {
                    this.$swal.fire({
                        toast: true,
                        position: 'top-end',
                        icon: 'error',
                        title: this.__('not_enough_stock_available'),
                        timer: 2000,
                        showConfirmButton: false
                    });
                    // Reset to maximum available stock
                    item.quantity = item.variant.stock;
                }

                // Check max stock limit if applicable
                if (item.max_stock && item.quantity > item.max_stock) {
                    toastr.error(this.__('not_enough_stock_available'));
                    // Reset to maximum stock
                    item.quantity = item.max_stock;
                }
            }

            this.saveTabsToStorage();

            this.saveTabsToStorage();
        },

        calculateSubtotal() {
            return this.cart.reduce((total, item) => total + (item.price * item.quantity), 0);
        },

        calculateDiscountAmount() {
            const subtotal = this.calculateSubtotal();

            // Calculate both percentage and fixed amount discounts
            let percentageDiscount = 0;
            if (this.discount.percentage > 0) {
                percentageDiscount = (subtotal * this.discount.percentage) / 100;
            }

            let fixedAmount = parseFloat(this.discount.amount) || 0;
            let totalDiscount = fixedAmount + percentageDiscount;

            // Make sure discount doesn't exceed subtotal
            return Math.min(totalDiscount, subtotal);
        },

        calculateAdditionalChargesTotal() {
            return this.additionalCharges.reduce((total, charge) => total + parseFloat(charge.amount || 0), 0);
        },

        calculateFinalTotal() {
            const subtotal = this.calculateSubtotal();
            const discountAmount = this.calculateDiscountAmount();
            const additionalCharges = this.calculateAdditionalChargesTotal();

            return subtotal - discountAmount + additionalCharges;
        },

        // Discount Methods
        showDiscountModal() {
            if (this.discountModal) {
                this.discountModal.show();
            }
        },

        closeDiscountModal() {
            if (this.discountModal) {
                this.discountModal.hide();
            }
        },

        applyDiscount() {
            // Validate discount
            if (this.discount.percentage > 100) {
                toastr.error(this.__('percentage_cannot_exceed_100'));
                return;
            }

            if (this.discount.amount > this.calculateSubtotal()) {
                toastr.error(this.__('discount_cannot_exceed_subtotal'));
                return;
            }

            // If percentage is set, calculate the amount and use only percentage-based discount
            if (this.discount.percentage > 0) {
                this.discount.amount = (this.calculateSubtotal() * this.discount.percentage / 100).toFixed(2);
                // Set percentage to zero to avoid double calculation in calculateDiscountAmount
                this.discount.percentage = 0;
            }

            this.saveTabsToStorage();

            toastr.success(this.__('discount_applied'));

            this.closeDiscountModal();
        },

        clearDiscount() {
            // Check if there was actually a discount to clear
            const hadDiscount = this.discount.amount > 0 || this.discount.percentage > 0;
            
            this.discount = {
                percentage: 0,
                amount: 0
            };
            this.saveTabsToStorage();

            // Only show toast if there was actually a discount
            if (hadDiscount) {
                toastr.success(this.__('discount_cleared'));
            }

            this.closeDiscountModal();
        },

        clearDiscountSilent() {
            this.discount = {
                percentage: 0,
                amount: 0
            };
            this.saveTabsToStorage();
        },

        // Additional Charges Methods
        showAdditionalChargeModal() {
            // Initialize temporary charges array from current charges
            this.tempAdditionalCharges = JSON.parse(JSON.stringify(this.additionalCharges));

            // If no charges exist, initialize with an empty one
            if (this.tempAdditionalCharges.length === 0) {
                this.tempAdditionalCharges.push({ charge_name: '', amount: 0 });
            }

            // Clear any previous errors
            this.chargeErrors = this.tempAdditionalCharges.map(() => ({}));

            // Show the modal
            if (this.additionalChargeModal) {
                this.additionalChargeModal.show();
            }
        },

        closeAdditionalChargeModal() {
            if (this.additionalChargeModal) {
                this.additionalChargeModal.hide();
            }
        },

        addNewCharge() {
            this.tempAdditionalCharges.push({ charge_name: '', amount: 0 });
            // Clear error for the new charge
            this.chargeErrors.push({});
        },

        removeAdditionalCharge(index) {
            this.tempAdditionalCharges.splice(index, 1);
            this.chargeErrors.splice(index, 1);
        },

        clearAdditionalCharges() {
            // Check if there were actually charges to clear
            const hadCharges = this.additionalCharges.length > 0;
            
            this.tempAdditionalCharges = [];
            this.chargeErrors = [];
            this.additionalCharges = [];
            this.saveTabsToStorage();

            // Only show toast if there were actually charges
            if (hadCharges) {
                toastr.success(this.__('charges_cleared'));
            }

            this.closeAdditionalChargeModal();
        },

        clearAdditionalChargesSilent() {
            this.tempAdditionalCharges = [];
            this.chargeErrors = [];
            this.additionalCharges = [];
            this.saveTabsToStorage();
        },

        applyAdditionalCharges() {
            // Reset errors
            this.chargeErrors = this.tempAdditionalCharges.map(() => ({}));

            // Validate all charges
            let hasError = false;

            this.tempAdditionalCharges.forEach((charge, index) => {
                if (!charge.charge_name.trim()) {
                    this.$set(this.chargeErrors, index, {...this.chargeErrors[index], name: 'Charge name is required'});
                    hasError = true;
                }

                if (!charge.amount || charge.amount <= 0) {
                    this.$set(this.chargeErrors, index, {...this.chargeErrors[index], amount: 'Amount must be greater than 0'});
                    hasError = true;
                }
            });

            // If validation fails, don't proceed
            if (hasError) {
                return;
            }

            // Apply the charges
            this.additionalCharges = JSON.parse(JSON.stringify(this.tempAdditionalCharges));
            this.saveTabsToStorage();

            toastr.success(this.__('charges_applied'));

            this.closeAdditionalChargeModal();
        },

        // Load and save tabs to storage
        loadTabsFromStorage() {
            const savedTabs = localStorage.getItem('pos_tabs');
            if (savedTabs) {
                this.tabs = JSON.parse(savedTabs);
            } else {
                // Initialize with a single empty tab if no saved data
                this.tabs = [{
                    id: 'tab-' + Date.now(),
                    cart: [],
                    selectedUser: null,
                    discount: {
                        percentage: 0,
                        amount: 0
                    },
                    additionalCharges: [],
                    paymentMethod: 'cash'
                }];
            }
        },
        saveTabsToStorage() {
            localStorage.setItem('pos_tabs', JSON.stringify(this.tabs));
        },
        clearTabs() {
            this.tabs = [{
                id: 'tab-' + Date.now(),
                cart: [],
                selectedUser: null,
                discount: {
                    percentage: 0,
                    amount: 0
                },
                additionalCharges: [],
                paymentMethod: 'cash'
            }];
            this.saveTabsToStorage();
        },

        // Other methods remain the same
        changePerPage() {
            this.currentPage = 1;
            this.getProducts();
        },
        closeRegisterModal() {
            if (this.registerUserModal) {
                this.registerUserModal.hide();
            }
        },
        addSelectedVariantToCart(product) {
            // Check if product is out of stock before proceeding
            if (this.isProductOutOfStock(product)) {
                toastr.error(this.__('out_of_stock'));
                return;
            }

            const variant = this.getSelectedVariant(product);
            if (variant) {
                this.addVariantToCart(product, variant);
            } else {
                toastr.error(this.__('please_select_variant'));
            }
        },
        getSelectedVariant(product) {
            if (!product.variants || product.variants.length === 0) {
                return null;
            }

            if (product.selectedVariantId) {
                return product.variants.find(v => v.id === product.selectedVariantId);
            }

            return product.variants[0];
        },

        // Check if product is out of stock
        isProductOutOfStock(product) {
            // If product has unlimited stock, it's never out of stock
            if (product.is_unlimited_stock) {
                return false;
            }

            // If no variants, consider it out of stock
            if (!product.variants || product.variants.length === 0) {
                return true;
            }

            // For single variant products
            if (product.variants.length === 1) {
                const variant = product.variants[0];
                return variant.stock <= 0 || variant.status === 0;
            }

            // For multiple variant products, check the selected variant
            const selectedVariant = this.getSelectedVariant(product);
            if (!selectedVariant) {
                return true;
            }

            return selectedVariant.stock <= 0 || selectedVariant.status === 0;
        },
                                        addVariantToCart(product, variant) {
            if (this.isProductOutOfStock(product)) {
                toastr.error(this.__('out_of_stock'));
                return;
            }

            const price = variant.discounted_price > 0
                ? variant.discounted_price
                : variant.price;

            const cartItem = {
                product_id: product.id,
                product_variant_id: variant.id,
                name: product.name,
                variant_name: `${variant.measurement} ${variant.measurement_unit_name}`,
                price: price,
                quantity: 1,
                image: product.image_url,
                variant: variant, // Store the full variant object for reference
                is_unlimited_stock: product.is_unlimited_stock // Store product's unlimited stock flag
            };

            // Check if item is already in cart
            const existingIndex = this.cart.findIndex(item =>
                item.product_id === cartItem.product_id &&
                item.product_variant_id === cartItem.product_variant_id
            );

            if (existingIndex !== -1) {
                // For unlimited stock products, just increase quantity
                if (product.is_unlimited_stock) {
                    this.cart[existingIndex].quantity += 1;
                } else {
                    // For limited stock products, check stock
                    if (this.cart[existingIndex].quantity >= variant.stock) {
                        toastr.error(this.__('not_enough_stock_available'));
                        return;
                    }
                    this.cart[existingIndex].quantity += 1;
                }

                toastr.success(this.__('quantity_updated'));
            } else {
                // For limited stock products, check initial stock
                if (!product.is_unlimited_stock && variant.stock <= 0) {
                    toastr.error(this.__('not_enough_stock_available'));
                    return;
                }

                // Add new item
                this.cart.push(cartItem);

                toastr.success(this.__('item_added_to_cart'));
            }

            // Save cart data to localStorage
            this.saveTabsToStorage();
        },
        confirmExit() {
            this.$swal.fire({
                title: 'Are you sure?',
                text: 'Any unsaved bills will be lost.',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonText: 'Yes, exit',
                cancelButtonText: 'Cancel'
            }).then((result) => {
                if (result.isConfirmed) {
                    // Reset tabs to initial state before clearing storage
                    this.tabs = [{
                        id: 'tab-' + Date.now(),
                        cart: [],
                        selectedUser: null,
                        discount: {
                            percentage: 0,
                            amount: 0
                        },
                        additionalCharges: [],
                        paymentMethod: 'cash'
                    }];

                    // Clear localStorage for tabs
                    localStorage.removeItem('pos_tabs');

                    // Redirect to dashboard and reload the page to restore sidebar
                    window.location.href = '/seller/dashboard';
                }
            });
        },
        debounceSearch() {
            if (this.searchTimeout) {
                clearTimeout(this.searchTimeout);
            }
            this.searchTimeout = setTimeout(() => {
                this.getProducts();
            }, 500);
        },
        navigateToProduct(productId) {
            window.location.href = `/seller/manage_products/view/${productId}`;
        },
        addNewTab() {
            // Limit to 5 tabs
            if (this.tabs.length >= 5) {
                toastr.warning('Maximum 5 tabs allowed');
                return;
            }

            this.tabs.push({
                id: 'tab-' + Date.now(),
                cart: [],
                selectedUser: null,
                discount: {
                    percentage: 0,
                    amount: 0
                },
                additionalCharges: [],
                paymentMethod: 'cash'
            });

            // Switch to the newly added tab
            this.activeTabIndex = this.tabs.length - 1;
            this.saveTabsToStorage();
        },
        closeTab(index) {
            // Don't allow closing the tab when viewing a previous order
            if (this.viewingPreviousOrder && this.activeTabIndex === index) {
                toastr.warning('Cannot close tab while viewing a previous bill');
                return;
            }

            // Don't close if it's the only tab
            if (this.tabs.length === 1) {
                toastr.info('Cannot close last tab');
                return;
            }

            // Ask for confirmation if cart has items
            if (this.tabs[index].cart.length > 0) {
                this.$swal.fire({
                    title: 'Are you sure?',
                    text: 'This bill has items. Do you want to discard it?',
                    icon: 'warning',
                    showCancelButton: true,
                    confirmButtonText: 'Yes, discard it',
                    cancelButtonText: 'Cancel'
                }).then((result) => {
                    if (result.isConfirmed) {
                        this.doCloseTab(index);
                    }
                });
            } else {
                this.doCloseTab(index);
            }
        },
        doCloseTab(index) {
            // If closing the active tab, switch to another tab first
            if (this.activeTabIndex === index) {
                this.activeTabIndex = index > 0 ? index - 1 : 0;
            } else if (this.activeTabIndex > index) {
                // If closing a tab before the active tab, adjust the index
                this.activeTabIndex--;
            }

            this.tabs.splice(index, 1);
            this.saveTabsToStorage();
        },
        switchTab(index) {
            if (index >= 0 && index < this.tabs.length) {
                // If viewing a previous bill, just toggle to regular tab view without losing previous bill data
                if (this.viewingPreviousOrder) {
                    this.viewingPreviousOrder = false; // Just hide the previous bill view
                    this.activeTabIndex = index;
                    // Note: We're NOT clearing currentViewingOrder or previousOrderData here
                    // This allows the user to switch back and forth without losing data
                } else {
                    this.activeTabIndex = index;
                }
                this.saveTabsToStorage();
            }
        },
        clearCart() {
            // If viewing a previous order, ask for confirmation before clearing
            if (this.viewingPreviousOrder) {
                this.$swal.fire({
                    title: 'Clear previous order?',
                    text: 'This will clear all items from the previous order view. Are you sure?',
                    icon: 'warning',
                    showCancelButton: true,
                    confirmButtonText: 'Yes, clear it',
                    cancelButtonText: 'Cancel'
                }).then((result) => {
                    if (result.isConfirmed) {
                        this.doCartClear();
                    }
                });
            } else {
                this.doCartClear();
            }
        },
        doCartClear() {
            // Check what needs to be cleared before clearing
            const hadDiscount = this.discount.amount > 0 || this.discount.percentage > 0;
            const hadCharges = this.additionalCharges.length > 0;
            const hadItems = this.cart.length > 0;

            this.cart = [];
            this.clearDiscountSilent(); // Use silent version to avoid duplicate toast
            this.clearAdditionalChargesSilent(); // Use silent version to avoid duplicate toast
            this.selectedUser = null; // Reset customer selection
            this.saveTabsToStorage();

            // If we were viewing a previous order, exit that mode
            if (this.viewingPreviousOrder) {
                this.viewingPreviousOrder = false;
                this.currentViewingOrder = null;
            }

            // Show dynamic toast messages based on what was actually cleared
            if (hadItems && hadDiscount && hadCharges) {
                toastr.success('Cart cleared, discount cleared, charges cleared');
            } else if (hadItems && hadDiscount) {
                toastr.success('Cart cleared, discount cleared');
            } else if (hadItems && hadCharges) {
                toastr.success('Cart cleared, charges cleared');
            } else if (hadDiscount && hadCharges) {
                toastr.success('Discount cleared, charges cleared');
            } else if (hadItems) {
                toastr.success('Cart cleared');
            } else if (hadDiscount) {
                toastr.success('Discount cleared');
            } else if (hadCharges) {
                toastr.success('Charges cleared');
            } else {
                toastr.success('Cart cleared');
            }
        },

        doCartClearSilent() {
            this.cart = [];
            this.clearDiscountSilent();
            this.clearAdditionalChargesSilent();
            this.selectedUser = null; // Reset customer selection
            this.saveTabsToStorage();

            // If we were viewing a previous order, exit that mode
            if (this.viewingPreviousOrder) {
                this.viewingPreviousOrder = false;
                this.currentViewingOrder = null;
            }
        },
        placeOrderAndPrint() {
            this.placeOrder(true);
        },
        placeOrder(print = false) {
            if (this.getActiveTab.cart.length === 0) {
                this.$swal.fire({
                    icon: 'error',
                    title: 'Cart is empty',
                    text: 'Please add items to cart first',
                    showConfirmButton: true,
                    confirmButtonText: 'OK'
                });
                return;
            }

                                    // First, check stock availability for all items
            for (const item of this.getActiveTab.cart) {
                // Skip stock validation for unlimited stock products
                if (item.is_unlimited_stock) {
                    continue;
                }

                // For existing items in previous orders, we need to make sure
                // we're not counting their original quantity against available stock
                let originalQuantity = 0;
                if (this.viewingPreviousOrder && this.currentViewingOrder) {
                    const originalItem = this.currentViewingOrder.items.find(
                        origItem => origItem.product_variant_id === item.product_variant_id
                    );
                    if (originalItem) {
                        originalQuantity = originalItem.quantity;
                    }
                }

                // Check if requested quantity (minus original quantity for updates) exceeds available stock
                if ((item.quantity - originalQuantity) > item.variant.stock) {
                    this.$swal.fire({
                        icon: 'error',
                        title: 'Not enough stock',
                        text: `Not enough stock available for ${item.name}. Available: ${item.variant.stock}`,
                        showConfirmButton: true,
                        confirmButtonText: 'OK'
                    });
                    return;
                }
            }

            // Construct order data
            let orderData = {
                items: this.getActiveTab.cart,
                payment_method: this.getActiveTab.paymentMethod,
                subtotal: this.calculateSubtotal(),
                total: this.calculateFinalTotal(),
                final_total: this.calculateFinalTotal(),
                discount_amount: this.getActiveTab.discount.amount || 0,
                discount_percentage: this.getActiveTab.discount.percentage || 0,
                additional_charges: this.getActiveTab.additionalCharges
            };

            // Add user data if a user is selected
            if (this.getActiveTab.selectedUser) {
                orderData.user_id = this.getActiveTab.selectedUser.id;
                orderData.user_type = this.getActiveTab.selectedUser.user_type;
            }

            // If we're viewing a previous order, add order_id for updating
            if (this.viewingPreviousOrder && this.currentViewingOrder) {
                orderData.order_id = this.currentViewingOrder.id;
            }

            // Confirm order placement or update
            const actionText = this.viewingPreviousOrder ? 'Update' : 'Place';
            this.$swal.fire({
                title: `Confirm order ${actionText}`,
                text: `Are you sure you want to ${actionText} the order?`,
                icon: 'question',
                showCancelButton: true,
                confirmButtonColor: '#3085d6',
                cancelButtonColor: '#d33',
                confirmButtonText: `Yes, ${actionText} it`,
                cancelButtonText: 'Cancel'
            }).then((result) => {
                if (result.isConfirmed) {
                    // Show loading
                    this.$swal.fire({
                        title: 'Processing',
                        text: `Processing order ${actionText}...`,
                        allowOutsideClick: false,
                        allowEscapeKey: false,
                        didOpen: () => {
                            this.$swal.showLoading();
                        }
                    });

                    // Determine which API endpoint to use based on whether we're updating or creating
                    const apiEndpoint = this.viewingPreviousOrder
                        ? '/api/seller/pos/update_order'
                        : '/api/seller/pos/place_order';

                    // Send order to API
                    axios.post(apiEndpoint, orderData)
                        .then(response => {
                            if (response.data.status) {
                                const orderId = response.data.data.pos_order_id;

                                // Only show print dialog if print parameter is true
                                if (print) {
                                    // Try to print via iframe first
                                    this.printInvoice(orderId);

                                    // Show a notification with a link to open the invoice directly if needed
                                    this.$swal.fire({
                                        position: 'top-end',
                                        icon: 'info',
                                        title: 'Invoice Printing',
                                        html: 'If the print dialog doesn\'t appear, <a href="/pos/invoice/' + orderId + '" target="_blank">click here to open the invoice</a>',
                                        showConfirmButton: false,
                                        timer: 5000,
                                        timerProgressBar: true
                                    });
                                }

                                if (!this.viewingPreviousOrder) {
                                    // Save the order to local storage for previous bills feature
                                    this.saveOrderToHistory(orderId, orderData);

                                    // Remove current tab instead of just clearing it
                                    if (this.tabs.length > 1) {
                                        // If there are multiple tabs, remove the current one
                                        this.doCloseTab(this.activeTabIndex);
                                    } else {
                                        this.doCartClearSilent();
                                    }

                                    this.saveTabsToStorage();
                                } else {
                                    // Update the order in localStorage
                                    this.updateOrderInHistory(orderData);

                                    // After updating, exit the previous bill view
                                    this.exitPreviousBillView();
                                }

                                this.$swal.fire({
                                    icon: 'success',
                                    title: `Order ${actionText}d`,
                                    text: `Order ${actionText}d successfully`,
                                    showConfirmButton: true,
                                    confirmButtonText: 'OK'
                                });
                            } else {
                                this.$swal.fire({
                                    icon: 'error',
                                    title: 'Error',
                                    text: response.data.message || `Error ${actionText}ing order`,
                                    showConfirmButton: true,
                                    confirmButtonText: 'OK'
                                });
                            }
                        })
                        .catch(error => {
                            let errorMessage = `Error ${actionText}ing order`;
                            if (error.response && error.response.data && error.response.data.message) {
                                errorMessage = error.response.data.message;
                            }

                            this.$swal.fire({
                                icon: 'error',
                                title: 'Error',
                                text: errorMessage,
                                showConfirmButton: true,
                                confirmButtonText: 'OK'
                            });
                        });
                }
            });
        },
        closeProductDetailsModal() {
            if (this.productDetailsModal) {
                this.productDetailsModal.hide();
            }
        },
        saveOrderToHistory(orderId, orderData) {
            // Create a complete order record
            const order = {
                id: orderId,
                date: new Date().toISOString(),
                items: orderData.items,
                user: this.getActiveTab.selectedUser,
                discount: this.getActiveTab.discount,
                additionalCharges: this.getActiveTab.additionalCharges,
                paymentMethod: this.getActiveTab.paymentMethod,
                subtotal: this.calculateSubtotal(),
                total: this.calculateFinalTotal()
            };

            // Retrieve existing orders from localStorage
            let previousOrders = localStorage.getItem('pos_previous_orders');
            if (previousOrders) {
                previousOrders = JSON.parse(previousOrders);
            } else {
                previousOrders = [];
            }

            // Add the new order to the beginning of the array (most recent first)
            previousOrders.unshift(order);

            // Limit to the last 20 orders
            if (previousOrders.length > 20) {
                previousOrders = previousOrders.slice(0, 20);
            }

            // Save back to localStorage
            localStorage.setItem('pos_previous_orders', JSON.stringify(previousOrders));

            // Update the component's previousOrders array
            this.previousOrders = previousOrders;
        },
        loadPreviousOrders() {
            let previousOrders = localStorage.getItem('pos_previous_orders');
            if (previousOrders) {
                this.previousOrders = JSON.parse(previousOrders);
            } else {
                this.previousOrders = [];
            }
        },
        togglePreviousBill() {
            // Always reload the latest orders first to ensure we have the most recent data
            this.loadPreviousOrders();

            // If there are no previous orders, show a message
            if (this.previousOrders.length === 0) {
                this.$swal.fire({
                    icon: 'info',
                    title: 'No previous bills',
                    text: 'There are no previous bills available to view',
                    showConfirmButton: true,
                    confirmButtonText: 'OK'
                });
                return;
            }

            // Toggle previous bill view
            this.viewingPreviousOrder = !this.viewingPreviousOrder;

            // If turning on previous bill view, always load the most recent order (index 0)
            if (this.viewingPreviousOrder) {
                this.loadPreviousOrder(this.previousOrders[0]);
            }
        },
        loadPreviousOrder(order) {
            // Mark that we're viewing a previous order
            this.viewingPreviousOrder = true;
            this.currentViewingOrder = order;

            this.previousOrderData = {
                cart: [...order.items],
                selectedUser: order.user,
                discount: { ...order.discount },
                additionalCharges: [...order.additionalCharges],
                paymentMethod: order.paymentMethod
            };

            toastr.success('Previous bill loaded - Make changes if needed and click Place Order to update');
        },
        updateOrderInHistory(updateData) {
            // Find the order in previousOrders and update it
            const orderIndex = this.previousOrders.findIndex(order => order.id === updateData.order_id);
            if (orderIndex !== -1) {
                // Update the order data
                this.previousOrders[orderIndex].items = updateData.items;
                this.previousOrders[orderIndex].discount = {
                    percentage: updateData.discount_percentage,
                    amount: updateData.discount_amount
                };
                this.previousOrders[orderIndex].additionalCharges = updateData.additional_charges;
                this.previousOrders[orderIndex].paymentMethod = updateData.payment_method;
                this.previousOrders[orderIndex].subtotal = this.calculateSubtotal();
                this.previousOrders[orderIndex].total = this.calculateFinalTotal();

                localStorage.setItem('pos_previous_orders', JSON.stringify(this.previousOrders));
            }
        },
        exitPreviousBillView() {
            this.viewingPreviousOrder = false;

            toastr.info('Returned to regular mode');
        },
        formatDate(dateString) {
            if (!dateString) return '';
            const date = new Date(dateString);
            return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
        },
                printInvoice(orderId) {
            const baseUrl = window.location.origin;
            const invoiceUrl = `${baseUrl}/pos/invoice/${orderId}`;

            const printOperation = new Promise((resolve, reject) => {
                let printFrame = null;
                let cleanupTimeout = null;

                const cleanup = () => {
                    if (cleanupTimeout) {
                        clearTimeout(cleanupTimeout);
                    }
                    if (printFrame && printFrame.parentNode) {
                        printFrame.parentNode.removeChild(printFrame);
                    }
                };

                try {
                    printFrame = document.createElement('iframe');
                    printFrame.style.cssText = 'position:fixed;bottom:0;right:0;width:0;height:0;border:0;';
                    printFrame.setAttribute('name', 'print_frame_' + Date.now());

                    printFrame.onload = () => {
                        try {
                            const contentWindow = printFrame.contentWindow;

                            if (!contentWindow || !contentWindow.document || !contentWindow.document.body) {
                                throw new Error('Cannot access iframe content');
                            }

                            setTimeout(() => {
                                try {
                                    contentWindow.print();

                                    cleanupTimeout = setTimeout(cleanup, 1000);
                                    resolve();
                                } catch (printError) {
                                    reject(printError);
                                }
                            }, 200);
                        } catch (error) {
                            reject(error);
                        }
                    };

                    printFrame.onerror = () => {
                        reject(new Error('Failed to load invoice in iframe'));
                    };

                    document.body.appendChild(printFrame);
                    printFrame.src = invoiceUrl;

                } catch (error) {
                    cleanup();
                    reject(error);
                }
            });

            printOperation
                .catch(error => {
                    console.error('Print failed:', error);
                    window.open(invoiceUrl, '_blank');
                });
        },
        searchCustomers() {
            clearTimeout(this.searchTimeout);
            this.showCustomerResults = true;

            if (!this.customerSearchTerm || this.customerSearchTerm.trim().length < 2) {
                this.filteredUsers = [];
                return;
            }

            this.searchTimeout = setTimeout(() => {
                axios.get('/api/seller/pos/users', {
                    params: { search: this.customerSearchTerm.trim() }
                })
                .then(response => {
                    if (response.data.status) {
                        this.filteredUsers = response.data.data;
                    }
                })
                .catch(error => {
                    console.error('Error searching customers:', error);
                });
            }, 300);
        },

        selectUser(user) {
            this.selectedUser = user;
            this.customerSearchTerm = user.name;
            this.showCustomerResults = false;
            this.saveTabsToStorage();
        },

        selectCashSale() {
            this.selectedUser = null;
            this.customerSearchTerm = '';
            this.showCustomerResults = false;
            this.saveTabsToStorage();
        },
        fetchStoreName() {
            axios.get('/api/seller/pos/store-name')
                .then(response => {
                    if (response.data.status) {
                        this.storeName = response.data.data.store_name;
                    }
                })
                .catch(error => {
                    console.error('Error fetching store name:', error);
                });
        },

        validateDiscountInput(type, event) {
            let value = event.target.value;

            if (value.includes('-')) {
                value = value.replace('-', '');
            }

            value = Math.max(0, Number(value));

            if (type === 'percentage') {
                value = Math.min(100, value);
                this.discount.percentage = value;
            } else if (type === 'amount') {
                value = Math.min(this.calculateSubtotal(), value);
                this.discount.amount = value;
            }

            event.target.value = value;
        },
    }
}
</script>

<style>
 .sidebar-wrapper{
    display: none !important;
 }
 header{
    display: none !important;
 }
 #main{
    padding: 0px 10px 10px 10px !important;
    margin: 0px !important;
 }
</style>

<style scoped>
.product-card {
    border: 1px solid #e9ecef;
    border-radius: 8px;
    overflow: hidden;
    transition: all 0.3s ease;
    cursor: pointer;
    height: 100%;
    box-shadow: 0 2px 5px rgba(0, 0, 0, 0.05);
}

.product-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.product-image {
    height: 160px;
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
    background-color: #f8f9fa;
    padding: 10px;
}

.product-image img {
    max-height: 140px;
    max-width: 100%;
    object-fit: contain;
    display: block;
    margin: 0 auto;
}

.product-info {
    padding: 12px;
}

.product-name-measure-row {
    flex-wrap: nowrap;
}

.product-title {
    font-size: 16px;
    overflow: hidden;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    min-width: 0;
}

.single-variant {
    font-size: 0.75rem;
    color: #6c757d;
    white-space: nowrap;
    flex-shrink: 0;
}

.variant-info {
    font-weight: 600;
}

.form-select-sm {
    font-size: 0.8rem;
    padding: 0.25rem 0.5rem;
    height: 30px;
}

.mini-select {
    font-size: 0.75rem;
    padding: 0.2rem 0.4rem;
    height: 25px;
}

.short-select {
    width: auto;
    min-width: 80px;
    max-width: 120px;
}

.btn-xs {
    padding: 0.2rem 0.5rem;
    font-size: 0.8rem;
    line-height: 1.2;
    margin-top: 5px;
}

.no-variants {
    padding: 8px 0;
    text-align: center;
    font-size: 12px;
}

.product-price {
    font-weight: bold;
    color: #435ebe;
    margin-bottom: 5px;
}

.original-price {
    text-decoration: line-through;
    color: #6c757d;
    font-size: 11px;
    font-weight: normal;
    margin-left: 4px;
}

.add-btn {
    padding: 2px 6px;
    font-size: 12px;
}

.product-price .discounted {
    color: #dc3545;
}

.product-price .original-price {
    text-decoration: line-through;
    color: #6c757d;
    font-size: 12px;
    margin-left: 5px;
}

.cart-items {
    max-height: 400px;
    overflow-y: auto;
}

.cart-item {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    padding: 10px 0;
    border-bottom: 1px solid #e9ecef;
    position: relative;
}

.item-image {
    width: 60px;
    height: 60px;
    overflow: hidden;
    border-radius: 4px;
    margin-right: 10px;
    border: 1px solid #e9ecef;
}

.item-image img {
    width: 100%;
    height: 100%;
    object-fit: cover;
}

.item-details {
    flex: 1;
    min-width: 150px;
    padding-right: 10px;
}

.item-details h5 {
    font-size: 14px;
    margin-bottom: 3px;
    font-weight: 600;
}

.item-details p.variant-info {
    font-size: 12px;
    color: #6c757d;
    margin-bottom: 5px;
    font-weight: 600;
}

.item-details .price {
    font-weight: bold;
    color: #435ebe;
    font-size: 13px;
}

.item-quantity {
    width: 120px;
    margin: 10px 0;
}

.item-quantity .form-control {
    padding: 0.25rem 0.5rem;
    text-align: center;
}

.item-quantity .input-group {
    flex-wrap: nowrap;
}

.item-total {
    width: 80px;
    text-align: right;
    font-weight: bold;
    margin-right: 10px;
}

.item-actions {
    margin-left: auto;
}

@media (min-width: 768px) {
    .cart-item {
        flex-wrap: nowrap;
    }

    .item-quantity {
        margin: 0 10px;
    }
}

@media (max-width: 767.98px) {
    .cart-item {
        padding: 15px 0;
    }

    .item-details {
        width: calc(100% - 70px);
    }

    .item-quantity {
        width: 60%;
    }

    .item-total {
        width: 30%;
        margin-left: auto;
    }

    .item-actions {
        position: absolute;
        top: 10px;
        right: 0;
    }
}

.item-quantity .form-control::-webkit-outer-spin-button,
.item-quantity .form-control::-webkit-inner-spin-button {
    -webkit-appearance: none;
    margin: 0;
}

.item-quantity .form-control[type=number] {
    -moz-appearance: textfield;
}

.fullscreen-header {
    background: #e2e3e7;
    color: white;
    margin-bottom: 15px;
}

.fullscreen-header h5 {
    margin-bottom: 0;
}

.pos-tabs-container {
    background: #fff;
    padding: 10px;
    border-radius: 4px;
    box-shadow: 0 2px 5px rgba(0, 0, 0, 0.05);
}

.pos-tabs-wrapper {
    display: flex;
    width: 100%;
    gap: 8px;
}

.pos-tab {
    width: 19%;
    flex: 0 0 auto;
    padding: 10px 15px;
    background-color: #f8f9fa;
    border: 1px solid #dee2e6;
    border-radius: 8px;
    cursor: pointer;
    display: flex;
    justify-content: space-between;
    align-items: center;
    transition: all 0.2s;
}

.pos-tab:hover {
    background-color: #e9ecef;
}

.pos-tab.active {
    background-color: #9AC444;
    color: white;
    border-color: #9AC444;
}

.pos-tab-close {
    font-size: 18px;
    margin-left: 8px;
    cursor: pointer;
}

.pos-tab-close:hover {
    color: #dc3545;
}

.previous-bill-tab {
    background-color: #007bff !important;
    color: white !important;
    border-color: #007bff !important;
    position: relative;
}

.previous-bill-tab::after {
    content: "Editing";
    position: absolute;
    top: -8px;
    right: 5px;
    background-color: #dc3545;
    color: white;
    font-size: 10px;
    padding: 2px 5px;
    border-radius: 3px;
    font-weight: bold;
}

.disabled-tab {
    opacity: 0.6;
    cursor: not-allowed;
    background-color: #f0f0f0 !important;
}

.disabled-tab:hover {
    background-color: #f0f0f0 !important;
}

.previous-bill-badge {
    animation: pulse 2s infinite;
}

@keyframes pulse {
    0% {
        transform: scale(1);
        opacity: 1;
    }
    50% {
        transform: scale(1.05);
        opacity: 0.8;
    }
    100% {
        transform: scale(1);
        opacity: 1;
    }
}

.previous-bill-indicator {
    border-left: 4px solid #0d6efd;
}

.badge {
    font-size: 85%;
}

.search-select {
    position: relative;
    width: 100%;
}

.search-results {
    position: absolute;
    top: 100%;
    left: 0;
    right: 0;
    background: white;
    border: 1px solid #ddd;
    border-radius: 0 0 4px 4px;
    max-height: 200px;
    overflow-y: auto;
    z-index: 1000;
    box-shadow: 0 4px 8px rgba(0,0,0,0.1);
}

.search-option {
    padding: 8px 12px;
    cursor: pointer;
    border-bottom: 1px solid #f0f0f0;
}

.search-option:hover {
    background-color: #f5f5f5;
}

.search-option:last-child {
    border-bottom: none;
}

.out-of-stock {
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 32px;
}

.out-of-stock .badge {
    font-size: 0.75rem;
    padding: 0.4rem 0.6rem;
    font-weight: 600;
    background-color: #dc3545 !important;
    color: white;
    border-radius: 4px;
}
</style>
