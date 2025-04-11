import 'package:flutter/material.dart';
import 'simple_test_app.dart';

/// A simple main entry point for testing purposes
///
/// This bypasses all the complex dependencies to check
/// if the Flutter environment is working correctly
void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Run the simplified test app
  runApp(const SimpleTestApp());
}
