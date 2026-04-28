# AidPoint V2 (Smart Relief) 🌍🤝

AidPoint V2 is a comprehensive disaster relief and aid management platform built with Flutter. It streamlines incident reporting, resource allocation, and task management across different organizational roles during emergencies. By integrating real-time databases, interactive maps, and AI-powered categorization, AidPoint ensures coordinated and efficient relief operations.

🛑 Note to Judges: Testing Environment Requirements AidPoint relies on native Android hardware to function correctly (specifically the Camera for Gemini Vision AI parsing, and GPS for field geolocation). Please install the provided APK on a physical Android device to test full functionality, as standard emulators may fail to run these native features.

## ✨ Key Features

* Role-Based Access Control (RBAC): Dedicated dashboards and permissions for different user roles:
* Chief Director: Oversees operations via a Master Log and manages personnel.
* Field Lead: Reports incidents, manages tasks, and updates statuses on the ground.
* Supply Partner: Coordinates and provides necessary relief supplies.
* Real-time Incident Reporting: Users can submit relief requests with photos and descriptions, which instantly sync across the network.
* Interactive Mapping & Geocoding: Pinpoint incident locations using draggable maps with human-readable addresses (Reverse Geocoding).
* AI-Powered Supply Categorization: Uses Google Gemini OCR to automatically analyze and categorize handwritten or photographed supply lists.
* Task Claiming Workflow: Structured workflow for claiming and partially fulfilling relief tasks.
* Cloud Infrastructure: Fully powered by Firebase (Authentication, Cloud Firestore, Storage) for real-time data sync and secure media storage.

## 🛠️ Tech Stack

* Framework: [Flutter](https://flutter.dev/) (Dart)
* Backend Platform: [Firebase](https://firebase.google.com/)
* Firebase Authentication
* Cloud Firestore
* Firebase Storage
* AI & Machine Learning: Google Generative AI (`google_generative_ai`)
* Mapping: `flutter_map`, `latlong2`, `geocoding`, `geolocator`
* State Management: `provider`
* Hardware Integrations: `image_picker` (Camera/Gallery access)

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (>=3.11.4)
* Android Studio / Xcode for emulators
* A Firebase Project configured for Android/iOS
* A Google Gemini API Key

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/virdiarsh17-bot/AidPoint.git
   cd AidPoint_V2/aidpoint
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Configure Firebase
   Ensure your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are placed in the respective directories. Update the `firebase_options.dart` if necessary. Make sure to add your SHA-1 and SHA-256 fingerprints to your Firebase project for authentication.

4. Run the app
   ```bash
   flutter run
   ```

## 🔐 Environment Setup

You will need to set up certain environment variables or configuration files for external APIs:
* Firebase: Handled via standard initialization using `firebase_core`.
* Gemini API: Ensure your Gemini API Key is correctly injected into the application's AI service layer to enable OCR capabilities.

## 🤝 Contributing
Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](issues).

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
