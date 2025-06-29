import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditKaryawanScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> karyawanData;

  const EditKaryawanScreen({
    super.key,
    required this.docId,
    required this.karyawanData,
  });

  @override
  State<EditKaryawanScreen> createState() => _EditKaryawanScreenState();
}

class _EditKaryawanScreenState extends State<EditKaryawanScreen> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final Map<String, TimeOfDay?> _jamMulai = {
    'Senin': null,
    'Selasa': null,
    'Rabu': null,
    'Kamis': null,
    'Jumat': null,
    'Sabtu': null,
    'Minggu': null,
  };
  final Map<String, TimeOfDay?> _jamSelesai = {
    'Senin': null,
    'Selasa': null,
    'Rabu': null,
    'Kamis': null,
    'Jumat': null,
    'Sabtu': null,
    'Minggu': null,
  };
  final Map<String, bool> _hariLibur = {
    'Senin': false,
    'Selasa': false,
    'Rabu': false,
    'Kamis': false,
    'Jumat': false,
    'Sabtu': false,
    'Minggu': false,
  };
  final Map<String, bool> _samaDenganHariSebelumnya = {
    'Senin': false,
    'Selasa': false,
    'Rabu': false,
    'Kamis': false,
    'Jumat': false,
    'Sabtu': false,
    'Minggu': false,
  };
  bool _isLoading = false;
  List<Map<String, dynamic>> _locations = [];
  final List<String> _selectedLocationIds = [];

  @override
  void initState() {
    super.initState();
    // Inisialisasi field dengan data karyawan yang ada
    _namaController.text = widget.karyawanData['nama'] ?? '';
    _alamatController.text = widget.karyawanData['alamat'] ?? '';
    _emailController.text = ''; // Email akan diambil dari users collection
    _selectedLocationIds
        .addAll(List<String>.from(widget.karyawanData['location_ids'] ?? []));
    // Inisialisasi jam kerja dan status libur
    final jamKerja = widget.karyawanData['jam_kerja'] as Map<String, dynamic>?;
    if (jamKerja != null) {
      _jamMulai.forEach((hari, _) {
        final data = jamKerja[hari] as Map<String, dynamic>?;
        if (data != null) {
          _hariLibur[hari] = data['libur'] ?? false;
          if (!_hariLibur[hari]!) {
            _jamMulai[hari] = _parseTime(data['jam_mulai']);
            _jamSelesai[hari] = _parseTime(data['jam_selesai']);
          }
        }
      });
    }
    _fetchLocations();
    _fetchUserEmail();
  }

  Future<void> _fetchLocations() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('locations').get();
      setState(() {
        _locations = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'namaLokasi': doc.data()['namaLokasi'],
                  'koordinat': doc.data()['koordinat'],
                })
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengambil data lokasi: $e')),
      );
    }
  }

  Future<void> _fetchUserEmail() async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('karyawan_id', isEqualTo: widget.docId)
          .get();
      if (userSnapshot.docs.isNotEmpty) {
        setState(() {
          _emailController.text = userSnapshot.docs.first.data()['email'] ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengambil data email: $e')),
      );
    }
  }

  TimeOfDay? _parseTime(String? time) {
    if (time == null || time == '-' || time.isEmpty) return null;
    final parts = time.split(':');
    if (parts.length != 2) return null;
    try {
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickTime(String hari, bool isJamMulai) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isJamMulai) {
          _jamMulai[hari] = picked;
        } else {
          _jamSelesai[hari] = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getHariSebelumnya(String hari) {
    final hariList = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    final index = hariList.indexOf(hari);
    return hariList[index == 0 ? hariList.length - 1 : index - 1];
  }

  Future<void> _updateKaryawan() async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    final nama = _namaController.text.trim();
    final alamat = _alamatController.text.trim();
    final email = _emailController.text.trim();

    if (nama.isEmpty ||
        alamat.isEmpty ||
        email.isEmpty ||
        _selectedLocationIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Nama, alamat, email, dan minimal satu lokasi harus diisi')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Proses jadwal kerja
      final jamKerja = _jamMulai.keys.map((hari) {
        bool isLibur = _hariLibur[hari] ?? false;
        String jamMulai;
        String jamSelesai;

        if (isLibur) {
          jamMulai = '-';
          jamSelesai = '-';
        } else if (_samaDenganHariSebelumnya[hari] == true) {
          final hariSebelumnya = _getHariSebelumnya(hari);
          jamMulai = _formatTime(_jamMulai[hariSebelumnya]);
          jamSelesai = _formatTime(_jamSelesai[hariSebelumnya]);
        } else {
          jamMulai = _formatTime(_jamMulai[hari]);
          jamSelesai = _formatTime(_jamSelesai[hari]);
        }

        return MapEntry(
          hari,
          {
            'jam_mulai': jamMulai,
            'jam_selesai': jamSelesai,
            'libur': isLibur,
          },
        );
      });

      // Update karyawan di collection karyawan
      await FirebaseFirestore.instance
          .collection('karyawan')
          .doc(widget.docId)
          .update({
        'nama': nama,
        'alamat': alamat,
        'posisi': widget.karyawanData['posisi'] ?? 'Karyawan',
        'jam_kerja': Map.fromEntries(jamKerja),
        'location_ids': _selectedLocationIds,
      });

      // Update email di collection users
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('karyawan_id', isEqualTo: widget.docId)
          .get();
      if (userSnapshot.docs.isNotEmpty) {
        final userId = userSnapshot.docs.first.id;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'email': email,
          'nama': nama,
        });

        // Update email di Firebase Authentication
        final user = await FirebaseAuth.instance.fetchSignInMethodsForEmail(
            userSnapshot.docs.first.data()['email']);
        if (user.isNotEmpty) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null && currentUser.uid == userId) {
            await currentUser.updateEmail(email);
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Karyawan berhasil diperbarui')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Karyawan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              TextField(
                controller: _namaController,
                decoration: InputDecoration(
                  labelText: 'Nama',
                  hintText: 'Masukkan nama karyawan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _alamatController,
                decoration: InputDecoration(
                  labelText: 'Alamat',
                  hintText: 'Masukkan alamat karyawan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Masukkan email karyawan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Lokasi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _locations.isEmpty
                  ? const Text('Tidak ada lokasi tersedia')
                  : Wrap(
                      spacing: 8.0,
                      children: _locations.map((location) {
                        return FilterChip(
                          label: Text(location['namaLokasi']),
                          selected:
                              _selectedLocationIds.contains(location['id']),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedLocationIds.add(location['id']);
                              } else {
                                _selectedLocationIds.remove(location['id']);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 24),
              const Text(
                'Jadwal Kerja',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._jamMulai.keys.map((hari) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              hari,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _hariLibur[hari] == true ||
                                            _samaDenganHariSebelumnya[hari] ==
                                                true
                                        ? null
                                        : () => _pickTime(hari, true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 10),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _samaDenganHariSebelumnya[hari] == true
                                            ? _formatTime(_jamMulai[
                                                _getHariSebelumnya(hari)])
                                            : _formatTime(_jamMulai[hari]),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _hariLibur[hari] == true ||
                                                  _samaDenganHariSebelumnya[
                                                          hari] ==
                                                      true
                                              ? Colors.grey
                                              : Colors.black,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _hariLibur[hari] == true ||
                                            _samaDenganHariSebelumnya[hari] ==
                                                true
                                        ? null
                                        : () => _pickTime(hari, false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 10),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _samaDenganHariSebelumnya[hari] == true
                                            ? _formatTime(_jamSelesai[
                                                _getHariSebelumnya(hari)])
                                            : _formatTime(_jamSelesai[hari]),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _hariLibur[hari] == true ||
                                                  _samaDenganHariSebelumnya[
                                                          hari] ==
                                                      true
                                              ? Colors.grey
                                              : Colors.black,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Checkbox(
                            value: _hariLibur[hari],
                            onChanged: (value) {
                              setState(() {
                                _hariLibur[hari] = value ?? false;
                                if (value == true) {
                                  _jamMulai[hari] = null;
                                  _jamSelesai[hari] = null;
                                  _samaDenganHariSebelumnya[hari] = false;
                                }
                              });
                            },
                          ),
                          const Text('Libur'),
                        ],
                      ),
                      if (hari != 'Senin')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Checkbox(
                              value: _samaDenganHariSebelumnya[hari],
                              onChanged: _hariLibur[hari] == true
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _samaDenganHariSebelumnya[hari] =
                                            value ?? false;
                                        if (value == true) {
                                          final hariSebelumnya =
                                              _getHariSebelumnya(hari);
                                          _jamMulai[hari] =
                                              _jamMulai[hariSebelumnya];
                                          _jamSelesai[hari] =
                                              _jamSelesai[hariSebelumnya];
                                        }
                                      });
                                    },
                            ),
                            const Text('Sama dengan hari sebelumnya'),
                          ],
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateKaryawan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Simpan', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
