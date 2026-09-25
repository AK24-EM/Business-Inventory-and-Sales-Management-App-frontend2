/// Test Runner - Executes all test suites
/// 
/// This file provides a convenient way to run all tests in the project.
/// It groups tests by category for better organization and reporting.

import 'package:flutter_test/flutter_test.dart';

// Import all test files
import 'models/sale_model_test.dart' as sale_model_tests;
import 'models/customer_model_test.dart' as customer_model_tests;
import 'services/analytics_service_test.dart' as analytics_service_tests;

void main() {
  group('🧪 ALL TESTS', () {
    group('📦 Model Tests', () {
      sale_model_tests.main();
      customer_model_tests.main();
    });

    group('⚙️ Service Tests', () {
      analytics_service_tests.main();
    });

    // Add more test groups here as they're created
    // group('🎨 Widget Tests', () {
    //   login_screen_tests.main();
    //   pos_screen_tests.main();
    // });

    // group('🔗 Integration Tests', () {
    //   sale_flow_tests.main();
    // });
  });
}
