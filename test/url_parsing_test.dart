import 'package:flutter_test/flutter_test.dart';
import 'package:gympad/services/url_parsing_service.dart';

void main() {
  group('UrlParsingService Tests', () {
    test('should parse valid GymPad URL correctly', () {
      const testUrl = 'https://gympad-e44fc.web.app/gymId="GYM_ABC"&equipmentId="123"';
      
      final result = UrlParsingService.parseGympadUrl(testUrl);
      
      expect(result, isNotNull);
      expect(result!['gymId'], equals('GYM_ABC'));
      expect(result['equipmentId'], equals('123'));
    });

    test('should return null for invalid URL', () {
      const testUrl = 'https://example.com/invalid';
      
      final result = UrlParsingService.parseGympadUrl(testUrl);
      
      expect(result, isNull);
    });

    test('should parse URL with query parameters', () {
      const testUrl = 'https://gympad-e44fc.web.app/?gymId=GYM_XYZ&equipmentId=456';
      
      final result = UrlParsingService.parseGympadUrl(testUrl);
      
      expect(result, isNotNull);
      expect(result!['gymId'], equals('GYM_XYZ'));
      expect(result['equipmentId'], equals('456'));
    });

    test('should debug URL parsing', () {
      const testUrl = 'https://gympad-e44fc.web.app/gymId="GYM_ABC"&equipmentId="123"';
      
      final uri = Uri.parse(testUrl);
      print('Host: ${uri.host}');
      print('Path: ${uri.path}');
      print('Decoded Path: ${Uri.decodeComponent(uri.path)}');
      print('Query: ${uri.query}');
      print('Fragment: ${uri.fragment}');
      
      // Test the regex
      final RegExp gymIdRegex = RegExp(r'gymId="([^"]+)"');
      final RegExp equipmentIdRegex = RegExp(r'equipmentId="([^"]+)"');
      
      final decodedPath = Uri.decodeComponent(uri.path);
      print('Full decoded path: $decodedPath');
      
      final gymIdMatch = gymIdRegex.firstMatch(decodedPath);
      final equipmentIdMatch = equipmentIdRegex.firstMatch(decodedPath);
      
      print('GymId match: ${gymIdMatch?.group(1)}');
      print('EquipmentId match: ${equipmentIdMatch?.group(1)}');
      
      expect(gymIdMatch, isNotNull);
      expect(equipmentIdMatch, isNotNull);
    });
  });
}
