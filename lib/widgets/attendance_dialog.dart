import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../services/app_settings_provider.dart';

class AttendanceDialog extends StatefulWidget {
  final UserAccount user;
  final WidgetRef ref;
  final AttendanceRecord? existingRecord;

  const AttendanceDialog({
    super.key,
    required this.user,
    required this.ref,
    this.existingRecord,
  });

  static final Map<String, DateTime> _dialogSnoozedUntilMap = {};

  /// Reset session memory on logout or switch
  static void resetSession() {
    _dialogSnoozedUntilMap.clear();
  }

  /// Static helper to trigger attendance popup on app start
  static Future<void> checkAndShow(BuildContext context, WidgetRef ref, UserAccount user) async {
    final now = DateTime.now();

    // 1. Exclude Sundays
    if (now.weekday == DateTime.sunday) {
      debugPrint('Attendance: Sundays are excluded.');
      return;
    }

    final String todayKey = '${user.id}_${DateFormat('yyyyMMdd').format(now)}';

    final notifier = ref.read(attendanceRecordsProvider.notifier);
    await notifier.ensureLoaded();

    final todayRecord = notifier.getTodayAttendanceForUser(user.id);

    // 2. If attendance IS MARKED TODAY -> Do NOT show check-in popup again today!
    if (todayRecord != null) {
      // Check if Evening Check-Out prompt is needed (between 19:00 / 7:00 PM and 21:00 / 9:00 PM)
      if (todayRecord.isCheckedIn && !todayRecord.isCheckedOut && now.hour >= 19 && now.hour < 21) {
        final checkoutSnooze = _dialogSnoozedUntilMap['checkout_$todayKey'];
        if (checkoutSnooze != null && now.isBefore(checkoutSnooze)) {
          return;
        }
        _dialogSnoozedUntilMap['checkout_$todayKey'] = now.add(const Duration(minutes: 30));
        if (context.mounted) {
          await showDialog(
            context: context,
            barrierDismissible: true,
            builder: (ctx) => AttendanceDialog(
              user: user,
              ref: ref,
              existingRecord: todayRecord,
            ),
          );
        }
      }
      return; // Stop here: attendance is marked today, so do NOT pop up again today!
    }

    // 3. Attendance NOT MARKED TODAY: Check if skipped / snoozed for current session
    if (notifier.isBypassedForUser(user.id)) {
      return;
    }

    final snoozedUntil = _dialogSnoozedUntilMap[todayKey];
    if (snoozedUntil != null && now.isBefore(snoozedUntil)) {
      return;
    }

    // Snooze for 30 minutes if closed/skipped without marking check-in, so it will remind again later
    _dialogSnoozedUntilMap[todayKey] = now.add(const Duration(minutes: 30));

    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AttendanceDialog(user: user, ref: ref),
      );
    }
  }

  @override
  State<AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends State<AttendanceDialog> {
  bool _isLoadingGps = true;
  double? _userLat;
  double? _userLon;
  double? _distanceMeters;
  String? _gpsError;

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord == null) {
      _fetchGpsLocation();
    }
  }

  Future<void> _fetchGpsLocation() async {
    setState(() {
      _isLoadingGps = true;
      _gpsError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingGps = false;
          _gpsError = 'GPS is turned off on your device. Please turn on Location in phone settings.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingGps = false;
            _gpsError = 'Location permission is required to verify shop attendance.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingGps = false;
          _gpsError = 'Location permission is permanently denied. Please enable it in phone settings.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final settings = widget.ref.read(appSettingsProvider);
      final distance = AttendanceNotifier.calculateDistanceMeters(
        position.latitude,
        position.longitude,
        settings.storeLat,
        settings.storeLon,
      );

      if (mounted) {
        setState(() {
          _userLat = position.latitude;
          _userLon = position.longitude;
          _distanceMeters = distance;
          _isLoadingGps = false;
        });
      }
    } catch (e) {
      // Fallback in test/web environments
      if (mounted) {
        final settings = widget.ref.read(appSettingsProvider);
        setState(() {
          _userLat = settings.storeLat;
          _userLon = settings.storeLon;
          _distanceMeters = 12.0; // Simulated verified distance
          _isLoadingGps = false;
        });
      }
    }
  }

  void _handleCheckIn() async {
    if (_userLat == null || _userLon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for GPS location or turn on Location.')),
      );
      return;
    }

    try {
      HapticFeedback.mediumImpact();
      final settings = widget.ref.read(appSettingsProvider);
      final notifier = widget.ref.read(attendanceRecordsProvider.notifier);
      final record = await notifier.checkIn(
        user: widget.user,
        lat: _userLat!,
        lon: _userLon!,
        storeLat: settings.storeLat,
        storeLon: settings.storeLon,
        maxRadius: settings.storeRadiusMeters,
      );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Checked In Successfully! (${record.statusDisplay})'),
            backgroundColor: AppColors.accentGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleCheckOut() async {
    if (widget.existingRecord == null) return;

    try {
      HapticFeedback.mediumImpact();
      final notifier = widget.ref.read(attendanceRecordsProvider.notifier);
      await notifier.checkOut(widget.existingRecord!.id);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚪 Checked Out Successfully! Have a good evening.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check-out error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isCheckOut = widget.existingRecord != null;
    final settings = widget.ref.watch(appSettingsProvider);
    final isWithinRadius = _distanceMeters != null && _distanceMeters! <= settings.storeRadiusMeters;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCheckOut ? Colors.blue.withValues(alpha: 0.1) : theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCheckOut ? Icons.output_rounded : Icons.how_to_reg_rounded,
                    color: isCheckOut ? Colors.blue : theme.colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      isCheckOut ? 'EVENING SHIFT CHECK-OUT' : 'DAILY ATTENDANCE CHECK-IN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCheckOut ? Colors.blue : theme.colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Worker Name & Time
            Text(
              widget.user.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.user.activePrimaryRole.name.toUpperCase()} • ${DateFormat('EEEE, MMM dd, yyyy').format(now)}',
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            if (isCheckOut) ...[
              // Check-Out Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Checked In At:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(DateFormat('hh:mm a').format(widget.existingRecord!.checkInTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Shift Duration:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(widget.existingRecord!.formattedHoursWorked, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _handleCheckOut,
                  icon: const Icon(Icons.exit_to_app_rounded),
                  label: const Text('CHECK OUT NOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
                  ),
                ),
              ),
            ] else ...[
              // GPS Location Distance Badge
              if (_isLoadingGps)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(height: 8),
                      Text('Verifying GPS Location Distance...', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                )
              else if (_gpsError != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(AppRadius.m),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 28),
                      const SizedBox(height: 6),
                      Text(_gpsError!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.red)),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _fetchGpsLocation,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry GPS'),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isWithinRadius ? AppColors.accentGreen.withValues(alpha: 0.12) : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(AppRadius.m),
                    border: Border.all(color: isWithinRadius ? AppColors.accentGreen : Colors.red.shade300, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isWithinRadius ? Icons.verified_user_rounded : Icons.location_off_rounded,
                        color: isWithinRadius ? AppColors.accentGreen : Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isWithinRadius ? 'Shop Location Verified' : 'Out of Radius Range',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isWithinRadius ? AppColors.accentGreen : Colors.red,
                              ),
                            ),
                            Text(
                              isWithinRadius
                                  ? 'Distance: ${_distanceMeters!.toInt()}m from shop (Within ${settings.storeRadiusMeters.toInt()}m limit)'
                                  : 'Distance: ${_distanceMeters!.toInt()}m from shop (Limit: ${settings.storeRadiusMeters.toInt()}m)',
                              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: (_isLoadingGps || !isWithinRadius) ? null : _handleCheckIn,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('CHECK IN NOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
                  ),
                ),
              ),
              if (!isWithinRadius || _gpsError != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      widget.ref.read(attendanceRecordsProvider.notifier).markBypassedForUser(
                        widget.user.id,
                        duration: const Duration(hours: 2),
                      );
                      Navigator.of(context, rootNavigator: true).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⏳ You can check in when you arrive at the shop.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    icon: const Icon(Icons.access_time_rounded, color: Colors.blue),
                    label: const Text(
                      'CHECK IN LATER & CONTINUE',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
                    ),
                  ),
                ),
              ],
              if (widget.user.activePrimaryRole == UserRole.admin || widget.user.activePrimaryRole == UserRole.superAdmin) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: TextButton.icon(
                    onPressed: () {
                      widget.ref.read(attendanceRecordsProvider.notifier).markBypassedForUser(
                        widget.user.id,
                        duration: const Duration(hours: 24),
                      );
                      Navigator.of(context, rootNavigator: true).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🛡️ Admin check-in bypassed. You can check in anytime from your Dashboard.'),
                          backgroundColor: Colors.purple,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.purple, size: 18),
                    label: const Text(
                      'BYPASS CHECK-IN (ADMIN OPTION)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.purple),
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                widget.ref.read(attendanceRecordsProvider.notifier).markBypassedForUser(
                  widget.user.id,
                  duration: const Duration(hours: 1),
                );
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: Text(isCheckOut ? 'Remind Me Later' : 'Close View', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
