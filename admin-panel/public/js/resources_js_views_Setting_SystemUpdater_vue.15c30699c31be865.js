"use strict";
(self["webpackChunk"] = self["webpackChunk"] || []).push([["resources_js_views_Setting_SystemUpdater_vue"],{

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Setting/SystemUpdater.vue?vue&type=script&lang=js":
/*!**********************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Setting/SystemUpdater.vue?vue&type=script&lang=js ***!
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


/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = ({
  data: function data() {
    return {
      isLoading: false,
      updaterResult: {
        version: '0.0.0'
      }
    };
  },
  computed: {
    sortOptions: function sortOptions() {
      // Create an options list from our fields
      return this.fields.filter(function (f) {
        return f.sortable;
      }).map(function (f) {
        return {
          text: f.label,
          value: f.key
        };
      });
    }
  },
  created: function created() {
    this.checkSystemRegister();
  },
  methods: {
    checkSystemRegister: function checkSystemRegister() {
      var _this = this;
      axios__WEBPACK_IMPORTED_MODULE_0___default().get(this.$apiUrl + '/store_settings/purchase_code_updater').then(function (response) {
        console.log(response.data);
        if (response.data == 1) {
          _this.checkSystemUpdate();
        }
      });
    },
    checkSystemUpdate: function checkSystemUpdate() {
      var _this2 = this;
      axios__WEBPACK_IMPORTED_MODULE_0___default().get(this.$baseUrl + '/updater.check').then(function (response) {
        var result = JSON.stringify(response.data);
        _this2.updaterResult = JSON.parse(result);
      });
    },
    systemUpdate: function systemUpdate() {
      var _this3 = this;
      this.$swal.fire({
        title: "Are you Sure?",
        text: "You want be able to revert this",
        confirmButtonText: "Yes, Sure",
        cancelButtonText: "Cancel",
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#9AC444',
        cancelButtonColor: '#d33'
      }).then(function (result) {
        if (result.value) {
          _this3.isLoading = true;
          axios__WEBPACK_IMPORTED_MODULE_0___default().get(_this3.$baseUrl + "/updater.update").then(function (response) {
            if (response != '') {
              _this3.showMessage("success", "Congratulation System Updated Successfully");
              _this3.checkSystemUpdate();
              _this3.isLoading = false;
              setTimeout(function () {
                window.location.href = _this3.$baseUrl + '/migration';
              }, 5000);
            } else {
              _this3.showMessage("error", "Something went wrong! System did not update.");
              _this3.showError("Something went wrong! System did not update.");
              _this3.isLoading = false;
            }
          });
        }
      });
    }
  }
});

/***/ }),

/***/ "./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Setting/SystemUpdater.vue?vue&type=style&index=0&id=2fc7d8ec&scoped=true&lang=css":
/*!******************************************************************************************************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Setting/SystemUpdater.vue?vue&type=style&index=0&id=2fc7d8ec&scoped=true&lang=css ***!
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
___CSS_LOADER_EXPORT___.push([module.id, "\n.page-content-wrapper[data-v-2fc7d8ec] {\r\n  min-height: calc(95vh - 200px);\r\n  display: flex;\r\n  flex-direction: column;\n}\n.page-content[data-v-2fc7d8ec] {\r\n  flex: 1;\r\n  padding-bottom: 2rem;\n}\n.card[data-v-2fc7d8ec] {\r\n  margin-bottom: 2rem;\n}\r\n\r\n/* Ensure proper spacing for footer */\n@media (min-height: 600px) {\n.page-content-wrapper[data-v-2fc7d8ec] {\r\n    min-height: calc(95vh - 150px);\n}\n}\r\n", ""]);
// Exports
/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (___CSS_LOADER_EXPORT___);


/***/ }),

/***/ "./node_modules/style-loader/dist/cjs.js!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Setting/SystemUpdater.vue?vue&type=style&index=0&id=2fc7d8ec&scoped=true&lang=css":
/*!**********************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/style-loader/dist/cjs.js!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Setting/SystemUpdater.vue?vue&type=style&index=0&id=2fc7d8ec&scoped=true&lang=css ***!
  \**********************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! !../../../../node_modules/style-loader/dist/runtime/injectStylesIntoStyleTag.js */ "./node_modules/style-loader/dist/runtime/injectStylesIntoStyleTag.js");
/* harmony import */ var _node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_SystemUpdater_vue_vue_type_style_index_0_id_2fc7d8ec_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! !!../../../../node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!../../../../node_modules/vue-loader/lib/loaders/stylePostLoader.js!../../../../node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./SystemUpdater.vue?vue&type=style&index=0&id=2fc7d8ec&scoped=true&lang=css */ "./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Setting/SystemUpdater.vue?vue&type=style&index=0&id=2fc7d8ec&scoped=true&lang=css");

            

