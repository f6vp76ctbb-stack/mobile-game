/// Firebase project constants (project "qubble", set up 2026-07-22).
///
/// These values are deliberately committed: Firebase client config is not a
/// secret — it ships inside every app binary and web bundle by design. Access
/// control comes from the Firestore security rules (`firebase/firestore.rules`)
/// and Google's API restrictions, never from hiding these identifiers.
class FirebaseConfig {
  const FirebaseConfig._();

  static const projectId = 'qubble';
  static const apiKey = 'AIzaSyBbZTzIdLAp2F8CLCpGUOHG4P8I5-fOfaY';
  static const messagingSenderId = '108672510585';
  static const androidAppId = '1:108672510585:android:4ceeb3ce32d40a2d8302a8';
  static const storageBucket = 'qubble.firebasestorage.app';
}
