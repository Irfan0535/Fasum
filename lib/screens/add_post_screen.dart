import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasum/screens/location.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class AddPostScreen extends StatefulWidget {
  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  File? _image;
  final picker = ImagePicker();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _placeNameController = TextEditingController();
  Position? _currentPosition;

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  void _updateLocation(Position position) {
    setState(() {
      _currentPosition = position;
    });
  }

  Future<void> _uploadPost() async {
    if (_image == null ||
        _descriptionController.text.isEmpty ||
        _placeNameController.text.isEmpty ||
        _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Image, description, place name, and location are required')),
      );
      return;
    }

    String imageUrl;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('post_images')
          .child('${DateTime.now()}.jpg');
      await ref.putFile(_image!);
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
      'placeName': _placeNameController.text,
      'location':
          GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
      'timestamp': Timestamp.now(),
      'username': username,
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
                    : Image.file(_image!),
              ),
              TextField(
                controller: _placeNameController,
                decoration: InputDecoration(labelText: 'Place Name'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 20),
              LocationWidget(onLocationChanged: _updateLocation),
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
