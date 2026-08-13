import 'dart:ui' as ui;
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/services/googleRoutesApiService.dart';


class OrderTrackerScreen extends StatefulWidget {
  final double addressLatitude;
  final double addressLongitude;
  final String address;
  final String orderId;
  final String deliveryBoyName;
  final String deliveryBoyNumber;

  const OrderTrackerScreen({
    Key? key,
    required this.addressLatitude,
    required this.addressLongitude,
    required this.address,
    required this.orderId,
    required this.deliveryBoyName,
    required this.deliveryBoyNumber,
  }) : super(key: key);

  @override
  State<OrderTrackerScreen> createState() => _OrderTrackerScreenState();
}

class _OrderTrackerScreenState extends State<OrderTrackerScreen> {
  late GoogleMapController controller;
  late CameraPosition kGooglePlex;
  late LatLng kMapCenter;
  double mapZoom = 14.4746;

  String googleMapCurrentStyle = "[]";

  late LatLng SOURCE;
  late LatLng DEST;
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  late BitmapDescriptor deliveryBoyIcon;
  late BitmapDescriptor customerIcon;

  Set<Marker> _markers = {};

  late Timer? timer;

  // Route information
  String routeDistance = "Calculating...";
  String routeDuration = "Calculating...";
  double routeDistanceValue = 0; // in meters
  double routeDurationValue = 0; // in seconds
  bool isLoadingRoute = true;
  List<LatLng> waypointCoordinates = []; // All waypoint coordinates

  callApi() async {
    deliveryBoyIcon = await bitmapDescriptorFromSvgAsset(
        context, Constant.getAssetsPath(1, "delivery_boy"));

    customerIcon = await bitmapDescriptorFromSvgAsset(
        context, Constant.getAssetsPath(1, "customer_location"));

    await getDeliveryBoyLocation();

    timer = Timer.periodic(Duration(seconds: 30), (timer) async {
      await getDeliveryBoyLocation();
    });
  }

