import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;

Future<bool> ensureLocationPermission(BuildContext context) async {
  LocationPermission status = await Geolocator.checkPermission();
  if (status == LocationPermission.denied) {
    status = await Geolocator.requestPermission();
  }
  if (status == LocationPermission.deniedForever) {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Permission Needed"),
        content: Text(
            "Location permission is required. Please enable it in settings."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))
        ],
      ),
    );
    return false;
  }
  return status == LocationPermission.whileInUse ||
      status == LocationPermission.always;
}

class AddressLocationPickerScreen extends StatefulWidget {
  @override
  State<AddressLocationPickerScreen> createState() =>
      _AddressLocationPickerScreenState();
}

class _AddressLocationPickerScreenState
    extends State<AddressLocationPickerScreen> {
  GoogleMapController? mapController;
  LatLng? selectedLatLng;
  String address = "";
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    setInitialPosition();
  }

  Future<void> setInitialPosition() async {
    bool granted = await ensureLocationPermission(context);
    if (!granted) return;
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (_) {}
    setState(() {
      selectedLatLng = pos != null
          ? LatLng(pos.latitude, pos.longitude)
          : LatLng(17.414, 78.448); // fallback: Hyderabad
    });
    if (selectedLatLng != null) getAddressFromLatLng(selectedLatLng!);
  }

  Future<void> getAddressFromLatLng(LatLng ll) async {
    setState(() => isLoading = true);
    try {
      var list = await geo.placemarkFromCoordinates(ll.latitude, ll.longitude);
      if (list.isNotEmpty) {
        final pm = list.first;
        setState(() {
          final items = <String>[
            pm.name ?? '',
            pm.subLocality ?? '',
            pm.locality ?? '',
            pm.subAdministrativeArea ?? '',
            pm.administrativeArea ?? '',
            pm.postalCode ?? ''
          ].where((v) => v.isNotEmpty).toList();
          address = items.join(', ');
        });
      }
    } catch (_) {
      setState(() => address = "");
    }
    setState(() => isLoading = false);
  }

  void onMapTap(LatLng ll) {
    setState(() {
      selectedLatLng = ll;
      address = "";
    });
    getAddressFromLatLng(ll);
  }

  Future<void> searchAndMove(String query) async {
    if (query.isEmpty) return;
    setState(() {
      isLoading = true;
    });
    try {
      final locations = await geo.locationFromAddress(query);
      if (locations.isNotEmpty) {
        final ll = LatLng(locations.first.latitude, locations.first.longitude);
        setState(() {
          selectedLatLng = ll;
        });
        if (mapController != null) {
          mapController!.animateCamera(CameraUpdate.newLatLngZoom(ll, 16));
        }
        getAddressFromLatLng(ll);
      }
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("No results for '$query'")));
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0XFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text('Add Address Details',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, color: Colors.black)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(99),
              color: Colors.white,
              child: TextField(
                controller: searchController,
                style: GoogleFonts.inter(),
                decoration: InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 0, horizontal: 18),
                  hintText: "Search address",
                  hintStyle:
                      GoogleFonts.inter(color: Colors.grey, fontSize: 16),
                  border: InputBorder.none,
                  suffixIcon: Icon(Icons.search, color: Color(0xFFA4A9B6)),
                ),
                onSubmitted: searchAndMove,
              ),
            ),
          ),
          SizedBox(
            height: 260,
            child: selectedLatLng == null
                ? Center(child: CircularProgressIndicator())
                : ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: GoogleMap(
                      initialCameraPosition:
                          CameraPosition(target: selectedLatLng!, zoom: 15),
                      onMapCreated: (gm) => mapController = gm,
                      markers: selectedLatLng != null
                          ? {
                              Marker(
                                markerId: MarkerId("picked"),
                                position: selectedLatLng!,
                                draggable: true,
                                onDragEnd: onMapTap,
                              ),
                            }
                          : {},
                      onTap: onMapTap,
                      myLocationButtonEnabled: true,
                      myLocationEnabled: true,
                      zoomControlsEnabled: false,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, top: 24),
            child: Material(
              color: Colors.white,
              elevation: 6,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address.isNotEmpty ? address.split(",")[0] : "",
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.black),
                          ),
                          SizedBox(height: 4),
                          Text(
                            address,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
            child: SizedBox(
              height: 54,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: address.isEmpty
                    ? null
                    : () => Navigator.pop(context, address),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF9AC444),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                child: Text(
                  "Confirm address",
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
