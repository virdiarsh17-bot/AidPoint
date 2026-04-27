import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/gemini_service.dart';
import '../../services/location_service.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../models/incident_report.dart';

class IncidentCreationScreen extends StatefulWidget {
  const IncidentCreationScreen({super.key});

  @override
  State<IncidentCreationScreen> createState() => _IncidentCreationScreenState();
}

class _IncidentCreationScreenState extends State<IncidentCreationScreen> {
  final _geminiService = GeminiService();
  final _locationService = LocationService();
  final _storageService = StorageService();
  final _authService = AuthService();
  
  final _descriptionController = TextEditingController();
  final MapController _mapController = MapController();

  File? _selectedImage;
  Uint8List? _imageBytes;
  
  LatLng _currentMapCenter = const LatLng(0, 0);
  bool _isLoadingLocation = true;

  bool _isSubmitting = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _handleLostData();
  }

  Future<void> _handleLostData() async {
    final ImagePicker picker = ImagePicker();
    final LostDataResponse response = await picker.retrieveLostData();
    if (response.isEmpty) return;
    
    if (response.file != null) {
      final Uint8List bytes = await response.file!.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _selectedImage = File(response.file!.path);
      });
      // Optionally run Gemini if needed, but for now just recover the image
    }
  }

  Future<bool> _checkPermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isPermanentlyDenied) {
        openAppSettings();
      }
      return status.isGranted;
    } else {
      // For gallery on Android 13+
      if (Platform.isAndroid) {
        final status = await Permission.photos.request();
        return status.isGranted;
      }
      return true;
    }
  }

  Future<void> _initLocation() async {
    print("--- DEBUG LOC 1: _initLocation started ---");
    try {
      Position? position = await _locationService.getCurrentPosition();
      if (position != null) {
        print("--- DEBUG LOC 2: Position found! ${position.latitude}, ${position.longitude} ---");
        if (mounted) {
          setState(() {
            _currentMapCenter = LatLng(position.latitude, position.longitude);
            _isLoadingLocation = false;
          });
          // Move the map securely
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _mapController.move(_currentMapCenter, 15.0);
          });
        }
      } else {
        print("--- DEBUG LOC 3: No position returned (Service disabled or permission denied) ---");
        if (mounted) setState(() => _isLoadingLocation = false);
      }
    } catch (e) {
      print("--- DEBUG LOC 4: Exception in _initLocation: $e ---");
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('GPS Timeout: Using default location.')));
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoading = true);
    print("--- DEBUG 1: Function Started ---");

    try {
      final ImagePicker picker = ImagePicker();
      print("--- DEBUG 2: Requesting Camera/Gallery (with 30s timeout) ---");

      // 2. Open the Camera
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 50,
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        print("--- DEBUG 2.1: Camera Request Timed Out ---");
        return null;
      });

      if (pickedFile == null) {
        print("--- DEBUG 3: User closed camera or timeout reached ---");
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      print("--- DEBUG 4: Photo captured! Size: ${await pickedFile.length()} bytes ---");
      final Uint8List bytes = await pickedFile.readAsBytes();

      // 3. Send to Gemini (The "Brain")
      print("--- DEBUG 5: Sending to Gemini AI (with 30s timeout) ---");
      final String ocrResult = await _geminiService.extractTextFromImage(bytes)
          .timeout(const Duration(seconds: 30), onTimeout: () => "Timeout error: AI took too long.");

      print("--- DEBUG 6: Gemini responded! ---");
      
      // Clean up markdown formatting if Gemini included it
      String cleanedResult = ocrResult;
      if (cleanedResult.contains("```json")) {
        cleanedResult = cleanedResult.split("```json").last.split("```").first.trim();
      } else if (cleanedResult.contains("```")) {
        cleanedResult = cleanedResult.split("```").last.split("```").first.trim();
      }

      setState(() {
        _descriptionController.text = cleanedResult;
        _imageBytes = bytes;
        _selectedImage = File(pickedFile.path);
      });
    } catch (e) {
      print("--- DEBUG 10: Error in _pickImage: $e ---");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      print("--- DEBUG 11: Function Finished, clearing loader ---");
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _submitReport() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try { final result = await InternetAddress.lookup('google.com'); if (result.isEmpty || result[0].rawAddress.isEmpty) { throw Exception("No Internet"); } } on SocketException catch (_) { if (mounted) { ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text("No internet connection! Please check your network and try again."), backgroundColor: Colors.red, ), ); setState(() => _isSubmitting = false); } return; }

    try {
      print("--- LOG: Attempting to split JSON and save to Firestore ---");
      String rawText = _descriptionController.text;
      String cleanJson = rawText.replaceAll('```json', '').replaceAll('```', '').trim();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final reporterName = authProvider.appUser?.name ?? 'Unknown';
      final reporterContact = authProvider.appUser?.phone ?? 'N/A';
      
      String? address = await _locationService.getAddressFromCoordinates(_currentMapCenter.latitude, _currentMapCenter.longitude);

      try {
        List parsedList = jsonDecode(cleanJson);
        for (var item in parsedList) {
          String itemName = "";
          int itemQuantity = 1;
          if (item is Map) {
            itemName = item['item']?.toString() ?? 'Unknown Item';
            itemQuantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
          } else {
            itemName = item.toString();
          }

          await FirebaseFirestore.instance.collection('requests').add({
            'description': itemName,
            'quantity': itemQuantity,
            'status': 'Open',
            'timestamp': FieldValue.serverTimestamp(),
            'latitude': _currentMapCenter.latitude,
            'longitude': _currentMapCenter.longitude,
            'address': address,
            'reporterUid': _authService.currentUser?.uid ?? '',
            'reporterName': reporterName,
            'reporterContact': reporterContact,
          }).timeout(const Duration(seconds: 15));
        }

      } catch (formatError) {
        print("--- LOG: JSON parse failed, saving as single text block ---");
        await FirebaseFirestore.instance.collection('requests').add({
          'description': rawText,
          'quantity': 1,
          'status': 'Open',
          'timestamp': FieldValue.serverTimestamp(),
          'latitude': _currentMapCenter.latitude,
          'longitude': _currentMapCenter.longitude,
          'address': address,
          'reporterUid': _authService.currentUser?.uid ?? '',
          'reporterName': reporterName,
          'reporterContact': reporterContact,
        }).timeout(const Duration(seconds: 15));
      }



      print("--- LOG: Firestore Save SUCCESS! ---");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request submitted successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("--- FATAL SUBMIT ERROR: $e ---");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Submit Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Relief Request')),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // 1. Draggable Map
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueAccent, width: 2),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _currentMapCenter,
                            initialZoom: 15.0,
                            onPositionChanged: (position, hasGesture) {
                              if (hasGesture) {
                                setState(() => _currentMapCenter = position.center);
                              }
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.panda.aidpoint',
                            ),
                          ],
                        ),
                        // Fixed Center Pin
                        const Center(
                          child: Icon(Icons.location_on, size: 40, color: Colors.red),
                        ),
                        // Small loader if location is still being fetched
                        if (_isLoadingLocation)
                          Container(
                            color: Colors.black12,
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 8),
                                  Text("Finding you...", style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Drag the map to pinpoint the exact location.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]), textAlign: TextAlign.center),
                  const SizedBox(height: 24),

                  // 2. Media Upload
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Image Preview constrained to 150 height
                  if (_selectedImage != null)
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 24),

                   // 4. OCR Extraction & Text Field
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Extracted / Manual Details',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting ? null : _submitReport,
                      child: _isSubmitting 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text('Submit Request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}