  getDeliveryBoyLocation() async {
    context.read<LiveOrderTrackingProvider>().getLiveOrderTrackingApiProvider(
      context: context,
      params: {
        ApiAndParams.orderId: widget.orderId,
      },
    ).then((value) async {
      DEST = LatLng(widget.addressLatitude,
          widget.addressLongitude); // Customer destination

      SOURCE = LatLng(
          context.read<LiveOrderTrackingProvider>().deliveryBoyLatitude,
          context
              .read<LiveOrderTrackingProvider>()
              .deliveryBoyLongitude); // Delivery boy current location

      // Fetch real route polylines
      await getRouteAndPolylines(SOURCE, DEST);

      _markers.clear();
      _markers.add(
        Marker(
          markerId: MarkerId('SOURCE'),
          position: SOURCE,
          icon: deliveryBoyIcon,
          infoWindow: InfoWindow(
            title: widget.deliveryBoyName,
            snippet: "Delivery Boy",
          ),
        ),
      );

      _markers.add(
        Marker(
          markerId: MarkerId('DEST'),
          position: DEST,
          icon: customerIcon,
          infoWindow: InfoWindow(
            title: widget.address,
            snippet: "Delivery Location",
          ),
        ),
      );

      // Add waypoint markers for intermediate route points
      if (waypointCoordinates.isNotEmpty) {
        for (int i = 0; i < waypointCoordinates.length; i++) {
          final waypoint = waypointCoordinates[i];
          // Skip if it's the same as source or destination
          if ((waypoint.latitude != SOURCE.latitude ||
                  waypoint.longitude != SOURCE.longitude) &&
              (waypoint.latitude != DEST.latitude ||
                  waypoint.longitude != DEST.longitude)) {
            _markers.add(
              Marker(
                markerId: MarkerId('waypoint_$i'),
                position: waypoint,
                infoWindow: InfoWindow(
                  title: "Waypoint ${i + 1}",
                ),
              ),
            );
          }
        }
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  // Get route polylines and calculate distance/duration
  Future<void> getRouteAndPolylines(LatLng origin, LatLng destination) async {
    try {
      setState(() {
        isLoadingRoute = true;
      });

      final routesService = GoogleRoutesApiService();
      final response = await routesService.computeRoute(
        origin: origin,
        destination: destination,
        context: context,
      );

      if (response != null && response.routes.isNotEmpty) {
        final route = response.routes.first;
        waypointCoordinates.clear();

        // Extract distance and duration
        routeDistanceValue = route.distanceMeters.toDouble();
        routeDurationValue = route.getDurationInSeconds();

        // Format distance
        if (routeDistanceValue >= 1000) {
          routeDistance = '${(routeDistanceValue / 1000).toStringAsFixed(2)} km';
        } else {
          routeDistance = '${routeDistanceValue.toStringAsFixed(0)} m';
        }

        // Format duration
        final minutes = (routeDurationValue / 60).toInt();
        final hours = minutes ~/ 60;
        final remainingMinutes = minutes % 60;

        if (hours > 0) {
          routeDuration = '$hours h $remainingMinutes min';
        } else {
          routeDuration = '$remainingMinutes min';
        }

        // Use decoded polyline from Routes API response
        polylineCoordinates = route.decodedPolyline;

        if (polylineCoordinates.isNotEmpty) {
          final firstPoint = polylineCoordinates.first;
          final lastPoint = polylineCoordinates.last;
          debugPrint('Route Summary:');
          debugPrint('  Total points: ${polylineCoordinates.length}');
          debugPrint('  Distance: $routeDistance');
          debugPrint('  Duration: $routeDuration');
          debugPrint('  Start: ${firstPoint.latitude}, ${firstPoint.longitude}');
          debugPrint('  End: ${lastPoint.latitude}, ${lastPoint.longitude}');
        }
      } else {
        // API error or no response - use straight line
        debugPrint('❌ Routes API failed, using straight line fallback');
        polylineCoordinates = [origin, destination];
        routeDistance = "Error";
        routeDuration = "Error";
      }

      if (mounted) {
        setState(() {
          isLoadingRoute = false;
        });
      }
    } catch (e) {
      debugPrint('Error getting route: $e');
      polylineCoordinates = [origin, destination];
      routeDistance = "Error";
      routeDuration = "Error";

      if (mounted) {
        setState(() {
          isLoadingRoute = false;
        });
      }
    }
  }

  // Decode polyline points from Google Directions API
  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return poly;
  }

  //street router
  /* Future<List<LatLng>> getRoutePoints(LatLng origin, LatLng destination) async {
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=${Constant.googleApiKey}';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final points = data['routes'][0]['overview_polyline']['points'];
      return decodePolyline(points);
    } else {
      return [origin, destination];
    }
  } */

  //street router
  /* List<LatLng> decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return poly;
  } */

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero).then((value) async {
      kMapCenter = LatLng(widget.addressLatitude, widget.addressLongitude);

      kGooglePlex = CameraPosition(
        target: kMapCenter,
        zoom: mapZoom,
      );

      googleMapCurrentStyle =
          Constant.session.getBoolData(SessionManager.isDarkTheme)
              ? await rootBundle.loadString(Constant.getAssetsPath(5, "nightMode"))
              : await rootBundle.loadString(Constant.getAssetsPath(5, "dayMode"));
      await checkPermission();

      callApi();
    });
  }

  checkPermission() async {
    await hasLocationPermissionGiven().then(
      (value) async {
        if (value is PermissionStatus) {
          if (value.isDenied) {
            await Permission.location.request();
          } else if (value.isPermanentlyDenied) {
            if (!Constant.session.getBoolData(
                SessionManager.keyPermissionLocationHidePromptPermanently)) {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Wrap(
                    children: [
                      PermissionHandlerBottomSheet(
                        titleJsonKey: locationPermissionTitleLabel,
                        messageJsonKey: locationPermissionMessageLabel,
                        sessionKeyForAskNeverShowAgain: SessionManager
                            .keyPermissionLocationHidePromptPermanently,
                      ),
                    ],
                  );
                },
              );
            }
          }
        }
      },
    );
  }

  updateMap(double latitude, double longitude) {
    kMapCenter = LatLng(latitude, longitude);
    kGooglePlex = CameraPosition(
      target: kMapCenter,
      zoom: mapZoom,
    );

    _markers.add(
      Marker(
        markerId: MarkerId('SOURCE'),
        position: SOURCE,
        icon: deliveryBoyIcon,
      ),
    );

    controller.animateCamera(CameraUpdate.newCameraPosition(kGooglePlex));
  }

  Future<BitmapDescriptor> bitmapDescriptorFromSvgAsset(
      BuildContext context, String assetName) async {
    // Read SVG file as String
    String svgString =
        await DefaultAssetBundle.of(context).loadString(assetName);
    // Create DrawableRoot from SVG String
    final PictureInfo pictureInfo =
        await vg.loadPicture(SvgStringLoader(svgString), null);

    double width = 39;
    double height = 50;

    // Convert to ui.Picture
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);

    canvas.scale(
        width / pictureInfo.size.width, height / pictureInfo.size.height);
    canvas.drawPicture(pictureInfo.picture);
    final ui.Picture scaledPicture = recorder.endRecording();

    final image = await scaledPicture.toImage(width.toInt(), height.toInt());

    // Convert to ui.Image. toImage() takes width and height as parameters
    // you need to find the best size to suit your needs and take into account the
    // screen DPI

    ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  Widget emptyDataWidget() {
    return Container(
      alignment: Alignment.center,
      height: context.height,
      width: context.width,
      child: DefaultBlankItemMessageScreen(
        image: "something_went_wrong",
        title: deliveryBoyNotLiveLabel,
        description: "",
        buttonTitle: tryAgainLabel,
        callback: () {
          getDeliveryBoyLocation();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(
        context: context,
        title: CustomTextLabel(
          jsonKey: orderTrackingLabel,
        ),
        showBackButton: Navigator.of(context).canPop(),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            return;
          } else {
            Future.delayed(const Duration(milliseconds: 500)).then((value) {
              Navigator.pop(context, true);
            });
          }
        },
        child: Consumer<LiveOrderTrackingProvider>(
          builder: (_, liveOrderTrackingProvider, __) {
            if (liveOrderTrackingProvider.liveOrderTrackingState ==
                LiveOrderTrackingState.loading) {
              return CustomShimmer(
                height: context.height,
                width: context.width,
                margin: EdgeInsets.all(10),
              );
            }
            if (liveOrderTrackingProvider.liveOrderTrackingState ==
                LiveOrderTrackingState.empty) {
              return emptyDataWidget();
            }
            if (liveOrderTrackingProvider.liveOrderTrackingState ==
                LiveOrderTrackingState.error) {
              return emptyDataWidget();
            }
            if (liveOrderTrackingProvider.liveOrderTrackingState ==
                LiveOrderTrackingState.loaded) {
              return Stack(
                children: [
                  PositionedDirectional(
                    top: 0,
                    end: 0,
                    start: 0,
                    bottom: 0,
                    child: mapWidget(),
                  ),
                  PositionedDirectional(
                    end: 10,
                    start: 10,
                    bottom: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsetsDirectional.all(5),
                                  decoration: BoxDecoration(
                                    color:
                                        ColorsRes.appColorLightHalfTransparent,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.location_on_outlined,
                                    color: ColorsRes.appColor,
                                  ),
                                ),
                                getSizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CustomTextLabel(
                                        jsonKey: deliveryLocationLabel,
                                        style: TextStyle(
                                          color: ColorsRes.mainTextColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        softWrap: true,
                                      ),
                                      CustomTextLabel(
                                        jsonKey: widget.address,
                                        style: TextStyle(
                                          color: ColorsRes.mainTextColor,
                                        ),
                                        softWrap: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            getSizedBox(height: 10),
                            // Route Information Card
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    // Distance Info
                                    Column(
                                      children: [
                                        Icon(
                                          Icons.straighten_rounded,
                                          color: ColorsRes.appColor,
                                          size: 20,
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          routeDistance,
                                          style: TextStyle(
                                            color: ColorsRes.mainTextColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          'Distance',
                                          style: TextStyle(
                                            color: ColorsRes.subTitleMainTextColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    VerticalDivider(
                                      color: ColorsRes.appColorLightHalfTransparent,
                                      thickness: 1,
                                    ),
                                    // Time Info
                                    Column(
                                      children: [
                                        Icon(
                                          Icons.schedule_rounded,
                                          color: ColorsRes.appColor,
                                          size: 20,
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          routeDuration,
                                          style: TextStyle(
                                            color: ColorsRes.mainTextColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          'ETA',
                                          style: TextStyle(
                                            color: ColorsRes.subTitleMainTextColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            getSizedBox(height: 10),
                            GestureDetector(
                              onTap: () {
                                try {
                                  launchUrl(Uri.parse(
                                      "tel:${widget.deliveryBoyNumber.replaceAll(" ", "")}"));
                                } catch (e) {
                                  showMessage(
                                      context,
                                      getTranslatedValue(
                                          context, somethingWentWrongLabel),
                                      MessageType.warning);
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                CustomTextLabel(
                                                  jsonKey:
                                                      widget.deliveryBoyName,
                                                  style: TextStyle(
                                                    color:
                                                        ColorsRes.mainTextColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  softWrap: true,
                                                ),
                                                CustomTextLabel(
                                                  jsonKey:
                                                      widget.deliveryBoyNumber,
                                                  style: TextStyle(
                                                    color:
                                                        ColorsRes.mainTextColor,
                                                  ),
                                                  softWrap: true,
                                                ),
                                              ],
                                            ),
                                          ),
                                          getSizedBox(width: 10),
                                          Container(
                                            padding:
                                                EdgeInsetsDirectional.all(5),
                                            decoration: BoxDecoration(
                                              color: ColorsRes
                                                  .appColorLightHalfTransparent,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              Icons.call,
                                              color: ColorsRes.appColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return Container();
          },
        ),
      ),
    );
  }

  Widget mapWidget() {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: kGooglePlex,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      onMapCreated: _onMapCreated,
      zoomControlsEnabled: true,
      zoomGesturesEnabled: true,
      style: googleMapCurrentStyle,
      onCameraMove: (position) {
        mapZoom = position.zoom;
      },
      padding: EdgeInsets.only(bottom: 200),
      polylines: {
        Polyline(
          polylineId: PolylineId("route"),
          color: ColorsRes.appColor,
          points: polylineCoordinates,
          visible: true,
          zIndex: 1,
          width: 5,
          consumeTapEvents: true,
          geodesic: true,
        )
      },
      markers: _markers,
    );
  }

  Future<void> _onMapCreated(GoogleMapController controllerParam) async {
    controller = controllerParam;
  }

  @override
  Future<void> didChangeDependencies() async {
    googleMapCurrentStyle =
        Constant.session.getBoolData(SessionManager.isDarkTheme)
            ? await rootBundle.loadString(Constant.getAssetsPath(5, "nightMode"))
            : await rootBundle.loadString(Constant.getAssetsPath(5, "dayMode"));
    setState(() {});
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
