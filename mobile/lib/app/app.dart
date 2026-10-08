import 'package:flutter/material.dart';

import '../core/security/profile_screen_security.dart';
import '../features/discovery/presentation/discovery_screen.dart';
import '../features/profile/data/profile_api.dart';
import '../l10n/app_localizations.dart';
import 'app_theme.dart';

class AnbuMatrimonyApp extends StatelessWidget {
  const AnbuMatrimonyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAppTheme(),
      home: const _MainNavigation(),
    );
  }
}

class _MainNavigation extends StatefulWidget {
  const _MainNavigation();

  @override
  State<_MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<_MainNavigation> {
  int _selectedIndex = 0;

  void _openProfile(String profileId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ProfileScreen(profileId: profileId, active: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DiscoveryScreen(onProfileTap: _openProfile),
          ShortlistScreen(onProfileTap: _openProfile),
          _ProfileScreen(active: _selectedIndex == 2),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.manage_search_outlined),
            selectedIcon: const Icon(Icons.manage_search_rounded),
            label: strings.discover,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bookmark_border_rounded),
            selectedIcon: const Icon(Icons.bookmark_rounded),
            label: strings.shortlist,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: strings.myProfile,
          ),
        ],
      ),
    );
  }
}

class _ProfileScreen extends StatefulWidget {
  const _ProfileScreen({this.profileId, this.active = false});

  final String? profileId;
  final bool active;

