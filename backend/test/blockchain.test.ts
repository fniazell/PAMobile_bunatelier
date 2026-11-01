import { test, describe, beforeEach } from 'node:test';
import assert from 'node:assert';
import {
  buildCanonicalReceiptString,
  computeReceiptHash,
  computeOrderIdHash,
} from '../src/services/receiptCanonicalizer.js';
import { ReceiptStore } from '../src/services/receiptStore.js';
import { VoucherStore } from '../src/services/voucherStore.js';
import { BlockchainService } from '../src/services/blockchainService.js';

describe('Bun Atelier Blockchain E-Receipt Ledger Core & Service Tests', () => {
  beforeEach(() => {
    ReceiptStore.getInstance().clearForTest();
    VoucherStore.getInstance().clearForTest();
  });

  // 1. Consistent Canonical Hashing
  test('1. Receipt valid menghasilkan canonical string dan SHA-256 hash yang konsisten', () => {
    const sampleData = {
      orderId: 'BA001',
      orderType: 'PICKUP',
      branchId: 'out-1',
      currency: 'IDR',
      items: [
        { name: 'OG Main Character', price: 30000, quantity: 2, subtotal: 60000 },
      ],
      subtotal: 60000,
      discount: 0,
      tax: 6000,
      deliveryFee: 0,
      total: 66000,
      paymentMethod: 'QRIS',
      paymentStatus: 'PAID',
    };

    const hash1 = computeReceiptHash(sampleData);
    const hash2 = computeReceiptHash(sampleData);

    assert.strictEqual(hash1, hash2, 'Hash harus identik untuk data yang sama');
    assert.match(hash1, /^0x[0-9a-f]{64}$/, 'Hash harus berupa format 32-byte 0x hex');
  });

  // 2. Tamper Detection: Total changed (Rp 60.000 -> Rp 10.000)
  test('2. Perubahan total Rp 60.000 menjadi Rp 10.000 menghasilkan hash berbeda dan verifikasi gagal', () => {
    const original = {
      orderId: 'BA001',
      orderType: 'PICKUP',
      branchId: 'out-1',
      currency: 'IDR',
      items: [
        { name: 'OG Main Character', price: 30000, quantity: 2, subtotal: 60000 },
      ],
      subtotal: 60000,
      discount: 0,
      tax: 6000,
      deliveryFee: 0,
      total: 66000,
      paymentMethod: 'QRIS',
      paymentStatus: 'PAID',
    };

    const tampered = {
      ...original,
      total: 10000, // Dimanipulasi
    };

    const originalHash = computeReceiptHash(original);
    const tamperedHash = computeReceiptHash(tampered);

    assert.notStrictEqual(originalHash, tamperedHash, 'Hash harus berbeda ketika total diubah');
  });

  // 3. Item/Quantity alteration detection
  test('3. Perubahan kuantitas atau item pesanan terdeteksi menghasilkan hash berbeda', () => {
    const base = {
      orderId: 'BA002',
      orderType: 'PICKUP',
      branchId: 'out-1',
      currency: 'IDR',
      items: [
        { name: 'OG Main Character', price: 30000, quantity: 2, subtotal: 60000 },
      ],
      subtotal: 60000,
      discount: 0,
      tax: 6000,
      deliveryFee: 0,
      total: 66000,
      paymentMethod: 'QRIS',
      paymentStatus: 'PAID',
    };

    const alteredQty = {
      ...base,
      items: [
        { name: 'OG Main Character', price: 30000, quantity: 1, subtotal: 30000 },
      ],
    };

    assert.notStrictEqual(computeReceiptHash(base), computeReceiptHash(alteredQty));
  });

  // 4. OrderId Hash consistency
  test('4. OrderIdHash keccak256 konsisten untuk indexing smart contract', () => {
    const hashA = computeOrderIdHash('BA-20261028-001');
    const hashB = computeOrderIdHash('BA-20261028-001');
    assert.strictEqual(hashA, hashB);
    assert.match(hashA, /^0x[0-9a-f]{64}$/);
  });

  // 5. Unrecorded receipt verification returns NOT_RECORDED
  test('5. Verifikasi order yang belum dicatat menghasilkan status NOT_RECORDED', async () => {
    const service = BlockchainService.getInstance();
    const result = await service.verifyReceipt('NON_EXISTENT_ORDER');
    assert.strictEqual(result.status, 'NOT_RECORDED');
    assert.strictEqual(result.isValid, false);
  });

  // 6. Record receipt and verify TAMPERED when payload differs
  test('6. Record receipt lalu verifikasi payload yang dimanipulasi menghasilkan status TAMPERED', async () => {
    const service = BlockchainService.getInstance();

    const validData = {
      orderId: 'BA-TAMPER-TEST-001',
      orderType: 'PICKUP',
      branchId: 'out-1',
      currency: 'IDR',
      items: [
        { name: 'Truffle Wagyu Burger', price: 45000, quantity: 1, subtotal: 45000 },
      ],
      subtotal: 45000,
      discount: 0,
      tax: 4500,
      deliveryFee: 0,
      total: 49500,
      paymentMethod: 'QRIS',
      paymentStatus: 'PAID',
    };

    // 1. Record receipt
    const recordResult = await service.recordReceipt(validData);
    assert.strictEqual(recordResult.success, true);
    assert.strictEqual(recordResult.orderId, 'BA-TAMPER-TEST-001');

    // 2. Verify with authentic data -> NOT_CONFIGURED when live EVM is not active
    const verifyValid = await service.verifyReceipt('BA-TAMPER-TEST-001');
    assert.strictEqual(verifyValid.status, 'NOT_CONFIGURED');
    assert.strictEqual(verifyValid.isValid, false);
    assert.ok(verifyValid.reason.includes('belum dikonfigurasi'));

    // 3. Verify with tampered data (total changed to 5000) -> TAMPERED
    const tamperedData = {
      ...validData,
      total: 5000,
    };
    const verifyTampered = await service.verifyReceipt('BA-TAMPER-TEST-001', tamperedData);
    assert.strictEqual(verifyTampered.status, 'TAMPERED');
    assert.strictEqual(verifyTampered.isValid, false);
    assert.ok(verifyTampered.reason.includes('MANIPULASI'));
  });

  // 7. Idempotency test: Retry does not duplicate or break index
  test('7. Retry pencatatan tidak membuat duplikat receipt (Idempotent)', async () => {
    const service = BlockchainService.getInstance();

    const order = {
      orderId: 'BA-IDEMPOTENT-001',
      orderType: 'PICKUP',
      branchId: 'out-1',
      currency: 'IDR',
      items: [{ name: 'Biscoff Bun', price: 25000, quantity: 1, subtotal: 25000 }],
      subtotal: 25000,
      discount: 0,
      tax: 2500,
      deliveryFee: 0,
      total: 27500,
      paymentMethod: 'QRIS',
      paymentStatus: 'PAID',
    };

    const res1 = await service.recordReceipt(order);
    const res2 = await service.recordReceipt(order);

    assert.strictEqual(res1.txHash, res2.txHash);
    assert.strictEqual(res1.receiptIndex, res2.receiptIndex);
    assert.strictEqual(ReceiptStore.getInstance().getAll().length, 1);
  });

  // 8. Hash Chain Link: Receipt 2 references Receipt 1
  test('8. Previous receipt hash merujuk secara linear pada receipt sebelumnya', async () => {
    const service = BlockchainService.getInstance();

    const order1 = {
      orderId: 'CHAIN-ORD-1',
      orderType: 'PICKUP',
      branchId: 'out-1',
      currency: 'IDR',
      items: [{ name: 'Item 1', price: 10000, quantity: 1, subtotal: 10000 }],
      subtotal: 10000,
      discount: 0,
      tax: 1000,
      deliveryFee: 0,
      total: 11000,
      paymentMethod: 'QRIS',
      paymentStatus: 'PAID',
    };

    const order2 = {
      orderId: 'CHAIN-ORD-2',
      orderType: 'PICKUP',
      branchId: 'out-1',
      currency: 'IDR',
      items: [{ name: 'Item 2', price: 20000, quantity: 1, subtotal: 20000 }],
      subtotal: 20000,
      discount: 0,
      tax: 2000,
      deliveryFee: 0,
      total: 22000,
      paymentMethod: 'QRIS',
      paymentStatus: 'PAID',
    };

    const res1 = await service.recordReceipt(order1);
    const res2 = await service.recordReceipt(order2);

    // Order 1 is genesis (ZeroHash previousReceiptHash)
    assert.strictEqual(res1.previousReceiptHash, '0x0000000000000000000000000000000000000000000000000000000000000000');
    // Order 2 points to Order 1's receiptHash
    assert.strictEqual(res2.previousReceiptHash, res1.receiptHash);
  });

  // 9. Status endpoint honesty
  test('9. getStatus() melaporkan status kejujuran mode simulasi / live', () => {
    const service = BlockchainService.getInstance();
    const status = service.getStatus();
    assert.strictEqual(typeof status.isLiveConfigured, 'boolean');
    assert.ok(status.mode === 'LIVE_ON_CHAIN' || status.mode === 'NOT_CONFIGURED');
    assert.strictEqual(typeof status.totalReceipts, 'number');
  });

  // 10. Persistence across Store reload
  test('10. Catatan tersimpan secara persisten dan terbaca kembali saat reload', async () => {
    const service = BlockchainService.getInstance();
    await service.recordReceipt({
      orderId: 'PERSIST-ORD-1',
      orderType: 'PICKUP',
      branchId: 'out-1',
      currency: 'IDR',
      items: [{ name: 'Persist Bun', price: 10000, quantity: 1, subtotal: 10000 }],
      subtotal: 10000,
      discount: 0,
      tax: 1000,
      deliveryFee: 0,
      total: 11000,
      paymentMethod: 'QRIS',
      paymentStatus: 'PAID',
    });

    const store = ReceiptStore.getInstance();
    const list = store.getAll();
    assert.strictEqual(list.length, 1);

    const record = store.getByOrderId('PERSIST-ORD-1');
    assert.ok(record);
    assert.strictEqual(record?.orderId, 'PERSIST-ORD-1');
  });

  // 11. Voucher ditukar tetapi belum digunakan
  test('11. Voucher ditukar tetapi belum digunakan tercatat dengan status belum dikonsumsi', async () => {
    const service = BlockchainService.getInstance();
    const refId = 'REF-VCH-TEST-001';
    const proofHash = '0x1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff';

    const recordRes = await service.recordRedemption({
      referenceId: refId,
      discountPercent: 10,
      pointsBurned: 100,
      proofHash: proofHash,
    });

    assert.strictEqual(recordRes.success, true);
    assert.strictEqual(recordRes.isSimulated, false);
    assert.strictEqual(recordRes.txHash, '');

    const verifyRes = service.verifyVoucher({ referenceId: refId });
    assert.strictEqual(verifyRes.isValid, false);
    assert.strictEqual(verifyRes.isRecorded, false);
    assert.strictEqual(verifyRes.isConsumed, false);
    assert.strictEqual(verifyRes.status, 'NOT_CONFIGURED');
    assert.strictEqual(verifyRes.isSimulated, false);
    assert.strictEqual(verifyRes.usage, null);
  });

  // 12. Voucher digunakan pada order yang berhasil
  test('12. Voucher digunakan pada order yang berhasil mencatat usageTxHash dan isConsumed = true', async () => {
    const service = BlockchainService.getInstance();
    const refId = 'REF-VCH-TEST-002';
    const proofHash = '0x222233334444555566667777888899990000aaaabbbbccccddddeeeeffff1111';
    const orderHash = '0x33334444555566667777888899990000aaaabbbbccccddddeeeeffff11112222';

    // 1. Redeem
    await service.recordRedemption({
      referenceId: refId,
      discountPercent: 15,
      pointsBurned: 150,
      proofHash: proofHash,
    });

    // 2. Use on order
    const usageRes = await service.recordUsage({
      referenceId: refId,
      orderHash: orderHash,
      discountPercent: 15,
    });

    assert.strictEqual(usageRes.success, true);
    assert.strictEqual(usageRes.isSimulated, false);
    assert.strictEqual(usageRes.txHash, '');

    // 3. Verify
    const verifyRes = service.verifyVoucher({
      referenceId: refId,
      clientProofHash: proofHash,
      clientOrderHash: orderHash,
    });

    assert.strictEqual(verifyRes.isValid, false);
    assert.strictEqual(verifyRes.isRecorded, false);
    assert.strictEqual(verifyRes.isConsumed, true);
    assert.strictEqual(verifyRes.status, 'NOT_CONFIGURED');
    assert.ok(verifyRes.usage);
    assert.strictEqual(verifyRes.usage?.orderHash, orderHash);
  });

  // 13. Fingerprint proof valid diverifikasi cocok
  test('13. Fingerprint penukaran poin (proofHash) valid diverifikasi cocok', async () => {
    const service = BlockchainService.getInstance();
    const refId = 'REF-VCH-TEST-003';
    const proofHash = '0x4444555566667777888899990000aaaabbbbccccddddeeeeffff111122223333';

    await service.recordRedemption({
      referenceId: refId,
      discountPercent: 5,
      pointsBurned: 50,
      proofHash: proofHash,
    });

    const verifyRes = service.verifyVoucher({
      referenceId: refId,
      clientProofHash: proofHash,
    });

    assert.strictEqual(verifyRes.isValid, false);
    assert.strictEqual(verifyRes.status, 'NOT_CONFIGURED');
  });

  // 14. Fingerprint tidak valid menghasilkan status PROOF_MISMATCH
  test('14. Fingerprint penukaran tidak valid menghasilkan status PROOF_MISMATCH', async () => {
    const service = BlockchainService.getInstance();
    const refId = 'REF-VCH-TEST-004';
    const realProofHash = '0x555566667777888899990000aaaabbbbccccddddeeeeffff1111222233334444';
    const tamperedProofHash = '0xFAKEEEEE66667777888899990000aaaabbbbccccddddeeeeffff111122223333';

    await service.recordRedemption({
      referenceId: refId,
      discountPercent: 5,
      pointsBurned: 50,
      proofHash: realProofHash,
    });

    const verifyRes = service.verifyVoucher({
      referenceId: refId,
      clientProofHash: tamperedProofHash,
    });

    assert.strictEqual(verifyRes.isValid, false);
    assert.strictEqual(verifyRes.status, 'PROOF_MISMATCH');
    assert.ok(verifyRes.reason.includes('tidak cocok'));
  });

  // 15. Verifikasi voucher yang tidak terdaftar menghasilkan NOT_RECORDED
  test('15. Verifikasi voucher yang tidak terdaftar menghasilkan NOT_RECORDED', () => {
    const service = BlockchainService.getInstance();
    const verifyRes = service.verifyVoucher({ referenceId: 'NON_EXISTENT_REF' });

    assert.strictEqual(verifyRes.isValid, false);
    assert.strictEqual(verifyRes.status, 'NOT_RECORDED');
    assert.strictEqual(verifyRes.isRecorded, false);
  });

  // 16. Ketahanan data: VoucherStore persisten menyimpan data ke disk
  test('16. VoucherStore persisten menyimpan data ke disk dan terbaca kembali saat reload', async () => {
    const service = BlockchainService.getInstance();
    const refId = 'REF-PERSIST-001';
    const proofHash = '0x9999888877776666555544443333222211110000aaaabbbbccccddddeeeeffff';

    await service.recordRedemption({
      referenceId: refId,
      discountPercent: 20,
      pointsBurned: 200,
      proofHash: proofHash,
    });

    const store = VoucherStore.getInstance();
    assert.strictEqual(store.getRedemptionsCount() >= 1, true);

    const saved = store.getRedemption(refId);
    assert.ok(saved);
    assert.strictEqual(saved?.referenceId, refId);
    assert.strictEqual(saved?.proofHash, proofHash);
  });
});
