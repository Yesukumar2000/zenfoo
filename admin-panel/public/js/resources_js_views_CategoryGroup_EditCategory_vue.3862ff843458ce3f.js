"use strict";
(self["webpackChunk"] = self["webpackChunk"] || []).push([["resources_js_views_CategoryGroup_EditCategory_vue"],{

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/CategoryGroup/EditCategory.vue?vue&type=script&lang=js":
/*!***************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/CategoryGroup/EditCategory.vue?vue&type=script&lang=js ***!
  \***************************************************************************************************************************************************************************************************************/
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


/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = ({
  props: ['record'],
  data: function data() {
    return {
      id: this.record ? this.record.id : null,
      name: this.record ? this.record.name : '',
      icon: null,
      image: null,
      color: this.record ? this.record.color : '#000000',
      status: this.record ? this.record.status : 1,
      isLoading: false
    };
  },
  computed: {
    modal_title: function modal_title() {
      return this.id ? 'Edit Category Group' : 'Add Category Group';
    }
  },
  created: function created() {},
  methods: {
    onFileChange: function onFileChange(event) {
      this.image = event.target.files[0];
    },
    onIconChange: function onIconChange(event) {
      this.icon = event.target.files[0];
    },
    showModal: function showModal() {
      this.$refs['my-modal'].show();
    },
    hideModal: function hideModal() {
      this.$refs['my-modal'].hide();
    },
    saveGroup: function saveGroup() {
      var _this = this;
      this.isLoading = true;
      var formData = new FormData();
      if (this.id) formData.append('id', this.id);
      formData.append('name', this.name);
      if (this.icon) formData.append('icon', this.icon);
      formData.append('color', this.color);
      formData.append('status', this.status);
      if (this.image) formData.append('image', this.image);
      var url = this.id ? this.$apiUrl + '/group-category/update' : this.$apiUrl + '/group-category/save';
      axios__WEBPACK_IMPORTED_MODULE_0___default().post(url, formData).then(function (res) {
        if (res.data.status === 1) {
          _this.$emit('groupSaved', res.data.message);
          _this.hideModal();
          _this.isLoading = false;
        } else {
          _this.showError(res.data.message);
          _this.isLoading = false;
        }
      })["catch"](function (err) {
        _this.isLoading = false;
        _this.showError(err.message || "Something went wrong!");
      });
    },
    showError: function showError(message) {
      alert(message); // replace with your toast/notification
    }
  },
  mounted: function mounted() {
    this.showModal();
  }
});

/***/ }),

/***/ "./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/CategoryGroup/EditCategory.vue?vue&type=style&index=0&id=78b4d5d5&scoped=true&lang=css":
/*!***********************************************************************************************************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/CategoryGroup/EditCategory.vue?vue&type=style&index=0&id=78b4d5d5&scoped=true&lang=css ***!
  \***********************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/
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
___CSS_LOADER_EXPORT___.push([module.id, "\n.form-check-inline[data-v-78b4d5d5] {\r\n    margin-right: 20px;\n}\r\n", ""]);
// Exports
/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (___CSS_LOADER_EXPORT___);


/***/ }),

/***/ "./node_modules/style-loader/dist/cjs.js!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/CategoryGroup/EditCategory.vue?vue&type=style&index=0&id=78b4d5d5&scoped=true&lang=css":
/*!***************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/style-loader/dist/cjs.js!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/CategoryGroup/EditCategory.vue?vue&type=style&index=0&id=78b4d5d5&scoped=true&lang=css ***!
  \***************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! !../../../../node_modules/style-loader/dist/runtime/injectStylesIntoStyleTag.js */ "./node_modules/style-loader/dist/runtime/injectStylesIntoStyleTag.js");
/* harmony import */ var _node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_EditCategory_vue_vue_type_style_index_0_id_78b4d5d5_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! !!../../../../node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!../../../../node_modules/vue-loader/lib/loaders/stylePostLoader.js!../../../../node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./EditCategory.vue?vue&type=style&index=0&id=78b4d5d5&scoped=true&lang=css */ "./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/CategoryGroup/EditCategory.vue?vue&type=style&index=0&id=78b4d5d5&scoped=true&lang=css");

            

var options = {};

options.insert = "head";
options.singleton = false;

var update = _node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0___default()(_node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_EditCategory_vue_vue_type_style_index_0_id_78b4d5d5_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_1__["default"], options);



/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (_node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_EditCategory_vue_vue_type_style_index_0_id_78b4d5d5_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_1__["default"].locals || {});

/***/ }),

/***/ "./resources/js/views/CategoryGroup/EditCategory.vue":
/*!***********************************************************!*\
  !*** ./resources/js/views/CategoryGroup/EditCategory.vue ***!
  \***********************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _EditCategory_vue_vue_type_template_id_78b4d5d5_scoped_true__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./EditCategory.vue?vue&type=template&id=78b4d5d5&scoped=true */ "./resources/js/views/CategoryGroup/EditCategory.vue?vue&type=template&id=78b4d5d5&scoped=true");
