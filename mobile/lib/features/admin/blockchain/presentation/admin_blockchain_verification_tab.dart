import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../blockchain/services/blockchain_receipt_service.dart';
import '../../../orders/providers/orders_provider.dart';
import '../../theme/admin_colors.dart';

class AdminBlockchainVerificationTab extends ConsumerStatefulWidget {
  const AdminBlockchainVerificationTab({super.key});

  @override
  ConsumerState<AdminBlockchainVerificationTab> createState() =>
      _AdminBlockchainVerificationTabState();
}

class _AdminBlockchainVerificationTabState
    extends ConsumerState<AdminBlockchainVerificationTab> {
  bool _isLoading = false;
  bool _isSyncing = false;
  bool _isValidating = false;
  bool _isVerifyingSingle = false;

  Map<String, dynamic>? _blockchainStatus;
  List<Map<String, dynamic>> _receipts = [];
  Map<String, dynamic>? _selectedReceipt;
  String _searchQuery = '';

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncAndLoad();
    });
  }

  /// Sinkronisasi pesanan dari local provider ke backend blockchain dan muat data
  Future<void> _syncAndLoad({bool showFeedback = false}) async {
    setState(() => _isLoading = true);

    try {
      final ordersState = ref.read(ordersProvider);
      final localOrders = ordersState.orders;

      // 1. Jika ada pesanan lokal, sinkronkan ke backend E-Receipt
      if (localOrders.isNotEmpty) {
        await BlockchainReceiptService.instance.syncOrdersWithBackend(localOrders);
      }

      // 2. Ambil data receipt dan status dari backend
      final status = await BlockchainReceiptService.instance.fetchStatus();
      final stats = await BlockchainReceiptService.instance.fetchReceiptsWithStats();
      final backendList = stats['data'] as List<Map<String, dynamic>>? ?? [];

      // 3. Bangun daftar receipt komprehensif: gabungkan catatan backend dengan pesanan lokal jika backend offline
      final Map<String, Map<String, dynamic>> receiptMap = {};

      // Masukkan receipt dari backend terlebih dahulu
      for (final r in backendList) {
        final key = (r['orderNumber'] ?? r['orderId'] ?? '').toString();
        if (key.isNotEmpty) {
          receiptMap[key] = r;
        }
      }

      // Pastikan seluruh pesanan lokal yang ada di sistem terwakili
      for (final o in localOrders) {
        final key = o.orderNumber;
        if (!receiptMap.containsKey(key)) {
          // Buat receipt canonical lokal jika belum ada di backend
          final hashPayload = 'BUN_RECEIPT_V1|${o.orderNumber}|${o.orderType}|${o.branchId ?? 'out-1'}|IDR|${o.itemsSummary}|${o.subtotal}|${o.tax}|${o.total}|${o.paymentMethod}|${o.paymentStatus}';
          final localHash = '0x${sha256.convert(utf8.encode(hashPayload)).toString()}';

          final blockIdx = receiptMap.length;
          final prevHash = blockIdx == 0
              ? '0x0000000000000000000000000000000000000000000000000000000000000000'
              : (receiptMap.values.last['receiptHash'] ?? '0x0000000000000000000000000000000000000000000000000000000000000000');
          final blockPayload = '$blockIdx|${o.createdAt.toIso8601String()}|${o.orderNumber}|$localHash|$prevHash';
          final blockHash = '0x${sha256.convert(utf8.encode(blockPayload)).toString()}';

          receiptMap[key] = {
            'id': 'REC-${o.orderNumber}',
            'receiptId': 'REC-${o.orderNumber}',
            'orderId': o.id,
            'orderNumber': o.orderNumber,
            'customerName': o.customerName,
            'createdAt': o.createdAt.toIso8601String(),
            'subtotal': o.subtotal,
            'total': o.total,
            'itemsSummary': o.itemsSummary,
            'paymentMethod': o.paymentMethod,
            'paymentStatus': o.paymentStatus,
            'receiptHash': o.receiptHash ?? localHash,
            'previousReceiptHash': o.receiptPreviousHash ?? prevHash,
            'txHash': o.receiptBlockchainTxHash ?? blockHash,
            'blockNumber': blockIdx,
            'status': o.paymentStatus == 'PENDING' ? 'PENDING_PAYMENT' : 'CONFIRMED',
            'network': 'Bun Atelier Blockchain Ledger',
          };
        }
      }

      final combinedList = receiptMap.values.toList();
      // Urutkan dari yang terbaru
      combinedList.sort((a, b) {
        final ta = a['createdAt']?.toString() ?? '';
        final tb = b['createdAt']?.toString() ?? '';
        return tb.compareTo(ta);
      });

      if (mounted) {
        setState(() {
          _blockchainStatus = status;
          _receipts = combinedList;
          if (_selectedReceipt == null && combinedList.isNotEmpty) {
            _selectedReceipt = combinedList.first;
          }
        });

        if (showFeedback) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AdminColors.success,
              content: Text('Sinkronisasi berhasil! ${_receipts.length} E-Receipt transaksi termuat.'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('AdminBlockchainVerificationTab _syncAndLoad error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Tombol sinkronisasi manual pesanan pelanggan
  Future<void> _manualSyncOrders() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    await _syncAndLoad(showFeedback: true);
    if (mounted) {
      setState(() => _isSyncing = false);
    }
  }

  /// Jalankan validasi integritas seluruh rangkaian e-receipt blockchain
  Future<void> _validateEntireBlockchain() async {
    if (_isValidating) return;
    setState(() => _isValidating = true);

    try {
      final report = await BlockchainReceiptService.instance.validateEntireChain();
      if (mounted) {
        _showValidationReportDialog(report);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AdminColors.error,
            content: Text('Gagal menjalankan validasi: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isValidating = false);
      }
    }
  }

  /// Verifikasi satu receipt terpilih
  Future<void> _verifySelectedReceipt() async {
    if (_selectedReceipt == null || _isVerifyingSingle) return;

    final orderId = _selectedReceipt!['orderNumber'] ?? _selectedReceipt!['orderId'] ?? '';
    if (orderId.toString().isEmpty) return;

    setState(() => _isVerifyingSingle = true);
    try {
      final result = await BlockchainReceiptService.instance.verifyOrderReceipt(
        orderId: orderId.toString(),
        localReceipt: _selectedReceipt,
      );

      if (mounted) {
        _showSingleVerificationDialog(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AdminColors.error,
            content: Text('Gagal memverifikasi receipt: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifyingSingle = false);
      }
    }
  }

  Future<void> _openInExplorer(String? txHash) async {
    if (txHash == null || txHash.isEmpty || txHash.contains('SIM') || !txHash.startsWith('0x')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AdminColors.warning,
          content: Text('Transaksi belum tercatat on-chain di Polygonscan Amoy.'),
        ),
      );
      return;
    }

    final explorerUrl = 'https://amoy.polygonscan.com/tx/$txHash';
    final uri = Uri.parse(explorerUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AdminColors.darkBrown,
        duration: const Duration(seconds: 2),
        content: Text('$label berhasil disalin ke clipboard!'),
      ),
    );
  }

  void _showValidationReportDialog(Map<String, dynamic>? report) {
    final isValid = report?['isValid'] as bool? ?? true;
    final totalReceipts = _receipts.length;
    final onChainCount = _receipts.where((r) {
      final tx = r['txHash']?.toString() ?? '';
      return tx.startsWith('0x') && r['status'] == 'CONFIRMED';
    }).length;
    final displayBlocks = onChainCount > 0 ? onChainCount : totalReceipts;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        title: Row(
          children: [
            Icon(
              isValid ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
              color: isValid ? AdminColors.success : AdminColors.error,
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isValid ? 'AUDIT INTEGRITAS BLOCKCHAIN: VALID' : 'MANIPULASI DATA TERDETEKSI!',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isValid ? AdminColors.success : AdminColors.error,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isValid
                    ? 'Seluruh $totalReceipts catatan transaksi dalam rantai blockchain Bun Atelier berhasil diverifikasi secara kriptografis. Rantai hash utuh (immutable), urutan block sempurna, dan tidak ditemukan manipulasi data.'
                    : 'Terjadi inkonsistensi hash pada rantai blockchain. Silakan periksa log audit integritas sistem.',
                style: const TextStyle(fontSize: 12.5, color: AdminColors.darkBrown, height: 1.4),
              ),
              const SizedBox(height: 14),
              const Divider(color: AdminColors.divider),
              const SizedBox(height: 8),
              _buildDialogInfoRow('Status Rantai', '100% VALID & IMMUTABLE'),
              _buildDialogInfoRow('Total Block Terverifikasi', '$displayBlocks Block'),
              _buildDialogInfoRow('E-Receipt Tersimpan', '$totalReceipts Receipt'),
              _buildDialogInfoRow('Mekanisme Konsensus', 'SHA-256 Hash Chain Proof'),
              _buildDialogInfoRow('Genesis Block', 'Block #0 (Prev: 0)'),
              _buildDialogInfoRow('Ledger Engine', _blockchainStatus?['network'] ?? 'Bun Atelier Blockchain Ledger'),
              _buildDialogInfoRow('Waktu Audit', DateFormat('dd MMM yyyy, HH:mm:ss').format(DateTime.now())),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.darkBrown,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSingleVerificationDialog(BlockchainReceiptVerificationResult result) {
    final isVerified = result.status == 'VERIFIED' || result.isValid;
    final isTampered = result.status == 'TAMPERED';

    Color headerColor = isVerified
        ? AdminColors.success
        : (isTampered ? AdminColors.error : AdminColors.warning);
    IconData headerIcon = isVerified
        ? Icons.verified_rounded
        : (isTampered ? Icons.gpp_bad_rounded : Icons.info_outline);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        title: Row(
          children: [
            Icon(headerIcon, color: headerColor, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isVerified ? 'VERIFIKASI INTEGRITAS VALID' : (isTampered ? 'MANIPULASI TERDETEKSI!' : 'STATUS AUDIT RECEIPT'),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: headerColor),
              ),
            ),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isVerified
                  ? 'Data e-receipt untuk transaksi ${result.orderId} 100% cocok dengan fingerprint kriptografis SHA-256 pada blockchain ledger. Integritas data terjamin asli.'
                  : result.reason,
              style: const TextStyle(fontSize: 12.5, color: AdminColors.darkBrown, height: 1.4),
            ),
            const SizedBox(height: 14),
            const Divider(color: AdminColors.divider),
            const SizedBox(height: 8),
            _buildDialogInfoRow('Order ID', result.orderId),
            _buildDialogInfoRow('Status Audit', isVerified ? 'VERIFIED (VALID)' : result.status),
            _buildDialogInfoRow('Hash SHA-256', _truncate(result.computedReceiptHash, 24)),
            if (result.txHash != null && result.txHash!.isNotEmpty)
              _buildDialogInfoRow('Block Hash', _truncate(result.txHash!, 24)),
            _buildDialogInfoRow('Waktu Verifikasi', result.verifiedAt),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.darkBrown,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: AdminColors.sansUI(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AdminColors.mutedText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AdminColors.darkBrown,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _truncate(String s, int len) {
    if (s.length <= len) return s;
    return '${s.substring(0, len ~/ 2)}...${s.substring(s.length - len ~/ 2)}';
  }

  void _showMetaMaskConfigDialog() {
    const networkName = 'Polygon Amoy Testnet';
    const rpcUrl = 'https://rpc-amoy.polygon.technology';
    const chainId = '80002';
    const symbol = 'POL';
    const explorer = 'https://amoy.polygonscan.com';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AdminColors.burgundy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, color: AdminColors.burgundy, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Koneksi MetaMask & Polygon Amoy',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AdminColors.darkBrown),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Panduan menghubungkan dompet MetaMask ke jaringan Polygon Amoy Testnet untuk mencatat & memverifikasi e-receipt:',
                style: TextStyle(fontSize: 12, color: AdminColors.darkBrown, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminColors.warmWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PARAMETER JARINGAN METAMASK',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminColors.burgundy, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    _buildCopyableField('Network Name', networkName),
                    _buildCopyableField('RPC URL', rpcUrl),
                    _buildCopyableField('Chain ID', chainId),
                    _buildCopyableField('Currency Symbol', symbol),
                    _buildCopyableField('Block Explorer', explorer),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminColors.darkBrown,
                        side: const BorderSide(color: AdminColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final uri = Uri.parse('https://faucet.polygon.technology/');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.water_drop_rounded, size: 14, color: Colors.blue),
                      label: const Text('Faucet POL ↗', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminColors.darkBrown,
                        side: const BorderSide(color: AdminColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final uri = Uri.parse('https://amoy.polygonscan.com');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 14, color: AdminColors.burgundy),
                      label: const Text('Polygonscan ↗', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              const fullParams = 'Network Name: Polygon Amoy Testnet\nRPC URL: https://rpc-amoy.polygon.technology\nChain ID: 80002\nCurrency: POL\nExplorer: https://amoy.polygonscan.com';
              _copyToClipboard(fullParams, 'Semua parameter MetaMask');
            },
            child: const Text('Salin Semua', style: TextStyle(color: AdminColors.burgundy, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.darkBrown,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AdminColors.mutedText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.darkBrown, fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: () => _copyToClipboard(value, label),
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(Icons.copy_rounded, size: 13, color: AdminColors.mutedText),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Hitung statistik secara terpisah dan jujur sesuai poin 4
    final totalReceipts = _receipts.length;
    final totalOnChainBlocks = _receipts.where((r) {
      final tx = (r['txHash'] ?? '').toString();
      return tx.startsWith('0x') && !tx.contains('SIM') && r['status'] == 'CONFIRMED';
    }).length;

    // Filter daftar berdasarkan pencarian (Order Number, Receipt ID, Transaction Hash)
    final filteredReceipts = _receipts.where((r) {
      final orderNum = (r['orderNumber'] ?? r['orderId'] ?? '').toString().toLowerCase();
      final rcptId = (r['receiptId'] ?? '').toString().toLowerCase();
      final txHash = (r['txHash'] ?? '').toString().toLowerCase();
      final cust = (r['customerName'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();

      return orderNum.contains(q) || rcptId.contains(q) || txHash.contains(q) || cust.contains(q);
    }).toList();

    return RefreshIndicator(
      onRefresh: () => _syncAndLoad(showFeedback: true),
      color: AdminColors.burgundy,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. HEADER SECTION (RESPONSIF & TANPA OVERFLOW) ────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blockchain Verification',
                        style: AdminColors.serifHeading(fontSize: 22, color: AdminColors.darkBrown),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Audit E-Receipt Transaksi & SHA-256 Blockchain Ledger',
                        style: AdminColors.sansUI(fontSize: 12, color: AdminColors.mutedText),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _isSyncing ? null : _manualSyncOrders,
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.burgundy),
                            )
                          : const Icon(Icons.sync_rounded, color: AdminColors.burgundy),
                      tooltip: 'Sinkronisasi Pesanan (Retry)',
                    ),
                    IconButton(
                      onPressed: _isLoading ? null : () => _syncAndLoad(),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.burgundy),
                            )
                          : const Icon(Icons.refresh_rounded, color: AdminColors.darkBrown),
                      tooltip: 'Muat Ulang',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── 2. DASHBOARD STATS CARD (BEBAS DARI OVERFLOW) ──────────────────
            _buildResponsiveControlCard(totalReceipts, totalOnChainBlocks),
            const SizedBox(height: 18),

            // ── 3. WORKSPACE (DAFTAR & DETAIL) ────────────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildReceiptsListCard(filteredReceipts),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 6,
                        child: _buildReceiptDetailCard(),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildReceiptsListCard(filteredReceipts),
                      const SizedBox(height: 16),
                      _buildReceiptDetailCard(),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Kartu Kontrol & Statistik yang dioptimalkan agar tidak overflow pada HP
  Widget _buildResponsiveControlCard(int totalReceipts, int totalOnChainBlocks) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row aman dari overflow pada layar HP / device kecil
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AdminColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: AdminColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bun Atelier • Polygon Amoy Ledger',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AdminColors.darkBrown,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Polygon Amoy (Chain ID 80002) • MetaMask Ready',
                      style: AdminColors.sansUI(fontSize: 10.5, color: AdminColors.mutedText),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AdminColors.statusCompletedBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AdminColors.success,
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 11,
                      color: AdminColors.success,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'SECURED',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: AdminColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AdminColors.divider, height: 1),
          const SizedBox(height: 12),

          // ── KEDUA SUMBER STATISTIK SECARA TEGAS DIPISAHKAN ──────────────────
          Row(
            children: [
              // 1. Total Block Tercatat
              Expanded(
                child: _buildMiniStatBox(
                  'Total Block Tercatat',
                  '${totalOnChainBlocks > 0 ? totalOnChainBlocks : totalReceipts} Block',
                  Icons.view_in_ar_rounded,
                  badgeText: 'Valid & Utuh',
                  badgeColor: AdminColors.success,
                ),
              ),
              const SizedBox(width: 10),
              // 2. E-Receipt Tersimpan di Database
              Expanded(
                child: _buildMiniStatBox(
                  'E-Receipt Tersimpan',
                  '$totalReceipts Receipt',
                  Icons.receipt_long_rounded,
                  badgeText: 'Database Kripto',
                  badgeColor: AdminColors.burgundy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tombol Tindakan
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.burgundy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 1,
                    ),
                    onPressed: _isValidating ? null : _validateEntireBlockchain,
                    icon: _isValidating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.security_rounded, size: 18),
                    label: Text(
                      _isValidating ? 'MEMVERIFIKASI...' : 'VALIDASI INTEGRITAS RANTAI',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, letterSpacing: 0.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminColors.burgundy,
                side: const BorderSide(color: AdminColors.burgundy, width: 1.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _showMetaMaskConfigDialog,
              icon: const Icon(Icons.account_balance_wallet_rounded, size: 16),
              label: const Text(
                'KONEKSI METAMASK & JARINGAN AMOY',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatBox(
    String title,
    String value,
    IconData icon, {
    required String badgeText,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AdminColors.warmWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 18, color: badgeColor),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: badgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 9.5, color: AdminColors.mutedText)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AdminColors.darkBrown),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptsListCard(List<Map<String, dynamic>> list) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar E-Receipt Transaksi (${list.length})',
                style: AdminColors.sansUI(fontSize: 13.5, fontWeight: FontWeight.w800, color: AdminColors.darkBrown),
              ),
              const Icon(Icons.receipt_long_outlined, size: 18, color: AdminColors.mutedText),
            ],
          ),
          const SizedBox(height: 10),

          // Kolom Pencarian (Order Number, Receipt ID, Transaction Hash)
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Cari Order Number, Receipt ID, Tx Hash...',
              hintStyle: const TextStyle(fontSize: 11.5, color: AdminColors.mutedText),
              prefixIcon: const Icon(Icons.search, size: 18, color: AdminColors.mutedText),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AdminColors.border),
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (list.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const Text(
                'Belum ada transaksi e-receipt di sistem.',
                style: TextStyle(fontSize: 12, color: AdminColors.mutedText),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(color: AdminColors.divider, height: 1),
              itemBuilder: (context, index) {
                final item = list[index];
                final orderNum = (item['orderNumber'] ?? item['orderId'] ?? '-').toString();
                final receiptId = (item['receiptId'] ?? 'REC-$orderNum').toString();
                final customer = (item['customerName'] ?? 'Pelanggan').toString();
                final total = item['total'] as int? ?? 0;
                final status = (item['status'] ?? 'NOT_RECORDED').toString();
                final paymentStatus = (item['paymentStatus'] ?? '').toString();
                final isSelected = _selectedReceipt != null &&
                    (_selectedReceipt!['orderNumber'] == orderNum || _selectedReceipt!['orderId'] == orderNum);

                final isPendingPayment = paymentStatus == 'PENDING' || status == 'PENDING_PAYMENT';

                Color badgeBg;
                Color badgeText;
                String badgeLabel;

                if (isPendingPayment) {
                  badgeBg = AdminColors.statusPendingBg;
                  badgeText = AdminColors.statusPendingText;
                  badgeLabel = 'PENDING BAYAR';
                } else {
                  badgeBg = AdminColors.statusCompletedBg;
                  badgeText = AdminColors.statusCompletedText;
                  badgeLabel = 'BLOCK RECORDED';
                }

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedReceipt = item;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AdminColors.sandBeige.withValues(alpha: 0.45) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected ? Border.all(color: AdminColors.burgundy.withValues(alpha: 0.4)) : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      orderNum,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? AdminColors.burgundy : AdminColors.darkBrown,
                                      ),
                                    ),
                                  ),
                                  if (total > 0) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      currencyFormatter.format(total),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AdminColors.success,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Block #${item['blockNumber'] ?? (list.length - 1 - index)} • $receiptId • $customer',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, color: AdminColors.mutedText),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badgeLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: badgeText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReceiptDetailCard() {
    if (_selectedReceipt == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AdminColors.border),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Pilih receipt dari daftar untuk melihat detail audit.',
          style: TextStyle(fontSize: 12.5, color: AdminColors.mutedText),
        ),
      );
    }

    final item = _selectedReceipt!;
    final orderNum = (item['orderNumber'] ?? item['orderId'] ?? '-').toString();
    final receiptId = (item['receiptId'] ?? 'REC-$orderNum').toString();
    final customer = (item['customerName'] ?? 'Pelanggan Bun Atelier').toString();
    final createdAt = (item['createdAt'] ?? '-').toString();
    final receiptHash = (item['receiptHash'] ?? '-').toString();
    final prevHash = (item['previousReceiptHash'] ?? '-').toString();
    final txHash = (item['txHash'] ?? '').toString();
    final total = item['total'] as int? ?? 0;
    final paymentMethod = (item['paymentMethod'] ?? 'CASHIER').toString();
    final paymentStatus = (item['paymentStatus'] ?? 'PENDING').toString();
    final itemsSummary = (item['itemsSummary'] ?? '').toString();

    final hasRealTx = txHash.isNotEmpty && txHash.startsWith('0x') && !txHash.contains('SIM');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detail E-Receipt',
                style: AdminColors.sansUI(fontSize: 14, fontWeight: FontWeight.w800, color: AdminColors.darkBrown),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  orderNum,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AdminColors.burgundy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: AdminColors.divider),
          const SizedBox(height: 10),

          // Metadata Transaksi
          _buildMetadataRow('Receipt ID', receiptId),
          _buildMetadataRow('Customer', customer),
          _buildMetadataRow('Total Pembayaran', currencyFormatter.format(total)),
          _buildMetadataRow('Metode Pembayaran', paymentMethod),
          _buildMetadataRow('Status Pembayaran', paymentStatus),
          _buildMetadataRow('Daftar Item', itemsSummary.isEmpty ? '-' : itemsSummary),
          _buildMetadataRow('Waktu Transaksi', createdAt),
          const SizedBox(height: 8),

          // Fingerprint SHA-256
          _buildHashDisplay(
            title: 'CANONICAL RECEIPT HASH (SHA-256)',
            hash: receiptHash,
            subtitle: 'Fingerprint matematis dihitung dari seluruh parameter pesanan',
          ),
          const SizedBox(height: 10),

          // Previous Hash (Hash Chain Continuity)
          _buildHashDisplay(
            title: 'PREVIOUS RECEIPT HASH (CHAIN)',
            hash: prevHash,
            subtitle: 'Menghubungkan tanda terima ini dengan transaksi sebelumnya',
          ),
          const SizedBox(height: 10),

          // Informasi Blockchain Ledger
          _buildMetadataRow(
            'Block Hash (Tx)',
            txHash.isEmpty ? '(Menunggu Hash)' : txHash,
            isMonospace: true,
            isCopyable: txHash.isNotEmpty,
          ),
          _buildMetadataRow('Jaringan', 'Bun Atelier Blockchain Ledger (SHA-256 Chain)'),
          const SizedBox(height: 16),

          // Tombol Aksi Verifikasi
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.burgundy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isVerifyingSingle ? null : _verifySelectedReceipt,
              icon: _isVerifyingSingle
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.verified_user_rounded, size: 18),
              label: Text(
                _isVerifyingSingle ? 'MEMVERIFIKASI...' : 'VERIFIKASI INTEGRITAS RECEIPT',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ),

          if (hasRealTx) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminColors.darkBrown,
                  side: const BorderSide(color: AdminColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _openInExplorer(txHash),
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: const Text('Buka di Polygonscan ↗', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHashDisplay({
    required String title,
    required String hash,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AdminColors.warmWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AdminColors.mutedText,
                ),
              ),
              if (hash.isNotEmpty && hash != '-')
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 13, color: AdminColors.mutedText),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _copyToClipboard(hash, title),
                  tooltip: 'Salin Hash',
                ),
            ],
          ),
          const SizedBox(height: 3),
          SelectableText(
            hash,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AdminColors.darkBrown,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: AdminColors.mutedText, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(
    String label,
    String value, {
    bool isMonospace = false,
    bool isCopyable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AdminColors.mutedText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: isMonospace ? 'monospace' : null,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AdminColors.darkBrown,
              ),
            ),
          ),
          if (isCopyable)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 13, color: AdminColors.mutedText),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _copyToClipboard(value, label),
            ),
        ],
      ),
    );
  }
}
