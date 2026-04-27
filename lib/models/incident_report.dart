import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentReport {
  final String id;
  final String reporterUid;
  final String reporterName;
  final double latitude;
  final double longitude;
  final String? address;
  final String description;
  final int quantity;
  final String status; // 'Open', 'Active', 'Completed'
  final String? claimedByUid;
  final String? claimedByName;
  final String? supplierName;
  final String? supplierContact;
  final String? reporterContact;
  final DateTime timestamp;

  IncidentReport({
    required this.id,
    required this.reporterUid,
    required this.reporterName,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.quantity,
    required this.status,
    this.claimedByUid,
    this.claimedByName,
    this.supplierName,
    this.supplierContact,
    this.reporterContact,
    this.address,
    required this.timestamp,
  });

  factory IncidentReport.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return IncidentReport(
      id: doc.id,
      reporterUid: data['reporterUid'] ?? '',
      reporterName: data['reporterName'] ?? 'Unknown',
      latitude: data['latitude'] ?? 0.0,
      longitude: data['longitude'] ?? 0.0,
      description: data['description'] ?? '',
      quantity: data['quantity'] ?? 1,
      status: data['status'] ?? 'Open',
      claimedByUid: data['claimedByUid'],
      claimedByName: data['claimedByName'],
      supplierName: data['supplierName'],
      supplierContact: data['supplierContact'],
      reporterContact: data['reporterContact'],
      address: data['address'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterUid': reporterUid,
      'reporterName': reporterName,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'quantity': quantity,
      'status': status,
      'claimedByUid': claimedByUid,
      'claimedByName': claimedByName,
      'supplierName': supplierName,
      'supplierContact': supplierContact,
      'reporterContact': reporterContact,
      'address': address,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}


