import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_repository.dart';

class DudiManagementScreen extends ConsumerStatefulWidget {
  const DudiManagementScreen({super.key});

  @override
  ConsumerState<DudiManagementScreen> createState() =>
      _DudiManagementScreenState();
}

class _DudiManagementScreenState extends ConsumerState<DudiManagementScreen>
    with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late AnimationController _animCtrl;

  // ── Brand colors ──────────────────────────────────────────────────────────
  static const Color _blue900 = Color(0xFF1E3A8A);
  static const Color _blue800 = Color(0xFF1E40AF);
  static const Color _blue700 = Color(0xFF1D4ED8);
  static const Color _blue600 = Color(0xFF2563EB);
  static const Color _blue500 = Color(0xFF3B82F6);
  static const Color _blue400 = Color(0xFF60A5FA);
  static const Color _blue200 = Color(0xFFBFDBFE);
  static const Color _blue100 = Color(0xFFDBEAFE);
  static const Color _blue50 = Color(0xFFEFF6FF);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(paginatedCompaniesProvider(_currentPage));

    return Scaffold(
      backgroundColor: _blue50,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: companiesAsync.when(
              data: (companies) {
                final filtered = companies
                    .where(
                      (c) =>
                          (c['name'] ?? '').toString().toLowerCase().contains(
                            _searchQuery,
                          ) ||
                          (c['address'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains(_searchQuery),
                    )
                    .toList();

                if (filtered.isEmpty) return _buildEmptyState();

                return Column(
                  children: [
                    _buildStatsBar(filtered.length),
                    Expanded(child: _buildGrid(filtered)),
                    _buildPaginationControl(companies.length),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: _blue700),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Terjadi kesalahan:\n$e",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCompanyDialog(context),
        backgroundColor: _blue700,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          "Tambah Perusahaan",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_blue900, _blue800, _blue700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 20,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.business_center_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Manajemen DUDI",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Kelola Dunia Usaha & Dunia Industri",
                  style: TextStyle(color: _blue200, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: _blue50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _blue200),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search_rounded, color: _blue400, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) =>
                          setState(() => _searchQuery = v.toLowerCase()),
                      style: const TextStyle(fontSize: 13.5, color: _blue900),
                      decoration: const InputDecoration(
                        hintText: "Cari nama atau alamat perusahaan...",
                        hintStyle: TextStyle(color: _blue400, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: _blue400,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats bar ─────────────────────────────────────────────────────────────
  Widget _buildStatsBar(int count) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          _statChip(Icons.apartment_rounded, "$count Mitra", _blue700),
          const SizedBox(width: 10),
          _statChip(
            Icons.check_circle_outline_rounded,
            "Semua Aktif",
            Colors.green.shade700,
          ),
          const SizedBox(width: 10),
          _statChip(
            Icons.layers_outlined,
            "Hal. ${_currentPage + 1}",
            Colors.orange.shade700,
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Card grid ─────────────────────────────────────────────────────────────
  Widget _buildGrid(List<Map<String, dynamic>> companies) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        mainAxisExtent: 240,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: companies.length,
      itemBuilder: (ctx, i) {
        final anim = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _animCtrl,
            curve: Interval(
              (i * 0.12).clamp(0.0, 0.8),
              1.0,
              curve: Curves.easeOut,
            ),
          ),
        );
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(anim),
            child: _buildCompanyCard(companies[i]),
          ),
        );
      },
    );
  }

  // ── Company card ──────────────────────────────────────────────────────────
  Widget _buildCompanyCard(Map<String, dynamic> company) {
    final name = company['name'] ?? '-';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final address = company['address'] ?? '-';
    final lat = company['latitude']?.toStringAsFixed(6) ?? '0';
    final lng = company['longitude']?.toStringAsFixed(6) ?? '0';
    final radius = company['radius_meter']?.toString() ?? '0';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCompanyDialog(context, company: company),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _blue100),
            boxShadow: [
              BoxShadow(
                color: _blue200.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Accent bar ────────────────────────────────────────
              Container(
                height: 5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_blue800, _blue600, _blue400],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Avatar + name ──────────────────────────
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_blue800, _blue600],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _blue900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _blue50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    "Mitra Industri",
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: _blue700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Container(height: 1, color: _blue50),
                      const SizedBox(height: 12),

                      // ── Address ────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: _blue50,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: _blue600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ── Coordinates ────────────────────────────
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: _blue50,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(
                              Icons.my_location_rounded,
                              size: 13,
                              color: _blue600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "$lat, $lng",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // ── Footer: radius + actions ───────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _blue100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.radar_rounded,
                                  size: 13,
                                  color: _blue800,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "$radius m",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _blue800,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              _actionButton(
                                icon: Icons.edit_outlined,
                                color: _blue700,
                                bgColor: _blue100,
                                onTap: () => _showCompanyDialog(
                                  context,
                                  company: company,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _actionButton(
                                icon: Icons.delete_outline_rounded,
                                color: Colors.red.shade700,
                                bgColor: Colors.red.shade50,
                                onTap: () =>
                                    _deleteCompany(context, company['id']),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  // ── Pagination ────────────────────────────────────────────────────────────
  Widget _buildPaginationControl(int currentLength) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _blue100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageBtn(
            Icons.arrow_back_ios_new_rounded,
            _currentPage > 0 ? () => setState(() => _currentPage--) : null,
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: _blue50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _blue200),
            ),
            child: Text(
              "Halaman ${_currentPage + 1}",
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _blue800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          _pageBtn(
            Icons.arrow_forward_ios_rounded,
            currentLength == 10 ? () => setState(() => _currentPage++) : null,
          ),
        ],
      ),
    );
  }

  Widget _pageBtn(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? _blue700 : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 16,
            color: enabled ? Colors.white : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: _blue100, shape: BoxShape.circle),
            child: const Icon(
              Icons.business_outlined,
              size: 56,
              color: _blue600,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Belum ada data mitra",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: _blue800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Tambahkan perusahaan mitra baru\nmenggunakan tombol di bawah",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _blue400),
          ),
        ],
      ),
    );
  }

  // ── Add / Edit dialog ─────────────────────────────────────────────────────
  void _showCompanyDialog(
    BuildContext context, {
    Map<String, dynamic>? company,
  }) {
    final isEditing = company != null;
    final nameCtrl = TextEditingController(text: company?['name']);
    final addrCtrl = TextEditingController(text: company?['address']);
    final latCtrl = TextEditingController(
      text: company?['latitude']?.toString() ?? '',
    );
    final lngCtrl = TextEditingController(
      text: company?['longitude']?.toString() ?? '',
    );
    final radCtrl = TextEditingController(
      text: company?['radius_meter']?.toString() ?? '100',
    );

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: 480,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _blue900.withOpacity(0.18),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_blue900, _blue700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isEditing
                            ? Icons.edit_note_rounded
                            : Icons.add_business_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing
                            ? "Edit Data Perusahaan"
                            : "Tambah Perusahaan Baru",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(6),
                      ),
                    ),
                  ],
                ),
              ),

              // Dialog body
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _dialogField(
                      nameCtrl,
                      "Nama Perusahaan",
                      Icons.business_rounded,
                    ),
                    const SizedBox(height: 14),
                    _dialogField(
                      addrCtrl,
                      "Alamat Lengkap",
                      Icons.map_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _dialogField(
                            latCtrl,
                            "Latitude",
                            Icons.location_on_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dialogField(
                            lngCtrl,
                            "Longitude",
                            Icons.location_on_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _dialogField(
                      radCtrl,
                      "Radius Absensi (Meter)",
                      Icons.radar_rounded,
                      isNumber: true,
                    ),
                  ],
                ),
              ),

              // Dialog footer
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: _blue200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: Colors.grey.shade600,
                        ),
                        child: const Text(
                          "Batal",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_blue800, _blue600],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _blue700.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final data = {
                              'name': nameCtrl.text,
                              'address': addrCtrl.text,
                              'latitude': double.tryParse(latCtrl.text) ?? 0.0,
                              'longitude': double.tryParse(lngCtrl.text) ?? 0.0,
                              'radius_meter': int.tryParse(radCtrl.text) ?? 100,
                            };
                            if (isEditing) {
                              await ref
                                  .read(adminRepositoryProvider)
                                  .updateCompany(company!['id'], data);
                            } else {
                              await ref
                                  .read(adminRepositoryProvider)
                                  .addCompany(data);
                            }
                            ref.invalidate(paginatedCompaniesProvider);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: const Text(
                            "Simpan Data",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 13.5, color: _blue900),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        floatingLabelStyle: const TextStyle(
          color: _blue800,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: _blue500, size: 19),
        filled: true,
        fillColor: _blue50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _blue200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _blue200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _blue700, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  // ── Delete dialog ─────────────────────────────────────────────────────────
  void _deleteCompany(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red.shade700,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Hapus Mitra?",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Perusahaan ini akan dihapus permanen\ndari sistem dan tidak dapat dipulihkan.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: _blue200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: Colors.grey.shade600,
                      ),
                      child: const Text(
                        "Batal",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        await ref
                            .read(adminRepositoryProvider)
                            .deleteCompany(id);
                        ref.invalidate(paginatedCompaniesProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text(
                        "Ya, Hapus",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}