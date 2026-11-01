import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import os from 'os';
import {
  EReceipt,
  EReceiptData,
  BlockchainBlock,
} from './block.model.js';

export class SimpleBlockchainService {
  private static instance: SimpleBlockchainService;

  private storageDir: string;
  private receiptsFilePath: string;
  private blocksFilePath: string;

  private receipts: Map<string, EReceipt> = new Map();
  private blocks: BlockchainBlock[] = [];

  // Mutex untuk serialisasi pembuatan block demi mencegah race condition pada concurrent payments
  private mutex: Promise<any> = Promise.resolve();

  private constructor() {
    this.storageDir =
      process.env.BLOCKCHAIN_STORAGE_DIR ||
      path.join(process.cwd(), 'data', 'blockchain');
    try {
      if (!fs.existsSync(this.storageDir)) {
        fs.mkdirSync(this.storageDir, { recursive: true });
      }
    } catch (_) {
      this.storageDir = path.join(os.tmpdir(), 'bun_atelier_blockchain');
      if (!fs.existsSync(this.storageDir)) {
        try {
          fs.mkdirSync(this.storageDir, { recursive: true });
        } catch (_) {}
      }
    }

    this.receiptsFilePath = path.join(this.storageDir, 'e_receipts.json');
    this.blocksFilePath = path.join(this.storageDir, 'blockchain_blocks.json');

    // Migrasi data jika sebelumnya tersimpan di folder sementara os.tmpdir()
    try {
      const oldTmpDir = path.join(os.tmpdir(), 'bun_atelier_blockchain');
      if (
        this.storageDir !== oldTmpDir &&
        fs.existsSync(path.join(oldTmpDir, 'e_receipts.json')) &&
        !fs.existsSync(this.receiptsFilePath)
      ) {
        fs.copyFileSync(path.join(oldTmpDir, 'e_receipts.json'), this.receiptsFilePath);
      }
      if (
        this.storageDir !== oldTmpDir &&
        fs.existsSync(path.join(oldTmpDir, 'blockchain_blocks.json')) &&
        !fs.existsSync(this.blocksFilePath)
      ) {
        fs.copyFileSync(path.join(oldTmpDir, 'blockchain_blocks.json'), this.blocksFilePath);
      }
    } catch (_) {}

    this.loadFromDisk();
  }

  public static getInstance(): SimpleBlockchainService {
    if (!SimpleBlockchainService.instance) {
      SimpleBlockchainService.instance = new SimpleBlockchainService();
    }
    return SimpleBlockchainService.instance;
  }

  /**
   * Muat data e_receipts dan blockchain_blocks dari disk persisten.
   */
  public loadFromDisk(): void {
    try {
      // 1. Muat E-Receipts
      this.receipts.clear();
      if (fs.existsSync(this.receiptsFilePath)) {
        const rawReceipts = fs.readFileSync(this.receiptsFilePath, 'utf8');
        const list: EReceipt[] = JSON.parse(rawReceipts);
        for (const r of list) {
          if (r && r.order_id) {
            this.receipts.set(r.order_id, r);
          }
        }
      }

      // 2. Muat Blockchain Blocks
      this.blocks = [];
      if (fs.existsSync(this.blocksFilePath)) {
        const rawBlocks = fs.readFileSync(this.blocksFilePath, 'utf8');
        const list: BlockchainBlock[] = JSON.parse(rawBlocks);
        // Pastikan terurut berdasarkan block_index
        this.blocks = list.sort((a, b) => a.block_index - b.block_index);
      }
    } catch (err) {
      console.error('[SimpleBlockchainService] Gagal memuat data dari disk:', err);
    }
  }

  /**
   * Simpan e-receipts ke file persisten.
   */
  private saveReceiptsToDisk(): void {
    try {
      const list = Array.from(this.receipts.values());
      fs.writeFileSync(this.receiptsFilePath, JSON.stringify(list, null, 2), 'utf8');
    } catch (err) {
      console.error('[SimpleBlockchainService] Gagal menyimpan e_receipts.json:', err);
    }
  }

