import test from 'node:test';
import assert from 'node:assert';
import { SimpleBlockchainService } from '../src/blockchain/blockchain.service.js';
import { BlockchainValidator } from '../src/blockchain/blockchain.validator.js';

test('Bun Atelier Simple Blockchain Test Suite', async (t) => {
  const service = SimpleBlockchainService.getInstance();
  const validator = new BlockchainValidator(service);

  // Reset data sebelum pengujian
  service._resetForTesting();

  await t.test('1. Customer pemesanan & pembayaran berhasil (PAID): E-Receipt dibuat dan Block Genesis tercatat otomatis', async () => {
    const orderData = {
      receiptId: 'REC-BA-001',
      orderId: 'BA-20261030-001',
      timestamp: '2026-10-30T10:00:00.000Z',
      items: [
        { name: 'OG Main Character Burger', quantity: 2, price: 65000, subtotal: 130000 },
        { name: 'Truffle Fries', quantity: 1, price: 35000, subtotal: 35000 },
      ],
      subtotal: 165000,
      total: 181500,
      paymentMethod: 'QRIS',
      paymentStatus: 'PAID',
    };

    const result = await service.recordTransactionPayment(orderData);

    assert.strictEqual(result.success, true);
    assert.ok(result.receipt);
    assert.ok(result.block);

    // Verifikasi atribut E-Receipt
    assert.strictEqual(result.receipt?.order_id, 'BA-20261030-001');
    assert.strictEqual(result.receipt?.receipt_number, 'REC-BA-001');
    assert.strictEqual(typeof result.receipt?.receipt_hash, 'string');
    assert.strictEqual(result.receipt?.receipt_hash.length, 64); // SHA-256 hex length

    // Verifikasi atribut Block #0 (Genesis Block)
    assert.strictEqual(result.block?.block_index, 0);
    assert.strictEqual(result.block?.transaction_id, 'BA-20261030-001');
    assert.strictEqual(result.block?.previous_hash, '0'); // Genesis previousHash is '0'
    assert.strictEqual(result.block?.receipt_hash, result.receipt?.receipt_hash);
    assert.strictEqual(typeof result.block?.current_hash, 'string');
    assert.strictEqual(result.block?.current_hash.length, 64);
  });

  await t.test('2. Pembayaran Gagal (FAILED): Tidak ada block yang dibuat', async () => {
    const initialBlockCount = service.getAllBlocks().length;

    const failedOrder = {
      receiptId: 'REC-BA-FAIL-001',
      orderId: 'BA-FAIL-001',
      timestamp: '2026-10-30T10:05:00.000Z',
      items: [{ name: 'Classic Burger', quantity: 1, price: 50000, subtotal: 50000 }],
      subtotal: 50000,
      total: 55000,
      paymentMethod: 'CREDIT_CARD',
      paymentStatus: 'FAILED',
    };

    const result = await service.recordTransactionPayment(failedOrder);

    assert.strictEqual(result.success, false);
    assert.ok(result.error?.includes('Pembayaran belum berhasil'));
    assert.strictEqual(service.getAllBlocks().length, initialBlockCount);
  });

  await t.test('3. Pembayaran Pending (PENDING): Tidak ada block yang dibuat', async () => {
    const initialBlockCount = service.getAllBlocks().length;

    const pendingOrder = {
      receiptId: 'REC-BA-PEND-001',
      orderId: 'BA-PEND-001',
      timestamp: '2026-10-30T10:10:00.000Z',
      items: [{ name: 'Cheeseburger', quantity: 1, price: 45000, subtotal: 45000 }],
      subtotal: 45000,
      total: 49500,
      paymentMethod: 'CASHIER',
      paymentStatus: 'PENDING',
    };

    const result = await service.recordTransactionPayment(pendingOrder);

    assert.strictEqual(result.success, false);
    assert.ok(result.error?.includes('Pembayaran belum berhasil'));
    assert.strictEqual(service.getAllBlocks().length, initialBlockCount);
  });

  await t.test('4. Transaksi kedua berhasil: Block baru terhubung dengan previousHash block sebelumnya', async () => {
    const genesisBlock = service.getLatestBlock();
    assert.ok(genesisBlock);

    const secondOrder = {
      receiptId: 'REC-BA-002',
      orderId: 'BA-20261030-002',
      timestamp: '2026-10-30T10:15:00.000Z',
      items: [{ name: 'Double Trouble Burger', quantity: 1, price: 85000, subtotal: 85000 }],
      subtotal: 85000,
      total: 93500,
      paymentMethod: 'GO_PAY',
      paymentStatus: 'CONFIRMED',
    };

    const result = await service.recordTransactionPayment(secondOrder);

    assert.strictEqual(result.success, true);
    assert.ok(result.block);
    assert.strictEqual(result.block?.block_index, 1);
    // previous_hash block kedua harus sama dengan current_hash block pertama
    assert.strictEqual(result.block?.previous_hash, genesisBlock.current_hash);
    assert.strictEqual(service.getAllBlocks().length, 2);
  });

  await t.test('5. Validasi integritas blockchain: Seluruh rantai 100% valid', () => {
    const report = validator.validateBlockchain();

    assert.strictEqual(report.isValid, true);
    assert.strictEqual(report.totalBlocks, 2);
    assert.strictEqual(report.issues.length, 0);
    assert.ok(report.message.includes('100% VALID'));
  });

  await t.test('6. Transaksi yang sama diproses ulang: Idempotent & tidak menghasilkan block duplikat', async () => {
    const blockCountBefore = service.getAllBlocks().length;

    const repeatOrder = {
      receiptId: 'REC-BA-002',
      orderId: 'BA-20261030-002', // Order ID yang sama dengan test 4
      timestamp: '2026-10-30T10:15:00.000Z',
      items: [{ name: 'Double Trouble Burger', quantity: 1, price: 85000, subtotal: 85000 }],
      subtotal: 85000,
      total: 93500,
      paymentMethod: 'GO_PAY',
      paymentStatus: 'CONFIRMED',
    };

    const result = await service.recordTransactionPayment(repeatOrder);

    assert.strictEqual(result.success, true);
    assert.strictEqual(result.isDuplicate, true);
    assert.strictEqual(service.getAllBlocks().length, blockCountBefore);
  });

  await t.test('7. Backend direstart: Data e-receipt dan blockchain tetap tersimpan persisten di disk', () => {
    // Simulasikan reload dari disk
    service.loadFromDisk();

    const blocks = service.getAllBlocks();
    assert.strictEqual(blocks.length, 2);

    const report = validator.validateBlockchain();
    assert.strictEqual(report.isValid, true);
  });

  await t.test('8. Data e-receipt diubah secara ilegal: Validasi mendeteksi RECEIPT_DATA_MANIPULATED', () => {
    // Manipulasi total pesanan order 1 dari 181.500 menjadi 10.000
    service._tamperReceiptForTesting('BA-20261030-001', 10000);

    const report = validator.validateBlockchain();

    assert.strictEqual(report.isValid, false);
    assert.ok(report.issues.length > 0);
    const hasTamperIssue = report.issues.some((i) => i.issueType === 'RECEIPT_DATA_MANIPULATED');
    assert.strictEqual(hasTamperIssue, true);
  });

  await t.test('9. Data block diubah secara ilegal: Validasi mendeteksi BLOCK_HASH_MISMATCH', () => {
    // Reset dan buat 2 block fresh
    service._resetForTesting();

    return Promise.all([
      service.recordTransactionPayment({
        receiptId: 'REC-1',
        orderId: 'ORD-1',
        timestamp: '2026-10-30T11:00:00.000Z',
        items: [{ name: 'Bun A', quantity: 1, price: 20000, subtotal: 20000 }],
        subtotal: 20000,
        total: 22000,
        paymentMethod: 'CASH',
        paymentStatus: 'PAID',
      }),
    ]).then(async () => {
      // Ubah transaction_id block #0
      service._tamperBlockForTesting(0, 'ORD-FAKE-HACKED');

      const report = validator.validateBlockchain();
      assert.strictEqual(report.isValid, false);
      const hasBlockTamper = report.issues.some((i) => i.issueType === 'BLOCK_HASH_MISMATCH');
      assert.strictEqual(hasBlockTamper, true);
    });
  });

  await t.test('10. Concurrency: Dua pembayaran simultaneous diproses antrean tanpa tabrakan index', async () => {
    service._resetForTesting();

    const p1 = service.recordTransactionPayment({
      receiptId: 'REC-PAR-1',
      orderId: 'ORD-PARALLEL-1',
      timestamp: '2026-10-30T12:00:00.000Z',
      items: [{ name: 'Item 1', quantity: 1, price: 30000, subtotal: 30000 }],
      subtotal: 30000,
      total: 33000,
      paymentMethod: 'QRIS',
      paymentStatus: 'PAID',
    });

    const p2 = service.recordTransactionPayment({
      receiptId: 'REC-PAR-2',
      orderId: 'ORD-PARALLEL-2',
      timestamp: '2026-10-30T12:00:01.000Z',
      items: [{ name: 'Item 2', quantity: 1, price: 40000, subtotal: 40000 }],
      subtotal: 40000,
      total: 44000,
      paymentMethod: 'QRIS',
      paymentStatus: 'PAID',
    });

    const [r1, r2] = await Promise.all([p1, p2]);

    assert.strictEqual(r1.success, true);
    assert.strictEqual(r2.success, true);
    assert.notStrictEqual(r1.block?.block_index, r2.block?.block_index);

    const report = validator.validateBlockchain();
    assert.strictEqual(report.isValid, true);
    assert.strictEqual(report.totalBlocks, 2);
  });
});

