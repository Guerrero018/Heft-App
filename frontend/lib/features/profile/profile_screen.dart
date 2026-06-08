import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import '../body_progress/data/body_progress_provider.dart';
import '../achievements/data/achievements_provider.dart';
import 'data/privacy_preferences_provider.dart';
import 'edit_profile_screen.dart';
import 'widgets/profile_body_progress_section.dart';
import 'widgets/profile_settings_menu.dart';
import '../achievements/presentation/widgets/achievements_vitrine_section.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(bodyProgressProvider.notifier).loadAll(force: true);
      await ref.read(achievementsProvider.notifier).refresh(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final privacy = ref.watch(privacyPreferencesProvider).prefs;

    if (user == null && authState.isInitializing) {
      return const Scaffold(
        backgroundColor: AppTheme.surfaceColor,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: _ProfileScrollBehavior(),
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 8, top: 4),
                        child: ProfileSettingsMenu(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ProfileHeader(
                      user: user,
                      showEmail: privacy.showEmailOnProfile,
                    ),
                    if (privacy.showStatsOnProfile) ...[
                      const SizedBox(height: 24),
                      _StatsRow(user: user),
                    ] else
                      const SizedBox(height: 24),
                    const SizedBox(height: 28),
                    const AchievementsVitrineSection(),
                    const SizedBox(height: 28),
                    const ProfileBodyProgressSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Evita la franja amarilla del glow/overscroll del Material al tirar del scroll.
class _ProfileScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic>? user;
  final bool showEmail;

  const _ProfileHeader({
    required this.user,
    this.showEmail = true,
  });

  @override
  Widget build(BuildContext context) {
    final picture = user?['profile_picture']?.toString();
    final hasPicture = picture != null && picture.isNotEmpty;

    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 56,
                backgroundColor: AppTheme.cardColor,
                backgroundImage: hasPicture
                    ? CachedNetworkImageProvider(picture)
                    : const CachedNetworkImageProvider(
                        'https://res.cloudinary.com/dcmhsvy2l/image/upload/v1776343470/DefaultProfile.png',
                      ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.black, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user?['username'] ?? 'Usuario',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (showEmail)
          Text(
            user?['email'] ?? '',
            style: const TextStyle(color: AppTheme.hintColor, fontSize: 13),
          ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic>? user;

  const _StatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _StatChip(
              label: 'Peso',
              value: user?['weight'] != null
                  ? '${double.parse(user!['weight'].toString()).toStringAsFixed(1)} kg'
                  : '-- kg',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatChip(
              label: 'Altura',
              value: user?['height'] != null
                  ? '${double.parse(user!['height'].toString()).toInt()} cm'
                  : '-- cm',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.hintColor, fontSize: 12)),
        ],
      ),
    );
  }
}

