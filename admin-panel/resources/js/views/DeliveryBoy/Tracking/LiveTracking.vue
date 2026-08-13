<template>
    <div class="live-tracking-container">
        <!-- Page Heading with Breadcrumbs -->
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Live Tracking</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">Dashboard</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">
                                Live Tracking
                            </li>
                        </ol>
                    </nav>
                </div>
            </div>
        </div>

        <div class="row mb-3">
            <div class="col-12">
                <router-link to="/dashboard" class="btn btn-secondary btn-sm">
                    <i class="fa fa-arrow-left me-1"></i> Back to Dashboard
                </router-link>
            </div>
        </div>

        <!-- City Filter -->
        <div class="row mb-3">
            <div class="col-md-12">
                <div class="card">
                    <div class="card-body py-2">
                        <div class="row align-items-center">
                            <div class="col-md-3">
                                <label class="mb-0"><i class="fa fa-map-marker-alt"></i> Filter by City:</label>
                            </div>
                            <div class="col-md-6">
                                <select v-model="selectedCityId" @change="onCityChange" class="form-control">
                                    <option :value="null">All Cities</option>
                                    <option v-for="city in cities" :key="city.id" :value="city.id">
                                        {{ city.name }}
                                    </option>
                                </select>
                            </div>
                            <div class="col-md-3 text-right">
                                <span class="badge bg-info">
                                    {{ drivers.length }} Driver(s) in {{ selectedCityName }}
                                </span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Stats List -->
        <div class="d-flex justify-content-between align-items-center mb-3 stats-list">
            <div class="stat-item">
                <span class="stat-dot bg-success"></span>
                <span class="stat-label">Online Drivers:</span>
                <span class="stat-value">{{ onlineDrivers }}</span>
            </div>
            <div class="stat-item">
                <span class="stat-dot bg-danger"></span>
                <span class="stat-label">Offline Drivers:</span>
                <span class="stat-value">{{ offlineDrivers }}</span>
            </div>
            <div class="stat-item">
                <span class="stat-dot bg-primary"></span>
                <span class="stat-label">Active Deliveries:</span>
                <span class="stat-value">{{ activeDeliveries }}</span>
            </div>
        </div>

        <!-- Main Map Card -->
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <div>
                    <h5 class="mb-0">
                        <i class="fa fa-map-marked-alt"></i> Live Driver Tracking - Hyderabad
                    </h5>
                    <small class="text-muted">Real-time delivery partner locations</small>
                </div>
                <div>
                    <span class="badge bg-success pulse-badge">
                        <span class="pulse-dot"></span> LIVE
                    </span>
                    <button class="btn btn-sm btn-primary ml-2" @click="refreshMap">
                        <i class="fa fa-sync-alt"></i> Refresh
                    </button>
                </div>
            </div>
            <div class="card-body p-0">
                <!-- Loading State -->
                <div v-if="isLoading || !mapReady" class="text-center py-5">
                    <div class="spinner-border text-primary" role="status">
                        <span class="sr-only">Loading...</span>
                    </div>
                    <p class="mt-3">{{ loadingMessage }}</p>
                </div>

                <!-- Google Map -->
                <div v-show="mapReady && !isLoading" id="live-tracking-map" style="width: 100%; height: 600px;"></div>

                <!-- Error State -->
                <div v-if="!isLoading && hasError" class="text-center py-5">
                    <i class="fa fa-exclamation-triangle fa-3x text-danger mb-3"></i>
                    <p class="text-danger">Failed to load map. Please try again.</p>
                </div>
            </div>
        </div>

        <!-- Driver List Card -->
        <div class="card mt-3">
            <div class="card-header">
                <h5 class="mb-0"><i class="fa fa-users"></i> Active Drivers</h5>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Driver</th>
                                <th>Location</th>
                                <th>Status</th>
                                <!-- <th>Speed</th> -->
                                <th>Orders</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-if="drivers.length === 0">
                                <td colspan="5" class="text-center py-4">
                                    <i class="fa fa-info-circle fa-2x text-muted mb-2"></i>
                                    <p class="text-muted mb-0">No drivers available</p>
                                </td>
                            </tr>
                            <tr v-for="driver in drivers" :key="driver.id">
                                <td>
                                    <div class="d-flex align-items-center">
                                        <div class="driver-avatar mr-2" :style="{backgroundColor: driver.color}">
                                            {{ driver.name.charAt(0) }}
                                        </div>
                                        <div>
                                            <strong>{{ driver.name }}</strong><br>
                                            <small class="text-muted">{{ driver.phone }}</small>
                                        </div>
                                    </div>
                                </td>
                                <td>
                                    <i class="fa fa-map-marker-alt text-danger"></i>
                                    {{ driver.locationName }}
                                </td>
                                <td>
                                    <span class="status-badge" :class="driver.status === 'Delivering' ? 'status-delivering' : 'status-idle'">
                                        {{ driver.status }}
                                    </span>
                                </td>
                                <!-- <td>{{ driver.speed }} km/h</td> -->
                                <td>{{ driver.completedOrders }}/{{ driver.totalOrders }}</td>
                                <td>
                                    <button class="btn btn-sm btn-info" @click="focusOnDriver(driver)">
                                        <i class="fa fa-crosshairs"></i> Locate
                                    </button>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    name: 'LiveTracking',
    data() {
        return {
            isLoading: true,
            mapReady: false,
            hasError: false,
            loadingMessage: 'Initializing...',
            googleApiKey: null,
            map: null,
            markers: [],
            infoWindows: [],
            zonePolygons: [],
            drivers: [],
            cities: [],
            selectedCityId: null,
            stats: {
                onlineDrivers: 0,
                offlineDrivers: 0,
                activeDeliveries: 0,
                totalDistance: 0,
                // avgSpeed: 0
            },
            refreshInterval: null,
            isRefreshing: false,
            pendingGeocodingRequests: 0,
            geocodingCache: {},
            geocodingCacheSize: 0,
            maxCacheSize: 100,
            failedRefreshCount: 0,
            maxFailedRefreshes: 5,
            driverColors: ['#4CAF50', '#2196F3', '#FF9800', '#9C27B0', '#F44336', '#00BCD4', '#E91E63', '#795548'],
            driverColorMap: {}
        };
    },
    computed: {
        onlineDrivers() {
            return this.stats.onlineDrivers;
        },
        offlineDrivers() {
            return this.stats.offlineDrivers;
        },
        activeDeliveries() {
            return this.stats.activeDeliveries;
        },
        totalDistance() {
            return this.stats.totalDistance;
        },
        selectedCityName() {
            if (!this.selectedCityId) {
                return 'All Cities';
            }
            const city = this.cities.find(c => c.id === this.selectedCityId);
            return city ? city.name : 'Selected City';
        }
        // avgSpeed() {
        //     return this.stats.avgSpeed;
        // }
    },
    mounted() {
        console.log('[LiveTracking] Component mounted!');
        console.log('[LiveTracking] Initial state - isLoading:', this.isLoading, 'mapReady:', this.mapReady, 'hasError:', this.hasError);
        console.log('[LiveTracking] Drivers count:', this.drivers.length);
        console.log('[LiveTracking] API URL:', this.$apiUrl);
        this.initializeTracking();
    },
    beforeDestroy() {
        // Cleanup intervals
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }

        // Cleanup map elements
        if (this.infoWindows) {
            this.infoWindows.forEach(iw => iw.close());
        }
        if (this.markers) {
            this.markers.forEach(marker => marker.setMap(null));
        }
        if (this.zonePolygons) {
            this.zonePolygons.forEach(polygon => {
                if (polygon && typeof polygon.setMap === 'function') {
                    polygon.setMap(null);
                }
            });
        }

        // Cleanup geocoder and cache
        if (this.geocoder) {
            this.geocoder = null;
        }
        this.geocodingCache = {};
        this.geocodingCacheSize = 0;
    },
    methods: {
        async initializeTracking() {
            // console.log('[LiveTracking] Initializing tracking system...');
            try {
                this.loadingMessage = 'Loading cities...';
                await this.fetchCities();

                this.loadingMessage = 'Fetching driver locations...';
                await this.fetchLiveTrackingData();

                this.loadingMessage = 'Loading Google Maps...';
                await this.fetchGoogleApiKey();

                this.loadingMessage = 'Rendering map...';

                // Start auto-refresh every 30 seconds
                this.startAutoRefresh();

                this.isLoading = false;
            } catch (error) {
                // console.error('[LiveTracking] Initialization error:', error);
                this.hasError = true;
                this.isLoading = false;
            }
        },

        async fetchCities() {
            // console.log('[LiveTracking] Fetching cities...');
            try {
                const response = await axios.get(`${this.$apiUrl}/cities/`);
                // console.log('[LiveTracking] Cities response:', response.data);

                if (response.data.status === 1 && response.data.data) {
                    this.cities = response.data.data;
                    // console.log('[LiveTracking] Loaded', this.cities.length, 'cities');
                } else if (Array.isArray(response.data)) {
                    // Handle if response directly contains cities array
                    this.cities = response.data;
                    // console.log('[LiveTracking] Loaded', this.cities.length, 'cities');
                }
            } catch (error) {
                // console.error('[LiveTracking] Error fetching cities:', error);
            }
        },

        onCityChange() {
            // console.log('[LiveTracking] City filter changed to:', this.selectedCityId);

            // Validate city still exists if one is selected
            if (this.selectedCityId) {
                const cityExists = this.cities.find(c => c.id === this.selectedCityId);
                if (!cityExists) {
                    // console.error('[LiveTracking] Selected city no longer exists');
                    this.selectedCityId = null;
                    if (this.$swal) {
                        this.$swal.fire({
                            icon: 'warning',
                            title: 'City Not Found',
                            text: 'The selected city is no longer available. Showing all cities.',
                            timer: 2000,
                            showConfirmButton: false
                        });
                    }
                }
            }

            // Fetch new data and update map
            this.fetchLiveTrackingData().then(() => {
                if (this.map && this.mapReady) {
                    // Clear existing markers and zones
                    this.clearMapElements();

                    // Draw zone boundaries for selected city
                    this.drawZoneBoundaries();

                    // Add driver markers
                    this.addDriverMarkers();

                    // Adjust map view to fit selected city/zone
                    this.fitMapToZone();
                }
            }).catch(() => {
                // console.error('[LiveTracking] Error during city change');
            });
        },

        async fetchLiveTrackingData() {
            console.log('[LiveTracking] Fetching live tracking data...');
            try {
                // Build URL with city filter if selected
                let url = `${this.$apiUrl}/delivery_boys/live-tracking`;
                if (this.selectedCityId) {
                    url += `?city_id=${this.selectedCityId}`;
                }

                console.log('[LiveTracking] API URL:', url);
                const response = await axios.get(url);
                console.log('[LiveTracking] Live tracking response:', response.data);

                if (response.data.status === 1 && response.data.data) {
                    const { drivers, stats } = response.data.data;

                    // Assign consistent colors to drivers based on their ID
                    this.drivers = drivers.map((driver) => {
                        // Check if driver already has a color assigned
                        if (!this.driverColorMap[driver.id]) {
                            // Assign a new color based on map size
                            const colorIndex = Object.keys(this.driverColorMap).length % this.driverColors.length;
                            this.driverColorMap[driver.id] = this.driverColors[colorIndex];
                        }

                        return {
                            ...driver,
                            color: this.driverColorMap[driver.id],
                            locationName: 'Loading location...' // Will be fetched via geocoding
                        };
                    });

                    this.stats = stats;

                    console.log('[LiveTracking] Loaded', this.drivers.length, 'drivers');
                    console.log('[LiveTracking] Stats:', this.stats);

                    // Reset failed refresh count on success
                    this.failedRefreshCount = 0;

                    // Fetch location names for all drivers
                    if (this.map) {
                        this.fetchAllLocationNames();
                    }
                }
            } catch (error) {
                console.error('[LiveTracking] Error fetching live tracking data:', error);
                console.error('[LiveTracking] Error details:', error.response?.data || error.message);
                this.failedRefreshCount++;
                throw error; // Re-throw to be handled by caller
            }
        },

        async fetchAllLocationNames() {
            // console.log('[LiveTracking] Fetching location names for all drivers...');

            // Create a single geocoder instance for reuse
            if (!this.geocoder) {
                this.geocoder = new google.maps.Geocoder();
            }

            for (let driver of this.drivers) {
                if (driver.lat && driver.lng) {
                    // Create cache key from coordinates
                    const cacheKey = `${driver.lat.toFixed(4)}_${driver.lng.toFixed(4)}`;

                    // Check if location name is already cached
                    if (this.geocodingCache[cacheKey]) {
                        driver.locationName = this.geocodingCache[cacheKey];
                        continue;
                    }

                    // Check cache size limit before adding new entries
                    if (this.geocodingCacheSize >= this.maxCacheSize) {
                        // Clear half of the cache (oldest entries removed via simple clear)
                        this.geocodingCache = {};
                        this.geocodingCacheSize = 0;
                        // console.log('[LiveTracking] Geocoding cache cleared due to size limit');
                    }

                    try {
                        this.pendingGeocodingRequests++;
                        const latlng = { lat: driver.lat, lng: driver.lng };

                        this.geocoder.geocode({ location: latlng }, (results, status) => {
                            this.pendingGeocodingRequests--;

                            if (status === 'OK' && results[0]) {
                                const addressComponents = results[0].address_components;
                                let placeParts = [];

                                // Get neighborhood
                                let neighborhood = addressComponents.find(c =>
                                    c.types.includes('neighborhood') ||
                                    c.types.includes('sublocality_level_3')
                                );
                                if (neighborhood) placeParts.push(neighborhood.long_name);

                                // Get area/sublocality
                                let sublocality = addressComponents.find(c =>
                                    c.types.includes('sublocality_level_1') ||
                                    c.types.includes('sublocality_level_2')
                                );
                                if (sublocality) placeParts.push(sublocality.long_name);

                                // Get city
                                let locality = addressComponents.find(c =>
                                    c.types.includes('locality')
                                );
                                if (locality) placeParts.push(locality.long_name);

                                const locationName = placeParts.length > 0 ? placeParts.join(', ') : results[0].formatted_address;

                                // Cache the result with size tracking
                                this.geocodingCache[cacheKey] = locationName;
                                this.geocodingCacheSize++;
                                driver.locationName = locationName;
                            }
                        });
                    } catch (error) {
                        this.pendingGeocodingRequests--;
                        // console.error('[LiveTracking] Error fetching location name for driver:', driver.id, error);
                    }
                }
            }
        },

        startAutoRefresh() {
            // console.log('[LiveTracking] Starting auto-refresh (every 30 seconds)...');
            this.refreshInterval = setInterval(async () => {
                // Prevent concurrent refreshes
                if (this.isRefreshing) {
                    // console.log('[LiveTracking] Skipping refresh - previous refresh still in progress');
                    return;
                }

                // Stop auto-refresh if too many failures
                if (this.failedRefreshCount >= this.maxFailedRefreshes) {
                    // console.error('[LiveTracking] Too many failed refreshes, stopping auto-refresh');
                    clearInterval(this.refreshInterval);
                    this.refreshInterval = null;

                    // Show error notification to user
                    if (this.$swal) {
                        this.$swal.fire({
                            icon: 'error',
                            title: 'Connection Lost',
                            text: 'Unable to refresh driver locations. Please check your connection and refresh the page.',
                            confirmButtonText: 'Reload Page',
                            allowOutsideClick: false
                        }).then((result) => {
                            if (result.isConfirmed) {
                                window.location.reload();
                            }
                        });
                    }
                    return;
                }

                this.isRefreshing = true;
                try {
                    await this.fetchLiveTrackingData();
                    this.updateMarkersWithoutReset();
                } catch (error) {
                    // console.error('[LiveTracking] Auto-refresh error:', error);
                    // Error count is incremented in fetchLiveTrackingData
                } finally {
                    this.isRefreshing = false;
                }
            }, 30000);
        },

        updateMarkers() {
            // console.log('[LiveTracking] Updating markers on map (full reset)...');
            if (!this.map || !this.mapReady) return;

            this.clearMapElements();
            this.drawZoneBoundaries();
            this.addDriverMarkers();
            this.fitMapToZone();
        },

        updateMarkersWithoutReset() {
            // console.log('[LiveTracking] Updating markers without resetting view...');
            if (!this.map || !this.mapReady) return;

            // Only clear and redraw markers, don't reset map view
            // This preserves user's current pan/zoom state
            this.markers.forEach(marker => marker.setMap(null));
            this.markers = [];

            // Keep info windows closed but don't lose reference
            this.infoWindows.forEach(iw => iw.close());
            this.infoWindows = [];

            // Redraw markers with updated positions
            this.addDriverMarkers();

            // Don't call fitMapToZone() to preserve user's current view
        },

        clearMapElements() {
            // console.log('[LiveTracking] Clearing map elements...');

            // Remove old markers
            this.markers.forEach(marker => marker.setMap(null));
            this.markers = [];

            // Close info windows
            this.infoWindows.forEach(iw => iw.close());
            this.infoWindows = [];

            // Remove zone polygons
            this.zonePolygons.forEach(polygon => polygon.setMap(null));
            this.zonePolygons = [];
        },

        drawZoneBoundaries() {
            // console.log('[LiveTracking] Drawing zone boundaries...');

            if (!this.map || !this.mapReady) return;

            // Clear existing polygons
            this.zonePolygons.forEach(polygon => polygon.setMap(null));
            this.zonePolygons = [];

            // If a specific city is selected, draw only that city's boundary
            if (this.selectedCityId) {
                const selectedCity = this.cities.find(c => c.id === this.selectedCityId);
                if (selectedCity && selectedCity.boundary_points) {
                    this.drawCityBoundary(selectedCity);
                }
            } else {
                // Draw all city boundaries when "All Cities" is selected
                this.cities.forEach(city => {
                    if (city.boundary_points) {
                        this.drawCityBoundary(city);
                    }
                });
            }
        },

        drawCityBoundary(city) {
            try {
                let boundaryPoints = city.boundary_points;

                // Validate boundary_points exists
                if (!boundaryPoints) {
                    // console.log(`[LiveTracking] No boundary points for city: ${city.name}`);
                    return;
                }

                // Parse boundary_points if it's a string
                if (typeof boundaryPoints === 'string') {
                    try {
                        boundaryPoints = JSON.parse(boundaryPoints);
                    } catch (parseError) {
                        // console.error(`[LiveTracking] Invalid JSON in boundary_points for ${city.name}:`, parseError);
                        return;
                    }
                }

                // Validate boundary_points is an array with at least 3 points
                if (!Array.isArray(boundaryPoints) || boundaryPoints.length < 3) {
                    // console.error(`[LiveTracking] Invalid boundary_points for ${city.name}: needs at least 3 points`);
                    return;
                }

                // Validate each point has lat/lng
                const isValid = boundaryPoints.every(point =>
                    point &&
                    (point.lat !== undefined && point.lat !== null) &&
                    (point.lng !== undefined && point.lng !== null)
                );

                if (!isValid) {
                    // console.error(`[LiveTracking] Invalid boundary_points format for ${city.name}`);
                    return;
                }

                // Convert to Google Maps LatLng objects
                const polygonPath = boundaryPoints.map(point => ({
                    lat: parseFloat(point.lat),
                    lng: parseFloat(point.lng)
                }));

                // Create polygon
                const polygon = new google.maps.Polygon({
                    paths: polygonPath,
                    strokeColor: '#2196F3',
                    strokeOpacity: 0.8,
                    strokeWeight: 2,
                    fillColor: '#2196F3',
                    fillOpacity: 0.15,
                    map: this.map
                });

                this.zonePolygons.push(polygon);

                // Add city name label at center of polygon
                const bounds = new google.maps.LatLngBounds();
                polygonPath.forEach(point => bounds.extend(point));
                const center = bounds.getCenter();

                const marker = new google.maps.Marker({
                    position: center,
                    map: this.map,
                    icon: {
                        url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(`
                            <svg xmlns="http://www.w3.org/2000/svg" width="80" height="30" viewBox="0 0 80 30">
                                <rect x="0" y="0" width="80" height="30" rx="5" fill="#2196F3" opacity="0.9"/>
                                <text x="40" y="20" font-family="Arial" font-size="12" fill="white" text-anchor="middle" font-weight="bold">${city.name}</text>
                            </svg>
                        `),
                        anchor: new google.maps.Point(40, 15)
                    },
                    zIndex: 100
                });

                this.zonePolygons.push({ setMap: (map) => marker.setMap(map) });

                // console.log(`[LiveTracking] Drew boundary for ${city.name}`);
            } catch (error) {
                // console.error(`[LiveTracking] Error drawing boundary for ${city.name}:`, error);
            }
        },

        fitMapToZone() {
            // console.log('[LiveTracking] Fitting map to zone...');

            if (!this.map || !this.mapReady) return;

            const bounds = new google.maps.LatLngBounds();

            if (this.selectedCityId) {
                // Fit to selected city boundary
                const selectedCity = this.cities.find(c => c.id === this.selectedCityId);
                if (selectedCity && selectedCity.boundary_points) {
                    let boundaryPoints = selectedCity.boundary_points;
                    if (typeof boundaryPoints === 'string') {
                        boundaryPoints = JSON.parse(boundaryPoints);
                    }
                    boundaryPoints.forEach(point => {
                        bounds.extend({ lat: parseFloat(point.lat), lng: parseFloat(point.lng) });
                    });
                }
            } else {
                // Fit to all cities
                this.cities.forEach(city => {
                    if (city.boundary_points) {
                        let boundaryPoints = city.boundary_points;
                        if (typeof boundaryPoints === 'string') {
                            boundaryPoints = JSON.parse(boundaryPoints);
                        }
                        boundaryPoints.forEach(point => {
                            bounds.extend({ lat: parseFloat(point.lat), lng: parseFloat(point.lng) });
                        });
                    }
                });
            }

            // Include driver markers in bounds if available
            this.drivers.forEach(driver => {
                if (driver.lat && driver.lng) {
                    bounds.extend({ lat: driver.lat, lng: driver.lng });
                }
            });

            // Fit map to bounds
            if (!bounds.isEmpty()) {
                this.map.fitBounds(bounds);

                // Add some padding
                const padding = this.selectedCityId ? 50 : 100;
                this.map.fitBounds(bounds, padding);
            }
        },

        async fetchGoogleApiKey() {
            // console.log('[LiveTracking] Starting fetchGoogleApiKey...');
            this.isLoading = true;
            try {
                // console.log('[LiveTracking] API URL:', this.$apiUrl);
                const response = await axios.get(`${this.$apiUrl}/store_settings`);
                // console.log('[LiveTracking] Settings response:', response.data);

                if (response.data.status === 1 || response.data.data) {
                    const settings = response.data.data.store_settings || response.data.data;
                    // console.log('[LiveTracking] Settings data:', settings);

                    // Try to find the Google Maps API key from settings array
                    if (Array.isArray(settings)) {
                        const googleMapSetting = settings.find(setting =>
                            setting.variable === 'googleMapApiKey' ||
                            setting.variable === 'google_map_api_key' ||
                            setting.variable === 'google_place_api_key'
                        );

                        if (googleMapSetting && googleMapSetting.value) {
                            this.googleApiKey = googleMapSetting.value;
                        }
                    } else {
                        // If settings is an object, try direct property access
                        this.googleApiKey = settings.googleMapApiKey || settings.google_map_api_key || settings.google_place_api_key;
                    }

                    // console.log('[LiveTracking] Google API Key found:', this.googleApiKey ? 'YES' : 'NO');
                    // console.log('[LiveTracking] Google API Key (first 20 chars):', this.googleApiKey ? this.googleApiKey.substring(0, 20) + '...' : 'null');

                    if (this.googleApiKey) {
                        // console.log('[LiveTracking] Loading Google Maps script...');
                        await this.loadGoogleMapsScript();
                    } else {
                        // console.error('[LiveTracking] Google Maps API key not found in settings');
                        // console.log('[LiveTracking] Settings structure:', JSON.stringify(settings, null, 2));
                        this.hasError = true;
                        this.isLoading = false;
                    }
                } else {
                    // console.error('[LiveTracking] Settings API returned unexpected response');
                    this.hasError = true;
                    this.isLoading = false;
                }
            } catch (error) {
                // console.error('[LiveTracking] Error fetching settings:', error);
                this.hasError = true;
                this.isLoading = false;
            }
        },

        loadGoogleMapsScript() {
            // console.log('[LiveTracking] loadGoogleMapsScript called');
            return new Promise((resolve, reject) => {
                if (window.google && window.google.maps) {
                    // console.log('[LiveTracking] Google Maps already loaded, creating map...');
                    this.createMap();
                    resolve();
                    return;
                }

                // console.log('[LiveTracking] Creating Google Maps script tag...');
                const script = document.createElement('script');
                const scriptUrl = `https://maps.googleapis.com/maps/api/js?key=${this.googleApiKey}&libraries=places`;
                // console.log('[LiveTracking] Script URL:', scriptUrl);
                script.src = scriptUrl;
                script.async = true;
                script.defer = true;
                script.onload = () => {
                    // console.log('[LiveTracking] Google Maps script loaded successfully!');
                    this.createMap();
                    resolve();
                };
                script.onerror = (error) => {
                    // console.error('[LiveTracking] Failed to load Google Maps script:', error);
                    this.hasError = true;
                    this.isLoading = false;
                    reject(new Error('Failed to load Google Maps'));
                };
                // console.log('[LiveTracking] Appending script to document head...');
                document.head.appendChild(script);
            });
        },

        createMap() {
            // console.log('[LiveTracking] createMap called');
            this.$nextTick(() => {
                // console.log('[LiveTracking] Inside $nextTick, searching for map element...');
                const mapElement = document.getElementById('live-tracking-map');
                // console.log('[LiveTracking] Map element found:', mapElement ? 'YES' : 'NO');

                if (!mapElement) {
                    // console.error('[LiveTracking] Map element not found in DOM!');
                    this.hasError = true;
                    this.isLoading = false;
                    return;
                }

                // console.log('[LiveTracking] Map element dimensions:', mapElement.offsetWidth, mapElement.offsetHeight);

                // Center of Hyderabad
                const center = { lat: 17.406498, lng: 78.431213 };
                // console.log('[LiveTracking] Creating Google Map with center:', center);

                try {
                    // Dark mode map styling
                    this.map = new google.maps.Map(mapElement, {
                    center: center,
                    zoom: 12,
                    mapTypeId: 'roadmap',
                    styles: [
                        { elementType: "geometry", stylers: [{ color: "#242f3e" }] },
                        { elementType: "labels.text.stroke", stylers: [{ color: "#242f3e" }] },
                        { elementType: "labels.text.fill", stylers: [{ color: "#746855" }] },
                        {
                            featureType: "administrative.locality",
                            elementType: "labels.text.fill",
                            stylers: [{ color: "#d59563" }],
                        },
                        {
                            featureType: "poi",
                            elementType: "labels.text.fill",
                            stylers: [{ color: "#d59563" }],
                        },
                        {
                            featureType: "poi.park",
                            elementType: "geometry",
                            stylers: [{ color: "#263c3f" }],
                        },
                        {
                            featureType: "poi.park",
                            elementType: "labels.text.fill",
                            stylers: [{ color: "#6b9a76" }],
                        },
                        {
                            featureType: "road",
                            elementType: "geometry",
                            stylers: [{ color: "#38414e" }],
                        },
                        {
                            featureType: "road",
                            elementType: "geometry.stroke",
                            stylers: [{ color: "#212a37" }],
                        },
                        {
                            featureType: "road",
                            elementType: "labels.text.fill",
                            stylers: [{ color: "#9ca5b3" }],
                        },
                        {
                            featureType: "road.highway",
                            elementType: "geometry",
                            stylers: [{ color: "#746855" }],
                        },
                        {
                            featureType: "road.highway",
                            elementType: "geometry.stroke",
                            stylers: [{ color: "#1f2835" }],
                        },
                        {
                            featureType: "road.highway",
                            elementType: "labels.text.fill",
                            stylers: [{ color: "#f3d19c" }],
                        },
                        {
                            featureType: "transit",
                            elementType: "geometry",
                            stylers: [{ color: "#2f3948" }],
                        },
                        {
                            featureType: "transit.station",
                            elementType: "labels.text.fill",
                            stylers: [{ color: "#d59563" }],
                        },
                        {
                            featureType: "water",
                            elementType: "geometry",
                            stylers: [{ color: "#17263c" }],
                        },
                        {
                            featureType: "water",
                            elementType: "labels.text.fill",
                            stylers: [{ color: "#515c6d" }],
                        },
                        {
                            featureType: "water",
                            elementType: "labels.text.stroke",
                            stylers: [{ color: "#17263c" }],
                        },
                    ],
                });

                // console.log('[LiveTracking] Google Map created successfully!');

                this.mapReady = true;

                // Draw zone boundaries
                // console.log('[LiveTracking] Drawing zone boundaries...');
                this.drawZoneBoundaries();

                // Add markers for each driver
                // console.log('[LiveTracking] Adding driver markers...');
                this.addDriverMarkers();
                // console.log('[LiveTracking] Driver markers added successfully!');

                // Fit map to show zones and drivers
                this.fitMapToZone();

                // console.log('[LiveTracking] Map is ready! isLoading:', this.isLoading, 'mapReady:', this.mapReady);

                } catch (error) {
                    // console.error('[LiveTracking] Error creating map:', error);
                    this.hasError = true;
                    this.isLoading = false;
                }
            });
        },

        addDriverMarkers() {
            // console.log('[LiveTracking] addDriverMarkers called with', this.drivers.length, 'drivers');
            this.drivers.forEach((driver, index) => {
                // console.log(`[LiveTracking] Creating marker for driver ${index + 1}:`, driver.name, 'at', driver.lat, driver.lng);
                // Create custom bike icon SVG
                const bikeIcon = {
                    url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(`
                        <svg xmlns="http://www.w3.org/2000/svg" width="60" height="60" viewBox="0 0 60 60">
                            <!-- Outer pulse ring -->
                            <circle cx="30" cy="30" r="28" fill="${driver.color}" opacity="0.2">
                                <animate attributeName="r" from="20" to="28" dur="2s" repeatCount="indefinite"/>
                                <animate attributeName="opacity" from="0.4" to="0" dur="2s" repeatCount="indefinite"/>
                            </circle>

                            <!-- Background circle -->
                            <circle cx="30" cy="30" r="20" fill="${driver.color}"/>

                            <!-- Delivery scooter -->
                            <g transform="translate(30, 30)">
                                <!-- Delivery Box -->
                                <rect x="5" y="-12" width="10" height="10" fill="#FF6B35" rx="1"/>
                                <text x="10" y="-4" text-anchor="middle" fill="white" font-size="8" font-weight="bold">Z</text>

                                <!-- Scooter body -->
                                <path d="M-8,-5 L8,-5 L6,5 L-6,5 Z" fill="#212121"/>

                                <!-- Seat -->
                                <rect x="-6" y="-8" width="8" height="3" fill="#424242" rx="1"/>

                                <!-- Handlebars -->
                                <line x1="-8" y1="-5" x2="-10" y2="-8" stroke="#424242" stroke-width="1.5"/>
                                <circle cx="-10" cy="-8" r="1.5" fill="#757575"/>

                                <!-- Front wheel -->
                                <circle cx="-8" cy="8" r="4" fill="#212121"/>
                                <circle cx="-8" cy="8" r="2.5" fill="#424242"/>

                                <!-- Rear wheel -->
                                <circle cx="6" cy="8" r="4" fill="#212121"/>
                                <circle cx="6" cy="8" r="2.5" fill="#424242"/>

                                <!-- Driver (helmet and body) -->
                                <ellipse cx="-2" cy="-10" rx="3" ry="3.5" fill="#1565C0"/>
                                <rect x="-4" y="-7" width="4" height="6" fill="#1976D2" rx="1"/>

                                <!-- Visor -->
                                <ellipse cx="-2" cy="-10" rx="2" ry="1.5" fill="#0D47A1" opacity="0.7"/>
                            </g>
                        </svg>
                    `),
                    scaledSize: new google.maps.Size(60, 60),
                    anchor: new google.maps.Point(30, 30)
                };

                const marker = new google.maps.Marker({
                    position: { lat: driver.lat, lng: driver.lng },
                    map: this.map,
                    icon: bikeIcon,
                    title: driver.name,
                    animation: google.maps.Animation.DROP
                });

                // Info window with theme-aware styling
                const isDarkMode = document.body.classList.contains('theme-dark');

                // Define colors based on current theme
                const bgColor = isDarkMode ? '#2d3748' : '#ffffff';
                const textColor = isDarkMode ? '#e2e8f0' : '#2d3748';
                const secondaryTextColor = isDarkMode ? '#cbd5e0' : '#4a5568';
                const headingColor = isDarkMode ? '#f7fafc' : '#1a202c';
                const strongColor = isDarkMode ? '#f7fafc' : '#2d3748';

                const infoContent = `
                    <div style="padding: 12px; min-width: 220px; background-color: ${bgColor}; color: ${textColor}; border-radius: 8px; font-family: Arial, sans-serif; box-shadow: 0 2px 8px rgba(0,0,0,0.15);">
                        <h6 style="margin: 0 0 12px 0; color: ${headingColor}; font-weight: bold; font-size: 16px; border-bottom: 2px solid ${driver.color}; padding-bottom: 8px;">
                            <i class="fa fa-user-circle" style="color: ${driver.color};"></i> ${driver.name}
                        </h6>
                        <p style="margin: 8px 0; font-size: 13px; color: ${secondaryTextColor};">
                            <i class="fa fa-phone" style="color: ${driver.color}; margin-right: 6px;"></i> ${driver.phone}
                        </p>
                        <p style="margin: 8px 0; font-size: 13px; color: ${secondaryTextColor};">
                            <i class="fa fa-map-marker-alt" style="color: ${driver.color}; margin-right: 6px;"></i> ${driver.locationName}
                        </p>
                        <p style="margin: 8px 0; font-size: 13px; color: ${secondaryTextColor};">
                            <i class="fa fa-circle" style="color: ${driver.status === 'Delivering' ? '#4CAF50' : '#FF9800'}; margin-right: 6px;"></i>
                            <strong style="color: ${strongColor};">${driver.status}</strong>
                        </p>
                        <!--
                        <p style="margin: 8px 0; font-size: 13px; color: ${secondaryTextColor};">
                            <i class="fa fa-tachometer-alt" style="color: ${driver.color}; margin-right: 6px;"></i> Speed: <strong style="color: ${strongColor};">${driver.speed} km/h</strong>
                        </p>
                        -->
                        <p style="margin: 8px 0; font-size: 13px; color: ${secondaryTextColor};">
                            <i class="fa fa-box" style="color: ${driver.color}; margin-right: 6px;"></i> Orders: <strong style="color: ${strongColor};">${driver.completedOrders}/${driver.totalOrders}</strong>
                        </p>
                    </div>
                `;

                const infoWindow = new google.maps.InfoWindow({
                    content: infoContent
                });

                marker.addListener('click', () => {
                    // Close all info windows
                    this.infoWindows.forEach(iw => iw.close());
                    // Open this info window
                    infoWindow.open(this.map, marker);
                });

                this.markers.push(marker);
                this.infoWindows.push(infoWindow);
            });
        },

        focusOnDriver(driver) {
            const position = { lat: driver.lat, lng: driver.lng };
            this.map.panTo(position);
            this.map.setZoom(15);

            // Find and click the marker
            const markerIndex = this.drivers.findIndex(d => d.id === driver.id);
            if (markerIndex !== -1) {
                google.maps.event.trigger(this.markers[markerIndex], 'click');
            }
        },

        async refreshMap() {
            // console.log('[LiveTracking] Manual refresh triggered');
            await this.fetchLiveTrackingData();
            this.updateMarkers();

            this.$swal.fire({
                icon: 'success',
                title: 'Map Refreshed',
                text: 'Driver locations updated',
                timer: 1500,
                showConfirmButton: false
            });
        }
    }
};
</script>

