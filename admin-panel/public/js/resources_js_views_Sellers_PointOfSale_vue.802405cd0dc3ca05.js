"use strict";
(self["webpackChunk"] = self["webpackChunk"] || []).push([["resources_js_views_Sellers_PointOfSale_vue"],{

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Sellers/PointOfSale.vue?vue&type=script&lang=js":
/*!********************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Sellers/PointOfSale.vue?vue&type=script&lang=js ***!
  \********************************************************************************************************************************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }
function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }
function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter); }
function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }
function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }
function _createForOfIteratorHelper(o, allowArrayLike) { var it = typeof Symbol !== "undefined" && o[Symbol.iterator] || o["@@iterator"]; if (!it) { if (Array.isArray(o) || (it = _unsupportedIterableToArray(o)) || allowArrayLike && o && typeof o.length === "number") { if (it) o = it; var i = 0; var F = function F() {}; return { s: F, n: function n() { if (i >= o.length) return { done: true }; return { done: false, value: o[i++] }; }, e: function e(_e) { throw _e; }, f: F }; } throw new TypeError("Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); } var normalCompletion = true, didErr = false, err; return { s: function s() { it = it.call(o); }, n: function n() { var step = it.next(); normalCompletion = step.done; return step; }, e: function e(_e2) { didErr = true; err = _e2; }, f: function f() { try { if (!normalCompletion && it["return"] != null) it["return"](); } finally { if (didErr) throw err; } } }; }
function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }
function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }
function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }
function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }
function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//

/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = ({
  data: function data() {
    var _ref;
    return _ref = {
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
      showCustomerResults: false
    }, _defineProperty(_ref, "searchTimeout", null), _defineProperty(_ref, "showRegisterUserModal", false), _defineProperty(_ref, "newUser", {
      name: '',
      mobile: ''
    }), _defineProperty(_ref, "tabs", [{
      id: 'tab-' + Date.now(),
      cart: [],
      selectedUser: null,
      discount: {
        percentage: 0,
        amount: 0
      },
      additionalCharges: [],
      paymentMethod: 'cash'
    }]), _defineProperty(_ref, "activeTabIndex", 0), _defineProperty(_ref, "showProductDetailsModal", false), _defineProperty(_ref, "selectedProduct", null), _defineProperty(_ref, "selectedVariant", null), _defineProperty(_ref, "productQuantity", 1), _defineProperty(_ref, "isFullscreenMode", false), _defineProperty(_ref, "discountModal", null), _defineProperty(_ref, "additionalChargeModal", null), _defineProperty(_ref, "registerUserModal", null), _defineProperty(_ref, "productDetailsModal", null), _defineProperty(_ref, "chargeErrors", []), _defineProperty(_ref, "previousOrders", []), _defineProperty(_ref, "viewingPreviousOrder", false), _defineProperty(_ref, "currentViewingOrder", null), _defineProperty(_ref, "previousOrderData", {
      cart: [],
      selectedUser: null,
      discount: {
        percentage: 0,
        amount: 0
      },
      additionalCharges: [],
      paymentMethod: 'cash'
    }), _defineProperty(_ref, "tempAdditionalCharges", []), _defineProperty(_ref, "previousActiveTabIndex", 0), _defineProperty(_ref, "storeName", ''), _ref;
  },
  computed: {
    totalPages: function totalPages() {
      return this.paginationInfo.last_page;
    },
    paginationRange: function paginationRange() {
      var range = [];
      for (var i = 1; i <= this.totalPages; i++) {
        range.push(i);
      }
      return range;
    },
    // Add missing getActiveTab computed property
    getActiveTab: function getActiveTab() {
      if (this.viewingPreviousOrder) {
        return this.previousOrderData;
      }
      return this.tabs[this.activeTabIndex];
    },
    // Reactive cart data linked to current tab
    cart: {
      get: function get() {
        if (this.viewingPreviousOrder) {
          return this.previousOrderData.cart;
        }
        return this.tabs[this.activeTabIndex].cart;
      },
      set: function set(value) {
        if (this.viewingPreviousOrder) {
          this.previousOrderData.cart = value;
        } else {
          this.tabs[this.activeTabIndex].cart = value;
        }
      }
    },
    selectedUser: {
      get: function get() {
        if (this.viewingPreviousOrder) {
          return this.previousOrderData.selectedUser;
        }
        return this.tabs[this.activeTabIndex].selectedUser;
      },
      set: function set(value) {
        if (this.viewingPreviousOrder) {
          this.previousOrderData.selectedUser = value;
        } else {
          this.tabs[this.activeTabIndex].selectedUser = value;
        }
      }
    },
    discount: {
      get: function get() {
        if (this.viewingPreviousOrder) {
          return this.previousOrderData.discount;
        }
        return this.tabs[this.activeTabIndex].discount;
      },
      set: function set(value) {
        if (this.viewingPreviousOrder) {
          this.previousOrderData.discount = value;
        } else {
          this.tabs[this.activeTabIndex].discount = value;
        }
      }
    },
    additionalCharges: {
      get: function get() {
        if (this.viewingPreviousOrder) {
          return this.previousOrderData.additionalCharges;
        }
        return this.tabs[this.activeTabIndex].additionalCharges;
      },
      set: function set(value) {
        if (this.viewingPreviousOrder) {
          this.previousOrderData.additionalCharges = value;
        } else {
          this.tabs[this.activeTabIndex].additionalCharges = value;
        }
      }
    },
    paymentMethod: {
      get: function get() {
        if (this.viewingPreviousOrder) {
          return this.previousOrderData.paymentMethod;
        }
        return this.tabs[this.activeTabIndex].paymentMethod;
      },
      set: function set(value) {
        if (this.viewingPreviousOrder) {
          this.previousOrderData.paymentMethod = value;
        } else {
          this.tabs[this.activeTabIndex].paymentMethod = value;
        }
      }
    }
  },
  created: function created() {
    this.getCategories();
    this.getProducts();
    this.getUsers();
    this.loadTabsFromStorage();
    this.loadPreviousOrders();
    this.fetchStoreName(); // Add this line to fetch the store name

    // Initialize fullscreen mode
    this.isFullscreenMode = true;
  },
  mounted: function mounted() {
    var _this = this;
    // Initialize Bootstrap modals properly after DOM is updated
    this.$nextTick(function () {
      // First check if bootstrap is available
      if (typeof bootstrap !== 'undefined') {
        _this.discountModal = new bootstrap.Modal(document.getElementById('discountModal'));
        _this.additionalChargeModal = new bootstrap.Modal(document.getElementById('additionalChargeModal'));
        _this.registerUserModal = new bootstrap.Modal(document.getElementById('registerUserModal'));
        _this.productDetailsModal = new bootstrap.Modal(document.getElementById('productDetailsModal'));
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
      document.addEventListener('click', _this.handleClickOutside);
    });
  },
  beforeDestroy: function beforeDestroy() {
    this.saveTabsToStorage();
    // Remove event listener when component is destroyed
    document.removeEventListener('click', this.handleClickOutside);
  },
  methods: {
    // Add this method to handle closing the dropdown when clicking outside
    handleClickOutside: function handleClickOutside(event) {
      var searchSelect = this.$el.querySelector('.search-select');
      if (searchSelect && !searchSelect.contains(event.target)) {
        this.showCustomerResults = false;
      }
    },
    // Category Methods
    getCategories: function getCategories() {
      var _this2 = this;
      axios.get('/api/seller/pos/categories').then(function (response) {
        if (response.data.status) {
          _this2.categories = response.data.data;
        }
      })["catch"](function (error) {
        _this2.$swal.fire({
          title: _this2.__('error'),
          text: _this2.__('something_went_wrong'),
          icon: 'error'
        });
      });
    },
    // Product Methods
    getProducts: function getProducts() {
      var _this3 = this;
      this.loading = true;
      var params = {
        page: this.currentPage,
        per_page: this.perPage
      };
      if (this.selectedCategory) {
        params.category_id = this.selectedCategory;
      }
      if (this.searchTerm.trim() !== '') {
        params.search = this.searchTerm.trim();
      }
      axios.get('/api/seller/pos/products', {
        params: params
      }).then(function (response) {
        _this3.loading = false;
        if (response.data.status) {
          var products = response.data.data;

          // Initialize selectedVariantId for each product
          products.forEach(function (product) {
            if (product.variants && product.variants.length > 0) {
              product.selectedVariantId = product.variants[0].id;
            }
          });
          _this3.products = products;
          _this3.paginationInfo = {
            total: response.data.meta.total,
            from: response.data.meta.from || 0,
            to: response.data.meta.to || 0,
            last_page: response.data.meta.last_page || 1
          };
        }
      })["catch"](function (error) {
        _this3.loading = false;
        _this3.$swal.fire({
          title: _this3.__('error'),
          text: _this3.__('something_went_wrong'),
          icon: 'error'
        });
      });
    },
    changePage: function changePage(page) {
      if (page < 1 || page > this.totalPages) return;
      this.currentPage = page;
      this.getProducts();
    },
    viewProductDetails: function viewProductDetails(product) {
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
    getUsers: function getUsers() {
      var _this4 = this;
      // We'll load a smaller initial set just to populate the dropdown faster
      axios.get('/api/seller/pos/users', {
        params: {
          limit: 20
        }
      }).then(function (response) {
        if (response.data.status) {
          _this4.users = response.data.data;
        }
      })["catch"](function (error) {
        console.error('Error fetching users:', error);
      });
    },
    userSelected: function userSelected() {
      // Any additional logic when a user is selected
    },
    showRegisterModal: function showRegisterModal() {
      if (this.registerUserModal) {
        this.registerUserModal.show();
      }
    },
    registerUser: function registerUser() {
      var _this5 = this;
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
      }).then(function (response) {
        if (response.data.status) {
          _this5.$swal.fire({
            title: _this5.__('success'),
            text: _this5.__('user_registered_successfully'),
            icon: 'success'
          });

          // Add the new user to the list and select them
          _this5.users.unshift(response.data.data);
          _this5.selectedUser = response.data.data;

          // Reset form and close modal
          _this5.newUser = {
            name: '',
            mobile: ''
          };
          _this5.closeRegisterModal();
        }
      })["catch"](function (error) {
        var _error$response, _error$response$data;
        _this5.$swal.fire({
          title: _this5.__('error'),
          text: ((_error$response = error.response) === null || _error$response === void 0 ? void 0 : (_error$response$data = _error$response.data) === null || _error$response$data === void 0 ? void 0 : _error$response$data.message) || _this5.__('something_went_wrong'),
          icon: 'error'
        });
      });
    },
    // Cart Methods
    addToCart: function addToCart() {
      if (!this.selectedProduct || !this.selectedVariant) {
        this.$swal.fire({
          title: this.__('error'),
          text: this.__('select_product_and_variant'),
          icon: 'error'
        });
        return;
      }
      var price = this.selectedVariant.discounted_price > 0 ? this.selectedVariant.discounted_price : this.selectedVariant.price;
      var cartItem = {
        product_id: this.selectedProduct.id,
        product_variant_id: this.selectedVariant.id,
        name: this.selectedProduct.name,
        variant_name: "".concat(this.selectedVariant.measurement, " ").concat(this.selectedVariant.measurement_unit_name),
        price: price,
        quantity: this.productQuantity,
        image: this.selectedProduct.image_url,
        variant: this.selectedVariant // Store the full variant object for reference
      };

      // Check if item is already in cart
      var existingIndex = this.cart.findIndex(function (item) {
        return item.product_id === cartItem.product_id && item.product_variant_id === cartItem.product_variant_id;
      });
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
    removeFromCart: function removeFromCart(index) {
      this.cart.splice(index, 1);
      this.saveTabsToStorage();
    },
    increaseQuantity: function increaseQuantity(index, item) {
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
    decreaseQuantity: function decreaseQuantity(index) {
      if (this.cart[index].quantity > 1) {
        this.cart[index].quantity--;
        this.saveTabsToStorage();
      }
    },
    updateCartItem: function updateCartItem(index) {
      var item = this.cart[index];

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
    calculateSubtotal: function calculateSubtotal() {
      return this.cart.reduce(function (total, item) {
        return total + item.price * item.quantity;
      }, 0);
    },
    calculateDiscountAmount: function calculateDiscountAmount() {
      var subtotal = this.calculateSubtotal();

      // Calculate both percentage and fixed amount discounts
      var percentageDiscount = 0;
      if (this.discount.percentage > 0) {
        percentageDiscount = subtotal * this.discount.percentage / 100;
      }
      var fixedAmount = parseFloat(this.discount.amount) || 0;
      var totalDiscount = fixedAmount + percentageDiscount;

      // Make sure discount doesn't exceed subtotal
      return Math.min(totalDiscount, subtotal);
    },
    calculateAdditionalChargesTotal: function calculateAdditionalChargesTotal() {
      return this.additionalCharges.reduce(function (total, charge) {
        return total + parseFloat(charge.amount || 0);
      }, 0);
    },
    calculateFinalTotal: function calculateFinalTotal() {
      var subtotal = this.calculateSubtotal();
      var discountAmount = this.calculateDiscountAmount();
      var additionalCharges = this.calculateAdditionalChargesTotal();
      return subtotal - discountAmount + additionalCharges;
    },
    // Discount Methods
    showDiscountModal: function showDiscountModal() {
      if (this.discountModal) {
        this.discountModal.show();
      }
    },
    closeDiscountModal: function closeDiscountModal() {
      if (this.discountModal) {
        this.discountModal.hide();
      }
    },
    applyDiscount: function applyDiscount() {
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
    clearDiscount: function clearDiscount() {
      // Check if there was actually a discount to clear
      var hadDiscount = this.discount.amount > 0 || this.discount.percentage > 0;
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
    clearDiscountSilent: function clearDiscountSilent() {
      this.discount = {
        percentage: 0,
        amount: 0
      };
      this.saveTabsToStorage();
    },
    // Additional Charges Methods
    showAdditionalChargeModal: function showAdditionalChargeModal() {
      // Initialize temporary charges array from current charges
      this.tempAdditionalCharges = JSON.parse(JSON.stringify(this.additionalCharges));

      // If no charges exist, initialize with an empty one
      if (this.tempAdditionalCharges.length === 0) {
        this.tempAdditionalCharges.push({
          charge_name: '',
          amount: 0
        });
      }

      // Clear any previous errors
      this.chargeErrors = this.tempAdditionalCharges.map(function () {
        return {};
      });

      // Show the modal
      if (this.additionalChargeModal) {
        this.additionalChargeModal.show();
      }
    },
    closeAdditionalChargeModal: function closeAdditionalChargeModal() {
      if (this.additionalChargeModal) {
        this.additionalChargeModal.hide();
      }
    },
    addNewCharge: function addNewCharge() {
      this.tempAdditionalCharges.push({
        charge_name: '',
        amount: 0
      });
      // Clear error for the new charge
      this.chargeErrors.push({});
    },
    removeAdditionalCharge: function removeAdditionalCharge(index) {
      this.tempAdditionalCharges.splice(index, 1);
      this.chargeErrors.splice(index, 1);
    },
    clearAdditionalCharges: function clearAdditionalCharges() {
      // Check if there were actually charges to clear
      var hadCharges = this.additionalCharges.length > 0;
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
    clearAdditionalChargesSilent: function clearAdditionalChargesSilent() {
      this.tempAdditionalCharges = [];
      this.chargeErrors = [];
      this.additionalCharges = [];
      this.saveTabsToStorage();
    },
    applyAdditionalCharges: function applyAdditionalCharges() {
      var _this6 = this;
      // Reset errors
      this.chargeErrors = this.tempAdditionalCharges.map(function () {
        return {};
      });

      // Validate all charges
      var hasError = false;
      this.tempAdditionalCharges.forEach(function (charge, index) {
        if (!charge.charge_name.trim()) {
          _this6.$set(_this6.chargeErrors, index, _objectSpread(_objectSpread({}, _this6.chargeErrors[index]), {}, {
            name: 'Charge name is required'
          }));
          hasError = true;
        }
        if (!charge.amount || charge.amount <= 0) {
          _this6.$set(_this6.chargeErrors, index, _objectSpread(_objectSpread({}, _this6.chargeErrors[index]), {}, {
            amount: 'Amount must be greater than 0'
          }));
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
    loadTabsFromStorage: function loadTabsFromStorage() {
      var savedTabs = localStorage.getItem('pos_tabs');
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
    saveTabsToStorage: function saveTabsToStorage() {
      localStorage.setItem('pos_tabs', JSON.stringify(this.tabs));
    },
    clearTabs: function clearTabs() {
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
    changePerPage: function changePerPage() {
      this.currentPage = 1;
      this.getProducts();
    },
    closeRegisterModal: function closeRegisterModal() {
      if (this.registerUserModal) {
        this.registerUserModal.hide();
      }
    },
    addSelectedVariantToCart: function addSelectedVariantToCart(product) {
      // Check if product is out of stock before proceeding
      if (this.isProductOutOfStock(product)) {
        toastr.error(this.__('out_of_stock'));
        return;
      }
      var variant = this.getSelectedVariant(product);
      if (variant) {
        this.addVariantToCart(product, variant);
      } else {
        toastr.error(this.__('please_select_variant'));
      }
    },
    getSelectedVariant: function getSelectedVariant(product) {
      if (!product.variants || product.variants.length === 0) {
        return null;
      }
      if (product.selectedVariantId) {
        return product.variants.find(function (v) {
          return v.id === product.selectedVariantId;
        });
      }
      return product.variants[0];
    },
    // Check if product is out of stock
    isProductOutOfStock: function isProductOutOfStock(product) {
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
        var variant = product.variants[0];
        return variant.stock <= 0 || variant.status === 0;
      }

      // For multiple variant products, check the selected variant
      var selectedVariant = this.getSelectedVariant(product);
      if (!selectedVariant) {
        return true;
      }
      return selectedVariant.stock <= 0 || selectedVariant.status === 0;
    },
    addVariantToCart: function addVariantToCart(product, variant) {
      if (this.isProductOutOfStock(product)) {
        toastr.error(this.__('out_of_stock'));
        return;
      }
      var price = variant.discounted_price > 0 ? variant.discounted_price : variant.price;
      var cartItem = {
        product_id: product.id,
        product_variant_id: variant.id,
        name: product.name,
        variant_name: "".concat(variant.measurement, " ").concat(variant.measurement_unit_name),
        price: price,
        quantity: 1,
        image: product.image_url,
        variant: variant,
        // Store the full variant object for reference
        is_unlimited_stock: product.is_unlimited_stock // Store product's unlimited stock flag
      };

      // Check if item is already in cart
      var existingIndex = this.cart.findIndex(function (item) {
        return item.product_id === cartItem.product_id && item.product_variant_id === cartItem.product_variant_id;
      });
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
    confirmExit: function confirmExit() {
      var _this7 = this;
      this.$swal.fire({
        title: 'Are you sure?',
        text: 'Any unsaved bills will be lost.',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonText: 'Yes, exit',
        cancelButtonText: 'Cancel'
      }).then(function (result) {
        if (result.isConfirmed) {
          // Reset tabs to initial state before clearing storage
          _this7.tabs = [{
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
    debounceSearch: function debounceSearch() {
      var _this8 = this;
      if (this.searchTimeout) {
        clearTimeout(this.searchTimeout);
      }
      this.searchTimeout = setTimeout(function () {
        _this8.getProducts();
      }, 500);
    },
    navigateToProduct: function navigateToProduct(productId) {
      window.location.href = "/seller/manage_products/view/".concat(productId);
    },
    addNewTab: function addNewTab() {
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
    closeTab: function closeTab(index) {
      var _this9 = this;
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
        }).then(function (result) {
          if (result.isConfirmed) {
            _this9.doCloseTab(index);
          }
        });
      } else {
        this.doCloseTab(index);
      }
    },
    doCloseTab: function doCloseTab(index) {
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
    switchTab: function switchTab(index) {
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
    clearCart: function clearCart() {
      var _this10 = this;
      // If viewing a previous order, ask for confirmation before clearing
      if (this.viewingPreviousOrder) {
        this.$swal.fire({
          title: 'Clear previous order?',
          text: 'This will clear all items from the previous order view. Are you sure?',
          icon: 'warning',
          showCancelButton: true,
          confirmButtonText: 'Yes, clear it',
          cancelButtonText: 'Cancel'
        }).then(function (result) {
          if (result.isConfirmed) {
            _this10.doCartClear();
          }
        });
      } else {
        this.doCartClear();
      }
    },
    doCartClear: function doCartClear() {
      // Check what needs to be cleared before clearing
      var hadDiscount = this.discount.amount > 0 || this.discount.percentage > 0;
      var hadCharges = this.additionalCharges.length > 0;
      var hadItems = this.cart.length > 0;
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
    doCartClearSilent: function doCartClearSilent() {
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
    placeOrderAndPrint: function placeOrderAndPrint() {
      this.placeOrder(true);
    },
    placeOrder: function placeOrder() {
      var _this11 = this;
      var print = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : false;
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
      var _iterator = _createForOfIteratorHelper(this.getActiveTab.cart),
        _step;
      try {
        var _loop = function _loop() {
          var item = _step.value;
          // Skip stock validation for unlimited stock products
          if (item.is_unlimited_stock) {
            return "continue";
          }

          // For existing items in previous orders, we need to make sure
          // we're not counting their original quantity against available stock
          var originalQuantity = 0;
          if (_this11.viewingPreviousOrder && _this11.currentViewingOrder) {
            var originalItem = _this11.currentViewingOrder.items.find(function (origItem) {
              return origItem.product_variant_id === item.product_variant_id;
            });
            if (originalItem) {
              originalQuantity = originalItem.quantity;
            }
          }

          // Check if requested quantity (minus original quantity for updates) exceeds available stock
          if (item.quantity - originalQuantity > item.variant.stock) {
            _this11.$swal.fire({
              icon: 'error',
              title: 'Not enough stock',
              text: "Not enough stock available for ".concat(item.name, ". Available: ").concat(item.variant.stock),
              showConfirmButton: true,
              confirmButtonText: 'OK'
            });
            return {
              v: void 0
            };
          }
        };
        for (_iterator.s(); !(_step = _iterator.n()).done;) {
          var _ret = _loop();
          if (_ret === "continue") continue;
          if (_typeof(_ret) === "object") return _ret.v;
        }

        // Construct order data
      } catch (err) {
        _iterator.e(err);
      } finally {
        _iterator.f();
      }
      var orderData = {
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
      var actionText = this.viewingPreviousOrder ? 'Update' : 'Place';
      this.$swal.fire({
        title: "Confirm order ".concat(actionText),
        text: "Are you sure you want to ".concat(actionText, " the order?"),
        icon: 'question',
        showCancelButton: true,
        confirmButtonColor: '#3085d6',
        cancelButtonColor: '#d33',
        confirmButtonText: "Yes, ".concat(actionText, " it"),
        cancelButtonText: 'Cancel'
      }).then(function (result) {
        if (result.isConfirmed) {
          // Show loading
          _this11.$swal.fire({
            title: 'Processing',
            text: "Processing order ".concat(actionText, "..."),
            allowOutsideClick: false,
            allowEscapeKey: false,
            didOpen: function didOpen() {
              _this11.$swal.showLoading();
            }
          });

          // Determine which API endpoint to use based on whether we're updating or creating
          var apiEndpoint = _this11.viewingPreviousOrder ? '/api/seller/pos/update_order' : '/api/seller/pos/place_order';

          // Send order to API
          axios.post(apiEndpoint, orderData).then(function (response) {
            if (response.data.status) {
              var orderId = response.data.data.pos_order_id;

              // Only show print dialog if print parameter is true
              if (print) {
                // Try to print via iframe first
                _this11.printInvoice(orderId);

                // Show a notification with a link to open the invoice directly if needed
                _this11.$swal.fire({
                  position: 'top-end',
                  icon: 'info',
                  title: 'Invoice Printing',
                  html: 'If the print dialog doesn\'t appear, <a href="/pos/invoice/' + orderId + '" target="_blank">click here to open the invoice</a>',
                  showConfirmButton: false,
                  timer: 5000,
                  timerProgressBar: true
                });
              }
              if (!_this11.viewingPreviousOrder) {
                // Save the order to local storage for previous bills feature
                _this11.saveOrderToHistory(orderId, orderData);

                // Remove current tab instead of just clearing it
                if (_this11.tabs.length > 1) {
                  // If there are multiple tabs, remove the current one
                  _this11.doCloseTab(_this11.activeTabIndex);
                } else {
                  _this11.doCartClearSilent();
                }
                _this11.saveTabsToStorage();
              } else {
                // Update the order in localStorage
                _this11.updateOrderInHistory(orderData);

                // After updating, exit the previous bill view
                _this11.exitPreviousBillView();
              }
              _this11.$swal.fire({
                icon: 'success',
                title: "Order ".concat(actionText, "d"),
                text: "Order ".concat(actionText, "d successfully"),
                showConfirmButton: true,
                confirmButtonText: 'OK'
              });
            } else {
              _this11.$swal.fire({
                icon: 'error',
                title: 'Error',
                text: response.data.message || "Error ".concat(actionText, "ing order"),
                showConfirmButton: true,
                confirmButtonText: 'OK'
              });
            }
          })["catch"](function (error) {
            var errorMessage = "Error ".concat(actionText, "ing order");
            if (error.response && error.response.data && error.response.data.message) {
              errorMessage = error.response.data.message;
            }
            _this11.$swal.fire({
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
    closeProductDetailsModal: function closeProductDetailsModal() {
      if (this.productDetailsModal) {
        this.productDetailsModal.hide();
      }
    },
    saveOrderToHistory: function saveOrderToHistory(orderId, orderData) {
      // Create a complete order record
      var order = {
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
      var previousOrders = localStorage.getItem('pos_previous_orders');
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
    loadPreviousOrders: function loadPreviousOrders() {
      var previousOrders = localStorage.getItem('pos_previous_orders');
      if (previousOrders) {
        this.previousOrders = JSON.parse(previousOrders);
      } else {
        this.previousOrders = [];
      }
    },
    togglePreviousBill: function togglePreviousBill() {
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
    loadPreviousOrder: function loadPreviousOrder(order) {
      // Mark that we're viewing a previous order
      this.viewingPreviousOrder = true;
      this.currentViewingOrder = order;
      this.previousOrderData = {
        cart: _toConsumableArray(order.items),
        selectedUser: order.user,
        discount: _objectSpread({}, order.discount),
        additionalCharges: _toConsumableArray(order.additionalCharges),
        paymentMethod: order.paymentMethod
      };
      toastr.success('Previous bill loaded - Make changes if needed and click Place Order to update');
    },
    updateOrderInHistory: function updateOrderInHistory(updateData) {
      // Find the order in previousOrders and update it
      var orderIndex = this.previousOrders.findIndex(function (order) {
        return order.id === updateData.order_id;
      });
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
    exitPreviousBillView: function exitPreviousBillView() {
      this.viewingPreviousOrder = false;
      toastr.info('Returned to regular mode');
    },
    formatDate: function formatDate(dateString) {
      if (!dateString) return '';
      var date = new Date(dateString);
      return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], {
        hour: '2-digit',
        minute: '2-digit'
      });
    },
    printInvoice: function printInvoice(orderId) {
      var baseUrl = window.location.origin;
      var invoiceUrl = "".concat(baseUrl, "/pos/invoice/").concat(orderId);
      var printOperation = new Promise(function (resolve, reject) {
        var printFrame = null;
        var cleanupTimeout = null;
        var cleanup = function cleanup() {
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
          printFrame.onload = function () {
            try {
              var contentWindow = printFrame.contentWindow;
              if (!contentWindow || !contentWindow.document || !contentWindow.document.body) {
                throw new Error('Cannot access iframe content');
              }
              setTimeout(function () {
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
          printFrame.onerror = function () {
            reject(new Error('Failed to load invoice in iframe'));
          };
          document.body.appendChild(printFrame);
          printFrame.src = invoiceUrl;
        } catch (error) {
          cleanup();
          reject(error);
        }
      });
      printOperation["catch"](function (error) {
        console.error('Print failed:', error);
        window.open(invoiceUrl, '_blank');
      });
    },
    searchCustomers: function searchCustomers() {
      var _this12 = this;
      clearTimeout(this.searchTimeout);
      this.showCustomerResults = true;
      if (!this.customerSearchTerm || this.customerSearchTerm.trim().length < 2) {
        this.filteredUsers = [];
        return;
      }
      this.searchTimeout = setTimeout(function () {
        axios.get('/api/seller/pos/users', {
          params: {
            search: _this12.customerSearchTerm.trim()
          }
        }).then(function (response) {
          if (response.data.status) {
            _this12.filteredUsers = response.data.data;
          }
        })["catch"](function (error) {
          console.error('Error searching customers:', error);
        });
      }, 300);
    },
    selectUser: function selectUser(user) {
      this.selectedUser = user;
      this.customerSearchTerm = user.name;
      this.showCustomerResults = false;
      this.saveTabsToStorage();
    },
    selectCashSale: function selectCashSale() {
      this.selectedUser = null;
      this.customerSearchTerm = '';
      this.showCustomerResults = false;
      this.saveTabsToStorage();
    },
    fetchStoreName: function fetchStoreName() {
      var _this13 = this;
      axios.get('/api/seller/pos/store-name').then(function (response) {
        if (response.data.status) {
          _this13.storeName = response.data.data.store_name;
        }
      })["catch"](function (error) {
        console.error('Error fetching store name:', error);
      });
    },
    validateDiscountInput: function validateDiscountInput(type, event) {
      var value = event.target.value;
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
    }
  }
});

/***/ }),

/***/ "./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Sellers/PointOfSale.vue?vue&type=style&index=0&id=3a395e78&lang=css":
/*!****************************************************************************************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Sellers/PointOfSale.vue?vue&type=style&index=0&id=3a395e78&lang=css ***!
  \****************************************************************************************************************************************************************************************************************************************************************************************************************************************************/
/***/ ((module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ../../../../node_modules/css-loader/dist/runtime/api.js */ "./node_modules/css-loader/dist/runtime/api.js");
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_0__);
// Imports

var ___CSS_LOADER_EXPORT___ = _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_0___default()(function(i){return i[1]});
// Module
___CSS_LOADER_EXPORT___.push([module.id, "\n.sidebar-wrapper{\n   display: none !important;\n}\nheader{\n   display: none !important;\n}\n#main{\n   padding: 0px 10px 10px 10px !important;\n   margin: 0px !important;\n}\n", ""]);
// Exports
/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (___CSS_LOADER_EXPORT___);


/***/ }),

