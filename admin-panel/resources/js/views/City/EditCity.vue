<template>
  <div>
    <!-- Page Heading -->
    <div class="page-heading">
      <div class="row">
        <div class="col-12 col-md-6 order-md-1 order-last">
          <h3>Manage Zones</h3>
        </div>
        <div class="col-12 col-md-6 order-md-2 order-first">
          <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
            <ol class="breadcrumb">
              <li class="breadcrumb-item">
                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
              </li>
              <li class="breadcrumb-item active" aria-current="page">
                <template v-if="city.id">{{ __('edit') }}</template>
                <template v-else>{{ __('create') }}</template>
                Zone
              </li>
            </ol>
          </nav>
        </div>
      </div>

      <div class="row mb-3">
        <div class="col-12">
          <router-link to="/cities" class="btn btn-secondary btn-sm">
            <i class="fa fa-arrow-left me-1"></i> Back to List
          </router-link>
        </div>
      </div>

      <!-- City Form and Map -->
      <div class="row">
        <!-- City Form -->
        <div class="col-md-6 col-sm-12 order-md-1 order-last">
          <div class="card h-100">
            <div class="card-header">
              <h4>
                <template v-if="city.id">{{ __('edit') }}</template>
                <template v-else>{{ __('create') }}</template>
              </h4>
            </div>
            <div class="card-body">
              <form ref="cityForm" @submit.prevent="saveRecord">
                <!-- City Search -->
                <div class="form-group">
                  <label for="city_name">{{ __('search') }}</label>
                  <GmapAutocomplete
                    class="form-control"
                    placeholder="Search"
                    @place_changed="setPlace"
                    :options="{ fields: ['address_components','formatted_address','geometry','name','place_id','types'], strictBounds: false }"
                    id="city_name"
                  />
                  <input type="hidden" v-model="city.formatted_address" />
                  <!-- <small class="text-primary">
                    {{ __('search_your_city_where_you_will_deliver_the_food_and_to_find_co_ordinates') }}
                  </small> -->
                </div>

                <!-- Latitude & Longitude -->
                <div class="form-group">
                  <label>{{ __('latitude') }} <span class="text-danger">*</span></label>
                  <input type="text" class="form-control" v-model="city.latitude" readonly required />
                </div>
                <div class="form-group">
                  <label>{{ __('longitude') }} <span class="text-danger">*</span></label>
                  <input type="text" class="form-control" v-model="city.longitude" readonly required />
                </div>

                <!-- City & State -->
                <div class="form-group">
                  <label>{{ __('city_name') }} <span class="text-danger">*</span></label>
                  <input type="text" class="form-control" v-model="city.name" readonly required />
                </div>
                <div class="form-group">
                  <label>{{ __('state_name') }} <span class="text-danger">*</span></label>
                  <input type="text" class="form-control" v-model="city.state" readonly required />
                </div>

                <!-- Zone -->
                <div class="form-group">
                  <label>{{ __('zone_name') }} <span class="text-danger">*</span></label>
                  <input type="text" class="form-control" v-model="city.zone" required />
                </div>

                <!-- Travel & Delivery -->
                <!-- <div class="form-group">
                  <label>{{ __('time_to_travel_1km') }} <span class="text-danger">*</span></label>
                  <input type="number" class="form-control" min="0" max="999999999" v-model="city.time_to_travel" required />
                </div> -->

                <!-- Minimum amount for free delivery - hidden, default 100000 -->
                <!-- <div class="form-group">
                  <label>{{ __('minimum_amount_for_free_delivery') }} <span class="text-danger">*</span></label>
                  <input type="number" class="form-control" min="0" max="999999999" v-model="city.min_amount_for_free_delivery" required />
                </div> -->

                <div class="form-group d-none">
                  <label>{{ __('maximum_delivarable_distance') }} <span class="text-danger">*</span></label>
                  <input type="number" class="form-control" min="0" max="999999999" v-model="city.max_deliverable_distance" />
                </div>

                <!-- Delivery Charge Method - hidden, default per_km_charge -->
                <!-- <div class="form-group">
                  <label>{{ __('delivery_charge_methods') }} <span class="text-danger">*</span></label>
                  <select class="form-control" v-model="city.delivery_charge_method" required>
                    <option value="">{{ __('select_method') }}</option>
                    <option value="fixed_charge">{{ __('fixed_delivery_charges') }}</option>
                    <option value="per_km_charge">{{ __('per_km_delivery_charges') }}</option>
                    <option value="range_wise_charges">{{ __('range_wise_delivery_charges') }}</option>
                  </select>
                </div> -->

                <!-- Conditional Charges -->
                <!-- <div v-if="city.delivery_charge_method==='fixed_charge'" class="form-group">
                  <label>{{ __('fix_delivery_charges') }} <span class="text-danger">*</span></label>
                  <input type="number" class="form-control" min="0" step="any" v-model="city.fixed_charge" />
                </div> -->

                <div class="form-group">
                  <label>{{ __('per_km_delivery_charges') }} <span class="text-danger">*</span></label>
                  <input type="number" class="form-control" min="0" step="any" v-model="city.per_km_charge" />
                  <input type="hidden" v-model="city.boundary_points" />
                </div>

                <!-- Range-wise Delivery -->
                <!-- <div v-if="city.delivery_charge_method==='range_wise_charges'" class="form-group">
                  <label>{{ __('range_wise_delivery_charges') }}</label>
                  <div class="row mb-2" v-for="(range, index) in city.range_wise_charges" :key="index">
                    <div class="col-3">
                      <input type="number" class="form-control" placeholder="From" v-model="range.from_range" />
                    </div>
                    <div class="col-3">
                      <input type="number" class="form-control" placeholder="To" v-model="range.to_range" />
                    </div>
                    <div class="col-3">
                      <input type="number" class="form-control" placeholder="Price" v-model="range.price" step="any" />
                    </div>
                    <div class="col-3">
                      <button type="button" class="btn btn-danger" @click="removeRange(index)" v-if="index!==0">Remove</button>
                      <button type="button" class="btn btn-success" @click="addRange" v-if="index===0">Add</button>
                    </div>
                  </div>
                </div> -->

                <!-- Form Buttons -->
                <div class="form-group">
                  <button type="submit" class="btn btn-primary">{{ __('save') }}</button>
                  <button type="reset" class="btn btn-secondary">{{ __('clear') }}</button>
                </div>
              </form>
            </div>
          </div>
        </div>

        <!-- Map -->
        <div class="col-md-6 col-sm-12 order-md-1 order-last map_view_desktop">
          <div class="card h-100">
            <div class="card-header">
              <h4>Map View</h4>
            </div>
            <div class="card-body">
              <div class="mb-2">
                <button @click="clearOverlay" class="badge bg-danger">Clear Map</button>
                <button @click="restoreOverlay" class="badge bg-success">Restore Map</button>
              </div>
              <GmapMap
                :center="center"
                :zoom="13"
                :map-type-control="true"
                style="width: 100%; height: 700px"
                ref="mapRef"
              >
                <GmapMarker
                  v-for="(m, index) in markers"
                  :key="index"
                  :position="m.position"
                  :draggable="true"
                  @click="center=m.position"
                />
                <GmapInfoWindow
                  :position="infoWindow.position"
                  :opened="infoWindow.open"
                  @closeclick="infoWindow.open=false"
                >
                  <div v-html="infoWindow.template"></div>
                </GmapInfoWindow>
              </GmapMap>
              <textarea v-model="vertices" class="form-control mt-2" placeholder="Selected boundary points" rows="3"></textarea>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from "axios";
