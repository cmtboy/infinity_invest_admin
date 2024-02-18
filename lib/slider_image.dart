import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class SliderScreen extends StatefulWidget {
  @override
  _SliderScreenState createState() => _SliderScreenState();
}

class _SliderScreenState extends State<SliderScreen> {
  List<String> sliderData = [];

  @override
  void initState() {
    super.initState();
    // Call the fetchSliderImage function when the screen is first created
    fetchSliderImage();
  }

  Future<void> fetchSliderImage() async {
    try {
      DocumentSnapshot admindoc = await FirebaseFirestore.instance
          .collection('admin')
          .doc('slider')
          .get();

      // Check if the document exists
      if (admindoc.exists) {
        // Document exists, retrieve data
        List<dynamic>? sliderdata = admindoc['items'];

        // Ensure that sliderdata is not null before proceeding
        if (sliderdata != null) {
          // Filter out non-String elements and convert them to String
          setState(() {
            // Update the state with the converted data
            sliderData = sliderdata.whereType<String>().toList();
          });

          print(sliderData);
        } else {
          // Handle the case where 'items' is null
          print("Items is null in the document.");
        }
      } else {
        // Document doesn't exist
        print("Document does not exist.");
      }
    } catch (e) {
      // Handle any errors that occurred during the try block
      print("Error fetching document: $e");
    }
  }

  // // Add your Firestore collection reference
  final CollectionReference _adminCollection =
      FirebaseFirestore.instance.collection('admin');


  String? imagelink;

  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();
  bool isUploading = false;
  bool isloading = false;

  Future<void> _uploadPicture() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final Reference storageRef = _storage
          .ref()
          .child('pictures/${DateTime.now().toIso8601String()}.jpg');

      UploadTask uploadTask = storageRef.putFile(File(pickedFile.path));
      setState(() {
        isUploading = true; // Set to false when there's an error
      });

      // Wait until the upload is complete and we have received the download URL
      // before updating the user's profile picture
      await uploadTask.whenComplete(() async {
        final String imageUrl = await storageRef.getDownloadURL();

        await _adminCollection.doc('slider').update({
          'items': FieldValue.arrayUnion([imageUrl]),
        });
        setState(() {
          imagelink = imageUrl;
        });
        print(imagelink);

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("picture updated successfully")));

        setState(() {
          isUploading = false; // Set to false when there's an error
        });
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error updating picture: $error")));
        return error;
      });
    }
  }

  Future<void> deleteImageLink(String imageUrl) async {
     setState(() {
          isloading = true; // Set to false when there's an error
        });
    try {
      // Remove the image URL from the Firestore 'items' array
      await _adminCollection.doc('slider').update({
        'items': FieldValue.arrayRemove([imageUrl]),
      });

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image deleted successfully.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Handle any errors that occurred during the try block
      print("Error deleting image link: $e");

      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting image.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
         setState(() {
          isloading = false; // Set to false when there's an error
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Slider Images'),
      ),
      body: sliderData.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: sliderData.length,
                itemBuilder: (context, index) {
                  // You can use any widget to display the images, for example, Image.network
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Image.network(
                            sliderData[index],
                            fit: BoxFit
                                .cover, // Adjust the BoxFit property based on your requirement
                          ),
                        ),
                        Expanded(
                            flex: 1,
                            child: IconButton(
                                onPressed: () {
                                  deleteImageLink( sliderData[index]);
                                },
                                icon: Icon(Icons.delete))),
                      ],
                    ),
                  );
                },
              ),
            )
          : Center(
              // Show a loading indicator or message while data is being fetched
              child: CircularProgressIndicator(),
            ),
      floatingActionButton:isUploading|| isloading ?CircularProgressIndicator(): FloatingActionButton(
        onPressed: () {
          _uploadPicture();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