var options = {};

options.insert = "head";
options.singleton = false;

var update = _node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0___default()(_node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_SystemUpdater_vue_vue_type_style_index_0_id_2fc7d8ec_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_1__["default"], options);



/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (_node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_SystemUpdater_vue_vue_type_style_index_0_id_2fc7d8ec_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_1__["default"].locals || {});

/***/ }),

/***/ "./resources/js/views/Setting/SystemUpdater.vue":
/*!******************************************************!*\
  !*** ./resources/js/views/Setting/SystemUpdater.vue ***!
  \******************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _SystemUpdater_vue_vue_type_template_id_2fc7d8ec_scoped_true__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./SystemUpdater.vue?vue&type=template&id=2fc7d8ec&scoped=true */ "./resources/js/views/Setting/SystemUpdater.vue?vue&type=template&id=2fc7d8ec&scoped=true");
/* harmony import */ var _SystemUpdater_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./SystemUpdater.vue?vue&type=script&lang=js */ "./resources/js/views/Setting/SystemUpdater.vue?vue&type=script&lang=js");
/* harmony import */ var _SystemUpdater_vue_vue_type_style_index_0_id_2fc7d8ec_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ./SystemUpdater.vue?vue&type=style&index=0&id=2fc7d8ec&scoped=true&lang=css */ "./resources/js/views/Setting/SystemUpdater.vue?vue&type=style&index=0&id=2fc7d8ec&scoped=true&lang=css");
/* harmony import */ var _node_modules_vue_loader_lib_runtime_componentNormalizer_js__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! !../../../../node_modules/vue-loader/lib/runtime/componentNormalizer.js */ "./node_modules/vue-loader/lib/runtime/componentNormalizer.js");



;


/* normalize component */

var component = (0,_node_modules_vue_loader_lib_runtime_componentNormalizer_js__WEBPACK_IMPORTED_MODULE_3__["default"])(
  _SystemUpdater_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"],
  _SystemUpdater_vue_vue_type_template_id_2fc7d8ec_scoped_true__WEBPACK_IMPORTED_MODULE_0__.render,
  _SystemUpdater_vue_vue_type_template_id_2fc7d8ec_scoped_true__WEBPACK_IMPORTED_MODULE_0__.staticRenderFns,
  false,
  null,
  "2fc7d8ec",
  null
  
)

/* hot reload */
if (false) { var api; }
component.options.__file = "resources/js/views/Setting/SystemUpdater.vue"
/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (component.exports);

/***/ }),

/***/ "./resources/js/views/Setting/SystemUpdater.vue?vue&type=script&lang=js":
/*!******************************************************************************!*\
  !*** ./resources/js/views/Setting/SystemUpdater.vue?vue&type=script&lang=js ***!
  \******************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_5_use_0_node_modules_vue_loader_lib_index_js_vue_loader_options_SystemUpdater_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./SystemUpdater.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Setting/SystemUpdater.vue?vue&type=script&lang=js");
 /* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (_node_modules_babel_loader_lib_index_js_clonedRuleSet_5_use_0_node_modules_vue_loader_lib_index_js_vue_loader_options_SystemUpdater_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]); 

/***/ }),

/***/ "./resources/js/views/Setting/SystemUpdater.vue?vue&type=style&index=0&id=2fc7d8ec&scoped=true&lang=css":
/*!**************************************************************************************************************!*\
  !*** ./resources/js/views/Setting/SystemUpdater.vue?vue&type=style&index=0&id=2fc7d8ec&scoped=true&lang=css ***!
  \**************************************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _node_modules_style_loader_dist_cjs_js_node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_SystemUpdater_vue_vue_type_style_index_0_id_2fc7d8ec_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/style-loader/dist/cjs.js!../../../../node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!../../../../node_modules/vue-loader/lib/loaders/stylePostLoader.js!../../../../node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./SystemUpdater.vue?vue&type=style&index=0&id=2fc7d8ec&scoped=true&lang=css */ "./node_modules/style-loader/dist/cjs.js!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Setting/SystemUpdater.vue?vue&type=style&index=0&id=2fc7d8ec&scoped=true&lang=css");


/***/ }),

/***/ "./resources/js/views/Setting/SystemUpdater.vue?vue&type=template&id=2fc7d8ec&scoped=true":
/*!************************************************************************************************!*\
  !*** ./resources/js/views/Setting/SystemUpdater.vue?vue&type=template&id=2fc7d8ec&scoped=true ***!
  \************************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: () => (/* reexport safe */ _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_SystemUpdater_vue_vue_type_template_id_2fc7d8ec_scoped_true__WEBPACK_IMPORTED_MODULE_0__.render),
