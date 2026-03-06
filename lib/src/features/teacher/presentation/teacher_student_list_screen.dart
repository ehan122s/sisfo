import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/teacher_repository.dart';

class TeacherStudentListScreen extends ConsumerStatefulWidget {
  const TeacherStudentListScreen({super.key});

  @override
  ConsumerState<TeacherStudentListScreen> createState() =>
      _TeacherStudentListScreenState();
}

class _TeacherStudentListScreenState
    extends ConsumerState<TeacherStudentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(managedStudentsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('Daftar Siswa Binaan'), elevation: 0),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari siswa...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: studentsAsync.when(
              data: (students) {
                final filtered = students.where((s) {
                  final name = (s['full_name'] ?? '').toLowerCase();
                  final company = (s['company_name'] ?? '').toLowerCase();
                  return name.contains(_searchQuery) ||
                      company.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Siswa tidak ditemukan.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final student = filtered[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: student['avatar_url'] != null
                              ? NetworkImage(student['avatar_url'])
                              : null,
                          child: student['avatar_url'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(student['full_name'] ?? '-'),
                        subtitle: Text(
                          '${student['class_name'] ?? '-'} • ${student['company_name']}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.go(
                            '/teacher/dashboard/students/${student['student_id']}',
                            extra: student, // Pass student data object
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
