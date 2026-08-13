"use strict";
(self["webpackChunk"] = self["webpackChunk"] || []).push([["resources_js_views_City_EditCity_vue"],{

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/City/EditCity.vue?vue&type=script&lang=js":
/*!**************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/City/EditCity.vue?vue&type=script&lang=js ***!
  \**************************************************************************************************************************************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var axios__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! axios */ "./node_modules/axios/index.js");
/* harmony import */ var axios__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(axios__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var vue2_google_maps__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! vue2-google-maps */ "./node_modules/vue2-google-maps/dist/main.js");
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
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
      city: {
        id: "",
        latitude: "",
        longitude: "",
        name: "",
        state: "",
        zone: "",
        formatted_address: "",
        time_to_travel: "",
        min_amount_for_free_delivery: "",
        max_deliverable_distance: "",
        delivery_charge_method: "",
        fixed_charge: "",
        per_km_charge: "",
        range_wise_charges: [{
          from_range: "",
          to_range: "",
          price: ""
        }],
        boundary_points: "",
        geolocation_type: "",
        radius: ""
      },
      markers: [],
      center: {
        lat: 0,
        lng: 0
      },
      infoWindow: {
        position: {
          lat: 0,
          lng: 0
        },
        open: false,
        template: ""
      },
      vertices: "",
      drawingManager: null,
      map: null,
      googleMapsLoaded: false
    };
  },
  mounted: function mounted() {
    var _this = this;
    this.$refs.mapRef.$mapPromise.then(function (map) {
      _this.map = map;

      // Set initial map center
      var defaultCenter = {
        lat: parseFloat(_this.city.latitude) || 17.4486,
        lng: parseFloat(_this.city.longitude) || 78.3908
      };
      _this.center = defaultCenter;
      _this.markers = [{
        position: defaultCenter
      }];
      _this.infoWindow = {
        position: defaultCenter,
        template: "<b>".concat(_this.city.name || "Default City", "</b><br>").concat(_this.city.formatted_address || "Address"),
        open: true
      };

      // ✅ Wait for the Drawing library before initializing
      var waitForDrawingLib = setInterval(function () {
        if (window.google && google.maps && google.maps.drawing) {
          clearInterval(waitForDrawingLib);
          _this.initDrawingManager(); // initialize drawing
          if (_this.city.boundary_points) {
            _this.setMapOverlay(); // restore previous shapes
          }
        }
      }, 300);
    });
  },
  computed: {
    google: function google() {
      return (0,vue2_google_maps__WEBPACK_IMPORTED_MODULE_1__.gmapApi)();
    }
  },
  created: function created() {
    this.city.id = this.$route.params.id;
    if (this.city.id) {
      this.getCity();
    }
  },
  methods: {
    addRange: function addRange() {
      this.city.range_wise_charges.push({
        from_range: "",
        to_range: "",
        price: ""
      });
    },
    removeRange: function removeRange(index) {
      this.city.range_wise_charges.splice(index, 1);
    },
    setPlace: function setPlace(place) {
      if (!place || !place.geometry) return;
      this.city.latitude = place.geometry.location.lat();
      this.city.longitude = place.geometry.location.lng();
      this.city.name = place.name;
      this.city.formatted_address = place.formatted_address;
      var addr = place.formatted_address.split(",");
      this.city.state = addr[addr.length - 2] || "";
      this.center = {
        lat: this.city.latitude,
        lng: this.city.longitude
      };
      this.markers = [{
        position: this.center
      }];
      this.infoWindow = {
        position: this.center,
        open: true,
        template: "<b>".concat(this.city.name, "</b><br>").concat(this.city.formatted_address)
      };
    },
    getCity: function getCity() {
      var _this2 = this;
      axios__WEBPACK_IMPORTED_MODULE_0___default().get("".concat(this.$apiUrl, "/cities/edit/").concat(this.city.id)).then(function (res) {
        var data = res.data.data;
        Object.keys(_this2.city).forEach(function (key) {
          if (key === "range_wise_charges") {
            _this2.city[key] = JSON.parse(data[key]);
          } else {
            _this2.city[key] = data[key];
          }
        });
        _this2.center = {
          lat: parseFloat(data.latitude),
          lng: parseFloat(data.longitude)
        };
        _this2.markers = [{
          position: _this2.center
        }];
        _this2.infoWindow = {
          position: _this2.center,
          open: true,
          template: "<b>".concat(data.name, "</b><br>").concat(data.formatted_address)
        };
        _this2.vertices = _this2.city.boundary_points;
      });
    },
    // ✅ Initialize drawing manager
    initDrawingManager: function initDrawingManager() {
      var _this3 = this;
      var google = window.google;
      if (!google || !google.maps || !google.maps.drawing) {
        console.warn("Google Drawing library not yet loaded.");
        return;
      }
      this.drawingManager = new google.maps.drawing.DrawingManager({
        drawingMode: google.maps.drawing.OverlayType.POLYGON,
        drawingControl: true,
        drawingControlOptions: {
          position: google.maps.ControlPosition.TOP_CENTER,
          drawingModes: [google.maps.drawing.OverlayType.POLYGON, google.maps.drawing.OverlayType.CIRCLE]
        },
        polygonOptions: {
          editable: true
        },
        circleOptions: {
          editable: true,
          fillOpacity: 0.3,
          strokeWeight: 2
        }
      });
      this.drawingManager.setMap(this.map);
      google.maps.event.addListener(this.drawingManager, "overlaycomplete", function (event) {
        if (event.type === "circle") {
          var center = event.overlay.getCenter();
          _this3.vertices = JSON.stringify([{
            lat: center.lat(),
            lng: center.lng()
          }]);
          _this3.radius = event.overlay.getRadius();
          _this3.geolocation_type = "circle";
          _this3.city.boundary_points = _this3.vertices;
          _this3.city.radius = _this3.radius;
          _this3.city.geolocation_type = "circle";
        } else if (event.type === "polygon") {
          var path = event.overlay.getPath().getArray().map(function (latlng) {
            return {
              lat: latlng.lat(),
              lng: latlng.lng()
            };
          });
          _this3.vertices = JSON.stringify(path);
          _this3.geolocation_type = "polygon";
          _this3.city.boundary_points = _this3.vertices;
          _this3.city.geolocation_type = "polygon";
        }
      });
    },
    setMapOverlay: function setMapOverlay() {
      var google = window.google;
      if (!google || !this.vertices) return;
      var points = JSON.parse(this.vertices);
      if (this.city.geolocation_type === "polygon") {
        var polygon = new google.maps.Polygon({
          paths: points,
          strokeColor: "#FF0000",
          fillColor: "#FF0000",
          fillOpacity: 0.3,
          editable: true,
          map: this.map
        });
      } else if (this.city.geolocation_type === "circle") {
        var circle = new google.maps.Circle({
          center: points[0],
          radius: Number(this.city.radius),
          strokeColor: "#FF0000",
          fillColor: "#FF0000",
          fillOpacity: 0.3,
          editable: true,
          map: this.map
        });
      }
    },
    clearOverlay: function clearOverlay() {
      this.vertices = "";
      this.city.boundary_points = "";
      this.geolocation_type = "";
      if (this.drawingManager) this.drawingManager.setMap(null);
      this.initDrawingManager();
    },
    restoreOverlay: function restoreOverlay() {
      if (this.city.boundary_points) {
        this.vertices = this.city.boundary_points;
        this.setMapOverlay();
      }
    },
    saveRecord: function saveRecord() {
      var _this4 = this;
      if (!this.vertices) return alert("Draw Deliverable area on Map");
      var formData = new FormData();
      Object.keys(this.city).forEach(function (key) {
        if (key === "range_wise_charges") {
          formData.append(key, JSON.stringify(_this4.city[key]));
        } else {
          formData.append(key, _this4.city[key]);
        }
      });
      formData.append("geolocation_type", this.geolocation_type);
      formData.append("radius", this.radius);
      formData.append("boundary_points", this.vertices);
      var url = this.city.id ? "".concat(this.$apiUrl, "/cities/update") : "".concat(this.$apiUrl, "/cities/save");
      axios__WEBPACK_IMPORTED_MODULE_0___default().post(url, formData).then(function (res) {
        alert(res.data.message);
        if (res.data.status === 1) _this4.$router.push("/cities");
      });
    }
  }
});