/* harmony import */ var _EditCategory_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./EditCategory.vue?vue&type=script&lang=js */ "./resources/js/views/CategoryGroup/EditCategory.vue?vue&type=script&lang=js");
/* harmony import */ var _EditCategory_vue_vue_type_style_index_0_id_78b4d5d5_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ./EditCategory.vue?vue&type=style&index=0&id=78b4d5d5&scoped=true&lang=css */ "./resources/js/views/CategoryGroup/EditCategory.vue?vue&type=style&index=0&id=78b4d5d5&scoped=true&lang=css");
/* harmony import */ var _node_modules_vue_loader_lib_runtime_componentNormalizer_js__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! !../../../../node_modules/vue-loader/lib/runtime/componentNormalizer.js */ "./node_modules/vue-loader/lib/runtime/componentNormalizer.js");



;


/* normalize component */

var component = (0,_node_modules_vue_loader_lib_runtime_componentNormalizer_js__WEBPACK_IMPORTED_MODULE_3__["default"])(
  _EditCategory_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"],
  _EditCategory_vue_vue_type_template_id_78b4d5d5_scoped_true__WEBPACK_IMPORTED_MODULE_0__.render,
  _EditCategory_vue_vue_type_template_id_78b4d5d5_scoped_true__WEBPACK_IMPORTED_MODULE_0__.staticRenderFns,
  false,
  null,
  "78b4d5d5",
  null
  
)

/* hot reload */
if (false) { var api; }
component.options.__file = "resources/js/views/CategoryGroup/EditCategory.vue"
/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (component.exports);

/***/ }),

/***/ "./resources/js/views/CategoryGroup/EditCategory.vue?vue&type=script&lang=js":
/*!***********************************************************************************!*\
  !*** ./resources/js/views/CategoryGroup/EditCategory.vue?vue&type=script&lang=js ***!
  \***********************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_5_use_0_node_modules_vue_loader_lib_index_js_vue_loader_options_EditCategory_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./EditCategory.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/CategoryGroup/EditCategory.vue?vue&type=script&lang=js");
 /* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (_node_modules_babel_loader_lib_index_js_clonedRuleSet_5_use_0_node_modules_vue_loader_lib_index_js_vue_loader_options_EditCategory_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]); 

/***/ }),

/***/ "./resources/js/views/CategoryGroup/EditCategory.vue?vue&type=style&index=0&id=78b4d5d5&scoped=true&lang=css":
/*!*******************************************************************************************************************!*\
  !*** ./resources/js/views/CategoryGroup/EditCategory.vue?vue&type=style&index=0&id=78b4d5d5&scoped=true&lang=css ***!
  \*******************************************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _node_modules_style_loader_dist_cjs_js_node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_EditCategory_vue_vue_type_style_index_0_id_78b4d5d5_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/style-loader/dist/cjs.js!../../../../node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!../../../../node_modules/vue-loader/lib/loaders/stylePostLoader.js!../../../../node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./EditCategory.vue?vue&type=style&index=0&id=78b4d5d5&scoped=true&lang=css */ "./node_modules/style-loader/dist/cjs.js!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/CategoryGroup/EditCategory.vue?vue&type=style&index=0&id=78b4d5d5&scoped=true&lang=css");


/***/ }),

/***/ "./resources/js/views/CategoryGroup/EditCategory.vue?vue&type=template&id=78b4d5d5&scoped=true":
/*!*****************************************************************************************************!*\
  !*** ./resources/js/views/CategoryGroup/EditCategory.vue?vue&type=template&id=78b4d5d5&scoped=true ***!
  \*****************************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: () => (/* reexport safe */ _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_EditCategory_vue_vue_type_template_id_78b4d5d5_scoped_true__WEBPACK_IMPORTED_MODULE_0__.render),
/* harmony export */   staticRenderFns: () => (/* reexport safe */ _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_EditCategory_vue_vue_type_template_id_78b4d5d5_scoped_true__WEBPACK_IMPORTED_MODULE_0__.staticRenderFns)
/* harmony export */ });
/* harmony import */ var _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_EditCategory_vue_vue_type_template_id_78b4d5d5_scoped_true__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./EditCategory.vue?vue&type=template&id=78b4d5d5&scoped=true */ "./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/CategoryGroup/EditCategory.vue?vue&type=template&id=78b4d5d5&scoped=true");


/***/ }),