  /**
   * Simpan blockchain_blocks ke file persisten.
   */
  private saveBlocksToDisk(): void {
    try {
      fs.writeFileSync(this.blocksFilePath, JSON.stringify(this.blocks, null, 2), 'utf8');
    } catch (err) {
      console.error('[SimpleBlockchainService] Gagal menyimpan blockchain_blocks.json:', err);
    }
  }

  /**
   * Serialisasi kanonikal dari data e-receipt untuk menjamin determinisme hash.
   */
  public buildCanonicalReceiptString(data: EReceiptData): string {
    const normalizedItems = (data.items || []).map((item) => ({
      name: (item.name || '').trim(),
      quantity: Math.max(1, Math.round(Number(item.quantity) || 1)),
      price: Math.round(Number(item.price) || 0),
      subtotal: Math.round(Number(item.subtotal) || 0),
    }));

    // Urutkan item berdasarkan nama untuk konsistensi deterministik
    normalizedItems.sort((a, b) => a.name.localeCompare(b.name));

    const canonicalObj = {
      receiptId: (data.receiptId || '').trim(),
      orderId: (data.orderId || '').trim(),
      timestamp: (data.timestamp || '').trim(),
      items: normalizedItems,
      subtotal: Math.round(Number(data.subtotal) || 0),
      total: Math.round(Number(data.total) || 0),
      paymentMethod: (data.paymentMethod || '').trim().toUpperCase(),
      paymentStatus: (data.paymentStatus || '').trim().toUpperCase(),
    };

    return JSON.stringify(canonicalObj);
  }

  /**
   * Hitung hash SHA-256 dari e-receipt secara kanonikal.
   */
  public calculateReceiptHash(data: EReceiptData): string {
    const canonicalString = this.buildCanonicalReceiptString(data);
    return crypto.createHash('sha256').update(canonicalString).digest('hex');
  }

  /**
   * Hitung hash SHA-256 untuk sebuah block berdasarkan isi block dan previousHash.
   */
  public calculateBlockHash(
    blockIndex: number,
    timestamp: string,
    transactionId: string,
    receiptHash: string,
    previousHash: string
  ): string {
    const blockPayload = `${blockIndex}|${timestamp.trim()}|${transactionId.trim()}|${receiptHash.trim()}|${previousHash.trim()}`;
    return crypto.createHash('sha256').update(blockPayload).digest('hex');
  }

  /**
   * Catat transaksi yang berhasil dibayar ke dalam blockchain secara otomatis.
   * Hanya dijalankan jika status pembayaran terkonfirmasi (PAID / CONFIRMED).
   */
  public async recordTransactionPayment(receiptData: EReceiptData): Promise<{
    success: boolean;
    receipt?: EReceipt;
    block?: BlockchainBlock;
    error?: string;
    isDuplicate?: boolean;
  }> {
    return new Promise((resolve) => {
      this.mutex = this.mutex.then(async () => {
        try {
          const result = this._recordInternal(receiptData);
          resolve(result);
        } catch (err: any) {
          resolve({
            success: false,
            error: `Terjadi kegagalan saat mencatat block: ${err?.message || err}`,
          });
        }
      });
    });
  }

