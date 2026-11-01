import fs from 'fs';
import path from 'path';
import os from 'os';

export interface StoredRedemptionRecord {
  referenceId: string;
  discountPercent: number;
  pointsBurned: number;
  proofHash: string;
  txHash: string;
  blockNumber: number;
  timestamp: string;
  network: string;
  isSimulated: boolean;
  explorerUrl?: string;
}

export interface StoredUsageRecord {
  referenceId: string;
  orderHash: string;
  discountPercent: number;
  txHash: string;
  blockNumber: number;
  timestamp: string;
  network: string;
  isSimulated: boolean;
  explorerUrl?: string;
}

interface VoucherStoreFileStructure {
  redemptions: StoredRedemptionRecord[];
  usages: StoredUsageRecord[];
}

export class VoucherStore {
  private static instance: VoucherStore;
  private filePath: string;
  private redemptions: Map<string, StoredRedemptionRecord> = new Map();
  private usages: Map<string, StoredUsageRecord> = new Map();

  private constructor() {
    this.filePath = process.env.VOUCHER_STORAGE_PATH || path.join(os.tmpdir(), 'bun_atelier_vouchers.json');
    this.load();
  }

  public static getInstance(): VoucherStore {
    if (!VoucherStore.instance) {
      VoucherStore.instance = new VoucherStore();
    }
    return VoucherStore.instance;
  }

  private load(): void {
    try {
      if (fs.existsSync(this.filePath)) {
        const raw = fs.readFileSync(this.filePath, 'utf8');
        const data: VoucherStoreFileStructure = JSON.parse(raw);
        this.redemptions.clear();
        this.usages.clear();

        if (Array.isArray(data.redemptions)) {
          for (const item of data.redemptions) {
            if (item && item.referenceId) {
              this.redemptions.set(item.referenceId, item);
            }
          }
        }

        if (Array.isArray(data.usages)) {
          for (const item of data.usages) {
            if (item && item.referenceId) {
              this.usages.set(item.referenceId, item);
            }
          }
        }
      }
    } catch (err) {
      console.warn('VoucherStore: Failed to read persistent vouchers file, starting fresh:', err);
      this.redemptions.clear();
      this.usages.clear();
    }
  }

  private persist(): void {
    try {
      const data: VoucherStoreFileStructure = {
        redemptions: Array.from(this.redemptions.values()),
        usages: Array.from(this.usages.values()),
      };
      fs.writeFileSync(this.filePath, JSON.stringify(data, null, 2), 'utf8');
    } catch (err) {
      console.error('VoucherStore: Error writing to vouchers file:', err);
    }
  }

  public saveRedemption(record: StoredRedemptionRecord): void {
    this.redemptions.set(record.referenceId, record);
    this.persist();
  }

  public getRedemption(referenceId: string): StoredRedemptionRecord | undefined {
    return this.redemptions.get(referenceId.trim());
  }

  public saveUsage(record: StoredUsageRecord): void {
    this.usages.set(record.referenceId, record);
    this.persist();
  }

  public getUsage(referenceId: string): StoredUsageRecord | undefined {
    return this.usages.get(referenceId.trim());
  }

  public getAllRedemptions(): StoredRedemptionRecord[] {
    return Array.from(this.redemptions.values());
  }

  public getAllUsages(): StoredUsageRecord[] {
    return Array.from(this.usages.values());
  }

  public getRedemptionsCount(): number {
    return this.redemptions.size;
  }

  public getUsagesCount(): number {
    return this.usages.size;
  }

  public clearForTest(): void {
    this.redemptions.clear();
    this.usages.clear();
    try {
      if (fs.existsSync(this.filePath)) {
        fs.unlinkSync(this.filePath);
      }
    } catch (_) {}
  }
}

