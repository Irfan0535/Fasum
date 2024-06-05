import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fasum/screens/location.dart'; // Import LocationWidget

class AddPostScreen extends StatefulWidget {
  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  XFile? _image;
  Uint8List? _webImage;
  final picker = ImagePicker();
  final TextEditingController _descriptionController = TextEditingController();
  Position? _currentPosition;

  bool _isLocationEnabled =
      false; // Add a flag to track if location is obtained

  // Function to update current position
  void _updateLocation(Position? position) {
    setState(() {
      _currentPosition = position;
      _isLocationEnabled = true; // Update flag when location is obtained
    });
  }

  // Function to validate if all required fields are filled
  bool _validateFields() {
    return _image != null &&
        _descriptionController.text.isNotEmpty &&
        _isLocationEnabled; // Ensure location is enabled
  }

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = pickedFile;
        if (kIsWeb) {
          pickedFile.readAsBytes().then((value) {
            setState(() {
              _webImage = value;
            });
          });
        }
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _uploadPost() async {
    if (!_validateFields()) {
      // Check if all required fields are filled
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    String imageUrl;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('post_images')
          .child('${DateTime.now()}.jpg');

      if (kIsWeb) {
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        await ref.putData(_webImage!, metadata);
      } else {
        final file = File(_image!.path);
        await ref.putFile(file);
      }

      imageUrl = await ref.getDownloadURL();
    } catch (e) {
      print(e);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final username = user?.email ?? 'Anonymous';

    FirebaseFirestore.instance.collection('posts').add({
      'imageUrl': imageUrl,
      'description': _descriptionController.text,
      'timestamp': Timestamp.now(),
      'username': username,
      if (_currentPosition != null)
        'location':
            GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Post'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: getImage,
                child: _image == null
                    ? Icon(Icons.camera_alt, size: 100)
                    : kIsWeb
                        ? Image.memory(_webImage!)
                        : Image.file(File(_image!.path)),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 20),
              LocationWidget(
                  onLocationChanged: _updateLocation), // Add LocationWidget
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadPost,
                child: Text('Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
