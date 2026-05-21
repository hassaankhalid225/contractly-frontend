import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/contract_model.dart';
import '../../core/models/payment_model.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  const StatusBadge._({
    required this.status,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  factory StatusBadge.contract(String status) {
    return StatusBadge._(
      status: status,
      label: ContractStatus.label(status),
      background: AppColors.statusBgFor(status),
      foreground: AppColors.statusFgFor(status),
      icon: _iconFor(status),
    );
  }

  factory StatusBadge.payment(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case PaymentStatus.paid:
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
        break;
      case PaymentStatus.overdue:
        bg = AppColors.danger.withValues(alpha: 0.15);
        fg = AppColors.danger;
        break;
      case PaymentStatus.cancelled:
        bg = AppColors.textMuted.withValues(alpha: 0.18);
        fg = AppColors.textMuted;
        break;
      case PaymentStatus.pending:
      default:
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = AppColors.warning;
    }
    return StatusBadge._(
      status: status,
      label: PaymentStatus.label(status),
      background: bg,
      foreground: fg,
      icon: _paymentIconFor(status),
    );
  }

  factory StatusBadge.risk(String severity) {
    Color bg;
    Color fg;
    switch (severity) {
      case 'high':
        bg = AppColors.danger.withValues(alpha: 0.18);
        fg = AppColors.danger;
        break;
      case 'medium':
        bg = AppColors.warning.withValues(alpha: 0.18);
        fg = AppColors.warning;
        break;
      case 'low':
      default:
        bg = AppColors.success.withValues(alpha: 0.18);
        fg = AppColors.success;
    }
    return StatusBadge._(
      status: severity,
      label: '${severity[0].toUpperCase()}${severity.substring(1)} risk',
      background: bg,
      foreground: fg,
      icon: Icons.shield_outlined,
    );
  }

  static IconData _iconFor(String status) {
    switch (status) {
      case ContractStatus.active:
        return Icons.check_circle_outline;
      case ContractStatus.expiringSoon:
        return Icons.schedule;
      case ContractStatus.expired:
        return Icons.error_outline;
      case ContractStatus.completed:
        return Icons.task_alt;
      case ContractStatus.cancelled:
        return Icons.cancel_outlined;
      case ContractStatus.draft:
      default:
        return Icons.edit_document;
    }
  }

  static IconData _paymentIconFor(String status) {
    switch (status) {
      case PaymentStatus.paid:
        return Icons.check_circle_outline;
      case PaymentStatus.overdue:
        return Icons.warning_amber_outlined;
      case PaymentStatus.cancelled:
        return Icons.cancel_outlined;
      case PaymentStatus.pending:
      default:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
