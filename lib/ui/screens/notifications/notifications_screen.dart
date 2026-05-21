import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/auth_token_model.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../util/helpers/date_helper.dart';
import '../../components/empty_state.dart';
import '../../components/glass_card.dart';
import '../../components/loading_overlay.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(notificationsProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/home'),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary),
                  ),
                  const Gap(AppSpacing.xs),
                  Text('Notifications', style: AppTextStyles.heading),
                  const Spacer(),
                  if (state.items.any((n) => !state.isRead(n)))
                    TextButton(
                      onPressed: () => ref
                          .read(notificationsProvider.notifier)
                          .markAllRead(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.brandAccent,
                      ),
                      child: const Text('Mark all read'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: state.isLoading && state.items.isEmpty
                  ? const LoadingOverlay()
                  : state.items.isEmpty
                      ? EmptyState(
                          icon: Icons.notifications_off_outlined,
                          title: 'All caught up',
                          message:
                              "You'll see contract and payment reminders here as they come up.",
                        )
                      : RefreshIndicator(
                          color: AppColors.brandAccent,
                          backgroundColor: AppColors.brandSurface,
                          onRefresh: () => ref
                              .read(notificationsProvider.notifier)
                              .load(),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.sm,
                              AppSpacing.lg,
                              AppSpacing.lg,
                            ),
                            itemCount: state.items.length,
                            separatorBuilder: (_, __) =>
                                const Gap(AppSpacing.md),
                            itemBuilder: (_, i) {
                              final n = state.items[i];
                              return Dismissible(
                                key: ValueKey(
                                    'notif_${n.timestamp.millisecondsSinceEpoch}_$i'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding:
                                      const EdgeInsets.only(right: 24),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.danger,
                                  ),
                                ),
                                onDismissed: (_) => ref
                                    .read(notificationsProvider.notifier)
                                    .dismiss(n),
                                child: _NotificationTile(
                                  notification: n,
                                  isRead: state.isRead(n),
                                  onTap: () async {
                                    await ref
                                        .read(notificationsProvider.notifier)
                                        .markRead(n);
                                    if (n.contractId != null && context.mounted) {
                                      context.go(
                                          '/contracts/${n.contractId}');
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(notification.type);
    final icon = _iconFor(notification.type);
    return GlassCard(
      onTap: onTap,
      borderColor: isRead
          ? AppColors.glassBorder
          : color.withValues(alpha: 0.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Gap(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight:
                              isRead ? FontWeight.w500 : FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.brandAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const Gap(2),
                Text(notification.message, style: AppTextStyles.body),
                const Gap(4),
                Text(
                  DateHelper.relativeFromNow(notification.timestamp),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'contract_expiring':
        return AppColors.warning;
      case 'contract_expired':
      case 'payment_overdue':
        return AppColors.danger;
      case 'payment_due':
        return AppColors.brandGold;
      case 'contract_signed':
      case 'payment_received':
        return AppColors.success;
      default:
        return AppColors.brandAccent;
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'contract_expiring':
        return Icons.schedule;
      case 'contract_expired':
        return Icons.error_outline;
      case 'payment_due':
        return Icons.payments_outlined;
      case 'payment_overdue':
        return Icons.warning_amber_rounded;
      case 'contract_signed':
        return Icons.check_circle_outline;
      case 'payment_received':
        return Icons.savings_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
