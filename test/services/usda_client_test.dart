import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/food_db/usda_client.dart';

/// Minimal Dio fake: returns a canned payload from get(), throws for anything
/// else.
class _FakeDio implements Dio {
  final Map<String, dynamic> payload;
  _FakeDio(this.payload);

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: payload as T,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('skips incomplete result and prefers KCAL energy over kJ', () async {
    final payload = {
      'foods': [
        // First result is missing fat → must be skipped.
        {
          'foodNutrients': [
            {'nutrientName': 'Energy', 'unitName': 'KCAL', 'value': 100},
            {'nutrientName': 'Protein', 'unitName': 'G', 'value': 20},
            {
              'nutrientName': 'Carbohydrate, by difference',
              'unitName': 'G',
              'value': 0
            },
          ],
        },
        // Second result is complete; energy listed in both kJ and KCAL.
        {
          'foodNutrients': [
            {'nutrientName': 'Energy', 'unitName': 'kJ', 'value': 690},
            {'nutrientName': 'Energy', 'unitName': 'KCAL', 'value': 165},
            {'nutrientName': 'Protein', 'unitName': 'G', 'value': 31},
            {
              'nutrientName': 'Carbohydrate, by difference',
              'unitName': 'G',
              'value': 0
            },
            {'nutrientName': 'Total lipid (fat)', 'unitName': 'G', 'value': 3.6},
          ],
        },
      ],
    };

    final client = UsdaClient(apiKey: 'fake', dio: _FakeDio(payload));
    final per = await client.search('chicken breast');
    expect(per, isNotNull);
    expect(per!.kcal, 165); // KCAL, not the kJ 690
    expect(per.protein, 31);
    expect(per.carb, 0);
    expect(per.fat, closeTo(3.6, 0.001));
  });

  test('returns null when no result has all four nutrients', () async {
    final payload = {
      'foods': [
        {
          'foodNutrients': [
            {'nutrientName': 'Energy', 'unitName': 'KCAL', 'value': 100},
            {'nutrientName': 'Protein', 'unitName': 'G', 'value': 20},
          ],
        },
      ],
    };
    final client = UsdaClient(apiKey: 'fake', dio: _FakeDio(payload));
    expect(await client.search('mystery'), isNull);
  });

  test('parses Fiber, total dietary into fibre field', () async {
    final payload = {
      'foods': [
        {
          'foodNutrients': [
            {'nutrientName': 'Energy', 'unitName': 'KCAL', 'value': 370},
            {'nutrientName': 'Protein', 'unitName': 'G', 'value': 13},
            {
              'nutrientName': 'Carbohydrate, by difference',
              'unitName': 'G',
              'value': 66
            },
            {
              'nutrientName': 'Total lipid (fat)',
              'unitName': 'G',
              'value': 7
            },
            {
              'nutrientName': 'Fiber, total dietary',
              'unitName': 'G',
              'value': 10.6
            },
          ],
        },
      ],
    };
    final client = UsdaClient(apiKey: 'fake', dio: _FakeDio(payload));
    final per = await client.search('oats');
    expect(per, isNotNull);
    expect(per!.fibre, closeTo(10.6, 0.001));
  });

  test('returns non-null PerHundred with fibre null when no fiber nutrient',
      () async {
    final payload = {
      'foods': [
        {
          'foodNutrients': [
            {'nutrientName': 'Energy', 'unitName': 'KCAL', 'value': 165},
            {'nutrientName': 'Protein', 'unitName': 'G', 'value': 31},
            {
              'nutrientName': 'Carbohydrate, by difference',
              'unitName': 'G',
              'value': 0
            },
            {
              'nutrientName': 'Total lipid (fat)',
              'unitName': 'G',
              'value': 3.6
            },
          ],
        },
      ],
    };
    final client = UsdaClient(apiKey: 'fake', dio: _FakeDio(payload));
    final per = await client.search('chicken');
    expect(per, isNotNull);
    expect(per!.fibre, isNull);
  });
}
