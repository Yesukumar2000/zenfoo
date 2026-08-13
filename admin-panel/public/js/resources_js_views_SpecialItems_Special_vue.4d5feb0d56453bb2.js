"use strict";
(self["webpackChunk"] = self["webpackChunk"] || []).push([["resources_js_views_SpecialItems_Special_vue"],{

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SpecialItems/EditItem.vue?vue&type=script&lang=js":
/*!**********************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SpecialItems/EditItem.vue?vue&type=script&lang=js ***!
  \**********************************************************************************************************************************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var axios__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! axios */ "./node_modules/axios/index.js");
/* harmony import */ var axios__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(axios__WEBPACK_IMPORTED_MODULE_0__);
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
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
  props: ["id"],
  data: function data() {
    return {
      search: "",
      name: "",
      description: "",
      price: "",
      type: "",
      status: 1,
      image: null,
      image_url: null,
      error: null,
      isLoading: false,
      products: [],
      product_ids: [],
      quantities: {},
      currentPage: 1,
      pageSize: 10
    };
  },
  computed: {
    isEdit: function isEdit() {
      return !!this.id;
    },
    filteredProducts: function filteredProducts() {
      var _this = this;
      if (!this.search) return this.products;
      return this.products.filter(function (p) {
        return p.name.toLowerCase().includes(_this.search.toLowerCase());
      });
    },
    paginatedProducts: function paginatedProducts() {
      var start = (this.currentPage - 1) * this.pageSize;
      var end = start + this.pageSize;
      this.startIndex = start;
      this.endIndex = Math.min(end, this.filteredProducts.length);
      return this.filteredProducts.slice(start, end);
    }
  },
  created: function created() {
    this.fetchProducts();
  },
  watch: {
    product_ids: function product_ids(newIds, oldIds) {
      var _this2 = this;
      newIds.forEach(function (id) {
        if (!_this2.quantities[id] || _this2.quantities[id] === 0) {
          _this2.$set(_this2.quantities, id, 1);
        }
      });
      oldIds.forEach(function (id) {
        if (!newIds.includes(id)) {
          _this2.$set(_this2.quantities, id, 0);
        }
      });
    }
  },
  methods: {
    goBack: function goBack() {
      this.$router.push({
        path: "/manage_combos"
      });
    },
    fetchProducts: function fetchProducts() {
      var _this3 = this;
      if (this.id) {
        axios__WEBPACK_IMPORTED_MODULE_0___default().get("".concat(this.$apiUrl, "/combos/").concat(this.id, "/edit")).then(function (res) {
          var _combo$status;
          var combo = res.data.combo;
          var products = res.data.products || [];
          _this3.products = Array.isArray(products) ? products : [];
          _this3.name = combo.name || "";
          _this3.description = combo.description || "";
          _this3.price = combo.price || "";
          _this3.type = combo.type || "";
          _this3.status = (_combo$status = combo.status) !== null && _combo$status !== void 0 ? _combo$status : 1;
          _this3.image_url = combo.image_url || null;
          _this3.product_ids = combo.products.map(function (p) {
            return p.id;
          });
          _this3.quantities = {};
          _this3.products.forEach(function (p) {
            var _inCombo$pivot$quanti, _inCombo$pivot;
            var inCombo = combo.products.find(function (cp) {
              return cp.id === p.id;
            });
            _this3.quantities[p.id] = (_inCombo$pivot$quanti = inCombo === null || inCombo === void 0 ? void 0 : (_inCombo$pivot = inCombo.pivot) === null || _inCombo$pivot === void 0 ? void 0 : _inCombo$pivot.quantity) !== null && _inCombo$pivot$quanti !== void 0 ? _inCombo$pivot$quanti : 0;
            p.image_url = p.image ? "".concat(_this3.$apiUrl, "/storage/").concat(p.image) : "/images/no-image.png";
          });
        })["catch"](function () {
          return _this3.showError("Failed to load combo details.");
        });
      } else {
        axios__WEBPACK_IMPORTED_MODULE_0___default().get("".concat(this.$apiUrl, "/combos/products")).then(function (res) {
          var _ref, _ref2, _res$data$data;
          var products = (_ref = (_ref2 = (_res$data$data = res.data.data) !== null && _res$data$data !== void 0 ? _res$data$data : res.data.products) !== null && _ref2 !== void 0 ? _ref2 : res.data) !== null && _ref !== void 0 ? _ref : [];
          _this3.products = Array.isArray(products) ? products : [];
          _this3.products.forEach(function (p) {
            _this3.quantities[p.id] = 0;
            p.image_url = p.image ? "".concat(_this3.$apiUrl, "/storage/").concat(p.image) : "/images/no-image.png";
          });
        })["catch"](function () {
          return _this3.showError("Failed to load products.");
        });
      }
    },
    dropFile: function dropFile(event) {
      event.preventDefault();
      this.$refs.file_image.files = event.dataTransfer.files;
      this.handleFileUpload();
    },
    handleFileUpload: function handleFileUpload() {
      var file = this.$refs.file_image.files[0];
      this.error = null;
      if (!file) return;
      var validTypes = ["image/jpeg", "image/png", "image/jpg", "image/gif", "image/webp", "image/svg+xml"];
      if (!validTypes.includes(file.type)) {
        this.error = "Invalid file type.";
        return;
      }
      var maxSize = 2 * 1024 * 1024;
      if (file.size > maxSize) {
        this.error = "File size exceeds 2MB.";
        return;
      }
      this.image = file;
      this.image_url = URL.createObjectURL(file);
    },
    saveCombo: function saveCombo() {
      var _this4 = this;
      this.isLoading = true;
      var formData = new FormData();
      if (this.id) formData.append("id", this.id);
      formData.append("name", this.name);
      formData.append("description", this.description);
      formData.append("price", this.price);
      formData.append("type", this.type);
      if (this.image) formData.append("image", this.image);
      formData.append("status", this.status);
      this.product_ids.forEach(function (id) {
        formData.append("product_ids[]", id);
        formData.append("quantities[".concat(id, "]"), _this4.quantities[id] || 0);
      });
      var url = this.isEdit ? "".concat(this.$apiUrl, "/combos/save/").concat(this.id) : "".concat(this.$apiUrl, "/combos/save");
      axios__WEBPACK_IMPORTED_MODULE_0___default().post(url, formData, {
        headers: {
          "Content-Type": "multipart/form-data"
        }
      }).then(function (res) {
        var data = res.data;
        if (data.status === 1) {
          _this4.$swal.fire("Success", data.message, "success");
          _this4.$router.push({
            path: "/manage_combos"
          });
        } else {
          _this4.showError(data.message);
        }
      })["catch"](function (error) {
        _this4.showError(error.message || __("something_went_wrong"));
      })["finally"](function () {
        _this4.isLoading = false;
      });
    },
    showError: function showError(message) {
      this.$swal.fire("Error", message, "error");
    }
  }
});

