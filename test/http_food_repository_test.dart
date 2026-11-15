import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartify_refrigerator_demo/models/food_item.dart';
import 'package:smartify_refrigerator_demo/repositories/food_repository.dart';

void main() {
  test('inventory reads, removes, and restores through Flask', () async {
    final requests = <http.Request>[];
    var removed = false;
    Map<String, Object?>? event;
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'POST') {
        if (request.url.path == '/item/7/remove') {
          expect(jsonDecode(request.body), {
            'outcome': 'consumed',
            'use_first': true,
          });
          removed = true;
          event = {
            'id': 1,
            'item_id': 7,
            'name': 'Milk',
            'category': 'Dairy',
            'stored_at': '2026-10-20T10:00:00',
            'price': 3.5,
            'outcome': 'consumed',
            'use_first': true,
            'occurred_at': '2026-10-21T10:00:00+00:00',
          };
        } else if (request.url.path == '/item/7/restore') {
          expect(request.body, '{}');
          removed = false;
          event = null;
        } else {
          fail('Unexpected backend write: ${request.url}');
        }
        return http.Response('{}', 200);
      }
      expect(request.method, 'GET');
      if (request.url.path == '/accounting/events') {
        return http.Response(
          jsonEncode({
            'events': event == null ? [] : [event],
          }),
          200,
        );
      }
      expect(request.url.path, '/items');
      expect(request.url.query, isEmpty);
      return http.Response(
        jsonEncode({
          'items': removed
              ? <Map<String, Object?>>[]
              : [
                  {
                    'id': 7,
                    'name': 'Milk',
                    'stored_at': '2026-10-20T10:00:00',
                    'status': 'expiring_soon',
                    'price': 3.5,
                    'category': 'Dairy',
                    'expires_at': '2026-10-21T10:00:00',
                    'shelf_id': 1,
                    'image': '',
                    'confidence': null,
                    'last_seen': null,
                    'removed_at': null,
                  },
                ],
        }),
        200,
      );
    });
    final repository = HttpFoodRepository(
      baseUrl: 'http://localhost:5000',
      client: client,
    );

    final food = (await repository.getFoods()).single;
    expect(food.freshnessStatus, FreshnessStatus.expiringSoon);
    await repository.updateFood(
      food.copyWith(status: FoodStatus.consumed, savedAmount: 3.5),
    );
    final reloadedRepository = HttpFoodRepository(
      baseUrl: 'http://localhost:5000',
      client: client,
    );
    expect(
      (await reloadedRepository.getFoods()).single.status,
      FoodStatus.consumed,
    );
    expect((await reloadedRepository.getFoods()).single.savedAmount, 3.5);
    await repository.updateFood(food);
    expect((await repository.getFoods()).single.status, FoodStatus.inStock);
    expect(
      requests
          .where((request) => request.method == 'POST')
          .map((r) => r.url.path),
      ['/item/7/remove', '/item/7/restore'],
    );
  });
}
