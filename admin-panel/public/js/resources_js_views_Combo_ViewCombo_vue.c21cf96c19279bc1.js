"use strict";
(self["webpackChunk"] = self["webpackChunk"] || []).push([["resources_js_views_Combo_ViewCombo_vue"],{

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Combo/ViewCombo.vue?vue&type=script&lang=js":
/*!****************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Combo/ViewCombo.vue?vue&type=script&lang=js ***!
  \****************************************************************************************************************************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _babel_runtime_regenerator__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! @babel/runtime/regenerator */ "./node_modules/@babel/runtime/regenerator/index.js");
/* harmony import */ var _babel_runtime_regenerator__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_babel_runtime_regenerator__WEBPACK_IMPORTED_MODULE_0__);

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }
function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
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
  name: "ViewCombo",
  data: function data() {
    return {
      combo: null,
      isLoading: false
    };
  },
  created: function created() {
    this.fetchCombo();
  },
  methods: {
    fetchCombo: function fetchCombo() {
      var _this = this;
      return _asyncToGenerator( /*#__PURE__*/_babel_runtime_regenerator__WEBPACK_IMPORTED_MODULE_0___default().mark(function _callee() {
        var id, response;
        return _babel_runtime_regenerator__WEBPACK_IMPORTED_MODULE_0___default().wrap(function _callee$(_context) {
          while (1) {
            switch (_context.prev = _context.next) {
              case 0:
                id = _this.$route.params.id;
                if (id) {
                  _context.next = 3;
                  break;
                }
                return _context.abrupt("return");
              case 3:
                _this.isLoading = true;
                _context.prev = 4;
                _context.next = 7;
                return axios.get("".concat(_this.$apiUrl, "/combos/").concat(id));
              case 7:
                response = _context.sent;
                _this.combo = response.data.data;
                _context.next = 15;
                break;
              case 11:
                _context.prev = 11;
                _context.t0 = _context["catch"](4);
                console.error("Error loading combo:", _context.t0);
                _this.showMessage("error", "Failed to load combo details");
              case 15:
                _context.prev = 15;
                _this.isLoading = false;
                return _context.finish(15);
              case 18:
              case "end":
                return _context.stop();
            }
          }
        }, _callee, null, [[4, 11, 15, 18]]);
      }))();
    }
  }
});

/***/ }),

/***/ "./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Combo/ViewCombo.vue?vue&type=style&index=0&id=101249b9&scoped=true&lang=css":
/*!************************************************************************************************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Combo/ViewCombo.vue?vue&type=style&index=0&id=101249b9&scoped=true&lang=css ***!
  \************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/
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
___CSS_LOADER_EXPORT___.push([module.id, "\n.table td[data-v-101249b9],\r\n.table th[data-v-101249b9] {\r\n  vertical-align: middle;\n}\r\n", ""]);
// Exports
/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (___CSS_LOADER_EXPORT___);


/***/ }),

/***/ "./node_modules/style-loader/dist/cjs.js!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Combo/ViewCombo.vue?vue&type=style&index=0&id=101249b9&scoped=true&lang=css":
/*!****************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/style-loader/dist/cjs.js!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Combo/ViewCombo.vue?vue&type=style&index=0&id=101249b9&scoped=true&lang=css ***!
  \****************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! !../../../../node_modules/style-loader/dist/runtime/injectStylesIntoStyleTag.js */ "./node_modules/style-loader/dist/runtime/injectStylesIntoStyleTag.js");
/* harmony import */ var _node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_ViewCombo_vue_vue_type_style_index_0_id_101249b9_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! !!../../../../node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!../../../../node_modules/vue-loader/lib/loaders/stylePostLoader.js!../../../../node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./ViewCombo.vue?vue&type=style&index=0&id=101249b9&scoped=true&lang=css */ "./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Combo/ViewCombo.vue?vue&type=style&index=0&id=101249b9&scoped=true&lang=css");

            

var options = {};

options.insert = "head";
options.singleton = false;

var update = _node_modules_style_loader_dist_runtime_injectStylesIntoStyleTag_js__WEBPACK_IMPORTED_MODULE_0___default()(_node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_ViewCombo_vue_vue_type_style_index_0_id_101249b9_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_1__["default"], options);



/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (_node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_ViewCombo_vue_vue_type_style_index_0_id_101249b9_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_1__["default"].locals || {});

/***/ }),

/***/ "./resources/js/views/Combo/ViewCombo.vue":
/*!************************************************!*\
  !*** ./resources/js/views/Combo/ViewCombo.vue ***!
  \************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _ViewCombo_vue_vue_type_template_id_101249b9_scoped_true__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./ViewCombo.vue?vue&type=template&id=101249b9&scoped=true */ "./resources/js/views/Combo/ViewCombo.vue?vue&type=template&id=101249b9&scoped=true");