/***/ "./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Sellers/PointOfSale.vue?vue&type=style&index=1&id=3a395e78&scoped=true&lang=css":
/*!****************************************************************************************************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Sellers/PointOfSale.vue?vue&type=style&index=1&id=3a395e78&scoped=true&lang=css ***!
  \****************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/
/***/ ((module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ../../../../node_modules/css-loader/dist/runtime/api.js */ "./node_modules/css-loader/dist/runtime/api.js");
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_0__);
// Imports

var ___CSS_LOADER_EXPORT___ = _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_0___default()(function(i){return i[1]});
// Module
___CSS_LOADER_EXPORT___.push([module.id, "\n.product-card[data-v-3a395e78] {\r\n    border: 1px solid #e9ecef;\r\n    border-radius: 8px;\r\n    overflow: hidden;\r\n    transition: all 0.3s ease;\r\n    cursor: pointer;\r\n    height: 100%;\r\n    box-shadow: 0 2px 5px rgba(0, 0, 0, 0.05);\n}\n.product-card[data-v-3a395e78]:hover {\r\n    transform: translateY(-5px);\r\n    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);\n}\n.product-image[data-v-3a395e78] {\r\n    height: 160px;\r\n    display: flex;\r\n    align-items: center;\r\n    justify-content: center;\r\n    overflow: hidden;\r\n    background-color: #f8f9fa;\r\n    padding: 10px;\n}\n.product-image img[data-v-3a395e78] {\r\n    max-height: 140px;\r\n    max-width: 100%;\r\n    -o-object-fit: contain;\r\n       object-fit: contain;\r\n    display: block;\r\n    margin: 0 auto;\n}\n.product-info[data-v-3a395e78] {\r\n    padding: 12px;\n}\n.product-name-measure-row[data-v-3a395e78] {\r\n    flex-wrap: nowrap;\n}\n.product-title[data-v-3a395e78] {\r\n    font-size: 16px;\r\n    overflow: hidden;\r\n    display: -webkit-box;\r\n    -webkit-line-clamp: 2;\r\n    -webkit-box-orient: vertical;\r\n    min-width: 0;\n}\n.single-variant[data-v-3a395e78] {\r\n    font-size: 0.75rem;\r\n    color: #6c757d;\r\n    white-space: nowrap;\r\n    flex-shrink: 0;\n}\n.variant-info[data-v-3a395e78] {\r\n    font-weight: 600;\n}\n.form-select-sm[data-v-3a395e78] {\r\n    font-size: 0.8rem;\r\n    padding: 0.25rem 0.5rem;\r\n    height: 30px;\n}\n.mini-select[data-v-3a395e78] {\r\n    font-size: 0.75rem;\r\n    padding: 0.2rem 0.4rem;\r\n    height: 25px;\n}\n.short-select[data-v-3a395e78] {\r\n    width: auto;\r\n    min-width: 80px;\r\n    max-width: 120px;\n}\n.btn-xs[data-v-3a395e78] {\r\n    padding: 0.2rem 0.5rem;\r\n    font-size: 0.8rem;\r\n    line-height: 1.2;\r\n    margin-top: 5px;\n}\n.no-variants[data-v-3a395e78] {\r\n    padding: 8px 0;\r\n    text-align: center;\r\n    font-size: 12px;\n}\n.product-price[data-v-3a395e78] {\r\n    font-weight: bold;\r\n    color: #435ebe;\r\n    margin-bottom: 5px;\n}\n.original-price[data-v-3a395e78] {\r\n    text-decoration: line-through;\r\n    color: #6c757d;\r\n    font-size: 11px;\r\n    font-weight: normal;\r\n    margin-left: 4px;\n}\n.add-btn[data-v-3a395e78] {\r\n    padding: 2px 6px;\r\n    font-size: 12px;\n}\n.product-price .discounted[data-v-3a395e78] {\r\n    color: #dc3545;\n}\n.product-price .original-price[data-v-3a395e78] {\r\n    text-decoration: line-through;\r\n    color: #6c757d;\r\n    font-size: 12px;\r\n    margin-left: 5px;\n}\n.cart-items[data-v-3a395e78] {\r\n    max-height: 400px;\r\n    overflow-y: auto;\n}\n.cart-item[data-v-3a395e78] {\r\n    display: flex;\r\n    flex-wrap: wrap;\r\n    align-items: center;\r\n    padding: 10px 0;\r\n    border-bottom: 1px solid #e9ecef;\r\n    position: relative;\n}\n.item-image[data-v-3a395e78] {\r\n    width: 60px;\r\n    height: 60px;\r\n    overflow: hidden;\r\n    border-radius: 4px;\r\n    margin-right: 10px;\r\n    border: 1px solid #e9ecef;\n}\n.item-image img[data-v-3a395e78] {\r\n    width: 100%;\r\n    height: 100%;\r\n    -o-object-fit: cover;\r\n       object-fit: cover;\n}\n.item-details[data-v-3a395e78] {\r\n    flex: 1;\r\n    min-width: 150px;\r\n    padding-right: 10px;\n}\n.item-details h5[data-v-3a395e78] {\r\n    font-size: 14px;\r\n    margin-bottom: 3px;\r\n    font-weight: 600;\n}\n.item-details p.variant-info[data-v-3a395e78] {\r\n    font-size: 12px;\r\n    color: #6c757d;\r\n    margin-bottom: 5px;\r\n    font-weight: 600;\n}\n.item-details .price[data-v-3a395e78] {\r\n    font-weight: bold;\r\n    color: #435ebe;\r\n    font-size: 13px;\n}\n.item-quantity[data-v-3a395e78] {\r\n    width: 120px;\r\n    margin: 10px 0;\n}\n.item-quantity .form-control[data-v-3a395e78] {\r\n    padding: 0.25rem 0.5rem;\r\n    text-align: center;\n}\n.item-quantity .input-group[data-v-3a395e78] {\r\n    flex-wrap: nowrap;\n}\n.item-total[data-v-3a395e78] {\r\n    width: 80px;\r\n    text-align: right;\r\n    font-weight: bold;\r\n    margin-right: 10px;\n}\n.item-actions[data-v-3a395e78] {\r\n    margin-left: auto;\n}\n@media (min-width: 768px) {\n.cart-item[data-v-3a395e78] {\r\n        flex-wrap: nowrap;\n}\n.item-quantity[data-v-3a395e78] {\r\n        margin: 0 10px;\n}\n}\n@media (max-width: 767.98px) {\n.cart-item[data-v-3a395e78] {\r\n        padding: 15px 0;\n}\n.item-details[data-v-3a395e78] {\r\n        width: calc(100% - 70px);\n}\n.item-quantity[data-v-3a395e78] {\r\n        width: 60%;\n}\n.item-total[data-v-3a395e78] {\r\n        width: 30%;\r\n        margin-left: auto;\n}\n.item-actions[data-v-3a395e78] {\r\n        position: absolute;\r\n        top: 10px;\r\n        right: 0;\n}\n}\n.item-quantity .form-control[data-v-3a395e78]::-webkit-outer-spin-button,\r\n.item-quantity .form-control[data-v-3a395e78]::-webkit-inner-spin-button {\r\n    -webkit-appearance: none;\r\n    margin: 0;\n}\n.item-quantity .form-control[type=number][data-v-3a395e78] {\r\n    -moz-appearance: textfield;\n}\n.fullscreen-header[data-v-3a395e78] {\r\n    background: #e2e3e7;\r\n    color: white;\r\n    margin-bottom: 15px;\n}\n.fullscreen-header h5[data-v-3a395e78] {\r\n    margin-bottom: 0;\n}\n.pos-tabs-container[data-v-3a395e78] {\r\n    background: #fff;\r\n    padding: 10px;\r\n    border-radius: 4px;\r\n    box-shadow: 0 2px 5px rgba(0, 0, 0, 0.05);\n}\n.pos-tabs-wrapper[data-v-3a395e78] {\r\n    display: flex;\r\n    width: 100%;\r\n    gap: 8px;\n}\n.pos-tab[data-v-3a395e78] {\r\n    width: 19%;\r\n    flex: 0 0 auto;\r\n    padding: 10px 15px;\r\n    background-color: #f8f9fa;\r\n    border: 1px solid #dee2e6;\r\n    border-radius: 8px;\r\n    cursor: pointer;\r\n    display: flex;\r\n    justify-content: space-between;\r\n    align-items: center;\r\n    transition: all 0.2s;\n}\n.pos-tab[data-v-3a395e78]:hover {\r\n    background-color: #e9ecef;\n}\n.pos-tab.active[data-v-3a395e78] {\r\n    background-color: #9AC444;\r\n    color: white;\r\n    border-color: #9AC444;\n}\n.pos-tab-close[data-v-3a395e78] {\r\n    font-size: 18px;\r\n    margin-left: 8px;\r\n    cursor: pointer;\n}\n.pos-tab-close[data-v-3a395e78]:hover {\r\n    color: #dc3545;\n}\n.previous-bill-tab[data-v-3a395e78] {\r\n    background-color: #007bff !important;\r\n    color: white !important;\r\n    border-color: #007bff !important;\r\n    position: relative;\n}\n.previous-bill-tab[data-v-3a395e78]::after {\r\n    content: \"Editing\";\r\n    position: absolute;\r\n    top: -8px;\r\n    right: 5px;\r\n    background-color: #dc3545;\r\n    color: white;\r\n    font-size: 10px;\r\n    padding: 2px 5px;\r\n    border-radius: 3px;\r\n    font-weight: bold;\n}\n.disabled-tab[data-v-3a395e78] {\r\n    opacity: 0.6;\r\n    cursor: not-allowed;\r\n    background-color: #f0f0f0 !important;\n}\n.disabled-tab[data-v-3a395e78]:hover {\r\n    background-color: #f0f0f0 !important;\n}\n.previous-bill-badge[data-v-3a395e78] {\r\n    animation: pulse-data-v-3a395e78 2s infinite;\n}\n@keyframes pulse-data-v-3a395e78 {\n0% {\r\n        transform: scale(1);\r\n        opacity: 1;\n}\n50% {\r\n        transform: scale(1.05);\r\n        opacity: 0.8;\n}\n100% {\r\n        transform: scale(1);\r\n        opacity: 1;\n}\n}\n.previous-bill-indicator[data-v-3a395e78] {\r\n    border-left: 4px solid #0d6efd;\n}\n.badge[data-v-3a395e78] {\r\n    font-size: 85%;\n}\n.search-select[data-v-3a395e78] {\r\n    position: relative;\r\n    width: 100%;\n}\n.search-results[data-v-3a395e78] {\r\n    position: absolute;\r\n    top: 100%;\r\n    left: 0;\r\n    right: 0;\r\n    background: white;\r\n    border: 1px solid #ddd;\r\n    border-radius: 0 0 4px 4px;\r\n    max-height: 200px;\r\n    overflow-y: auto;\r\n    z-index: 1000;\r\n    box-shadow: 0 4px 8px rgba(0,0,0,0.1);\n}\n.search-option[data-v-3a395e78] {\r\n    padding: 8px 12px;\r\n    cursor: pointer;\r\n    border-bottom: 1px solid #f0f0f0;\n}\n.search-option[data-v-3a395e78]:hover {\r\n    background-color: #f5f5f5;\n}\n.search-option[data-v-3a395e78]:last-child {\r\n    border-bottom: none;\n}\n.out-of-stock[data-v-3a395e78] {\r\n    display: flex;\r\n    align-items: center;\r\n    justify-content: center;\r\n    min-height: 32px;\n}\n.out-of-stock .badge[data-v-3a395e78] {\r\n    font-size: 0.75rem;\r\n    padding: 0.4rem 0.6rem;\r\n    font-weight: 600;\r\n    background-color: #dc3545 !important;\r\n    color: white;\r\n    border-radius: 4px;\n}\r\n", ""]);
// Exports
/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (___CSS_LOADER_EXPORT___);


