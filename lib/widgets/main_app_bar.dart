import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../services/notification_service.dart';
import '../services/theme_provider.dart';
import '../services/user_provider.dart';
import '../models/user_model.dart';
import '../models/system_models.dart';
import 'calculator_dialog.dart';
import 'ai_chatbot_sheet.dart';
import '../services/transfer_provider.dart';
import '../services/branch_provider.dart';
import '../services/sync_provider.dart';
import 'staff_switch_sheet.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class MainAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showMenuButton;
  final bool showBackButton;
  final VoidCallback? onProfileTap;

  const MainAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showMenuButton = true,
    this.showBackButton = false,
    this.onProfileTap,
  });

  @override
  ConsumerState<MainAppBar> createState() => _MainAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

class _MainAppBarState extends ConsumerState<MainAppBar> with SingleTickerProviderStateMixin {
  bool _isToolsMode = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final role = user?.activePrimaryRole;
    
    final themeState = ref.watch(themeProvider);
    final bool isDark = themeState.mode == ThemeMode.dark;
    
    final Color roleColor = _getRoleColor(role, isDark, theme);
    final List<SystemNotification> notifications = ref.watch(notificationProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final pendingTransfers = ref.watch(pendingIncomingTransfersProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF2C2C2C), const Color(0xFF1E1E1E)]
              : [roleColor, roleColor.withValues(alpha: 0.85)],
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
            child: Row(
              children: [
                // 1. Navigation / Menu / Back
                if (widget.showBackButton)
                  _buildRoundButton(
                    context, 
                    Icons.arrow_back_rounded, 
                    () => Navigator.maybePop(context),
                    size: 40,
                    iconSize: 24,
                  )
                else if (widget.showMenuButton)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildRoundButton(
                        context, 
                        Icons.menu_rounded, 
                        () => Scaffold.of(context).openDrawer(),
                        size: 40,
                        iconSize: 24,
                      ),
                      if (pendingTransfers.isNotEmpty)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: roleColor, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  )
                else
                  const SizedBox(width: 8),

                const SizedBox(width: 4),

                // 2. Center Content (Dynamic Switcher)
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isToolsMode = !_isToolsMode),
                    borderRadius: BorderRadius.circular(AppRadius.m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _isToolsMode 
                        ? _buildToolsRow(context, isMobile, isDark) 
                        : _buildBrandInfo(user, isMobile),
                    ),
                  ),
                ),

                // 3. Right Actions (Critical Apps)
                SizedBox(width: isMobile ? 2 : 4),
                _buildRoundButton(
                  context, 
                  Icons.switch_account_rounded, 
                  () {
                    HapticFeedback.lightImpact();
                    StaffSwitchSheet.show(context);
                  },
                  size: isMobile ? 32 : 42,
                  iconSize: isMobile ? 16 : 20,
                  tooltip: 'Switch User / Staff Handover',
                ),
                if (user?.isPasscodeEnabled == true && user?.passcode != null && user!.passcode!.isNotEmpty) ...[
                  SizedBox(width: isMobile ? 2 : 4),
                  _buildRoundButton(
                    context, 
                    Icons.lock_outline_rounded, 
                    () {
                      HapticFeedback.mediumImpact();
                      ref.read(passcodeUnlockedProvider.notifier).state = false;
                    },
                    size: isMobile ? 32 : 42,
                    iconSize: isMobile ? 16 : 20,
                    tooltip: 'Lock System',
                  ),
                ],
                SizedBox(width: isMobile ? 2 : 4),
                _buildRoundButton(
                  context, 
                  Icons.calculate_outlined, 
                  () => showDialog(context: context, builder: (context) => const CalculatorDialog()),
                  size: isMobile ? 32 : 42,
                  iconSize: isMobile ? 16 : 20,
                  tooltip: 'Quick Calculator',
                ),
                if (widget.actions != null) ...[
                  SizedBox(width: isMobile ? 2 : 4),
                  ...widget.actions!,
                ],
                SizedBox(width: isMobile ? 2 : 4),
                _buildNotificationButton(context, unreadCount, () => _showNotificationsDialog(context, ref, notifications), isMobile),
                SizedBox(width: isMobile ? 2 : 4),
                _buildProfileAvatar(context, ref, roleColor, isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandInfo(UserAccount? user, bool isMobile) {
    final currentBranch = ref.watch(currentBranchProvider);
    final String branchText = currentBranch != null 
        ? '${currentBranch.name} (${currentBranch.location})'
        : (user?.branchCode ?? 'City Cosmetics');

    return Column(
      key: const ValueKey('brand_info'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            _buildCloudSyncIndicator(context, ref, isMobile),
          ],
        ),
        Text(
          user != null 
            ? '${user.firstName} • ${user.activePrimaryRole.name.toUpperCase()} • $branchText'
            : branchText,
          style: TextStyle(
            fontSize: 9,
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildToolsRow(BuildContext context, bool isMobile, bool isDark) {
    return Row(
      key: const ValueKey('tools'),
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildToolIcon(Icons.refresh_rounded, () {
          ref.read(transferProvider.notifier).loadTransfers();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing Data...'), duration: Duration(milliseconds: 500)));
        }),
        const SizedBox(width: 12),
        _buildToolIcon(Icons.calculate_outlined, () => showDialog(context: context, builder: (context) => const CalculatorDialog())),
        const SizedBox(width: 12),
        _buildToolIcon(Icons.auto_awesome_outlined, () => _showAiChatbot(context)),
        if (!isMobile) ...[
          const SizedBox(width: 12),
          _buildToolIcon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, 
            () => ref.read(themeProvider.notifier).toggleTheme(!isDark)
          ),
        ],
      ],
    );
  }

  Widget _buildToolIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildCloudSyncIndicator(BuildContext context, WidgetRef ref, bool isMobile) {
    final syncState = ref.watch(syncProvider);
    final connectivity = ref.watch(connectivityStatusProvider);

    final bool hasInternet = syncState.isConnected && 
        !(connectivity.valueOrNull?.every((result) => result == ConnectivityResult.none) ?? false);
    final bool isSyncing = syncState.isSyncing;

    // Strict 3-state Color mapping:
    // 1. Red when no internet
    // 2. Orange when syncing
    // 3. Green when there is internet and complete sync
    final Color color;
    final IconData icon;
    final String text;
    final String tooltip;

    if (!hasInternet) {
      color = const Color(0xFFFF3B30); // Red
      icon = Icons.cloud_off_rounded;
      text = 'NO INTERNET';
      tooltip = 'No Internet Connection (${syncState.pendingCount} queued) • Tap for details';
    } else if (isSyncing) {
      color = const Color(0xFFFF9500); // Orange
      icon = Icons.cloud_sync_rounded;
      text = 'SYNCING';
      tooltip = 'Synchronizing with Supabase Cloud...';
    } else {
      color = const Color(0xFF34C759); // Green
      icon = Icons.cloud_done_rounded;
      text = 'SYNCED';
      tooltip = 'Internet Connected & Complete Cloud Sync • Tap for details';
    }

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showCloudSyncConfirmationDialog(context, ref);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 6, vertical: isMobile ? 3.5 : 2.5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.65), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSyncing)
                RotationTransition(
                  turns: _pulseController,
                  child: Icon(icon, size: isMobile ? 13 : 14, color: color),
                )
              else
                Icon(icon, size: isMobile ? 13 : 14, color: color),
              if (!isMobile) ...[
                const SizedBox(width: 4),
                Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCloudSyncConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            final syncState = ref.watch(syncProvider);
            final connectivity = ref.watch(connectivityStatusProvider);
            final bool hasInternet = syncState.isConnected &&
                !(connectivity.valueOrNull?.every((r) => r == ConnectivityResult.none) ?? false);
            final bool isSyncing = syncState.isSyncing;
            final theme = Theme.of(context);

            final Color statusColor = !hasInternet
                ? const Color(0xFFFF3B30) // Red
                : (isSyncing ? const Color(0xFFFF9500) : const Color(0xFF34C759)); // Orange / Green

            final IconData statusIcon = !hasInternet
                ? Icons.cloud_off_rounded
                : (isSyncing ? Icons.cloud_sync_rounded : Icons.cloud_done_rounded);

            final String statusDescription = !hasInternet
                ? 'No Internet: System operating offline. All actions will automatically push once reconnected.'
                : (isSyncing
                    ? 'Syncing In Progress: Data is uploading/downloading with Supabase Cloud.'
                    : 'Complete Sync: Internet active and cloud data fully synchronized.');

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Cloud Synchronization',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.s),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          !hasInternet ? Icons.wifi_off_rounded : (isSyncing ? Icons.sync_rounded : Icons.check_circle_outline),
                          color: statusColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            statusDescription,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSyncDetailRow('Backend Server', 'Supabase Cloud (PostgreSQL)'),
                  const SizedBox(height: 8),
                  _buildSyncDetailRow(
                    'Connection Status',
                    !hasInternet ? 'No Internet (Red)' : (isSyncing ? 'Syncing (Orange)' : 'Connected & Synced (Green)'),
                    color: statusColor,
                  ),
                  const SizedBox(height: 8),
                  _buildSyncDetailRow(
                    'Last Synchronized',
                    DateFormat('MMM dd, yyyy • hh:mm:ss a').format(syncState.lastSynced),
                  ),
                  const SizedBox(height: 8),
                  _buildSyncDetailRow(
                    'Pending Offline Queue',
                    '${syncState.pendingCount} item(s)',
                    color: syncState.pendingCount > 0 ? Colors.orange : Colors.grey,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
                FilledButton.icon(
                  onPressed: syncState.isSyncing
                      ? null
                      : () async {
                          HapticFeedback.mediumImpact();
                          await ref.read(syncProvider.notifier).syncAll();
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('☁️ Cloud synchronization refreshed successfully!'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  icon: syncState.isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.sync_rounded, size: 18),
                  label: Text(syncState.isSyncing ? 'Syncing...' : 'Sync Now'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSyncDetailRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(UserRole? role, bool isDark, ThemeData theme) {
    if (isDark) return theme.appBarTheme.backgroundColor ?? const Color(0xFF1E1E1E);
    return theme.colorScheme.primary;
  }

  Widget _buildNotificationButton(BuildContext context, int count, VoidCallback onTap, bool isMobile) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildRoundButton(
          context, 
          Icons.notifications_none_rounded, 
          onTap,
          size: isMobile ? 32 : 42,
          iconSize: isMobile ? 16 : 20,
        ),
        if (count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileAvatar(BuildContext context, WidgetRef ref, Color roleColor, bool isMobile) {
    final user = ref.watch(currentUserProvider);
    final size = isMobile ? 30.0 : 38.0;

    return InkWell(
      onTap: () => widget.onProfileTap != null ? widget.onProfileTap!() : Navigator.pushNamed(context, '/profile'),
      borderRadius: BorderRadius.circular(size),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
          color: Colors.white24,
        ),
        child: ClipOval(
          child: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
              ? Image.network(
                  user.photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: Colors.white, size: size * 0.6),
                )
              : Icon(Icons.person, color: Colors.white, size: size * 0.6),
        ),
      ),
    );
  }

  Widget _buildRoundButton(BuildContext context, IconData icon, VoidCallback onTap, {double size = 40, double iconSize = 20, Color? color, String? tooltip}) {
    Widget button = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: color ?? Colors.white.withValues(alpha: 0.15),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(icon, size: iconSize, color: Colors.white),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: button);
    }
    return button;
  }

  // Show Notifications
  void _showNotificationsDialog(BuildContext context, WidgetRef ref, List<SystemNotification> allNotifications) {
    final theme = Theme.of(context);
    // Only show unread notifications in the "Recent" popup to satisfy "Clear All" logic
    final notifications = allNotifications.where((n) => !n.isRead).toList();
    final unreadCount = notifications.length;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
        backgroundColor: theme.colorScheme.surface,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500), // Added maxHeight to prevent overflows
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.m),
                decoration: const BoxDecoration(
                  color: AppColors.primaryMaroon,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 60), // Balanced spacer
                    const Expanded(
                      child: Text(
                        'Recent Notifications', 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: unreadCount == 0 ? null : TextButton(
                        onPressed: () {
                          ref.read(notificationProvider.notifier).markAllAsRead();
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white38,
                        ),
                        child: const Text('Clear All', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              if (notifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60, horizontal: 20), 
                  child: Column(
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 40, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No new notifications.', style: TextStyle(color: Colors.grey)),
                    ],
                  )
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            n.title.contains('BUTCHER') ? Icons.warning_rounded : Icons.info_outline_rounded, 
                            color: Colors.orange,
                            size: 20,
                          ),
                        ),
                        title: Text(n.title, 
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(n.message, 
                          style: const TextStyle(fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          DateFormat('HH:mm').format(n.createdAt), 
                          style: const TextStyle(fontSize: 10, color: Colors.grey)
                        ),
                        tileColor: Colors.orange.withValues(alpha: 0.02),
                        onTap: () {
                          ref.read(notificationProvider.notifier).markAsRead(n.id);
                          final title = n.title.toUpperCase();
                          if (title.contains('TRANSFER') || title.contains('DISPATCHED') || title.contains('STOCK')) {
                            Navigator.pop(context); // Close notifications dialog
                            Navigator.pushNamed(context, '/cashier/verify-stock');
                          }
                        },
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s),
                child: TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('Dismiss View', style: TextStyle(fontSize: 12))
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAiChatbot(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AiChatbotSheet(),
    );
  }
}
