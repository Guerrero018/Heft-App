import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/core/offline/connectivity_provider.dart';
import 'package:frontend/core/offline/offline_storage_service.dart';
import 'package:frontend/core/offline/offline_sync_provider.dart';
import 'package:frontend/features/achievements/data/achievements_provider.dart';
import 'package:frontend/features/achievements/domain/achievement_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDio extends Mock implements Dio {}

class OfflineConnectivity extends ConnectivityNotifier {
  @override
  ConnectivityState build() =>
      const ConnectivityState(hasNetworkInterface: false, isOnline: false);
}

class OnlineConnectivity extends ConnectivityNotifier {
  @override
  ConnectivityState build() =>
      const ConnectivityState(hasNetworkInterface: true, isOnline: true);
}

void main() {
  late MockDio mockDio;
  late OfflineStorageService storage;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = OfflineStorageService(prefs);

    mockDio = MockDio();
    when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'workouts/'),
        statusCode: 201,
        data: {'id': 1},
      ),
    );
    when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
        .thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: [],
      ),
    );

    container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(mockDio),
        connectivityProvider.overrideWith(OfflineConnectivity.new),
        offlineStorageServiceProvider.overrideWith((ref) async => storage),
        achievementsProvider.overrideWith(_EmptyAchievementsNotifier.new),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('enqueueWorkout stores pending item', () async {
    final notifier = container.read(offlineSyncProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    final ok = await notifier.enqueueWorkout({
      'name': 'Offline push',
      'sets': [],
    });

    expect(ok, true);
    expect(container.read(offlineSyncProvider).pendingCount, 1);
    expect(storage.readPendingWorkouts().first.displayName, 'Offline push');
  });

  test('syncPendingWorkouts uploads queued workout when online', () async {
    container.dispose();
    container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(mockDio),
        connectivityProvider.overrideWith(OnlineConnectivity.new),
        offlineStorageServiceProvider.overrideWith((ref) async => storage),
        achievementsProvider.overrideWith(_EmptyAchievementsNotifier.new),
      ],
    );

    final notifier = container.read(offlineSyncProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    await notifier.enqueueWorkout({'name': 'Queued', 'sets': []});
    expect(container.read(offlineSyncProvider).pendingCount, 1);

    await notifier.syncPendingWorkouts();

    expect(container.read(offlineSyncProvider).pendingCount, 0);
    verify(() => mockDio.post('workouts/', data: any(named: 'data'))).called(1);
  });
}

class _EmptyAchievementsNotifier extends AchievementsNotifier {
  @override
  AchievementsState build() => const AchievementsState();

  @override
  Future<void> sync({Set<String>? unlockedBaseline}) async {}
}
