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
  bool _widgetMounted = false;

  @override
  void initState() {
    super.initState();
    _widgetMounted = true;
    _loadStudents();
  }

  @override
  void dispose() {
    _widgetMounted = false;
    super.dispose();
  }

  bool get _isSafe => _widgetMounted && mounted;

  // ─── Load siswa + join placements & companies ───────────────────────────────
  Future<void> _loadStudents() async {
    if (!_isSafe) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // profiles → placements → companies (left join via foreign key)
      final response = await supabase
          .from('profiles')
          .select(
            'id, full_name, nisn, class_name, status, is_verified, avatar_url, role, '
            'company_id, '
            'placements(id, company_id, start_date, end_date, status, '
            '  companies(id, name, address, latitude, longitude, radius_meter))',
          )
          .eq('role', 'student')
          .order('full_name', ascending: true);

      if (!_isSafe) return;

      setState(() {
        _students = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      debugPrint('Loaded ${_students.length} students');
    } catch (e) {
      debugPrint('Error loading students: $e');
      if (_isSafe) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadStudents();
    if (_isSafe) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data diperbarui'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Helper: ambil data placement pertama siswa (jika ada)
  Map<String, dynamic>? _getPlacement(Map<String, dynamic> student) {
    final placements = student['placements'];
    if (placements == null) return null;
    if (placements is List && placements.isNotEmpty) return placements.first as Map<String, dynamic>;
    return null;
  }

  // Helper: ambil nama perusahaan dari placement
  String? _getCompanyName(Map<String, dynamic> student) {
    final placement = _getPlacement(student);
    if (placement == null) return null;
    final company = placement['companies'];
    if (company == null) return null;
    return (company as Map<String, dynamic>)['name']?.toString();
  }

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!_isSafe) return const SizedBox();

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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
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
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      '${_students.length} siswa',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text("Kelola data siswa & penempatan PKL",
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) {
              if (_isSafe) setState(() => _searchQuery = v);
            },
            decoration: InputDecoration(
              hintText: "Cari nama, NISN, atau kelas...",
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0F172A)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        if (_isSafe) setState(() => _searchQuery = "");
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

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
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
              ),
              const SizedBox(height: 16),
              const Text('Gagal Memuat Data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                _errorMessage!.length > 100 ? '${_errorMessage!.substring(0, 100)}...' : _errorMessage!,
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
            const Text('Belum Ada Data Siswa',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Tap tombol di bawah untuk menambahkan',
                style: TextStyle(color: Color(0xFF94A3B8))),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showStudentForm(),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Tambah Siswa Pertama'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
            Text('Tidak Ditemukan: "$_searchQuery"',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Coba kata kunci lain', style: TextStyle(color: Color(0xFF94A3B8))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
        itemCount: filteredStudents.length,
        itemBuilder: (context, i) => _studentCard(filteredStudents[i]),
      ),
    );
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

  Widget _studentCard(Map<String, dynamic> data) {
    final id = data['id']?.toString() ?? '';
    final fullName = data['full_name'] ?? 'Unknown';
    final className = data['class_name'] ?? 'Belum ada kelas';
    final nisn = data['nisn'] ?? '-';
    final status = data['status'] ?? 'active';
    final avatarUrl = data['avatar_url'];
    final isVerified = data['is_verified'] ?? false;
    final isActive = status == 'active';
    final companyName = _getCompanyName(data);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.blue, Colors.blue.shade700]),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.25), blurRadius: 8)],
                      ),
                      child: avatarUrl != null && (avatarUrl as String).isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S',
                                    style: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S',
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
                              ),
                            ),
                    ),
                    if (isVerified)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.check, size: 11, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              fullName,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(isActive: isActive),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.school_outlined, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(className,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.badge_outlined, size: 13, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text('NISN: $nisn',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                      if (companyName != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.business_center, size: 12, color: Colors.purple.shade700),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  companyName,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.purple.shade700),
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
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFFCBD5E1)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      label: 'Edit',
                      icon: Icons.edit_note_rounded,
                      color: Colors.blue,
                      onTap: () => _showStudentForm(studentData: data),
                    ),
                  ),
                  Container(width: 1, height: 24, color: Colors.grey.shade200),
                  Expanded(
                    child: _actionButton(
                      label: 'Penempatan',
                      icon: Icons.business_center_rounded,
                      color: Colors.purple,
                      onTap: () => _showPlacementForm(studentData: data),
                    ),
                  ),
                  Container(width: 1, height: 24, color: Colors.grey.shade200),
                  Expanded(
                    child: _actionButton(
                      label: isActive ? 'Nonaktif' : 'Aktif',
                      icon: isActive ? Icons.toggle_off : Icons.toggle_on,
                      color: isActive ? Colors.orange : Colors.green,
                      onTap: () => _toggleStatus(id, !isActive),
                    ),
                  ),
                  Container(width: 1, height: 24, color: Colors.grey.shade200),
                  Expanded(
                    child: _actionButton(
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

  Widget _buildStatusBadge({required bool isActive}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: 12,
            color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 3),
          Text(
            isActive ? 'Aktif' : 'Nonaktif',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  // ─── Form Tambah/Edit Siswa ──────────────────────────────────────────────────
  Future<void> _showStudentForm({Map<String, dynamic>? studentData}) async {
    if (!_isSafe) return;

    final isEditing = studentData != null;

    final nameController = TextEditingController(text: studentData?['full_name'] ?? '');
    final nisnController = TextEditingController(text: studentData?['nisn'] ?? '');
    final classController = TextEditingController(text: studentData?['class_name'] ?? '');
    final phoneController = TextEditingController(text: studentData?['phone_number'] ?? '');

    String selectedStatus = studentData?['status'] ?? 'active';
    bool isVerified = studentData?['is_verified'] ?? false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  _buildSheetHeader(title: isEditing ? 'Edit Siswa' : 'Tambah Siswa Baru'),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: nameController,
                            label: 'Nama Lengkap *',
                            hint: 'Masukkan nama lengkap',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: nisnController,
                            label: 'NISN *',
                            hint: 'Nomor Induk Siswa Nasional',
                            icon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: classController,
                            label: 'Kelas *',
                            hint: 'Contoh: XII RPL 1',
                            icon: Icons.school_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: phoneController,
                            label: 'No. Telepon',
                            hint: '08123456789',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              prefixIcon: const Icon(Icons.toggle_on_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'active', child: Text('Aktif')),
                              DropdownMenuItem(value: 'inactive', child: Text('Nonaktif')),
                              DropdownMenuItem(value: 'graduated', child: Text('Lulus')),
                            ],
                            onChanged: (v) => setModalState(() => selectedStatus = v!),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Terverifikasi'),
                            subtitle: const Text('Data sudah diverifikasi'),
                            value: isVerified,
                            activeColor: Colors.green,
                            onChanged: (v) => setModalState(() => isVerified = v),
                            secondary: const Icon(Icons.verified_user_outlined),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildSubmitButton(
                    label: isEditing ? 'Simpan Perubahan' : 'Tambah Siswa',
                    color: isEditing ? Colors.orange : Colors.blue,
                    icon: isEditing ? Icons.save : Icons.add_circle_outline,
                    onTap: () async {
                      if (nameController.text.isEmpty ||
                          nisnController.text.isEmpty ||
                          classController.text.isEmpty) {
                        _showMessage('Harap isi field wajib (*)', isError: true);
                        return;
                      }

                      Navigator.pop(ctx);

                      final payload = {
                        'full_name': nameController.text.trim(),
                        'nisn': nisnController.text.trim(),
                        'class_name': classController.text.trim(),
                        'phone_number': phoneController.text.trim().isEmpty
                            ? null
                            : phoneController.text.trim(),
                        'status': selectedStatus,
                        'is_verified': isVerified,
                      };

                      if (isEditing) {
                        await _updateStudent(id: studentData!['id'], data: payload);
                      } else {
                        await _createStudent(
                            data: {...payload, 'role': 'student'});
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

    nameController.dispose();
    nisnController.dispose();
    classController.dispose();
    phoneController.dispose();
  }

  // ─── Form Penempatan PKL ─────────────────────────────────────────────────────
  // Database schema:
  //   companies(id, name, address, latitude, longitude, radius_meter)
  //   placements(id, student_id, company_id, start_date, end_date, status)
  //
  // Flow: cari/buat company → buat/update placement yang link ke company tersebut
  Future<void> _showPlacementForm({required Map<String, dynamic> studentData}) async {
    if (!_isSafe) return;

    final studentId = studentData['id'];
    final studentName = studentData['full_name'] ?? 'Siswa';

    // Cek placement & company yang sudah ada
    final existingPlacement = _getPlacement(studentData);
    Map<String, dynamic>? existingCompany;
    if (existingPlacement != null && existingPlacement['companies'] != null) {
      existingCompany = Map<String, dynamic>.from(existingPlacement['companies'] as Map);
    }

    final isEditing = existingPlacement != null;

    final companyController =
        TextEditingController(text: existingCompany?['name'] ?? '');
    final addressController =
        TextEditingController(text: existingCompany?['address'] ?? '');
    final latController =
        TextEditingController(text: existingCompany?['latitude']?.toString() ?? '');
    final lngController =
        TextEditingController(text: existingCompany?['longitude']?.toString() ?? '');
    final radiusController = TextEditingController(
        text: existingCompany?['radius_meter']?.toString() ?? '100');

    // start_date / end_date dari placement
    final startDateController =
        TextEditingController(text: existingPlacement?['start_date'] ?? '');
    final endDateController =
        TextEditingController(text: existingPlacement?['end_date'] ?? '');

    String selectedStatus = existingPlacement?['status'] ?? 'active';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  _buildSheetHeader(
                    title: isEditing ? 'Edit Penempatan PKL' : 'Atur Penempatan PKL',
                    subtitle: 'Siswa: $studentName',
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Informasi Perusahaan'),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: companyController,
                            label: 'Nama Perusahaan/Instansi *',
                            hint: 'PT. Contoh Indonesia',
                            icon: Icons.business,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: addressController,
                            label: 'Alamat Lengkap *',
                            hint: 'Jl. Contoh No. 123, Kota',
                            icon: Icons.location_on_outlined,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 20),
                          _sectionTitle('Lokasi & Radius Absen'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: latController,
                                  label: 'Latitude',
                                  hint: '-6.2088',
                                  icon: Icons.my_location,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: lngController,
                                  label: 'Longitude',
                                  hint: '106.8456',
                                  icon: Icons.my_location,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: radiusController,
                            label: 'Radius Absen (meter)',
                            hint: '100',
                            icon: Icons.radio_button_checked,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          _sectionTitle('Periode PKL'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: startDateController,
                                  label: 'Tanggal Mulai',
                                  hint: 'YYYY-MM-DD',
                                  icon: Icons.calendar_today,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: endDateController,
                                  label: 'Tanggal Selesai',
                                  hint: 'YYYY-MM-DD',
                                  icon: Icons.event,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status Penempatan',
                              prefixIcon: const Icon(Icons.timeline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'active', child: Text('Aktif')),
                              DropdownMenuItem(value: 'completed', child: Text('Selesai')),
                              DropdownMenuItem(value: 'terminated', child: Text('Dihentikan')),
                            ],
                            onChanged: (v) => setModalState(() => selectedStatus = v!),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildSubmitButton(
                    label: isEditing ? 'Update Penempatan' : 'Simpan Penempatan',
                    color: Colors.purple,
                    icon: isEditing ? Icons.save : Icons.business_center,
                    onTap: () async {
                      if (companyController.text.isEmpty || addressController.text.isEmpty) {
                        _showMessage('Nama perusahaan & alamat wajib diisi!', isError: true);
                        return;
                      }

                      Navigator.pop(ctx);

                      await _savePlacement(
                        studentId: studentId,
                        existingPlacement: existingPlacement,
                        existingCompanyId: existingCompany?['id'],
                        companyName: companyController.text.trim(),
                        address: addressController.text.trim(),
                        latitude: double.tryParse(latController.text) ?? 0.0,
                        longitude: double.tryParse(lngController.text) ?? 0.0,
                        radiusMeter: num.tryParse(radiusController.text) ?? 100,
                        startDate: startDateController.text.trim().isEmpty
                            ? null
                            : startDateController.text.trim(),
                        endDate: endDateController.text.trim().isEmpty
                            ? null
                            : endDateController.text.trim(),
                        status: selectedStatus,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    companyController.dispose();
    addressController.dispose();
    latController.dispose();
    lngController.dispose();
    radiusController.dispose();
    startDateController.dispose();
    endDateController.dispose();
  }

  // ─── Shared Widgets ──────────────────────────────────────────────────────────
  Widget _buildSheetHeader({required String title, String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) =>
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold));

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildSubmitButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: Icon(icon),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  // ─── CRUD ────────────────────────────────────────────────────────────────────
  Future<void> _createStudent({required Map<String, dynamic> data}) async {
    try {
      if (!_isSafe) return;
      setState(() => _isLoading = true);
      await supabase.from('profiles').insert(data);
      if (_isSafe) {
        _showMessage('Siswa berhasil ditambahkan!');
        await _loadStudents();
      }
    } on PostgrestException catch (e) {
      if (_isSafe) _showMessage('Error: ${e.message}', isError: true);
    } catch (e) {
      if (_isSafe) _showMessage('Gagal: $e', isError: true);
    } finally {
      if (_isSafe) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStudent({required dynamic id, required Map<String, dynamic> data}) async {
    try {
      if (!_isSafe) return;
      setState(() => _isLoading = true);
      await supabase.from('profiles').update(data).eq('id', id);
      if (_isSafe) {
        _showMessage('Siswa berhasil diperbarui!');
        await _loadStudents();
      }
    } on PostgrestException catch (e) {
      if (_isSafe) _showMessage('Error: ${e.message}', isError: true);
    } catch (e) {
      if (_isSafe) _showMessage('Gagal: $e', isError: true);
    } finally {
      if (_isSafe) setState(() => _isLoading = false);
    }
  }

  /// Simpan penempatan: upsert company → upsert placement
  Future<void> _savePlacement({
    required dynamic studentId,
    required Map<String, dynamic>? existingPlacement,
    required dynamic existingCompanyId,
    required String companyName,
    required String address,
    required double latitude,
    required double longitude,
    required num radiusMeter,
    String? startDate,
    String? endDate,
    required String status,
  }) async {
    try {
      if (!_isSafe) return;
      setState(() => _isLoading = true);

      int companyId;

      if (existingCompanyId != null) {
        // Update company yang sudah ada
        await supabase.from('companies').update({
          'name': companyName,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          'radius_meter': radiusMeter,
        }).eq('id', existingCompanyId);
        companyId = existingCompanyId as int;
      } else {
        // Buat company baru
        final companyRes = await supabase
            .from('companies')
            .insert({
              'name': companyName,
              'address': address,
              'latitude': latitude,
              'longitude': longitude,
              'radius_meter': radiusMeter,
            })
            .select('id')
            .single();
        companyId = companyRes['id'] as int;
      }

      final placementPayload = {
        'student_id': studentId,
        'company_id': companyId,
        'start_date': startDate,
        'end_date': endDate,
        'status': status,
      };

      if (existingPlacement != null) {
        // Update placement
        await supabase
            .from('placements')
            .update(placementPayload)
            .eq('id', existingPlacement['id']);
        _showMessage('Penempatan PKL berhasil diperbarui!');
      } else {
        // Insert placement baru
        await supabase.from('placements').insert(placementPayload);
        _showMessage('Penempatan PKL berhasil ditambahkan!');
      }

      if (_isSafe) await _loadStudents();
    } on PostgrestException catch (e) {
      if (_isSafe) _showMessage('Error: ${e.message}', isError: true);
    } catch (e) {
      if (_isSafe) _showMessage('Gagal: $e', isError: true);
    } finally {
      if (_isSafe) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus(String id, bool active) async {
    try {
      if (!_isSafe) return;
      await supabase
          .from('profiles')
          .update({'status': active ? 'active' : 'inactive'})
          .eq('id', id);
      if (_isSafe) {
        _showMessage(active ? 'Diaktifkan' : 'Dinonaktifkan');
        await _loadStudents();
      }
    } catch (e) {
      if (_isSafe) _showMessage('Gagal: $e', isError: true);
    }
  }

  Future<void> _confirmDelete(String id, String name) async {
    if (!_isSafe) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Hapus Siswa?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Hapus "$name"?\n\nTindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('Ya, Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) await _deleteStudent(id, name);
  }

  Future<void> _deleteStudent(String id, String name) async {
    try {
      if (!_isSafe) return;
      setState(() => _isLoading = true);
      await supabase.from('profiles').delete().eq('id', id);
      if (_isSafe) {
        _showMessage('"$name" dihapus');
        await _loadStudents();
      }
    } catch (e) {
      if (_isSafe) _showMessage('Gagal: $e', isError: true);
    } finally {
      if (_isSafe) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!_isSafe) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}