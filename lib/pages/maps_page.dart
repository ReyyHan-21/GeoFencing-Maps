// ignore_for_file: deprecated_member_use, avoid_init_to_null, unnecessary_new, no_leading_underscores_for_local_identifiers, prefer_final_fields
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/widgets.dart';
// import 'package:flutter/widgets.dart';

// import 'dart:collection';
// import 'dart:ffi';
import 'dart:async';
import 'dart:convert';
// import 'dart:ffi';

import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
  BitmapDescriptor? _carIcon, _PedestrianIcon, _MotorIcon, _BusIcon;

  //|||||||||||| Get API ||||||||||||
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _apiController =
      TextEditingController(); //Kontroller untuk api key
  String _apiUrl = "192.168.1.160:1880/apps"; //Link default API
  //|||||||||||| End Get API ||||||||

  //
  late GoogleMapController _mapController;
  late StreamController<LatLng> _locationStreamController;
  List<Marker> markernya = [];
  List<Circle> circlenya = [];
  List<Circle> circlearin = [];
  late LatLng _lokasiSaya;
  final _customeInfoWindowController = CustomInfoWindowController();
  var data = [];

  // late Stream<LocationData> _locationStream;

  // Marker? _lokasiSayaMarker;

// |||||||||||||||||VOID STATE Start||||||||||||||||||||||||
  @override
  //Insert your current location
  void initState() {
    super.initState();
    // _locationStream = _location.onLocationChanged;
    _locationStreamController = StreamController<LatLng>();
    _requestLocationPermission();
    _setCustomMarkerIcon();
    _fetchLocationPeriodically();
    _getLokasiSaya();
  }

// ||||||||||||||||||API URL||||||||||||||||||||||
  void _updateApiUrl(String newUrl) {
    setState(() {
      _apiUrl = newUrl;
    });
    // print('API URL updated to: $_apiUrl');
  }
// ||||||||||||||||||API URL END|||||||||||||||||||||

  @override
  void dispose() {
    _locationStreamController.close();
    markernya.clear();
    circlenya.clear();
    circlearin.clear();
    data.clear();
    _apiController
        .dispose(); //Pastikan untuk menghapus controller saat widget dibuang
    super.dispose();
  }

  // void dispose()

  Future<void> _setCustomMarkerIcon() async {
    _carIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      'assets/image/car.png',
    );
    _PedestrianIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      'assets/image/pedestrian.png',
    );
    _MotorIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      'assets/image/motor.png',
    );
    _BusIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      'assets/image/bus.png',
    );
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

  // void _onMapCreated(GoogleMapController controller) {
  //   _mapController = controller;
  // }

  Future<void> _fetchLocationPeriodically() async {
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      final queryParameters = {
        'id': '1',
        'lat': _lokasiSaya.latitude.toString(),
        'lng': _lokasiSaya.longitude.toString(),
        'role': 'P'
      };
      final uri = Uri.https(
          _apiUrl.replaceAll("http://", "").replaceAll("/", ""),
          '/apps',
          queryParameters);
      // final uri = Uri.http('192.168.1.160:1880', '/apps', queryParameters);
      final headers = {'Content-Type': 'application/json'};
      final response = await http.get(uri, headers: headers);

      // final response = await http.get(Uri.parse('http:/192.168.1.160:1880/location'));

      if (response.statusCode == 200) {
        final datac = jsonDecode(response.body);
        data = datac;
        // print(data);
        // List<Widget> locationList = [];
        // print(data);
        // markernya.add(_currentPosition);
        // markernya.add(Marker(markerId: MarkerId(_currentPosition)));
        markernya.clear();
        datac.forEach((element) {
          // print("Print ini COk :");
          // print(element['latitude']);
          // print(data.indexOf(element['latitude']));
          // String rolecoy = "${element['role']}";
          String role = element['role'].toString();
          // String circle = element['role'].toString();
          // print(element['role']..toString());

          LatLng newLocation =
              LatLng(element['latitude'], element['longitude']);
          markernya.add(Marker(
            markerId: MarkerId(element['id'].toString()),
            position: newLocation,
            icon: role == "P"
                ? _PedestrianIcon!
                : role == "C"
                    ? _carIcon!
                    : role == "M"
                        ? _MotorIcon!
                        : _BusIcon!,
            onTap: () {
              _customeInfoWindowController.addInfoWindow!(
                Container(
                  padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                  alignment: Alignment.center,
                  height: 50,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Role : ${element['role']}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "Latitude: ${element['latitude']}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        " Longitude: ${element['longitude']}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "Speed: ${element['speed']} KM/H",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "HDOP : ${element['hdop']}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "Satelit : ${element['sats']}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    ],
                  ),
                ),
                newLocation,
              );
            },
          ));
          circlenya.addAll([
            Circle(
                circleId: const CircleId("lokasiSaya"),
                center: _lokasiSaya,
                radius: 65,
                strokeWidth: 0,
                fillColor: Colors.red.withOpacity(0.25)),
            Circle(
                circleId: const CircleId("lokasiSaya"),
                center: _lokasiSaya,
                radius: 45,
                strokeWidth: 0,
                fillColor: Colors.yellow.withOpacity(0.25)),
            Circle(
                circleId: const CircleId("lokasiSaya"),
                center: _lokasiSaya,
                radius: 25,
                strokeWidth: 0,
                fillColor: Colors.green.withOpacity(0.25)),
          ]);
          _locationStreamController.add(newLocation);
        });
        // LatLng newLocation = LatLng(data['latitude'], data['longitude']);
        // print(newLocation);
        // return newLocation;
      } else {
        throw Exception('Failed to load locations');
      }
    });
  }

  Stream<LatLng> _getLokasiSaya() async* {
    // ignore: non_constant_identifier_names
    final Position = await Geolocator.getCurrentPosition();
    setState(() {
      _lokasiSaya = LatLng(Position.latitude, Position.longitude);
      // print(_lokasiSaya);
      circlearin.clear();
      circlearin.addAll([
        // Circle(
        //     circleId: const CircleId("lokasiSaya"),
        //     center: _lokasiSaya,
        //     radius: 200,
        //     strokeWidth: 0,
        //     fillColor: Color.fromARGB(255, 255, 4, 4).withOpacity(0.2)),
        Circle(
            circleId: const CircleId("lokasiSaya"),
            center: _lokasiSaya,
            radius: 100,
            strokeWidth: 0,
            fillColor: Colors.blueAccent.withOpacity(0.2)),
      ]);
    });
  }

