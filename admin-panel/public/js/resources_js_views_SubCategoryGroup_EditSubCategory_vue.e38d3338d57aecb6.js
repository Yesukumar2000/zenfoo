"use strict";
(self["webpackChunk"] = self["webpackChunk"] || []).push([["resources_js_views_SubCategoryGroup_EditSubCategory_vue"],{

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SubCategoryGroup/EditSubCategory.vue?vue&type=script&lang=js":
/*!*********************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SubCategoryGroup/EditSubCategory.vue?vue&type=script&lang=js ***!
  \*********************************************************************************************************************************************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
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
      status: this.record ? this.record.status : 1,
      subcategories: [],
      image: null,
      selectedSubcategories: [],
      isLoading: false,
      categoryGroups: [],
      category_group_id: this.record ? this.record.category_group_id : '' // new field
    };
  },
  computed: {
    modal_title: function modal_title() {
      return this.id ? 'Edit Subcategory Group' : 'Add Subcategory Group';
    }
  },
  created: function created() {
    this.fetchSubcategories();
    this.fetchCategoryGroups();
    if (this.record && this.record.subcategory_ids) {
      this.selectedSubcategories = this.record.subcategory_ids.split(',');
    }
  },
  methods: {
    onFileChange: function onFileChange(event) {
      this.image = event.target.files[0];
    },
    fetchSubcategories: function fetchSubcategories() {
      var _this = this;
      axios.get(this.$apiUrl + '/subcategories/all').then(function (res) {
        _this.subcategories = res.data.data;
      });
    },
    fetchCategoryGroups: function fetchCategoryGroups() {
      var _this2 = this;
      axios.get(this.$apiUrl + '/group-category').then(function (res) {
        _this2.categoryGroups = res.data.data;
      });
    },
    hideModal: function hideModal() {
      this.$refs['my-modal'].hide();
    },
    saveGroup: function saveGroup() {
      var _this3 = this;
      this.isLoading = true;
      var formData = new FormData();
      if (this.id) formData.append('id', this.id);
      formData.append('name', this.name);
      formData.append('status', this.status);
      if (this.image) formData.append('image', this.image);
      formData.append('subcategory_ids', this.selectedSubcategories.join(','));
      formData.append('category_group_id', this.category_group_id); // added here

      var url = this.id ? this.$apiUrl + '/group-sub-category/update' : this.$apiUrl + '/group-sub-category/save';
      axios.post(url, formData).then(function (res) {
        if (res.data.status === 1) {
          _this3.$emit('groupSaved', res.data.message);
          _this3.hideModal();
        } else {
          alert(res.data.message);
        }
        _this3.isLoading = false;
      })["catch"](function () {
        _this3.isLoading = false;
        alert("Something went wrong!");
      });
    }
  },
  mounted: function mounted() {
    this.$refs['my-modal'].show();
  }
});

/***/ }),

/***/ "./resources/js/views/SubCategoryGroup/EditSubCategory.vue":
/*!*****************************************************************!*\
  !*** ./resources/js/views/SubCategoryGroup/EditSubCategory.vue ***!
  \*****************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _EditSubCategory_vue_vue_type_template_id_4f3ec2b6__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./EditSubCategory.vue?vue&type=template&id=4f3ec2b6 */ "./resources/js/views/SubCategoryGroup/EditSubCategory.vue?vue&type=template&id=4f3ec2b6");
/* harmony import */ var _EditSubCategory_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./EditSubCategory.vue?vue&type=script&lang=js */ "./resources/js/views/SubCategoryGroup/EditSubCategory.vue?vue&type=script&lang=js");
/* harmony import */ var _node_modules_vue_loader_lib_runtime_componentNormalizer_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! !../../../../node_modules/vue-loader/lib/runtime/componentNormalizer.js */ "./node_modules/vue-loader/lib/runtime/componentNormalizer.js");





/* normalize component */
;
var component = (0,_node_modules_vue_loader_lib_runtime_componentNormalizer_js__WEBPACK_IMPORTED_MODULE_2__["default"])(
  _EditSubCategory_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"],
  _EditSubCategory_vue_vue_type_template_id_4f3ec2b6__WEBPACK_IMPORTED_MODULE_0__.render,
  _EditSubCategory_vue_vue_type_template_id_4f3ec2b6__WEBPACK_IMPORTED_MODULE_0__.staticRenderFns,
  false,
  null,
  null,
  null
  
)

/* hot reload */
if (false) { var api; }
component.options.__file = "resources/js/views/SubCategoryGroup/EditSubCategory.vue"
/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (component.exports);

/***/ }),

/***/ "./resources/js/views/SubCategoryGroup/EditSubCategory.vue?vue&type=script&lang=js":
/*!*****************************************************************************************!*\
  !*** ./resources/js/views/SubCategoryGroup/EditSubCategory.vue?vue&type=script&lang=js ***!
  \*****************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_5_use_0_node_modules_vue_loader_lib_index_js_vue_loader_options_EditSubCategory_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./EditSubCategory.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SubCategoryGroup/EditSubCategory.vue?vue&type=script&lang=js");
 /* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (_node_modules_babel_loader_lib_index_js_clonedRuleSet_5_use_0_node_modules_vue_loader_lib_index_js_vue_loader_options_EditSubCategory_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]); 

/***/ }),

