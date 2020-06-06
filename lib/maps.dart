import 'dart:collection';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

class Maps extends StatefulWidget {
  final int storeID;
  final LatLng location;
  
  Maps({this.storeID, this.location});

  @override
  _MapsState createState() => _MapsState();
}

class _MapsState extends State<Maps> {
  GoogleMapController mapController;
  String _mapStyle;
  Set<Marker> _markers = HashSet<Marker>();
  LatLng _center;
  BitmapDescriptor markerIcon;
  final databaseReference = Firestore.instance;

  @override
  void initState() {
    super.initState();
    _center = const LatLng(43.588083, -79.642514);
    setMarkerIcon();
    rootBundle.loadString('assets/mapstyle.txt').then((string) {
      _mapStyle = string;
    });
    databaseReference
        .collection("HtoO")
        .getDocuments()
        .then((QuerySnapshot snapshot) {
      snapshot.documents.forEach(
        (f) {
        _markers.add(
          Marker(
            markerId: MarkerId("${f.data["MarkerID"]}"),
            position: LatLng(GeoPoint(f.data["Location"].latitude,f.data["Location"].longitude).latitude,GeoPoint(f.data["Location"].latitude,f.data["Location"].longitude).longitude),
            infoWindow: InfoWindow(
              title: "${f.data["Name"]}",
              snippet: "Gallons of Water Available: ${f.data["Water Bottle"]}",
              onTap: () async{
                print("hi");
                await openMap(f.data["Location"].latitude,f.data["Location"].longitude);
              }
            ),
            onTap: (){
              setState(() {
                CameraPosition(target: LatLng(GeoPoint(f.data["Location"].latitude,f.data["Location"].longitude).latitude,GeoPoint(f.data["Location"].latitude,f.data["Location"].longitude).longitude), zoom: 20);
              });
            },
            icon: markerIcon
          )
          );
        }
      );
      setState(() {
        print("RESTART");
      });
    });
  }

  static Future<void> openMap(double latitude, double longitude) async {
    String googleUrl = 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
    if (await canLaunch(googleUrl)) {
      await launch(googleUrl);
    } else {
      throw 'Could not open the map.';
    }
  }

  void setMarkerIcon() async{
    markerIcon = await BitmapDescriptor.fromAssetImage(ImageConfiguration(), "assets/bottle.png");
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapController.setMapStyle(_mapStyle);
    setState(() {
      
    });
  }

  @override
  Widget build(BuildContext context) {
    if(widget.storeID!=null && widget.location!=null){
      _center = widget.location;
    }

    print("THIS IS MARKERS");
    print(_markers);

    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: <Widget>[
            _markers.isNotEmpty?GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 12.0,
              ),
              myLocationEnabled: true,
              markers: _markers,
            ):Text('LOADING...'),
          ],
        ),
      ),
    );
  }
}