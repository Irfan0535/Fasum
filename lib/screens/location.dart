import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationWidget extends StatefulWidget {
  final Function(Position) onLocationChanged;

  const LocationWidget({super.key, required this.onLocationChanged});

  @override
  State<LocationWidget> createState() => _LocationWidgetState();
}

class _LocationWidgetState extends State<LocationWidget> {
  String _locationMessage = '';
  Position? _currentPosition;

  void _getCurrentLocation() async {
    final status = await Permission.location.status;
    if (!status.isGranted) {
      final result = await Permission.location.request();
      if (result != PermissionStatus.granted) {
        return;
      }
    }
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
      _locationMessage =
          'Latitude ${position.latitude}, Longitude: ${position.longitude}';
      widget.onLocationChanged(position);
    });
  }

  Future<void> _showOnMap() async {
    if (_currentPosition != null) {
      Uri googleMapsUrl = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude},'
          '${_currentPosition!.longitude}');
      try {
        await launchUrl(googleMapsUrl);
      } catch (e) {
        throw 'Could not launch $googleMapsUrl';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(_locationMessage),
        ElevatedButton(
          onPressed: _getCurrentLocation,
          child: const Text("Get Location"),
        ),
        const SizedBox(
          height: 10,
        ),
        if (_currentPosition != null)
          ElevatedButton(
            onPressed: _showOnMap,
            child: const Text('Show on Map'),
          ),
      ],
    );
  }
}
