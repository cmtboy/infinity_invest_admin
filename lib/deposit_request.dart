import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:infinity_invest_admin/notification_provider.dart';

class DepositRequestModel {
  String name;
  double amount;
  String senderNumber;
  String transactionId;
  String uid;

  DepositRequestModel({
    required this.name,
    required this.amount,
    required this.senderNumber,
    required this.transactionId,
    required this.uid,
  });
}

class DepositRequest extends StatefulWidget {
  const DepositRequest({Key? key}) : super(key: key);

  @override
  State<DepositRequest> createState() => _DepositRequestState();
}

class _DepositRequestState extends State<DepositRequest> {
  final CollectionReference _adminCollection =
      FirebaseFirestore.instance.collection('admin');

  Future<List<DepositRequestModel>> _fetchDepositRequests() async {
    try {
      DocumentSnapshot depositDoc = await _adminCollection.doc('deposit').get();

      List<dynamic> depositRequestsData = depositDoc['depositrequest'];

      List<DepositRequestModel> depositRequests = depositRequestsData
          .map((data) => DepositRequestModel(
                name: data['name'] ?? '',
                amount: double.parse(data['amount'] ?? '0.0'),
                senderNumber: data['sendernumber'] ?? '',
                transactionId: data['transactionId'] ?? '',
                uid: data['uid'] ?? '',
              ))
          .toList();

      return depositRequests;
    } catch (e) {
      throw Exception('Error fetching deposit requests: $e');
    }
  }

  bool _isApproving = false;
  bool _isDeclining = false;
  Future<void> _approveRequest(DepositRequestModel request) async {
    setState(() {
      _isApproving = true;
    });
    // Get user document from 'users' collection
    DocumentReference userDocRef =
        FirebaseFirestore.instance.collection('users').doc(request.uid);

    try {
      // Fetch current user balance
      DocumentSnapshot userDoc = await userDocRef.get();
      double currentBalance = double.parse(userDoc['balance'] ?? '0.0');
      String parentRefer = userDoc['parent_refer'] ?? '';

      // Update user balance by adding the deposit amount
      double newBalance = currentBalance + request.amount;
      await userDocRef.update({'balance': newBalance.toString()});

      // Add the approved request to the 'deposit_history' array
      await userDocRef.update({
        'deposit_history': FieldValue.arrayUnion([
          {
            'name': request.name,
            'amount': request.amount,
            'senderNumber': request.senderNumber,
            'transactionId': request.transactionId,
          }
        ]),
      });
      updateParentReferbalance(parentRefer, request.amount);
      saveNewNotification(request.uid, 'Admin Approved your deposit Request',
          'your deposit balance added your wallet balance');
      // Remove the approved request from the 'depositrequest' array
      await removeRequestToAdmin(request);
      setState(() {
        _isApproving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Request approved successrfully"),
        ),
      );
      FocusScope.of(context).unfocus();
      print('Request approved successfully!');
    } catch (e) {
      print('Error approving request: $e');
    }
  }

  removeRequestToAdmin(DepositRequestModel request) async {
    final adminDocRef =
        FirebaseFirestore.instance.collection('admin').doc('deposit');

    final adminDataSnapshot = await adminDocRef.get();
    final adminDataMap = adminDataSnapshot.data();

    if (adminDataMap == null || !adminDataMap.containsKey('depositrequest')) {
      print('Error: depositRequest data not found');
      return;
    }

    List<Map<String, dynamic>> depositRequests =
        (adminDataMap['depositrequest'] as List).cast<Map<String, dynamic>>();
    // print(depositRequests);
    final targetIndex = depositRequests.indexWhere((item) =>
        item['uid'] == request.uid &&
        item['transactionId'] == request.transactionId);
    // print("target index $targetIndex");

    // print(request.uid);
    // print(request.amount);
    // print(request.transactionId);

    if (targetIndex != -1) {
      depositRequests.removeAt(targetIndex);

      adminDataMap['depositrequest'] = depositRequests;
      print("updated depositRequests $depositRequests");
      await adminDocRef.update(adminDataMap);
      print("teget index deleted sucessfully");
    }
  }