/***/ }),

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SpecialItems/Special.vue?vue&type=script&lang=js":
/*!*********************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SpecialItems/Special.vue?vue&type=script&lang=js ***!
  \*********************************************************************************************************************************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _EditItem_vue__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./EditItem.vue */ "./resources/js/views/SpecialItems/EditItem.vue");
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


/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = ({
  name: "CombosList",
  components: {
    EditItem: _EditItem_vue__WEBPACK_IMPORTED_MODULE_0__["default"]
  },
  data: function data() {
    return {
      fields: [{
        key: "index",
        label: "S.No",
        "class": "text-center"
      }, {
        key: "Title",
        label: "Name",
        "class": "text-center"
      }],
      combos: [],
      totalRows: 0,
      currentPage: 1,
      perPage: 10,
      pageOptions: [10, 25, 50, 100],
      filter: "",
      isLoading: false
    };
  },
  mounted: function mounted() {
    var _this = this;
    this.getCombos();
    this.showCreateModal();

    // Listen for save events
    this.$eventBus.$on("comboSaved", function (message) {
      _this.showMessage("success", message);
      _this.getCombos();
      _this.create_new = false;
    });
  },
  methods: {
    getCombos: function getCombos() {
      var _this2 = this;
      this.isLoading = true;
      var params = {
        page: this.currentPage,
        per_page: this.perPage,
        search: this.filter
      };
      axios.get(this.$apiUrl + "/special", {
        params: params
      }).then(function (res) {
        _this2.isLoading = false;
        var combos = res.data; // <-- plain array
        _this2.combos = combos.map(function (combo, i) {
          return _objectSpread(_objectSpread({}, combo), {}, {
            index: (_this2.currentPage - 1) * _this2.perPage + i + 1
          });
        });
        _this2.totalRows = combos.length; // <-- totalRows is just length for plain array
      })["catch"](function () {
        return _this2.isLoading = false;
      });
    },
    deleteCombo: function deleteCombo(index, id) {
      var _this3 = this;
      this.$swal.fire({
        title: "Are you sure?",
        text: "You won't be able to revert this!",
        icon: "warning",
        showCancelButton: true,
        confirmButtonText: "Yes, delete it!",
        cancelButtonText: "Cancel"
      }).then(function (result) {
        if (result.value) {
          axios.post(_this3.$apiUrl + "/special/delete", {
            id: id
          }).then(function () {
            _this3.combos.splice(index, 1);
            _this3.totalRows--;
            _this3.$swal.fire("Deleted!", "Combo deleted successfully.", "success");
          });
        }
      });
    }
  }
});

