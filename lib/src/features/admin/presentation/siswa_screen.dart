import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SiswaScreen extends StatefulWidget {
  const SiswaScreen({super.key});

  @override
  State<SiswaScreen> createState() => _SiswaScreenState();
}

class _SiswaScreenState extends State<SiswaScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  String _searchQuery = "";
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _companies = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _loadCompanies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Load companies dari DUDI
  Future<void> _loadCompanies() async {
    if (!mounted) return;
    
    try {
      final response = await supabase
          .from('companies')
          .select('id, name, address, latitude, longitude, radius_meter')
          .order('name', ascending: true);
      
      if (!mounted) return;
      setState(() {
        _companies = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error loading companies: $e');
    }
  }

  // Load siswa
  Future<void> _loadStudents() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await supabase
          .from('profiles')
          .select('''
            id, full_name, nisn, class_name, status, is_verified, avatar_url, role,
            placements(id, company_id, start_date, end_date, status),
            companies(id, name, address)
          ''')
          .eq('role', 'student')
          .order('full_name', ascending: true);

      if (!mounted) return;

      setState(() {
        _students = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading students: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([_loadStudents(), _loadCompanies()]);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Data diperbarui'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // Helper: ambil placement pertama
  Map<String, dynamic>? _getPlacement(Map<String, dynamic> student) {
    final placements = student['placements'];
    if (placements == null) return null;
    if (placements is List && placements.isNotEmpty) {
      return placements.first as Map<String, dynamic>;
    }
    return null;
  }

  // Helper: nama perusahaan
  String? _getCompanyName(Map<String, dynamic> student) {
    final placement = _getPlacement(student);
    if (placement == null) return null;
    final company = placement['companies'];
    if (company == null) return null;
    return (company as Map<String, dynamic>)['name']?.toString();
  }

  // Helper: company ID
  int? _getCompanyId(Map<String, dynamic> student) {
    final placement = _getPlacement(student);
    if (placement == null) return null;
    return placement['company_id'] as int?;
  }

  List<Map<String, dynamic>> _filterStudents(List<Map<String, dynamic>> data) {
    if (_searchQuery.isEmpty) return data;

    final query = _searchQuery.toLowerCase();
    return data.where((s) {
      final name = (s['full_name'] ?? '').toString().toLowerCase();
      final nisn = (s['nisn'] ?? '').toString().toLowerCase();
      final className = (s['class_name'] ?? '').toString().toLowerCase();
      final company = (_getCompanyName(s) ?? '').toLowerCase();

      return name.contains(query) ||
          nisn.contains(query) ||
          className.contains(query) ||
          company.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStudentForm(),
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Tambah Siswa', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  "Student Directory",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      '${_students.length}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text("Kelola data siswa & penempatan PKL", style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          
          // Search bar
          TextField(
            onChanged: (v) {
              if (mounted) setState(() => _searchQuery = v);
            },
            decoration: InputDecoration(
              hintText: "Cari nama, NISN, kelas, perusahaan...",
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0F172A), size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        if (mounted) setState(() => _searchQuery = "");
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  // BODY
  Widget _buildBody() {
    if (_isLoading && _students.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator.adaptive(),
            SizedBox(height: 20),
            Text('Memuat data...', style: TextStyle(color: Color(0xFF64748B))),
          ],
        ),
      );
    }

    if (_errorMessage != null && _students.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
              ),
              const SizedBox(height: 16),
              const Text('Gagal Memuat Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                _errorMessage!.length > 100 
                    ? '${_errorMessage!.substring(0, 100)}...' 
                    : _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline_rounded, size: 80, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text('Belum Ada Data Siswa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Tap tombol di bawah untuk menambahkan', style: TextStyle(color: Color(0xFF94A3B8))),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showStudentForm(),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Tambah Siswa Pertama'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final filteredStudents = _filterStudents(_students);

    if (filteredStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 80, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text('Tidak Ditemukan: "$_searchQuery"', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Coba kata kunci lain', style: TextStyle(color: Color(0xFF94A3B8))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: filteredStudents.length,
        itemBuilder: (context, i) => _studentCard(filteredStudents[i]),
      ),
    );
  }

  Widget _studentCard(Map<String, dynamic> data) {
    final id = data['id'].toString();
    final fullName = data['full_name'] ?? 'Unknown';
    final className = data['class_name'] ?? 'Belum ada kelas';
    final nisn = data['nisn'] ?? '-';
    final status = data['status'] ?? 'active';
    final avatarUrl = data['avatar_url'];
    final isVerified = data['is_verified'] == true;
    final isActive = status == 'active';
    final companyName = _getCompanyName(data);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.blue, Color(0xFF1D4ED8)]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.25), blurRadius: 8)],
                      ),
                      child: avatarUrl != null && avatarUrl.toString().isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                              ),
                            ),
                    ),
                    if (isVerified)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.check, size: 10, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              fullName,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(isActive: isActive),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.school_outlined, size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              className,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.badge_outlined, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            nisn,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      if (companyName != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.business_center, size: 11, color: Colors.purple.shade700),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  companyName,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.purple.shade700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _actionBtnSmall(
                      label: 'Edit',
                      icon: Icons.edit_note_rounded,
                      color: Colors.blue,
                      onTap: () => _showStudentForm(studentData: data),
                    ),
                  ),
                  Container(width: 1, height: 36, color: Colors.grey.shade200),
                  Expanded(
                    child: _actionBtnSmall(
                      label: 'PKL',
                      icon: Icons.business_center_rounded,
                      color: Colors.purple,
                      onTap: () => _showPlacementForm(studentData: data),
                    ),
                  ),
                  Container(width: 1, height: 36, color: Colors.grey.shade200),
                  Expanded(
                    child: _actionBtnSmall(
                      label: isActive ? 'Off' : 'On',
                      icon: isActive ? Icons.toggle_off : Icons.toggle_on,
                      color: isActive ? Colors.orange : Colors.green,
                      onTap: () => _toggleStatus(id, !isActive),
                    ),
                  ),
                  Container(width: 1, height: 36, color: Colors.grey.shade200),
                  Expanded(
                    child: _actionBtnSmall(
                      label: 'Hapus',
                      icon: Icons.delete_forever_rounded,
                      color: Colors.red,
                      onTap: () => _confirmDelete(id, fullName),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtnSmall({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge({required bool isActive}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: 10,
            color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 2),
          Text(
            isActive ? 'Aktif' : 'Off',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FORM SISWA
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _showStudentForm({Map<String, dynamic>? studentData}) async {
    if (!mounted) return;

    final isEditing = studentData != null;
    
    String currentName = studentData?['full_name'] ?? '';
    String currentNisn = studentData?['nisn'] ?? '';
    String currentClass = studentData?['class_name'] ?? '';
    String currentPhone = studentData?['phone_number'] ?? '';
    String selectedStatus = studentData?['status'] ?? 'active';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final nameController = TextEditingController(text: currentName);
        final nisnController = TextEditingController(text: currentNisn);
        final classController = TextEditingController(text: currentClass);
        final phoneController = TextEditingController(text: currentPhone);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHeader(
                    context: ctx,
                    title: isEditing ? '✏️ Edit Siswa' : '➕ Tambah Siswa Baru',
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Column(
                        children: [
                          _txtField(ctrl: nameController, label: 'Nama Lengkap *', hint: 'Masukkan nama lengkap', icon: Icons.person_outline),
                          const SizedBox(height: 14),
                          
                          _txtField(ctrl: nisnController, label: 'NISN *', hint: 'Nomor Induk Siswa Nasional', icon: Icons.badge_outlined, kbType: TextInputType.number),
                          const SizedBox(height: 14),
                          
                          _txtField(ctrl: classController, label: 'Kelas *', hint: 'Contoh: XII RPL 1', icon: Icons.school_outlined),
                          const SizedBox(height: 14),
                          
                          _txtField(ctrl: phoneController, label: 'No. Telepon', hint: '08123456789', icon: Icons.phone_outlined, kbType: TextInputType.phone),
                          const SizedBox(height: 16),
                          
                          DropdownButtonFormField<String>(
                            value: selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              prefixIcon: const Icon(Icons.toggle_on_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'active', child: Text('Aktif')),
                              DropdownMenuItem(value: 'inactive', child: Text('Nonaktif')),
                              DropdownMenuItem(value: 'graduated', child: Text('Lulus')),
                            ],
                            onChanged: (v) {
                              setModalState(() { selectedStatus = v!; });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  _submitBtn(
                    label: isEditing ? 'Simpan Perubahan' : 'Tambah Siswa',
                    color: isEditing ? Colors.orange : Colors.blue,
                    icon: isEditing ? Icons.save : Icons.add_circle_outline,
                    onTap: () async {
                      if (nameController.text.isEmpty ||
                          nisnController.text.isEmpty ||
                          classController.text.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: const Text('⚠️ Harap isi field wajib (*)'),
                            backgroundColor: Colors.red.shade700,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                        return;
                      }
                      
                      final payload = {
                        'full_name': nameController.text.trim(),
                        'nisn': nisnController.text.trim(),
                        'class_name': classController.text.trim(),
                        'phone_number': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                        'status': selectedStatus,
                        'role': 'student',
                      };
                      
                      Navigator.pop(ctx);
                      
                      if (isEditing) {
                        await _updateStudent(id: studentData!['id'], data: payload);
                      } else {
                        // ✅ FIX: Gunakan RPC function bukan admin API
                        await _createStudentWithRpc(data: payload);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FORM PENEMPATAN
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _showPlacementForm({required Map<String, dynamic> studentData}) async {
    if (!mounted) return;

    final studentId = studentData['id'];
    final studentName = studentData['full_name'] ?? 'Siswa';

    final existingPlacement = _getPlacement(studentData);
    Map<String, dynamic>? existingCompany;
    int? existingCompanyId;
    
    if (existingPlacement != null) {
      existingCompanyId = existingPlacement['company_id'] as int?;
      if (existingCompanyId != null) {
        try {
          existingCompany = _companies.firstWhere((c) => c['id'] == existingCompanyId);
        } catch (_) {
          existingCompany = null;
        }
      }
    }

    final isEditing = existingPlacement != null;
    int? selectedCompanyId = existingCompanyId;
    String selectedCompanyName = existingCompany?['name'] ?? '';
    
    String currentAddress = existingCompany?['address'] ?? '';
    String currentLat = existingCompany?['latitude']?.toString() ?? '';
    String currentLng = existingCompany?['longitude']?.toString() ?? '';
    String currentRadius = existingCompany?['radius_meter']?.toString() ?? '100';
    String currentStartDate = existingPlacement?['start_date'] ?? '';
    String currentEndDate = existingPlacement?['end_date'] ?? '';
    String selectedStatus = existingPlacement?['status'] ?? 'active';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final addressCtrl = TextEditingController(text: currentAddress);
        final latCtrl = TextEditingController(text: currentLat);
        final lngCtrl = TextEditingController(text: currentLng);
        final radiusCtrl = TextEditingController(text: currentRadius);
        final startDateCtrl = TextEditingController(text: currentStartDate);
        final endDateCtrl = TextEditingController(text: currentEndDate);
        final searchCtrl = TextEditingController();

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.9,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHeader(
                    context: ctx,
                    title: isEditing ? '🏢 Edit Penempatan PKL' : '🏢 Atur Penempatan PKL',
                    subtitle: 'Siswa: $studentName',
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _secTitle('🏭 Pilih Perusahaan (DUDI)'),
                          const SizedBox(height: 8),
                          
                          TextField(
                            controller: searchCtrl,
                            onChanged: (_) => setModalState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Cari perusahaan...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        searchCtrl.clear();
                                        setModalState(() {});
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                          const SizedBox(height: 10),
                          
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.purple.shade300, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.purple.shade50,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: selectedCompanyId,
                                icon: const Icon(Icons.business_center, color: Colors.purple, size: 20),
                                isExpanded: true,
                                hint: const Text('Pilih perusahaan...', style: TextStyle(fontSize: 14)),
                                items: _companies
                                    .where((c) {
                                      if (searchCtrl.text.isEmpty) return true;
                                      final name = (c['name'] ?? '').toString().toLowerCase();
                                      return name.contains(searchCtrl.text.toLowerCase());
                                    })
                                    .map<DropdownMenuItem<int>>((company) {
                                  final cid = company['id'];
                                  final cname = company['name'] ?? 'Perusahaan';
                                  
                                  return DropdownMenuItem<int>(
                                    value: cid,
                                    child: Row(
                                      children: [
                                        Icon(Icons.business, size: 18, color: Colors.purple.shade700),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(cname, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                                              Text(company['address'] ?? '', style: TextStyle(fontSize: 10, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis, maxLines: 1),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (int? newVal) {
                                  if (newVal == null) return;
                                  
                                  setModalState(() {
                                    selectedCompanyId = newVal;
                                    try {
                                      final sel = _companies.firstWhere((c) => c['id'] == newVal);
                                      selectedCompanyName = sel['name'] ?? '';
                                      addressCtrl.text = sel['address'] ?? '';
                                      latCtrl.text = sel['latitude']?.toString() ?? '';
                                      lngCtrl.text = sel['longitude']?.toString() ?? '';
                                      radiusCtrl.text = sel['radius_meter']?.toString() ?? '100';
                                    } catch (_) {}
                                  });
                                },
                              ),
                            ),
                          ),
                          
                          if (selectedCompanyId != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Terpilih: $selectedCompanyName',
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF166534), fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          if (selectedCompanyId == null) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final newId = await _showAddCompanyDialog(ctx);
                                if (newId != null) {
                                  await _loadCompanies();
                                  setModalState(() {
                                    selectedCompanyId = newId;
                                    try {
                                      final sel = _companies.firstWhere((c) => c['id'] == newId);
                                      selectedCompanyName = sel['name'] ?? '';
                                      addressCtrl.text = sel['address'] ?? '';
                                      latCtrl.text = sel['latitude']?.toString() ?? '';
                                      lngCtrl.text = sel['longitude']?.toString() ?? '';
                                      radiusCtrl.text = sel['radius_meter']?.toString() ?? '100';
                                    } catch (_) {}
                                  });
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.blue.shade300, width: 1.5),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.blue.shade50,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_business, color: Color(0xFF1D4ED8), size: 16),
                                    SizedBox(width: 8),
                                    Text('+ Tambah Perusahaan ke DUDI', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8), fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          
                          _secTitle('📍 Detail Lokasi'),
                          const SizedBox(height: 10),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _txtField(ctrl: latCtrl, label: 'Latitude', hint: '-6.2088', icon: Icons.my_location, kbType: TextInputType.numberWithOptions(decimal: true)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _txtField(ctrl: lngCtrl, label: 'Longitude', hint: '106.8456', icon: Icons.explore, kbType: TextInputType.numberWithOptions(decimal: true)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          
                          _txtField(ctrl: radiusCtrl, label: 'Radius Absen (m)', hint: '100', icon: Icons.radio_button_checked, kbType: TextInputType.number),
                          const SizedBox(height: 16),
                          
                          _secTitle('📅 Periode PKL'),
                          const SizedBox(height: 10),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _txtField(ctrl: startDateCtrl, label: 'Mulai', hint: 'YYYY-MM-DD', icon: Icons.calendar_today),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _txtField(ctrl: endDateCtrl, label: 'Selesai', hint: 'YYYY-MM-DD', icon: Icons.event),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          DropdownButtonFormField<String>(
                            value: selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status Penempatan',
                              prefixIcon: const Icon(Icons.timeline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'active', child: Text('🟢 Aktif')),
                              DropdownMenuItem(value: 'completed', child: Text('✅ Selesai')),
                              DropdownMenuItem(value: 'terminated', child: Text('🔴 Dihentikan')),
                            ],
                            onChanged: (v) { setModalState(() => selectedStatus = v!); },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  _submitBtn(
                    label: isEditing ? 'Update Penempatan' : 'Simpan Penempatan',
                    color: Colors.purple,
                    icon: isEditing ? Icons.save : Icons.business_center,
                    onTap: () async {
                      if (selectedCompanyId == null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: const Text('⚠️ Pilih perusahaan dari DUDI!'),
                            backgroundColor: Colors.red.shade700,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                        return;
                      }
                      
                      Navigator.pop(ctx);
                      
                      try {
                        final payload = {
                          'student_id': studentId,
                          'company_id': selectedCompanyId,
                          'start_date': startDateCtrl.text.trim().isEmpty ? null : startDateCtrl.text.trim(),
                          'end_date': endDateCtrl.text.trim().isEmpty ? null : endDateCtrl.text.trim(),
                          'status': selectedStatus,
                        };
                        
                        if (isEditing) {
                          await supabase.from('placements').update(payload).eq('id', existingPlacement!['id']);
                          if (mounted) _showMessage('✅ Penempatan berhasil diperbarui!');
                        } else {
                          await supabase.from('placements').insert(payload);
                          if (mounted) _showMessage('✅ Penempatan berhasil ditambahkan!');
                        }
                        
                        if (mounted) await _loadStudents();
                      } catch (e) {
                        if (mounted) _showMessage('❌ Error: $e', isError: true);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<int?> _showAddCompanyDialog(BuildContext parentCtx) async {
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final latCtrl = TextEditingController(text: '-6.2088');
    final lngCtrl = TextEditingController(text: '106.8456');
    final radiusCtrl = TextEditingController(text: '100');

    final result = await showDialog<int>(
      context: parentCtx,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_business, color: Colors.purple),
              SizedBox(width: 12),
              Flexible(child: Text('Tambah Perusahaan', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _txtField(ctrl: nameCtrl, label: 'Nama Perusahaan *', hint: 'PT. Contoh Indonesia', icon: Icons.business),
                const SizedBox(height: 12),
                _txtField(ctrl: addrCtrl, label: 'Alamat *', hint: 'Jl. Contoh No. 123', icon: Icons.location_on, maxLines: 2),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _txtField(ctrl: latCtrl, label: 'Latitude', hint: '-6.2088', icon: Icons.my_location, kbType: TextInputType.numberWithOptions(decimal: true))),
                    const SizedBox(width: 10),
                    Expanded(child: _txtField(ctrl: lngCtrl, label: 'Longitude', hint: '106.8456', icon: Icons.explore, kbType: TextInputType.numberWithOptions(decimal: true))),
                  ],
                ),
                const SizedBox(height: 12),
                _txtField(ctrl: radiusCtrl, label: 'Radius (m)', hint: '100', icon: Icons.radio_button_checked, kbType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || addrCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    SnackBar(content: const Text('⚠️ Nama & alamat wajib diisi!'), backgroundColor: Colors.red.shade700),
                  );
                  return;
                }
                
                try {
                  final res = await supabase.from('companies').insert({
                    'name': nameCtrl.text.trim(),
                    'address': addrCtrl.text.trim(),
                    'latitude': double.tryParse(latCtrl.text) ?? 0.0,
                    'longitude': double.tryParse(lngCtrl.text) ?? 0.0,
                    'radius_meter': int.tryParse(radiusCtrl.text) ?? 100,
                  }).select('id').single();
                  
                  if (dialogCtx.mounted) {
                    Navigator.of(dialogCtx).pop(res['id'] as int);
                  }
                } catch (e) {
                  if (dialogCtx.mounted) {
                    ScaffoldMessenger.of(dialogCtx).showSnackBar(
                      SnackBar(content: Text('❌ Gagal: $e'), backgroundColor: Colors.red.shade700),
                    );
                  }
                }
              },
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    nameCtrl.dispose();
    addrCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
    radiusCtrl.dispose();
    
    return result;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _sheetHeader({required BuildContext context, required String title, String? subtitle}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _secTitle(String title) =>
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold));

  Widget _txtField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? kbType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: kbType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }

  Widget _submitBtn({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: Icon(icon, size: 20),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CRUD OPERATIONS - FIXED: Menggunakan RPC function
  // ══════════════════════════════════════════════════════════════════════════

  /// ✅ FIXED: Gunakan RPC function untuk create student
  Future<void> _createStudentWithRpc({required Map<String, dynamic> data}) async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);
      
      // Generate email dan password dari NISN
      final nisn = data['nisn'] as String? ?? '';
      final email = '${nisn.toLowerCase()}@epkl.local';
      final password = 'Siswa${nisn.padRight(8, '0').substring(0, 8)}';
      
      // ✅ Gunakan RPC function - TIDAK perlu service role key!
      final response = await supabase.rpc('create_student_with_auth', params: {
        'p_email': email,
        'p_password': password,
        'p_full_name': data['full_name'],
        'p_nisn': data['nisn'],
        'p_class_name': data['class_name'],
        'p_phone_number': data['phone_number'],
        'p_status': data['status'],
      });
      
      if (!mounted) return;
      
      // Check response
      final success = response['success'] as bool? ?? false;
      if (!success) {
        final errorMsg = response['error'] ?? 'Unknown error';
        final errorCode = response['code'] ?? 'ERROR';
        
        if (errorCode == 'DUPLICATE') {
          _showMessage('⚠️ $errorMsg', isError: true);
        } else {
          _showMessage('❌ Gagal: $errorMsg', isError: true);
        }
        return;
      }
      
      _showMessage('✅ Siswa berhasil ditambahkan!\n📧 Email: $email\n🔑 Password: $password');
      await _loadStudents();
      
    } on PostgrestException catch (e) {
      if (!mounted) return;
      
      if (e.code == '42883') {
        _showMessage('❌ RPC function belum dibuat! Jalankan SQL di Supabase Editor.', isError: true);
      } else {
        _showMessage('❌ Database Error: ${e.message}', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('❌ Gagal: $e', isError: true);
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStudent({required dynamic id, required Map<String, dynamic> data}) async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);
      
      await supabase.from('profiles').update(data).eq('id', id);
      
      if (!mounted) return;
      _showMessage('✅ Siswa berhasil diperbarui!');
      await _loadStudents();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _showMessage('❌ Error: ${e.message}', isError: true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('❌ Gagal: $e', isError: true);
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus(String id, bool active) async {
    try {
      if (!mounted) return;
      
      await supabase.from('profiles').update({
        'status': active ? 'active' : 'inactive'
      }).eq('id', id);
      
      if (!mounted) return;
      _showMessage(active ? '✅ Diaktifkan' : '⚠️ Dinonaktifkan');
      await _loadStudents();
    } catch (e) {
      if (!mounted) return;
      _showMessage('❌ Gagal: $e', isError: true);
    }
  }

  Future<void> _confirmDelete(String id, String name) async {
    if (!mounted) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 12),
            Flexible(child: Text('Hapus Siswa?', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text('Hapus "$name"?\n\nTindakan ini tidak dapat dibatalkan'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(c, true),
            icon: const Icon(Icons.delete_forever, size: 16),
            label: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    
    if (confirm == true && mounted) await _deleteStudent(id, name);
  }

  Future<void> _deleteStudent(String id, String name) async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);
      
      // Hapus placement dulu (jika ada)
      await supabase.from('placements').delete().eq('student_id', id);
      
      // Hapus profile
      await supabase.from('profiles').delete().eq('id', id);
      
      if (!mounted) return;
      _showMessage('"$name" dihapus');
      await _loadStudents();
    } catch (e) {
      if (!mounted) return;
      _showMessage('❌ Gagal: $e', isError: true);
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}