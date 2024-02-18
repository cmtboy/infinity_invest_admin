import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({Key? key}) : super(key: key);

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  final CollectionReference adminCollection =
      FirebaseFirestore.instance.collection('admin');

  TextEditingController titleController = TextEditingController();
  TextEditingController subtitleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notice'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showAddNoticeBottomSheet(context);
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: adminCollection.doc('announcement').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          List<Map<String, dynamic>> notices = List.from(data['data'] ?? []);

          return ListView.builder(
            itemCount: notices.length,
            itemBuilder: (context, index) {
              var notice = notices[index];
              return ListTile(
                title: Text(notice['title']),
                subtitle: Text(notice['subtitle']),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _deleteNotice(index);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddNoticeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Add New Notice'),
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextFormField(
                controller: subtitleController,
                decoration: InputDecoration(labelText: 'Subtitle'),
              ),
              ElevatedButton(
                onPressed: () {
                  _addNotice();
                  Navigator.of(context).pop();
                },
                child: Text('Add Notice'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addNotice() {
    var newNotice = {
      'title': titleController.text,
      'subtitle': subtitleController.text,
    };

    adminCollection.doc('announcement').update({
      'data': FieldValue.arrayUnion([newNotice]),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("New notice added successrfully"),
      ),
    );
    FocusScope.of(context).unfocus();
  }

  void _deleteNotice(int index) {
    adminCollection.doc('announcement').get().then((document) {
      if (document.exists) {
        List<Map<String, dynamic>> notices = List.from(document['data']);
        notices.removeAt(index);

        adminCollection.doc('announcement').update({
          'data': notices,
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Notice delete successrfully"),
      ),
    );
    FocusScope.of(context).unfocus();
  }
}
