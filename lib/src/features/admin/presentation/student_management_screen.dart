import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_repository.dart';
import '../../../constants/app_constants.dart';

class StudentManagementScreen extends ConsumerStatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  ConsumerState<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState
    extends ConsumerState<StudentManagementScreen> {
  int _currentPage = 0;
  final int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(paginatedStudentsProvider(_currentPage));
    final companiesAsync = ref.watch(
      allCompaniesProvider,
    ); // Need companies for dropdown

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Manajemen Siswa",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Fitur Tambah Siswa via Admin memerlukan akses API khusus. Siswa disarankan Register sendiri di Mobile App.",
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Tambah Siswa"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: studentsAsync.when(
                data: (students) {
                  if (students.isEmpty) {
                    return const Center(child: Text("Belum ada data siswa"));
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 20,
                              columns: const [
                                DataColumn(label: Text("Nama Lengkap")),
                                DataColumn(label: Text("NISN")),
                                DataColumn(label: Text("Kelas")),
                                DataColumn(
                                  label: Text("Status"),
                                ), // Status Column
                                DataColumn(label: Text("Lokasi PKL")),
                                DataColumn(label: Text("Aksi")),
                              ],
                              rows: students.map((student) {
                                // Extract Placement Info
                                String placementName = "-";
                                if (student['placements'] != null &&
                                    (student['placements'] as List)
                                        .isNotEmpty) {
                                  final p =
                                      (student['placements'] as List).first;
                                  if (p['companies'] != null) {
                                    placementName = p['companies']['name'];
                                  }
                                }

                                // Extract Status
                                String status = student['status'] ?? 'active';
                                Color statusColor = Colors.green;
                                if (status == 'pending') {
                                  statusColor = Colors.orange;
                                }
                                if (status == 'rejected') {
                                  statusColor = Colors.red;
                                }

                                return DataRow(
                                  cells: [
                                    DataCell(Text(student['full_name'] ?? '-')),
                                    DataCell(Text(student['nisn'] ?? '-')),
                                    DataCell(
                                      Text(student['class_name'] ?? '-'),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: statusColor,
                                          ),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: placementName == '-'
                                              ? Colors.grey[200]
                                              : Colors.green[100],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          placementName,
                                          style: TextStyle(
                                            color: placementName == '-'
                                                ? Colors.grey
                                                : Colors.green[800],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          if (status == 'pending') ...[
                                            Tooltip(
                                              message: "Approve Siswa",
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green,
                                                ),
                                                onPressed: () async {
                                                  await ref
                                                      .read(
                                                        adminRepositoryProvider,
                                                      )
                                                      .updateStudentStatus(
                                                        student['id'],
                                                        'active',
                                                      );
                                                  ref.invalidate(
                                                    paginatedStudentsProvider,
                                                  );
                                                },
                                              ),
                                            ),
                                            Tooltip(
                                              message: "Reject Siswa",
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.cancel,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () async {
                                                  if (!context.mounted) return;
                                                  // Confirm reject
                                                  showDialog(
                                                    context: context,
                                                    builder: (c) => AlertDialog(
                                                      title: const Text(
                                                        "Tolak Pendaftaran?",
                                                      ),
                                                      content: const Text(
                                                        "Siswa tidak akan bisa login.",
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(c),
                                                          child: const Text(
                                                            "Batal",
                                                          ),
                                                        ),
                                                        ElevatedButton(
                                                          style:
                                                              ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    Colors.red,
                                                                foregroundColor:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                          onPressed: () async {
                                                            await ref
                                                                .read(
                                                                  adminRepositoryProvider,
                                                                )
                                                                .updateStudentStatus(
                                                                  student['id'],
                                                                  'rejected',
                                                                );
                                                            ref.invalidate(
                                                              paginatedStudentsProvider,
                                                            );
                                                            if (c.mounted) {
                                                              Navigator.pop(c);
                                                            }
                                                          },
                                                          child: const Text(
                                                            "Tolak",
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            const VerticalDivider(),
                                          ],
                                          Tooltip(
                                            message: "Edit Profil & Penempatan",
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.blue,
                                              ),
                                              onPressed: () => _showEditDialog(
                                                context,
                                                student,
                                                companiesAsync,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Tooltip(
                                            message: "Hapus Siswa",
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed: () => _deleteStudent(
                                                context,
                                                student['id'],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      // Pagination
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _currentPage > 0
                                  ? () => setState(() => _currentPage--)
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text("Halaman ${_currentPage + 1}"),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: students.length == _pageSize
                                  ? () => setState(() => _currentPage++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error: $e")),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    Map<String, dynamic> student,
    AsyncValue<List<Map<String, dynamic>>> companiesAsync,
  ) {
    final nameController = TextEditingController(text: student['full_name']);
    final nisnController = TextEditingController(text: student['nisn']);

    // Initial Class
    String? selectedClass = student['class_name'];
    if (selectedClass != null &&
        !AppConstants.schoolClasses.contains(selectedClass)) {
      selectedClass = null;
    }

    // Initial Company ID
    int? selectedCompanyId;
    if (student['placements'] != null &&
        (student['placements'] as List).isNotEmpty) {
      final p = (student['placements'] as List).first;
      if (p['company_id'] != null) {
        selectedCompanyId = p['company_id'];
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Edit Data Siswa"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Nama Lengkap",
                    ),
                  ),
                  TextField(
                    controller: nisnController,
                    decoration: const InputDecoration(labelText: "NISN"),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey(selectedClass),
                    initialValue: selectedClass,
                    decoration: const InputDecoration(labelText: "Kelas"),
                    items: AppConstants.schoolClasses.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedClass = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Tempat PKL (DUDI):",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  companiesAsync.when(
                    data: (companies) {
                      return DropdownButton<int>(
                        isExpanded: true,
                        hint: const Text("Pilih Perusahaan"),
                        value: selectedCompanyId,
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text("- Belum Ada -"),
                          ),
                          ...companies.map((c) {
                            return DropdownMenuItem<int>(
                              value: c['id'],
                              child: Text(c['name']),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() => selectedCompanyId = val);
                        },
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => const Text("Gagal memuat list DUDI"),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  // 1. Update Profile
                  await ref.read(adminRepositoryProvider).updateStudent(
                    student['id'],
                    {
                      'full_name': nameController.text,
                      'nisn': nisnController.text,
                      'class_name': selectedClass, // Use variable
                    },
                  );

                  // 2. Update Placement (if changed)
                  if (selectedCompanyId != null) {
                    await ref
                        .read(adminRepositoryProvider)
                        .assignStudentPlacement(
                          student['id'],
                          selectedCompanyId!,
                        );
                  }

                  ref.invalidate(paginatedStudentsProvider); // Refresh list
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Simpan"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteStudent(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Siswa?"),
        content: const Text("Data profil siswa akan dihapus."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref.read(adminRepositoryProvider).deleteStudent(id);
              ref.invalidate(paginatedStudentsProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }
}
