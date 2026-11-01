import { SimpleBlockchainService } from './blockchain.service.js';
import {
  BlockchainBlock,
  BlockchainValidationIssue,
  BlockchainValidationReport,
} from './block.model.js';

export class BlockchainValidator {
  private blockchainService: SimpleBlockchainService;

  constructor(blockchainService?: SimpleBlockchainService) {
    this.blockchainService = blockchainService || SimpleBlockchainService.getInstance();
  }

  /**
   * Memeriksa integritas seluruh rangkaian block pada blockchain Bun Atelier.
   *
   * 1. Kesesuaian hash setiap block (hitung ulang hash dari isi block).
   * 2. Kesesuaian previousHash (merujuk ke currentHash block sebelumnya).
   * 3. Urutan index block (harus berurutan linier: 0, 1, 2, ...).
   * 4. Kesesuaian receiptHash dengan data e-receipt yang tersimpan.
   */
  public validateBlockchain(): BlockchainValidationReport {
    const blocks: BlockchainBlock[] = this.blockchainService.getAllBlocks();
    const issues: BlockchainValidationIssue[] = [];
    const chainSummary: BlockchainValidationReport['chainSummary'] = [];

    const nowIso = new Date().toISOString();

    if (blocks.length === 0) {
      return {
        isValid: true,
        totalBlocks: 0,
        message: 'Blockchain kosong. Belum ada transaksi yang dicatat ke dalam ledger.',
        verifiedAt: nowIso,
        issues: [],
        chainSummary: [],
      };
    }

    for (let i = 0; i < blocks.length; i++) {
      const currentBlock = blocks[i];
      let blockHasError = false;

      // 1. Periksa Urutan Index Block
      if (currentBlock.block_index !== i) {
        issues.push({
          blockIndex: currentBlock.block_index,
          transactionId: currentBlock.transaction_id,
          issueType: 'INVALID_INDEX_SEQUENCE',
          details: `Urutan index block tidak beraturan. Ditemukan index ${currentBlock.block_index}, seharusnya index ${i}.`,
        });
        blockHasError = true;
      }

      // 2. Periksa Previous Hash
      if (i === 0) {
        // Genesis block harus memiliki previous_hash '0'
        if (currentBlock.previous_hash !== '0') {
          issues.push({
            blockIndex: currentBlock.block_index,
            transactionId: currentBlock.transaction_id,
            issueType: 'CHAIN_BROKEN',
            details: `Genesis block (Index 0) harus memiliki previous_hash '0', ditemukan: '${currentBlock.previous_hash}'.`,
            expectedHash: '0',
            actualHash: currentBlock.previous_hash,
          });
          blockHasError = true;
        }
      } else {
        const previousBlock = blocks[i - 1];
        if (currentBlock.previous_hash !== previousBlock.current_hash) {
          issues.push({
            blockIndex: currentBlock.block_index,
            transactionId: currentBlock.transaction_id,
            issueType: 'CHAIN_BROKEN',
            details: `Rantai terputus pada Block #${currentBlock.block_index}! previous_hash tidak cocok dengan current_hash Block #${previousBlock.block_index}.`,
            expectedHash: previousBlock.current_hash,
            actualHash: currentBlock.previous_hash,
          });
          blockHasError = true;
        }
      }

      // 3. Periksa Integritas Hash Block (Recalculate Current Hash)
      const expectedBlockHash = this.blockchainService.calculateBlockHash(
        currentBlock.block_index,
        currentBlock.timestamp,
        currentBlock.transaction_id,
        currentBlock.receipt_hash,
        currentBlock.previous_hash
      );

      if (currentBlock.current_hash !== expectedBlockHash) {
        issues.push({
          blockIndex: currentBlock.block_index,
          transactionId: currentBlock.transaction_id,
          issueType: 'BLOCK_HASH_MISMATCH',
          details: `ISI BLOCK TELAH DIMANIPULASI! current_hash Block #${currentBlock.block_index} tidak cocok dengan hasil perhitungan ulang.`,
          expectedHash: expectedBlockHash,
          actualHash: currentBlock.current_hash,
        });
        blockHasError = true;
      }

      // 4. Periksa Kesesuaian dengan E-Receipt di Database
      const storedReceipt = this.blockchainService.getReceiptByOrderId(currentBlock.transaction_id);
      if (!storedReceipt) {
        issues.push({
          blockIndex: currentBlock.block_index,
          transactionId: currentBlock.transaction_id,
          issueType: 'RECEIPT_NOT_FOUND',
          details: `E-Receipt untuk transaksi ${currentBlock.transaction_id} tidak ditemukan dalam tabel e_receipts.`,
        });
        blockHasError = true;
      } else {
        // Bandingkan receipt_hash yang dicatat di block dengan yang ada di tabel e_receipts
        if (storedReceipt.receipt_hash !== currentBlock.receipt_hash) {
          issues.push({
            blockIndex: currentBlock.block_index,
            transactionId: currentBlock.transaction_id,
            issueType: 'RECEIPT_DATA_MANIPULATED',
            details: `Ketidakcocokan receipt_hash pada transaksi ${currentBlock.transaction_id}. Hash di block berbeda dengan di tabel e_receipts.`,
            expectedHash: currentBlock.receipt_hash,
            actualHash: storedReceipt.receipt_hash,
          });
          blockHasError = true;
        }

        // Hitung ulang hash e-receipt dari data aslinya (receipt_data)
        const recomputedReceiptHash = this.blockchainService.calculateReceiptHash(storedReceipt.receipt_data);
        if (recomputedReceiptHash !== storedReceipt.receipt_hash) {
          issues.push({
            blockIndex: currentBlock.block_index,
            transactionId: currentBlock.transaction_id,
            issueType: 'RECEIPT_DATA_MANIPULATED',
            details: `DATA E-RECEIPT ASLI TELAH DIMANIPULASI! Perhitungan ulang hash dari payload transaksi ${currentBlock.transaction_id} tidak cocok.`,
            expectedHash: storedReceipt.receipt_hash,
            actualHash: recomputedReceiptHash,
          });
          blockHasError = true;
        }
      }

      chainSummary.push({
        blockIndex: currentBlock.block_index,
        transactionId: currentBlock.transaction_id,
        currentHash: currentBlock.current_hash,
        previousHash: currentBlock.previous_hash,
        status: blockHasError ? 'TAMPERED' : 'VALID',
      });
    }

    const isValid = issues.length === 0;
    const message = isValid
      ? `Seluruh rangkaian blockchain (${blocks.length} block) 100% VALID dan terverifikasi secara matematis.`
      : `Ditemukan ${issues.length} masalah integritas pada rantai blockchain! Terdeteksi indikasi manipulasi data atau rantai terputus.`;

    return {
      isValid,
      totalBlocks: blocks.length,
      message,
      verifiedAt: nowIso,
      issues,
      chainSummary,
    };
  }

