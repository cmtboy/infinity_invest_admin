import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReferBenefit extends StatefulWidget {
  const ReferBenefit({Key? key}) : super(key: key);

  @override
  State<ReferBenefit> createState() => _ReferBenefitState();
}

class _ReferBenefitState extends State<ReferBenefit> {
  final TextEditingController _benefitController = TextEditingController();
  final CollectionReference _adminCollection =
      FirebaseFirestore.instance.collection('admin');

  @override
  void initState() {
    super.initState();
    _loadBenefit();
  }

  Future<void> _loadBenefit() async {
    try {
      DocumentSnapshot referDoc = await _adminCollection.doc('refer').get();
      String benefit = referDoc['benefit'] ?? '';
      _benefitController.text = benefit;
    } catch (e) {
      print('Error loading benefit: $e');
    }
  }

  Future<void> _updateBenefit() async {
    try {
      await _adminCollection.doc('refer').update({
        'benefit': _benefitController.text,
      });
      print('Benefit updated successfully!');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Data update successrfully"),
        ),
      );
      FocusScope.of(context).unfocus();
    } catch (e) {
      print('Error updating benefit: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Refer Benefit'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              keyboardType: TextInputType.number,
              controller: _benefitController,
              decoration: InputDecoration(labelText: 'Benefit'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateBenefit,
              child: Text('Update Benefit'),
            ),
          ],
        ),
      ),
    );
  }
}