/***/ }),

/***/ "./node_modules/style-loader/dist/cjs.js!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Sellers/PointOfSale.vue?vue&type=style&index=0&id=3a395e78&lang=css":
/*!********************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/style-loader/dist/cjs.js!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Sellers/PointOfSale.vue?vue&type=style&index=0&id=3a395e78&lang=css ***!
  \********************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! !../../../../node_modules/style-loader/dist/runtime/injectStylesIntoStyleTag.js */ "./node_modules/style-loader/dist/runtime/injectStylesIntoStyleTag.js");
/* harmony import */ var _node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_PointOfSale_vue_vue_type_style_index_0_id_3a395e78_lang_css__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! !!../../../../node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!../../../../node_modules/vue-loader/lib/loaders/stylePostLoader.js!../../../../node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./PointOfSale.vue?vue&type=style&index=0&id=3a395e78&lang=css */ "./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Sellers/PointOfSale.vue?vue&type=style&index=0&id=3a395e78&lang=css");

            

var options = {};

options.insert = "head";
options.singleton = false;

var update = _node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0___default()(_node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_PointOfSale_vue_vue_type_style_index_0_id_3a395e78_lang_css__WEBPACK_IMPORTED_MODULE_1__["default"], options);



/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (_node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_PointOfSale_vue_vue_type_style_index_0_id_3a395e78_lang_css__WEBPACK_IMPORTED_MODULE_1__["default"].locals || {});

