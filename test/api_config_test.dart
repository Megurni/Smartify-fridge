import 'package:flutter_test/flutter_test.dart';
import 'package:smartify_refrigerator_demo/config/api_config.dart';

void main() {
  for (final origin in [
    'http://localhost:8080',
    'http://100.112.112.84:8080',
    'https://fridge.example',
  ]) {
    test('web uses the same origin at $origin', () {
      final base = resolveApiBaseUrl(
        isWeb: true,
        nativeDefaultUrl: 'http://localhost:5001',
        pageUrl: Uri.parse('$origin/inventory?filter=urgent'),
      );
      expect(base, '$origin/api/');
      expect(Uri.parse(base).resolve('items').toString(), '$origin/api/items');
      expect(
        Uri.parse(base).resolve('item/3/remove').toString(),
        '$origin/api/item/3/remove',
      );
    });
  }

  test('explicit backend URL overrides same-origin routing', () {
    expect(
      resolveApiBaseUrl(
        isWeb: true,
        nativeDefaultUrl: 'http://localhost:5001',
        configuredUrl: 'http://100.112.112.84:5001',
        pageUrl: Uri.parse('http://localhost:8080/'),
      ),
      'http://100.112.112.84:5001',
    );
  });

  test('relative web override resolves against the page', () {
    expect(
      resolveApiBaseUrl(
        isWeb: true,
        nativeDefaultUrl: 'http://localhost:5001',
        configuredUrl: '/api/',
        pageUrl: Uri.parse('http://100.112.112.84:8080/'),
      ),
      'http://100.112.112.84:8080/api/',
    );
  });

  test('native defaults and explicit native overrides remain supported', () {
    expect(
      resolveApiBaseUrl(
        isWeb: false,
        nativeDefaultUrl: 'http://localhost:5001',
      ),
      'http://localhost:5001',
    );
    expect(
      resolveApiBaseUrl(
        isWeb: false,
        nativeDefaultUrl: 'http://localhost:5001',
        configuredUrl: 'http://100.112.112.84:5001',
      ),
      'http://100.112.112.84:5001',
    );
  });
}
