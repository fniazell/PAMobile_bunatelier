import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/admin_colors.dart';
import '../../../../core/services/google_maps_service.dart';
import '../../../branch/models/branch_model.dart';
import '../../../branch/providers/branch_provider.dart';

class AdminBranchManagementWidget extends ConsumerWidget {
  const AdminBranchManagementWidget({super.key});

  void _showEditBranchDialog(BuildContext context, WidgetRef ref, BranchModel branch) {
    final nameController = TextEditingController(text: branch.name);
    final cityController = TextEditingController(text: branch.city);
    final countryController = TextEditingController(text: branch.country);
    final addressController = TextEditingController(text: branch.address ?? '');
    final latController = TextEditingController(text: branch.latitude?.toString() ?? '');
    final lngController = TextEditingController(text: branch.longitude?.toString() ?? '');
    final mapsQueryController = TextEditingController(text: branch.mapsQuery ?? '');
    final hoursController = TextEditingController(text: branch.operatingHours ?? '');
    final phoneController = TextEditingController(text: branch.phone ?? '');
    final timezoneController = TextEditingController(text: branch.timezone);
    final currencyController = TextEditingController(text: branch.currencyCode);

    bool isVerified = branch.isVerified;
    bool isActive = branch.isActive;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AdminColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.edit_location_alt_rounded, color: AdminColors.burgundy, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kelola Data Cabang',
                      style: AdminColors.serifHeading(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Branch ID (Readonly)
                      Text(
                        'ID Cabang: ${branch.id} (Terkunci)',
                        style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      // Nama Cabang
                      _buildTextField(
                        controller: nameController,
                        label: 'Nama Cabang',
                        hint: 'Bun Atelier — Flagship',
                      ),
                      const SizedBox(height: 10),

                      // Kota & Negara Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: cityController,
                              label: 'Kota',
                              hint: 'Jakarta / London',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              controller: countryController,
                              label: 'Negara',
                              hint: 'Indonesia / UK',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Alamat Lengkap
                      _buildTextField(
                        controller: addressController,
                        label: 'Alamat Lengkap (Kosongkan jika belum terverifikasi)',
                        hint: 'Jl. Senopati No. 45...',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 10),

                      // Koordinat Lat / Long
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: latController,
                              label: 'Latitude (-90 s/d 90)',
                              hint: '-6.2298',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              controller: lngController,
                              label: 'Longitude (-180 s/d 180)',
                              hint: '106.8097',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Maps Query Fallback
                      _buildTextField(
                        controller: mapsQueryController,
                        label: 'Query Pencarian Google Maps (Fallback)',
                        hint: 'Bun Atelier London, United Kingdom',
                      ),
                      const SizedBox(height: 10),

                      // Jam Operasional & Telepon
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: hoursController,
                              label: 'Jam Buka',
                              hint: '10:00 - 23:00',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              controller: phoneController,
                              label: 'Telepon',
                              hint: '+62 21...',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Zona Waktu & Mata Uang
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: timezoneController,
                              label: 'Zona Waktu',
                              hint: 'Asia/Jayapura / Asia/Jakarta',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              controller: currencyController,
                              label: 'Mata Uang',
                              hint: 'IDR / GBP / MYR / SGD',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Verification Switch
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AdminColors.warmWhite,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status Koordinat Terverifikasi',
                                  style: AdminColors.sansUI(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Aktifkan jika lat & lng sudah dipastikan akurat',
                                  style: AdminColors.sansUI(fontSize: 10, color: AdminColors.mutedText),
                                ),
                              ],
                            ),
                            Switch(
                              value: isVerified,
                              activeThumbColor: AdminColors.success,
                              onChanged: (val) => setDialogState(() => isVerified = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Active Status Switch
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AdminColors.warmWhite,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status Gerai Aktif',
                                  style: AdminColors.sansUI(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Dapat dipilih oleh pelanggan pada pemesanan',
                                  style: AdminColors.sansUI(fontSize: 10, color: AdminColors.mutedText),
                                ),
                              ],
                            ),
                            Switch(
                              value: isActive,
                              activeThumbColor: AdminColors.burgundy,
                              onChanged: (val) => setDialogState(() => isActive = val),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    final lat = double.tryParse(latController.text.trim());
                    final lng = double.tryParse(lngController.text.trim());
                    final query = mapsQueryController.text.trim().isNotEmpty
                        ? mapsQueryController.text.trim()
                        : '${nameController.text.trim()}, ${cityController.text.trim()}';

                    GoogleMapsService.openBranch(
                      query: query,
                      latitude: lat,
                      longitude: lng,
                      isVerified: isVerified && lat != null && lng != null,
                      label: nameController.text.trim(),
                    );
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Test Google Maps'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text('Batal', style: AdminColors.sansUI(color: AdminColors.mutedText)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.burgundy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    // Validasi latitude & longitude jika diisi
                    double? lat;
                    double? lng;
                    if (latController.text.trim().isNotEmpty) {
                      lat = double.tryParse(latController.text.trim());
                      if (lat == null || lat < -90 || lat > 90) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Latitude harus angka valid antara -90 dan 90'),
                            backgroundColor: AdminColors.error,
                          ),
                        );
                        return;
                      }
                    }
                    if (lngController.text.trim().isNotEmpty) {
                      lng = double.tryParse(lngController.text.trim());
                      if (lng == null || lng < -180 || lng > 180) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Longitude harus angka valid antara -180 dan 180'),
                            backgroundColor: AdminColors.error,
                          ),
                        );
                        return;
                      }
                    }

                    final updated = branch.copyWith(
                      name: nameController.text.trim(),
                      city: cityController.text.trim(),
                      country: countryController.text.trim(),
                      address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                      latitude: lat,
                      longitude: lng,
                      mapsQuery: mapsQueryController.text.trim().isEmpty ? null : mapsQueryController.text.trim(),
                      operatingHours: hoursController.text.trim().isEmpty ? null : hoursController.text.trim(),
                      phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                      timezone: timezoneController.text.trim().isEmpty ? branch.timezone : timezoneController.text.trim(),
                      currencyCode: currencyController.text.trim().isEmpty ? branch.currencyCode : currencyController.text.trim().toUpperCase(),
                      isVerified: isVerified,
                      isActive: isActive,
                      updatedAt: DateTime.now(),
                    );

                    await ref.read(branchProvider.notifier).updateBranch(updated);
                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Data cabang ${updated.name} berhasil diperbarui.'),
                          backgroundColor: AdminColors.success,
                        ),
                      );
                    }
                  },
                  child: const Text('Simpan Perubahan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.darkBrown),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AdminColors.sansUI(fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.burgundy)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchState = ref.watch(branchProvider);
    final branches = branchState.branches;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.store_mall_directory_rounded, color: AdminColors.burgundy, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Manajemen 7 Cabang Bun Atelier',
                        style: AdminColors.sansUI(fontSize: 14, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AdminColors.burgundy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${branches.where((b) => b.isActive).length}/${branches.length} Aktif',
                  style: AdminColors.sansUI(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AdminColors.burgundy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Kelola alamat, koordinat terverifikasi, query Google Maps, serta status operasional ketujuh cabang (Senopati, PIK, Maluku, Bali, London, Kuala Lumpur, Singapore).',
            style: AdminColors.sansUI(fontSize: 11.5, color: AdminColors.mutedText),
          ),
          const SizedBox(height: 16),

          // List of Branches
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: branches.length,
            separatorBuilder: (context, index) => const Divider(color: AdminColors.divider, height: 20),
            itemBuilder: (context, index) {
              final branch = branches[index];

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 500;

                  final detailsContent = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            branch.name,
                            style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: branch.isVerified
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              branch.isVerified ? 'Terverifikasi' : 'Pencarian Maps',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: branch.isVerified ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${branch.displayLocation} • ${branch.timezoneLabel} • ${branch.currencyLabel}',
                        style: AdminColors.sansUI(fontSize: 11.5, color: AdminColors.darkBrown),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        branch.address ?? 'Alamat belum diverifikasi • Query: "${branch.effectiveMapsQuery}"',
                        style: AdminColors.sansUI(
                          fontSize: 11,
                          color: branch.address != null ? AdminColors.mutedText : Colors.amber.shade900,
                          fontStyle: branch.address != null ? FontStyle.normal : FontStyle.italic,
                        ),
                      ),
                      if (branch.hasCoordinates) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Koordinat: ${branch.latitude!.toStringAsFixed(4)}, ${branch.longitude!.toStringAsFixed(4)}',
                          style: AdminColors.sansUI(fontSize: 10.5, color: AdminColors.mutedText),
                        ),
                      ],
                    ],
                  );

                  final actionsContent = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Test Google Maps',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.map_outlined, color: AdminColors.burgundy, size: 20),
                        onPressed: () {
                          GoogleMapsService.openBranch(
                            query: branch.effectiveMapsQuery,
                            latitude: branch.latitude,
                            longitude: branch.longitude,
                            isVerified: branch.isVerified,
                            label: branch.name,
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Edit Data Cabang',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit_outlined, color: AdminColors.darkBrown, size: 20),
                        onPressed: () => _showEditBranchDialog(context, ref, branch),
                      ),
                      Switch(
                        value: branch.isActive,
                        activeThumbColor: AdminColors.burgundy,
                        onChanged: (val) {
                          ref.read(branchProvider.notifier).toggleBranchActive(branch.id, val);
                        },
                      ),
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: branch.isVerified
                                    ? AdminColors.success.withValues(alpha: 0.12)
                                    : AdminColors.warning.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  branch.isVerified ? Icons.verified_rounded : Icons.search_rounded,
                                  color: branch.isVerified ? AdminColors.success : AdminColors.warning,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: detailsContent),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            actionsContent,
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: branch.isVerified
                              ? AdminColors.success.withValues(alpha: 0.12)
                              : AdminColors.warning.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            branch.isVerified ? Icons.verified_rounded : Icons.search_rounded,
                            color: branch.isVerified ? AdminColors.success : AdminColors.warning,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: detailsContent),
                      const SizedBox(width: 8),
                      actionsContent,
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
