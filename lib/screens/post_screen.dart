import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasum/screens/home_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PostScreen extends StatefulWidget {
  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<PostScreen> {
  final _TextController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Post'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      floatingActionButton: IconButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()));
          },
          icon: Icon(Icons.arrow_back_ios_new_outlined)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                await _showImageSourceDialog();
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                    color: Colors.lightBlueAccent,
                    borderRadius: BorderRadius.circular(90)),
                child: _image != null
                    ? Image.file(File(_image!.path))
                    : Icon(Icons.camera_alt),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _TextController,
              decoration: InputDecoration(
                hintText: 'Input Text',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  textStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  )),
              onPressed: () async {
                if (_image == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select an image')),
                  );
                  return;
                }

                Reference referenceRoot = FirebaseStorage.instance.ref();
                Reference referenceDirImages = referenceRoot.child("images");
                Reference referenceImagesToUpload =
                    referenceDirImages.child(_image!.path.split("/").last);

                try {
                  final uploadTask =
                      await referenceImagesToUpload.putFile(File(_image!.path));
                  final downloadUrl = await uploadTask.ref.getDownloadURL();

                  // Add Firebase Cloud Firestore functionality here
                  final CollectionReference posts =
                      FirebaseFirestore.instance.collection('test');
                  await posts.add({
                    'text': _TextController.text,
                    'image_url': downloadUrl,
                    'timestamp': Timestamp.now(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Image uploaded successfully')),
                  );

                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => const HomeScreen()));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error uploading image: $e')),
                  );
                }
              },
              child: Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pilih Sumber Gambar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Open Camera'),
              onTap: () async {
                Navigator.of(context).pop();
                final pickedFile =
                    await _picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  setState(() {
                    _image = pickedFile;
                  });
                }
              },
            ),
            ListTile(
              title: Text('Pick From Gallery'),
              onTap: () async {
                Navigator.of(context).pop();
                final pickedFile =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    _image = pickedFile;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _TextController.dispose();
    super.dispose();
  }
}
