/**
 * Model dan struktur data untuk E-Receipt dan Blockchain Sederhana Bun Atelier.
 */

export interface EReceiptItem {
  name: string;
  quantity: number;
  price: number;
  subtotal: number;
}

export interface EReceiptData {
  receiptId: string;
  orderId: string;
  timestamp: string;
  items: EReceiptItem[];
  subtotal: number;
  total: number;
  paymentMethod: string;
  paymentStatus: string;
  customerNote?: string;
  branchId?: string;
}

export interface EReceipt {
  id: string;
  order_id: string;
  receipt_number: string;
  receipt_data: EReceiptData;
  receipt_hash: string; // SHA-256 hash dari data e-receipt yang telah dinormalisasi
  created_at: string;
}

export interface BlockchainBlock {
  id: string;
  block_index: number;
  transaction_id: string; // ID transaksi / Order ID
  timestamp: string; // Waktu pembuatan block (ISO 8601)
  receipt_hash: string; // Hash SHA-256 dari e-receipt terkait
  previous_hash: string; // Hash dari block sebelumnya ('0' untuk Genesis Block)
  current_hash: string; // Hash SHA-256 dari isi block ini
}

export interface BlockchainValidationIssue {
  blockIndex: number;
  transactionId: string;
  issueType: 'BLOCK_HASH_MISMATCH' | 'CHAIN_BROKEN' | 'INVALID_INDEX_SEQUENCE' | 'RECEIPT_NOT_FOUND' | 'RECEIPT_DATA_MANIPULATED';
  details: string;
  expectedHash?: string;
  actualHash?: string;
}

export interface BlockchainValidationReport {
  isValid: boolean;
  totalBlocks: number;
  message: string;
  verifiedAt: string;
  issues: BlockchainValidationIssue[];
  chainSummary: Array<{
    blockIndex: number;
    transactionId: string;
    currentHash: string;
    previousHash: string;
    status: 'VALID' | 'TAMPERED';
  }>;
}