  private _recordInternal(receiptData: EReceiptData): {
    success: boolean;
    receipt?: EReceipt;
    block?: BlockchainBlock;
    error?: string;
    isDuplicate?: boolean;
  } {
    const orderId = (receiptData.orderId || '').trim();
    if (!orderId) {
      return { success: false, error: 'Order ID wajib diisi.' };
    }

    // 1. Verifikasi Status Pembayaran (Aturan 7):
    // Pesanan yang belum dibayar, pending, atau gagal TIDAK boleh menghasilkan block.
    const status = (receiptData.paymentStatus || '').trim().toUpperCase();
    const isPaid = status === 'PAID' || status === 'CONFIRMED' || status === 'SETTLED' || status === 'SUCCESS';

    if (!isPaid) {
      return {
        success: false,
        error: `Pembayaran belum berhasil (Status: '${status}'). Block blockchain hanya dibuat untuk transaksi yang telah terkonfirmasi lunas.`,
      };
    }

    // 2. Idempotency Check: Hindari pencatatan block ganda untuk satu transaksi
    const existingBlock = this.blocks.find((b) => b.transaction_id === orderId);
    if (existingBlock) {
      const existingReceipt = this.receipts.get(orderId);
      return {
        success: true,
        isDuplicate: true,
        receipt: existingReceipt,
        block: existingBlock,
      };
    }

    const nowIso = receiptData.timestamp || new Date().toISOString();
    const receiptNumber = receiptData.receiptId || `REC-${orderId}`;

    // 3. Buat E-Receipt dan Hash SHA-256
    const receiptHash = this.calculateReceiptHash({
      ...receiptData,
      receiptId: receiptNumber,
      orderId,
      timestamp: nowIso,
    });

    const newReceipt: EReceipt = {
      id: crypto.randomUUID ? crypto.randomUUID() : `rcpt_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      order_id: orderId,
      receipt_number: receiptNumber,
      receipt_data: {
        ...receiptData,
        receiptId: receiptNumber,
        orderId,
        timestamp: nowIso,
      },
      receipt_hash: receiptHash,
      created_at: nowIso,
    };

    // 4. Buat Block Baru
    const latestBlock = this.getLatestBlock();
    const blockIndex = latestBlock ? latestBlock.block_index + 1 : 0;
    // Genesis Block menggunakan previous_hash '0'
    const previousHash = latestBlock ? latestBlock.current_hash : '0';

    const currentHash = this.calculateBlockHash(
      blockIndex,
      nowIso,
      orderId,
      receiptHash,
      previousHash
    );

    const newBlock: BlockchainBlock = {
      id: crypto.randomUUID ? crypto.randomUUID() : `blk_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      block_index: blockIndex,
      transaction_id: orderId,
      timestamp: nowIso,
      receipt_hash: receiptHash,
      previous_hash: previousHash,
      current_hash: currentHash,
    };

    // 5. Simpan Permanen ke Database/Disk
    this.receipts.set(orderId, newReceipt);
    this.blocks.push(newBlock);

    this.saveReceiptsToDisk();
    this.saveBlocksToDisk();

    console.log(`[SimpleBlockchain] Block #${blockIndex} berhasil dicatat: Tx=${orderId}, Hash=${currentHash.substring(0, 16)}...`);

    return {
      success: true,
      receipt: newReceipt,
      block: newBlock,
    };
  }

  // ── GETTER & QUERY METHODS ────────────────────────────────────────────────

  public getAllBlocks(): BlockchainBlock[] {
    return [...this.blocks];
  }

  public getLatestBlock(): BlockchainBlock | undefined {
    return this.blocks.length > 0 ? this.blocks[this.blocks.length - 1] : undefined;
  }

  public getBlockByIndex(index: number): BlockchainBlock | undefined {
    return this.blocks.find((b) => b.block_index === index);
  }

  public getBlockByTransactionId(transactionId: string): BlockchainBlock | undefined {
    return this.blocks.find((b) => b.transaction_id === transactionId.trim());
  }

  public getAllReceipts(): EReceipt[] {
    return Array.from(this.receipts.values());
  }

  public getReceiptByOrderId(orderId: string): EReceipt | undefined {
    return this.receipts.get(orderId.trim());
  }

  /**
   * Reset chain (hanya untuk keperluan pengujian / test suite).
   */
  public _resetForTesting(): void {
    this.receipts.clear();
    this.blocks = [];
    this.saveReceiptsToDisk();
    this.saveBlocksToDisk();
  }

  /**
   * Modifikasi block untuk pengujian deteksi tampering.
   */
  public _tamperBlockForTesting(blockIndex: number, fakeTransactionId: string): boolean {
    const block = this.blocks.find((b) => b.block_index === blockIndex);
    if (!block) return false;
    block.transaction_id = fakeTransactionId;
    this.saveBlocksToDisk();
    return true;
  }

  /**
   * Modifikasi e-receipt untuk pengujian deteksi tampering.
   */
  public _tamperReceiptForTesting(orderId: string, fakeTotal: number): boolean {
    const receipt = this.receipts.get(orderId);
    if (!receipt) return false;
    receipt.receipt_data.total = fakeTotal;
    this.saveReceiptsToDisk();
    return true;
  }
}
