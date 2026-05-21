import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/contract_model.dart';
import '../../util/helpers/currency_helper.dart';
import '../../util/helpers/date_helper.dart';
import 'glass_card.dart';
import 'status_badge.dart';

class ContractTile extends StatelessWidget {
  final ContractModel contract;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ContractTile({
    super.key,
    required this.contract,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.statusFgFor(contract.status);
    final body = GlassCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.lg),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contract.title,
                                style: AppTextStyles.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Gap(AppSpacing.xxs),
                              Text(
                                contract.clientName,
                                style: AppTextStyles.bodySecondary.copyWith(
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Gap(AppSpacing.sm),
                        StatusBadge.contract(contract.status),
                      ],
                    ),
                    const Gap(AppSpacing.md),
                    Row(
                      children: [
                        Text(
                          CurrencyHelper.format(
                            contract.value,
                            contract.currency,
                          ),
                          style: AppTextStyles.money.copyWith(fontSize: 14),
                        ),
                        const Spacer(),
                        if (contract.endDate != null)
                          Text(
                            DateHelper.daysRemainingLabel(contract.endDate!),
                            style: AppTextStyles.caption,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (onDelete == null) return body;

    return Dismissible(
      key: ValueKey('contract_${contract.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.brandSurface,
            title: Text('Delete contract?', style: AppTextStyles.title),
            content: Text(
              '"${contract.title}" will be permanently removed along with its payments.',
              style: AppTextStyles.body,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      child: body,
    );
  }
}
