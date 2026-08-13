import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:project/helper/utils/generalImports.dart';

class MapScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;

  const MapScreen({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
  }) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  LatLng? _currentPosition;
  String _currentAddress = '';
  bool _isLoading = true;
  Set<Marker> _markers = {};
  
  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _currentPosition = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _currentAddress = widget.initialAddress ?? '';
      _addMarker(_currentPosition!);
    } else {
      await _getCurrentLocation();
    }
    
    if (_currentAddress.isEmpty && _currentPosition != null) {
      await _getAddressFromLatLng(_currentPosition!);
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          showMessage(context, 'Location permissions are denied', MessageType.error);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        showMessage(context, 'Location permissions are permanently denied', MessageType.error);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      _currentPosition = LatLng(position.latitude, position.longitude);
      _addMarker(_currentPosition!);
      
      if (_controller != null) {
        _controller!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition!, 15.0),
        );
      }
    } catch (e) {
      showMessage(context, 'Error getting current location: $e', MessageType.error);
    }
  }

  void _addMarker(LatLng position) {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('selected_location'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
        });
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _currentPosition = position;
      _addMarker(position);
    });
    _getAddressFromLatLng(position);
  }

  void _onConfirmLocation() {
    if (_currentPosition != null) {
      Navigator.pop(context, {
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'address': _currentAddress,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomTextLabel(
          text: 'Select Location',
          style: TextStyle(
            color: ColorsRes.mainTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Theme.of(context).cardColor,
        iconTheme: IconThemeData(color: ColorsRes.mainTextColor),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: ColorsRes.appColor,
              ),
            )
          : Column(
              children: [
                // Address display
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  color: Theme.of(context).cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextLabel(
                        text: 'Selected Address:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ColorsRes.appColor,
                        ),
                      ),
                      getSizedBox(height: 8),
                      CustomTextLabel(
                        text: _currentAddress.isEmpty ? 'Tap on map to select location' : _currentAddress,
                        style: TextStyle(
                          fontSize: 13,
                          color: ColorsRes.subTitleTextColor,
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                // Map
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition ?? const LatLng(23.0225, 72.5714), // Default to Ahmedabad
                      zoom: 15.0,
                    ),
                    markers: _markers,
                    onMapCreated: (GoogleMapController controller) {
                      _controller = controller;
                      if (_currentPosition != null) {
                        controller.animateCamera(
                          CameraUpdate.newLatLngZoom(_currentPosition!, 15.0),
                        );
                      }
                    },
                    onTap: _onMapTap,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                ),
                // Confirm button
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  color: Theme.of(context).cardColor,
                  child: ElevatedButton(
                    onPressed: _currentPosition != null ? _onConfirmLocation : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsRes.appColor,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: CustomTextLabel(
                      text: 'Confirm Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}