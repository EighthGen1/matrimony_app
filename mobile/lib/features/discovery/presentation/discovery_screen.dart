import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/data/profile_api.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({required this.onProfileTap, super.key});

  final ValueChanged<String> onProfileTap;

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class ShortlistScreen extends StatefulWidget {
  const ShortlistScreen({required this.onProfileTap, super.key});

  final ValueChanged<String> onProfileTap;

  @override
  State<ShortlistScreen> createState() => _ShortlistScreenState();
}

class _ShortlistScreenState extends State<ShortlistScreen> {
  late final ProfileApiClient _apiClient;
  late Future<List<DiscoveryProfile>> _shortlists;

  @override
  void initState() {
    super.initState();
    _apiClient = ProfileApiClient(
      config: const ProfileApiConfig.fromEnvironment(),
    );
    _shortlists = const ProfileApiConfig.fromEnvironment().isConfigured
        ? _load()
        : Future.value(const <DiscoveryProfile>[]);
  }

  @override
  void dispose() {
    _apiClient.close();
    super.dispose();
  }

  Future<List<DiscoveryProfile>> _load() async =>
      (await _apiClient.fetchShortlists()).items;

  Future<void> _refresh() async {
    setState(() => _shortlists = _load());
    await _shortlists;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final configured = const ProfileApiConfig.fromEnvironment().isConfigured;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.shortlist, style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            tooltip: strings.retry,
            onPressed: configured ? _refresh : null,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: !configured
          ? _DiscoveryMessage(
              icon: Icons.bookmark_border_rounded,
              title: strings.shortlist,
              message: strings.discoveryNotConfigured,
            )
          : FutureBuilder<List<DiscoveryProfile>>(
              future: _shortlists,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _DiscoveryLoading();
                }
                if (snapshot.hasError) {
                  return _DiscoveryMessage(
                    icon: Icons.cloud_off_outlined,
                    title: strings.profilesCouldNotLoad,
                    message: snapshot.error.toString(),
                    actionLabel: strings.retry,
                    onAction: _refresh,
                  );
                }
                final profiles = snapshot.requireData;
                if (profiles.isEmpty) {
                  return _DiscoveryMessage(
                    icon: Icons.bookmark_border_rounded,
                    title: strings.shortlistEmptyTitle,
                    message: strings.shortlistEmpty,
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    itemCount: profiles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) => _DiscoveryProfileCard(
                      profile: profiles[index],
                      onTap: () => widget.onProfileTap(profiles[index].id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  late final ProfileApiClient _apiClient;
  final ScrollController _scrollController = ScrollController();
  DiscoveryFilters _filters = const DiscoveryFilters();
  List<DiscoveryProfile> _profiles = const [];
  int _total = 0;
  int _page = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _apiClient = ProfileApiClient(
      config: const ProfileApiConfig.fromEnvironment(),
    );
    _scrollController.addListener(_loadNextPageWhenNearEnd);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadNextPageWhenNearEnd)
      ..dispose();
    _apiClient.close();
    super.dispose();
  }

  Future<void> _loadFirstPage({DiscoveryFilters? filters}) async {
    if (filters != null) _filters = filters;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _error = null;
      _profiles = const [];
      _page = 0;
      _hasMore = false;
    });
    try {
      final result = await _apiClient.fetchDiscovery(
        page: 1,
        filters: _filters,
      );
      if (!mounted) return;
      setState(() {
        _profiles = result.items;
        _total = result.total;
        _page = result.page;
        _hasMore = result.hasMore;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final result = await _apiClient.fetchDiscovery(
        page: _page + 1,
        filters: _filters,
      );
      if (!mounted) return;
      setState(() {
        _profiles = [..._profiles, ...result.items];
        _total = result.total;
        _page = result.page;
        _hasMore = result.hasMore;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loadingMore = false;
      });
    }
  }

  void _loadNextPageWhenNearEnd() {
    if (_scrollController.position.extentAfter < 400) {
      _loadMore();
    }
  }

  Future<void> _openFilters() async {
    final filters = await showModalBottomSheet<DiscoveryFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _DiscoveryFilterSheet(filters: _filters),
    );
    if (filters != null) _loadFirstPage(filters: filters);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final configured = const ProfileApiConfig.fromEnvironment().isConfigured;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Row(
          children: [
            const Icon(Icons.favorite_rounded,
                color: AppColors.brand, size: 22),
            const SizedBox(width: 10),
            Text(strings.discover, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        actions: [
          IconButton(
            tooltip: strings.filters,
            onPressed: configured ? _openFilters : null,
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: !configured
          ? _DiscoveryMessage(
              icon: Icons.manage_search_rounded,
              title: strings.discoveryNotConfiguredTitle,
              message: strings.discoveryNotConfigured,
            )
          : _loading
              ? const _DiscoveryLoading()
              : _error != null && _profiles.isEmpty
                  ? _DiscoveryMessage(
                      icon: Icons.cloud_off_outlined,
                      title: strings.profilesCouldNotLoad,
                      message: _error.toString(),
                      actionLabel: strings.retry,
                      onAction: _loadFirstPage,
                    )
                  : _profiles.isEmpty
                      ? _DiscoveryMessage(
                          icon: Icons.search_off_rounded,
                          title: strings.noProfilesFound,
                          message: strings.tryDifferentFilters,
                          actionLabel: strings.filters,
                          onAction: _openFilters,
                        )
                      : RefreshIndicator(
                          onRefresh: _loadFirstPage,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 10, 20, 16),
                                sliver: SliverToBoxAdapter(
                                  child: _DiscoveryHeader(
                                    count: _total,
                                    subtitle: strings.discoverSubtitle,
                                    countLabel: strings.profilesAvailable,
                                  ),
                                ),
                              ),
                              SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 28),
                                sliver: SliverList.separated(
                                  itemCount: _profiles.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 14),
                                  itemBuilder: (context, index) =>
                                      _DiscoveryProfileCard(
                                    profile: _profiles[index],
                                    onTap: () => widget
                                      .onProfileTap(_profiles[index].id),
                                  ),
                                ),
                              ),
                              if (_loadingMore)
                                const SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                )
                              else if (_hasMore)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 0, 20, 24),
                                    child: OutlinedButton(
                                      onPressed: _loadMore,
                                      child: Text(strings.loadMoreProfiles),
                                    ),
                                  ),
                                )
                              else if (_error != null)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: TextButton.icon(
                                      onPressed: _loadMore,
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: Text(strings.retry),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
    );
  }
}

