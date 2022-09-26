import 'package:location/location.dart';

class LocationModel {
  double lat;
  double long;
  double accuracy;
  LocationModel({
    required this.lat,
    required this.long,
    required this.accuracy,
  });
}

Future<LocationModel?> getCurrentLocation() async {
  try {
    Location location = Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;
    try {
      _serviceEnabled = await location.serviceEnabled();
    } catch (e) {
      _serviceEnabled = false;
    }
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return null;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    _locationData = await location.getLocation();
    
    return LocationModel(
        lat: _locationData.latitude ?? 0,
        long: _locationData.longitude ?? 0,
        accuracy: _locationData.accuracy ?? 0);
  } catch (e) {
    return null;
  }
}
