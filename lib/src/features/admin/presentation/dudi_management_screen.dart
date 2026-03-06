import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_repository.dart';

class DudiManagementScreen extends ConsumerStatefulWidget {
  const DudiManagementScreen({super.key});

  @override
  ConsumerState<DudiManagementScreen> createState() =>
      _DudiManagementScreenState();
}

class _DudiManagementScreenState extends ConsumerState<DudiManagementScreen> {
  int _currentPage = 0;
  final int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(paginatedCompaniesProvider(_currentPage));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Manajemen DUDI (Perusahaan)",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCompanyDialog(context),
                icon: const Icon(Icons.add),
                label: const Text("Tambah Perusahaan"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: companiesAsync.when(
                data: (companies) {
                  if (companies.isEmpty) {
                    return const Center(
                      child: Text("Belum ada data perusahaan."),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text("Nama Perusahaan")),
                                DataColumn(label: Text("Alamat")),
                                DataColumn(label: Text("Koordinat")),
                                DataColumn(label: Text("Radius (m)")),
                                DataColumn(label: Text("Aksi")),
                              ],
                              rows: companies.map((company) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(company['name'] ?? '-')),
                                    DataCell(
                                      Text(
                                        company['address'] ?? '-',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        "${company['latitude']}, ${company['longitude']}",
                                      ),
                                    ),
                                    DataCell(
                                      Text("${company['radius_meter']}"),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () => _showCompanyDialog(
                                              context,
                                              company: company,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => _deleteCompany(
                                              context,
                                              company['id'],
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
                              onPressed: companies.length == _pageSize
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

  void _showCompanyDialog(
    BuildContext context, {
    Map<String, dynamic>? company,
  }) {
    final isEditing = company != null;
    final nameController = TextEditingController(text: company?['name']);
    final addressController = TextEditingController(text: company?['address']);
    final latController = TextEditingController(
      text: company?['latitude']?.toString() ?? '-7.004634',
    );
    final longController = TextEditingController(
      text: company?['longitude']?.toString() ?? '107.266168',
    );
    final radiusController = TextEditingController(
      text: company?['radius_meter']?.toString() ?? '100',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? "Edit Perusahaan" : "Tambah Perusahaan"),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Nama Perusahaan",
                  ),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: "Alamat Lengkap",
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latController,
                        decoration: const InputDecoration(
                          labelText: "Latitude",
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: longController,
                        decoration: const InputDecoration(
                          labelText: "Longitude",
                        ),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: radiusController,
                  decoration: const InputDecoration(
                    labelText: "Radius Toleransi (Meter)",
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Tips: Gunakan Google Maps untuk menyalin titik koordinat latitude & longitude.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'name': nameController.text,
                'address': addressController.text,
                'latitude': double.tryParse(latController.text) ?? 0.0,
                'longitude': double.tryParse(longController.text) ?? 0.0,
                'radius_meter': int.tryParse(radiusController.text) ?? 100,
              };

              if (isEditing) {
                await ref
                    .read(adminRepositoryProvider)
                    .updateCompany(company['id'], data);
              } else {
                await ref.read(adminRepositoryProvider).addCompany(data);
              }

              ref.invalidate(paginatedCompaniesProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _deleteCompany(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Perusahaan?"),
        content: const Text("Data DUDI akan dihapus permanen."),
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
              await ref.read(adminRepositoryProvider).deleteCompany(id);
              ref.invalidate(paginatedCompaniesProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }
}
