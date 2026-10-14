import 'package:flutter_test/flutter_test.dart';
import 'package:milan_app/core/constants.dart';
import 'package:milan_app/data/discover_repository.dart';

void main() {
  group('DiscoverFilters', () {
    test('defaults to the full age range with no other constraints', () {
      const DiscoverFilters filters = DiscoverFilters();

      expect(filters.minAge, kFilterMinAge);
      expect(filters.maxAge, kFilterMaxAge);
      expect(filters.gender, isNull);
      expect(filters.city, isNull);
      expect(filters.interests, isEmpty);
      expect(filters.activeCount, 0);
    });

    test('sends p_-prefixed named parameters expected by the RPC', () {
      const DiscoverFilters filters = DiscoverFilters(
        minAge: 25,
        maxAge: 35,
        gender: 'female',
        city: ' Pokhara ',
        interests: <String>['Music'],
      );

      final Map<String, dynamic> params = filters.toRpcParams(
        limit: 20,
        offset: 40,
      );

      expect(params['p_min_age'], 25);
      expect(params['p_max_age'], 35);
      expect(params['p_gender'], 'female');
      expect(params['p_city'], 'Pokhara'); // trimmed
      expect(params['p_interests'], <String>['Music']);
      expect(params['p_limit'], 20);
      expect(params['p_offset'], 40);
    });

    test('sends null for untouched optional filters', () {
      final Map<String, dynamic> params = const DiscoverFilters().toRpcParams(
        limit: 10,
        offset: 0,
      );

      expect(params['p_gender'], isNull);
      expect(params['p_city'], isNull);
      expect(params['p_interests'], isNull);
    });

    test('counts each active constraint once', () {
      expect(const DiscoverFilters(minAge: 30).activeCount, 1);
      expect(const DiscoverFilters(maxAge: 40).activeCount, 1);
      expect(const DiscoverFilters(gender: 'male').activeCount, 1);
      expect(const DiscoverFilters(city: 'Lalitpur').activeCount, 1);
      expect(
        const DiscoverFilters(interests: <String>['Music', 'Art']).activeCount,
        1,
      );
      expect(const DiscoverFilters(city: '   ').activeCount, 0);
      expect(
        const DiscoverFilters(
          minAge: 22,
          gender: 'female',
          city: 'Butwal',
          interests: <String>['Yoga'],
        ).activeCount,
        4,
      );
    });

    test('copyWith replaces only the provided fields', () {
      const DiscoverFilters base = DiscoverFilters(minAge: 20, maxAge: 30);

      final DiscoverFilters updated = base.copyWith(gender: 'other');

      expect(updated.minAge, 20);
      expect(updated.maxAge, 30);
      expect(updated.gender, 'other');
    });
  });
}
