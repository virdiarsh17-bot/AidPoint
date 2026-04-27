import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../models/incident_report.dart';

class SupplierDashboard extends StatefulWidget {
  const SupplierDashboard({super.key});

  @override
  State<SupplierDashboard> createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _navigate(double lat, double lng) async {
    final url = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      final fallbackUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      if (await canLaunchUrl(fallbackUrl)) {
        await launchUrl(fallbackUrl);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open Google Maps.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<RequestProvider>().requests;
    final currentUserUid = context.watch<AuthProvider>().firebaseUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().signOut(),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Requests'),
            Tab(text: 'My Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestList(
            requests.where((r) => r.status == 'Open').toList(),
            showClaimButton: true,
          ),
          _buildRequestList(
            requests.where((r) => r.status == 'Active' && r.claimedByUid == currentUserUid).toList(),
            showNavigateButton: true,
          ),
          _buildRequestList(
            requests.where((r) => r.status == 'Completed' && r.claimedByUid == currentUserUid).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(List<IncidentReport> list, {bool showClaimButton = false, bool showNavigateButton = false}) {
    if (list.isEmpty) {
      return RefreshIndicator(
        color: Colors.green,
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) setState(() {});
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: const Center(
                child: Text(
                  'No requests found in this section.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.green,
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) setState(() {});
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final req = list[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${req.description} (Quantity: ${req.quantity})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text('Reporter: ${req.reporterName}'),
                            Text('Status: ${req.status}'),
                            Text('Location: ${req.address ?? 'Unknown'}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (showClaimButton || showNavigateButton) const SizedBox(height: 12),
                  if (showClaimButton)
                    ElevatedButton(
                      onPressed: () => _showClaimDialog(req),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Claim Task'),
                    ),
                  if (showNavigateButton)
                    ElevatedButton.icon(
                      onPressed: () => _navigate(req.latitude, req.longitude),
                      icon: const Icon(Icons.navigation),
                      label: const Text('Navigate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showClaimDialog(IncidentReport req) {
    final TextEditingController quantityController = TextEditingController();
    quantityController.text = req.quantity.toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Claim Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How many ${req.description} can you provide?'),
              const SizedBox(height: 10),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity (Max: ${req.quantity})',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                int? claimedAmount = int.tryParse(quantityController.text);
                if (claimedAmount == null || claimedAmount <= 0 || claimedAmount > req.quantity) {
                  return;
                }
                Navigator.pop(context);

                final authProvider = context.read<AuthProvider>();
                final supplierName = authProvider.appUser?.name ?? 'Unknown Supplier';
                final supplierContact = authProvider.appUser?.phone ?? 'No Contact Info';

                if (claimedAmount == req.quantity) {
                  await FirebaseFirestore.instance.collection('requests').doc(req.id).update({
                    'status': 'Active',
                    'claimedByUid': authProvider.firebaseUser?.uid,
                    'claimedByName': supplierName,
                    'supplierName': supplierName,
                    'supplierContact': supplierContact,
                  });
                } else {
                  await FirebaseFirestore.instance.collection('requests').add({
                    'description': req.description,
                    'quantity': claimedAmount,
                    'status': 'Active',
                    'timestamp': FieldValue.serverTimestamp(),
                    'latitude': req.latitude,
                    'longitude': req.longitude,
                    'reporterUid': req.reporterUid,
                    'reporterName': req.reporterName,
                    'claimedByUid': authProvider.firebaseUser?.uid,
                    'claimedByName': supplierName,
                    'supplierName': supplierName,
                    'supplierContact': supplierContact,
                  });
                  await FirebaseFirestore.instance.collection('requests').doc(req.id).update({
                    'quantity': req.quantity - claimedAmount,
                  });
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}