/***/ }),

/***/ "./resources/js/views/City/EditCity.vue":
/*!**********************************************!*\
  !*** ./resources/js/views/City/EditCity.vue ***!
  \**********************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _EditCity_vue_vue_type_template_id_a8c9b86c__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./EditCity.vue?vue&type=template&id=a8c9b86c */ "./resources/js/views/City/EditCity.vue?vue&type=template&id=a8c9b86c");
/* harmony import */ var _EditCity_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./EditCity.vue?vue&type=script&lang=js */ "./resources/js/views/City/EditCity.vue?vue&type=script&lang=js");
/* harmony import */ var _node_modules_vue_loader_lib_runtime_componentNormalizer_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! !../../../../node_modules/vue-loader/lib/runtime/componentNormalizer.js */ "./node_modules/vue-loader/lib/runtime/componentNormalizer.js");





/* normalize component */
;
var component = (0,_node_modules_vue_loader_lib_runtime_componentNormalizer_js__WEBPACK_IMPORTED_MODULE_2__["default"])(
  _EditCity_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"],
  _EditCity_vue_vue_type_template_id_a8c9b86c__WEBPACK_IMPORTED_MODULE_0__.render,
  _EditCity_vue_vue_type_template_id_a8c9b86c__WEBPACK_IMPORTED_MODULE_0__.staticRenderFns,
  false,
  null,
  null,
  null
  
)

