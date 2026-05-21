import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/payment_model.dart';
import '../../../core/providers/contract_provider.dart';
import '../../../core/providers/payment_provider.dart';
import '../../../util/helpers/currency_helper.dart';
import '../../../util/helpers/date_helper.dart';
import '../../components/empty_state.dart';
import '../../components/glass_card.dart';
import '../../components/loading_overlay.dart';
import '../../components/status_badge.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(contractProvider.notifier).loadContracts();
      await ref
          .read(paymentProvider.notifier)
          .loadPayments(replaceFilters: true);
      await ref.read(paymentProvider.notifier).loadSummary();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(paymentProvider.notifier).loadPayments(replaceFilters: true),
      ref.read(paymentProvider.notifier).loadSummary(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final payments = ref.watch(paymentProvider);
    final summary = payments.summary;
    final contracts = ref.watch(contractProvider).contracts;
    final currency = contracts.isEmpty ? 'USD' : contracts.first.currency;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
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
                AppSpacing.md,
              ),
              child: Text('Payments', style: AppTextStyles.headingLarge),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryStat(
                      icon: Icons.savings_outlined,
                      label: 'Earned',
                      value: CurrencyHelper.compact(
                          summary.totalEarned, currency),
                      tint: AppColors.success,
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: _SummaryStat(
                      icon: Icons.schedule_rounded,
                      label: 'Pending',
                      value: CurrencyHelper.compact(
                          summary.totalPending, currency),
                      tint: AppColors.brandGold,
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: _SummaryStat(
                      icon: Icons.warning_amber_rounded,
                      label: 'Overdue',
                      value: CurrencyHelper.compact(
                          summary.totalOverdue, currency),
                      tint: AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.lg),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GlassCard(
                child: SizedBox(
                  height: 180,
                  child: payments.payments.isEmpty
                      ? Center(
                          child: Text(
                            'No earnings yet',
                            style: AppTextStyles.bodySecondary,
                          ),
                        )
                      : _EarningsChart(payments: payments.payments),
                ),
              ),
            ),
            const Gap(AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text('All Milestones', style: AppTextStyles.title),
            ),
            const Gap(AppSpacing.sm),
            if (payments.isLoading && payments.payments.isEmpty)
              const LoadingOverlay()
            else if (payments.payments.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: EmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'No payments yet',
                  message:
                      'Add payment milestones from any contract to track earnings here.',
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: Column(
                  children: [
                    for (final p in payments.payments) ...[
                      _PaymentRow(
                        payment: p,
                        contractTitle: _titleFor(contracts, p.contractId),
                        onMarkPaid: p.status == PaymentStatus.paid
                            ? null
                            : () => _confirmMarkPaid(p),
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

  String _titleFor(List<dynamic> contracts, String contractId) {
    final match = contracts.where((c) => c.id == contractId);
    return match.isEmpty ? 'Contract' : match.first.title.toString();
  }

  Future<void> _confirmMarkPaid(PaymentModel p) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.brandSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.success, size: 56),
              const Gap(AppSpacing.md),
              Text('Mark as paid?',
                  style: AppTextStyles.title, textAlign: TextAlign.center),
              const Gap(AppSpacing.xs),
              Text(
                CurrencyHelper.format(p.amount, p.currency),
                style: AppTextStyles.heading
                    .copyWith(color: AppColors.brandGold),
              ),
              const Gap(AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      await ref.read(paymentProvider.notifier).markPaid(p.id);
    }
  }
}

class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  const _SummaryStat({
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
          Text(value,
              style: AppTextStyles.title.copyWith(color: tint, fontSize: 16)),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final PaymentModel payment;
  final String contractTitle;
  final VoidCallback? onMarkPaid;
  const _PaymentRow({
    required this.payment,
    required this.contractTitle,
    required this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contractTitle,
                    style: AppTextStyles.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const Gap(2),
                Text(
                  'Due ${DateHelper.formatFull(payment.dueDate)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyHelper.format(payment.amount, payment.currency),
                style: AppTextStyles.subtitle
                    .copyWith(color: AppColors.brandGold),
              ),
              const Gap(2),
              StatusBadge.payment(payment.status),
            ],
          ),
          if (onMarkPaid != null) ...[
            const Gap(AppSpacing.sm),
            IconButton(
              tooltip: 'Mark paid',
              onPressed: onMarkPaid,
              icon: const Icon(Icons.check_circle_outline,
                  color: AppColors.success),
            ),
          ],
        ],
      ),
    );
  }
}

class _EarningsChart extends StatelessWidget {
  final List<PaymentModel> payments;
  const _EarningsChart({required this.payments});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i), 1);
      return m;
    });
    final totals = months.map((m) {
      double sum = 0;
      for (final p in payments) {
        if (p.status != PaymentStatus.paid) continue;
        final paid = p.paidDate ?? p.dueDate;
        if (paid.year == m.year && paid.month == m.month) sum += p.amount;
      }
      return sum;
    }).toList();

    final maxValue =
        totals.fold<double>(0, (max, v) => v > max ? v : max).clamp(1, double.infinity);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxValue * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue / 3,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.glassBorder.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: maxValue / 2,
              getTitlesWidget: (v, _) => Text(
                v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toStringAsFixed(0),
                style: AppTextStyles.caption.copyWith(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= months.length) return const SizedBox.shrink();
                return Text(
                  _shortMonth(months[i]),
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: AppColors.brandAccent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.brandAccent.withValues(alpha: 0.3),
                  AppColors.brandAccent.withValues(alpha: 0.0),
                ],
              ),
            ),
            spots: [
              for (var i = 0; i < totals.length; i++)
                FlSpot(i.toDouble(), totals[i]),
            ],
          ),
        ],
      ),
    );
  }

  String _shortMonth(DateTime d) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[d.month - 1];
  }
}
