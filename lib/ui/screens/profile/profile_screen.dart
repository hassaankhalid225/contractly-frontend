import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/contract_provider.dart';
import '../../../core/providers/payment_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../util/helpers/currency_helper.dart';
import '../../../util/helpers/date_helper.dart';
import '../../components/error_snackbar.dart';
import '../../components/glass_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled =
      StorageService.readPref<bool>(AppConstants.prefNotificationsEnabled) ??
          true;
  String _currency =
      StorageService.readPref<String>(AppConstants.prefCurrency) ?? 'USD';

  Future<void> _openLink(String url) async {
    final ok =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      AppSnackbar.error(context, 'Could not open the link.');
    }
  }

  Future<void> _editName() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    final controller = TextEditingController(text: user.name ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.brandSurface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Update name', style: AppTextStyles.title),
              const Gap(AppSpacing.lg),
              TextField(
                controller: controller,
                style: AppTextStyles.body,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const Gap(AppSpacing.xl),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandAccent,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    if (saved != true) return;
    final newName = controller.text.trim();
    if (newName.isEmpty) return;
    try {
      await ref.read(authProvider.notifier).updateProfile(name: newName);
      if (mounted) AppSnackbar.info(context, 'Profile updated.');
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Could not update profile.');
      }
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.brandSurface,
        title: Text('Log out?', style: AppTextStyles.title),
        content: Text("You'll need to sign in again next time.",
            style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await NotificationService.cancelAll();
    await ref.read(authProvider.notifier).signOut();
    if (mounted) context.go('/auth');
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.brandSurface,
        title: Text('Delete account?', style: AppTextStyles.title),
        content: Text(
          'This will permanently delete your account, all contracts and payments. This cannot be undone.',
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
            child: const Text('Delete forever'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await NotificationService.cancelAll();
    await ref.read(authProvider.notifier).deleteAccount();
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final stats = ref.watch(contractProvider).stats;
    final summary = ref.watch(paymentProvider).summary;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Text('Profile', style: AppTextStyles.headingLarge),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: GlassCard(
              child: Row(
                children: [
                  _Avatar(
                    photoUrl: user?.photoUrl,
                    initials: user?.initials ?? '?',
                  ),
                  const Gap(AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? '—',
                          style: AppTextStyles.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(2),
                        Text(
                          user?.email ?? user?.phone ?? '',
                          style: AppTextStyles.bodySecondary,
                        ),
                        if (user != null) ...[
                          const Gap(2),
                          Text(
                            'Member since ${DateHelper.formatFull(user.createdAt)}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _editName,
                    icon: const Icon(Icons.edit,
                        color: AppColors.brandAccent),
                  ),
                ],
              ),
            ),
          ),
          const Gap(AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: GlassCard(
              child: Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Contracts',
                      value: stats.total.toString(),
                    ),
                  ),
                  const _VerticalDivider(),
                  Expanded(
                    child: _MiniStat(
                      label: 'Earned',
                      value: CurrencyHelper.compact(
                          summary.totalEarned, _currency),
                    ),
                  ),
                  const _VerticalDivider(),
                  Expanded(
                    child: _MiniStat(
                      label: 'Active',
                      value: stats.active.toString(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(AppSpacing.xl),
          _SettingsSection(
            title: 'Settings',
            children: [
              _SettingTile(
                icon: Icons.notifications_active_outlined,
                label: 'Notifications',
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (v) async {
                    setState(() => _notificationsEnabled = v);
                    await StorageService.writePref(
                      AppConstants.prefNotificationsEnabled,
                      v,
                    );
                    if (!v) {
                      await NotificationService.cancelAll();
                      if (mounted) {
                        AppSnackbar.info(
                            context, 'Notifications turned off.');
                      }
                    }
                  },
                  activeThumbColor: AppColors.brandAccent,
                ),
              ),
              _SettingTile(
                icon: Icons.attach_money,
                label: 'Default Currency',
                trailing: DropdownButton<String>(
                  value: _currency,
                  underline: const SizedBox.shrink(),
                  dropdownColor: AppColors.brandSurface,
                  iconEnabledColor: AppColors.textSecondary,
                  style: AppTextStyles.body,
                  items: AppConstants.supportedCurrencies
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => _currency = v);
                    await StorageService.writePref(
                      AppConstants.prefCurrency,
                      v,
                    );
                  },
                ),
              ),
              _SettingTile(
                icon: Icons.shield_outlined,
                label: 'Privacy Policy',
                onTap: () => _openLink(AppConstants.privacyPolicyUrl),
              ),
              _SettingTile(
                icon: Icons.gavel_outlined,
                label: 'Terms of Service',
                onTap: () => _openLink(AppConstants.termsUrl),
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          _SettingsSection(
            title: 'Account',
            children: [
              _SettingTile(
                icon: Icons.logout,
                iconColor: AppColors.warning,
                labelColor: AppColors.warning,
                label: 'Log out',
                onTap: _logout,
              ),
              _SettingTile(
                icon: Icons.delete_outline,
                iconColor: AppColors.danger,
                labelColor: AppColors.danger,
                label: 'Delete account',
                onTap: _deleteAccount,
              ),
            ],
          ),
        ],
      ),
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
      radius: 28,
      backgroundColor: AppColors.brandAccent,
      child: Text(initials,
          style: AppTextStyles.title.copyWith(color: Colors.white)),
    );
    if (photoUrl == null || photoUrl!.isEmpty) return fallback;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: photoUrl!,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => fallback,
        placeholder: (_, __) => fallback,
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.title),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.glassBorder,
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              title.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      color: AppColors.glassBorder,
                      height: 1,
                      thickness: 1,
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? labelColor;

  const _SettingTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.brandAccent, size: 20),
            const Gap(AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: labelColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null)
              trailing!
            else
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary,
                size: 14,
              ),
          ],
        ),
      ),
    );
  }
}
