<template>
    <div class="p-3">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <div>
                <h5 class="mb-1">Track</h5>
                <p class="text-muted mb-0">Track delivery boy location and activity.</p>
            </div>
            <div v-if="lastUpdated && !isLoading" class="text-end">
                <small class="text-muted">
                    <i class="fa fa-clock"></i> Last Updated: {{ formatTime(lastUpdated) }}
                </small>
            </div>
        </div>
        <hr>

        <!-- Loading State -->
        <div class="text-center py-5" v-if="isLoading">
            <b-spinner class="align-middle"></b-spinner>
            <strong class="ms-2">{{ __('loading') }}...</strong>
        </div>

        <!-- Location Info -->
        <div v-if="!isLoading && googleApiKey && deliveryBoyLocation" class="alert alert-info mb-3">
            <div class="row align-items-center">
                <div class="col-md-8">
                    <div class="d-flex align-items-center">
                        <i class="fa fa-map-marker-alt fa-2x text-danger me-3"></i>
                        <div>
                            <strong class="d-block" style="font-size: 1.1rem;">
                                <span v-if="isLoadingPlace">
                                    <b-spinner small class="me-2"></b-spinner>
                                    Loading location...
                                </span>
                                <span v-else>{{ placeName || 'Unknown Location' }}</span>
                            </strong>
                            <!-- Commented out coordinates display -->
                            <!-- <small class="text-muted">
                                {{ deliveryBoyLocation.latitude }}, {{ deliveryBoyLocation.longitude }}
                            </small> -->
                        </div>
                    </div>
                </div>
                <div class="col-md-4 text-end">
                    <strong>Status:</strong> <span class="badge bg-success" style="font-size: 0.9rem; padding: 0.4rem 0.8rem;">{{ deliveryBoyLocation.status || 'Available' }}</span>
                </div>
            </div>
        </div>

        <!-- Google Maps Container -->
        <div v-show="!isLoading && googleApiKey" id="delivery-boy-map" style="width: 100%; height: 500px; border-radius: 8px;"></div>

        <!-- Error State -->
        <div class="alert alert-warning" v-if="!isLoading && !googleApiKey">
            <i class="fa fa-exclamation-triangle"></i>
            Google Maps API Key is not configured. Please configure it in Store Settings.
        </div>
    </div>
</template>