/* hot reload */
if (false) { var api; }
component.options.__file = "resources/js/views/City/EditCity.vue"
/* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (component.exports);

/***/ }),

/***/ "./resources/js/views/City/EditCity.vue?vue&type=script&lang=js":
/*!**********************************************************************!*\
  !*** ./resources/js/views/City/EditCity.vue?vue&type=script&lang=js ***!
  \**********************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": () => (__WEBPACK_DEFAULT_EXPORT__)
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_5_use_0_node_modules_vue_loader_lib_index_js_vue_loader_options_EditCity_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./EditCity.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-5.use[0]!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/City/EditCity.vue?vue&type=script&lang=js");
 /* harmony default export */ const __WEBPACK_DEFAULT_EXPORT__ = (_node_modules_babel_loader_lib_index_js_clonedRuleSet_5_use_0_node_modules_vue_loader_lib_index_js_vue_loader_options_EditCity_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]); 

/***/ }),

/***/ "./resources/js/views/City/EditCity.vue?vue&type=template&id=a8c9b86c":
/*!****************************************************************************!*\
  !*** ./resources/js/views/City/EditCity.vue?vue&type=template&id=a8c9b86c ***!
  \****************************************************************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: () => (/* reexport safe */ _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_EditCity_vue_vue_type_template_id_a8c9b86c__WEBPACK_IMPORTED_MODULE_0__.render),
/* harmony export */   staticRenderFns: () => (/* reexport safe */ _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_EditCity_vue_vue_type_template_id_a8c9b86c__WEBPACK_IMPORTED_MODULE_0__.staticRenderFns)
/* harmony export */ });
/* harmony import */ var _node_modules_vue_loader_lib_loaders_templateLoader_js_vue_loader_options_node_modules_vue_loader_lib_index_js_vue_loader_options_EditCity_vue_vue_type_template_id_a8c9b86c__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!../../../../node_modules/vue-loader/lib/index.js??vue-loader-options!./EditCity.vue?vue&type=template&id=a8c9b86c */ "./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/City/EditCity.vue?vue&type=template&id=a8c9b86c");


/***/ }),