<style scoped>
.live-tracking-container {
    padding: 20px;
}

.pulse-badge {
    padding: 8px 12px;
    font-size: 12px;
    display: inline-flex;
    align-items: center;
    gap: 6px;
}

.pulse-dot {
    display: inline-block;
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background-color: white;
    animation: pulse 2s infinite;
}

@keyframes pulse {
    0% {
        box-shadow: 0 0 0 0 rgba(255, 255, 255, 0.7);
    }
    70% {
        box-shadow: 0 0 0 10px rgba(255, 255, 255, 0);
    }
    100% {
        box-shadow: 0 0 0 0 rgba(255, 255, 255, 0);
    }
}

.driver-avatar {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-weight: bold;
    font-size: 18px;
}

/* Theme-aware table styling */
.table th {
    font-weight: 600;
    border-bottom: 2px solid var(--cui-border-color, #dee2e6);
}

/* Light mode table header */
body.theme-light .table th {
    background-color: #f8f9fa;
    color: #2d3748;
}

/* Dark mode table header */
body.theme-dark .table th {
    background-color: #2d3748;
    color: #e2e8f0;
}

.card {
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    border: none;
}

/* Theme-aware card styling */
body.theme-light .card-header {
    background-color: #fff;
    border-bottom: 1px solid #dee2e6;
    color: #2d3748;
}

body.theme-dark .card-header {
    background-color: #2d3748;
    border-bottom: 1px solid #4a5568;
    color: #e2e8f0;
}

body.theme-light .card {
    background-color: #fff;
    color: #2d3748;
}

body.theme-dark .card {
    background-color: #1a202c;
    color: #e2e8f0;
}

/* Badge text visibility */
body.theme-light .badge,
body.theme-dark .badge {
    color: #fff !important;
}

/* Specific badge colors for better visibility */
body.theme-light .badge.bg-info {
    background-color: #17a2b8 !important;
    color: #fff !important;
}

body.theme-dark .badge.bg-info {
    background-color: #3182ce !important;
    color: #fff !important;
}

/* LIVE badge sits on a light green gradient (see app.scss .badge.bg-success) */
.badge.bg-success.pulse-badge {
    color: #14532d !important;
}

/* Table text visibility */
body.theme-dark .table {
    color: #e2e8f0;
}

body.theme-dark .table td,
body.theme-dark .table th {
    border-color: #4a5568;
}

/* Form controls in dark mode */
body.theme-dark .form-control {
    background-color: #2d3748;
    border-color: #4a5568;
    color: #e2e8f0;
}

body.theme-dark .form-control:focus {
    background-color: #2d3748;
    border-color: #4299e1;
    color: #e2e8f0;
}

/* Labels in both modes */
body.theme-dark label {
    color: #e2e8f0;
}

body.theme-light label {
    color: #2d3748;
}

/* Loading and error messages */
body.theme-dark .text-muted {
    color: #a0aec0 !important;
}

body.theme-light .text-muted {
    color: #718096 !important;
}

/* Loading message text */
body.theme-dark .card-body p {
    color: #e2e8f0;
}

body.theme-light .card-body p {
    color: #2d3748;
}

/* Button text visibility */
body.theme-dark .btn {
    color: #fff;
}

/* Driver status pill in the Active Drivers table.
   Bootstrap 5 has no .badge-success/.badge-warning and .badge defaults to white
   text, so this is styled standalone: dark text on a light pill in both themes. */
.status-badge {
    display: inline-block;
    padding: 0.35rem 0.75rem;
    border-radius: 0.5rem;
    font-size: 0.875rem;
    font-weight: 600;
    line-height: 1.2;
    white-space: nowrap;
    color: #1a202c !important;
}

.status-badge.status-delivering {
    background-color: #a7f3d0;
    border: 1px solid #34d399;
}

.status-badge.status-idle {
    background-color: #fde68a;
    border: 1px solid #f59e0b;
}

/* Strong tags in tables */
body.theme-dark .table strong {
    color: #f7fafc;
}

body.theme-light .table strong {
    color: #1a202c;
}

/* Small text in headers */
body.theme-dark .card-header small {
    color: #cbd5e0;
}

body.theme-light .card-header small {
    color: #718096;
}

/* Stats List Styles */
.stats-list {
    padding: 15px 20px;
    border-radius: 8px;
}

body.theme-dark .stats-list {
    background-color: #1a202c;
}

body.theme-light .stats-list {
    background-color: #f8f9fa;
}

.stat-item {
    display: flex;
    align-items: center;
    gap: 8px;
}

.stat-dot {
    width: 12px;
    height: 12px;
    border-radius: 50%;
    display: inline-block;
}

.stat-label {
    font-size: 14px;
    font-weight: 500;
}

body.theme-dark .stat-label {
    color: #cbd5e0;
}

body.theme-light .stat-label {
    color: #4a5568;
}

.stat-value {
    font-size: 18px;
    font-weight: 700;
}

body.theme-dark .stat-value {
    color: #f7fafc;
}

body.theme-light .stat-value {
    color: #1a202c;
}

@media (max-width: 768px) {
    #live-tracking-map {
        height: 400px !important;
    }

    .stats-list {
        flex-direction: column;
        align-items: flex-start !important;
        gap: 12px;
    }
}
</style>