/***/ }),

/***/ "./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SpecialItems/EditItem.vue?vue&type=style&index=0&id=6743e654&scoped=true&lang=css":
/*!******************************************************************************************************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SpecialItems/EditItem.vue?vue&type=style&index=0&id=6743e654&scoped=true&lang=css ***!
  \******************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/
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
___CSS_LOADER_EXPORT___.push([module.id, "\n.custom-image[data-v-6743e654] {\r\n  border-radius: 5px;\r\n  border: 1px solid #ddd;\n}\n.file-input-div[data-v-6743e654] {\r\n  padding: 20px;\r\n  border: 2px dashed #ccc;\r\n  text-align: center;\r\n  cursor: pointer;\n}\r\n", ""]);
// Exports
/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (___CSS_LOADER_EXPORT___);


/***/ }),

/***/ "./node_modules/style-loader/dist/cjs.js!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SpecialItems/EditItem.vue?vue&type=style&index=0&id=6743e654&scoped=true&lang=css":
/*!**********************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/style-loader/dist/cjs.js!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SpecialItems/EditItem.vue?vue&type=style&index=0&id=6743e654&scoped=true&lang=css ***!
  \**********************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! !../../../../node_modules/style-loader/dist/runtime/injectStylesIntoStyleTag.js */ "./node_modules/style-loader/dist/runtime/injectStylesIntoStyleTag.js");
/* harmony import */ var _node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_EditItem_vue_vue_type_style_index_0_id_6743e654_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! !!../../../../node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!../../../../node_modules/vue-loader/lib/loaders/stylePostLoader.js!../../../../node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./EditItem.vue?vue&type=style&index=0&id=6743e654&scoped=true&lang=css */ "./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SpecialItems/EditItem.vue?vue&type=style&index=0&id=6743e654&scoped=true&lang=css");

            

var options = {};

options.insert = "head";
options.singleton = false;

var update = _node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0___default()(_node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_EditItem_vue_vue_type_style_index_0_id_6743e654_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_1__["default"], options);



/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (_node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_EditItem_vue_vue_type_style_index_0_id_6743e654_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_1__["default"].locals || {});

/***/ }),

/***/ "./resources/js/views/SpecialItems/EditItem.vue":
/*!******************************************************!*\
  !*** ./resources/js/views/SpecialItems/EditItem.vue ***!
  \******************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _EditItem_vue_vue_type_template_id_6743e654_scoped_true__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./EditItem.vue?vue&type=template&id=6743e654&scoped=true */ "./resources/js/views/SpecialItems/EditItem.vue?vue&type=template&id=6743e654&scoped=true");
/* harmony import */ var _EditItem_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./EditItem.vue?vue&type=script&lang=js */ "./resources/js/views/SpecialItems/EditItem.vue?vue&type=script&lang=js");
/* harmony import */ var _EditItem_vue_vue_type_style_index_0_id_6743e654_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ./EditItem.vue?vue&type=style&index=0&id=6743e654&scoped=true&lang=css */ "./resources/js/views/SpecialItems/EditItem.vue?vue&type=style&index=0&id=6743e654&scoped=true&lang=css");
/* harmony import */ var _node_modules_vue_loader_lib_runtime_componentNormalizer_js__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! !../../../../node_modules/vue-loader/lib/runtime/componentNormalizer.js */ "./node_modules/vue-loader/lib/runtime/componentNormalizer.js");



;


/* normalize component */

var component = (0,_node_modules_vue_loader_lib_runtime_componentNormalizer_js__WEBPACK_IMPORTED_MODULE_3__["default"])(
  _EditItem_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"],
  _EditItem_vue_vue_type_template_id_6743e654_scoped_true__WEBPACK_IMPORTED_MODULE_0__.render,
  _EditItem_vue_vue_type_template_id_6743e654_scoped_true__WEBPACK_IMPORTED_MODULE_0__.staticRenderFns,
  false,
  null,
  "6743e654",
  null
  
)

