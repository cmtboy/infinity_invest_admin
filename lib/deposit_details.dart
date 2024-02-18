import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DepositDetailsModel {
  String depositMethod;
  String minimumDeposit;
  String number;

  DepositDetailsModel({
    required this.depositMethod,
    required this.minimumDeposit,
    required this.number,
  });

  factory DepositDetailsModel.fromMap(Map<String, dynamic> map) {
    return DepositDetailsModel(
      depositMethod: map['depositmethod'] ?? '',
      minimumDeposit: map['minimumdeposit'] ?? "0.0",
      number: map['number'] ?? "0",
    );
  }
}

class DepositDetails extends StatefulWidget {
  const DepositDetails({Key? key}) : super(key: key);

  @override
  State<DepositDetails> createState() => _DepositDetailsState();
}

class _DepositDetailsState extends State<DepositDetails> {
  final TextEditingController depositMethodController = TextEditingController();
  final TextEditingController minimumDepositController =
      TextEditingController();
  final TextEditingController numberController = TextEditingController();

  late CollectionReference _adminCollection;

  @override
  void initState() {
    super.initState();
    _adminCollection = FirebaseFirestore.instance.collection('admin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Deposit Details'),
      ),
      body: FutureBuilder(
        future: _fetchDepositDetails(),
        builder: (context, AsyncSnapshot<DepositDetailsModel> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData) {
            return Text('No data found');
          } else {
            DepositDetailsModel depositDetails = snapshot.data!;
            depositMethodController.text = depositDetails.depositMethod;
            minimumDepositController.text =
                depositDetails.minimumDeposit.toString();
            numberController.text = depositDetails.number.toString();

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: depositMethodController,
                    decoration: InputDecoration(labelText: 'Deposit Method'),
                  ),
                  TextField(
                    controller: minimumDepositController,
                    decoration: InputDecoration(labelText: 'Minimum Deposit'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: numberController,
                    decoration: InputDecoration(labelText: 'Number'),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveChanges,
                    child: Text('Save Changes'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Future<DepositDetailsModel> _fetchDepositDetails() async {
    try {
      DocumentSnapshot depositDoc = await _adminCollection.doc('deposit').get();
      Map<String, dynamic> depositData = depositDoc['depositdetails'];
      return DepositDetailsModel.fromMap(depositData);
    } catch (e) {
      throw Exception('Error fetching deposit details: $e');
    }
  }

  void _saveChanges() async {
    try {
      await _adminCollection.doc('deposit').update({
        'depositdetails': {
          'depositmethod': depositMethodController.text,
          'minimumdeposit': minimumDepositController.text,
          'number': numberController.text,
        },
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Data update successrfully"),
        ),
      );
      FocusScope.of(context).unfocus();
      print('Changes saved!');
    } catch (e) {
      print('Error saving changes: $e');
    }
  }
}