// ||||||||||||||||||||||Dialog Start||||||||||||||||||||||||||||||||
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
                const Padding(
                  padding: EdgeInsets.only(top: 15, bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Role',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      // Dropdown Menu //
                      DropdownMenu(dropdownMenuEntries: [
                        DropdownMenuEntry(
                          value: 'P',
                          label: 'Pedestrian',
                        ),
                        DropdownMenuEntry(
                          value: 'C',
                          label: 'Car',
                        ),
                        DropdownMenuEntry(
                          value: 'B',
                          label: 'Bus',
                        ),
                      ])
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Used Api Link : $_apiUrl',
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 15,
                    ),
                  ),
                ),
                TextFormField(
                  controller:
                      _apiController, // Controller untuk menampung input
                  decoration: InputDecoration(
                      hintText: 'Api Link Here',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                      )),
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Approve'),
              onPressed: () {
                setState(() {
                  _updateApiUrl(_apiController.text); // Simpan url baru
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
// ||||||||||||||||||||||Dialog End||||||||||||||||||||||||||||||||||

// ||||||||||||||||||||||||||VOID State End||||||||||||||||||||||||||||||||||||||

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
        body: StreamBuilder(
            stream: _getLokasiSaya(),
            builder: (context, snapshot) {
              return StreamBuilder<LatLng>(
                  // stream: _locationStream,
                  stream: _locationStreamController.stream,
                  builder: (context, snapshot) {
                    // print(snapshot.hasData);
                    // print(snapshot.data);
                    if (snapshot.hasData && snapshot.data != null) {
                      // print(newLocation);
                      return Stack(
                        children: [
                          GoogleMap(
                            mapType: MapType.normal,
                            initialCameraPosition:
                                CameraPosition(target: _lokasiSaya, zoom: 18.5),
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            onMapCreated: (controller) {
                              _mapController = controller;
                              _customeInfoWindowController.googleMapController =
                                  controller;
                            },
                            onTap: (location) {
                              _customeInfoWindowController.hideInfoWindow!();
                            },
                            onCameraMove: (position) {
                              _customeInfoWindowController.onCameraMove!();
                            },
                            markers: Set<Marker>.of(markernya),
                            circles: Set<Circle>.of(circlearin),
                          ),
                          CustomInfoWindow(
                            controller: _customeInfoWindowController,
                            height: 125,
                            width: 200,
                            offset: 40,
                          ),
                        ],
                      );
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  });
            }));
  }
}