/* harmony import */ var _ViewCombo_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./ViewCombo.vue?vue&type=script&lang=js */ "./resources/js/views/Combo/ViewCombo.vue?vue&type=script&lang=js");
/* harmony import */ var _ViewCombo_vue_vue_type_style_index_0_id_101249b9_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ./ViewCombo.vue?vue&type=style&index=0&id=101249b9&scoped=true&lang=css */ "./resources/js/views/Combo/ViewCombo.vue?vue&type=style&index=0&id=101249b9&scoped=true&lang=css");
/* harmony import */ var _node_modules_vue_loader_lib_runtime_componentNormalizer_js__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! !../../../../node_modules/vue-loader/lib/runtime/componentNormalizer.js */ "./node_modules/vue-loader/lib/runtime/componentNormalizer.js");



;


/* normalize component */

var component = (0,_node_modules_vue_loader_lib_runtime_componentNormalizer_js__WEBPACK_IMPORTED_MODULE_3__["default"])(
  _ViewCombo_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"],
  _ViewCombo_vue_vue_type_template_id_101249b9_scoped_true__WEBPACK_IMPORTED_MODULE_0__.render,
  _ViewCombo_vue_vue_type_template_id_101249b9_scoped_true__WEBPACK_IMPORTED_MODULE_0__.staticRenderFns,
  false,
  null,
  "101249b9",
  null
  
)

/* hot reload */
if (false) { var api; }
component.options.__file = "resources/js/views/Combo/ViewCombo.vue"
/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (component.exports);

/***/ }),

/***/ "./resources/js/views/Combo/ViewCombo.vue?vue&type=script&lang=js":
/*!************************************************************************!*\
  !*** ./resources/js/views/Combo/ViewCombo.vue?vue&type=script&lang=js ***!
  \************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_5_use_0_node_modules_vue_loader_lib_index_js_vue_loader_options_ViewCombo_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./ViewCombo.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Combo/ViewCombo.vue?vue&type=script&lang=js");
 /* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (_node_modules_babel_loader_lib_index_js_clonedRuleSet_5_use_0_node_modules_vue_loader_lib_index_js_vue_loader_options_ViewCombo_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]); 

/***/ }),

/***/ "./resources/js/views/Combo/ViewCombo.vue?vue&type=style&index=0&id=101249b9&scoped=true&lang=css":
/*!********************************************************************************************************!*\
  !*** ./resources/js/views/Combo/ViewCombo.vue?vue&type=style&index=0&id=101249b9&scoped=true&lang=css ***!
  \********************************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _node_modules_style_loader_dist_cjs_js_node_modules_css_loader_dist_cjs_js_clonedRuleSet_9_use_1_node_modules_vue_loader_lib_loaders_stylePostLoader_js_node_modules_postcss_loader_dist_cjs_js_clonedRuleSet_9_use_2_node_modules_vue_loader_lib_index_js_vue_loader_options_ViewCombo_vue_vue_type_style_index_0_id_101249b9_scoped_true_lang_css__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/style-loader/dist/cjs.js!../../../../node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!../../../../node_modules/vue-loader/lib/loaders/stylePostLoader.js!../../../../node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./ViewCombo.vue?vue&type=style&index=0&id=101249b9&scoped=true&lang=css */ "./node_modules/style-loader/dist/cjs.js!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-9.use[1]!./node_modules/vue-loader/lib/loaders/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-9.use[2]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Combo/ViewCombo.vue?vue&type=style&index=0&id=101249b9&scoped=true&lang=css");


/***/ }),

/***/ "./resources/js/views/Combo/ViewCombo.vue?vue&type=template&id=101249b9&scoped=true":
/*!******************************************************************************************!*\
  !*** ./resources/js/views/Combo/ViewCombo.vue?vue&type=template&id=101249b9&scoped=true ***!
  \******************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: () => (/* reexport safe */ _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_ViewCombo_vue_vue_type_template_id_101249b9_scoped_true__WEBPACK_IMPORTED_MODULE_0__.render),
/* harmony export */   staticRenderFns: () => (/* reexport safe */ _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_ViewCombo_vue_vue_type_template_id_101249b9_scoped_true__WEBPACK_IMPORTED_MODULE_0__.staticRenderFns)
/* harmony export */ });
/* harmony import */ var _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_ViewCombo_vue_vue_type_template_id_101249b9_scoped_true__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./ViewCombo.vue?vue&type=template&id=101249b9&scoped=true */ "./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Combo/ViewCombo.vue?vue&type=template&id=101249b9&scoped=true");


/***/ }),

