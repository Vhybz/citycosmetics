import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../core/uuid_utils.dart';
import '../core/supabase_config.dart';
import 'notification_service.dart';

/// Default Sunyani Branch GPS Coordinates
class StoreCoordinates {
  static const double defaultLat = 7.35134;
  static const double defaultLon = -2.31961;
  static const double maxRadiusMeters = 50.0;
}

final attendanceRecordsProvider = StateNotifierProvider<AttendanceNotifier, AsyncValue<List<AttendanceRecord>>>((ref) {
  return AttendanceNotifier(ref);
});

class AttendanceNotifier extends StateNotifier<AsyncValue<List<AttendanceRecord>>> {
  final Ref ref;
  final Map<String, DateTime> _bypassedUntilMap = {};
  Future<void>? _loadFuture;

  AttendanceNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadFuture = loadAttendanceRecords();
  }

  Future<void> ensureLoaded() async {
    if (_loadFuture != null) {
      await _loadFuture;
    }
  }

  bool isBypassedForUser(String userId) {
    final expiry = _bypassedUntilMap[userId];
    if (expiry == null) return false;
    if (DateTime.now().isAfter(expiry)) {
      _bypassedUntilMap.remove(userId);
      return false;
    }
    return true;
  }

  void markBypassedForUser(String userId, {Duration duration = const Duration(minutes: 15)}) {
    _bypassedUntilMap[userId] = DateTime.now().add(duration);
  }

  /// Haversine GPS distance formula in meters
  static double calculateDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusMeters = 6371000.0;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  Future<void> loadAttendanceRecords() async {
    try {
      final response = await SupabaseConfig.client
          .from('attendance_records')
          .select()
          .order('check_in_time', ascending: false)
          .limit(200);

      final records = (response as List).map((json) => AttendanceRecord.fromJson(json)).toList();
      state = AsyncValue.data(records);
      
      // Run auto check-out for overdue staff after loading
      autoCheckOutOverdueStaff();
    } catch (e) {
      debugPrint('Error loading attendance records: $e');
      state = AsyncValue.data([]);
    }
  }

  AttendanceRecord? getTodayAttendanceForUser(String userId) {
    final records = state.value ?? [];
    final now = DateTime.now();
    return records.where((r) {
      if (r.userId != userId) return false;
      final checkInLocal = r.checkInTime.toLocal();
      final dateLocal = r.date.toLocal();
      final isSameCheckInDay = checkInLocal.year == now.year &&
          checkInLocal.month == now.month &&
          checkInLocal.day == now.day;
      final isSameRecordDay = dateLocal.year == now.year &&
          dateLocal.month == now.month &&
          dateLocal.day == now.day;
      return isSameCheckInDay || isSameRecordDay;
    }).firstOrNull;
  }

  /// Process Daily Check-In
  Future<AttendanceRecord> checkIn({
    required UserAccount user,
    required double lat,
    required double lon,
    double storeLat = StoreCoordinates.defaultLat,
    double storeLon = StoreCoordinates.defaultLon,
    double maxRadius = StoreCoordinates.maxRadiusMeters,
  }) async {
    final now = DateTime.now();

    // Check Sunday Exclusion
    if (now.weekday == DateTime.sunday) {
      throw Exception('Sundays are excluded from attendance check-in.');
    }

    // Check distance
    final distance = calculateDistanceMeters(lat, lon, storeLat, storeLon);
    final isVerified = distance <= maxRadius;

    if (!isVerified) {
      throw Exception('Location Check-In Failed: You are ${distance.toInt()}m away from store. Must be within ${maxRadius.toInt()}m to check in.');
    }

    // Check if already checked in today
    final existing = getTodayAttendanceForUser(user.id);
    if (existing != null) {
      return existing;
    }

    // Determine status: On Time if before 8:30 AM, Late if after
    final bool isLate = now.hour > 8 || (now.hour == 8 && now.minute > 30);
    final String status = isLate ? 'late' : 'on_time';

    final record = AttendanceRecord(
      id: UuidUtils.generate(),
      userId: user.id,
      userName: user.name,
      userRole: user.activePrimaryRole.name.toUpperCase(),
      branchCode: user.branchCode,
      date: now,
      checkInTime: now,
      checkInLat: lat,
      checkInLon: lon,
      distanceMeters: distance,
      status: status,
      isVerifiedLocation: true,
      notes: isLate ? 'Checked in late at ${DateFormat('HH:mm').format(now)}' : 'On-time check-in',
    );

    try {
      await SupabaseConfig.client.from('attendance_records').upsert(record.toJson());
    } catch (e) {
      debugPrint('Attendance Check-In Supabase error: $e');
    }

    final currentList = state.value ?? [];
    state = AsyncValue.data([record, ...currentList]);

    // Send Real-Time Alert to Admin
    _notifyAdminOnCheckIn(user, record);

    return record;
  }

  /// Process Check-Out (Manual or Automatic at 21:00)
  Future<void> checkOut(String recordId, {bool isAuto = false}) async {
    final records = state.value ?? [];
    final idx = records.indexWhere((r) => r.id == recordId);
    if (idx == -1) return;

    final existing = records[idx];
    final now = DateTime.now();
    final checkOutTime = isAuto 
        ? DateTime(existing.date.year, existing.date.month, existing.date.day, 21, 0)
        : now;

    final updated = existing.copyWith(
      checkOutTime: checkOutTime,
      status: isAuto ? 'auto_checked_out' : 'checked_out',
      notes: isAuto ? 'Automatically checked out at 21:00' : 'Manual check-out at ${DateFormat('HH:mm').format(now)}',
    );

    try {
      await SupabaseConfig.client.from('attendance_records').update({
        'check_out_time': checkOutTime.toIso8601String(),
        'status': updated.status,
        'notes': updated.notes,
      }).eq('id', recordId);
    } catch (e) {
      debugPrint('Attendance Check-Out Supabase error: $e');
    }

    final newList = List<AttendanceRecord>.from(records);
    newList[idx] = updated;
    state = AsyncValue.data(newList);
  }

  /// Automatically check out overdue staff at 21:00 PM
  void autoCheckOutOverdueStaff() {
    final records = state.value ?? [];
    final now = DateTime.now();

    for (final r in records) {
      if (r.checkOutTime == null) {
        final checkInDay = DateTime(r.date.year, r.date.month, r.date.day);
        final today = DateTime(now.year, now.month, now.day);

        // If from a previous day or today past 21:00 PM
        if (checkInDay.isBefore(today) || (checkInDay.isAtSameMomentAs(today) && now.hour >= 21)) {
          checkOut(r.id, isAuto: true);
        }
      }
    }
  }

  void _notifyAdminOnCheckIn(UserAccount user, AttendanceRecord record) {
    try {
      final timeStr = DateFormat('hh:mm a').format(record.checkInTime);
      final statusLabel = record.status == 'late' ? 'LATE' : 'ON TIME';
      final msg = '${user.name} (${user.activePrimaryRole.name.toUpperCase()}) checked in at $timeStr ($statusLabel, ${record.distanceMeters.toInt()}m from shop).';

      ref.read(notificationProvider.notifier).addNotification(
        'ATTENDANCE CHECK-IN: ${user.name}',
        msg,
        type: record.status == 'late' ? 'warning' : 'info',
        isGlobal: true,
      );
    } catch (e) {
      debugPrint('Admin check-in notification error: $e');
    }
  }
}
