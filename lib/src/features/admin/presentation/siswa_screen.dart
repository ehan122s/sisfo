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

  // Cache companies DUDI
  List<Map<String, dynamic>> _companies = [];

  @override
  void initState() {
    super.initState();
    _widgetMounted = true;
    _loadStudents();
    _loadCompanies();
  }

  @override
  void dispose() {
    _widgetMounted = false;
    super.dispose();
  }

  bool get _isSafe => _widgetMounted && mounted;

  // Load companies dari DUDI
  Future<void> _loadCompanies() async {
    if (!_isSafe) return;
    
    try {
      final response = await supabase
          .from('companies')
          .select('id, name, address, latitude, longitude, radius_meter')
          .order('name', ascending: true);
      
      if (_isSafe) {
        setState(() {
          _companies = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Error loading companies: $e');
    }
  }

  // Load siswa
  Future<void> _loadStudents() async {
    if (!_isSafe) return;

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

      if (!_isSafe) return;

      setState(() {
        _students = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
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
    await Future.wait([_loadStudents(), _loadCompanies()]);
    
    if (_isSafe) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Data diperbarui'),
          duration: Duration(seconds: 1),
        ),
      );
    }
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

  // HEADER
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
          const Text("Kelola data siswa & penempatan PKL", style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          
          // Search bar
          TextField(
            onChanged: (v) {
              if (_isSafe) setState(() => _searchQuery = v);
            },
            decoration: InputDecoration(
              hintText: "Cari nama, NISN, kelas, atau perusahaan...",
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

  // BODY
  Widget _buildBody() {
    // Loading
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

    // Error state
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

    // Empty state
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

    // Filtered list
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
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
        itemCount: filteredStudents.length,
        itemBuilder: (context, i) => _studentCard(filteredStudents[i]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // STUDENT CARD
  // ══════════════════════════════════════════════════════════════════

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.blue, Color(0xFF1D4ED8)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.25), blurRadius: 8)],
                      ),
                      child: avatarUrl != null && avatarUrl.toString().isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Center(
                                    child: Text(
                                      fullName.isNotEmpty 
                                          ? fullName[0].toUpperCase() 
                                          : 'S',
                                      style: const TextStyle(
                                        color: Colors.white, 
                                        fontWeight: FontWeight.w900, 
                                        fontSize: 22,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                fullName.isNotEmpty 
                                    ? fullName[0].toUpperCase() 
                                    : 'S',
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.w900, 
                                  fontSize: 22,
                                ),
                              ),
                            ),
                    ),
                    
                    // Verified badge
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
                
                // Info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + Status Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800, 
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // Status Badge
                          _buildStatusBadge(isActive: isActive),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Class info
                      Row(
                        children: [
                          Icon(Icons.school_outlined, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              className,
                              style: TextStyle(
                                color: Colors.grey.shade600, 
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 2),
                      
                      // NISN info
                      Row(
                        children: [
                          Icon(Icons.badge_outlined, size: 13, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'NISN: $nisn',
                              style: TextStyle(
                                color: Colors.grey.shade500, 
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Company badge (jika ada)
                      if (companyName != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                                  companyName!,
                                  style: TextStyle(
                                    fontSize: 11, 
                                    fontWeight: FontWeight.w600, 
                                    color: Colors.purple.shade700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 14),
                      
                      // Arrow
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFFCBD5E1)),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 14),
            
            // Action buttons row
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Edit button
                  Expanded(
                    child: InkWell(
                      onTap: () => _showStudentForm(studentData: data),
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_note_rounded, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue)),
                        ],
                      ),
                    ),
                  ),
                  
                  // Divider
                  Container(width: 1, height: 24, color: Colors.grey.shade200),
                  
                  // Penempatan button
                  Expanded(
                    child: InkWell(
                      onTap: () => _showPlacementForm(studentData: data),
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.business_center_rounded, size: 16, color: Colors.purple),
                          const SizedBox(width: 4),
                          Text('Penempatan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.purple)),
                        ],
                      ),
                    ),
                  ),
                  
                  // Divider
                  Container(width: 1, height: 24, color: Colors.grey.shade200),
                  
                  // Toggle Status button
                  Expanded(
                    child: InkWell(
                      onTap: () => _toggleStatus(id, !isActive),
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isActive ? Icons.toggle_off : Icons.toggle_on, size: 16, color: isActive ? Colors.orange : Colors.green),
                          const SizedBox(width: 4),
                          Text(isActive ? 'Nonaktif' : 'Aktif', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? Colors.orange : Colors.green)),
                        ],
                      ),
                    ),
                  ),
                  
                  // Divider
                  Container(width: 1, height: 24, color: Colors.grey.shade200),
                  
                  // Delete button
                  Expanded(
                    child: InkWell(
                      onTap: () => _confirmDelete(id, fullName),
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_forever_rounded, size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          Text('Hapus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red)),
                        ],
                      ),
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

  // STATUS BADGE WIDGET
  Widget _buildStatusBadge({required bool isActive}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isActive 
            ? const Color(0xFFDCFCE7) 
            : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive 
              ? Icons.check_circle 
              : Icons.cancel,
            size: 12, 
            color: isActive 
              ? const Color(0xFF16A34A) 
              : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 3),
          Text(
            isActive 
              ? 'Aktif' 
              : 'Nonaktif',
            style: TextStyle(
              fontSize: 11, 
              fontWeight: FontWeight.w700, 
              color: isActive 
                ? const Color(0xFF16A34A) 
                : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  // ACTION BUTTON HELPER
  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // FORM SISWA
  // ════════════════════════════════════════════════════════════════

  Future<void> _showStudentForm({Map<String, dynamic>? studentData}) async {
    if (!_isSafe) return;

    final isEditing = studentData != null;
    
    final nameController = TextEditingController(text: studentData?['full_name'] ?? '');
    final nisnController = TextEditingController(text: studentData?['nisn'] ?? '');
    final classController = TextEditingController(text: studentData?['class_name'] ?? '');
    final phoneController = TextEditingController(text: studentData?['phone_number'] ?? '');
    
    String selectedStatus = studentData?['status'] ?? 'active';
    bool isVerified = studentData?['is_verified'] == true;

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
                  // Header
                  _sheetHeader(
                    title: isEditing 
                      ? '✏️ Edit Siswa' 
                      : '➕ Tambah Siswa Baru',
                  ),
                  
                  // Form Fields
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Nama Lengkap - ✅ FIXED: ctrl instead of controller
                          _txtField(
                            ctrl: nameController, 
                            label: 'Nama Lengkap *', 
                            hint: 'Masukkan nama lengkap', 
                            icon: Icons.person_outline,
                          ), 
                          const SizedBox(height: 16),
                          
                          // NISN - ✅ FIXED: ctrl + kbType
                          _txtField(
                            ctrl: nisnController, 
                            label: 'NISN *', 
                            hint: 'Nomor Induk Siswa Nasional', 
                            icon: Icons.badge_outlined, 
                            kbType: TextInputType.number,       // ✅ FIXED: kbType not keyboardType
                          ), 
                          const SizedBox(height: 16),
                          
                          // Kelas - ✅ FIXED: ctrl
                          _txtField(
                            ctrl: classController, 
                            label: 'Kelas *', 
                            hint: 'Contoh: XII RPL 1', 
                            icon: Icons.school_outlined,
                          ), 
                          const SizedBox(height: 16),
                          
                          // No. Telepon - ✅ FIXED: ctrl + kbType
                          _txtField(
                            ctrl: phoneController, 
                            label: 'No. Telepon', 
                            hint: '08123456789', 
                            icon: Icons.phone_outlined, 
                            kbType: TextInputType.phone,         // ✅ FIXED: kbType not keyboardType
                          ), 
                          const SizedBox(height: 20),
                          
                          // Status Dropdown
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
                            onChanged: (v) { 
                              setModalState(() { selectedStatus = v!; });
                            }, 
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Switch Terverifikasi
                          SwitchListTile(
                            title: const Text('Terverifikasi'), 
                            subtitle: const Text('Data sudah diverifikasi'), 
                            value: isVerified, 
                            activeColor: Colors.green, 
                            onChanged: (v) { 
                              setModalState(() { isVerified = v; }); 
                            }, 
                            secondary: const Icon(Icons.verified_user_outlined), 
                            contentPadding: EdgeInsets.zero,
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  
                  // Submit Button
                  _submitBtn(
                    label: isEditing 
                        ? 'Simpan Perubahan' 
                        : 'Tambah Siswa', 
                    color: isEditing 
                        ? Colors.orange 
                        : Colors.blue, 
                    icon: isEditing 
                        ? Icons.save 
                        : Icons.add_circle_outline, 
                    onTap: () async {
                      // Validation
                      if (nameController.text.isEmpty || 
                          nisnController.text.isEmpty || 
                          classController.text.isEmpty) { 
                        _showMessage('⚠️ Harap isi field wajib (*)', isError: true); 
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
                        'role': 'student',
                      };
                      
                      if (isEditing) { 
                        await _updateStudent(
                          id: studentData!['id'], 
                          data: payload, 
                        ); 
                      } else { 
                        await _createStudent(data: payload); 
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

    // Dispose controllers
    nameController.dispose();
    nisnController.dispose();
    classController.dispose();
    phoneController.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  // FORM PENEMPATAN DENGAN COMPANY PICKER DUDI
  // ══════════════════════════════════════════════════════════════

  Future<void> _showPlacementForm({required Map<String, dynamic> studentData}) async {
    if (!_isSafe) return;

    final studentId = studentData['id'];
    final studentName = studentData['full_name'] ?? 'Siswa';

    // Cek existing placement & company
    final existingPlacement = _getPlacement(studentData);
    Map<String, dynamic>? existingCompany;
    int? existingCompanyId;
    
    if (existingPlacement != null) {
      existingCompanyId = existingPlacement['company_id'] as int?;
      
      if (existingCompanyId != null) {
        try {
          existingCompany = _companies.firstWhere((c) => c['id'] == existingCompanyId);
        } catch (e) {
          existingCompany = null;
        }
      }
    }

    final isEditing = existingPlacement != null;

    // Controllers
    int? selectedCompanyId = existingCompanyId;
    String selectedCompanyName = existingCompany?['name'] ?? '';
    
    final addressCtrl = TextEditingController(text: existingCompany?['address'] ?? '');
    final latCtrl = TextEditingController(text: existingCompany?['latitude']?.toString() ?? '');
    final lngCtrl = TextEditingController(text: existingCompany?['longitude']?.toString() ?? '');
    final radiusCtrl = TextEditingController(text: existingCompany?['radius_meter']?.toString() ?? '100');
    final startDateCtrl = TextEditingController(text: existingPlacement?['start_date'] ?? '');
    final endDateCtrl = TextEditingController(text: existingPlacement?['end_date'] ?? '');
    
    String selectedStatus = existingPlacement?['status'] ?? 'active';

    // Search controller untuk filter
    final searchCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.92,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Header
                  _sheetHeader(
                    title: isEditing 
                        ? '🏢 Edit Penempatan PKL' 
                        : '🏢 Atur Penempatan PKL', 
                    subtitle: 'Siswa: $studentName',
                  ),
                  
                  // Body Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section: Pilih Perusahaan
                          _secTitle('🏭 Pilih Perusahaan (DUDI)'),
                          const SizedBox(height: 8),
                          
                          // Search bar
                          TextField(
                            controller: searchCtrl,
                            onChanged: (_) => setModalState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Cari perusahaan...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  searchCtrl.clear();
                                  setModalState(() {});
                                },
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // ✅ Dropdown Company dari DUDI
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.purple.shade300, 
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.purple.shade50,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: selectedCompanyId,
                                icon: const Icon(Icons.business_center, color: Colors.purple),
                                isExpanded: true,
                                hint: const Text('Pilih perusahaan...'),
                                
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
                                            Icon(Icons.business, size: 20, color: Colors.purple.shade700),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(cname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis), 
                                                  const SizedBox(height: 2), 
                                                  Text(company['address'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    })
                                    .toList(),
                                
                                onChanged: (int? newVal) {
                                  debugPrint('Selected company ID: $newVal');
                                  
                                  setModalState(() {
                                    selectedCompanyId = newVal;
                                    
                                    // Auto-fill fields jika company sudah dipilih
                                    if (newVal != null) {
                                      try {
                                        final sel = _companies.firstWhere((c) => c['id'] == newVal);
                                        
                                        selectedCompanyName = sel['name'];
                                        
                                        if (sel['address'] != null) {
                                          addressCtrl.text = sel['address'];
                                        }
                                        
                                        if (sel['latitude'] != null) {
                                          latCtrl.text = sel['latitude'].toString();
                                        }
                                        
                                        if (sel['longitude'] != null) {
                                          lngCtrl.text = sel['longitude'].toString();
                                        }
                                        
                                        if (sel['radius_meter'] != null) {
                                          radiusCtrl.text = sel['radius_meter'].toString();
                                        }
                                      } catch (e) {
                                        debugPrint('Error getting company details: $e');
                                      }
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Info terpilih
                          if (selectedCompanyId != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Terpilih: $selectedCompanyName',
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF166534), fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Jika belum pilih, tampilkan tombol buat baru
                          if (selectedCompanyId == null) ...[
                            InkWell(
                              onTap: () {
                                _showAddCompanyDialog(ctx).then((newId) {
                                  setModalState(() {
                                    selectedCompanyId = newId;
                                    _loadCompanies(); // Reload companies list
                                  });
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.blue.shade300, 
                                    style: BorderStyle.solid, 
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.blue.shade50,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_business, color: Color(0xFF1D4ED8), size: 18),
                                    const SizedBox(width: 8),
                                    const Text('+ Tambah Perusahaan ke DUDI', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8))),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          const Divider(),
                          const SizedBox(height: 16),
                          
                          // Section: Detail Lokasi
                          _secTitle('📍 Detail Lokasi'),
                          const SizedBox(height: 12),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _txtField(ctrl: latCtrl, label: 'Latitude', hint: '-6.2088', icon: Icons.my_location, kbType: TextInputType.numberWithOptions(decimal: true)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _txtField(ctrl: lngCtrl, label: 'Longitude', hint: '106.8456', icon: Icons.my_location, kbType: TextInputType.numberWithOptions(decimal: true)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          _txtField(ctrl: radiusCtrl, label: 'Radius Absen (m)', hint: '100', icon: Icons.radio_button_checked, kbType: TextInputType.number),
                          const SizedBox(height: 20),
                          
                          // Section: Periode
                          _secTitle('📅 Periode PKL'),
                          const SizedBox(height: 12),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _txtField(ctrl: startDateCtrl, label: 'Tanggal Mulai', hint: 'YYYY-MM-DD', icon: Icons.calendar_today),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _txtField(ctrl: endDateCtrl, label: 'Tanggal Selesai', hint: 'YYYY-MM-DD', icon: Icons.event),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Status dropdown
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
                  
                  // Submit Button
                  _submitBtn(
                    label: isEditing 
                        ? 'Update Penempatan' 
                        : 'Simpan Penempatan', 
                    color: Colors.purple, 
                    icon: isEditing 
                        ? Icons.save 
                        : Icons.business_center, 
                    onTap: () async {
                      // Validation
                      if (selectedCompanyId == null) {
                        _showMessage('⚠️ Pilih perusahaan dari DUDI!', isError: true);
                        return;
                      }
                      
                      if (addressCtrl.text.isEmpty) {
                        _showMessage('⚠️ Alamat wajib diisi!', isError: true);
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
                          _showMessage('✅ Penempatan berhasil diperbarui!');
                        } else {
                          await supabase.from('placements').insert(payload);
                          _showMessage('✅ Penempatan berhasil ditambahkan!');
                        }
                        
                        if (_isSafe) await _loadStudents();
                      } catch (e) {
                        _showMessage('❌ Error: $e', isError: true);
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

    // Dispose
    searchCtrl.dispose();
    addressCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
    radiusCtrl.dispose();
    startDateCtrl.dispose();
    endDateCtrl.dispose();
  }

  /// Dialog tambah perusahaan baru ke DUDI
  Future<int?> _showAddCompanyDialog(BuildContext ctx) async {
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final latCtrl = TextEditingController(text: '-6.2088');
    final lngCtrl = TextEditingController(text: '106.8456');
    final radiusCtrl = TextEditingController(text: '100');

    final result = await showDialog<int>(
      context: ctx,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_business, color: Colors.purple),
              SizedBox(width: 12),
              Text('Tambah Perusahaan ke DUDI', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _txtField(ctrl: nameCtrl, label: 'Nama Perusahaan *', hint: 'PT. Contoh Indonesia', icon: Icons.business),
                const SizedBox(height: 12),
                _txtField(ctrl: addrCtrl, label: 'Alamat Lengkap *', hint: 'Jl. Contoh No. 123', icon: Icons.location_on, maxLines: 2),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _txtField(ctrl: latCtrl, label: 'Latitude', hint: '-6.2088', icon: Icons.my_location, kbType: TextInputType.numberWithOptions(decimal: true))),
                    const SizedBox(width: 12),
                    Expanded(child: _txtField(ctrl: lngCtrl, label: 'Longitude', hint: '106.8456', icon: Icons.my_location, kbType: TextInputType.numberWithOptions(decimal: true))),
                  ],
                ),
                const SizedBox(height: 12),
                _txtField(ctrl: radiusCtrl, label: 'Radius Absen (m)', hint: '100', icon: Icons.radio_button_checked, kbType: TextInputType.number),
                const SizedBox(height: 20),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Batal'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || addrCtrl.text.isEmpty) {
                  _showMessage('⚠️ Nama & alamat wajib diisi!', isError: true);
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
                  
                  final newId = res['id'] as int;
                  
                  if (dialogCtx.mounted) {
                    Navigator.of(dialogCtx).pop(newId);
                  }
                } catch (e) {
                  _showMessage('❌ Gagal: $e', isError: true);
                }
              },
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Simpan ke DUDI', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    // Dispose
    nameCtrl.dispose();
    addrCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
    radiusCtrl.dispose();
    
    return result;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ══════════════════════════════════════════════════════════════════

  Widget _sheetHeader({required String title, String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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

  Widget _secTitle(String title) =>
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold));

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

  Widget _submitBtn({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
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

  // ══════════════════════════════════════════════════════════════════════════════
  // CRUD OPERATIONS
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _createStudent({required Map<String, dynamic> data}) async {
    try {
      if (!_isSafe) return;
      setState(() => _isLoading = true);
      
      await supabase.from('profiles').insert(data);
      
      if (_isSafe) { 
        _showMessage('✅ Siswa berhasil ditambahkan!'); 
        await _loadStudents(); 
      }
    } on PostgrestException catch (e) { 
      if (_isSafe) _showMessage('❌ Error: ${e.message}', isError: true); 
    } catch (e) { 
      if (_isSafe) _showMessage('❌ Gagal: $e', isError: true); 
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
        _showMessage('✅ Siswa berhasil diperbarui!'); 
        await _loadStudents(); 
      }
    } on PostgrestException catch (e) { 
      if (_isSafe) _showMessage('❌ Error: ${e.message}', isError: true); 
    } catch (e) { 
      if (_isSafe) _showMessage('❌ Gagal: $e', isError: true); 
    } finally { 
      if (_isSafe) setState(() => _isLoading = false); 
    }
  }

  Future<void> _toggleStatus(String id, bool active) async {
    try {
      if (!_isSafe) return;
      
      await supabase.from('profiles').update({
        'status': active ? 'active' : 'inactive'
      }).eq('id', id);
      
      if (_isSafe) { 
        _showMessage(active ? '✅ Diaktifkan' : '⚠️ Dinonaktifkan'); 
        await _loadStudents(); 
      }
    } catch (e) { 
      if (_isSafe) _showMessage('❌ Gagal: $e', isError: true); 
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
          ]
        ), 
        content: Text('Hapus "$name"? \n\nTindakan ini tidak dapat dibatalkan'), 
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false), 
            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)), 
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(c, true),
            icon: const Icon(Icons.delete_forever, size: 18), 
            label: const Text('Ya, Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, 
              foregroundColor: Colors.white,
            ),
          ),
        ]
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
      if (_isSafe) _showMessage('❌ Gagal: $e', isError: true); 
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
        backgroundColor: isError 
          ? Colors.red.shade700 
          : Colors.green.shade700, 
        behavior: SnackBarBehavior.floating, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
        margin: const EdgeInsets.all(16), 
        duration: const Duration(seconds: 3),
      ),
    );
  }
}