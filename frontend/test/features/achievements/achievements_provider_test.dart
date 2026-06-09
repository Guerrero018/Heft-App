import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/features/achievements/data/achievements_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    mockDio = MockDio();
    final achievementPayload = {
      'achievements': [
        {
          'id': 'first_workout',
          'title': 'Primer entreno',
          'subtitle': '',
          'description': 'Completa tu primer entreno',
          'category': 'special',
          'icon_key': 'emoji_events',
          'is_unlocked': true,
          'progress': 1,
        },
      ],
      'unlocked_count': 1,
      'total_count': 1,
    };
    when(() => mockDio.get('achievements/')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'achievements/'),
        data: achievementPayload,
      ),
    );
    when(() => mockDio.post('achievements/')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'achievements/'),
        data: {
          ...achievementPayload,
          'newly_unlocked': <String>[],
        },
      ),
    );

    container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(mockDio)],
    );
  });

  tearDown(() => container.dispose());

  test('load fetches achievements', () async {
    await container.read(achievementsProvider.notifier).load(force: true);
    final state = container.read(achievementsProvider);
    expect(state.achievements, isNotEmpty);
    expect(state.achievements.first.id, 'first_workout');
  });

  test('sync merges pending celebrations', () async {
    await container.read(achievementsProvider.notifier).load(force: true);
    await container.read(achievementsProvider.notifier).sync(
          unlockedBaseline: {},
        );

    final state = container.read(achievementsProvider);
    expect(state.error, isNull);
    expect(state.achievements.first.isUnlocked, true);
  });
}