<script>
export default {
    props: {
        deliveryBoyId: {
            type: [String, Number],
            required: true
        }
    },
    data() {
        return {
            isLoading: false,
            googleApiKey: null,
            mapReady: false,
            map: null,
            marker: null,
            locationUpdateInterval: null,
            deliveryBoyLocation: null,
            lastUpdated: null,
            placeName: null,
            isLoadingPlace: false,
            // Hyderabad coordinates (default)
            defaultLocation: {
                lat: 17.385044,
                lng: 78.486671
            }
        };
    },
    mounted() {
        this.initializeMap();
    },
    beforeDestroy() {
        // Clear interval when component is destroyed
        if (this.locationUpdateInterval) {
            clearInterval(this.locationUpdateInterval);
        }
    },
    methods: {
        async initializeMap() {
            this.isLoading = true;

            try {
                // Fetch settings to get Google Maps API key
                await this.fetchGoogleApiKey();

                if (this.googleApiKey) {
                    // Load Google Maps script
                    await this.loadGoogleMapsScript();
                    // Fetch delivery boy location
                    await this.fetchDeliveryBoyLocation();
                    // Initialize the map
                    this.createMap();
                    // Start periodic location updates (every 1 minute)
                    this.startLocationUpdates();
                }
            } catch (error) {
                console.error('Error initializing map:', error);
                this.showError('Failed to initialize map');
            } finally {
                this.isLoading = false;
            }
        },

        async fetchDeliveryBoyLocation() {
            try {
                const response = await axios.get(
                    `${this.$apiUrl}/delivery_boys/${this.deliveryBoyId}/location`
                );

                if (response.data.status === 1 && response.data.data) {
                    this.deliveryBoyLocation = response.data.data;
                    this.lastUpdated = new Date();

                    // Fetch place name using reverse geocoding
                    await this.fetchPlaceName();

                    // Update marker position if map is already created
                    if (this.map && this.marker) {
                        this.updateMarkerPosition();
                    }
                }
            } catch (error) {
                console.error('Error fetching delivery boy location:', error);
                // If there's an error or no location, we'll use default location
            }
        },

        async fetchPlaceName() {
            if (!this.deliveryBoyLocation || !this.deliveryBoyLocation.latitude || !this.deliveryBoyLocation.longitude) {
                return;
            }

            this.isLoadingPlace = true;

            try {
                // Wait for Google Maps to be loaded
                if (!window.google || !window.google.maps) {
                    console.warn('Google Maps not loaded yet');
                    this.isLoadingPlace = false;
                    return;
                }

                const geocoder = new google.maps.Geocoder();
                const latlng = {
                    lat: parseFloat(this.deliveryBoyLocation.latitude),
                    lng: parseFloat(this.deliveryBoyLocation.longitude)
                };

                geocoder.geocode({ location: latlng }, (results, status) => {
                    this.isLoadingPlace = false;

                    if (status === 'OK' && results[0]) {
                        // Build complete address: neighborhood, area, city
                        const addressComponents = results[0].address_components;
                        let placeParts = [];

                        // Get neighborhood or premise
                        let neighborhood = null;
                        for (let component of addressComponents) {
                            if (component.types.includes('neighborhood') ||
                                component.types.includes('premise') ||
                                component.types.includes('sublocality_level_3')) {
                                neighborhood = component.long_name;
                                break;
                            }
                        }
                        if (neighborhood) placeParts.push(neighborhood);

                        // Get sublocality (area) - level 2 or level 1
                        let sublocality = null;
                        for (let component of addressComponents) {
                            if (component.types.includes('sublocality_level_2') ||
                                component.types.includes('sublocality_level_1')) {
                                sublocality = component.long_name;
                                break;
                            }
                        }
                        if (sublocality && sublocality !== neighborhood) {
                            placeParts.push(sublocality);
                        }

                        // Get locality (city)
                        let locality = null;
                        for (let component of addressComponents) {
                            if (component.types.includes('locality')) {
                                locality = component.long_name;
                                break;
                            }
                        }
                        if (locality && !placeParts.includes(locality)) {
                            placeParts.push(locality);
                        }

                        // If we have parts, join them
                        if (placeParts.length > 0) {
                            this.placeName = placeParts.join(', ');
                        } else {
                            // Fallback to formatted address (first 3 parts)
                            const formatted = results[0].formatted_address;
                            const parts = formatted.split(',');
                            this.placeName = parts.slice(0, 3).join(',');
                        }
                    } else {
                        console.warn('Geocoder failed:', status);
                        this.placeName = 'Location unavailable';
                    }
                });
            } catch (error) {
                console.error('Error fetching place name:', error);
                this.isLoadingPlace = false;
                this.placeName = 'Location unavailable';
            }
        },

        startLocationUpdates() {
            // Update location every 1 minute (60000 milliseconds)
            this.locationUpdateInterval = setInterval(() => {
                this.fetchDeliveryBoyLocation();
            }, 60000);
        },

        async fetchGoogleApiKey() {
            try {
                const response = await axios.get(this.$apiUrl + '/store_settings');
                const settings = response.data.data.store_settings;

                // Try to find the Google Maps API key from settings
                const googleMapSetting = settings.find(setting =>
                    setting.variable === 'googleMapApiKey' ||
                    setting.variable === 'google_map_api_key' ||
                    setting.variable === 'google_place_api_key'
                );

                if (googleMapSetting && googleMapSetting.value) {
                    this.googleApiKey = googleMapSetting.value;
                }
            } catch (error) {
                console.error('Error fetching Google API key:', error);
                throw error;
            }
        },

        loadGoogleMapsScript() {
            return new Promise((resolve, reject) => {
                // Check if Google Maps is already loaded
                if (window.google && window.google.maps) {
                    resolve();
                    return;
                }

                // Check if script is already being loaded
                if (document.querySelector('script[src*="maps.googleapis.com"]')) {
                    // Wait for it to load
                    const checkGoogleMaps = setInterval(() => {
                        if (window.google && window.google.maps) {
                            clearInterval(checkGoogleMaps);
                            resolve();
                        }
                    }, 100);
                    return;
                }

                // Set up callback for Google Maps
                window.initGoogleMaps = () => {
                    resolve();
                    delete window.initGoogleMaps;
                };

                // Create and load the script with callback
                const script = document.createElement('script');
                script.src = `https://maps.googleapis.com/maps/api/js?key=${this.googleApiKey}&libraries=places&callback=initGoogleMaps&loading=async`;
                script.async = true;
                script.defer = true;

                script.onerror = () => {
                    reject(new Error('Failed to load Google Maps script'));
                    delete window.initGoogleMaps;
                };

                document.head.appendChild(script);
            });
        },

        createMap() {
            // Use $nextTick to ensure DOM is fully rendered
            this.$nextTick(() => {
                try {
                    const mapElement = document.getElementById('delivery-boy-map');

                    if (!mapElement) {
                        console.error('Map element not found in DOM');
                        return;
                    }

                    // Determine initial center - use delivery boy location if available
                    const initialCenter = this.deliveryBoyLocation && this.deliveryBoyLocation.latitude && this.deliveryBoyLocation.longitude
                        ? {
                            lat: parseFloat(this.deliveryBoyLocation.latitude),
                            lng: parseFloat(this.deliveryBoyLocation.longitude)
                        }
                        : this.defaultLocation;

                    // Initialize the map with dark mode
                    this.map = new google.maps.Map(mapElement, {
                        center: initialCenter,
                        zoom: 15,
                        mapTypeId: 'roadmap',
                        streetViewControl: false,
                        mapTypeControl: true,
                        fullscreenControl: true,
                        zoomControl: true,
                        // Dark mode styling
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

                    // Add a marker at the location with modern scooter icon
                    this.marker = new google.maps.Marker({
                        position: initialCenter,
                        map: this.map,
                        title: 'Delivery Boy Location',
                        animation: google.maps.Animation.DROP,
                        icon: {
                            url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(`
                                <svg xmlns="http://www.w3.org/2000/svg" width="80" height="80" viewBox="0 0 80 80">
                                    <!-- Shadow -->
                                    <ellipse cx="40" cy="72" rx="22" ry="3" fill="rgba(0,0,0,0.4)"/>

                                    <!-- Modern Electric Scooter -->
                                    <g transform="translate(40, 40)">
                                        <!-- Back wheel - modern alloy -->
                                        <circle cx="-12" cy="12" r="7" fill="#1a1a1a" stroke="#00E676" stroke-width="1"/>
                                        <circle cx="-12" cy="12" r="5" fill="#2a2a2a"/>
                                        <circle cx="-12" cy="12" r="2.5" fill="#00E676"/>
                                        <circle cx="-12" cy="12" r="1" fill="#1a1a1a"/>

                                        <!-- Front wheel - modern alloy -->
                                        <circle cx="12" cy="12" r="7" fill="#1a1a1a" stroke="#00E676" stroke-width="1"/>
                                        <circle cx="12" cy="12" r="5" fill="#2a2a2a"/>
                                        <circle cx="12" cy="12" r="2.5" fill="#00E676"/>
                                        <circle cx="12" cy="12" r="1" fill="#1a1a1a"/>

                                        <!-- Scooter deck/platform -->
                                        <rect x="-12" y="8" width="24" height="3" rx="1.5" fill="#212121" stroke="#00E676" stroke-width="0.5"/>

                                        <!-- Battery pack under deck -->
                                        <rect x="-8" y="9" width="16" height="2" rx="1" fill="#00E676" opacity="0.3"/>

                                        <!-- Front fork -->
                                        <path d="M 12,12 L 12,-8" stroke="#212121" stroke-width="3" stroke-linecap="round"/>

                                        <!-- Handlebar -->
                                        <line x1="5" y1="-8" x2="19" y2="-8" stroke="#212121" stroke-width="2.5" stroke-linecap="round"/>
                                        <circle cx="5" cy="-8" r="1.5" fill="#00E676"/>
                                        <circle cx="19" cy="-8" r="1.5" fill="#00E676"/>

                                        <!-- Modern headlight -->
                                        <circle cx="12" cy="-6" r="2" fill="#00E676" opacity="0.8"/>
                                        <circle cx="12" cy="-6" r="1.2" fill="#FFF"/>

                                        <!-- Digital display -->
                                        <rect x="10" y="-11" width="4" height="2.5" rx="0.5" fill="#1a1a1a" stroke="#00E676" stroke-width="0.5"/>
                                        <line x1="10.5" y1="-9.5" x2="13.5" y2="-9.5" stroke="#00E676" stroke-width="0.3"/>

                                        <!-- Rear suspension -->
                                        <path d="M -12,12 L -10,5 L -8,8" stroke="#FF5722" stroke-width="2" fill="none" stroke-linecap="round"/>

                                        <!-- Seat - modern sporty -->
                                        <path d="M -8,3 Q -4,1 0,3 Q 4,1 8,3 L 6,6 L -6,6 Z" fill="#212121" stroke="#00E676" stroke-width="0.5"/>
                                        <ellipse cx="0" cy="4" rx="6" ry="1.5" fill="#00E676" opacity="0.2"/>

                                        <!-- Delivery person - modern rider -->
                                        <!-- Head with modern helmet -->
                                        <circle cx="0" cy="-12" r="5" fill="#FFD54F"/>
                                        <circle cx="-1.2" cy="-13" r="0.7" fill="#212121"/>
                                        <circle cx="1.2" cy="-13" r="0.7" fill="#212121"/>

                                        <!-- Modern full-face helmet -->
                                        <path d="M -5,-12 Q -6,-18 0,-20 Q 6,-18 5,-12" fill="#00E676" stroke="#00BFA5" stroke-width="1"/>
                                        <!-- Helmet visor -->
                                        <path d="M -4,-13 Q 0,-15 4,-13" stroke="#1a1a1a" stroke-width="1.5" fill="none" opacity="0.6"/>
                                        <ellipse cx="0" cy="-18" rx="2" ry="1" fill="#FFF" opacity="0.4"/>

                                        <!-- Body - modern jacket -->
                                        <path d="M -3,-8 L -4,2 L -2,2 L -1,-8 Z" fill="#00BFA5"/>
                                        <path d="M 3,-8 L 4,2 L 2,2 L 1,-8 Z" fill="#00BFA5"/>
                                        <rect x="-3" y="-8" width="6" height="10" rx="2" fill="#00E676"/>

                                        <!-- Reflective stripe -->
                                        <rect x="-3" y="-4" width="6" height="1" fill="#FFD700" opacity="0.8"/>

                                        <!-- Arms reaching handlebar -->
                                        <path d="M -3,-6 Q -5,-2 5,-8" stroke="#00BFA5" stroke-width="3" stroke-linecap="round"/>
                                        <path d="M 3,-6 Q 8,-4 19,-8" stroke="#00BFA5" stroke-width="3" stroke-linecap="round"/>

                                        <!-- Hands with gloves -->
                                        <circle cx="5" cy="-8" r="1.8" fill="#212121"/>
                                        <circle cx="19" cy="-8" r="1.8" fill="#212121"/>

                                        <!-- Legs -->
                                        <path d="M -1.5,2 L -4,10" stroke="#1a1a1a" stroke-width="3.5" stroke-linecap="round"/>
                                        <path d="M 1.5,2 L 5,10" stroke="#1a1a1a" stroke-width="3.5" stroke-linecap="round"/>

                                        <!-- Modern shoes/boots -->
                                        <ellipse cx="-4" cy="10" rx="2.5" ry="2" fill="#212121" stroke="#00E676" stroke-width="0.5"/>
                                        <ellipse cx="5" cy="10" rx="2.5" ry="2" fill="#212121" stroke="#00E676" stroke-width="0.5"/>

                                        <!-- Modern delivery box - insulated bag -->
                                        <rect x="-20" y="-8" width="8" height="10" rx="1.5" fill="#FF6B00" stroke="#FF5722" stroke-width="1"/>
                                        <rect x="-19.5" y="-7.5" width="7" height="9" rx="1" fill="#FF7B00" opacity="0.3"/>
                                        <!-- Logo -->
                                        <circle cx="-16" cy="-3" r="2.5" fill="#FFF"/>
                                        <text x="-17.5" y="-1" font-size="4" fill="#FF5722" font-weight="bold">Z</text>
                                        <!-- Zipper -->
                                        <line x1="-16" y1="-8" x2="-16" y2="2" stroke="#FFD700" stroke-width="0.8"/>
                                        <!-- Handle -->
                                        <path d="M -18,-9 Q -16,-11 -14,-9" stroke="#212121" stroke-width="1.5" fill="none"/>
                                    </g>

                                    <!-- Modern pulse effect -->
                                    <circle cx="40" cy="40" r="34" fill="none" stroke="#00E676" stroke-width="2.5" opacity="0.4">
                                        <animate attributeName="r" from="25" to="38" dur="1.5s" repeatCount="indefinite"/>
                                        <animate attributeName="opacity" from="0.6" to="0" dur="1.5s" repeatCount="indefinite"/>
                                    </circle>

                                    <!-- Secondary pulse -->
                                    <circle cx="40" cy="40" r="28" fill="none" stroke="#00BFA5" stroke-width="2" opacity="0.3">
                                        <animate attributeName="r" from="20" to="32" dur="1.5s" repeatCount="indefinite"/>
                                        <animate attributeName="opacity" from="0.5" to="0" dur="1.5s" repeatCount="indefinite"/>
                                    </circle>
                                </svg>
                            `),
                            scaledSize: new google.maps.Size(80, 80),
                            anchor: new google.maps.Point(40, 40)
                        }
                    });

                    // Add info window
                    this.updateInfoWindow();

                    this.mapReady = true;
                } catch (error) {
                    console.error('Error creating map:', error);
                    this.showError('Failed to create map');
                }
            });
        },

        updateMarkerPosition() {
            if (!this.deliveryBoyLocation || !this.deliveryBoyLocation.latitude || !this.deliveryBoyLocation.longitude) {
                return;
            }

            const newPosition = {
                lat: parseFloat(this.deliveryBoyLocation.latitude),
                lng: parseFloat(this.deliveryBoyLocation.longitude)
            };

            // Animate marker to new position
            this.marker.setPosition(newPosition);
            this.map.panTo(newPosition);

            // Update info window
            this.updateInfoWindow();
        },

        updateInfoWindow() {
            const locationInfo = this.deliveryBoyLocation ? `
                <div style="padding: 12px; min-width: 200px;">
                    <h6 style="margin: 0 0 8px 0; font-weight: bold; color: #1976D2;">
                        <i class="fa fa-map-marker-alt" style="color: #FF5722;"></i> Delivery Boy Location
                    </h6>
                    <div style="margin: 0; font-size: 13px; color: #333; line-height: 1.6;">
                        ${this.placeName ? `<div style="margin-bottom: 6px;"><strong>📍 Location:</strong> ${this.placeName}</div>` : ''}
                        <div style="margin-bottom: 4px;"><strong>Status:</strong> <span style="color: #4CAF50; font-weight: bold;">${this.deliveryBoyLocation.status || 'Available'}</span></div>
                        <div style="font-size: 11px; color: #666; margin-top: 6px; padding-top: 6px; border-top: 1px solid #eee;">
                            ${this.deliveryBoyLocation.latitude}, ${this.deliveryBoyLocation.longitude}<br>
                            <strong>Last Updated:</strong> ${this.lastUpdated ? this.lastUpdated.toLocaleString() : 'N/A'}
                        </div>
                    </div>
                </div>
            ` : `
                <div style="padding: 12px;">
                    <h6 style="margin: 0 0 8px 0; font-weight: bold; color: #1976D2;">Hyderabad</h6>
                    <p style="margin: 0; font-size: 12px; color: #666;">
                        Default Location<br>
                        ${this.defaultLocation.lat}, ${this.defaultLocation.lng}
                    </p>
                </div>
            `;

            const infoWindow = new google.maps.InfoWindow({
                content: locationInfo
            });

            this.marker.addListener('click', () => {
                infoWindow.open(this.map, this.marker);
            });
        },

        formatTime(date) {
            if (!date) return 'N/A';
            const now = new Date();
            const diff = Math.floor((now - date) / 1000); // difference in seconds

            if (diff < 60) return 'Just now';
            if (diff < 3600) return `${Math.floor(diff / 60)} min ago`;
            if (diff < 86400) return `${Math.floor(diff / 3600)} hours ago`;

            return date.toLocaleString();
        }
    }
};
</script>

<style scoped>
#delivery-boy-map {
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}
</style>
