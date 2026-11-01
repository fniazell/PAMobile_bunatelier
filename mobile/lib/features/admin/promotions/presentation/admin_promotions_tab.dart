import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/admin_colors.dart';
import '../providers/promotions_provider.dart';

class AdminPromotionsTab extends ConsumerStatefulWidget {
  const AdminPromotionsTab({super.key});

  @override
  ConsumerState<AdminPromotionsTab> createState() => _AdminPromotionsTabState();
}

class _AdminPromotionsTabState extends ConsumerState<AdminPromotionsTab> {
  String _selectedFilter = 'ALL'; // 'ALL', 'ACTIVE', 'EXPIRED', 'INACTIVE'
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(int amount) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return fmt.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final promoState = ref.watch(promotionsProvider);
    final promos = promoState.promotions;

    final filtered = promos.where((p) {
      if (_selectedFilter == 'ACTIVE' && !p.isCurrentlyValid) return false;
      if (_selectedFilter == 'EXPIRED' && !p.isExpired) return false;
      if (_selectedFilter == 'INACTIVE' && (p.isActive || p.isExpired)) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return p.code.toLowerCase().contains(q) || p.description.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    final activeCount = promos.where((p) => p.isCurrentlyValid).length;
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AdminColors.warmWhite,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditPromoModal(context),
        backgroundColor: AdminColors.burgundy,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Buat Promo Baru', style: AdminColors.sansUI(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Column(
        children: [
          // ── Header & Campaign Status ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: const BoxDecoration(
              color: AdminColors.warmWhite,
              border: Border(bottom: BorderSide(color: AdminColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 640;
                    final activeBadge = Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AdminColors.sandBeige,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$activeCount Aktif di Checkout',
                        style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.darkBrown),
                      ),
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CAMPAIGNS & REWARDS INCENTIVE',
                                style: AdminColors.sansUI(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AdminColors.burgundy,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Manajemen Voucher & Promosi',
                                style: AdminColors.serifHeading(fontSize: 22),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          activeBadge,
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CAMPAIGNS & REWARDS INCENTIVE',
                                style: AdminColors.sansUI(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AdminColors.burgundy,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Manajemen Voucher & Promosi',
                                style: AdminColors.serifHeading(fontSize: 24),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        activeBadge,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Cari kode promo atau nama kampanye diskon...',
                    hintStyle: AdminColors.sansUI(color: AdminColors.mutedText, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AdminColors.burgundy, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminColors.border)),
                  ),
                ),
                const SizedBox(height: 10),

                // Filter status chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua (${promos.length})', 'ALL'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Aktif ($activeCount)', 'ACTIVE'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Nonaktif (${promos.where((p) => !p.isActive && !p.isExpired).length})', 'INACTIVE'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Kedaluwarsa (${promos.where((p) => p.isExpired).length})', 'EXPIRED'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Promotions List ─────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_offer_outlined, size: 48, color: AdminColors.mutedText),
                        const SizedBox(height: 12),
                        Text('Belum ada promosi yang cocok', style: AdminColors.serifHeading(fontSize: 18)),
                        const SizedBox(height: 4),
                        Text('Buat voucher atau kode promo untuk menarik minat pelanggan', style: AdminColors.sansUI(fontSize: 12, color: AdminColors.mutedText)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final promo = filtered[index];
                      return _buildArtisanalVoucherCard(promo, isWide);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String key) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AdminColors.burgundy,
      backgroundColor: AdminColors.sandBeige,
      labelStyle: AdminColors.sansUI(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? Colors.white : AdminColors.darkBrown,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => setState(() => _selectedFilter = key),
    );
  }

  // ── Artisanal Voucher Ticket Card ─────────────────────────────────────────
  Widget _buildArtisanalVoucherCard(PromotionItem promo, bool isWide) {
    final isValid = promo.isCurrentlyValid;
    final isExpired = promo.isExpired;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Ticket Notch / Discount Stencil
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isValid ? AdminColors.burgundy : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          promo.discountType == 'PERCENT'
                              ? '${promo.discountValue}%'
                              : '${(promo.discountValue / 1000).round()}k',
                          style: AdminColors.serifHeading(fontSize: 22, color: Colors.white),
                        ),
                        Text(
                          promo.discountType == 'PERCENT' ? 'OFF' : 'POTONGAN',
                          style: AdminColors.sansUI(fontSize: 9, fontWeight: FontWeight.w800, color: AdminColors.sandBeige, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Center Content: Code & Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AdminColors.sandBeige,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AdminColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      promo.code,
                                      style: AdminColors.sansUI(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AdminColors.burgundy,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: promo.code));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: AdminColors.burgundy,
                                            content: Text('Kode ${promo.code} disalin ke clipboard!'),
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      child: const Icon(Icons.copy, size: 14, color: AdminColors.burgundy),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isValid
                                      ? const Color(0xFFDCFCE7)
                                      : (isExpired ? const Color(0xFFFEE2E2) : const Color(0xFFF3F4F6)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isValid ? 'AKTIF DI CHECKOUT' : (isExpired ? 'KEDALUWARSA' : 'NONAKTIF'),
                                  style: AdminColors.sansUI(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isValid
                                        ? AdminColors.success
                                        : (isExpired ? AdminColors.error : AdminColors.mutedText),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: promo.isActive,
                            activeThumbColor: AdminColors.burgundy,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: (val) {
                              ref.read(promotionsProvider.notifier).toggleActive(promo.id);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Text(
                        promo.description,
                        style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),

                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            promo.minPurchase > 0
                                ? 'Min. Belanja: ${_formatCurrency(promo.minPurchase)}'
                                : 'Tanpa Minimum Belanja',
                            style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText),
                          ),
                          if (promo.targetCategory != null && promo.targetCategory!.isNotEmpty)
                            Text(
                              '• Kategori: ${promo.targetCategory!.toUpperCase()}',
                              style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.burgundy),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      Text(
                        'Berlaku: ${DateFormat('dd MMM yyyy').format(promo.startDate)} — ${DateFormat('dd MMM yyyy').format(promo.endDate)}',
                        style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AdminColors.divider),

          // Bottom Action Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AdminColors.warmWhite,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 14, color: AdminColors.success),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isValid ? 'Dapat langsung diuji di halaman checkout' : 'Voucher sedang tidak aktif',
                          style: AdminColors.sansUI(fontSize: 10, color: AdminColors.mutedText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showAddEditPromoModal(context, promo: promo),
                      icon: const Icon(Icons.edit_outlined, size: 13, color: AdminColors.burgundy),
                      label: Text('Edit', style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.burgundy)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _confirmDeletePromo(promo),
                      icon: const Icon(Icons.delete_outline, size: 13, color: AdminColors.error),
                      label: Text('Hapus', style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.error)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Add / Edit Promotion Modal ────────────────────────────────────────────
  void _showAddEditPromoModal(BuildContext context, {PromotionItem? promo}) {
    final isEditing = promo != null;
    final codeCtrl = TextEditingController(text: promo?.code ?? '');
    final descCtrl = TextEditingController(text: promo?.description ?? '');
    final valCtrl = TextEditingController(text: promo?.discountValue.toString() ?? '15');
    final minCtrl = TextEditingController(text: promo?.minPurchase.toString() ?? '50000');
    String discType = promo?.discountType ?? 'PERCENT';
    String selectedCategory = promo?.targetCategory ?? 'ALL';
    DateTime startDate = promo?.startDate ?? DateTime.now();
    DateTime endDate = promo?.endDate ?? DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle & Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AdminColors.divider)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isEditing ? 'Edit Kampanye Promo' : 'Buat Voucher Promosi Baru', style: AdminColors.serifHeading(fontSize: 22)),
                                Text('Voucher aktif akan otomatis valid di keranjang & checkout', style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText)),
                              ],
                            ),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(modalCtx)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Fields
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('KODE VOUCHER *'),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: codeCtrl,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. CRAVEBURGER20',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  final r = 1000 + (DateTime.now().millisecondsSinceEpoch % 9000);
                                  codeCtrl.text = 'BUN$r';
                                },
                                icon: const Icon(Icons.auto_awesome, size: 14, color: AdminColors.burgundy),
                                label: Text('Acak', style: AdminColors.sansUI(fontSize: 11, color: AdminColors.burgundy, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          _buildFieldLabel('JUDUL & DESKRIPSI PROMO *'),
                          TextField(
                            controller: descCtrl,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Diskon 20% Menu Burger Spesial Akhir Pekan',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),

                          _buildFieldLabel('JENIS DISKON *'),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('Persentase (%)')),
                                  selected: discType == 'PERCENT',
                                  selectedColor: AdminColors.burgundy,
                                  labelStyle: AdminColors.sansUI(color: discType == 'PERCENT' ? Colors.white : AdminColors.darkBrown, fontWeight: FontWeight.bold),
                                  onSelected: (_) => setModalState(() => discType = 'PERCENT'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('Potongan Tunai (Rp)')),
                                  selected: discType == 'FIXED',
                                  selectedColor: AdminColors.burgundy,
                                  labelStyle: AdminColors.sansUI(color: discType == 'FIXED' ? Colors.white : AdminColors.darkBrown, fontWeight: FontWeight.bold),
                                  onSelected: (_) => setModalState(() => discType = 'FIXED'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel(discType == 'PERCENT' ? 'BESAR PERSEN (%) *' : 'NOMINAL POTONGAN (RP) *'),
                                    TextField(
                                      controller: valCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: discType == 'PERCENT' ? '20' : '25000',
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('MIN. BELANJA (RP)'),
                                    TextField(
                                      controller: minCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(hintText: '50000', border: OutlineInputBorder()),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Target Category
                          _buildFieldLabel('BERLAKU UNTUK KATEGORI'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedCategory,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: 'ALL', child: Text('Semua Menu')),
                                  DropdownMenuItem(value: 'burger', child: Text('Hanya Burgers')),
                                  DropdownMenuItem(value: 'croissant', child: Text('Hanya Croissant Burgers')),
                                  DropdownMenuItem(value: 'sides', child: Text('Hanya Sides & Fries')),
                                  DropdownMenuItem(value: 'drinks', child: Text('Hanya Drinks')),
                                  DropdownMenuItem(value: 'desserts', child: Text('Hanya Desserts')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedCategory = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Validity Dates
                          _buildFieldLabel('PERIODE BERLAKU VOUCHER'),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: modalCtx,
                                      initialDate: startDate,
                                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null) {
                                      setModalState(() => startDate = picked);
                                    }
                                  },
                                  icon: const Icon(Icons.calendar_today, size: 14, color: AdminColors.burgundy),
                                  label: Text(
                                    DateFormat('dd MMM yyyy').format(startDate),
                                    style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.darkBrown),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('—'),
                              ),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: modalCtx,
                                      initialDate: endDate,
                                      firstDate: startDate,
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null) {
                                      setModalState(() => endDate = picked);
                                    }
                                  },
                                  icon: const Icon(Icons.event, size: 14, color: AdminColors.burgundy),
                                  label: Text(
                                    DateFormat('dd MMM yyyy').format(endDate),
                                    style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.darkBrown),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                final code = codeCtrl.text.trim().toUpperCase();
                                final desc = descCtrl.text.trim();
                                final val = int.tryParse(valCtrl.text.trim()) ?? 0;
                                final min = int.tryParse(minCtrl.text.trim()) ?? 0;

                                if (code.isEmpty || desc.isEmpty || val <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Harap lengkapi kode promo, judul, dan nilai diskon!')),
                                  );
                                  return;
                                }

                                if (isEditing) {
                                  final updated = promo.copyWith(
                                    code: code,
                                    description: desc,
                                    discountType: discType,
                                    discountValue: val,
                                    minPurchase: min,
                                    startDate: startDate,
                                    endDate: endDate,
                                    targetCategory: selectedCategory == 'ALL' ? null : selectedCategory,
                                  );
                                  ref.read(promotionsProvider.notifier).updatePromotion(updated);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(backgroundColor: AdminColors.success, content: Text('Promo $code berhasil diperbarui.')),
                                  );
                                } else {
                                  final newPromo = PromotionItem(
                                    id: 'prm-${DateTime.now().millisecondsSinceEpoch}',
                                    code: code,
                                    description: desc,
                                    discountType: discType,
                                    discountValue: val,
                                    minPurchase: min,
                                    startDate: startDate,
                                    endDate: endDate,
                                    targetCategory: selectedCategory == 'ALL' ? null : selectedCategory,
                                    isActive: true,
                                  );
                                  ref.read(promotionsProvider.notifier).addPromotion(newPromo);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(backgroundColor: AdminColors.success, content: Text('Promo baru $code berhasil diaktifkan!')),
                                  );
                                }

                                Navigator.pop(modalCtx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminColors.burgundy,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                isEditing ? 'Simpan Perubahan Promo' : 'Aktifkan Voucher Promosi',
                                style: AdminColors.sansUI(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.w800, color: AdminColors.burgundy, letterSpacing: 0.8),
      ),
    );
  }

  void _confirmDeletePromo(PromotionItem promo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Promo ${promo.code}?', style: AdminColors.serifHeading(fontSize: 18, color: AdminColors.error)),
        content: Text('Voucher ini akan dihapus permanen dan tidak dapat digunakan lagi oleh pelanggan di keranjang.', style: AdminColors.sansUI(fontSize: 13, height: 1.4)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: AdminColors.sansUI(fontWeight: FontWeight.bold, color: AdminColors.darkBrown))),
          ElevatedButton(
            onPressed: () {
              ref.read(promotionsProvider.notifier).deletePromotion(promo.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(backgroundColor: AdminColors.error, content: Text('Promo ${promo.code} telah dihapus.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error),
            child: Text('Ya, Hapus', style: AdminColors.sansUI(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