import { gmapApi } from "vue2-google-maps";

export default {
  data() {
    return {
      city: {
        id: "",
        latitude: "",
        longitude: "",
        name: "",
        state: "",
        zone: "",
        formatted_address: "",
        time_to_travel: 5,
        min_amount_for_free_delivery: 100000,
        max_deliverable_distance: "",
        delivery_charge_method: "per_km_charge",
        fixed_charge: "",
        per_km_charge: "",
        range_wise_charges: [{ from_range: "", to_range: "", price: "" }],
        boundary_points: "",
        geolocation_type: "",
        radius: ""
      },
      markers: [],
      center: { lat: 0, lng: 0 },
      infoWindow: { position: { lat: 0, lng: 0 }, open: false, template: "" },
      vertices: "",
      drawingManager: null,
      map: null,
      googleMapsLoaded: false,
      currentOverlay: null // Store reference to current polygon/circle
    };
  },

  mounted() {
    this.$refs.mapRef.$mapPromise.then((map) => {
      this.map = map;

      // Set initial map center
      const defaultCenter = {
        lat: parseFloat(this.city.latitude) || 17.4486,
        lng: parseFloat(this.city.longitude) || 78.3908,
      };
      this.center = defaultCenter;
      this.markers = [{ position: defaultCenter }];
      this.infoWindow = {
        position: defaultCenter,
        template: `<b>${this.city.name || "Default City"}</b><br>${this.city.formatted_address || "Address"}`,
        open: true,
      };

      // ✅ Wait for the Drawing library before initializing
      const waitForDrawingLib = setInterval(() => {
        if (window.google && google.maps && google.maps.drawing) {
          clearInterval(waitForDrawingLib);
          this.initDrawingManager(); // initialize drawing
          if (this.city.boundary_points) {
            this.setMapOverlay(); // restore previous shapes
          }
        }
      }, 300);
    });
  },

  computed: {
    google() {
      return gmapApi();
    }
  },

  created() {
    this.city.id = this.$route.params.id;
    if (this.city.id) {
      this.getCity();
    }
  },

  methods: {
    addRange() {
      this.city.range_wise_charges.push({ from_range: "", to_range: "", price: "" });
    },

    removeRange(index) {
      this.city.range_wise_charges.splice(index, 1);
    },

    setPlace(place) {
      if (!place || !place.geometry) return;
      this.city.latitude = place.geometry.location.lat();
      this.city.longitude = place.geometry.location.lng();
      this.city.name = place.name;
      this.city.formatted_address = place.formatted_address;

      const addr = place.formatted_address.split(",");
      this.city.state = addr[addr.length - 2] || "";

      this.center = { lat: this.city.latitude, lng: this.city.longitude };
      this.markers = [{ position: this.center }];
      this.infoWindow = {
        position: this.center,
        open: true,
        template: `<b>${this.city.name}</b><br>${this.city.formatted_address}`
      };
    },

    getCity() {
      axios.get(`${this.$apiUrl}/cities/edit/${this.city.id}`).then((res) => {
        const data = res.data.data;
        Object.keys(this.city).forEach((key) => {
          if (key === "range_wise_charges") {
            this.city[key] = JSON.parse(data[key]);
          } else {
            this.city[key] = data[key];
          }
        });

        this.center = { lat: parseFloat(data.latitude), lng: parseFloat(data.longitude) };
        this.markers = [{ position: this.center }];
        this.infoWindow = {
          position: this.center,
          open: true,
          template: `<b>${data.name}</b><br>${data.formatted_address}`
        };
        this.vertices = this.city.boundary_points;

        // Set geolocation_type from loaded data
        this.geolocation_type = this.city.geolocation_type;
        this.radius = this.city.radius;

        // Wait for map and drawing library to be ready, then draw the overlay
        this.$nextTick(() => {
          if (this.map && window.google && google.maps && google.maps.drawing) {
            this.setMapOverlay();
          } else {
            // If map not ready yet, wait for it
            const waitForMap = setInterval(() => {
              if (this.map && window.google && google.maps && google.maps.drawing) {
                clearInterval(waitForMap);
                this.setMapOverlay();
              }
            }, 300);
          }
        });
      });
    },

    // ✅ Initialize drawing manager
    initDrawingManager() {
      const google = window.google;
      if (!google || !google.maps || !google.maps.drawing) {
        console.warn("Google Drawing library not yet loaded.");
        return;
      }

      this.drawingManager = new google.maps.drawing.DrawingManager({
        drawingMode: google.maps.drawing.OverlayType.POLYGON,
        drawingControl: true,
        drawingControlOptions: {
          position: google.maps.ControlPosition.TOP_CENTER,
          drawingModes: [
            google.maps.drawing.OverlayType.POLYGON,
            google.maps.drawing.OverlayType.CIRCLE
          ]
        },
        polygonOptions: { editable: true },
        circleOptions: {
          editable: true,
          fillOpacity: 0.3,
          strokeWeight: 2
        }
      });

      this.drawingManager.setMap(this.map);

      google.maps.event.addListener(this.drawingManager, "overlaycomplete", (event) => {
        if (event.type === "circle") {
          const center = event.overlay.getCenter();
          this.vertices = JSON.stringify([{ lat: center.lat(), lng: center.lng() }]);
          this.radius = event.overlay.getRadius();
          this.geolocation_type = "circle";
          this.city.boundary_points = this.vertices;
          this.city.radius = this.radius;
          this.city.geolocation_type = "circle";
        } else if (event.type === "polygon") {
          const path = event.overlay.getPath().getArray().map(latlng => ({
            lat: latlng.lat(),
            lng: latlng.lng()
          }));
          this.vertices = JSON.stringify(path);
          this.geolocation_type = "polygon";
          this.city.boundary_points = this.vertices;
          this.city.geolocation_type = "polygon";
        }
      });
    },

    setMapOverlay() {
      const google = window.google;
      if (!google || !this.vertices) return;

      // Remove existing overlay if any
      if (this.currentOverlay) {
        this.currentOverlay.setMap(null);
        this.currentOverlay = null;
      }

      const points = JSON.parse(this.vertices);

      if (this.city.geolocation_type === "polygon") {
        const polygon = new google.maps.Polygon({
          paths: points,
          strokeColor: "#FF0000",
          fillColor: "#FF0000",
          fillOpacity: 0.3,
          editable: true,
          draggable: true,
          map: this.map
        });

        // Store reference to current overlay
        this.currentOverlay = polygon;

        // Update vertices when polygon path is edited (points dragged)
        const updatePolygonVertices = () => {
          const path = polygon.getPath().getArray().map(latlng => ({
            lat: latlng.lat(),
            lng: latlng.lng()
          }));
          this.vertices = JSON.stringify(path);
          this.city.boundary_points = this.vertices;
        };

        // Listen for path changes (when user drags vertices)
        google.maps.event.addListener(polygon.getPath(), 'set_at', updatePolygonVertices);
        google.maps.event.addListener(polygon.getPath(), 'insert_at', updatePolygonVertices);
        google.maps.event.addListener(polygon.getPath(), 'remove_at', updatePolygonVertices);

        // Listen for drag end (when whole polygon is dragged)
        google.maps.event.addListener(polygon, 'dragend', updatePolygonVertices);

      } else if (this.city.geolocation_type === "circle") {
        const circle = new google.maps.Circle({
          center: points[0],
          radius: Number(this.city.radius),
          strokeColor: "#FF0000",
          fillColor: "#FF0000",
          fillOpacity: 0.3,
          editable: true,
          draggable: true,
          map: this.map
        });

        // Store reference to current overlay
        this.currentOverlay = circle;

        // Update vertices when circle is edited
        const updateCircleVertices = () => {
          const center = circle.getCenter();
          this.vertices = JSON.stringify([{ lat: center.lat(), lng: center.lng() }]);
          this.radius = circle.getRadius();
          this.city.boundary_points = this.vertices;
          this.city.radius = this.radius;
        };

        // Listen for center change (when circle is dragged)
        google.maps.event.addListener(circle, 'center_changed', updateCircleVertices);
        // Listen for radius change (when circle edge is dragged)
        google.maps.event.addListener(circle, 'radius_changed', updateCircleVertices);
      }
    },

    clearOverlay() {
      this.vertices = "";
      this.city.boundary_points = "";
      this.geolocation_type = "";
      // Remove current overlay from map
      if (this.currentOverlay) {
        this.currentOverlay.setMap(null);
        this.currentOverlay = null;
      }
      if (this.drawingManager) this.drawingManager.setMap(null);
      this.initDrawingManager();
    },

    restoreOverlay() {
      if (this.city.boundary_points) {
        this.vertices = this.city.boundary_points;
        this.setMapOverlay();
      }
    },

    saveRecord() {
      if (!this.vertices) return alert("Draw Deliverable area on Map");

      const formData = new FormData();
      Object.keys(this.city).forEach((key) => {
        if (key === "range_wise_charges") {
          formData.append(key, JSON.stringify(this.city[key]));
        } else {
          formData.append(key, this.city[key]);
        }
      });

      formData.append("geolocation_type", this.geolocation_type);
      formData.append("radius", this.radius);
      formData.append("boundary_points", this.vertices);

      const url = this.city.id
        ? `${this.$apiUrl}/cities/update`
        : `${this.$apiUrl}/cities/save`;

      axios.post(url, formData).then((res) => {
        alert(res.data.message);
        if (res.data.status === 1) this.$router.push("/cities");
      });
    }
  }
};
</script>