/* hot reload */
if (false) { var api; }
component.options.__file = "resources/js/views/SpecialItems/EditItem.vue"
/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (component.exports);

/***/ }),

/***/ "./resources/js/views/SpecialItems/Special.vue":
/*!*****************************************************!*\
  !*** ./resources/js/views/SpecialItems/Special.vue ***!
  \*****************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _Special_vue_vue_type_template_id_1df5e230__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./Special.vue?vue&type=template&id=1df5e230 */ "./resources/js/views/SpecialItems/Special.vue?vue&type=template&id=1df5e230");
/* harmony import */ var _Special_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./Special.vue?vue&type=script&lang=js */ "./resources/js/views/SpecialItems/Special.vue?vue&type=script&lang=js");
/* harmony import */ var _node_modules_vue_loader_lib_runtime_componentNormalizer_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! !../../../../node_modules/vue-loader/lib/runtime/componentNormalizer.js */ "./node_modules/vue-loader/lib/runtime/componentNormalizer.js");





/* normalize component */
;
var component = (0,_node_modules_vue_loader_lib_runtime_componentNormalizer_js__WEBPACK_IMPORTED_MODULE_2__["default"])(
  _Special_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"],
  _Special_vue_vue_type_template_id_1df5e230__WEBPACK_IMPORTED_MODULE_0__.render,
  _Special_vue_vue_type_template_id_1df5e230__WEBPACK_IMPORTED_MODULE_0__.staticRenderFns,
  false,
  null,
  null,
  null
  
)

/* hot reload */
if (false) { var api; }
component.options.__file = "resources/js/views/SpecialItems/Special.vue"
/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (component.exports);

/***/ }),

/***/ "./resources/js/views/SpecialItems/EditItem.vue?vue&type=script&lang=js":
/*!******************************************************************************!*\
  !*** ./resources/js/views/SpecialItems/EditItem.vue?vue&type=script&lang=js ***!
  \******************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_5_use_0_node_modules_vue_loader_lib_index_js_vue_loader_options_EditItem_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./EditItem.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SpecialItems/EditItem.vue?vue&type=script&lang=js");
 /* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (_node_modules_babel_loader_lib_index_js_clonedRuleSet_5_use_0_node_modules_vue_loader_lib_index_js_vue_loader_options_EditItem_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]); 

/***/ }),

/***/ "./resources/js/views/SpecialItems/Special.vue?vue&type=script&lang=js":
/*!*****************************************************************************!*\
  !*** ./resources/js/views/SpecialItems/Special.vue?vue&type=script&lang=js ***!
  \*****************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_5_use_0_node_modules_vue_loader_lib_index_js_vue_loader_options_Special_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./Special.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SpecialItems/Special.vue?vue&type=script&lang=js");
 /* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (_node_modules_babel_loader_lib_index_js_clonedRuleSet_5_use_0_node_modules_vue_loader_lib_index_js_vue_loader_options_Special_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]); 

/***/ }),

/***/ "./resources/js/views/SpecialItems/EditItem.vue?vue&type=style&index=0&id=6743e654&scoped=true&lang=css":
/*!**************************************************************************************************************!*\
  !*** ./resources/js/views/SpecialItems/EditItem.vue?vue&type=style&index=0&id=6743e654&scoped=true&lang=css ***!
  \**************************************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _node_modules_style_loader_dist_cjs_js_node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_EditItem_vue_vue_type_style_index_0_id_6743e654_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/style-loader/dist/cjs.js!../../../../node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!../../../../node_modules/vue-loader/lib/loaders/stylePostLoader.js!../../../../node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./EditItem.vue?vue&type=style&index=0&id=6743e654&scoped=true&lang=css */ "./node_modules/style-loader/dist/cjs.js!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SpecialItems/EditItem.vue?vue&type=style&index=0&id=6743e654&scoped=true&lang=css");


/***/ }),

/***/ "./resources/js/views/SpecialItems/EditItem.vue?vue&type=template&id=6743e654&scoped=true":
/*!************************************************************************************************!*\
  !*** ./resources/js/views/SpecialItems/EditItem.vue?vue&type=template&id=6743e654&scoped=true ***!
  \************************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: () => (/* reexport safe */ _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_EditItem_vue_vue_type_template_id_6743e654_scoped_true__WEBPACK_IMPORTED_MODULE_0__.render),
