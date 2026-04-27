import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DirectorDashboard extends StatelessWidget {
  const DirectorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<RequestProvider>().requests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chief Director Dashboard'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().signOut(),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: Colors.purple), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  const Padding(padding: EdgeInsets.all(8.0), child: Text('Master Log (All Requests)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final req = requests[index];
                        return ListTile(
                          title: Text(req.description, maxLines: 1),
                          subtitle: Text('Status: ${req.status} | Qty: ${req.quantity} | Loc: ${req.address ?? '${req.latitude.toStringAsFixed(2)}, ${req.longitude.toStringAsFixed(2)}'}'),
                          trailing: req.status == 'Open' ? const Icon(Icons.error, color: Colors.red) : const Icon(Icons.check_circle, color: Colors.green),
                          onTap: () => _showRequestDetails(context, req),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  const Padding(padding: EdgeInsets.all(8.0), child: Text('Personnel Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                  const Divider(),
                  Expanded(
                    child: FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance.collection('users').get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final users = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, idx) {
                            final u = users[idx].data() as Map<String, dynamic>;
                            return ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(u['email'] ?? 'Unknown User'),
                              subtitle: Text('Role: ${u['role'] ?? 'None'}'),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestDetails(BuildContext context, dynamic req) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(req.description),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Status', req.status),
              _detailRow('Quantity', req.quantity.toString()),
              _detailRow('Location', req.address ?? '${req.latitude}, ${req.longitude}'),
              const Divider(),
              _detailRow('Field Lead', req.reporterName),
              _detailRow('Field Lead Contact', req.reporterContact ?? 'N/A'),
              if (req.status == 'Completed') ...[
                _detailRow('Supply Partner', req.supplierName ?? 'N/A'),
                _detailRow('Supplier Contact', req.supplierContact ?? 'N/A'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