class _DiscoveryHeader extends StatelessWidget {
  const _DiscoveryHeader({
    required this.count,
    required this.subtitle,
    required this.countLabel,
  });

  final int count;
  final String subtitle;
  final String countLabel;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.brandSoft,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.brandDeep,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$count $countLabel',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.diversity_3_rounded,
              color: AppColors.brand,
              size: 36,
            ),
          ],
        ),
      );
}

class _DiscoveryProfileCard extends StatelessWidget {
  const _DiscoveryProfileCard({required this.profile, required this.onTap});

  final DiscoveryProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      profile.displayName.substring(0, 1).toUpperCase(),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.brand,
                              ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                profile.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (profile.verified) ...[
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.verified_rounded,
                                color: AppColors.success,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${profile.age} · ${profile.gender}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${profile.city}, ${profile.state}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              if (profile.education != null || profile.occupation != null) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (profile.education != null)
                      _ProfileTag(
                        icon: Icons.school_outlined,
                        text: profile.education!,
                      ),
                    if (profile.occupation != null)
                      _ProfileTag(
                        icon: Icons.work_outline_rounded,
                        text: profile.occupation!,
                      ),
                  ],
                ),
              ],
              if (profile.bio != null) ...[
                const SizedBox(height: 14),
                Text(
                  profile.bio!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  strings.viewProfile,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.brand,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTag extends StatelessWidget {
  const _ProfileTag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F5F2),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.muted),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 190),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      );
}

class _DiscoveryMessage extends StatelessWidget {
  const _DiscoveryMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.brand, size: 46),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 9),
                Text(message, textAlign: TextAlign.center),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

class _DiscoveryLoading extends StatelessWidget {
  const _DiscoveryLoading();

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) => const Card(
          child: SizedBox(height: 148),
        ),
      );
}

class _DiscoveryFilterSheet extends StatefulWidget {
  const _DiscoveryFilterSheet({required this.filters});

  final DiscoveryFilters filters;

  @override
  State<_DiscoveryFilterSheet> createState() => _DiscoveryFilterSheetState();
}

class _DiscoveryFilterSheetState extends State<_DiscoveryFilterSheet> {
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _educationController;
  late final TextEditingController _minAgeController;
  late final TextEditingController _maxAgeController;
  String? _gender;
  bool? _verified;

  @override
  void initState() {
    super.initState();
    final filters = widget.filters;
    _cityController = TextEditingController(text: filters.city);
    _stateController = TextEditingController(text: filters.state);
    _educationController = TextEditingController(text: filters.education);
    _minAgeController =
        TextEditingController(text: filters.minAge?.toString());
    _maxAgeController =
        TextEditingController(text: filters.maxAge?.toString());
    _gender = filters.gender;
    _verified = filters.verified;
  }

  @override
  void dispose() {
    _cityController.dispose();
    _stateController.dispose();
    _educationController.dispose();
    _minAgeController.dispose();
    _maxAgeController.dispose();
    super.dispose();
  }

  int? _age(TextEditingController controller) =>
      int.tryParse(controller.text.trim());

  void _apply() {
    final minAge = _age(_minAgeController);
    final maxAge = _age(_maxAgeController);
    if ((minAge != null && (minAge < 18 || minAge > 100)) ||
        (maxAge != null && (maxAge < 18 || maxAge > 100)) ||
        (minAge != null && maxAge != null && minAge > maxAge)) {
      return;
    }
    Navigator.of(context).pop(
      DiscoveryFilters(
        gender: _gender,
        minAge: minAge,
        maxAge: maxAge,
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        education: _educationController.text.trim(),
        verified: _verified,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.filters, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: InputDecoration(labelText: strings.gender),
              items: [
                DropdownMenuItem(value: null, child: Text(strings.any)),
                DropdownMenuItem(value: 'female', child: Text(strings.women)),
                DropdownMenuItem(value: 'male', child: Text(strings.men)),
                DropdownMenuItem(value: 'other', child: Text(strings.other)),
              ],
              onChanged: (value) => setState(() => _gender = value),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minAgeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: strings.minimumAge),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxAgeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: strings.maximumAge),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cityController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: strings.city),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stateController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: strings.state),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _educationController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: strings.education),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.verifiedOnly),
              value: _verified ?? false,
              onChanged: (value) =>
                  setState(() => _verified = value ? true : null),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context)
                        .pop(const DiscoveryFilters()),
                    child: Text(strings.clearAll),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _apply,
                    child: Text(strings.applyFilters),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
