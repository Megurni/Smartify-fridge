import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartify_refrigerator_demo/repositories/food_illustrations.dart';
import 'package:smartify_refrigerator_demo/repositories/food_repository.dart';

void main() {
  test(
    'all categories have fallbacks and exact matching rejects misleading results',
    () {
      expect(categoryIllustrations.length, 11);
      expect(categoryIllustration('Dairy'), 'glass-of-milk');
      expect(categoryIllustration('unknown'), 'fork-and-knife-with-plate');
      expect(illustrationName(' Eggs '), 'egg');
      expect(selectIllustration('egg', ['fluent-emoji-flat:eggplant']), isNull);
      expect(
        selectIllustration('egg', ['fluent-emoji-flat:egg']),
        'fluent-emoji-flat:egg',
      );
    },
  );
  test(
    'API results are restricted to collection and cached across instances',
    () async {
      SharedPreferences.setMockInitialValues({});
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        if (request.url.path == '/search') {
          expect(request.url.queryParameters['prefix'], 'fluent-emoji-flat');
          return http.Response('{"icons":["fluent-emoji-flat:avocado"]}', 200);
        }
        return http.Response('<svg xmlns="http://www.w3.org/2000/svg"/>', 200);
      });
      expect(
        await FoodIllustrations(client: client).find('avocado'),
        contains('<svg'),
      );
      expect(
        await FoodIllustrations(client: client).find('avocado'),
        contains('<svg'),
      );
      expect(requests, 2);
    },
  );
  test(
    'backend photo URL preserves the api proxy prefix and ignores filesystem paths',
    () async {
      var includeUrl = true;
      final repository = HttpFoodRepository(
        baseUrl: 'http://localhost:8080/api/',
        client: MockClient(
          (request) async => http.Response(
            '{"id":1,"name":"Milk","stored_at":"2026-11-20T10:00:00","category":"Dairy","image":"/private/photo.jpg"${includeUrl ? ',"image_url":"capture/7/image"' : ''}}',
            200,
          ),
        ),
      );
      expect(
        (await repository.getFood('1'))!.image,
        'http://localhost:8080/api/capture/7/image',
      );
      includeUrl = false;
      expect((await repository.getFood('1'))!.image, isEmpty);
    },
  );
}
