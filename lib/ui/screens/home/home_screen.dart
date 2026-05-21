import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/contract_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/contract_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/payment_provider.dart';
import '../../../util/helpers/currency_helper.dart';
import '../../../util/helpers/date_helper.dart';
import '../../components/contract_tile.dart';
import '../../components/empty_state.dart';
import '../../components/glass_card.dart';
import '../../components/section_header.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAll());
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      ref.read(contractProvider.notifier).loadContracts(),
      ref.read(contractProvider.notifier).loadStats(),
      ref.read(paymentProvider.notifier).loadSummary(),
      ref.read(notificationsProvider.notifier).load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final contractState = ref.watch(contractProvider);
    final paySummary = ref.watch(paymentProvider).summary;
    final unreadCount = ref.watch(notificationsProvider).unreadCount;

    final stats = contractState.stats;
    final contracts = contractState.contracts;
    final expiringSoon = contracts
        .where((c) => c.status == ContractStatus.expiringSoon)
        .take(8)
        .toList();
    final recent = contracts.take(5).toList();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refreshAll,
        color: AppColors.brandAccent,
        backgroundColor: AppColors.brandSurface,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateHelper.greetingForHour(),
                          style: AppTextStyles.bodySecondary,
                        ),
                        const Gap(2),
                        Text(
                          user?.displayName ?? 'there',
                          style: AppTextStyles.headingLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _NotificationsButton(unreadCount: unreadCount),
                  const Gap(AppSpacing.sm),
                  GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: _Avatar(photoUrl: user?.photoUrl, initials: user?.initials ?? '?'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.description_rounded,
                      label: 'Contracts',
                      value: stats.total.toString(),
                      tint: AppColors.brandAccent,
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.bolt_rounded,
                      label: 'Active',
                      value: stats.active.toString(),
                      tint: AppColors.success,
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.payments_rounded,
                      label: 'Pending',
                      value: CurrencyHelper.compact(
                        paySummary.totalPending,
                        contracts.isEmpty ? 'USD' : contracts.first.currency,
                      ),
                      tint: AppColors.brandGold,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      label: 'Create Contract',
                      icon: Icons.add_rounded,
                      onTap: () => context.go('/contracts/create'),
                      isAccent: true,
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: _QuickAction(
                      label: 'Upload & Analyze',
                      icon: Icons.upload_file_rounded,
                      onTap: () => context.go('/contracts/upload'),
                      isAccent: false,
                    ),
                  ),
                ],
              ),
            ),
            if (expiringSoon.isNotEmpty) ...[
              const SectionHeader(title: 'Expiring Soon'),
              SizedBox(
                height: 132,
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  scrollDirection: Axis.horizontal,
                  itemCount: expiringSoon.length,
                  separatorBuilder: (_, __) => const Gap(AppSpacing.md),
                  itemBuilder: (_, i) {
                    final c = expiringSoon[i];
                    return SizedBox(
                      width: 240,
                      child: GlassCard(
                        onTap: () => context.go('/contracts/${c.id}'),
                        borderColor: AppColors.warning.withValues(alpha: 0.5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(c.title,
                                style: AppTextStyles.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(c.clientName,
                                style: AppTextStyles.bodySecondary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Row(
                              children: [
                                const Icon(Icons.schedule,
                                    size: 14, color: AppColors.warning),
                                const Gap(4),
                                Text(
                                  c.endDate != null
                                      ? DateHelper.daysRemainingLabel(
                                          c.endDate!)
                                      : 'No end date',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            SectionHeader(
              title: 'Recent Contracts',
              actionLabel: contracts.isNotEmpty ? 'See all' : null,
              onActionTap:
                  contracts.isNotEmpty ? () => context.go('/contracts') : null,
            ),
            if (recent.isEmpty && !contractState.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                child: EmptyState(
                  icon: Icons.description_outlined,
                  title: 'No contracts yet',
                  message:
                      'Generate a professional contract or upload an existing one to get started.',
                  actionLabel: 'Create Contract',
                  onActionTap: () => context.go('/contracts/create'),
                ),
              )
            else
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    for (final c in recent) ...[
                      ContractTile(
                        contract: c,
                        onTap: () => context.go('/contracts/${c.id}'),
                      ),
                      const Gap(AppSpacing.md),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsButton extends StatelessWidget {
  final int unreadCount;
  const _NotificationsButton({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          onPressed: () => context.go('/notifications'),
          icon: const Icon(Icons.notifications_outlined,
              color: AppColors.textPrimary),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.brandAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(minWidth: 16),
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  const _Avatar({required this.photoUrl, required this.initials});

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.brandAccent,
      child: Text(
        initials,
        style: AppTextStyles.subtitle.copyWith(color: Colors.white),
      ),
    );
    if (photoUrl == null || photoUrl!.isEmpty) return fallback;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: photoUrl!,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => fallback,
        placeholder: (_, __) => fallback,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: tint, size: 18),
          ),
          const Gap(AppSpacing.md),
          Text(value, style: AppTextStyles.title),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isAccent;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isAccent,
  });

  @override
  Widget build(BuildContext context) {
    if (isAccent) {
      return InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.brandAccent, AppColors.brandAccentSoft],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandAccent.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const Gap(AppSpacing.md),
              Text(
                label,
                style: AppTextStyles.subtitle.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.brandAccent, size: 22),
          const Gap(AppSpacing.md),
          Text(label, style: AppTextStyles.subtitle),
        ],
      ),
    );
  }
}