/***/ "./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Combo/ViewCombo.vue?vue&type=template&id=101249b9&scoped=true":
/*!*********************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/Combo/ViewCombo.vue?vue&type=template&id=101249b9&scoped=true ***!
  \*********************************************************************************************************************************************************************************************************************************/
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
          _c("h3", [_vm._v(_vm._s(_vm.combo.name))]),
          _vm._v(" "),
          _c("p", { staticClass: "text-muted mb-0" }, [
            _vm._v("View Combo Details"),
          ]),
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
                      _vm._v(_vm._s(_vm.__("manage_combos"))),
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
                        _vm._s(_vm.combo.name) +
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
      _vm._m(0),
      _vm._v(" "),
      _vm.combo
        ? _c("div", { staticClass: "card-body" }, [
            _c("div", { staticClass: "row mb-3" }, [
              _c("div", { staticClass: "col-md-4 text-center" }, [
                _vm.combo.image_url
                  ? _c("img", {
                      staticClass: "img-fluid rounded shadow-sm",
                      staticStyle: {
                        "max-height": "220px",
                        "object-fit": "cover",
                      },
                      attrs: { src: _vm.combo.image_url, alt: "Combo Image" },
                    })
                  : _c("div", { staticClass: "text-muted" }, [
                      _vm._v("No Image Available"),
                    ]),
              ]),
              _vm._v(" "),
              _c("div", { staticClass: "col-md-8" }, [
                _c("h4", { staticClass: "mb-2" }, [
                  _vm._v(_vm._s(_vm.combo.name)),
                ]),
                _vm._v(" "),
                _c("p", { staticClass: "text-muted" }, [
                  _vm._v(_vm._s(_vm.combo.description)),
                ]),
                _vm._v(" "),
                _c("ul", { staticClass: "list-group list-group-flush" }, [
                  _c("li", { staticClass: "list-group-item" }, [
                    _c("strong", [_vm._v("Price:")]),
                    _vm._v(" ₹" + _vm._s(_vm.combo.price) + "\n            "),
                  ]),
                  _vm._v(" "),
                  _c("li", { staticClass: "list-group-item" }, [
                    _c("strong", [_vm._v("Type:")]),
                    _vm._v(" " + _vm._s(_vm.combo.type) + "\n            "),
                  ]),
                  _vm._v(" "),
                  _c("li", { staticClass: "list-group-item" }, [
                    _c("strong", [_vm._v("Categories:")]),
                    _vm._v(" "),
                    _vm.combo.categories && _vm.combo.categories.length
                      ? _c(
                          "span",
                          _vm._l(_vm.combo.categories, function (cat) {
                            return _c(
                              "span",
                              {
                                key: cat.id,
                                staticClass: "badge bg-primary me-1",
                              },
                              [
                                _vm._v(
                                  "\n                  " +
                                    _vm._s(cat.name) +
                                    "\n                "
                                ),
                              ]
                            )
                          }),
                          0
                        )
                      : _c("span", { staticClass: "text-muted" }, [
                          _vm._v("No categories"),
                        ]),
                  ]),
                ]),
              ]),
            ]),
            _vm._v(" "),
            _vm.combo.products && _vm.combo.products.length
              ? _c("div", [
                  _c("h5", { staticClass: "mt-4" }, [
                    _vm._v("Included Products"),
                  ]),
                  _vm._v(" "),
                  _c(
                    "table",
                    { staticClass: "table table-striped table-bordered mt-2" },
                    [
                      _vm._m(1),
                      _vm._v(" "),
                      _c(
                        "tbody",
                        _vm._l(_vm.combo.products, function (product, index) {
                          return _c("tr", { key: product.id }, [
                            _c("td", [_vm._v(_vm._s(index + 1))]),
                            _vm._v(" "),
                            _c("td", [_vm._v(_vm._s(product.name))]),
                            _vm._v(" "),
                            _c("td", [
                              product.image_url
                                ? _c("img", {
                                    staticClass: "rounded",
                                    attrs: {
                                      src: product.image_url,
                                      height: "50",
                                      width: "50",
                                    },
                                  })
                                : _vm._e(),
                            ]),
                            _vm._v(" "),
                            _c("td", [_vm._v("₹" + _vm._s(product.price))]),
                          ])
                        }),
                        0
                      ),
                    ]
                  ),
                ])
              : _c("div", { staticClass: "text-muted mt-3" }, [
                  _c("i", [_vm._v("No products added to this combo.")]),
                ]),
          ])
        : _c("div", { staticClass: "card-body" }, [
            _c(
              "div",
              { staticClass: "text-center" },
              [
                _c("b-spinner", { attrs: { label: "Loading..." } }),
                _vm._v(" "),
                _c("p", [_vm._v("Loading combo details...")]),
              ],
              1
            ),
          ]),
    ]),
    _vm._v(" "),
    _c(
      "div",
      { staticClass: "mt-3" },
      [
        _c(
          "router-link",
          { staticClass: "btn btn-secondary", attrs: { to: "/manage_combos" } },
          [
            _c("i", { staticClass: "fa fa-arrow-left" }),
            _vm._v(" Back to Combos\n    "),
          ]
        ),
      ],
      1
    ),
  ])
}
var staticRenderFns = [
  function () {
    var _vm = this
    var _h = _vm.$createElement
    var _c = _vm._self._c || _h
    return _c("div", { staticClass: "card-header" }, [
      _c("h4", [_vm._v("Combo Information")]),
    ])
  },
  function () {
    var _vm = this
    var _h = _vm.$createElement
    var _c = _vm._self._c || _h
    return _c("thead", [
      _c("tr", [
        _c("th", [_vm._v("#")]),
        _vm._v(" "),
        _c("th", [_vm._v("Product Name")]),
        _vm._v(" "),
        _c("th", [_vm._v("Image")]),
        _vm._v(" "),
        _c("th", [_vm._v("Price")]),
      ]),
    ])
  },
]
render._withStripped = true



/***/ })

}]);