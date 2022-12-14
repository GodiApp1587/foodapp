import 'package:openfoodfacts/model/State.dart';
import 'package:openfoodfacts/model/parameter/StatesTagsParameter.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:openfoodfacts/utils/CountryHelper.dart';
import 'package:openfoodfacts/utils/OpenFoodAPIConfiguration.dart';
import 'package:openfoodfacts/utils/QueryType.dart';
import 'package:test/test.dart';

import 'test_constants.dart';

/// Integration tests related to the "to-be-completed" products
void main() {
  OpenFoodAPIConfiguration.globalUser = TestConstants.PROD_USER;
  OpenFoodAPIConfiguration.globalQueryType = QueryType.PROD;

  group('$OpenFoodAPIClient get all to-be-completed products', () {
    Future<int> _getCount(
      final OpenFoodFactsCountry country,
      final OpenFoodFactsLanguage language,
    ) async {
      final String reason = '($country, $language)';
      final ProductSearchQueryConfiguration configuration =
          ProductSearchQueryConfiguration(
        country: country,
        language: language,
        fields: [
          ProductField.BARCODE,
          ProductField.STATES_TAGS,
        ],
        parametersList: [
          StatesTagsParameter(map: {State.COMPLETED: false}),
        ],
      );

      final SearchResult result;
      try {
        result = await OpenFoodAPIClient.searchProducts(
          OpenFoodAPIConfiguration.globalUser,
          configuration,
          queryType: OpenFoodAPIConfiguration.globalQueryType,
        );
      } catch (e) {
        fail('Could not retrieve data for $reason: $e');
      }
      expect(result.page, 1, reason: reason); // default
      expect(result.products, isNotNull, reason: reason);
      for (final Product product in result.products!) {
        expect(product.statesTags, isNotNull);
        expect(product.statesTags!, contains('en:to-be-completed'));
      }
      return result.count!;
    }

    Future<int> _getCountForAllLanguages(
      final OpenFoodFactsCountry country,
    ) async {
      final List<OpenFoodFactsLanguage> languages = <OpenFoodFactsLanguage>[
        OpenFoodFactsLanguage.ENGLISH,
        OpenFoodFactsLanguage.FRENCH,
        OpenFoodFactsLanguage.ITALIAN,
      ];
      int? result;
      for (final OpenFoodFactsLanguage language in languages) {
        final int count = await _getCount(country, language);
        if (result != null) {
          expect(count, result, reason: language.toString());
        }
        result = count;
      }
      return result!;
    }

    Future<void> _checkTypeCount(
      final OpenFoodFactsCountry country,
      final int minimalExpectedCount,
    ) async {
      final int count = await _getCountForAllLanguages(country);
      expect(count, greaterThanOrEqualTo(minimalExpectedCount));
    }

    test(
        'in France',
        () async => _checkTypeCount(
            OpenFoodFactsCountry.FRANCE, 800000) // 20220706: was 910148
        );

    test(
        'in Italy',
        () async => _checkTypeCount(
            OpenFoodFactsCountry.ITALY, 100000) // 20220706: was 171488
        );

    test(
        'in Spain',
        () async => _checkTypeCount(
            OpenFoodFactsCountry.SPAIN, 200000) // 20220706: was 272194
        );
  });
}