/* harmony export */   staticRenderFns: () => (/* reexport safe */ _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_EditItem_vue_vue_type_template_id_6743e654_scoped_true__WEBPACK_IMPORTED_MODULE_0__.staticRenderFns)
/* harmony export */ });
/* harmony import */ var _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_EditItem_vue_vue_type_template_id_6743e654_scoped_true__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./EditItem.vue?vue&type=template&id=6743e654&scoped=true */ "./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SpecialItems/EditItem.vue?vue&type=template&id=6743e654&scoped=true");


/***/ }),

/***/ "./resources/js/views/SpecialItems/Special.vue?vue&type=template&id=1df5e230":
/*!***********************************************************************************!*\
  !*** ./resources/js/views/SpecialItems/Special.vue?vue&type=template&id=1df5e230 ***!
  \***********************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: () => (/* reexport safe */ _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_Special_vue_vue_type_template_id_1df5e230__WEBPACK_IMPORTED_MODULE_0__.render),
/* harmony export */   staticRenderFns: () => (/* reexport safe */ _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_Special_vue_vue_type_template_id_1df5e230__WEBPACK_IMPORTED_MODULE_0__.staticRenderFns)
/* harmony export */ });
/* harmony import */ var _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_Special_vue_vue_type_template_id_1df5e230__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./Special.vue?vue&type=template&id=1df5e230 */ "./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SpecialItems/Special.vue?vue&type=template&id=1df5e230");


/***/ }),