/***/ "./resources/js/views/SubCategoryGroup/EditSubCategory.vue?vue&type=template&id=4f3ec2b6":
/*!***********************************************************************************************!*\
  !*** ./resources/js/views/SubCategoryGroup/EditSubCategory.vue?vue&type=template&id=4f3ec2b6 ***!
  \***********************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: () => (/* reexport safe */ _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_EditSubCategory_vue_vue_type_template_id_4f3ec2b6__WEBPACK_IMPORTED_MODULE_0__.render),
/* harmony export */   staticRenderFns: () => (/* reexport safe */ _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_EditSubCategory_vue_vue_type_template_id_4f3ec2b6__WEBPACK_IMPORTED_MODULE_0__.staticRenderFns)
/* harmony export */ });
/* harmony import */ var _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_EditSubCategory_vue_vue_type_template_id_4f3ec2b6__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./EditSubCategory.vue?vue&type=template&id=4f3ec2b6 */ "./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SubCategoryGroup/EditSubCategory.vue?vue&type=template&id=4f3ec2b6");


/***/ }),

/***/ "./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SubCategoryGroup/EditSubCategory.vue?vue&type=template&id=4f3ec2b6":
/*!**************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/SubCategoryGroup/EditSubCategory.vue?vue&type=template&id=4f3ec2b6 ***!
  \**************************************************************************************************************************************************************************************************************************************/
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
              _c("h5", [_vm._v(_vm._s(_vm.modal_title))]),
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
        {
          key: "modal-footer",
          fn: function () {
            return [
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
                  _vm._v("\r\n            Save\r\n            "),
                  _vm.isLoading
                    ? _c("b-spinner", {
                        attrs: { small: "", label: "Spinning" },
                      })
                    : _vm._e(),
                ],
                1
              ),
              _vm._v(" "),
              _c(
                "b-button",
                {
                  attrs: { variant: "secondary" },
                  on: { click: _vm.hideModal },
                },
                [_vm._v("Cancel")]
              ),
            ]
          },
          proxy: true,
        },
      ]),
    },
    [
      _vm._v(" "),
      _c(
        "form",
        {
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
              _c("label", [_vm._v("Category Group")]),
              _c("i", { staticClass: "text-danger" }, [_vm._v("*")]),
              _vm._v(" "),
              _c(
                "select",
                {
                  directives: [
                    {
                      name: "model",
                      rawName: "v-model",
                      value: _vm.category_group_id,
                      expression: "category_group_id",
                    },
                  ],
                  staticClass: "form-control",
                  attrs: { required: "" },
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
                      _vm.category_group_id = $event.target.multiple
                        ? $$selectedVal
                        : $$selectedVal[0]
                    },
                  },
                },
                [
                  _c("option", { attrs: { value: "" } }, [
                    _vm._v("Select Category Group"),
                  ]),
                  _vm._v(" "),
                  _vm._l(_vm.categoryGroups, function (cat) {
                    return _c(
                      "option",
                      { key: cat.id, domProps: { value: cat.id } },
                      [
                        _vm._v(
                          "\r\n                        " +
                            _vm._s(cat.name) +
                            "\r\n                    "
                        ),
                      ]
                    )
                  }),
                ],
                2
              ),
            ]),
            _vm._v(" "),
            _c("div", { staticClass: "form-group col-md-6" }, [
              _c("label", [_vm._v("Group Name")]),
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
              _c("label", [_vm._v("Image")]),
              _vm._v(" "),
              _c("input", {
                staticClass: "form-control",
                attrs: { type: "file" },
                on: { change: _vm.onFileChange },
              }),
            ]),
            _vm._v(" "),
            _c("div", { staticClass: "form-group col-12 mt-3" }, [
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
            _vm._v(" "),
            _c(
              "div",
              { staticClass: "form-group col-12 mt-3" },
              [
                _c("label", [_vm._v("Select Subcategories")]),
                _vm._v(" "),
                _vm._l(_vm.subcategories, function (sub) {
                  return _c(
                    "div",
                    { key: sub.id, staticClass: "form-check mb-1" },
                    [
                      _c("input", {
                        directives: [
                          {
                            name: "model",
                            rawName: "v-model",
                            value: _vm.selectedSubcategories,
                            expression: "selectedSubcategories",
                          },
                        ],
                        staticClass: "me-2",
                        attrs: { type: "checkbox" },
                        domProps: {
                          value: sub.id,
                          checked: Array.isArray(_vm.selectedSubcategories)
                            ? _vm._i(_vm.selectedSubcategories, sub.id) > -1
                            : _vm.selectedSubcategories,
                        },
                        on: {
                          change: function ($event) {
                            var $$a = _vm.selectedSubcategories,
                              $$el = $event.target,
                              $$c = $$el.checked ? true : false
                            if (Array.isArray($$a)) {
                              var $$v = sub.id,
                                $$i = _vm._i($$a, $$v)
                              if ($$el.checked) {
                                $$i < 0 &&
                                  (_vm.selectedSubcategories = $$a.concat([
                                    $$v,
                                  ]))
                              } else {
                                $$i > -1 &&
                                  (_vm.selectedSubcategories = $$a
                                    .slice(0, $$i)
                                    .concat($$a.slice($$i + 1)))
                              }
                            } else {
                              _vm.selectedSubcategories = $$c
                            }
                          },
                        },
                      }),
                      _vm._v(" "),
                      _c("span", { staticClass: "flex-grow-1" }, [
                        _vm._v(_vm._s(sub.name)),
                      ]),
                    ]
                  )
                }),
              ],
              2
            ),
          ]),
          _vm._v(" "),
          _c("button", {
            ref: "dummy_submit",
            staticStyle: { display: "none" },
            attrs: { type: "submit" },
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