import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../models/incident_report.dart';
import '../features/incident_creation_screen.dart';

class FieldLeadDashboard extends StatefulWidget {
  const FieldLeadDashboard({super.key});

  @override
  State<FieldLeadDashboard> createState() => _FieldLeadDashboardState();
}
class _FieldLeadDashboardState extends State<FieldLeadDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  void _completeTask(IncidentReport req) async {
    await FirebaseFirestore.instance.collection('requests').doc(req.id).update({
      'status': 'Completed',
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task Marked as Completed!')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final requests = context.watch<RequestProvider>().requests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Lead Dashboard'),
        backgroundColor: Colors.blueAccent,
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
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestList(requests, 'Open'),
          _buildRequestList(requests, 'Active'),
          _buildRequestList(requests, 'Completed'),
        ],
      ),
      floatingActionButton: SizedBox(
        height: 60,
        width: 60,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const IncidentCreationScreen()),
            );
          },
          backgroundColor: Colors.blueAccent.shade700,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Modern rounded-square look
          ),
          child: const Icon(
            Icons.camera_enhance_rounded,
            size: 30,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
  Widget _buildRequestList(List<IncidentReport> allRequests, String status) {
    final filtered = allRequests.where((r) => r.status == status).toList();
    
    if (filtered.isEmpty) {
      return RefreshIndicator(
        color: Colors.blueAccent,
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) setState(() {});
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Text(
                  'No $status requests found.',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: Colors.blueAccent,
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) setState(() {});
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final req = filtered[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text( '${req.description} (Quantity: ${req.quantity})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), ),
              subtitle: Text('Status: ${req.status}'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Reporter: ${req.reporterName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Location: ${req.address ?? '${req.latitude}, ${req.longitude}'}'),
                      const SizedBox(height: 8),
                      (req.supplierName != null)
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Handled by: ${req.supplierName} \nContact: ${req.supplierContact}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                      Text('Full Description: ${req.description}'),
                      if (status == 'Active') ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _completeTask(req),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Mark as Completed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}