/***/ "./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SpecialItems/EditItem.vue?vue&type=template&id=6743e654&scoped=true":
/*!***************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SpecialItems/EditItem.vue?vue&type=template&id=6743e654&scoped=true ***!
  \***************************************************************************************************************************************************************************************************************************************/
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
  return _c("div", [
    _c("div", { staticClass: "page-heading" }, [
      _c("div", { staticClass: "row" }, [
        _c("div", { staticClass: "col-12 col-md-6 order-md-1 order-last" }, [
          _c(
            "h3",
            [
              _vm.id
                ? [_vm._v(_vm._s(_vm.__("edit")))]
                : [_vm._v(_vm._s(_vm.__("create")))],
              _vm._v("\n          " + _vm._s(_vm.__("combo")) + "\n        "),
            ],
            2
          ),
        ]),
        _vm._v(" "),
        _c("div", { staticClass: "col-12 col-md-6 order-md-2 order-first" }, [
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
                    _c("router-link", { attrs: { to: "/dashboard" } }, [
                      _vm._v(_vm._s(_vm.__("dashboard"))),
                    ]),
                  ],
                  1
                ),
                _vm._v(" "),
                _c(
                  "li",
                  { staticClass: "breadcrumb-item" },
                  [
                    _c("router-link", { attrs: { to: "/manage_combos" } }, [
                      _vm._v(_vm._s(_vm.__("manage_special_item"))),
                    ]),
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
                  [
                    _vm.id
                      ? [_vm._v(_vm._s(_vm.__("edit")))]
                      : [_vm._v(_vm._s(_vm.__("create")))],
                    _vm._v(
                      "\n              " +
                        _vm._s(_vm.__("combo")) +
                        "\n            "
                    ),
                  ],
                  2
                ),
              ]),
            ]
          ),
        ]),
      ]),
    ]),
    _vm._v(" "),
    _c("div", { staticClass: "row" }, [
      _c("div", { staticClass: "col-12" }, [
        _c(
          "form",
          {
            attrs: { enctype: "multipart/form-data" },
            on: {
              submit: function ($event) {
                $event.preventDefault()
                return _vm.saveCombo.apply(null, arguments)
              },
            },
          },
          [
            _c("div", { staticClass: "card" }, [
              _c("div", { staticClass: "card-body" }, [
                _c("div", { staticClass: "row" }, [
                  _c("div", { staticClass: "form-group col-md-6" }, [
                    _c("label", [_vm._v(_vm._s(_vm.__("title")))]),
                    _vm._v(" "),
                    _c("input", {
                      directives: [
                        {
                          name: "model",
                          rawName: "v-model",
                          value: _vm.name,
                          expression: "name",
                        },
                      ],
                      staticClass: "form-control",
                      attrs: {
                        type: "text",
                        required: "",
                        placeholder: _vm.__("enter_special_title"),
                      },
                      domProps: { value: _vm.name },
                      on: {
                        input: function ($event) {
                          if ($event.target.composing) {
                            return
                          }
                          _vm.name = $event.target.value
                        },
                      },
                    }),
                  ]),
                  _vm._v(" "),
                  _c(
                    "div",
                    { staticClass: "col-md-12 mt-3" },
                    [
                      _vm._l(_vm.paginatedProducts, function (p) {
                        return _c(
                          "div",
                          {
                            key: p.id,
                            staticClass:
                              "d-flex align-items-center mb-2 border-bottom pb-1",
                          },
                          [
                            _c("input", {
                              directives: [
                                {
                                  name: "model",
                                  rawName: "v-model",
                                  value: _vm.product_ids,
                                  expression: "product_ids",
                                },
                              ],
                              staticClass: "me-2",
                              attrs: { type: "checkbox" },
                              domProps: {
                                value: p.id,
                                checked: Array.isArray(_vm.product_ids)
                                  ? _vm._i(_vm.product_ids, p.id) > -1
                                  : _vm.product_ids,
                              },
                              on: {
                                change: function ($event) {
                                  var $$a = _vm.product_ids,
                                    $$el = $event.target,
                                    $$c = $$el.checked ? true : false
                                  if (Array.isArray($$a)) {
                                    var $$v = p.id,
                                      $$i = _vm._i($$a, $$v)
                                    if ($$el.checked) {
                                      $$i < 0 &&
                                        (_vm.product_ids = $$a.concat([$$v]))
                                    } else {
                                      $$i > -1 &&
                                        (_vm.product_ids = $$a
                                          .slice(0, $$i)
                                          .concat($$a.slice($$i + 1)))
                                    }
                                  } else {
                                    _vm.product_ids = $$c
                                  }
                                },
                              },
                            }),
                            _vm._v(" "),
                            _c("img", {
                              staticClass: "me-2 rounded",
                              attrs: {
                                src: p.image_url,
                                width: "40",
                                height: "40",
                              },
                            }),
                            _vm._v(" "),
                            _c("span", { staticClass: "flex-grow-1" }, [
                              _vm._v(_vm._s(p.name)),
                            ]),
                            _vm._v(" "),
                            _c("input", {
                              directives: [
                                {
                                  name: "model",
                                  rawName: "v-model.number",
                                  value: _vm.quantities[p.id],
                                  expression: "quantities[p.id]",
                                  modifiers: { number: true },
                                },
                              ],
                              staticClass: "form-control w-25",
                              attrs: {
                                type: "number",
                                min: "1",
                                placeholder: "Qty",
                                disabled: !_vm.product_ids.includes(p.id),
                              },
                              domProps: { value: _vm.quantities[p.id] },
                              on: {
                                input: function ($event) {
                                  if ($event.target.composing) {
                                    return
                                  }
                                  _vm.$set(
                                    _vm.quantities,
                                    p.id,
                                    _vm._n($event.target.value)
                                  )
                                },
                                blur: function ($event) {
                                  return _vm.$forceUpdate()
                                },
                              },
                            }),
                          ]
                        )
                      }),
                      _vm._v(" "),
                      _c(
                        "div",
                        {
                          staticClass:
                            "d-flex justify-content-between align-items-center mt-3",
                        },
                        [
                          _c("div", [
                            _c("small", [
                              _vm._v(
                                "Showing " +
                                  _vm._s(_vm.startIndex + 1) +
                                  " - " +
                                  _vm._s(_vm.endIndex) +
                                  " of " +
                                  _vm._s(_vm.filteredProducts.length)
                              ),
                            ]),
                          ]),
                          _vm._v(" "),
                          _c("div", [
                            _c(
                              "button",
                              {
                                staticClass:
                                  "btn btn-sm btn-outline-primary me-1",
                                attrs: {
                                  disabled: _vm.currentPage === 1,
                                  type: "button",
                                },
                                on: {
                                  click: function ($event) {
                                    _vm.currentPage--
                                  },
                                },
                              },
                              [
                                _vm._v(
                                  "\n                      Prev\n                    "
                                ),
                              ]
                            ),
                            _vm._v(" "),
                            _c(
                              "button",
                              {
                                staticClass: "btn btn-sm btn-outline-primary",
                                attrs: {
                                  disabled:
                                    _vm.currentPage * _vm.pageSize >=
                                    _vm.filteredProducts.length,
                                  type: "button",
                                },
                                on: {
                                  click: function ($event) {
                                    _vm.currentPage++
                                  },
                                },
                              },
                              [
                                _vm._v(
                                  "\n                      Next\n                    "
                                ),
                              ]
                            ),
                          ]),
                        ]
                      ),
                    ],
                    2
                  ),
                  _vm._v(" "),
                  _vm.id
                    ? _c(
                        "div",
                        { staticClass: "form-group col-md-12 mt-4" },
                        [
                          _c("label", [_vm._v(_vm._s(_vm.__("status")))]),
                          _vm._v(" "),
                          _c("b-form-radio-group", {
                            attrs: {
                              options: [
                                { text: "Deactivated", value: 0 },
                                { text: "Activated", value: 1 },
                              ],
                              buttons: "",
                              "button-variant": "outline-primary",
                            },
                            model: {
                              value: _vm.status,
                              callback: function ($$v) {
                                _vm.status = $$v
                              },
                              expression: "status",
                            },
                          }),
                        ],
                        1
                      )
                    : _vm._e(),
                  _vm._v(" "),
                  _c("div", { staticClass: "text-end mt-4" }, [
                    _c(
                      "button",
                      {
                        staticClass: "btn btn-primary",
                        attrs: { type: "submit", disabled: _vm.isLoading },
                      },
                      [
                        _vm._v(
                          "\n                  " +
                            _vm._s(
                              _vm.isEdit ? _vm.__("update") : _vm.__("save")
                            ) +
                            "\n                  "
                        ),
                        _vm.isLoading
                          ? _c("b-spinner", {
                              staticClass: "ms-1",
                              attrs: { small: "", label: "Saving..." },
                            })
                          : _vm._e(),
                      ],
                      1
                    ),
                    _vm._v(" "),
                    _c(
                      "button",
                      {
                        staticClass: "btn btn-secondary ms-2",
                        attrs: { type: "button" },
                        on: { click: _vm.goBack },
                      },
                      [
                        _vm._v(
                          "\n                  " +
                            _vm._s(_vm.__("cancel")) +
                            "\n                "
                        ),
                      ]
                    ),
                  ]),
                ]),
              ]),
            ]),
          ]
        ),
      ]),
    ]),
  ])
}
var staticRenderFns = []
render._withStripped = true



