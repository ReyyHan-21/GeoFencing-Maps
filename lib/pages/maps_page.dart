// ignore_for_file: deprecated_member_use, avoid_init_to_null, unnecessary_new, no_leading_underscores_for_local_identifiers, prefer_final_fields
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/widgets.dart';
// import 'package:flutter/widgets.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  Location _location = Location();
  BitmapDescriptor? _customIcon;

  //
  late GoogleMapController _mapController;
  late Marker _currentMarker;
  late StreamController<LatLng> _locationStreamController;

  // late Stream<LocationData> _locationStream;
  LatLng? _currentPosition;

// VOID
  @override
  //Insert your current location
  void initState() {
    super.initState();
    // _locationStream = _location.onLocationChanged;
    _locationStreamController = StreamController<LatLng>();
    _requestLocationPermission();
    _setCustomMarkerIcon();
    _fetchLocationPeriodically();
  }

  @override
  void dispose() {
    _locationStreamController.close();
    super.dispose();
  }

  // void dispose()

  Future<void> _setCustomMarkerIcon() async {
    _customIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      'assets/image/sedan_top.png',
    );
  }

  // void _onMapCreated(GoogleMapController controller) {
  //   _mapController = controller;
  // }

  Future<void> _fetchLocationPeriodically() async {
    Timer.periodic(const Duration(seconds: 3), (timer) async {
      final queryParameters = {'id': '1240'};
      final uri = Uri.http('192.168.1.160:1880', '/apps', queryParameters);
      final headers = {'Content-Type': 'application/json'};
      final response = await http.get(uri, headers: headers);

      // final response = await http.get(Uri.parse('http:/192.168.1.160:1880/location'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // print(data);
        LatLng newLocation = LatLng(data[0]["latitude"], data[0]["longitude"]);
        // LatLng newLocation = LatLng(data['latitude'], data['longitude']);
        _locationStreamController.add(newLocation);
        // print(newLocation);
        // return newLocation;
      } else {
        throw Exception('Failed to load locations');
      }
    });
  }

// VOID END

  @override
  Widget build(BuildContext context) {
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
              onPressed: () => _showMyDialog(),
              icon: const Icon(Icons.settings),
              color: const Color.fromARGB(255, 255, 255, 255),
            )
          ],
        ),
        body: StreamBuilder<LatLng>(
            // stream: _locationStream,
            stream: _locationStreamController.stream,
            builder: (context, snapshot) {
              // print(snapshot.hasData);
              if (snapshot.hasData) {
                LatLng newPosition = snapshot.data!;
                _currentMarker = Marker(
                    markerId: const MarkerId('currentLocation'),
                    position: newPosition,
                    icon: _customIcon!,
                    infoWindow: InfoWindow(
                      title: 'Current Location',
                      snippet:
                          'Lat: ${newPosition.latitude}, Lng: ${newPosition.longitude}',
                    ));
                return GoogleMap(
                  // myLocationEnabled: true,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition:
                      CameraPosition(target: newPosition, zoom: 17.5),
                  markers: {_currentMarker},
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            }));
  }

  Future<void> _requestLocationPermission() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Settings',
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Row(
                  children: [
                    Text(
                      'Role',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    // Dropdown Menu //
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Api Link',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    '//Api Link Here',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Approve'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
