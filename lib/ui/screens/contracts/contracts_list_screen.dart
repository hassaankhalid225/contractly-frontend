import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/contract_model.dart';
import '../../../core/providers/contract_provider.dart';
import '../../components/contract_tile.dart';
import '../../components/empty_state.dart';
import '../../components/error_snackbar.dart';
import '../../components/loading_overlay.dart';

class ContractsListScreen extends ConsumerStatefulWidget {
  const ContractsListScreen({super.key});

  @override
  ConsumerState<ContractsListScreen> createState() =>
      _ContractsListScreenState();
}

class _ContractsListScreenState extends ConsumerState<ContractsListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _activeFilter;

  static const _filters = <_FilterOption>[
    _FilterOption(label: 'All', status: null),
    _FilterOption(label: 'Active', status: ContractStatus.active),
    _FilterOption(label: 'Expiring', status: ContractStatus.expiringSoon),
    _FilterOption(label: 'Expired', status: ContractStatus.expired),
    _FilterOption(label: 'Draft', status: ContractStatus.draft),
    _FilterOption(label: 'Completed', status: ContractStatus.completed),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref
          .read(contractProvider.notifier)
          .loadContracts(replaceFilters: true),
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 380), () {
      ref.read(contractProvider.notifier).loadContracts(
            search: value,
            replaceFilters: true,
            status: _activeFilter,
          );
    });
  }

  Future<void> _refresh() async {
    await ref.read(contractProvider.notifier).loadContracts(
          replaceFilters: true,
          status: _activeFilter,
          search: _searchController.text.isEmpty
              ? null
              : _searchController.text,
        );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contractProvider);
    final contracts = state.contracts.where((c) {
      if (_activeFilter == null) return true;
      return c.status == _activeFilter;
    }).toList();

    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppSnackbar.error(context, state.error!.friendlyMessage);
        ref.read(contractProvider.notifier).clearError();
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/contracts/create'),
        backgroundColor: AppColors.brandAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('New', style: AppTextStyles.button),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.brandAccent,
          backgroundColor: AppColors.brandSurface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                sliver: SliverToBoxAdapter(
                  child: Text('Contracts', style: AppTextStyles.headingLarge),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'Search by title or client',
                      hintStyle: AppTextStyles.bodySecondary,
                      filled: true,
                      fillColor: AppColors.brandSurface.withValues(alpha: 0.5),
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.textSecondary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close,
                                  color: AppColors.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const Gap(AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final f = _filters[i];
                      final selected = _activeFilter == f.status;
                      return ChoiceChip(
                        selected: selected,
                        showCheckmark: false,
                        label: Text(f.label),
                        labelStyle: AppTextStyles.label.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        selectedColor: AppColors.brandAccent,
                        backgroundColor:
                            AppColors.brandSurface.withValues(alpha: 0.6),
                        side: BorderSide(
                          color: selected
                              ? AppColors.brandAccent
                              : AppColors.glassBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelected: (_) {
                          setState(() => _activeFilter = f.status);
                          ref.read(contractProvider.notifier).loadContracts(
                                status: f.status,
                                search: _searchController.text,
                                replaceFilters: true,
                              );
                        },
                      );
                    },
                  ),
                ),
              ),
              if (state.isLoading && contracts.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: AppSpacing.lg),
                    child: LoadingOverlay(),
                  ),
                )
              else if (contracts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: _searchController.text.isNotEmpty
                          ? 'No matching contracts'
                          : 'No contracts yet',
                      message: _searchController.text.isNotEmpty
                          ? 'Try a different search term or filter.'
                          : 'Tap the New button to create your first contract.',
                      actionLabel: _searchController.text.isEmpty
                          ? 'Create Contract'
                          : null,
                      onActionTap: _searchController.text.isEmpty
                          ? () => context.go('/contracts/create')
                          : null,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.giant + AppSpacing.huge,
                  ),
                  sliver: SliverList.separated(
                    itemCount: contracts.length,
                    separatorBuilder: (_, __) => const Gap(AppSpacing.md),
                    itemBuilder: (_, i) {
                      final c = contracts[i];
                      return ContractTile(
                        contract: c,
                        onTap: () => context.go('/contracts/${c.id}'),
                        onDelete: () async {
                          final ok = await ref
                              .read(contractProvider.notifier)
                              .deleteContract(c.id);
                          if (mounted && ok) {
                            AppSnackbar.info(context, 'Contract deleted.');
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterOption {
  final String label;
  final String? status;
  const _FilterOption({required this.label, required this.status});
}
