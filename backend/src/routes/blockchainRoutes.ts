import { Router, Request, Response } from 'express';
import { BlockchainService } from '../services/blockchainService.js';
import { CanonicalReceiptData } from '../services/receiptCanonicalizer.js';
import { verifyAdmin } from '../middleware/authMiddleware.js';

const router = Router();
const blockchainService = BlockchainService.getInstance();

// ── GET /api/blockchain/status ──────────────────────────────────────────────
// Status umum blockchain Polygon Amoy dan E-Receipt ledger
router.get('/status', (req: Request, res: Response) => {
  try {
    const status = blockchainService.getStatus();
    res.json({
      success: true,
      data: status,
    });
  } catch (err: any) {
    res.status(500).json({
      success: false,
      error: err?.message || 'Gagal mengambil status blockchain.',
    });
  }
});

// ── GET /api/blockchain/receipts ────────────────────────────────────────────
// Admin-only: Daftar seluruh e-receipts yang tersimpan di database
router.get('/receipts', verifyAdmin, (req: Request, res: Response) => {
  try {
    const store = blockchainService.getReceiptStore();
    const list = store.getAll();

    const formatted = list.map((r) => ({
      id: r.id || `REC-${r.orderId}`,
      receiptId: r.receiptId || `REC-${r.orderId}`,
      orderId: r.orderId,
      orderNumber: r.orderNumber || r.orderId,
      customerName: r.customerName || 'Pelanggan Bun Atelier',
      createdAt: r.createdAt,
      subtotal: r.receiptData?.subtotal || 0,
      total: r.receiptData?.total || 0,
      items: r.receiptData?.items || [],
      itemsSummary: (r.receiptData?.items || []).map((i: any) => `${i.quantity}x ${i.name}`).join(', '),
      paymentMethod: r.receiptData?.paymentMethod || 'CASHIER',
      paymentStatus: r.receiptData?.paymentStatus || 'PENDING',
      receiptHash: r.receiptHash,
      previousReceiptHash: r.previousReceiptHash,
      txHash: r.txHash || '',
      blockNumber: r.blockNumber || 0,
      status: r.status,
      network: r.network || blockchainService.getNetworkName(),
      explorerUrl: r.explorerUrl,
    }));

    const onChainCount = list.filter(
      (r) => r.status === 'CONFIRMED' && r.txHash && r.txHash.startsWith('0x') && !r.txHash.includes('SIM')
    ).length;

    res.json({
      success: true,
      totalReceipts: list.length,
      totalOnChainBlocks: onChainCount,
      data: formatted,
    });
  } catch (err: any) {
    res.status(500).json({
      success: false,
      error: err?.message || 'Gagal mengambil riwayat receipt blockchain.',
    });
  }
});

// ── POST /api/blockchain/receipt/sync ───────────────────────────────────────
// Admin-only: Sinkronisasi pesanan pelanggan dari aplikasi ke e-receipt database & Polygon Amoy
router.post('/receipt/sync', verifyAdmin, async (req: Request, res: Response) => {
  try {
    const orders = req.body.orders;
    if (!Array.isArray(orders)) {
      return res.status(400).json({
        success: false,
        error: 'Parameter orders wajib berupa array pesanan.',
      });
    }

    const result = await blockchainService.syncOrders(orders);
    res.json({
      success: true,
      data: result,
    });
  } catch (err: any) {
    res.status(500).json({
      success: false,
      error: err?.message || 'Gagal melakukan sinkronisasi pesanan ke blockchain.',
    });
  }
});

