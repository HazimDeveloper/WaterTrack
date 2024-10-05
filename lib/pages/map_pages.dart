import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_map_hakas_version/models/map_style.dart';
import 'package:google_map_hakas_version/pages/home_pages.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

LatLng SOURCE_LOCATION = LatLng(5.3897, 103.1000);
LatLng DEST_LOCATION = LatLng(5.3910, 103.0973);
const double CAMERA_ZOOM = 16;
const double CAMERA_BEARING = 30;
const double CAMERA_TILT = 50;


class MapPages extends StatefulWidget {
  const MapPages({Key? key, this.latitude,this.longitude,this.placeName}) : super(key: key) ;

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
  Set<Marker> _marker = Set<Marker>();
  LatLng currentLocation =
      LatLng(SOURCE_LOCATION.latitude, SOURCE_LOCATION.longitude);
  LatLng destinationLocation =
      LatLng(DEST_LOCATION.latitude, DEST_LOCATION.longitude);
  Set<Polyline> _polyline = Set<Polyline>();
  List<LatLng> coordinatesPolyLine = [];
  late PolylinePoints polylinePoints;
  late double distance = 0.0;
  bool isLoading = true; // Flag to indicate loading state
  bool useIframe = false;
  late final WebViewController controllerIframe;
  late final WebViewController _webViewController;
  bool _isWebViewReady = false;
  @override
  void initState() {
    super.initState();
    _initWebViewController();
    polylinePoints = PolylinePoints();
    setMarkerIcon();
    
    if(widget.latitude != null && widget.longitude != null){
      destinationLocation = LatLng(widget.latitude!, widget.longitude!);
    }
    
    setInitialLocation(); // Get current location
    
  }

  Future<void> setMarkerIcon() async {
    destIcon = await BitmapDescriptor.asset(
        ImageConfiguration(devicePixelRatio: 2.0),
        'assets/images/destinationIcon-2.png',
        width: 50,
        height: 50);
    sourceIcon = await BitmapDescriptor.asset(
        ImageConfiguration(devicePixelRatio: 2), 'assets/images/sourceIcon.png',
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
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );

    // Get current position
    Position position =
        await Geolocator.getCurrentPosition(locationSettings: locationSettings);

    // Update current location
    setState(() {
      SOURCE_LOCATION = LatLng(position.latitude, position.longitude);
      distance = calculateDistance(SOURCE_LOCATION, destinationLocation);
    });

    // Once location is retrieved, set the polyline
    await initialisePolyline();
    await showMarkerOnMap();
    // After polyline is ready, stop loading and show the map
    setState(() {
      isLoading = false; // Stop loading once everything is ready
    });
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

  @override
  Widget build(BuildContext context) {
    CameraPosition _initialCameraPosition = CameraPosition(
        target: SOURCE_LOCATION,
        zoom: CAMERA_ZOOM,
        tilt: CAMERA_TILT,
        bearing: CAMERA_BEARING);

    return Scaffold(
      body: Stack(
        children: [
          // If loading, show a CircularProgressIndicator in the center of the screen
          if (isLoading && !useIframe)
            Center(child: CircularProgressIndicator()),

          if (useIframe && _isWebViewReady)
            WebViewWidget(controller: _webViewController),

          if (useIframe && !_isWebViewReady)
            Center(child: CircularProgressIndicator()),

          // Once loading is finished, display the GoogleMap widget
          if (!isLoading && !useIframe)
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: _initialCameraPosition,
                myLocationButtonEnabled: true,
                compassEnabled: false,
                tiltGesturesEnabled: false,
                polylines: _polyline,
                markers: _marker,
                mapType: MapType.normal,
                style: MapStyle().aubergine,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                  showMarkerOnMap();
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
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      image: DecorationImage(
                          image: AssetImage('assets/images/me.png'),
                          fit: BoxFit.cover),
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Expanded(
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
                  Icon(
                    Icons.location_pin,
                    size: 40,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),

          if (!useIframe)
            AnimatedPositioned(
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              bottom: 10,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset.zero)
                    ]),
                padding: EdgeInsets.all(30),
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            image: DecorationImage(
                                image: AssetImage('assets/images/less-water.png'),
                                fit: BoxFit.cover),
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.placeName.toString(),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                                "${distance.toStringAsFixed(2)}KM from Current Location")
                          ],
                        )),
                        Icon(
                          Icons.location_pin,
                          size: 40,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          
                          onTap: () {
                           
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(50),
                              image: DecorationImage(
                                  image: AssetImage('assets/images/map-icon.png'),
                                  fit: BoxFit.cover),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "LIVE DIRECTION",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text("Use Google Maps to Follow The Directions",style: TextStyle(fontSize: 12),)
                          ],
                        )),
                        IconButton(onPressed: (){
                           final Uri _url =
                                Uri.parse(getGoogleMapsIframeUrl());
                            launchUrl(_url);
                        }, icon: Icon(Icons.map,color: Colors.red,))
                      ],
                    ),
                  ],
                ),
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
                  icon: Icon(Icons.list),
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
          markerId: MarkerId('sourcePin'),
          position: SOURCE_LOCATION,
          icon: sourceIcon!));

      _marker.add(Marker(
          markerId: MarkerId("destPin"),
          position: destinationLocation,
          icon: destIcon!));

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
        mode: TravelMode.driving,
      ),
    );

    if (result.status == "OK") {
      result.points.forEach((PointLatLng point) {
        coordinatesPolyLine.add(LatLng(point.latitude, point.longitude));
      });

      setState(() {
        _polyline.add(Polyline(
          polylineId: PolylineId("polyline"),
          color: Colors.purple,
          points: coordinatesPolyLine,
        ));
      });
    } else {
      // Handle ZERO_RESULTS or any other error case
      print("No route found between the specified locations.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("No route found between the specified locations.")),
      );
    }
  }
}
