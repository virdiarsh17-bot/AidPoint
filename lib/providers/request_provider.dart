import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incident_report.dart';

class RequestProvider extends ChangeNotifier {
  List<IncidentReport> _requests = [];

  List<IncidentReport> get requests => _requests;

  RequestProvider() {
    FirebaseFirestore.instance
        .collection('requests')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _requests = snapshot.docs.map((doc) => IncidentReport.fromFirestore(doc)).toList();
      notifyListeners();
    });
  }
}
