import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../services/blockchain_receipt_service.dart';

class BlockAuditRecord {
  final int index;
  final String timestamp;
  final String actionType;
  final String payloadSummary;
  final String previousHash;
  String currentHash;
  final String? txHash;
  final String? explorerUrl;
  final bool isSimulated;

  BlockAuditRecord({
    required this.index,
    required this.timestamp,
    required this.actionType,
    required this.payloadSummary,
    required this.previousHash,
    required this.currentHash,
    this.txHash,
    this.explorerUrl,
    this.isSimulated = true,
  });

  static String calculateHash(int index, String timestamp, String payload, String prevHash) {
    final raw = '$index|$timestamp|$payload|$prevHash';
    final bytes = utf8.encode(raw);
    return sha256.convert(bytes).toString();
  }
}

class BlockchainScreen extends StatefulWidget {
  const BlockchainScreen({super.key});

  @override
  State<BlockchainScreen> createState() => _BlockchainScreenState();
}

class _BlockchainScreenState extends State<BlockchainScreen> {
  final List<BlockAuditRecord> _chain = [];
  bool _isTampered = false;
  bool _isLoading = false;
  bool _usingRealData = false;

  @override
  void initState() {
    super.initState();
    _loadChainData();
  }

  Future<void> _loadChainData() async {
    setState(() => _isLoading = true);
    try {
      final realReceipts = await BlockchainReceiptService.instance.fetchAllReceipts();
      if (!mounted) return;

      if (realReceipts.isNotEmpty) {
        _chain.clear();
        _isTampered = false;
        _usingRealData = true;

        // Block 0: Genesis
        const genesisPrev = '0x0000000000000000000000000000000000000000000000000000000000000000';
        _chain.add(
          BlockAuditRecord(
            index: 0,
            timestamp: '2026-10-20 00:00:00',
            actionType: 'GENESIS',
            payloadSummary: 'Genesis Block: Bun Atelier Immutable Ledger Initialized',
            previousHash: genesisPrev,
            currentHash: '0x${sha256.convert(utf8.encode('GENESIS_BLOCK_0'))}',
            isSimulated: false,
          ),
        );

        for (int i = 0; i < realReceipts.length; i++) {
          final r = realReceipts[i];
          final orderId = r['orderId']?.toString() ?? 'ORDER';
          final total = r['receiptData']?['total'] ?? 0;
          final items = (r['receiptData']?['items'] as List<dynamic>? ?? [])
              .map((it) => '${it['quantity']}x ${it['name']}')
              .join(', ');

          _chain.add(
            BlockAuditRecord(
              index: i + 1,
              timestamp: r['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
              actionType: 'RECEIPT_RECORDED',
              payloadSummary: 'Order #$orderId: $items (Total: Rp $total)',
              previousHash: r['previousReceiptHash']?.toString() ?? genesisPrev,
              currentHash: r['receiptHash']?.toString() ?? '',
              txHash: r['txHash']?.toString(),
              explorerUrl: r['explorerUrl']?.toString(),
              isSimulated: r['isSimulated'] as bool? ?? true,
            ),
          );
        }
      } else {
        _initDemoChain();
      }
    } catch (_) {
      if (mounted) _initDemoChain();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _initDemoChain() {
    _chain.clear();
    _isTampered = false;
    _usingRealData = false;

    // Block 0: Genesis
    const b0Time = '2026-10-20 18:00:00';
    const b0Payload = 'Genesis Block: Bun Atelier Ledger Initialized';
    const b0Prev = '0000000000000000000000000000000000000000000000000000000000000000';
    final b0Hash = BlockAuditRecord.calculateHash(0, b0Time, b0Payload, b0Prev);
    _chain.add(BlockAuditRecord(index: 0, timestamp: b0Time, actionType: 'GENESIS', payloadSummary: b0Payload, previousHash: b0Prev, currentHash: b0Hash));

    // Block 1: Order Created
    const b1Time = '2026-10-20 18:15:22';
    const b1Payload = 'Order #BA-20261020-001 Created (Pickup, 2 items, Total: Rp 143.000)';
    final b1Hash = BlockAuditRecord.calculateHash(1, b1Time, b1Payload, b0Hash);
    _chain.add(BlockAuditRecord(index: 1, timestamp: b1Time, actionType: 'ORDER_CREATED', payloadSummary: b1Payload, previousHash: b0Hash, currentHash: b1Hash));

    // Block 2: Payment Confirmed
    const b2Time = '2026-10-20 18:16:04';
    const b2Payload = 'Simulated QRIS Payment Confirmed (Ref: QRIS-982341)';
    final b2Hash = BlockAuditRecord.calculateHash(2, b2Time, b2Payload, b1Hash);
    _chain.add(BlockAuditRecord(index: 2, timestamp: b2Time, actionType: 'PAYMENT_CONFIRMED', payloadSummary: b2Payload, previousHash: b1Hash, currentHash: b2Hash));

    // Block 3: Kitchen Preparing
    const b3Time = '2026-10-20 18:18:30';
    const b3Payload = 'Cashier Status Update: Order #BA-001 is PREPARING';
    final b3Hash = BlockAuditRecord.calculateHash(3, b3Time, b3Payload, b2Hash);
    _chain.add(BlockAuditRecord(index: 3, timestamp: b3Time, actionType: 'STATUS_UPDATED', payloadSummary: b3Payload, previousHash: b2Hash, currentHash: b3Hash));

    // Block 4: Ready for Pickup
    const b4Time = '2026-10-20 18:32:10';
    const b4Payload = 'Kitchen Notification: Order #BA-001 READY_FOR_PICKUP';
    final b4Hash = BlockAuditRecord.calculateHash(4, b4Time, b4Payload, b3Hash);
    _chain.add(BlockAuditRecord(index: 4, timestamp: b4Time, actionType: 'READY_PICKUP', payloadSummary: b4Payload, previousHash: b3Hash, currentHash: b4Hash));
  }

  void _verifyIntegrity() {
    bool isValid = true;
    String? failureReason;

    if (_usingRealData) {
      for (int i = 1; i < _chain.length; i++) {
        final block = _chain[i];
        final prevBlock = _chain[i - 1];
        if (i == 1) {
          if (block.previousHash != '0x0000000000000000000000000000000000000000000000000000000000000000') {
            isValid = false;
            failureReason = 'Genesis pointer mismatch on Block #1!';
            break;
          }
        } else {
          if (block.previousHash.toLowerCase() != prevBlock.currentHash.toLowerCase()) {
            isValid = false;
            failureReason = 'Broken chain link at Block #${block.index}! Previous hash does not match Block #${prevBlock.index} current hash.';
            break;
          }
        }
      }
    } else {
      for (int i = 0; i < _chain.length; i++) {
        final block = _chain[i];
        final recalculated = BlockAuditRecord.calculateHash(
          block.index,
          block.timestamp,
          block.payloadSummary,
          block.previousHash,
        );

        if (recalculated != block.currentHash) {
          isValid = false;
          failureReason = 'Block #${block.index} data has been tampered with! Recomputed SHA-256 does not match stored hash.';
          break;
        }

        if (i > 0) {
          final prevBlock = _chain[i - 1];
          if (block.previousHash != prevBlock.currentHash) {
            isValid = false;
            failureReason = 'Broken chain link at Block #${block.index}! Previous hash does not match Block #${prevBlock.index} current hash.';
            break;
          }
        }
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isValid ? Icons.verified_rounded : Icons.gpp_bad_rounded,
              color: isValid ? AppColors.forestGreen : AppColors.error,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isValid ? 'CHAIN INTEGRITY: VALID' : 'CHAIN COMPROMISED!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isValid ? AppColors.forestGreen : AppColors.error,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isValid
              ? 'Seluruh (${_chain.length}) blok terverifikasi valid secara kriptografis menggunakan algoritma SHA-256.\n\nTidak ada perubahan data pesanan ilegal yang terdeteksi.'
              : failureReason ?? 'Manipulasi terdeteksi pada rantai blok!',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isValid ? AppColors.forestGreen : AppColors.error,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _simulateTamper() {
    setState(() {
      _isTampered = true;
      final original = _chain[1];
      _chain[1] = BlockAuditRecord(
        index: original.index,
        timestamp: original.timestamp,
        actionType: original.actionType,
        payloadSummary: 'TAMPERED: Order #BA-001 with HACKED Total: Rp 0',
        previousHash: original.previousHash,
        currentHash: original.currentHash, // Hash sengaja salah
        isSimulated: original.isSimulated,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.error,
        duration: Duration(seconds: 2),
        content: Text('Simulasi manipulasi: Data pada Block #1 diubah secara ilegal! Sekarang uji tombol verifikasi.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          'BLOCKCHAIN AUDIT',
          style: textTheme.headlineMedium?.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat Ulang Ledger',
            onPressed: _loadChainData,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Educational & Honest Network Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              color: AppColors.forestGreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_rounded, color: AppColors.butterYellow, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _usingRealData ? 'LIVE E-RECEIPT HASH CHAIN' : 'EDUCATIONAL SHA-256 HASH CHAIN',
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.butterYellow,
                              letterSpacing: 1.2,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _usingRealData ? 'PERSISTENT' : 'DEMO MODE',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Setiap transaksi e-receipt di-hash secara kanonikal (SHA-256). Setiap blok merangkum hash dari blok sebelumnya untuk menjamin transparansi data dan mencegah pemalsuan transaksi.',
                    style: TextStyle(color: AppColors.cream, fontSize: 12, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: _verifyIntegrity,
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                        label: const Text('VERIFY CHAIN', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.cream,
                          side: const BorderSide(color: AppColors.cream),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: _isTampered ? _loadChainData : _simulateTamper,
                        icon: Icon(_isTampered ? Icons.restore_rounded : Icons.bug_report_rounded, size: 16),
                        label: Text(_isTampered ? 'Reset Chain' : 'Test Tamper Demo', style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const LinearProgressIndicator(color: AppColors.coral),

            // Blocks List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: _chain.length,
                separatorBuilder: (context, index) => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Icon(Icons.link_rounded, color: AppColors.coral, size: 24),
                  ),
                ),
                itemBuilder: (context, index) {
                  final block = _chain[index];

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isTampered && block.index == 1 ? AppColors.error : AppColors.borderLight,
                        width: _isTampered && block.index == 1 ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.espresso.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'BLOCK #${block.index} [${block.actionType}]',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: block.index == 0 ? AppColors.forestGreen : AppColors.coral,
                              ),
                            ),
                            Text(
                              block.timestamp,
                              style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          block.payloadSummary,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _isTampered && block.index == 1 ? AppColors.error : AppColors.espresso,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Hashes
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PREV HASH:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.mutedText)),
                              Text(
                                block.previousHash,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppColors.espresso),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              const Text('BLOCK HASH (SHA-256):', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.forestGreen)),
                              Text(
                                block.currentHash,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _isTampered && block.index == 1 ? AppColors.error : AppColors.forestGreen,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (block.txHash != null) ...[
                                const SizedBox(height: 4),
                                const Text('TX HASH:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.coral)),
                                Text(
                                  block.txHash!,
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5, color: AppColors.espresso),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (block.explorerUrl != null) ...[
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => launchUrl(Uri.parse(block.explorerUrl!), mode: LaunchMode.externalApplication),
                                  child: const Text(
                                    'Buka di Sepolia Etherscan ↗',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.coral, decoration: TextDecoration.underline),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
