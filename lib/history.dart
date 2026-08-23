import 'package:flutter/material.dart';

import 'doctor_repository.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, this.patientUserId});

  /// When set, only this patient's own treatment history is shown.
  /// When null (e.g. the admin overview tab), every patient's history shows.
  final String? patientUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8fcfd),
      body: SafeArea(
        child: Column(
          children: [
            const _HistoryHeader(),
            Expanded(
              child: StreamBuilder<List<TreatmentHistoryItem>>(
                stream: patientUserId != null
                    ? DoctorRepository.watchTreatmentsForPatientUserId(
                        patientUserId!,
                      )
                    : DoctorRepository.watchAllTreatments(),
                builder: (context, snapshot) {
                  final records = snapshot.data ?? const [];
                  if (records.isEmpty) {
                    return const Center(
                      child: Text(
                        'ยังไม่มีประวัติการกายภาพบำบัด',
                        style: TextStyle(color: Color(0xff6b8e91)),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    itemCount: records.length,
                    itemBuilder: (context, index) => _TreatmentCard(
                      record: records[index],
                      showPatientName: patientUserId == null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(color: Color(0x0d246c70), blurRadius: 5, offset: Offset(0, 2)),
      ],
    ),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.chevron_left_rounded, color: Color(0xff167f88)),
        ),
        const SizedBox(width: 2),
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ประวัติการกายภาพบำบัด',
                style: TextStyle(
                  fontSize: 15,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff155a62),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'ตรวจสอบประวัติการรักษากายภาพบำบัด',
                style: TextStyle(fontSize: 8.5, color: Color(0xff72979b)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TreatmentCard extends StatelessWidget {
  const _TreatmentCard({required this.record, required this.showPatientName});

  final TreatmentHistoryItem record;
  final bool showPatientName;

  String _doctorName(String loginId) {
    final doctor = DoctorRepository.doctors.firstWhere(
      (item) => item.loginId == loginId,
      orElse: () => const DoctorAccount(name: 'ไม่ทราบหมอ', email: '', loginId: ''),
    );
    return doctor.name;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x0b246c70), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xff0d9984)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  record.treatmentType,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff114d58),
                  ),
                ),
              ),
              Text(
                record.dateIso,
                style: const TextStyle(fontSize: 10, color: Color(0xff6e9ca1)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (showPatientName) ...[
            _InfoRow(icon: Icons.person_outline_rounded, text: record.patientName),
            const SizedBox(height: 4),
          ],
          _InfoRow(
            icon: Icons.medical_services_outlined,
            text: 'หมอ ${_doctorName(record.doctorLoginId)}',
          ),
          const SizedBox(height: 4),
          _InfoRow(
            icon: Icons.accessibility_new_rounded,
            text: '${record.bodyPart} • ${record.setCount} เซ็ต',
          ),
          if (record.note != null && record.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _InfoRow(icon: Icons.notes_rounded, text: record.note!),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 13, color: const Color(0xff21a5ae)),
      const SizedBox(width: 5),
      Expanded(
        child: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xff376f76))),
      ),
    ],
  );
}