/* harmony export */   staticRenderFns: () => (/* reexport safe */ _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_SystemUpdater_vue_vue_type_template_id_2fc7d8ec_scoped_true__WEBPACK_IMPORTED_MODULE_0__.staticRenderFns)
/* harmony export */ });
/* harmony import */ var _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_SystemUpdater_vue_vue_type_template_id_2fc7d8ec_scoped_true__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./SystemUpdater.vue?vue&type=template&id=2fc7d8ec&scoped=true */ "./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Setting/SystemUpdater.vue?vue&type=template&id=2fc7d8ec&scoped=true");


/***/ }),

/***/ "./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Setting/SystemUpdater.vue?vue&type=template&id=2fc7d8ec&scoped=true":
/*!***************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Setting/SystemUpdater.vue?vue&type=template&id=2fc7d8ec&scoped=true ***!
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
  return _c("div", { staticClass: "page-content-wrapper" }, [
    _c("div", { staticClass: "page-heading" }, [
      _c("div", { staticClass: "row" }, [
        _c("div", { staticClass: "col-12 col-md-6 order-md-1 order-last" }, [
          _c("h3", [_vm._v(_vm._s(_vm.__("system_updater")))]),
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
                  [_vm._v(_vm._s(_vm.__("system_updater")))]
                ),
              ]),
            ]
          ),
        ]),
      ]),
    ]),
    _vm._v(" "),
    _c("div", { staticClass: "page-content" }, [
      _c("div", { staticClass: "row" }, [
        _c("div", { staticClass: "col-6 col-md-6 order-md-1 order-last" }, [
          _vm.updaterResult && _vm.updaterResult.description
            ? _c("div", { staticClass: "card" }, [
                _c("div", { staticClass: "card-header" }, [
                  _c("h4", [
                    _vm._v(
                      _vm._s(_vm.__("change_logs_of_egrocer")) +
                        " " +
                        _vm._s("v - " + _vm.updaterResult.version) +
                        " "
                    ),
                  ]),
                  _vm._v(" "),
                  _c("span", { staticClass: "pull-right" }, [
                    _c("span", { staticClass: "badge bg-primary" }, [
                      _vm._v(
                        "\n                  " +
                          _vm._s(_vm.__("new_update_available"))
                      ),
                      _c(
                        "span",
                        {
                          staticClass:
                            "badge rounded-pill bg-success text-white ms-1",
                        },
                        [_vm._v(_vm._s("v - " + _vm.updaterResult.version))]
                      ),
                    ]),
                  ]),
                ]),
                _vm._v(" "),
                _c("div", { staticClass: "card-body" }, [
                  _c("span", {
                    attrs: { id: "update_description" },
                    domProps: {
                      innerHTML: _vm._s(_vm.updaterResult.description),
                    },
                  }),
                ]),
                _vm._v(" "),
                _c(
                  "div",
                  { staticClass: "card-footer" },
                  [
                    _c(
                      "b-button",
                      {
                        attrs: {
                          type: "button",
                          variant: "primary",
                          disabled: _vm.isLoading,
                        },
                        on: { click: _vm.systemUpdate },
                      },
                      [
                        _vm.isLoading
                          ? _c(
                              "span",
                              [
                                _c("b-spinner", {
                                  attrs: { small: "", label: "Spinning" },
                                }),
                                _vm._v(
                                  "  " + _vm._s(_vm.__("system_is_updating"))
                                ),
                              ],
                              1
                            )
                          : _c("span", [
                              _vm._v(" " + _vm._s(_vm.__("update_the_system"))),
                            ]),
                      ]
                    ),
                  ],
                  1
                ),
              ])
            : _c("div", { staticClass: "card" }, [
                _c("div", { staticClass: "card-header" }, [
                  _c("h4", [
                    _vm._v(" " + _vm._s(_vm.__("system_is_up_to_date"))),
                  ]),
                  _vm._v(" "),
                  _c("span", { staticClass: "pull-right" }, [
                    _c("span", { staticClass: "badge bg-primary" }, [
                      _vm._v(
                        "\n                " +
                          _vm._s(_vm.__("egrocer_current_version_is")) +
                          "\n                "
                      ),
                      _c(
                        "span",
                        {
                          staticClass:
                            "badge rounded-pill bg-success text-white ms-1",
                        },
                        [_vm._v(_vm._s("v - " + _vm.$currentVersion))]
                      ),
                    ]),
                  ]),
                ]),
              ]),
        ]),
      ]),
    ]),
  ])
}
var staticRenderFns = []
render._withStripped = true



/***/ })

}]);