/***/ }),

/***/ "./node_modules/style-loader/dist/cjs.js!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Sellers/PointOfSale.vue?vue&type=style&index=1&id=3a395e78&scoped=true&lang=css":
/*!********************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/style-loader/dist/cjs.js!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Sellers/PointOfSale.vue?vue&type=style&index=1&id=3a395e78&scoped=true&lang=css ***!
  \********************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! !../../../../node_modules/style-loader/dist/runtime/injectStylesIntoStyleTag.js */ "./node_modules/style-loader/dist/runtime/injectStylesIntoStyleTag.js");
/* harmony import */ var _node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_PointOfSale_vue_vue_type_style_index_1_id_3a395e78_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! !!../../../../node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!../../../../node_modules/vue-loader/lib/loaders/stylePostLoader.js!../../../../node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./PointOfSale.vue?vue&type=style&index=1&id=3a395e78&scoped=true&lang=css */ "./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Sellers/PointOfSale.vue?vue&type=style&index=1&id=3a395e78&scoped=true&lang=css");

            

var options = {};

options.insert = "head";
options.singleton = false;

var update = _node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0___default()(_node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_PointOfSale_vue_vue_type_style_index_1_id_3a395e78_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_1__["default"], options);



/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (_node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_PointOfSale_vue_vue_type_style_index_1_id_3a395e78_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_1__["default"].locals || {});

/***/ }),

/***/ "./resources/js/views/Sellers/PointOfSale.vue":
/*!****************************************************!*\
  !*** ./resources/js/views/Sellers/PointOfSale.vue ***!
  \****************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _PointOfSale_vue_vue_type_template_id_3a395e78_scoped_true__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./PointOfSale.vue?vue&type=template&id=3a395e78&scoped=true */ "./resources/js/views/Sellers/PointOfSale.vue?vue&type=template&id=3a395e78&scoped=true");
/* harmony import */ var _PointOfSale_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./PointOfSale.vue?vue&type=script&lang=js */ "./resources/js/views/Sellers/PointOfSale.vue?vue&type=script&lang=js");
/* harmony import */ var _PointOfSale_vue_vue_type_style_index_0_id_3a395e78_lang_css__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ./PointOfSale.vue?vue&type=style&index=0&id=3a395e78&lang=css */ "./resources/js/views/Sellers/PointOfSale.vue?vue&type=style&index=0&id=3a395e78&lang=css");
/* harmony import */ var _PointOfSale_vue_vue_type_style_index_1_id_3a395e78_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! ./PointOfSale.vue?vue&type=style&index=1&id=3a395e78&scoped=true&lang=css */ "./resources/js/views/Sellers/PointOfSale.vue?vue&type=style&index=1&id=3a395e78&scoped=true&lang=css");
/* harmony import */ var _node_modules_vue_loader_lib_runtime_componentNormalizer_js__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__(/*! !../../../../node_modules/vue-loader/lib/runtime/componentNormalizer.js */ "./node_modules/vue-loader/lib/runtime/componentNormalizer.js");



;



/* normalize component */

var component = (0,_node_modules_vue_loader_lib_runtime_componentNormalizer_js__WEBPACK_IMPORTED_MODULE_4__["default"])(
  _PointOfSale_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"],
  _PointOfSale_vue_vue_type_template_id_3a395e78_scoped_true__WEBPACK_IMPORTED_MODULE_0__.render,
  _PointOfSale_vue_vue_type_template_id_3a395e78_scoped_true__WEBPACK_IMPORTED_MODULE_0__.staticRenderFns,
  false,
  null,
  "3a395e78",
  null
  
)

/* hot reload */
if (false) { var api; }
component.options.__file = "resources/js/views/Sellers/PointOfSale.vue"
/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (component.exports);

/***/ }),

/***/ "./resources/js/views/Sellers/PointOfSale.vue?vue&type=script&lang=js":
/*!****************************************************************************!*\
  !*** ./resources/js/views/Sellers/PointOfSale.vue?vue&type=script&lang=js ***!
  \****************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_5_use_0_node_modules_vue_loader_lib_index_js_vue_loader_options_PointOfSale_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./PointOfSale.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Sellers/PointOfSale.vue?vue&type=script&lang=js");
 /* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (_node_modules_babel_loader_lib_index_js_clonedRuleSet_5_use_0_node_modules_vue_loader_lib_index_js_vue_loader_options_PointOfSale_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]); 

/***/ }),

/***/ "./resources/js/views/Sellers/PointOfSale.vue?vue&type=style&index=0&id=3a395e78&lang=css":
/*!************************************************************************************************!*\
  !*** ./resources/js/views/Sellers/PointOfSale.vue?vue&type=style&index=0&id=3a395e78&lang=css ***!
  \************************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _node_modules_style_loader_dist_cjs_js_node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_PointOfSale_vue_vue_type_style_index_0_id_3a395e78_lang_css__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/style-loader/dist/cjs.js!../../../../node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!../../../../node_modules/vue-loader/lib/loaders/stylePostLoader.js!../../../../node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./PointOfSale.vue?vue&type=style&index=0&id=3a395e78&lang=css */ "./node_modules/style-loader/dist/cjs.js!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Sellers/PointOfSale.vue?vue&type=style&index=0&id=3a395e78&lang=css");


/***/ }),

/***/ "./resources/js/views/Sellers/PointOfSale.vue?vue&type=style&index=1&id=3a395e78&scoped=true&lang=css":
/*!************************************************************************************************************!*\
  !*** ./resources/js/views/Sellers/PointOfSale.vue?vue&type=style&index=1&id=3a395e78&scoped=true&lang=css ***!
  \************************************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _node_modules_style_loader_dist_cjs_js_node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_PointOfSale_vue_vue_type_style_index_1_id_3a395e78_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/style-loader/dist/cjs.js!../../../../node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!../../../../node_modules/vue-loader/lib/loaders/stylePostLoader.js!../../../../node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./PointOfSale.vue?vue&type=style&index=1&id=3a395e78&scoped=true&lang=css */ "./node_modules/style-loader/dist/cjs.js!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Sellers/PointOfSale.vue?vue&type=style&index=1&id=3a395e78&scoped=true&lang=css");


/***/ }),

/***/ "./resources/js/views/Sellers/PointOfSale.vue?vue&type=template&id=3a395e78&scoped=true":
/*!**********************************************************************************************!*\
  !*** ./resources/js/views/Sellers/PointOfSale.vue?vue&type=template&id=3a395e78&scoped=true ***!
  \**********************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: () => (/* reexport safe */ _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_PointOfSale_vue_vue_type_template_id_3a395e78_scoped_true__WEBPACK_IMPORTED_MODULE_0__.render),
/* harmony export */   staticRenderFns: () => (/* reexport safe */ _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_PointOfSale_vue_vue_type_template_id_3a395e78_scoped_true__WEBPACK_IMPORTED_MODULE_0__.staticRenderFns)
/* harmony export */ });
/* harmony import */ var _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_PointOfSale_vue_vue_type_template_id_3a395e78_scoped_true__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./PointOfSale.vue?vue&type=template&id=3a395e78&scoped=true */ "./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Sellers/PointOfSale.vue?vue&type=template&id=3a395e78&scoped=true");


/***/ }),

/***/ "./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Sellers/PointOfSale.vue?vue&type=template&id=3a395e78&scoped=true":
/*!*************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Sellers/PointOfSale.vue?vue&type=template&id=3a395e78&scoped=true ***!
  \*************************************************************************************************************************************************************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: () => (/* binding */ render),