/***/ "./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/CategoryGroup/EditCategory.vue?vue&type=template&id=78b4d5d5&scoped=true":
/*!********************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/CategoryGroup/EditCategory.vue?vue&type=template&id=78b4d5d5&scoped=true ***!
  \********************************************************************************************************************************************************************************************************************************************/
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
  return _c(
    "b-modal",
    {
      ref: "my-modal",
      attrs: {
        title: _vm.modal_title,
        size: "xl",
        scrollable: "",
        "no-close-on-backdrop": "",
        "no-fade": "",
        static: "",
      },
      on: {
        hidden: function ($event) {
          return _vm.$emit("modalClose")
        },
      },
      scopedSlots: _vm._u([
        {
          key: "modal-header",
          fn: function (ref) {
            var close = ref.close
            return [
              _vm.id
                ? _c("h5", { staticClass: "modal-title" }, [
                    _vm._v(_vm._s(_vm.modal_title) + " & Group: "),
                    _c("strong", [_vm._v(_vm._s(_vm.name))]),
                  ])
                : _c("h5", { staticClass: "modal-title" }, [
                    _vm._v(_vm._s(_vm.modal_title)),
                  ]),
              _vm._v(" "),
              _c(
                "button",
                {
                  staticClass: "close",
                  attrs: { type: "button", "aria-label": "Close" },
                  on: {
                    click: function ($event) {
                      return close()
                    },
                  },
                },
                [_vm._v("×")]
              ),
            ]
          },
        },
      ]),
    },
    [
      _c(
        "div",
        { attrs: { slot: "modal-footer" }, slot: "modal-footer" },
        [
          _c(
            "b-button",
            {
              attrs: { variant: "primary", disabled: _vm.isLoading },
              on: {
                click: function ($event) {
                  return _vm.$refs["dummy_submit"].click()
                },
              },
            },
            [
              _vm._v("\n            Save\n            "),
              _vm.isLoading
                ? _c("b-spinner", { attrs: { small: "", label: "Spinning" } })
                : _vm._e(),
            ],
            1
          ),
          _vm._v(" "),
          _c(
            "b-button",
            { attrs: { variant: "secondary" }, on: { click: _vm.hideModal } },
            [_vm._v("Cancel")]
          ),
        ],
        1
      ),
      _vm._v(" "),
      _vm._v(" "),
      _c(
        "form",
        {
          ref: "my-form",
          on: {
            submit: function ($event) {
              $event.preventDefault()
              return _vm.saveGroup.apply(null, arguments)
            },
          },
        },
        [
          _c("div", { staticClass: "row" }, [
            _c("div", { staticClass: "form-group col-md-6" }, [
              _c("label", [_vm._v("Group Name")]),
              _vm._v(" "),
              _c("i", { staticClass: "text-danger" }, [_vm._v("*")]),
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
                  placeholder: "Enter group name",
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
            _c("div", { staticClass: "form-group col-md-6" }, [
              _c("label", [_vm._v("Icon URL")]),
              _vm._v(" "),
              _c("input", {
                staticClass: "form-control",
                attrs: { type: "file" },
                on: { change: _vm.onIconChange },
              }),
            ]),
            _vm._v(" "),
            _c("div", { staticClass: "form-group col-md-6" }, [
              _c("label", [_vm._v("Image")]),
              _vm._v(" "),
              _c("input", {
                staticClass: "form-control",
                attrs: { type: "file" },
                on: { change: _vm.onFileChange },
              }),
            ]),
            _vm._v(" "),
            _c("div", { staticClass: "form-group col-md-6" }, [
              _c("label", [_vm._v("Color Palette")]),
              _vm._v(" "),
              _c("input", {
                directives: [
                  {
                    name: "model",
                    rawName: "v-model",
                    value: _vm.color,
                    expression: "color",
                  },
                ],
                staticClass: "form-control",
                attrs: { type: "color" },
                domProps: { value: _vm.color },
                on: {
                  input: function ($event) {
                    if ($event.target.composing) {
                      return
                    }
                    _vm.color = $event.target.value
                  },
                },
              }),
            ]),
            _vm._v(" "),
            _c("div", { staticClass: "form-group col-12" }, [
              _c("label", [_vm._v("Status")]),
              _c("br"),
              _vm._v(" "),
              _c("div", { staticClass: "form-check form-check-inline" }, [
                _c("input", {
                  directives: [
                    {
                      name: "model",
                      rawName: "v-model",
                      value: _vm.status,
                      expression: "status",
                    },
                  ],
                  staticClass: "form-check-input",
                  attrs: { type: "radio", name: "status", value: "1" },
                  domProps: { checked: _vm._q(_vm.status, "1") },
                  on: {
                    change: function ($event) {
                      _vm.status = "1"
                    },
                  },
                }),
                _vm._v(" "),
                _c("label", { staticClass: "form-check-label" }, [
                  _vm._v("Active"),
                ]),
              ]),
              _vm._v(" "),
              _c("div", { staticClass: "form-check form-check-inline" }, [
                _c("input", {
                  directives: [
                    {
                      name: "model",
                      rawName: "v-model",
                      value: _vm.status,
                      expression: "status",
                    },
                  ],
                  staticClass: "form-check-input",
                  attrs: { type: "radio", name: "status", value: "0" },
                  domProps: { checked: _vm._q(_vm.status, "0") },
                  on: {
                    change: function ($event) {
                      _vm.status = "0"
                    },
                  },
                }),
                _vm._v(" "),
                _c("label", { staticClass: "form-check-label" }, [
                  _vm._v("Inactive"),
                ]),
              ]),
            ]),
          ]),
          _vm._v(" "),
          _c("button", {
            ref: "dummy_submit",
            staticStyle: { display: "none" },
          }),
        ]
      ),
    ]
  )
}
var staticRenderFns = []
render._withStripped = true



/***/ })

}]);