  @override
  State<_ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<_ProfileScreen> {
  late final ProfileApiClient _apiClient;
  late Future<Profile> _profile;
  bool? _shortlistOverride;
  bool _actionInProgress = false;

  bool get _isOtherProfile =>
      widget.profileId != null &&
      widget.profileId != const ProfileApiConfig.fromEnvironment().profileId;

  @override
  void initState() {
    super.initState();
    const baseConfig = ProfileApiConfig.fromEnvironment();
    _apiClient = ProfileApiClient(
      config: widget.profileId == null
          ? baseConfig
          : ProfileApiConfig(
              baseUrl: baseConfig.baseUrl,
              accessToken: baseConfig.accessToken,
              profileId: widget.profileId!,
            ),
    );
    _profile = _apiClient.fetchProfile();
  }

  @override
  void dispose() {
    _apiClient.close();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _profile = _apiClient.fetchProfile();
    });
  }

  Future<void> _toggleShortlist(bool isShortlisted) async {
    setState(() => _actionInProgress = true);
    try {
      if (isShortlisted) {
        await _apiClient.removeShortlist(widget.profileId!);
      } else {
        await _apiClient.addShortlist(widget.profileId!);
      }
      if (!mounted) return;
      setState(() {
        _shortlistOverride = !isShortlisted;
        _actionInProgress = false;
      });
      _showMessage(
        isShortlisted
            ? AppLocalizations.of(context)!.removedFromShortlist
            : AppLocalizations.of(context)!.addedToShortlist,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _actionInProgress = false);
      _showMessage(error.toString());
    }
  }

  Future<void> _expressInterest() async {
    final strings = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.expressInterest),
        content: Text(strings.interestConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.sendInterest),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _actionInProgress = true);
    try {
      await _apiClient.expressInterest(widget.profileId!);
      if (!mounted) return;
      setState(() => _actionInProgress = false);
      _showMessage(strings.interestSent);
    } catch (error) {
      if (!mounted) return;
      setState(() => _actionInProgress = false);
      _showMessage(error.toString());
    }
  }

  Future<void> _reportProfile() async {
    final strings = AppLocalizations.of(context)!;
    final detailsController = TextEditingController();
    var reason = 'fake_details';
    final report = await showDialog<({String reason, String details})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(strings.reportProfile),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: reason,
                decoration: InputDecoration(labelText: strings.reportReason),
                items: [
                  DropdownMenuItem(
                    value: 'fake_details',
                    child: Text(strings.reportFakeDetails),
                  ),
                  DropdownMenuItem(
                    value: 'inappropriate_content',
                    child: Text(strings.reportInappropriate),
                  ),
                  DropdownMenuItem(
                    value: 'already_married',
                    child: Text(strings.reportAlreadyMarried),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text(strings.other),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => reason = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                maxLines: 3,
                maxLength: 2000,
                decoration: InputDecoration(
                  labelText: strings.reportDetailsOptional,
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                (reason: reason, details: detailsController.text.trim()),
              ),
              child: Text(strings.submitReport),
            ),
          ],
        ),
      ),
    );
    detailsController.dispose();
    if (report == null || !mounted) return;

    setState(() => _actionInProgress = true);
    try {
      await _apiClient.reportProfile(
        profileId: widget.profileId!,
        reason: report.reason,
        details: report.details,
      );
      if (!mounted) return;
      setState(() => _actionInProgress = false);
      _showMessage(strings.reportSubmitted);
    } catch (error) {
      if (!mounted) return;
      setState(() => _actionInProgress = false);
      _showMessage(error.toString());
    }
  }

  Future<void> _blockProfile() async {
    final strings = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.blockProfile),
        content: Text(strings.blockConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.blockProfile),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _actionInProgress = true);
    try {
      await _apiClient.blockProfile(widget.profileId!);
      if (!mounted) return;
      Navigator.of(context).pop();
      _showMessage(strings.profileBlocked);
    } catch (error) {
      if (!mounted) return;
      setState(() => _actionInProgress = false);
      _showMessage(error.toString());
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return SecureProfileScreen(
      enabled: widget.active,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 24,
          title: Row(
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: AppColors.brand,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                strings.appName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          actions: [
            if (_isOtherProfile)
              PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'report') _reportProfile();
                  if (action == 'block') _blockProfile();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'report',
                    child: Text(strings.reportProfile),
                  ),
                  PopupMenuItem(
                    value: 'block',
                    child: Text(strings.blockProfile),
                  ),
                ],
              ),
            IconButton(
              tooltip: strings.retry,
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: FutureBuilder<Profile>(
          future: _profile,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _ProfileLoading();
            }
            if (snapshot.hasError) {
              final isConfigured =
                  const ProfileApiConfig.fromEnvironment().isConfigured;
              return _ProfileError(
                message: isConfigured
                    ? snapshot.error.toString()
                    : strings.profileNotConfigured,
                onRetry: _reload,
              );
            }

            return _ProfileContent(
              profile: snapshot.requireData,
              strings: strings,
            );
          },
        ),
        bottomNavigationBar: _isOtherProfile
            ? FutureBuilder<Profile>(
                future: _profile,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final isShortlisted =
                      _shortlistOverride ?? snapshot.requireData.shortlisted;
                  return SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _actionInProgress
                                  ? null
                                  : () => _toggleShortlist(isShortlisted),
                              icon: Icon(
                                isShortlisted
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                              ),
                              label: Text(
                                isShortlisted
                                    ? strings.shortlisted
                                    : strings.shortlist,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _actionInProgress
                                  ? null
                                  : _expressInterest,
                              icon: _actionInProgress
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.favorite_border_rounded),
                              label: Text(strings.expressInterest),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile, required this.strings});

  final Profile profile;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            _ProfileHero(profile: profile, tagline: strings.profileTagline),
            const SizedBox(height: 28),
            _SectionHeading(
              eyebrow: strings.profileDetailsEyebrow,
              title: strings.profileDetails,
            ),
            const SizedBox(height: 14),
            Card(
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: strings.location,
                    value: '${profile.city}, ${profile.state}',
                  ),
                  const Divider(indent: 20, endIndent: 20),
                  _InfoRow(
                    icon: Icons.person_outline_rounded,
                    label: strings.gender,
                    value: profile.gender,
                  ),
                  if (profile.caste != null) ...[
                    const Divider(indent: 20, endIndent: 20),
                    _InfoRow(
                      icon: Icons.diversity_1_outlined,
                      label: strings.caste,
                      value: profile.caste!,
                    ),
                  ],
                  if (profile.education != null) ...[
                    const Divider(indent: 20, endIndent: 20),
                    _InfoRow(
                      icon: Icons.school_outlined,
                      label: strings.education,
                      value: profile.education!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            _SectionHeading(
              eyebrow: strings.contactEyebrow,
              title: strings.contactDetails,
            ),
            const SizedBox(height: 14),
            if (profile.premiumLocked)
              _PremiumContactCard(message: strings.premiumRequired)
            else if (profile.contact != null)
              Card(
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: strings.phone,
                      value: profile.contact!.phone,
                    ),
                    if (profile.contact!.email != null) ...[
                      const Divider(indent: 20, endIndent: 20),
                      _InfoRow(
                        icon: Icons.mail_outline_rounded,
                        label: strings.email,
                        value: profile.contact!.email!,
                      ),
                    ],
                  ],
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    strings.contactUnavailable,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile, required this.tagline});

  final Profile profile;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = profile.displayName.trim();
    final initial = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.94, end: 1),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) => Opacity(
        opacity: scale.clamp(0, 1),
        child: Transform.scale(scale: scale, child: child),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.brand, AppColors.brandDeep],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.16),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -82,
              right: -36,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 32,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          tagline.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.accent,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.32),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                Icon(
                                  Icons.place_outlined,
                                  size: 16,
                                  color: Colors.white.withValues(alpha: 0.76),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${profile.city}, ${profile.state}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.78,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.accent,
                        size: 17,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          profile.gender,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.86),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 5),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
        ],
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.brand, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumContactCard extends StatelessWidget {
  const _PremiumContactCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
        color: const Color(0xFFFFFCF6),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EEDC),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      AppLocalizations.of(context)!.premiumUnlockHint,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.brandSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_off_outlined,
                        color: AppColors.brand,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(AppLocalizations.of(context)!.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _ProfileLoading extends StatefulWidget {
  const _ProfileLoading();

  @override
  State<_ProfileLoading> createState() => _ProfileLoadingState();
}

class _ProfileLoadingState extends State<_ProfileLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Opacity(
          opacity: 0.55 + (_controller.value * 0.35),
          child: child,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                _SkeletonBlock(height: 245, radius: 28),
                SizedBox(height: 30),
                _SkeletonBlock(height: 22, width: 180, radius: 8),
                SizedBox(height: 14),
                _SkeletonBlock(height: 220, radius: 24),
                SizedBox(height: 28),
                _SkeletonBlock(height: 22, width: 150, radius: 8),
                SizedBox(height: 14),
                _SkeletonBlock(height: 100, radius: 24),
              ],
            ),
          ),
        ),
      );
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.height,
    required this.radius,
    this.width,
  });

  final double height;
  final double radius;
  final double? width;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFECE6E1),
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      );
}
