import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

/// Must match the `databaseURL` in firebase_options.dart. The Realtime
/// Database for this project lives in `asia-southeast1`, not the default
/// region — on Android, `FirebaseDatabase.instance` (no explicit URL)
/// connects to the default endpoint first and gets forcefully disconnected
/// by the server with "Database lives in a different region" and *no*
/// automatic reconnect, so the app silently never receives any esp32/led
/// updates. Always go through this instead of `FirebaseDatabase.instance`.
final FirebaseDatabase esp32Database = FirebaseDatabase.instanceFor(
  app: Firebase.app(),
  databaseURL:
      'https://project-arm-app-default-rtdb.asia-southeast1.firebasedatabase.app',
);

enum DeviceHealthState { offline, online, working }

DateTime? _parseTimestamp(Object? value) {
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.round());
  }
  if (value is String) {
    final parsedMs = int.tryParse(value);
    if (parsedMs != null) {
      return DateTime.fromMillisecondsSinceEpoch(parsedMs);
    }
    return DateTime.tryParse(value);
  }
  return null;
}

/// Shared with [DeviceStatusCard] so patient and doctor screens agree on
/// what counts as "online" vs a stale/offline reading from `esp32/led`.
DeviceHealthState resolveDeviceHealth({
  required Object? rawStatus,
  required Object? updatedAtValue,
  DateTime? now,
  Duration staleThreshold = const Duration(seconds: 30),
}) {
  final currentTime = now ?? DateTime.now();
  final normalized = (rawStatus?.toString().trim().toLowerCase() ?? '')
      .replaceAll(' ', '')
      .replaceAll('"', '')
      .replaceAll("'", '')
      .replaceAll('`', '')
      .replaceAll('\n', '')
      .replaceAll('\r', '');
  final lastUpdatedAt = _parseTimestamp(updatedAtValue);
  final isFresh = lastUpdatedAt != null &&
      currentTime.difference(lastUpdatedAt) <= staleThreshold;

  if (normalized == 'working' ||
      normalized == 'on' ||
      normalized == 'running' ||
      normalized == 'ทำงาน' ||
      normalized == 'กำลังทำงาน') {
    return DeviceHealthState.working;
  }

  if (normalized == 'connected' ||
      normalized == 'online' ||
      normalized == 'ready' ||
      normalized == 'ออนไลน์' ||
      normalized == 'พร้อมใช้งาน' ||
      normalized == 'ใช้งานได้') {
    return isFresh || lastUpdatedAt == null
        ? DeviceHealthState.online
        : DeviceHealthState.offline;
  }

  if (normalized == 'offline' ||
      normalized == 'off' ||
      normalized == 'ออฟไลน์' ||
      normalized == 'ปิด' ||
      normalized == 'disconnected' ||
      normalized == 'stop' ||
      normalized == 'stopped') {
    return DeviceHealthState.offline;
  }

  return isFresh || lastUpdatedAt == null
      ? DeviceHealthState.online
      : DeviceHealthState.offline;
}

/// The "สถานะเครื่องกายภาพ" card — reused by the patient home tab and the
/// doctor home tab so both roles see the same live `esp32/led` status.
class DeviceStatusCard extends StatelessWidget {
  const DeviceStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: esp32Database.ref('esp32/led').onValue,
      builder: (context, snapshot) {
        final data = snapshot.data?.snapshot.value;
        final map = data is Map
            ? Map<String, dynamic>.from(data)
            : <String, dynamic>{};
        final rawStatus = map['status'] ?? map['state'];
        final status = rawStatus?.toString().toUpperCase() ?? '';
        final updatedAtValue =
            map['updatedAt'] ?? map['timestamp'] ?? map['lastSeen'] ?? map['time'];

        final deviceState = resolveDeviceHealth(
          rawStatus: rawStatus,
          updatedAtValue: updatedAtValue,
        );

        final label = switch (deviceState) {
          DeviceHealthState.working => 'กำลังทำงาน',
          DeviceHealthState.online => 'ออนไลน์',
          DeviceHealthState.offline => 'ออฟไลน์',
        };
        final color = switch (deviceState) {
          DeviceHealthState.working => const Color(0xff0d9984),
          DeviceHealthState.online => const Color(0xfff39a1d),
          DeviceHealthState.offline => const Color(0xff7a8d92),
        };

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120d7b82),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'สถานะเครื่องกายภาพ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff114d58),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'status: $status',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xff5f8d93),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
