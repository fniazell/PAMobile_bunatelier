import fs from 'fs';
import path from 'path';
import os from 'os';
import { CanonicalReceiptData } from './receiptCanonicalizer.js';

export interface StoredReceiptRecord {
  id?: string;
  receiptId?: string;
  orderId: string;
  orderNumber?: string;
  customerName?: string;
  orderIdHash: string;
  receiptHash: string;
  previousReceiptHash: string;
  receiptIndex: number;
  network: string;
  chainId: number;
  contractAddress: string;
  txHash: string;
  blockNumber: number;
  status: 'CONFIRMED' | 'NOT_RECORDED' | 'PENDING' | 'PENDING_PAYMENT' | 'FAILED';
  createdAt: string;
  canonicalString: string;
  receiptData: CanonicalReceiptData;
  isSimulated: boolean;
  explorerUrl?: string;
}

export class ReceiptStore {
  private static instance: ReceiptStore;
  private filePath: string;
  private records: Map<string, StoredReceiptRecord> = new Map();

  private constructor() {
    this.filePath =
      process.env.RECEIPT_STORAGE_PATH ||
      path.join(process.cwd(), 'data', 'blockchain', 'bun_atelier_receipts.json');

    const dir = path.dirname(this.filePath);
    try {
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
    } catch (_) {
      this.filePath = path.join(os.tmpdir(), 'bun_atelier_receipts.json');
    }

    // Migrasi fallback jika file lama ada di tmpdir
    try {
      const oldTmpPath = path.join(os.tmpdir(), 'bun_atelier_receipts.json');
      if (this.filePath !== oldTmpPath && fs.existsSync(oldTmpPath) && !fs.existsSync(this.filePath)) {
        fs.copyFileSync(oldTmpPath, this.filePath);
      }
    } catch (_) {}

    this.load();
  }

  public static getInstance(): ReceiptStore {
    if (!ReceiptStore.instance) {
      ReceiptStore.instance = new ReceiptStore();
    }
    return ReceiptStore.instance;
  }

  private load(): void {
    try {
      if (fs.existsSync(this.filePath)) {
        const raw = fs.readFileSync(this.filePath, 'utf8');
        const list: StoredReceiptRecord[] = JSON.parse(raw);
        this.records.clear();
        for (const item of list) {
          if (item && item.orderId) {
            this.records.set(item.orderId, item);
          }
        }
      }
    } catch (err) {
      console.warn('ReceiptStore: Failed to read persistent receipts file, starting fresh:', err);
      this.records.clear();
    }
  }

  private persist(): void {
    try {
      const list = Array.from(this.records.values());
      fs.writeFileSync(this.filePath, JSON.stringify(list, null, 2), 'utf8');
    } catch (err) {
      console.error('ReceiptStore: Error writing to receipts file:', err);
    }
  }

  public getAll(): StoredReceiptRecord[] {
    return Array.from(this.records.values()).sort((a, b) => a.receiptIndex - b.receiptIndex);
  }

  public getByOrderId(orderId: string): StoredReceiptRecord | undefined {
    return this.records.get(orderId.trim());
  }

  public getByOrderIdHash(orderIdHash: string): StoredReceiptRecord | undefined {
    const target = orderIdHash.toLowerCase();
    for (const r of this.records.values()) {
      if (r.orderIdHash.toLowerCase() === target) {
        return r;
      }
    }
    return undefined;
  }

  public getLatest(): StoredReceiptRecord | undefined {
    const all = this.getAll();
    return all.length > 0 ? all[all.length - 1] : undefined;
  }

  public save(record: StoredReceiptRecord): void {
    this.records.set(record.orderId, record);
    this.persist();
  }

  public update(orderId: string, updates: Partial<StoredReceiptRecord>): StoredReceiptRecord | undefined {
    const existing = this.records.get(orderId);
    if (!existing) return undefined;
    const merged = { ...existing, ...updates };
    this.records.set(orderId, merged);
    this.persist();
    return merged;
  }

  public clearForTest(): void {
    this.records.clear();
    this.persist();
  }
}

