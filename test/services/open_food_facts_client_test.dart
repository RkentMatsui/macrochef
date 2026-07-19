import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/food_db/open_food_facts_client.dart';

class _Dio implements Dio {
  _Dio(this.payload);
  final Map<String, dynamic> payload;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async => Response<T>(
    requestOptions: RequestOptions(path: path),
    data: payload as T,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'preserves OFF physical grams without making generic serving a piece',
    () async {
      final result = await OpenFoodFactsClient(
        dio: _Dio({
          'products': [
            {
              'product_name': 'Soup',
              'serving_size': '1 serving (85 g)',
              'nutriments': {
                'energy-kcal_100g': 100,
                'proteins_100g': 3,
                'carbohydrates_100g': 10,
                'fat_100g': 2,
              },
            },
          ],
        }),
      ).searchFood('soup');

      expect(result!.basisPhysicalGrams, 85);
      expect(result.gramsPerPiece, isNull);
    },
  );

  test('preserves OFF stick basis and its explicit grams', () async {
    final result = await OpenFoodFactsClient(
      dio: _Dio({
        'products': [
          {
            'product_name': 'Coffee stick',
            'serving_size': '1 stick (2 g)',
            'nutriments': {
              'energy-kcal_100g': 350,
              'proteins_100g': 0,
              'carbohydrates_100g': 70,
              'fat_100g': 7.5,
            },
          },
        ],
      }),
    ).searchFood('coffee stick');

    expect(result!.basis!.unit, 'stick');
    expect(result.basis!.quantity, 1);
    expect(result.basisPhysicalGrams, 2);
    expect(result.gramsPerPiece, 2);
  });
}