  /**
   * Verifikasi spesifik untuk satu transaksi e-receipt berdasarkan Order ID.
   */
  public verifySingleTransaction(orderId: string): {
    isValid: boolean;
    status: 'VERIFIED' | 'TAMPERED' | 'NOT_RECORDED';
    orderId: string;
    block?: BlockchainBlock;
    reason: string;
    verifiedAt: string;
  } {
    const nowIso = new Date().toISOString();
    const cleanId = (orderId || '').trim();

    const block = this.blockchainService.getBlockByTransactionId(cleanId);
    const receipt = this.blockchainService.getReceiptByOrderId(cleanId);

    if (!block || !receipt) {
      return {
        isValid: false,
        status: 'NOT_RECORDED',
        orderId: cleanId,
        reason: `Transaksi dengan Order ID '${cleanId}' belum pernah dicatat dalam blockchain.`,
        verifiedAt: nowIso,
      };
    }

    // 1. Verifikasi block hash
    const expectedBlockHash = this.blockchainService.calculateBlockHash(
      block.block_index,
      block.timestamp,
      block.transaction_id,
      block.receipt_hash,
      block.previous_hash
    );

    if (block.current_hash !== expectedBlockHash) {
      return {
        isValid: false,
        status: 'TAMPERED',
        orderId: cleanId,
        block,
        reason: 'DATA BLOCK DIMANIPULASI! Hash block saat ini tidak cocok dengan data transaksi.',
        verifiedAt: nowIso,
      };
    }

    // 2. Verifikasi data receipt
    const recomputedReceiptHash = this.blockchainService.calculateReceiptHash(receipt.receipt_data);
    if (recomputedReceiptHash !== receipt.receipt_hash || receipt.receipt_hash !== block.receipt_hash) {
      return {
        isValid: false,
        status: 'TAMPERED',
        orderId: cleanId,
        block,
        reason: 'DATA E-RECEIPT DIMANIPULASI! Nilai subtotal, total, atau item pesanan telah diubah.',
        verifiedAt: nowIso,
      };
    }

    return {
      isValid: true,
      status: 'VERIFIED',
      orderId: cleanId,
      block,
      reason: 'TERVERIFIKASI ASLI! Data e-receipt 100% cocok dengan catatan kriptografis di blockchain.',
      verifiedAt: nowIso,
    };
  }
}

