import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyShowEmail = 'privacy_show_email_on_profile';
const _keyShowStats = 'privacy_show_stats_on_profile';

class PrivacyPreferences {
  final bool showEmailOnProfile;
  final bool showStatsOnProfile;

  const PrivacyPreferences({
    this.showEmailOnProfile = true,
    this.showStatsOnProfile = true,
  });

  PrivacyPreferences copyWith({
    bool? showEmailOnProfile,
    bool? showStatsOnProfile,
  }) {
    return PrivacyPreferences(
      showEmailOnProfile: showEmailOnProfile ?? this.showEmailOnProfile,
      showStatsOnProfile: showStatsOnProfile ?? this.showStatsOnProfile,
    );
  }
}

class PrivacyPreferencesState {
  final PrivacyPreferences prefs;
  final bool isLoading;

  const PrivacyPreferencesState({
    required this.prefs,
    this.isLoading = false,
  });

  PrivacyPreferencesState copyWith({
    PrivacyPreferences? prefs,
    bool? isLoading,
  }) {
    return PrivacyPreferencesState(
      prefs: prefs ?? this.prefs,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PrivacyPreferencesNotifier extends Notifier<PrivacyPreferencesState> {
  @override
  PrivacyPreferencesState build() {
    Future.microtask(load);
    return const PrivacyPreferencesState(
      prefs: PrivacyPreferences(),
      isLoading: true,
    );
  }

  Future<void> load() async {
    final storage = await SharedPreferences.getInstance();
    state = PrivacyPreferencesState(
      prefs: PrivacyPreferences(
        showEmailOnProfile: storage.getBool(_keyShowEmail) ?? true,
        showStatsOnProfile: storage.getBool(_keyShowStats) ?? true,
      ),
    );
  }

  Future<void> update(PrivacyPreferences updated) async {
    state = state.copyWith(prefs: updated);
    final storage = await SharedPreferences.getInstance();
    await storage.setBool(_keyShowEmail, updated.showEmailOnProfile);
    await storage.setBool(_keyShowStats, updated.showStatsOnProfile);
  }
}

final privacyPreferencesProvider =
    NotifierProvider<PrivacyPreferencesNotifier, PrivacyPreferencesState>(
  PrivacyPreferencesNotifier.new,
);
