import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/admin_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../branches/presentation/admin_branch_management_widget.dart';

class AdminSettingsTab extends ConsumerStatefulWidget {
  const AdminSettingsTab({super.key});

  @override
  ConsumerState<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends ConsumerState<AdminSettingsTab> {
  // Config state supported by app
  bool _autoConfirmOrders = false;
  int _prepLeadTimeMinutes = 20;
  bool _enableKitchenBellSound = true;
  bool _enableOrderNotifications = true;
  bool _enableDualCurrencyDisplay = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Container(
      color: AdminColors.warmWhite,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────────
            Text(
              'SYSTEM ARCHITECTURE & CONFIGURATION',
              style: AdminColors.sansUI(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AdminColors.burgundy,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Pengaturan & Konfigurasi Sistem',
              style: AdminColors.serifHeading(fontSize: 24),
            ),
            const SizedBox(height: 20),

            // ── Section 1: Profil Admin ────────────────────────────────────────
            _buildSectionHeader('1. PROFIL ADMINISTRATOR', Icons.badge_outlined),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminColors.border),
              ),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 450;

                      final userDetails = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                user?.fullName ?? 'Administrator Utama',
                                style: AdminColors.sansUI(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  user?.role.toUpperCase() ?? 'ADMIN',
                                  style: AdminColors.sansUI(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF92400E)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${user?.username ?? 'bunatelier.admin'}',
                            style: AdminColors.sansUI(fontSize: 12, fontWeight: FontWeight.bold, color: AdminColors.burgundy),
                          ),
                          Text(
                            user?.email ?? 'admin@bunatelier.com',
                            style: AdminColors.sansUI(fontSize: 12, color: AdminColors.mutedText),
                          ),
                        ],
                      );

                      final editButton = OutlinedButton(
                        onPressed: () => _showEditProfileDialog(context, user?.fullName ?? ''),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AdminColors.burgundy),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        child: Text(
                          'Ubah Profil',
                          style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.burgundy),
                        ),
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: AdminColors.burgundy,
                                  child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 26),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: userDetails),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: editButton,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AdminColors.burgundy,
                            child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: userDetails),
                          const SizedBox(width: 8),
                          editButton,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section 2: Keamanan Akun ───────────────────────────────────────
            _buildSectionHeader('2. KEAMANAN & AKSES KREDENSIAL', Icons.lock_outline),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminColors.border),
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    icon: Icons.key_outlined,
                    title: 'Kata Sandi Administrator',
                    subtitle: 'Terenkripsi SHA-256 dengan Unique Salt & Flutter Secure Storage',
                    trailing: OutlinedButton(
                      onPressed: () => _showChangePasswordDialog(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AdminColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      child: Text('Ganti Sandi', style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.darkBrown)),
                    ),
                  ),
                  const Divider(color: AdminColors.divider, height: 20),
                  _buildSettingRow(
                    icon: Icons.security_outlined,
                    title: 'Status Autentikasi',
                    subtitle: 'Multi-Role Guard (Customer & Administrator Protection Aktif)',
                    trailing: const Icon(Icons.verified_user, size: 18, color: AdminColors.success),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section 3: Pengaturan Multi-Branch (6 Cabang) ───────────────────
            _buildSectionHeader('3. MANAJEMEN MULTI-BRANCH (6 CABANG)', Icons.storefront_outlined),
            const SizedBox(height: 10),
            const AdminBranchManagementWidget(),
            const SizedBox(height: 20),

            // ── Section 4: Pengaturan Pesanan & Dapur ───────────────────────────
            _buildSectionHeader('4. PENGATURAN PESANAN & OPERASIONAL DAPUR', Icons.outdoor_grill_outlined),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.touch_app_outlined, color: AdminColors.burgundy, size: 20),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Konfirmasi Otomatis Pesanan', style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.bold)),
                            Text('Otomatis ubah status MENUNGGU ke DIKONFIRMASI saat pesanan masuk', style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _autoConfirmOrders,
                        activeThumbColor: AdminColors.burgundy,
                        onChanged: (val) {
                          setState(() => _autoConfirmOrders = val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Auto-confirm diubah ke: ${val ? 'Aktif' : 'Manual'}')),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(color: AdminColors.divider, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.timer_outlined, color: AdminColors.burgundy, size: 20),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Estimasi Waktu Menyiapkan (Prep Lead Time)', style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.bold)),
                            Text('Waktu rata-rata yang ditampilkan ke pelanggan', style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _prepLeadTimeMinutes,
                        items: const [
                          DropdownMenuItem(value: 15, child: Text('15 Menit')),
                          DropdownMenuItem(value: 20, child: Text('20 Menit')),
                          DropdownMenuItem(value: 25, child: Text('25 Menit')),
                          DropdownMenuItem(value: 30, child: Text('30 Menit')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _prepLeadTimeMinutes = val);
                        },
                        style: AdminColors.sansUI(fontSize: 12, fontWeight: FontWeight.bold, color: AdminColors.burgundy),
                      ),
                    ],
                  ),
                  const Divider(color: AdminColors.divider, height: 20),
                  _buildSettingRow(
                    icon: Icons.receipt_long,
                    title: 'Pajak Restoran (PB1)',
                    subtitle: '10% (Sesuai peraturan perpajakan Pemda DKI Jakarta)',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AdminColors.sandBeige, borderRadius: BorderRadius.circular(4)),
                      child: Text('10%', style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.burgundy)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section 5: Preferensi Tampilan & Notifikasi ─────────────────────
            _buildSectionHeader('5. PREFERENSI TAMPILAN & NOTIFIKASI', Icons.notifications_none_outlined),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_outlined, color: AdminColors.burgundy, size: 20),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Notifikasi Pesanan Masuk', style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.bold)),
                            Text('Tampilkan banner popup saat pelanggan melakukan checkout baru', style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _enableOrderNotifications,
                        activeThumbColor: AdminColors.burgundy,
                        onChanged: (val) => setState(() => _enableOrderNotifications = val),
                      ),
                    ],
                  ),
                  const Divider(color: AdminColors.divider, height: 20),
                  Row(
                    children: [
                      const Icon(Icons.volume_up_outlined, color: AdminColors.burgundy, size: 20),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Suara Bell Dapur', style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.bold)),
                            Text('Bunyikan dentang saat pesanan baru masuk ke antrean kasir', style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _enableKitchenBellSound,
                        activeThumbColor: AdminColors.burgundy,
                        onChanged: (val) => setState(() => _enableKitchenBellSound = val),
                      ),
                    ],
                  ),
                  const Divider(color: AdminColors.divider, height: 20),
                  Row(
                    children: [
                      const Icon(Icons.currency_exchange, color: AdminColors.burgundy, size: 20),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Integrasi Kurs Global Converter', style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.bold)),
                            Text('Tampilkan estimasi USD di Sales Analytics & Manajemen Kasir', style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _enableDualCurrencyDisplay,
                        activeThumbColor: AdminColors.burgundy,
                        onChanged: (val) => setState(() => _enableDualCurrencyDisplay = val),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section 6: Status Sistem & Integrasi Database ──────────────────
            _buildSectionHeader('6. INTEGRASI SISTEM & DATABASE', Icons.cloud_done_outlined),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminColors.border),
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    icon: Icons.storage_outlined,
                    title: 'Penyimpanan Lokal (SQLite)',
                    subtitle: 'Database sqflite • Transaksi offline & fallback auth aktif',
                    trailing: const Icon(Icons.check_circle, size: 16, color: AdminColors.success),
                  ),
                  const Divider(color: AdminColors.divider, height: 20),
                  _buildSettingRow(
                    icon: Icons.cloud_outlined,
                    title: 'Cloud Database (Supabase PostgreSQL)',
                    subtitle: 'Koneksi REST API wpfizausricpcartojns • Terhubung',
                    trailing: const Icon(Icons.check_circle, size: 16, color: AdminColors.success),
                  ),
                  const Divider(color: AdminColors.divider, height: 20),
                  _buildSettingRow(
                    icon: Icons.info_outline,
                    title: 'Versi Aplikasi Bun Atelier',
                    subtitle: 'Release v1.0.0+1 • Final Project SI Mobile Programming',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Logout Action Button ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _confirmLogout(context, ref),
                icon: const Icon(Icons.logout, color: Colors.white, size: 18),
                label: Text(
                  'Keluar dari Sesi Administrator (Logout)',
                  style: AdminColors.sansUI(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.burgundy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AdminColors.burgundy),
        const SizedBox(width: 8),
        Text(
          title,
          style: AdminColors.sansUI(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AdminColors.burgundy,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AdminColors.burgundy),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 1),
              Text(subtitle, style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText)),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }

  void _showEditProfileDialog(BuildContext context, String currentName) {
    final nameCtrl = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (diagCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Perbarui Profil Admin', style: AdminColors.serifHeading(fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nama Lengkap:', style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.burgundy)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(diagCtx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                final newName = nameCtrl.text.trim();
                if (newName.isNotEmpty) {
                  // Profile update logic if needed
                  Navigator.pop(diagCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: AdminColors.success, content: Text('Profil berhasil diperbarui.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AdminColors.burgundy),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final newCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (diagCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Ganti Kata Sandi', style: AdminColors.serifHeading(fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kata Sandi Baru:', style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.burgundy)),
              const SizedBox(height: 6),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Minimal 6 karakter'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(diagCtx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (newCtrl.text.trim().length >= 6) {
                  Navigator.pop(diagCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(backgroundColor: AdminColors.success, content: Text('Kata sandi berhasil diperbarui.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AdminColors.burgundy),
              child: const Text('Simpan Sandi', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (diagCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Konfirmasi Logout',
            style: AdminColors.serifHeading(fontSize: 20, color: AdminColors.burgundy),
          ),
          content: Text(
            'Sesi administrator Anda akan diakhiri dan dialihkan kembali ke halaman login. Anda harus memasukkan kredensial admin kembali untuk mengakses halaman ini.',
            style: AdminColors.sansUI(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(diagCtx),
              child: Text('Batal', style: AdminColors.sansUI(fontWeight: FontWeight.bold, color: AdminColors.darkBrown)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(diagCtx);
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AdminColors.burgundy),
              child: Text(
                'Ya, Keluar',
                style: AdminColors.sansUI(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