/* harmony export */   staticRenderFns: () => (/* binding */ staticRenderFns)
/* harmony export */ });
var render = function () {
  var _vm = this
  var _h = _vm.$createElement
  var _c = _vm._self._c || _h
  return _c("div", { class: { "fullscreen-pos": _vm.isFullscreenMode } }, [
    _vm.isFullscreenMode
      ? _c("div", { staticClass: "fullscreen-header" }, [
          _c("div", { staticClass: "container-fluid" }, [
            _c("div", { staticClass: "row" }, [
              _c("div", { staticClass: "col-md-12" }, [
                _c(
                  "div",
                  {
                    staticClass:
                      "d-flex align-items-center justify-content-between",
                  },
                  [
                    _c(
                      "button",
                      {
                        staticClass: "btn btn-primary me-3 mt-1",
                        on: { click: _vm.confirmExit },
                      },
                      [
                        _c("i", { staticClass: "fas fa-arrow-left" }),
                        _vm._v(" Exit POS\n                        "),
                      ]
                    ),
                    _vm._v(" "),
                    _c("h5", [_vm._v("POS Billing")]),
                    _vm._v(" "),
                    _c("h5", [_vm._v(_vm._s(_vm.storeName))]),
                  ]
                ),
              ]),
            ]),
          ]),
        ])
      : _vm._e(),
    _vm._v(" "),
    _vm.isFullscreenMode
      ? _c("div", { staticClass: "pos-tabs-container mb-3" }, [
          _c("div", { staticClass: "container-fluid" }, [
            _c("div", { staticClass: "row" }, [
              _c("div", { staticClass: "col-lg-8" }, [
                _c("div", { staticClass: "d-flex align-items-center" }, [
                  _c("div", { staticClass: "w-100" }, [
                    _c(
                      "div",
                      { staticClass: "pos-tabs-wrapper d-flex" },
                      [
                        _vm._l(_vm.tabs, function (tab, index) {
                          return _c(
                            "button",
                            {
                              key: index,
                              staticClass: "pos-tab",
                              class: {
                                active:
                                  _vm.activeTabIndex === index &&
                                  !_vm.viewingPreviousOrder,
                              },
                              on: {
                                click: function ($event) {
                                  return _vm.switchTab(index)
                                },
                              },
                            },
                            [
                              _c("span", [_vm._v("Bill " + _vm._s(index + 1))]),
                              _vm._v(" "),
                              _vm.tabs.length > 1
                                ? _c(
                                    "span",
                                    {
                                      staticClass: "pos-tab-close",
                                      on: {
                                        click: function ($event) {
                                          $event.stopPropagation()
                                          return _vm.closeTab(index)
                                        },
                                      },
                                    },
                                    [_vm._v("×")]
                                  )
                                : _vm._e(),
                            ]
                          )
                        }),
                        _vm._v(" "),
                        _vm.tabs.length < 5
                          ? _c(
                              "button",
                              {
                                staticClass:
                                  "btn btn-sm btn-outline-primary ms-2",
                                on: { click: _vm.addNewTab },
                              },
                              [
                                _c("i", { staticClass: "fas fa-plus" }),
                                _vm._v(
                                  "Hold Bill & Create Another\n                                "
                                ),
                              ]
                            )
                          : _vm._e(),
                      ],
                      2
                    ),
                  ]),
                ]),
              ]),
              _vm._v(" "),
              _c(
                "div",
                {
                  staticClass:
                    "col-lg-4 d-flex justify-content-end align-items-center",
                },
                [
                  _vm.previousOrders.length > 0
                    ? _c(
                        "button",
                        {
                          staticClass: "btn",
                          class: {
                            "btn-primary": _vm.viewingPreviousOrder,
                            "btn-outline-primary": !_vm.viewingPreviousOrder,
                          },
                          on: { click: _vm.togglePreviousBill },
                        },
                        [
                          _c("i", { staticClass: "fas fa-receipt" }),
                          _vm._v(" Previous Bill\n                    "),
                        ]
                      )
                    : _vm._e(),
                ]
              ),
            ]),
          ]),
        ])
      : _vm._e(),
    _vm._v(" "),
    !_vm.isFullscreenMode
      ? _c("div", { staticClass: "page-heading" }, [
          _c("div", { staticClass: "page-title" }, [
            _c("div", { staticClass: "row" }, [
              _c(
                "div",
                { staticClass: "col-12 col-md-6 order-md-1 order-last" },
                [_c("h3", [_vm._v(_vm._s(_vm.__("point_of_sale")))])]
              ),
              _vm._v(" "),
              _c(
                "div",
                { staticClass: "col-12 col-md-6 order-md-2 order-first" },
                [
                  _c(
                    "nav",
                    {
                      staticClass: "breadcrumb-header float-start float-lg-end",
                      attrs: { "aria-label": "breadcrumb" },
                    },
                    [
                      _c("ol", { staticClass: "breadcrumb" }, [
                        _c(
                          "li",
                          { staticClass: "breadcrumb-item" },
                          [
                            _c(
                              "router-link",
                              { attrs: { to: "/seller/dashboard" } },
                              [_vm._v(_vm._s(_vm.__("dashboard")))]
                            ),
                          ],
                          1
                        ),
                        _vm._v(" "),
                        _c(
                          "li",
                          {
                            staticClass: "breadcrumb-item active",
                            attrs: { "aria-current": "page" },
                          },
                          [_vm._v(_vm._s(_vm.__("point_of_sale")))]
                        ),
                      ]),
                    ]
                  ),
                ]
              ),
            ]),
          ]),
        ])
      : _vm._e(),
    _vm._v(" "),
    _c("div", { staticClass: "row" }, [
      _c("div", { staticClass: "col-lg-8 col-12" }, [
        _c("div", { staticClass: "card" }, [
          _c(
            "div",
            { staticClass: "card-header d-flex justify-content-between" },
            [
              _c("h4", [_vm._v(_vm._s(_vm.__("products")))]),
              _vm._v(" "),
              _c("div", { staticClass: "d-flex" }, [
                _c("div", { staticClass: "me-2" }, [
                  _c(
                    "select",
                    {
                      directives: [
                        {
                          name: "model",
                          rawName: "v-model",
                          value: _vm.selectedCategory,
                          expression: "selectedCategory",
                        },
                      ],
                      staticClass: "form-select",
                      staticStyle: { "min-width": "200px" },
                      on: {
                        change: [
                          function ($event) {
                            var $$selectedVal = Array.prototype.filter
                              .call($event.target.options, function (o) {
                                return o.selected
                              })
                              .map(function (o) {
                                var val = "_value" in o ? o._value : o.value
                                return val
                              })
                            _vm.selectedCategory = $event.target.multiple
                              ? $$selectedVal
                              : $$selectedVal[0]
                          },
                          _vm.getProducts,
                        ],
                      },
                    },
                    [
                      _c("option", { attrs: { value: "" } }, [
                        _vm._v(_vm._s(_vm.__("all_categories"))),
                      ]),
                      _vm._v(" "),
                      _vm._l(_vm.categories, function (category) {
                        return _c(
                          "option",
                          {
                            key: category.id,
                            domProps: { value: category.id },
                          },
                          [
                            _vm._v(
                              "\n                                    " +
                                _vm._s(category.name) +
                                "\n                                "
                            ),
                          ]
                        )
                      }),
                    ],
                    2
                  ),
                ]),
                _vm._v(" "),
                _c("div", { staticClass: "input-group" }, [
                  _c("input", {
                    directives: [
                      {
                        name: "model",
                        rawName: "v-model",
                        value: _vm.searchTerm,
                        expression: "searchTerm",
                      },
                    ],
                    staticClass: "form-control",
                    attrs: { type: "text", placeholder: "Search products" },
                    domProps: { value: _vm.searchTerm },
                    on: {
                      input: [
                        function ($event) {
                          if ($event.target.composing) {
                            return
                          }
                          _vm.searchTerm = $event.target.value
                        },
                        _vm.debounceSearch,
                      ],
                    },
                  }),
                ]),
              ]),
            ]
          ),
          _vm._v(" "),
          _c("div", { staticClass: "card-body" }, [
            _vm.loading
              ? _c("div", { staticClass: "text-center p-5" }, [_vm._m(0)])
              : _vm.products.length === 0
              ? _c("div", { staticClass: "text-center p-5" }, [
                  _c("p", { staticClass: "mb-0" }, [
                    _vm._v(_vm._s(_vm.__("no_products_found"))),
                  ]),
                ])
              : _c(
                  "div",
                  { staticClass: "row g-3" },
                  _vm._l(_vm.products, function (product) {
                    return _c(
                      "div",
                      { key: product.id, staticClass: "col-md-3 col-6" },
                      [
                        _c("div", { staticClass: "product-card" }, [
                          _c(
                            "div",
                            {
                              staticClass: "product-image",
                              on: {
                                click: function ($event) {
                                  return _vm.navigateToProduct(product.id)
                                },
                              },
                            },
                            [
                              _c("img", {
                                staticClass: "img-fluid",
                                attrs: {
                                  src: product.image_url,
                                  alt: product.name,
                                },
                              }),
                            ]
                          ),
                          _vm._v(" "),
                          _c("div", { staticClass: "product-info" }, [
                            _c(
                              "div",
                              {
                                staticClass:
                                  "product-name-measure-row d-flex align-items-baseline mb-2",
                              },
                              [
                                _c(
                                  "h5",
                                  {
                                    staticClass: "product-title mb-0",
                                    on: {
                                      click: function ($event) {
                                        return _vm.navigateToProduct(product.id)
                                      },
                                    },
                                  },
                                  [_vm._v(_vm._s(product.name))]
                                ),
                                _vm._v(" "),
                                product.variants &&
                                product.variants.length === 1
                                  ? _c(
                                      "div",
                                      { staticClass: "single-variant ms-2" },
                                      [
                                        _c(
                                          "span",
                                          { staticClass: "variant-info" },
                                          [
                                            _vm._v(
                                              _vm._s(
                                                product.variants[0].measurement
                                              ) +
                                                " " +
                                                _vm._s(
                                                  product.variants[0]
                                                    .measurement_unit_name
                                                )
                                            ),
                                          ]
                                        ),
                                      ]
                                    )
                                  : product.variants &&
                                    product.variants.length > 1
                                  ? _c("div", { staticClass: "ms-2" }, [
                                      _c(
                                        "select",
                                        {
                                          directives: [
                                            {
                                              name: "model",
                                              rawName: "v-model",
                                              value: product.selectedVariantId,
                                              expression:
                                                "product.selectedVariantId",
                                            },
                                          ],
                                          staticClass:
                                            "form-select form-select-sm mini-select short-select",
                                          on: {
                                            change: function ($event) {
                                              var $$selectedVal =
                                                Array.prototype.filter
                                                  .call(
                                                    $event.target.options,
                                                    function (o) {
                                                      return o.selected
                                                    }
                                                  )
                                                  .map(function (o) {
                                                    var val =
                                                      "_value" in o
                                                        ? o._value
                                                        : o.value
                                                    return val
                                                  })
                                              _vm.$set(
                                                product,
                                                "selectedVariantId",
                                                $event.target.multiple
                                                  ? $$selectedVal
                                                  : $$selectedVal[0]
                                              )
                                            },
                                          },
                                        },
                                        _vm._l(
                                          product.variants,
                                          function (variant) {
                                            return _c(
                                              "option",
                                              {
                                                key: variant.id,
                                                domProps: { value: variant.id },
                                              },
                                              [
                                                _vm._v(
                                                  "\n                                                    " +
                                                    _vm._s(
                                                      variant.measurement
                                                    ) +
                                                    " " +
                                                    _vm._s(
                                                      variant.measurement_unit_name
                                                    ) +
                                                    "\n                                                "
                                                ),
                                              ]
                                            )
                                          }
                                        ),
                                        0
                                      ),
                                    ])
                                  : _vm._e(),
                              ]
                            ),
                            _vm._v(" "),
                            product.variants && product.variants.length > 1
                              ? _c("div", { staticClass: "product-actions" }, [
                                  _c(
                                    "div",
                                    {
                                      staticClass:
                                        "d-flex justify-content-between align-items-center",
                                    },
                                    [
                                      _c(
                                        "div",
                                        { staticClass: "product-price mb-0" },
                                        [
                                          _vm.getSelectedVariant(product)
                                            ? [
                                                _vm.getSelectedVariant(product)
                                                  .discounted_price > 0
                                                  ? _c(
                                                      "span",
                                                      {
                                                        staticClass:
                                                          "discounted",
                                                      },
                                                      [
                                                        _vm._v(
                                                          "\n                                                        " +
                                                            _vm._s(
                                                              _vm.$currency
                                                            ) +
                                                            " " +
                                                            _vm._s(
                                                              _vm.getSelectedVariant(
                                                                product
                                                              ).discounted_price
                                                            ) +
                                                            "\n                                                        "
                                                        ),
                                                        _c(
                                                          "small",
                                                          {
                                                            staticClass:
                                                              "original-price",
                                                          },
                                                          [
                                                            _vm._v(
                                                              _vm._s(
                                                                _vm.$currency
                                                              ) +
                                                                " " +
                                                                _vm._s(
                                                                  _vm.getSelectedVariant(
                                                                    product
                                                                  ).price
                                                                )
                                                            ),
                                                          ]
                                                        ),
                                                      ]
                                                    )
                                                  : _c("span", [
                                                      _vm._v(
                                                        "\n                                                        " +
                                                          _vm._s(
                                                            _vm.$currency
                                                          ) +
                                                          " " +
                                                          _vm._s(
                                                            _vm.getSelectedVariant(
                                                              product
                                                            ).price
                                                          ) +
                                                          "\n                                                    "
                                                      ),
                                                    ]),
                                              ]
                                            : _vm._e(),
                                        ],
                                        2
                                      ),
                                      _vm._v(" "),
                                      _vm.isProductOutOfStock(product)
                                        ? _c(
                                            "div",
                                            { staticClass: "out-of-stock" },
                                            [
                                              _c(
                                                "span",
                                                {
                                                  staticClass:
                                                    "badge bg-danger",
                                                },
                                                [
                                                  _vm._v(
                                                    _vm._s(
                                                      _vm.__("out_of_stock")
                                                    )
                                                  ),
                                                ]
                                              ),
                                            ]
                                          )
                                        : _c(
                                            "button",
                                            {
                                              staticClass:
                                                "btn btn-primary btn-sm",
                                              on: {
                                                click: function ($event) {
                                                  $event.stopPropagation()
                                                  return _vm.addSelectedVariantToCart(
                                                    product
                                                  )
                                                },
                                              },
                                            },
                                            [
                                              _vm._v(
                                                "\n                                                 " +
                                                  _vm._s(
                                                    _vm.__("add_to_cart")
                                                  ) +
                                                  "\n                                            "
                                              ),
                                            ]
                                          ),
                                    ]
                                  ),
                                ])
                              : product.variants &&
                                product.variants.length === 1
                              ? _c("div", { staticClass: "product-actions" }, [
                                  _c(
                                    "div",
                                    {
                                      staticClass:
                                        "d-flex justify-content-between align-items-center",
                                    },
                                    [
                                      _c(
                                        "div",
                                        { staticClass: "product-price mb-0" },
                                        [
                                          product.variants[0].discounted_price >
                                          0
                                            ? _c(
                                                "span",
                                                { staticClass: "discounted" },
                                                [
                                                  _vm._v(
                                                    "\n                                                    " +
                                                      _vm._s(_vm.$currency) +
                                                      " " +
                                                      _vm._s(
                                                        product.variants[0]
                                                          .discounted_price
                                                      ) +
                                                      "\n                                                    "
                                                  ),
                                                  _c(
                                                    "small",
                                                    {
                                                      staticClass:
                                                        "original-price",
                                                    },
                                                    [
                                                      _vm._v(
                                                        _vm._s(_vm.$currency) +
                                                          " " +
                                                          _vm._s(
                                                            product.variants[0]
                                                              .price
                                                          )
                                                      ),
                                                    ]
                                                  ),
                                                ]
                                              )
                                            : _c("span", [
                                                _vm._v(
                                                  "\n                                                    " +
                                                    _vm._s(_vm.$currency) +
                                                    " " +
                                                    _vm._s(
                                                      product.variants[0].price
                                                    ) +
                                                    "\n                                                "
                                                ),
                                              ]),
                                        ]
                                      ),
                                      _vm._v(" "),
                                      _vm.isProductOutOfStock(product)
                                        ? _c(
                                            "div",
                                            { staticClass: "out-of-stock" },
                                            [
                                              _c(
                                                "span",
                                                {
                                                  staticClass:
                                                    "badge bg-danger",
                                                },
                                                [
                                                  _vm._v(
                                                    _vm._s(
                                                      _vm.__("out_of_stock")
                                                    )
                                                  ),
                                                ]
                                              ),
                                            ]
                                          )
                                        : _c(
                                            "button",
                                            {
                                              staticClass:
                                                "btn btn-primary btn-sm",
                                              on: {
                                                click: function ($event) {
                                                  $event.stopPropagation()
                                                  return _vm.addVariantToCart(
                                                    product,
                                                    product.variants[0]
                                                  )
                                                },
                                              },
                                            },
                                            [
                                              _vm._v(
                                                "\n                                                " +
                                                  _vm._s(
                                                    _vm.__("add_to_cart")
                                                  ) +
                                                  "\n                                            "
                                              ),
                                            ]
                                          ),
                                    ]
                                  ),
                                ])
                              : _c("div", { staticClass: "product-actions" }, [
                                  _c(
                                    "div",
                                    {
                                      staticClass:
                                        "d-flex justify-content-between align-items-center",
                                    },
                                    [
                                      _c(
                                        "div",
                                        { staticClass: "product-price mb-0" },
                                        [
                                          _c(
                                            "span",
                                            { staticClass: "text-muted" },
                                            [
                                              _vm._v(
                                                _vm._s(_vm.__("no_variants"))
                                              ),
                                            ]
                                          ),
                                        ]
                                      ),
                                      _vm._v(" "),
                                      _c(
                                        "div",
                                        { staticClass: "out-of-stock" },
                                        [
                                          _c(
                                            "span",
                                            { staticClass: "badge bg-danger" },
                                            [
                                              _vm._v(
                                                _vm._s(_vm.__("out_of_stock"))
                                              ),
                                            ]
                                          ),
                                        ]
                                      ),
                                    ]
                                  ),
                                ]),
                          ]),
                        ]),
                      ]
                    )
                  }),
                  0
                ),
            _vm._v(" "),
            _c(
              "div",
              {
                staticClass:
                  "d-flex justify-content-between align-items-center mt-4",
              },
              [
                _c("div", { staticClass: "d-flex align-items-center" }, [
                  _c("span", [_vm._v(_vm._s(_vm.__("show")))]),
                  _vm._v(" "),
                  _c(
                    "select",
                    {
                      directives: [
                        {
                          name: "model",
                          rawName: "v-model",
                          value: _vm.perPage,
                          expression: "perPage",
                        },
                      ],
                      staticClass: "form-select form-select-sm mx-2",
                      on: {
                        change: [
                          function ($event) {
                            var $$selectedVal = Array.prototype.filter
                              .call($event.target.options, function (o) {
                                return o.selected
                              })
                              .map(function (o) {
                                var val = "_value" in o ? o._value : o.value
                                return val
                              })
                            _vm.perPage = $event.target.multiple
                              ? $$selectedVal
                              : $$selectedVal[0]
                          },
                          _vm.changePerPage,
                        ],
                      },
                    },
                    [
                      _c("option", { attrs: { value: "9" } }, [_vm._v("9")]),
                      _vm._v(" "),
                      _c("option", { attrs: { value: "12" } }, [_vm._v("12")]),
                      _vm._v(" "),
                      _c("option", { attrs: { value: "24" } }, [_vm._v("24")]),
                      _vm._v(" "),
                      _c("option", { attrs: { value: "36" } }, [_vm._v("36")]),
                    ]
                  ),
                  _vm._v(" "),
                  _c("span", [_vm._v(_vm._s(_vm.__("per_page")))]),
                ]),
                _vm._v(" "),
                _c(
                  "ul",
                  { staticClass: "pagination pagination-primary" },
                  [
                    _c(
                      "li",
                      {
                        staticClass: "page-item",
                        class: { disabled: _vm.currentPage === 1 },
                      },
                      [
                        _c(
                          "a",
                          {
                            staticClass: "page-link",
                            attrs: { href: "#" },
                            on: {
                              click: function ($event) {
                                $event.preventDefault()
                                return _vm.changePage(_vm.currentPage - 1)
                              },
                            },
                          },
                          [
                            _c("span", { attrs: { "aria-hidden": "true" } }, [
                              _vm._v("«"),
                            ]),
                          ]
                        ),
                      ]
                    ),
                    _vm._v(" "),
                    _vm._l(_vm.paginationRange, function (page) {
                      return _c(
                        "li",
                        {
                          key: page,
                          staticClass: "page-item",
                          class: { active: page === _vm.currentPage },
                        },
                        [
                          _c(
                            "a",
                            {
                              staticClass: "page-link",
                              attrs: { href: "#" },
                              on: {
                                click: function ($event) {
                                  $event.preventDefault()
                                  return _vm.changePage(page)
                                },
                              },
                            },
                            [_vm._v(_vm._s(page))]
                          ),
                        ]
                      )
                    }),
                    _vm._v(" "),
                    _c(
                      "li",
                      {
                        staticClass: "page-item",
                        class: { disabled: _vm.currentPage === _vm.totalPages },
                      },
                      [
                        _c(
                          "a",
                          {
                            staticClass: "page-link",
                            attrs: { href: "#" },
                            on: {
                              click: function ($event) {
                                $event.preventDefault()
                                return _vm.changePage(_vm.currentPage + 1)
                              },
                            },
                          },
                          [
                            _c("span", { attrs: { "aria-hidden": "true" } }, [
                              _vm._v("»"),
                            ]),
                          ]
                        ),
                      ]
                    ),
                  ],
                  2
                ),
              ]
            ),
          ]),
        ]),
      ]),
      _vm._v(" "),
      _c("div", { staticClass: "col-lg-4 col-12" }, [
        _c("div", { staticClass: "d-flex justify-content-between mb-3" }, [
          _c(
            "button",
            {
              staticClass: "btn btn-primary",
              attrs: { disabled: _vm.cart.length === 0 },
              on: { click: _vm.showDiscountModal },
            },
            [
              _c("i", { staticClass: "fas fa-percentage me-1" }),
              _vm._v(_vm._s(_vm.__("add_discount")) + "\n                "),
            ]
          ),
          _vm._v(" "),
          _c(
            "button",
            {
              staticClass: "btn btn-primary",
              attrs: { disabled: _vm.cart.length === 0 },
              on: { click: _vm.showAdditionalChargeModal },
            },
            [
              _c("i", { staticClass: "fas fa-plus-circle me-1" }),
              _vm._v(
                _vm._s(_vm.__("add_additional_charges")) + "\n                "
              ),
            ]
          ),
        ]),
        _vm._v(" "),
        _c("div", { staticClass: "card mb-4" }, [
          _c("div", { staticClass: "card-header" }, [
            _c("h4", [_vm._v(_vm._s(_vm.__("customer")) + " Details")]),
          ]),
          _vm._v(" "),
          _c("div", { staticClass: "card-body" }, [
            _c("div", { staticClass: "row mb-3" }, [
              _c("div", { staticClass: "col-8" }, [
                _c("div", { staticClass: "search-select" }, [
                  _c("input", {
                    directives: [
                      {
                        name: "model",
                        rawName: "v-model",
                        value: _vm.customerSearchTerm,
                        expression: "customerSearchTerm",
                      },
                    ],
                    staticClass: "form-control",
                    attrs: { type: "text", placeholder: "Search customer" },
                    domProps: { value: _vm.customerSearchTerm },
                    on: {
                      input: [
                        function ($event) {
                          if ($event.target.composing) {
                            return
                          }
                          _vm.customerSearchTerm = $event.target.value
                        },
                        _vm.searchCustomers,
                      ],
                    },
                  }),
                  _vm._v(" "),
                  _vm.showCustomerResults && _vm.filteredUsers.length > 0
                    ? _c(
                        "div",
                        { staticClass: "search-results" },
                        [
                          _c(
                            "div",
                            {
                              staticClass: "search-option",
                              on: {
                                click: function ($event) {
                                  return _vm.selectCashSale()
                                },
                              },
                            },
                            [
                              _vm._v(
                                "\n                                        " +
                                  _vm._s(_vm.__("cash_sale")) +
                                  "\n                                    "
                              ),
                            ]
                          ),
                          _vm._v(" "),
                          _vm._l(_vm.filteredUsers, function (user) {
                            return _c(
                              "div",
                              {
                                key: user.id + "-" + user.user_type,
                                staticClass: "search-option",
                                on: {
                                  click: function ($event) {
                                    return _vm.selectUser(user)
                                  },
                                },
                              },
                              [
                                _vm._v(
                                  "\n                                        " +
                                    _vm._s(user.name) +
                                    "\n                                    "
                                ),
                              ]
                            )
                          }),
                        ],
                        2
                      )
                    : _vm._e(),
                ]),
              ]),
              _vm._v(" "),
              _c("div", { staticClass: "col-4" }, [
                _c(
                  "button",
                  {
                    staticClass: "btn btn-primary w-100",
                    on: { click: _vm.showRegisterModal },
                  },
                  [
                    _vm._v(
                      "\n                                " +
                        _vm._s(_vm.__("register_user")) +
                        "\n                            "
                    ),
                  ]
                ),
              ]),
            ]),
          ]),
        ]),
        _vm._v(" "),
        _c("div", { staticClass: "card" }, [
          _c(
            "div",
            {
              staticClass:
                "card-header d-flex justify-content-between align-items-center",
            },
            [
              _c("h4", [_vm._v(_vm._s(_vm.__("cart")))]),
              _vm._v(" "),
              _vm.cart.length > 0
                ? _c(
                    "button",
                    {
                      staticClass: "btn btn-sm btn-outline-danger",
                      on: { click: _vm.clearCart },
                    },
                    [
                      _vm._v(
                        "\n                        " +
                          _vm._s(_vm.__("clear_cart")) +
                          "\n                    "
                      ),
                    ]
                  )
                : _vm._e(),
            ]
          ),
          _vm._v(" "),
          _c("div", { staticClass: "card-body" }, [
            _vm.cart.length === 0
              ? _c("div", { staticClass: "text-center p-4" }, [
                  _c("p", [_vm._v(_vm._s(_vm.__("cart_empty")))]),
                ])
              : _c("div", [
                  _c(
                    "div",
                    { staticClass: "cart-items" },
                    _vm._l(_vm.cart, function (item, index) {
                      return _c(
                        "div",
                        { key: index, staticClass: "cart-item" },
                        [
                          _c("div", { staticClass: "item-image" }, [
                            _c("img", {
                              staticClass: "img-fluid rounded",
                              attrs: {
                                src:
                                  item.image || "/assets/img/placeholder.png",
                                alt: item.name,
                              },
                            }),
                          ]),
                          _vm._v(" "),
                          _c("div", { staticClass: "item-details" }, [
                            _c("h5", [_vm._v(_vm._s(item.name))]),
                            _vm._v(" "),
                            _c("p", { staticClass: "variant-info" }, [
                              _c("strong", [
                                _vm._v(
                                  _vm._s(
                                    item.variant
                                      ? item.variant.measurement +
                                          " " +
                                          item.variant.measurement_unit_name
                                      : item.variant_name
                                  )
                                ),
                              ]),
                            ]),
                            _vm._v(" "),
                            _c("div", { staticClass: "price" }, [
                              _vm._v(
                                "\n                                        " +
                                  _vm._s(_vm.$currency) +
                                  " " +
                                  _vm._s(item.price) +
                                  "\n                                    "
                              ),
                            ]),
                          ]),
                          _vm._v(" "),
                          _c("div", { staticClass: "item-quantity" }, [
                            _c("div", { staticClass: "input-group" }, [
                              _c(
                                "button",
                                {
                                  staticClass: "btn btn-outline-secondary",
                                  on: {
                                    click: function ($event) {
                                      return _vm.decreaseQuantity(index)
                                    },
                                  },
                                },
                                [_vm._v("-")]
                              ),
                              _vm._v(" "),
                              _c("input", {
                                directives: [
                                  {
                                    name: "model",
                                    rawName: "v-model",
                                    value: item.quantity,
                                    expression: "item.quantity",
                                  },
                                ],
                                staticClass: "form-control text-center",
                                attrs: { type: "number", min: "1" },
                                domProps: { value: item.quantity },
                                on: {
                                  change: function ($event) {
                                    return _vm.updateCartItem(index)
                                  },
                                  input: function ($event) {
                                    if ($event.target.composing) {
                                      return
                                    }
                                    _vm.$set(
                                      item,
                                      "quantity",
                                      $event.target.value
                                    )
                                  },
                                },
                              }),
                              _vm._v(" "),
                              _c(
                                "button",
                                {
                                  staticClass: "btn btn-outline-secondary",
                                  on: {
                                    click: function ($event) {
                                      return _vm.increaseQuantity(index, item)
                                    },
                                  },
                                },
                                [_vm._v("+")]
                              ),
                            ]),
                          ]),
                          _vm._v(" "),
                          _c("div", { staticClass: "item-total" }, [
                            _vm._v(
                              "\n                                    " +
                                _vm._s(_vm.$currency) +
                                " " +
                                _vm._s(
                                  (item.price * item.quantity).toFixed(2)
                                ) +
                                "\n                                "
                            ),
                          ]),
                          _vm._v(" "),
                          _c("div", { staticClass: "item-actions" }, [
                            _c(
                              "button",
                              {
                                staticClass: "btn btn-danger btn-sm",
                                on: {
                                  click: function ($event) {
                                    return _vm.removeFromCart(index)
                                  },
                                },
                              },
                              [_c("i", { staticClass: "bi bi-trash" })]
                            ),
                          ]),
                        ]
                      )
                    }),
                    0
                  ),
                  _vm._v(" "),
                  _c(
                    "div",
                    { staticClass: "cart-summary mt-4" },
                    [
                      _c(
                        "div",
                        { staticClass: "d-flex justify-content-between mb-2" },
                        [
                          _c("span", [
                            _vm._v(_vm._s(_vm.__("subtotal")) + ":"),
                          ]),
                          _vm._v(" "),
                          _c("span", [
                            _vm._v(
                              _vm._s(_vm.$currency) +
                                " " +
                                _vm._s(_vm.calculateSubtotal().toFixed(2))
                            ),
                          ]),
                        ]
                      ),
                      _vm._v(" "),
                      _vm.discount.amount > 0 || _vm.discount.percentage > 0
                        ? _c(
                            "div",
                            {
                              staticClass:
                                "d-flex justify-content-between mb-2 text-danger",
                            },
                            [
                              _c("span", [
                                _vm._v(_vm._s(_vm.__("discount")) + ":"),
                              ]),
                              _vm._v(" "),
                              _c("span", [
                                _vm._v(
                                  "-" +
                                    _vm._s(_vm.$currency) +
                                    " " +
                                    _vm._s(
                                      _vm.calculateDiscountAmount().toFixed(2)
                                    )
                                ),
                              ]),
                            ]
                          )
                        : _vm._e(),
                      _vm._v(" "),
                      _vm._l(_vm.additionalCharges, function (charge, index) {
                        return _c(
                          "div",
                          {
                            key: index,
                            staticClass: "d-flex justify-content-between mb-2",
                          },
                          [
                            _c("span", [
                              _vm._v(_vm._s(charge.charge_name) + ":"),
                            ]),
                            _vm._v(" "),
                            _c("span", [
                              _vm._v(
                                _vm._s(_vm.$currency) +
                                  " " +
                                  _vm._s(parseFloat(charge.amount).toFixed(2))
                              ),
                            ]),
                          ]
                        )
                      }),
                      _vm._v(" "),
                      _c(
                        "div",
                        {
                          staticClass:
                            "d-flex justify-content-between mb-2 pt-2 border-top fw-bold",
                        },
                        [
                          _c("span", [_vm._v(_vm._s(_vm.__("total")) + ":")]),
                          _vm._v(" "),
                          _c("span", [
                            _vm._v(
                              _vm._s(_vm.$currency) +
                                " " +
                                _vm._s(_vm.calculateFinalTotal().toFixed(2))
                            ),
                          ]),
                        ]
                      ),
                    ],
                    2
                  ),
                  _vm._v(" "),
                  _c("div", { staticClass: "mt-4" }, [
                    _c("div", { staticClass: "mb-3" }, [
                      _c(
                        "label",
                        {
                          staticClass: "form-label",
                          attrs: { for: "paymentMethod" },
                        },
                        [_vm._v(_vm._s(_vm.__("select_payment_method")))]
                      ),
                      _vm._v(" "),
                      _c(
                        "select",
                        {
                          directives: [
                            {
                              name: "model",
                              rawName: "v-model",
                              value: _vm.paymentMethod,
                              expression: "paymentMethod",
                            },
                          ],
                          staticClass: "form-select",
                          attrs: { id: "paymentMethod" },
                          on: {
                            change: function ($event) {
                              var $$selectedVal = Array.prototype.filter
                                .call($event.target.options, function (o) {
                                  return o.selected
                                })
                                .map(function (o) {
                                  var val = "_value" in o ? o._value : o.value
                                  return val
                                })
                              _vm.paymentMethod = $event.target.multiple
                                ? $$selectedVal
                                : $$selectedVal[0]
                            },
                          },
                        },
                        [
                          _c("option", { attrs: { value: "cash" } }, [
                            _vm._v(_vm._s(_vm.__("cash"))),
                          ]),
                          _vm._v(" "),
                          _c("option", { attrs: { value: "upi" } }, [
                            _vm._v(_vm._s(_vm.__("upi"))),
                          ]),
                          _vm._v(" "),
                          _c("option", { attrs: { value: "card" } }, [
                            _vm._v(_vm._s(_vm.__("card_payment"))),
                          ]),
                        ]
                      ),
                    ]),
                    _vm._v(" "),
                    _c("div", { staticClass: "d-flex gap-2" }, [
                      _c(
                        "button",
                        {
                          staticClass: "btn btn-outline-primary flex-grow-1",
                          attrs: { disabled: _vm.cart.length === 0 },
                          on: { click: _vm.placeOrderAndPrint },
                        },
                        [
                          _c("i", { staticClass: "fas fa-print me-1" }),
                          _vm._v(
                            " " +
                              _vm._s(_vm.__("save_and_print_bill")) +
                              "\n                                "
                          ),
                        ]
                      ),
                      _vm._v(" "),
                      _c(
                        "button",
                        {
                          staticClass: "btn btn-primary flex-grow-1",
                          attrs: { disabled: _vm.cart.length === 0 },
                          on: {
                            click: function ($event) {
                              return _vm.placeOrder(false)
                            },
                          },
                        },
                        [
                          _vm._v(
                            "\n                                    " +
                              _vm._s(_vm.__("place_order")) +
                              "\n                                "
                          ),
                        ]
                      ),
                    ]),
                  ]),
                ]),
          ]),
        ]),
      ]),
    ]),
    _vm._v(" "),
    _c(
      "div",
      {
        staticClass: "modal fade",
        attrs: {
          id: "registerUserModal",
          tabindex: "-1",
          "aria-labelledby": "registerUserModalLabel",
          "aria-hidden": "true",
        },
      },
      [
        _c("div", { staticClass: "modal-dialog" }, [
          _c("div", { staticClass: "modal-content" }, [
            _c("div", { staticClass: "modal-header" }, [
              _c(
                "h5",
                {
                  staticClass: "modal-title",
                  attrs: { id: "registerUserModalLabel" },
                },
                [_vm._v(_vm._s(_vm.__("register_new_customer")))]
              ),
              _vm._v(" "),
              _c("button", {
                staticClass: "btn-close",
                attrs: { type: "button" },
                on: { click: _vm.closeRegisterModal },
              }),
            ]),
            _vm._v(" "),
            _c("div", { staticClass: "modal-body" }, [
              _c("div", { staticClass: "mb-3" }, [
                _c(
                  "label",
                  { staticClass: "form-label", attrs: { for: "name" } },
                  [_vm._v(_vm._s(_vm.__("name")) + " *")]
                ),
                _vm._v(" "),
                _c("input", {
                  directives: [
                    {
                      name: "model",
                      rawName: "v-model",
                      value: _vm.newUser.name,
                      expression: "newUser.name",
                    },
                  ],
                  staticClass: "form-control",
                  attrs: { type: "text", id: "name", required: "" },
                  domProps: { value: _vm.newUser.name },
                  on: {
                    input: function ($event) {
                      if ($event.target.composing) {
                        return
                      }
                      _vm.$set(_vm.newUser, "name", $event.target.value)
                    },
                  },
                }),
              ]),
              _vm._v(" "),
              _c("div", { staticClass: "mb-3" }, [
                _c(
                  "label",
                  { staticClass: "form-label", attrs: { for: "mobile" } },
                  [_vm._v(_vm._s(_vm.__("mobile")))]
                ),
                _vm._v(" "),
                _c("input", {
                  directives: [
                    {
                      name: "model",
                      rawName: "v-model",
                      value: _vm.newUser.mobile,
                      expression: "newUser.mobile",
                    },
                  ],
                  staticClass: "form-control",
                  attrs: { type: "number", id: "mobile" },
                  domProps: { value: _vm.newUser.mobile },
                  on: {
                    input: function ($event) {
                      if ($event.target.composing) {
                        return
                      }
                      _vm.$set(_vm.newUser, "mobile", $event.target.value)
                    },
                  },
                }),
              ]),
            ]),
            _vm._v(" "),
            _c("div", { staticClass: "modal-footer" }, [
              _c(
                "button",
                {
                  staticClass: "btn btn-secondary",
                  attrs: { type: "button" },
                  on: { click: _vm.closeRegisterModal },
                },
                [_vm._v(_vm._s(_vm.__("cancel")))]
              ),
              _vm._v(" "),
              _c(
                "button",
                {
                  staticClass: "btn btn-primary",
                  attrs: { type: "button" },
                  on: { click: _vm.registerUser },
                },
                [_vm._v(_vm._s(_vm.__("register")))]
              ),
            ]),
          ]),
        ]),
      ]
    ),
    _vm._v(" "),
    _c(
      "div",
      {
        staticClass: "modal fade",
        attrs: {
          id: "productDetailsModal",
          tabindex: "-1",
          "aria-labelledby": "productDetailsModalLabel",
          "aria-hidden": "true",
        },
      },
      [
        _c("div", { staticClass: "modal-dialog modal-lg" }, [
          _c("div", { staticClass: "modal-content" }, [
            _c("div", { staticClass: "modal-header" }, [
              _c(
                "h5",
                {
                  staticClass: "modal-title",
                  attrs: { id: "productDetailsModalLabel" },
                },
                [
                  _vm._v(
                    _vm._s(_vm.selectedProduct ? _vm.selectedProduct.name : "")
                  ),
                ]
              ),
              _vm._v(" "),
              _c("button", {
                staticClass: "btn-close",
                attrs: { type: "button" },
                on: { click: _vm.closeProductDetailsModal },
              }),
            ]),
            _vm._v(" "),
            _vm.selectedProduct
              ? _c("div", { staticClass: "modal-body" }, [
                  _c("div", { staticClass: "row" }, [
                    _c("div", { staticClass: "col-md-5" }, [
                      _c("img", {
                        staticClass: "img-fluid rounded",
                        attrs: {
                          src: _vm.selectedProduct.image_url,
                          alt: _vm.selectedProduct.name,
                        },
                      }),
                    ]),
                    _vm._v(" "),
                    _c("div", { staticClass: "col-md-7" }, [
                      _c("h4", [_vm._v(_vm._s(_vm.selectedProduct.name))]),
                      _vm._v(" "),
                      _c("p", [
                        _vm._v(_vm._s(_vm.selectedProduct.description)),
                      ]),
                      _vm._v(" "),
                      _vm.selectedProduct.variants &&
                      _vm.selectedProduct.variants.length > 0
                        ? _c("div", { staticClass: "form-group mt-3" }, [
                            _c(
                              "label",
                              {
                                staticClass: "form-label",
                                attrs: { for: "variant" },
                              },
                              [_vm._v(_vm._s(_vm.__("variant")))]
                            ),
                            _vm._v(" "),
                            _c(
                              "select",
                              {
                                directives: [
                                  {
                                    name: "model",
                                    rawName: "v-model",
                                    value: _vm.selectedVariant,
                                    expression: "selectedVariant",
                                  },
                                ],
                                staticClass: "form-select",
                                attrs: { id: "variant" },
                                on: {
                                  change: function ($event) {
                                    var $$selectedVal = Array.prototype.filter
                                      .call(
                                        $event.target.options,
                                        function (o) {
                                          return o.selected
                                        }
                                      )
                                      .map(function (o) {
                                        var val =
                                          "_value" in o ? o._value : o.value
                                        return val
                                      })
                                    _vm.selectedVariant = $event.target.multiple
                                      ? $$selectedVal
                                      : $$selectedVal[0]
                                  },
                                },
                              },
                              _vm._l(
                                _vm.selectedProduct.variants,
                                function (variant) {
                                  return _c(
                                    "option",
                                    {
                                      key: variant.id,
                                      domProps: { value: variant },
                                    },
                                    [
                                      _vm._v(
                                        "\n                                        " +
                                          _vm._s(variant.measurement) +
                                          " " +
                                          _vm._s(
                                            variant.measurement_unit_name
                                          ) +
                                          "\n                                        - " +
                                          _vm._s(_vm.$currency) +
                                          " " +
                                          _vm._s(
                                            variant.discounted_price > 0
                                              ? variant.discounted_price
                                              : variant.price
                                          ) +
                                          "\n                                    "
                                      ),
                                    ]
                                  )
                                }
                              ),
                              0
                            ),
                          ])
                        : _vm._e(),
                      _vm._v(" "),
                      _c("div", { staticClass: "mt-3" }, [
                        _c(
                          "label",
                          {
                            staticClass: "form-label",
                            attrs: { for: "quantity" },
                          },
                          [_vm._v(_vm._s(_vm.__("quantity")))]
                        ),
                        _vm._v(" "),
                        _c("div", { staticClass: "input-group" }, [
                          _c(
                            "button",
                            {
                              staticClass: "btn btn-outline-secondary",
                              on: {
                                click: function ($event) {
                                  _vm.productQuantity > 1
                                    ? _vm.productQuantity--
                                    : 1
                                },
                              },
                            },
                            [_vm._v("-")]
                          ),
                          _vm._v(" "),
                          _c("input", {
                            directives: [
                              {
                                name: "model",
                                rawName: "v-model",
                                value: _vm.productQuantity,
                                expression: "productQuantity",
                              },
                            ],
                            staticClass: "form-control text-center",
                            attrs: { type: "number", id: "quantity", min: "1" },
                            domProps: { value: _vm.productQuantity },
                            on: {
                              input: function ($event) {
                                if ($event.target.composing) {
                                  return
                                }
                                _vm.productQuantity = $event.target.value
                              },
                            },
                          }),
                          _vm._v(" "),
                          _c(
                            "button",
                            {
                              staticClass: "btn btn-outline-secondary",
                              on: {
                                click: function ($event) {
                                  _vm.productQuantity++
                                },
                              },
                            },
                            [_vm._v("+")]
                          ),
                        ]),
                      ]),
                      _vm._v(" "),
                      _c("div", { staticClass: "mt-4" }, [
                        _c(
                          "button",
                          {
                            staticClass: "btn btn-primary",
                            on: { click: _vm.addToCart },
                          },
                          [
                            _vm._v(
                              "\n                                    " +
                                _vm._s(_vm.__("add_to_cart")) +
                                "\n                                "
                            ),
                          ]
                        ),
                      ]),
                    ]),
                  ]),
                ])
              : _vm._e(),
          ]),
        ]),
      ]
    ),
    _vm._v(" "),
    _c(
      "div",
      {
        staticClass: "modal fade",
        attrs: {
          id: "discountModal",
          tabindex: "-1",
          "aria-labelledby": "discountModalLabel",
          "aria-hidden": "true",
        },
      },
      [
        _c("div", { staticClass: "modal-dialog" }, [
          _c("div", { staticClass: "modal-content" }, [
            _c("div", { staticClass: "modal-header" }, [
              _c(
                "h5",
                {
                  staticClass: "modal-title",
                  attrs: { id: "discountModalLabel" },
                },
                [_vm._v(_vm._s(_vm.__("add_discount")))]
              ),
              _vm._v(" "),
              _c("button", {
                staticClass: "btn-close",
                attrs: {
                  type: "button",
                  "data-bs-dismiss": "modal",
                  "aria-label": "Close",
                },
              }),
            ]),
            _vm._v(" "),
            _c("div", { staticClass: "modal-body" }, [
              _c("div", { staticClass: "mb-3" }, [
                _c(
                  "label",
                  {
                    staticClass: "form-label",
                    attrs: { for: "discountPercentage" },
                  },
                  [_vm._v(_vm._s(_vm.__("discount_percentage")))]
                ),
                _vm._v(" "),
                _c("div", { staticClass: "input-group" }, [
                  _c("input", {
                    directives: [
                      {
                        name: "model",
                        rawName: "v-model.number",
                        value: _vm.discount.percentage,
                        expression: "discount.percentage",
                        modifiers: { number: true },
                      },
                    ],
                    staticClass: "form-control",
                    attrs: {
                      type: "number",
                      id: "discountPercentage",
                      min: "0",
                      max: "100",
                      step: "1",
                    },
                    domProps: { value: _vm.discount.percentage },
                    on: {
                      input: [
                        function ($event) {
                          if ($event.target.composing) {
                            return
                          }
                          _vm.$set(
                            _vm.discount,
                            "percentage",
                            _vm._n($event.target.value)
                          )
                        },
                        function ($event) {
                          return _vm.validateDiscountInput("percentage", $event)
                        },
                      ],
                      blur: function ($event) {
                        return _vm.$forceUpdate()
                      },
                    },
                  }),
                  _vm._v(" "),
                  _c("span", { staticClass: "input-group-text" }, [
                    _vm._v("%"),
                  ]),
                ]),
                _vm._v(" "),
                _c("small", { staticClass: "text-muted" }, [
                  _vm._v(
                    _vm._s(_vm.__("subtotal")) +
                      ": " +
                      _vm._s(_vm.$currency) +
                      " " +
                      _vm._s(_vm.calculateSubtotal().toFixed(2))
                  ),
                ]),
              ]),
              _vm._v(" "),
              _c("div", { staticClass: "mb-3" }, [
                _c(
                  "label",
                  {
                    staticClass: "form-label",
                    attrs: { for: "discountAmount" },
                  },
                  [_vm._v(_vm._s(_vm.__("discount_amount")))]
                ),
                _vm._v(" "),
                _c("div", { staticClass: "input-group" }, [
                  _c("span", { staticClass: "input-group-text" }, [
                    _vm._v(_vm._s(_vm.$currency)),
                  ]),
                  _vm._v(" "),
                  _c("input", {
                    directives: [
                      {
                        name: "model",
                        rawName: "v-model.number",
                        value: _vm.discount.amount,
                        expression: "discount.amount",
                        modifiers: { number: true },
                      },
                    ],
                    staticClass: "form-control",
                    attrs: {
                      type: "number",
                      id: "discountAmount",
                      min: "0",
                      max: _vm.calculateSubtotal(),
                      step: "0.01",
                    },
                    domProps: { value: _vm.discount.amount },
                    on: {
                      input: [
                        function ($event) {
                          if ($event.target.composing) {
                            return
                          }
                          _vm.$set(
                            _vm.discount,
                            "amount",
                            _vm._n($event.target.value)
                          )
                        },
                        function ($event) {
                          return _vm.validateDiscountInput("amount", $event)
                        },
                      ],
                      blur: function ($event) {
                        return _vm.$forceUpdate()
                      },
                    },
                  }),
                ]),
                _vm._v(" "),
                _c("small", { staticClass: "text-muted" }, [
                  _vm._v(_vm._s(_vm.__("discount_amount_not_exceed_total"))),
                ]),
              ]),
              _vm._v(" "),
              _c("p", { staticClass: "mb-0 text-info" }, [
                _c("i", { staticClass: "fas fa-info-circle me-1" }),
                _vm._v(
                  "\n                        " +
                    _vm._s(_vm.__("discount_info_message")) +
                    "\n                    "
                ),
              ]),
            ]),
            _vm._v(" "),
            _c("div", { staticClass: "modal-footer" }, [
              _c(
                "button",
                {
                  staticClass: "btn btn-secondary",
                  attrs: { type: "button", "data-bs-dismiss": "modal" },
                },
                [_vm._v(_vm._s(_vm.__("cancel")))]
              ),
              _vm._v(" "),
              _c(
                "button",
                {
                  staticClass: "btn btn-danger",
                  attrs: { type: "button" },
                  on: { click: _vm.clearDiscount },
                },
                [_vm._v(_vm._s(_vm.__("clear_discount")))]
              ),
              _vm._v(" "),
              _c(
                "button",
                {
                  staticClass: "btn btn-primary",
                  attrs: { type: "button" },
                  on: { click: _vm.applyDiscount },
                },
                [_vm._v(_vm._s(_vm.__("apply_discount")))]
              ),
            ]),
          ]),
        ]),
      ]
    ),
    _vm._v(" "),
    _c(
      "div",
      {
        staticClass: "modal fade",
        attrs: {
          id: "additionalChargeModal",
          tabindex: "-1",
          "aria-labelledby": "additionalChargeModalLabel",
          "aria-hidden": "true",
        },
      },
      [
        _c("div", { staticClass: "modal-dialog" }, [
          _c("div", { staticClass: "modal-content" }, [
            _c("div", { staticClass: "modal-header" }, [
              _c(
                "h5",
                {
                  staticClass: "modal-title",
                  attrs: { id: "additionalChargeModalLabel" },
                },
                [_vm._v(_vm._s(_vm.__("add_additional_charges")))]
              ),
              _vm._v(" "),
              _c("button", {
                staticClass: "btn-close",
                attrs: {
                  type: "button",
                  "data-bs-dismiss": "modal",
                  "aria-label": "Close",
                },
              }),
            ]),
            _vm._v(" "),
            _c(
              "div",
              { staticClass: "modal-body" },
              [
                _vm._l(_vm.tempAdditionalCharges, function (charge, index) {
                  return _c("div", { key: index, staticClass: "mb-3" }, [
                    _c("div", { staticClass: "row mb-2" }, [
                      _c("div", { staticClass: "col-12" }, [
                        _c(
                          "div",
                          {
                            staticClass:
                              "d-flex justify-content-between align-items-center",
                          },
                          [
                            _c("label", { staticClass: "form-label" }, [
                              _vm._v(
                                _vm._s(_vm.__("charge")) +
                                  " #" +
                                  _vm._s(index + 1)
                              ),
                            ]),
                            _vm._v(" "),
                            index > 0
                              ? _c(
                                  "button",
                                  {
                                    staticClass:
                                      "btn btn-sm btn-outline-danger",
                                    attrs: { type: "button" },
                                    on: {
                                      click: function ($event) {
                                        return _vm.removeAdditionalCharge(index)
                                      },
                                    },
                                  },
                                  [
                                    _c("i", {
                                      staticClass: "fas fa-trash me-1",
                                    }),
                                    _vm._v(
                                      _vm._s(_vm.__("remove")) +
                                        "\n                                    "
                                    ),
                                  ]
                                )
                              : _vm._e(),
                          ]
                        ),
                      ]),
                    ]),
                    _vm._v(" "),
                    _c("div", { staticClass: "row g-2" }, [
                      _c("div", { staticClass: "col-md-6" }, [
                        _c(
                          "label",
                          {
                            staticClass: "form-label",
                            attrs: { for: "chargeName" },
                          },
                          [_vm._v(_vm._s(_vm.__("charge_name")))]
                        ),
                        _vm._v(" "),
                        _c("input", {
                          directives: [
                            {
                              name: "model",
                              rawName: "v-model",
                              value: charge.charge_name,
                              expression: "charge.charge_name",
                            },
                          ],
                          staticClass: "form-control",
                          attrs: {
                            type: "text",
                            placeholder: "Enter Charge Name",
                            required: "",
                          },
                          domProps: { value: charge.charge_name },
                          on: {
                            input: function ($event) {
                              if ($event.target.composing) {
                                return
                              }
                              _vm.$set(
                                charge,
                                "charge_name",
                                $event.target.value
                              )
                            },
                          },
                        }),
                        _vm._v(" "),
                        _vm.chargeErrors[index] && _vm.chargeErrors[index].name
                          ? _c("div", { staticClass: "text-danger mt-1" }, [
                              _vm._v(_vm._s(_vm.chargeErrors[index].name)),
                            ])
                          : _vm._e(),
                      ]),
                      _vm._v(" "),
                      _c("div", { staticClass: "col-md-6" }, [
                        _c(
                          "label",
                          {
                            staticClass: "form-label",
                            attrs: { for: "chargeAmount" },
                          },
                          [_vm._v(_vm._s(_vm.__("amount")))]
                        ),
                        _vm._v(" "),
                        _c("div", { staticClass: "input-group" }, [
                          _c("span", { staticClass: "input-group-text" }, [
                            _vm._v(_vm._s(_vm.$currency)),
                          ]),
                          _vm._v(" "),
                          _c("input", {
                            directives: [
                              {
                                name: "model",
                                rawName: "v-model",
                                value: charge.amount,
                                expression: "charge.amount",
                              },
                            ],
                            staticClass: "form-control",
                            attrs: {
                              type: "number",
                              min: "0",
                              step: "0.01",
                              required: "",
                            },
                            domProps: { value: charge.amount },
                            on: {
                              input: function ($event) {
                                if ($event.target.composing) {
                                  return
                                }
                                _vm.$set(charge, "amount", $event.target.value)
                              },
                            },
                          }),
                        ]),
                        _vm._v(" "),
                        _vm.chargeErrors[index] &&
                        _vm.chargeErrors[index].amount
                          ? _c("div", { staticClass: "text-danger mt-1" }, [
                              _vm._v(_vm._s(_vm.chargeErrors[index].amount)),
                            ])
                          : _vm._e(),
                      ]),
                    ]),
                  ])
                }),
                _vm._v(" "),
                _c(
                  "button",
                  {
                    staticClass: "btn btn-outline-success w-100 mt-2",
                    attrs: { type: "button" },
                    on: {
                      click: function ($event) {
                        $event.stopPropagation()
                        $event.preventDefault()
                        return _vm.addNewCharge.apply(null, arguments)
                      },
                    },
                  },
                  [
                    _c("i", { staticClass: "fas fa-plus me-1" }),
                    _vm._v(
                      _vm._s(_vm.__("add_another_charge")) +
                        "\n                    "
                    ),
                  ]
                ),
              ],
              2
            ),
            _vm._v(" "),
            _c("div", { staticClass: "modal-footer" }, [
              _c(
                "button",
                {
                  staticClass: "btn btn-secondary",
                  attrs: { type: "button", "data-bs-dismiss": "modal" },
                },
                [_vm._v(_vm._s(_vm.__("cancel")))]
              ),
              _vm._v(" "),
              _c(
                "button",
                {
                  staticClass: "btn btn-danger",
                  attrs: { type: "button" },
                  on: { click: _vm.clearAdditionalCharges },
                },
                [_vm._v(_vm._s(_vm.__("clear_all_charges")))]
              ),
              _vm._v(" "),
              _c(
                "button",
                {
                  staticClass: "btn btn-primary",
                  attrs: { type: "button" },
                  on: { click: _vm.applyAdditionalCharges },
                },
                [_vm._v(_vm._s(_vm.__("apply_charges")))]
              ),
            ]),
          ]),
        ]),
      ]
    ),
  ])
}
var staticRenderFns = [
  function () {
    var _vm = this
    var _h = _vm.$createElement
    var _c = _vm._self._c || _h
    return _c(
      "div",
      { staticClass: "spinner-border", attrs: { role: "status" } },
      [_c("span", { staticClass: "visually-hidden" }, [_vm._v("Loading...")])]
    )
  },
]
render._withStripped = true



/***/ })

}]);