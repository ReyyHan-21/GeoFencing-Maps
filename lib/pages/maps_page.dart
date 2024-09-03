// ignore_for_file: deprecated_member_use, avoid_init_to_null, unnecessary_new, no_leading_underscores_for_local_identifiers, prefer_final_fields

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});
  
  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  Location _locationController = new Location();

  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  static const _pGooglePlex = LatLng(-7.971053, 112.662327); //Start
  static const _pGooglePlex2 = LatLng(-7.972457, 112.6631204); //Destination
  LatLng? currentP = null;

  BitmapDescriptor currentIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarker;

  void setCustomeMarkerIcon() {
    // BitmapDescriptor.fromAssetImage(ImageConfiguration.empty, 'assets/cars.svg')
    //     .then((icon) {
    //   currentIcon = icon;
    // });
    // BitmapDescriptor.fromAssetImage(
    //         const ImageConfiguration(), 'assets/source.svg')
    //     .then((icon) {
    //   sourceIcon = icon;
    // });
    // BitmapDescriptor.fromAssetImage(
    //         const ImageConfiguration(), 'assets/destination.svg')
    //     .then((icon) {
    //   destinationIcon = icon;
    // });
  }

  @override
  //Insert your current location
  void initState() {
    super.initState();
    getLocationUpdates();
    setCustomeMarkerIcon();
  }

  @override
  Widget build(BuildContext context) {
    StreamBuilder<LocationData> streamBuilder = StreamBuilder(
      stream: _locationController.onLocationChanged,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          currentP = 
              LatLng(snapshot.data!.latitude!, snapshot.data!.longitude!);
          return build(context);
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        centerTitle: true,
        title: const Text(
          "GeoFencing Maps",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings),
            color: const Color.fromARGB(255, 255, 255, 255),
          )
        ],
      ),
      body: currentP == null
          ? streamBuilder
          : GoogleMap(
              onMapCreated: (GoogleMapController controller) =>
                  _mapController.complete(controller),
              initialCameraPosition:
                  const CameraPosition(target: _pGooglePlex, zoom: 17.5),
              markers: {
                Marker(
                  markerId: const MarkerId("_currentLocation"),
                  position: currentP!,
                  icon: currentIcon,
                ),
                Marker(
                  markerId: const MarkerId("_sourceLocation"),
                  position: _pGooglePlex,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
                  infoWindow: const InfoWindow(
                    title: "Pt.Otomasi Cerdas Nusantara",
                    snippet: "Radius 15 Meter",
                  ),
                ),
                Marker(
                  markerId: const MarkerId("_destinationLocation"),
                  position: _pGooglePlex2,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueViolet),
                  infoWindow: const InfoWindow(
                    title: "Indomaret Danau Kerinci",
                    snippet: "Radius 35 Meter",
                  ),
                )
              },
              circles: {
                Circle(
                  circleId: const CircleId("_sourceLocation"),
                  center: _pGooglePlex,
                  radius: 15,
                  strokeWidth: 0,
                  fillColor: Colors.grey.withOpacity(0.5),
                ),
                Circle(
                  circleId: const CircleId("_destinationLocation"),
                  center: _pGooglePlex2,
                  radius: 35,
                  strokeWidth: 0,
                  fillColor:
                      const Color.fromARGB(255, 0, 0, 0).withOpacity(0.5),
                ),
              },
            ),
    );
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition _newCameraPosition = CameraPosition(
      target: pos,
      zoom: 17.5,
    );
    controller
        .animateCamera(CameraUpdate.newCameraPosition(_newCameraPosition));
  }

  Future<void> getLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          currentP =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
          _cameraToPosition(currentP!);
        });
      }
    });
  }
}
