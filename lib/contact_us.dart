import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactUs extends StatefulWidget {
  const ContactUs({Key? key}) : super(key: key);

  @override
  State<ContactUs> createState() => _ContactUsState();
}

class _ContactUsState extends State<ContactUs> {
  final CollectionReference adminCollection =
      FirebaseFirestore.instance.collection('admin');

  TextEditingController linkController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLink();
  }

  void _loadLink() {
    adminCollection.doc('contactus').get().then((document) {
      if (document.exists) {
        var link = document['link'];
        linkController.text = link;
      }
    });
  }

  Future<void> _updateLink() async {
    setState(() {
      isLoading = true;
    });

    try {
      await adminCollection.doc('contactus').update({
        'link': linkController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Link updated successfully'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error updating link: $e'),
      ));

      FocusScope.of(context).unfocus();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact Link'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 20,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: linkController,
                decoration: InputDecoration(
                  labelText: 'Contact Link',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _updateLink();
            },
            child: isLoading
                ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : Text('Save'),
          ),
        ],
      ),
    );
  }
}