  Future<void> _declineRequest(DepositRequestModel request) async {
    try {
      setState(() {
        _isDeclining = true;
      });
      // Remove the declined request from the 'depositrequest' array
      await removeRequestToAdmin(request);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Request delete successrfully"),
        ),
      );
      saveNewNotification(request.uid, 'Admin declined your deposit Request',
          'Try again with valid information');
      setState(() {
        _isDeclining = false;
      });
      FocusScope.of(context).unfocus();
      print('Request declined successfully!');
    } catch (e) {
      print('Error declining request: $e');
    }
  }

  Future<void> updateParentReferbalance(
      searchValue, double depositAmount) async {
    try {
      // Level 1: Get the first-level referred user
      QuerySnapshot level1QuerySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('refer_code', isEqualTo: searchValue)
          .get();

      if (level1QuerySnapshot.docs.isNotEmpty) {
        for (QueryDocumentSnapshot level1Document in level1QuerySnapshot.docs) {
          var level1Data = level1Document.data() as Map<String, dynamic>;
          double level1Balance = double.parse(level1Data['balance']);
          // Update the first-level referred user's balance
          await FirebaseFirestore.instance
              .collection('users')
              .doc(level1Document.id)
              .update({
            'balance': (level1Balance + (depositAmount * 0.07)).toString(),
          });

          // Level 2: Get the second-level referred user
          String level2ParentRefer = level1Data['parent_refer'] ?? '';
          if (level2ParentRefer.isNotEmpty) {
            QuerySnapshot level2QuerySnapshot = await FirebaseFirestore.instance
                .collection('users')
                .where('refer_code', isEqualTo: level2ParentRefer)
                .get();

            if (level2QuerySnapshot.docs.isNotEmpty) {
              for (QueryDocumentSnapshot level2Document
                  in level2QuerySnapshot.docs) {
                var level2Data = level2Document.data() as Map<String, dynamic>;
                double level2Balance = double.parse(level2Data['balance']);
                // Update the second-level referred user's balance
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(level2Document.id)
                    .update({
                  'balance':
                      (level2Balance + (depositAmount * 0.03)).toString(),
                });

                // Level 3: Get the third-level referred user
                String level3ParentRefer = level2Data['parent_refer'] ?? '';
                if (level3ParentRefer.isNotEmpty) {
                  QuerySnapshot level3QuerySnapshot = await FirebaseFirestore
                      .instance
                      .collection('users')
                      .where('refer_code', isEqualTo: level3ParentRefer)
                      .get();

                  if (level3QuerySnapshot.docs.isNotEmpty) {
                    for (QueryDocumentSnapshot level3Document
                        in level3QuerySnapshot.docs) {
                      var level3Data =
                          level3Document.data() as Map<String, dynamic>;
                      double level3Balance =
                          double.parse(level3Data['balance']);
                      // Update the third-level referred user's balance
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(level3Document.id)
                          .update({
                        'balance':
                            (level3Balance + (depositAmount * 0.02)).toString(),
                      });
                    }
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error updating referral balances: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton:
          _isApproving || _isDeclining ? CircularProgressIndicator() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      appBar: AppBar(
        title: Text('Deposit Requests'),
      ),
      body: FutureBuilder(
        future: _fetchDepositRequests(),
        builder: (context, AsyncSnapshot<List<DepositRequestModel>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Text('No deposit requests found');
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                DepositRequestModel request = snapshot.data![index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: ListTile(
                      title: Text('${request.name} - \$${request.amount}'),
                      subtitle:
                          Text('Transaction ID: ${request.transactionId}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.check),
                            onPressed: () => _approveRequest(request),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => _declineRequest(request),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
