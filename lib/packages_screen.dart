import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({Key? key}) : super(key: key);

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final CollectionReference packagesCollection =
      FirebaseFirestore.instance.collection('admin');

  TextEditingController packagenameController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController dailyIncomeController = TextEditingController();
  TextEditingController validityController = TextEditingController();
  // String? packageImage;
  String? imagelink;

  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();
  bool isUploading = false;

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

        // Update the user's profile picture in Firebase Authentication
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Packages'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showAddPackageBottomSheet(context);
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: packagesCollection.doc('packagelist').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }
          var data = snapshot.data;
          List<Map<String, dynamic>> packageList =
              List.from(data!['data'] ?? []);

          return ListView.builder(
            itemCount: packageList.length,
            itemBuilder: (context, index) {
              var package = packageList[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(package['packagename']!),
                    subtitle: Text('Price: ${package['price']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            _showEditPackageBottomSheet(
                                context, package, index);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _deletePackage(index);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddPackageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Add New Package'),
                  TextFormField(
                    controller: packagenameController,
                    decoration: InputDecoration(labelText: 'Package Name'),
                  ),
                  TextFormField(
                    readOnly: true,
                    onTap: () async {
                      setState(() {
                        isUploading = true;
                      });
                      _uploadPicture().then((_) {
                        setState(() {
                          isUploading = false;
                        });
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Image',
                      suffixIcon: imagelink == null
                          ? null
                          : SizedBox(
                              height: 20,
                              child: Image.network(
                                imagelink!,
                                fit: BoxFit.cover,
                              )),
                    ),
                  ),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    controller: priceController,
                    decoration: InputDecoration(labelText: 'Price'),
                  ),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    controller: dailyIncomeController,
                    decoration: InputDecoration(labelText: 'Daily Income'),
                  ),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    controller: validityController,
                    decoration: InputDecoration(labelText: 'Validity'),
                  ),
                  isUploading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () {
                            _addPackage();
                            Navigator.of(context).pop();
                          },
                          child: Text('Add Package'),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditPackageBottomSheet(
      BuildContext context, Map<String, dynamic> package, int index) {
    packagenameController.text = package['packagename']!;
    priceController.text = package['price']!;
    dailyIncomeController.text = package['dailyincome']!;
    validityController.text = package['validity']!;
    imagelink = package['imagestring'];

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Edit Package'),
                  TextFormField(
                    controller: packagenameController,
                    decoration: InputDecoration(labelText: 'Package Name'),
                  ),
                  TextFormField(
                    readOnly: true,
                    onTap: () async {
                      setState(() {
                        isUploading = true;
                      });
                      _uploadPicture().then((_) {
                        setState(() {
                          isUploading = false;
                        });
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Image',
                      suffixIcon: imagelink == null
                          ? null
                          : SizedBox(
                              height: 20,
                              child: Image.network(imagelink!),
                            ),
                    ),
                  ),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    controller: priceController,
                    decoration: InputDecoration(labelText: 'Price'),
                  ),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    controller: dailyIncomeController,
                    decoration: InputDecoration(labelText: 'Daily Income'),
                  ),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    controller: validityController,
                    decoration: InputDecoration(labelText: 'Validity'),
                  ),
                  isUploading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () {
                            _updatePackage(index);
                            Navigator.of(context).pop();
                          },
                          child: Text('Update Package'),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addPackage() {
    packagesCollection.doc('packagelist').update({
      'data': FieldValue.arrayUnion([
        {
          'packagename': packagenameController.text,
          'price': priceController.text,
          'dailyincome': dailyIncomeController.text,
          'validity': validityController.text,
          'imagestring': imagelink
        }
      ])
    });
  }

  void _updatePackage(int index) async {
    // Get the document that contains the package list
    DocumentSnapshot document =
        await packagesCollection.doc('packagelist').get();
    // Get the list of packages from the document
    List<Map<String, dynamic>> packageList = List.from(document['data'] ?? []);

    // Update the package at the specified index
    packageList[index]['packagename'] = packagenameController.text;
    packageList[index]['price'] = priceController.text;
    packageList[index]['dailyincome'] = dailyIncomeController.text;
    packageList[index]['validity'] = validityController.text;
    packageList[index]['imagestring'] = imagelink;

    // Update the document with the updated list of packages
    await packagesCollection.doc('packagelist').update({
      'data': packageList,
    });
  }

  void _deletePackage(int index) async {
    DocumentSnapshot document =
        await packagesCollection.doc('packagelist').get();
    List<Map<String, dynamic>> packageList = List.from(document['data'] ?? []);
    packageList.removeAt(index);
    packagesCollection.doc('packagelist').update({
      'data': packageList,
    });
  }
}