/***/ "./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/City/EditCity.vue?vue&type=template&id=a8c9b86c":
/*!*******************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/vue-loader/lib/loaders/templateLoader.js??vue-loader-options!./node_modules/vue-loader/lib/index.js??vue-loader-options!./resources/js/views/City/EditCity.vue?vue&type=template&id=a8c9b86c ***!
  \*******************************************************************************************************************************************************************************************************************/
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
          _c("h3", [_vm._v(_vm._s(_vm.__("manage_city")))]),
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
                    _vm.city.id
                      ? [_vm._v(_vm._s(_vm.__("edit")))]
                      : [_vm._v(_vm._s(_vm.__("create")))],
                    _vm._v(
                      "\n              " +
                        _vm._s(_vm.__("city")) +
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
      _vm._v(" "),
      _c("div", { staticClass: "row" }, [
        _c("div", { staticClass: "col-md-6 col-sm-12 order-md-1 order-last" }, [
          _c("div", { staticClass: "card h-100" }, [
            _c("div", { staticClass: "card-header" }, [
              _c(
                "h4",
                [
                  _vm.city.id
                    ? [_vm._v(_vm._s(_vm.__("edit")))]
                    : [_vm._v(_vm._s(_vm.__("create")))],
                  _vm._v(
                    "\n              " +
                      _vm._s(_vm.__("city")) +
                      "\n            "
                  ),
                ],
                2
              ),
            ]),
            _vm._v(" "),
            _c("div", { staticClass: "card-body" }, [
              _c(
                "form",
                {
                  ref: "cityForm",
                  on: {
                    submit: function ($event) {
                      $event.preventDefault()
                      return _vm.saveRecord.apply(null, arguments)
                    },
                  },
                },
                [
                  _c(
                    "div",
                    { staticClass: "form-group" },
                    [
                      _c("label", { attrs: { for: "city_name" } }, [
                        _vm._v(_vm._s(_vm.__("search_city"))),
                      ]),
                      _vm._v(" "),
                      _c("GmapAutocomplete", {
                        staticClass: "form-control",
                        attrs: {
                          placeholder: "Search City on map.",
                          options: {
                            fields: [
                              "address_components",
                              "formatted_address",
                              "geometry",
                              "name",
                              "place_id",
                              "types",
                            ],
                            strictBounds: false,
                          },
                          id: "city_name",
                        },
                        on: { place_changed: _vm.setPlace },
                      }),
                      _vm._v(" "),
                      _c("input", {
                        directives: [
                          {
                            name: "model",
                            rawName: "v-model",
                            value: _vm.city.formatted_address,
                            expression: "city.formatted_address",
                          },
                        ],
                        attrs: { type: "hidden" },
                        domProps: { value: _vm.city.formatted_address },
                        on: {
                          input: function ($event) {
                            if ($event.target.composing) {
                              return
                            }
                            _vm.$set(
                              _vm.city,
                              "formatted_address",
                              $event.target.value
                            )
                          },
                        },
                      }),
                      _vm._v(" "),
                      _c("small", { staticClass: "text-primary" }, [
                        _vm._v(
                          "\n                  " +
                            _vm._s(
                              _vm.__(
                                "search_your_city_where_you_will_deliver_the_food_and_to_find_co_ordinates"
                              )
                            ) +
                            "\n                "
                        ),
                      ]),
                    ],
                    1
                  ),
                  _vm._v(" "),
                  _c("div", { staticClass: "form-group" }, [
                    _c("label", [
                      _vm._v(_vm._s(_vm.__("latitude")) + " "),
                      _c("span", { staticClass: "text-danger" }, [_vm._v("*")]),
                    ]),
                    _vm._v(" "),
                    _c("input", {
                      directives: [
                        {
                          name: "model",
                          rawName: "v-model",
                          value: _vm.city.latitude,
                          expression: "city.latitude",
                        },
                      ],
                      staticClass: "form-control",
                      attrs: { type: "text", readonly: "", required: "" },
                      domProps: { value: _vm.city.latitude },
                      on: {
                        input: function ($event) {
                          if ($event.target.composing) {
                            return
                          }
                          _vm.$set(_vm.city, "latitude", $event.target.value)
                        },
                      },
                    }),
                  ]),
                  _vm._v(" "),
                  _c("div", { staticClass: "form-group" }, [
                    _c("label", [
                      _vm._v(_vm._s(_vm.__("longitude")) + " "),
                      _c("span", { staticClass: "text-danger" }, [_vm._v("*")]),
                    ]),
                    _vm._v(" "),
                    _c("input", {
                      directives: [
                        {
                          name: "model",
                          rawName: "v-model",
                          value: _vm.city.longitude,
                          expression: "city.longitude",
                        },
                      ],
                      staticClass: "form-control",
                      attrs: { type: "text", readonly: "", required: "" },
                      domProps: { value: _vm.city.longitude },
                      on: {
                        input: function ($event) {
                          if ($event.target.composing) {
                            return
                          }
                          _vm.$set(_vm.city, "longitude", $event.target.value)
                        },
                      },
                    }),
                  ]),
                  _vm._v(" "),
                  _c("div", { staticClass: "form-group" }, [
                    _c("label", [
                      _vm._v(_vm._s(_vm.__("city_name")) + " "),
                      _c("span", { staticClass: "text-danger" }, [_vm._v("*")]),
                    ]),
                    _vm._v(" "),
                    _c("input", {
                      directives: [
                        {
                          name: "model",
                          rawName: "v-model",
                          value: _vm.city.name,
                          expression: "city.name",
                        },
                      ],
                      staticClass: "form-control",
                      attrs: { type: "text", readonly: "", required: "" },
                      domProps: { value: _vm.city.name },
                      on: {
                        input: function ($event) {
                          if ($event.target.composing) {
                            return
                          }
                          _vm.$set(_vm.city, "name", $event.target.value)
                        },
                      },
                    }),
                  ]),
                  _vm._v(" "),
                  _c("div", { staticClass: "form-group" }, [
                    _c("label", [
                      _vm._v(_vm._s(_vm.__("state_name")) + " "),
                      _c("span", { staticClass: "text-danger" }, [_vm._v("*")]),
                    ]),
                    _vm._v(" "),
                    _c("input", {
                      directives: [
                        {
                          name: "model",
                          rawName: "v-model",
                          value: _vm.city.state,
                          expression: "city.state",
                        },
                      ],
                      staticClass: "form-control",
                      attrs: { type: "text", readonly: "", required: "" },
                      domProps: { value: _vm.city.state },
                      on: {
                        input: function ($event) {
                          if ($event.target.composing) {
                            return
                          }
                          _vm.$set(_vm.city, "state", $event.target.value)
                        },
                      },
                    }),
                  ]),
                  _vm._v(" "),
                  _c("div", { staticClass: "form-group" }, [
                    _c("label", [
                      _vm._v(_vm._s(_vm.__("zone_name")) + " "),
                      _c("span", { staticClass: "text-danger" }, [_vm._v("*")]),
                    ]),
                    _vm._v(" "),
                    _c("input", {
                      directives: [
                        {
                          name: "model",
                          rawName: "v-model",
                          value: _vm.city.zone,
                          expression: "city.zone",
                        },
                      ],
                      staticClass: "form-control",
                      attrs: { type: "text", required: "" },
                      domProps: { value: _vm.city.zone },
                      on: {
                        input: function ($event) {
                          if ($event.target.composing) {
                            return
                          }
                          _vm.$set(_vm.city, "zone", $event.target.value)
                        },
                      },
                    }),
                  ]),
                  _vm._v(" "),
                  _c("div", { staticClass: "form-group" }, [
                    _c("label", [
                      _vm._v(_vm._s(_vm.__("time_to_travel_1km")) + " "),
                      _c("span", { staticClass: "text-danger" }, [_vm._v("*")]),
                    ]),
                    _vm._v(" "),
                    _c("input", {
                      directives: [
                        {
                          name: "model",
                          rawName: "v-model",
                          value: _vm.city.time_to_travel,
                          expression: "city.time_to_travel",
                        },
                      ],
                      staticClass: "form-control",
                      attrs: {
                        type: "number",
                        min: "0",
                        max: "999999999",
                        required: "",
                      },
                      domProps: { value: _vm.city.time_to_travel },
                      on: {
                        input: function ($event) {
                          if ($event.target.composing) {
                            return
                          }
                          _vm.$set(
                            _vm.city,
                            "time_to_travel",
                            $event.target.value
                          )
                        },
                      },
                    }),
                  ]),
                  _vm._v(" "),
                  _c("div", { staticClass: "form-group" }, [
                    _c("label", [
                      _vm._v(
                        _vm._s(_vm.__("minimum_amount_for_free_delivery")) + " "
                      ),
                      _c("span", { staticClass: "text-danger" }, [_vm._v("*")]),
                    ]),
                    _vm._v(" "),
                    _c("input", {
                      directives: [
                        {
                          name: "model",
                          rawName: "v-model",
                          value: _vm.city.min_amount_for_free_delivery,
                          expression: "city.min_amount_for_free_delivery",
                        },
                      ],
                      staticClass: "form-control",
                      attrs: {
                        type: "number",
                        min: "0",
                        max: "999999999",
                        required: "",
                      },
                      domProps: {
                        value: _vm.city.min_amount_for_free_delivery,
                      },
                      on: {
                        input: function ($event) {
                          if ($event.target.composing) {
                            return
                          }
                          _vm.$set(
                            _vm.city,
                            "min_amount_for_free_delivery",
                            $event.target.value
                          )
                        },
                      },
                    }),
                  ]),
                  _vm._v(" "),
                  _c("div", { staticClass: "form-group d-none" }, [
                    _c("label", [
                      _vm._v(
                        _vm._s(_vm.__("maximum_delivarable_distance")) + " "
                      ),
                      _c("span", { staticClass: "text-danger" }, [_vm._v("*")]),
                    ]),
                    _vm._v(" "),
                    _c("input", {
                      directives: [
                        {
                          name: "model",
                          rawName: "v-model",
                          value: _vm.city.max_deliverable_distance,
                          expression: "city.max_deliverable_distance",
                        },
                      ],
                      staticClass: "form-control",
                      attrs: { type: "number", min: "0", max: "999999999" },
                      domProps: { value: _vm.city.max_deliverable_distance },
                      on: {
                        input: function ($event) {
                          if ($event.target.composing) {
                            return
                          }
                          _vm.$set(
                            _vm.city,
                            "max_deliverable_distance",
                            $event.target.value
                          )
                        },
                      },
                    }),
                  ]),
                  _vm._v(" "),
                  _c("div", { staticClass: "form-group" }, [
                    _c("label", [
                      _vm._v(_vm._s(_vm.__("delivery_charge_methods")) + " "),
                      _c("span", { staticClass: "text-danger" }, [_vm._v("*")]),
                    ]),
                    _vm._v(" "),
                    _c(
                      "select",
                      {
                        directives: [
                          {
                            name: "model",
                            rawName: "v-model",
                            value: _vm.city.delivery_charge_method,
                            expression: "city.delivery_charge_method",
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
                            _vm.$set(
                              _vm.city,
                              "delivery_charge_method",
                              $event.target.multiple
                                ? $$selectedVal
                                : $$selectedVal[0]
                            )
                          },
                        },
                      },
                      [
                        _c("option", { attrs: { value: "" } }, [
                          _vm._v(_vm._s(_vm.__("select_method"))),
                        ]),
                        _vm._v(" "),
                        _c("option", { attrs: { value: "fixed_charge" } }, [
                          _vm._v(_vm._s(_vm.__("fixed_delivery_charges"))),
                        ]),
                        _vm._v(" "),
                        _c("option", { attrs: { value: "per_km_charge" } }, [
                          _vm._v(_vm._s(_vm.__("per_km_delivery_charges"))),
                        ]),
                        _vm._v(" "),
                        _c(
                          "option",
                          { attrs: { value: "range_wise_charges" } },
                          [
                            _vm._v(
                              _vm._s(_vm.__("range_wise_delivery_charges"))
                            ),
                          ]
                        ),
                      ]
                    ),
                  ]),
                  _vm._v(" "),
                  _vm.city.delivery_charge_method === "fixed_charge"
                    ? _c("div", { staticClass: "form-group" }, [
                        _c("label", [
                          _vm._v(_vm._s(_vm.__("fix_delivery_charges")) + " "),
                          _c("span", { staticClass: "text-danger" }, [
                            _vm._v("*"),
                          ]),
                        ]),
                        _vm._v(" "),
                        _c("input", {
                          directives: [
                            {
                              name: "model",
                              rawName: "v-model",
                              value: _vm.city.fixed_charge,
                              expression: "city.fixed_charge",
                            },
                          ],
                          staticClass: "form-control",
                          attrs: { type: "number", min: "0", step: "any" },
                          domProps: { value: _vm.city.fixed_charge },
                          on: {
                            input: function ($event) {
                              if ($event.target.composing) {
                                return
                              }
                              _vm.$set(
                                _vm.city,
                                "fixed_charge",
                                $event.target.value
                              )
                            },
                          },
                        }),
                      ])
                    : _vm._e(),
                  _vm._v(" "),
                  _vm.city.delivery_charge_method === "per_km_charge"
                    ? _c("div", { staticClass: "form-group" }, [
                        _c("label", [
                          _vm._v(
                            _vm._s(_vm.__("per_km_delivery_charges")) + " "
                          ),
                          _c("span", { staticClass: "text-danger" }, [
                            _vm._v("*"),
                          ]),
                        ]),
                        _vm._v(" "),
                        _c("input", {
                          directives: [
                            {
                              name: "model",
                              rawName: "v-model",
                              value: _vm.city.per_km_charge,
                              expression: "city.per_km_charge",
                            },
                          ],
                          staticClass: "form-control",
                          attrs: { type: "number", min: "0", step: "any" },
                          domProps: { value: _vm.city.per_km_charge },
                          on: {
                            input: function ($event) {
                              if ($event.target.composing) {
                                return
                              }
                              _vm.$set(
                                _vm.city,
                                "per_km_charge",
                                $event.target.value
                              )
                            },
                          },
                        }),
                        _vm._v(" "),
                        _c("input", {
                          directives: [
                            {
                              name: "model",
                              rawName: "v-model",
                              value: _vm.city.boundary_points,
                              expression: "city.boundary_points",
                            },
                          ],
                          attrs: { type: "hidden" },
                          domProps: { value: _vm.city.boundary_points },
                          on: {
                            input: function ($event) {
                              if ($event.target.composing) {
                                return
                              }
                              _vm.$set(
                                _vm.city,
                                "boundary_points",
                                $event.target.value
                              )
                            },
                          },
                        }),
                      ])
                    : _vm._e(),
                  _vm._v(" "),
                  _vm.city.delivery_charge_method === "range_wise_charges"
                    ? _c(
                        "div",
                        { staticClass: "form-group" },
                        [
                          _c("label", [
                            _vm._v(
                              _vm._s(_vm.__("range_wise_delivery_charges"))
                            ),
                          ]),
                          _vm._v(" "),
                          _vm._l(
                            _vm.city.range_wise_charges,
                            function (range, index) {
                              return _c(
                                "div",
                                { key: index, staticClass: "row mb-2" },
                                [
                                  _c("div", { staticClass: "col-3" }, [
                                    _c("input", {
                                      directives: [
                                        {
                                          name: "model",
                                          rawName: "v-model",
                                          value: range.from_range,
                                          expression: "range.from_range",
                                        },
                                      ],
                                      staticClass: "form-control",
                                      attrs: {
                                        type: "number",
                                        placeholder: "From",
                                      },
                                      domProps: { value: range.from_range },
                                      on: {
                                        input: function ($event) {
                                          if ($event.target.composing) {
                                            return
                                          }
                                          _vm.$set(
                                            range,
                                            "from_range",
                                            $event.target.value
                                          )
                                        },
                                      },
                                    }),
                                  ]),
                                  _vm._v(" "),
                                  _c("div", { staticClass: "col-3" }, [
                                    _c("input", {
                                      directives: [
                                        {
                                          name: "model",
                                          rawName: "v-model",
                                          value: range.to_range,
                                          expression: "range.to_range",
                                        },
                                      ],
                                      staticClass: "form-control",
                                      attrs: {
                                        type: "number",
                                        placeholder: "To",
                                      },
                                      domProps: { value: range.to_range },
                                      on: {
                                        input: function ($event) {
                                          if ($event.target.composing) {
                                            return
                                          }
                                          _vm.$set(
                                            range,
                                            "to_range",
                                            $event.target.value
                                          )
                                        },
                                      },
                                    }),
                                  ]),
                                  _vm._v(" "),
                                  _c("div", { staticClass: "col-3" }, [
                                    _c("input", {
                                      directives: [
                                        {
                                          name: "model",
                                          rawName: "v-model",
                                          value: range.price,
                                          expression: "range.price",
                                        },
                                      ],
                                      staticClass: "form-control",
                                      attrs: {
                                        type: "number",
                                        placeholder: "Price",
                                        step: "any",
                                      },
                                      domProps: { value: range.price },
                                      on: {
                                        input: function ($event) {
                                          if ($event.target.composing) {
                                            return
                                          }
                                          _vm.$set(
                                            range,
                                            "price",
                                            $event.target.value
                                          )
                                        },
                                      },
                                    }),
                                  ]),
                                  _vm._v(" "),
                                  _c("div", { staticClass: "col-3" }, [
                                    index !== 0
                                      ? _c(
                                          "button",
                                          {
                                            staticClass: "btn btn-danger",
                                            attrs: { type: "button" },
                                            on: {
                                              click: function ($event) {
                                                return _vm.removeRange(index)
                                              },
                                            },
                                          },
                                          [_vm._v("Remove")]
                                        )
                                      : _vm._e(),
                                    _vm._v(" "),
                                    index === 0
                                      ? _c(
                                          "button",
                                          {
                                            staticClass: "btn btn-success",
                                            attrs: { type: "button" },
                                            on: { click: _vm.addRange },
                                          },
                                          [_vm._v("Add")]
                                        )
                                      : _vm._e(),
                                  ]),
                                ]
                              )
                            }
                          ),
                        ],
                        2
                      )
                    : _vm._e(),
                  _vm._v(" "),
                  _c("div", { staticClass: "form-group" }, [
                    _c(
                      "button",
                      {
                        staticClass: "btn btn-primary",
                        attrs: { type: "submit" },
                      },
                      [_vm._v(_vm._s(_vm.__("save")))]
                    ),
                    _vm._v(" "),
                    _c(
                      "button",
                      {
                        staticClass: "btn btn-secondary",
                        attrs: { type: "reset" },
                      },
                      [_vm._v(_vm._s(_vm.__("clear")))]
                    ),
                  ]),
                ]
              ),
            ]),
          ]),
        ]),
        _vm._v(" "),
        _c(
          "div",
          {
            staticClass:
              "col-md-6 col-sm-12 order-md-1 order-last map_view_desktop",
          },
          [
            _c("div", { staticClass: "card h-100" }, [
              _vm._m(0),
              _vm._v(" "),
              _c(
                "div",
                { staticClass: "card-body" },
                [
                  _c("div", { staticClass: "mb-2" }, [
                    _c(
                      "button",
                      {
                        staticClass: "badge bg-danger",
                        on: { click: _vm.clearOverlay },
                      },
                      [_vm._v("Clear Map")]
                    ),
                    _vm._v(" "),
                    _c(
                      "button",
                      {
                        staticClass: "badge bg-success",
                        on: { click: _vm.restoreOverlay },
                      },
                      [_vm._v("Restore Map")]
                    ),
                  ]),
                  _vm._v(" "),
                  _c(
                    "GmapMap",
                    {
                      ref: "mapRef",
                      staticStyle: { width: "100%", height: "700px" },
                      attrs: {
                        center: _vm.center,
                        zoom: 13,
                        "map-type-control": true,
                      },
                    },
                    [
                      _vm._l(_vm.markers, function (m, index) {
                        return _c("GmapMarker", {
                          key: index,
                          attrs: { position: m.position, draggable: true },
                          on: {
                            click: function ($event) {
                              _vm.center = m.position
                            },
                          },
                        })
                      }),
                      _vm._v(" "),
                      _c(
                        "GmapInfoWindow",
                        {
                          attrs: {
                            position: _vm.infoWindow.position,
                            opened: _vm.infoWindow.open,
                          },
                          on: {
                            closeclick: function ($event) {
                              _vm.infoWindow.open = false
                            },
                          },
                        },
                        [
                          _c("div", {
                            domProps: {
                              innerHTML: _vm._s(_vm.infoWindow.template),
                            },
                          }),
                        ]
                      ),
                    ],
                    2
                  ),
                  _vm._v(" "),
                  _c("textarea", {
                    directives: [
                      {
                        name: "model",
                        rawName: "v-model",
                        value: _vm.vertices,
                        expression: "vertices",
                      },
                    ],
                    staticClass: "form-control mt-2",
                    attrs: {
                      placeholder: "Selected boundary points",
                      rows: "3",
                    },
                    domProps: { value: _vm.vertices },
                    on: {
                      input: function ($event) {
                        if ($event.target.composing) {
                          return
                        }
                        _vm.vertices = $event.target.value
                      },
                    },
                  }),
                ],
                1
              ),
            ]),
          ]
        ),
      ]),
    ]),
  ])
}
var staticRenderFns = [
  function () {
    var _vm = this
    var _h = _vm.$createElement
    var _c = _vm._self._c || _h
    return _c("div", { staticClass: "card-header" }, [
      _c("h4", [_vm._v("Map View")]),
    ])
  },
]
render._withStripped = true



/***/ })

}]);