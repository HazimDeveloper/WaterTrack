import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_map_hakas_version/models/map_style.dart';
import 'package:google_map_hakas_version/pages/home_pages.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

LatLng SOURCE_LOCATION = const LatLng(5.3897, 103.1000);
LatLng DEST_LOCATION = const LatLng(5.3910, 103.0973);
const double CAMERA_ZOOM = 0.0;
const double CAMERA_BEARING = 0.0;
const double CAMERA_TILT = 0;

class MapPages extends StatefulWidget {
  const MapPages({super.key, this.latitude, this.longitude, this.placeName});

  final double? latitude;
  final double? longitude;
  final String? placeName;
  @override
  State<MapPages> createState() => _MapPagesState();
}

class _MapPagesState extends State<MapPages> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  BitmapDescriptor? sourceIcon;
  BitmapDescriptor? destIcon;
  final Set<Marker> _marker = <Marker>{};
  LatLng currentLocation =
      LatLng(SOURCE_LOCATION.latitude, SOURCE_LOCATION.longitude);
  LatLng destinationLocation =
      LatLng(DEST_LOCATION.latitude, DEST_LOCATION.longitude);
  final Set<Polyline> _polyline = <Polyline>{};
  List<LatLng> coordinatesPolyLine = [];
  late PolylinePoints polylinePoints;
  late double distance = 0.0;
  bool isLoading = true; // Flag to indicate loading state
  bool useIframe = false;
  late final WebViewController controllerIframe;
  late final WebViewController _webViewController;
  bool _isWebViewReady = false;
  List<Map<String, dynamic>> waterSupplyData = [];

  @override
  void initState() {
    super.initState();
    _initWebViewController();
    polylinePoints = PolylinePoints();
    setMarkerIcon();
    loadWaterSupplyData();

    if (widget.latitude != null && widget.longitude != null) {
      destinationLocation = LatLng(widget.latitude!, widget.longitude!);
    }

    _checkPermissionAndInitialize();
  }

  Future<void> loadWaterSupplyData() async {
    String jsonString =
        await rootBundle.loadString('assets/data/water_supply.json');
    print(jsonString);
    List<dynamic> jsonData = json.decode(jsonString);
    waterSupplyData = jsonData.cast<Map<String, dynamic>>();
  }

  Future<void> _checkPermissionAndInitialize() async {
    final hasPermission = await _handleLocationPermission();
    if (hasPermission) {
      setInitialLocation();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> setMarkerIcon() async {
    destIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(devicePixelRatio: 2.0),
        'assets/images/destinationIcon-2.png',
        width: 50,
        height: 50);
    sourceIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(devicePixelRatio: 2), 'assets/images/sourceIcon.png',
        width: 50, height: 50);
  }

  double calculateDistance(LatLng start, LatLng destination) {
    double distanceInMeter = Geolocator.distanceBetween(start.latitude,
        start.longitude, destination.latitude, destination.longitude);
    double distanceInKM = distanceInMeter / 1000;
    return distanceInKM;
  }

  // Get the initial location
  void setInitialLocation() async {
    try {
      final LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );

      Position position = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings);

      setState(() {
        SOURCE_LOCATION = LatLng(position.latitude, position.longitude);
        distance = calculateDistance(SOURCE_LOCATION, destinationLocation);
      });

      await initialisePolyline();
      await showMarkerOnMap();
    } catch (e) {
      print("Error getting location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Unable to get current location. Using default location.")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _initWebViewController() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isWebViewReady = true;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(getGoogleMapsIframeUrl()));
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    CameraPosition initialCameraPosition = CameraPosition(
        target: SOURCE_LOCATION,
        zoom: CAMERA_ZOOM,
        tilt: CAMERA_TILT,
        bearing: CAMERA_BEARING);

    return Scaffold(
      body: Stack(
        children: [
          // If loading, show a CircularProgressIndicator in the center of the screen
          if (isLoading && !useIframe)
            const Center(child: CircularProgressIndicator()),

          if (useIframe && _isWebViewReady)
            WebViewWidget(controller: _webViewController),

          if (useIframe && !_isWebViewReady)
            const Center(child: CircularProgressIndicator()),

          // Once loading is finished, display the GoogleMap widget
          if (!isLoading && !useIframe)
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: initialCameraPosition,
                myLocationButtonEnabled: true,
                compassEnabled: false,
                tiltGesturesEnabled: false,
                polylines: _polyline,
                markers: _marker,
                mapType: MapType.normal,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                  showMarkerOnMap();
                  _fitAllMarkers(controller);
                },
              ),
            ),
          Positioned(
            top: 10,
            right: 0,
            left: 0,
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: Offset.zero,
                        blurRadius: 10)
                  ]),
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      image: const DecorationImage(
                          image: AssetImage('assets/images/me.png'),
                          fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Muhd Hazim",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "My Location",
                          style: TextStyle(color: Colors.blue),
                        )
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.location_pin,
                    size: 40,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
          if (!isLoading && _marker.isEmpty)
            const Center(
              child: Text(
                "Location permission not granted. Unable to show map.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          if (!useIframe)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              bottom: 80,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset.zero)
                    ]),
                margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 30),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            image: const DecorationImage(
                                image:
                                    AssetImage('assets/images/less-water.png'),
                                fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.placeName.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "${distance.toStringAsFixed(2)}KM from Current Location",
                              style: const TextStyle(fontSize: 12),
                            )
                          ],
                        )),
                        const Icon(
                          Icons.location_pin,
                          size: 40,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              children: [
                Expanded(
                    child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                      ),
                      decoration: BoxDecoration(
                          color: Colors.lightBlueAccent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: Offset.zero)
                          ]),
                      child: IconButton(
                          onPressed: () {
                            final Uri url =
                                Uri.parse(getGoogleMapsIframeUrl());
                            launchUrl(url);
                          },
                          icon: const Icon(
                            Icons.map,
                            color: Colors.white,
                          )),
                    ),
                  ],
                )),
              ],
            ),
          ),
          Positioned(
              right: 30,
              top: 150,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100)),
                child: IconButton(
                  icon: const Icon(Icons.list),
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigator.push(context,
                    //     MaterialPageRoute(builder: (context) => HomePages()));
                  },
                ),
              )),
        ],
      ),
    );
  }

  // Show the markers on the map
  Future<void> showMarkerOnMap() async {
    if (sourceIcon != null && destIcon != null) {
      _marker.add(Marker(
          markerId: const MarkerId('sourcePin'),
          position: SOURCE_LOCATION,
          icon: sourceIcon!));

      _marker.add(Marker(
          markerId: const MarkerId("destPin"),
          position: destinationLocation,
          icon: destIcon!));

      // Add markers for water supply locations
      for (var supply in waterSupplyData) {
        _marker.add(Marker(
          markerId: MarkerId(supply['name']),
          position: LatLng(supply['latitude'], supply['longitude']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: supply['name'],
            snippet: 'Phone: ${supply['phone']}',
          ),
        ));
      }
      
      setState(() {});
    }
  }

  String getGoogleMapsIframeUrl() {
    final startLat = SOURCE_LOCATION.latitude;
    final startLng = SOURCE_LOCATION.longitude;
    final destLat = destinationLocation.latitude;
    final destLng = destinationLocation.longitude;

    return 'https://www.google.com/maps/dir/?api=1&origin=$startLat,$startLng&destination=$destLat,$destLng&travelmode=driving';
  }

  void _fitAllMarkers(GoogleMapController controller) {
    if (_marker.isEmpty) return;

    double minLat = _marker.first.position.latitude;
    double maxLat = _marker.first.position.latitude;
    double minLng = _marker.first.position.longitude;
    double maxLng = _marker.first.position.longitude;

    for (Marker marker in _marker) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng) {
        minLng = marker.position.longitude;
      }
      if (marker.position.longitude > maxLng) {
        maxLng = marker.position.longitude;
      }
    }

    controller.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      100, // padding
    ));
  }

  // Initialise the polyline after getting the current location
  Future<void> initialisePolyline() async {
    print(currentLocation);
    print(destinationLocation);
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: "AIzaSyAwwgmqAxzQmdmjNQ-vklZnvVdZjkWLcTY",
      request: PolylineRequest(
        origin:
            PointLatLng(SOURCE_LOCATION.latitude, SOURCE_LOCATION.longitude),
        destination: PointLatLng(
            destinationLocation.latitude, destinationLocation.longitude),
        mode: TravelMode.walking,
      ),
    );

    if (result.status == "OK") {
      for (var point in result.points) {
        coordinatesPolyLine.add(LatLng(point.latitude, point.longitude));
      }

      setState(() {
        _polyline.add(Polyline(
          polylineId: const PolylineId("polyline"),
          color: Colors.lightBlueAccent,
          points: coordinatesPolyLine,
          width: 5,
          patterns: [PatternItem.dash(30), PatternItem.gap(10)],
        ));
      });
    } else {
      // Handle ZERO_RESULTS or any other error case
      print("No route found between the specified locations.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("No route found between the specified locations.")),
      );
    }
  }
}
