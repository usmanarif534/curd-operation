import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UploadImageToFirebase extends StatefulWidget {
  const UploadImageToFirebase({Key? key}) : super(key: key);

  @override
  State<UploadImageToFirebase> createState() => _UploadImageToFirebaseState();
}

class _UploadImageToFirebaseState extends State<UploadImageToFirebase> {
  FirebaseStorage storage = FirebaseStorage.instance;
  File? image;

  // pick image
  Future pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        image = File(pickedFile!.path);
      });
    }
  }

  getPath(String path) {
    path = image!.path;
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('upload image'),
      onPressed: () {
        pickImage();
      },
    );
  }
}