// ── POST /api/blockchain/receipt/record ─────────────────────────────────────
// Otomatis mencatat transaksi pesanan baru
router.post('/receipt/record', async (req: Request, res: Response) => {
  try {
    const body = req.body;
    if (!body || (!body.orderId && !body.orderNumber)) {
      return res.status(400).json({
        success: false,
        error: 'Parameter orderId wajib disertakan.',
      });
    }

    const orderId = String(body.orderId || body.orderNumber);
    const orderNumber = String(body.orderNumber || body.orderId);
    const customerName = String(body.customerName || 'Pelanggan Bun Atelier');

    const canonical: CanonicalReceiptData = {
      orderId,
      orderType: body.orderType || 'PICKUP',
      branchId: body.branchId || 'out-1',
      currency: body.currency || body.branchCurrency || 'IDR',
      items: Array.isArray(body.items) ? body.items : [],
      subtotal: Number(body.subtotal || 0),
      discount: Number(body.discount || body.voucherDiscountAmount || 0),
      tax: Number(body.tax || 0),
      deliveryFee: Number(body.deliveryFee || 0),
      total: Number(body.total || 0),
      paymentMethod: body.paymentMethod || 'CASHIER',
      paymentStatus: body.paymentStatus || 'PENDING',
    };

    const recordResult = await blockchainService.recordReceipt(canonical);

    res.json({
      success: true,
      data: recordResult,
    });
  } catch (err: any) {
    res.status(500).json({
      success: false,
      error: err?.message || 'Gagal memproses e-receipt pesanan.',
    });
  }
});

// ── GET /api/blockchain/receipt/verify/:orderId ─────────────────────────────
// Admin-only: Verifikasi receipt terhadap data kanonikal dan on-chain Polygon Amoy
router.get('/receipt/verify/:orderId', verifyAdmin, async (req: Request, res: Response) => {
  try {
    const orderId = String(req.params.orderId);
    const result = await blockchainService.verifyReceipt(orderId);

    res.json({
      success: true,
      data: result,
    });
  } catch (err: any) {
    res.status(500).json({
      success: false,
      error: err?.message || 'Gagal memverifikasi receipt.',
    });
  }
});

// ── POST /api/blockchain/receipt/verify ────────────────────────────────────
// Admin-only: Verifikasi payload e-receipt terhadap data on-chain Polygon Amoy
router.post('/receipt/verify', verifyAdmin, async (req: Request, res: Response) => {
  try {
    const { orderId, currentData } = req.body;
    if (!orderId) {
      return res.status(400).json({
        success: false,
        error: 'orderId wajib disertakan.',
      });
    }

    const result = await blockchainService.verifyReceipt(String(orderId), currentData);
    res.json({
      success: true,
      data: result,
    });
  } catch (err: any) {
    res.status(500).json({
      success: false,
      error: err?.message || 'Gagal memverifikasi payload e-receipt.',
    });
  }
});

// ── GET /api/blockchain/validate ────────────────────────────────────────────
// Admin-only: Jalankan validasi integritas seluruh e-receipt yang tersimpan
router.get('/validate', verifyAdmin, async (req: Request, res: Response) => {
  try {
    const store = blockchainService.getReceiptStore();
    const list = store.getAll();
    const status = blockchainService.getStatus();

    if (list.length === 0) {
      return res.json({
        success: true,
        data: {
          isValid: true,
          totalReceipts: 0,
          totalOnChainBlocks: 0,
          status: 'EMPTY',
          message: 'Belum ada e-receipt transaksi yang tersimpan di sistem.',
          verifiedAt: new Date().toISOString(),
          issues: [],
        },
      });
    }

    const issues: any[] = [];
    for (const r of list) {
      const v = await blockchainService.verifyReceipt(r.orderId);
      if (v.status === 'TAMPERED') {
        issues.push({
          orderId: r.orderId,
          status: 'TAMPERED',
          reason: v.reason,
        });
      }
    }

    const isValid = issues.length === 0;

    res.json({
      success: true,
      data: {
        isValid,
        totalReceipts: list.length,
        totalOnChainBlocks: status.totalOnChainBlocks,
        isLiveConfigured: true,
        network: status.network || 'Bun Atelier Blockchain Ledger',
        contractAddress: status.contractAddress || 'BunAtelierLedger::SHA256Chain',
        message: isValid
          ? `Seluruh e-receipt (${list.length}) cocok secara kriptografis dalam rantai hash blockchain Bun Atelier.`
          : `Ditemukan ${issues.length} transaksi yang mengalami manipulasi data!`,
        verifiedAt: new Date().toISOString(),
        issues,
      },
    });
  } catch (err: any) {
    res.status(500).json({
      success: false,
      error: err?.message || 'Gagal menjalankan validasi blockchain.',
    });
  }
});

export default router;