/***/ }),

/***/ "./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SpecialItems/Special.vue?vue&type=template&id=1df5e230":
/*!**************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SpecialItems/Special.vue?vue&type=template&id=1df5e230 ***!
  \**************************************************************************************************************************************************************************************************************************/
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
  return _c("div", [
    _c("div", { staticClass: "page-heading" }, [
      _c("div", { staticClass: "row" }, [
        _c("div", { staticClass: "col-12 col-md-6 order-md-1 order-last" }, [
          _c("h3", [_vm._v(_vm._s(_vm.__("manage_combos")))]),
        ]),
        _vm._v(" "),
        _c("div", { staticClass: "col-12 col-md-6 order-md-2 order-first" }, [
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
                    _c("router-link", { attrs: { to: "/dashboard" } }, [
                      _vm._v(_vm._s(_vm.__("dashboard"))),
                    ]),
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
                  [
                    _vm._v(
                      "\n              " +
                        _vm._s(_vm.__("manage_combos")) +
                        "\n            "
                    ),
                  ]
                ),
              ]),
            ]
          ),
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
          _c("h4", [_vm._v(_vm._s(_vm.__("combo_packages")))]),
          _vm._v(" "),
          [
            _c(
              "router-link",
              {
                directives: [
                  {
                    name: "b-tooltip",
                    rawName: "v-b-tooltip.hover",
                    modifiers: { hover: true },
                  },
                ],
                staticClass: "btn btn-primary",
                attrs: { to: "/manage_combos/create", title: "Add Combo" },
              },
              [_vm._v(_vm._s(_vm.__("add_combo")))]
            ),
          ],
        ],
        2
      ),
      _vm._v(" "),
      _c(
        "div",
        { staticClass: "card-body" },
        [
          _c(
            "b-row",
            { staticClass: "mb-2" },
            [
              _c(
                "b-col",
                { attrs: { md: "3", "offset-md": "8" } },
                [
                  _c("h6", [_vm._v(_vm._s(_vm.__("search")))]),
                  _vm._v(" "),
                  _c("b-form-input", {
                    attrs: { type: "search", placeholder: _vm.__("search") },
                    on: { input: _vm.getCombos },
                    model: {
                      value: _vm.filter,
                      callback: function ($$v) {
                        _vm.filter = $$v
                      },
                      expression: "filter",
                    },
                  }),
                ],
                1
              ),
              _vm._v(" "),
              _c("b-col", { staticClass: "text-center", attrs: { md: "1" } }, [
                _c(
                  "button",
                  {
                    directives: [
                      {
                        name: "b-tooltip",
                        rawName: "v-b-tooltip.hover",
                        modifiers: { hover: true },
                      },
                    ],
                    staticClass: "btn btn-primary btn_refresh",
                    attrs: { title: _vm.__("refresh") },
                    on: { click: _vm.getCombos },
                  },
                  [
                    _c("i", {
                      staticClass: "fa fa-refresh",
                      attrs: { "aria-hidden": "true" },
                    }),
                  ]
                ),
              ]),
            ],
            1
          ),
          _vm._v(" "),
          _c("b-table", {
            attrs: {
              items: _vm.combos,
              fields: _vm.fields,
              filter: _vm.filter,
              bordered: true,
              busy: _vm.isLoading,
              stacked: "md",
              "show-empty": "",
              small: "",
            },
            scopedSlots: _vm._u([
              {
                key: "table-busy",
                fn: function () {
                  return [
                    _c(
                      "div",
                      { staticClass: "text-center text-black my-2" },
                      [
                        _c("b-spinner", { staticClass: "align-middle" }),
                        _vm._v(" "),
                        _c("strong", [
                          _vm._v(_vm._s(_vm.__("loading")) + "..."),
                        ]),
                      ],
                      1
                    ),
                  ]
                },
                proxy: true,
              },
              {
                key: "cell(image)",
                fn: function (row) {
                  return [
                    _c("img", {
                      attrs: { src: row.item.image_url, height: "50" },
                    }),
                  ]
                },
              },
              {
                key: "cell(actions)",
                fn: function (row) {
                  return [
                    _c(
                      "router-link",
                      {
                        directives: [
                          {
                            name: "b-tooltip",
                            rawName: "v-b-tooltip.hover",
                            modifiers: { hover: true },
                          },
                        ],
                        staticClass: "btn btn-sm btn-primary me-2",
                        attrs: {
                          to: { name: "EditItem", params: { id: row.item.id } },
                          title: _vm.__("edit"),
                        },
                      },
                      [_c("i", { staticClass: "fa fa-pencil-alt" })]
                    ),
                    _vm._v(" "),
                    _c(
                      "button",
                      {
                        directives: [
                          {
                            name: "b-tooltip",
                            rawName: "v-b-tooltip.hover",
                            modifiers: { hover: true },
                          },
                        ],
                        staticClass: "btn btn-sm btn-danger",
                        attrs: { title: _vm.__("delete") },
                        on: {
                          click: function ($event) {
                            return _vm.deleteCombo(row.index, row.item.id)
                          },
                        },
                      },
                      [_c("i", { staticClass: "fa fa-trash" })]
                    ),
                  ]
                },
              },
            ]),
          }),
          _vm._v(" "),
          _c(
            "b-row",
            [
              _c(
                "b-col",
                { staticClass: "my-1", attrs: { md: "2" } },
                [
                  _c(
                    "b-form-group",
                    {
                      staticClass: "mb-0",
                      attrs: {
                        label: _vm.__("per_page"),
                        "label-for": "per-page-select",
                        "label-align-sm": "right",
                        "label-size": "sm",
                      },
                    },
                    [
                      _c("b-form-select", {
                        staticClass: "form-control form-select",
                        attrs: {
                          id: "per-page-select",
                          options: _vm.pageOptions,
                          size: "sm",
                        },
                        on: { change: _vm.getCombos },
                        model: {
                          value: _vm.perPage,
                          callback: function ($$v) {
                            _vm.perPage = $$v
                          },
                          expression: "perPage",
                        },
                      }),
                    ],
                    1
                  ),
                ],
                1
              ),
              _vm._v(" "),
              _c(
                "b-col",
                { staticClass: "my-1", attrs: { md: "4", "offset-md": "6" } },
                [
                  _c("label", [
                    _vm._v(
                      _vm._s(_vm.__("total_records")) +
                        ": " +
                        _vm._s(_vm.totalRows)
                    ),
                  ]),
                  _vm._v(" "),
                  _c("b-pagination", {
                    staticClass: "my-0",
                    attrs: {
                      "total-rows": _vm.totalRows,
                      "per-page": _vm.perPage,
                      align: "fill",
                      size: "sm",
                    },
                    on: { change: _vm.getCombos },
                    model: {
                      value: _vm.currentPage,
                      callback: function ($$v) {
                        _vm.currentPage = $$v
                      },
                      expression: "currentPage",
                    },
                  }),
                ],
                1
              ),
            ],
            1
          ),
        ],
        1
      ),
    ]),
  ])
}
var staticRenderFns = []
render._withStripped = true



/***/ })

}]);