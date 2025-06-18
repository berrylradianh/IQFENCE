import 'package:flutter/material.dart';
import 'package:iqfence/models/presensi_model.dart';
import 'package:iqfence/utils/date_utils.dart' as CustomDateUtils;
import 'package:lucide_icons/lucide_icons.dart';

class PresensiCard extends StatelessWidget {
  final String date;
  final String userName;
  final List<PresensiModel> presensiList;

  const PresensiCard({
    super.key,
    required this.date,
    required this.userName,
    required this.presensiList,
  });

  @override
  Widget build(BuildContext context) {
    final parsedDate = CustomDateUtils.DateUtils.parseDate(date); // Use prefix
    final formattedDate =
        CustomDateUtils.DateUtils.formatDate(parsedDate); // Use prefix

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$formattedDate - $userName',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...presensiList.map((presensi) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(
                      presensi.type == 'Presensi Pulang'
                          ? LucideIcons.logOut
                          : LucideIcons.logIn,
                      color: presensi.type == 'Presensi Pulang'
                          ? Colors.red
                          : Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${presensi.jamPresensi} di ${presensi.locationName}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'User: ${presensi.userName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
