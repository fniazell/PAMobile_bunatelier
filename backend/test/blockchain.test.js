import { test, describe, before, beforeEach } from 'node:test';
import assert from 'node:assert';
import http from 'node:http';
import app from '../dist/app.js';
import {
  buildCanonicalReceiptString,
  computeReceiptHash,
  computeOrderIdHash,
} from '../dist/services/receiptCanonicalizer.js';
import { ReceiptStore } from '../dist/services/receiptStore.js';
import { BlockchainService } from '../dist/services/blockchainService.js';

let server;
let baseUrl;

describe('Bun Atelier Blockchain E-Receipt Ledger Tests', () => {
  before(async () => {
    // Start test server on random free port
    await new Promise((resolve) => {
      server = app.listen(0, () => {
        const address = server.address();
        const port = typeof address === 'object' && address ? address.port : 3002;
        baseUrl = `http://127.0.0.1:${port}`;
        resolve(null);
      });
    });
  });

  beforeEach(() => {
    ReceiptStore.getInstance().clearForTest();
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

  // 2. Tamper Detection: Total changed
  test('2. Perubahan total Rp 60.000 menjadi Rp 10.000 menghasilkan hash berbeda', () => {
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
      total: 10000, // Hacked total
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

  // 6. Record receipt via API and verify TAMPERED when payload differs
  test('6. Record receipt via API lalu verifikasi payload yang dimanipulasi menghasilkan TAMPERED', async () => {
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
    const recordRes = await fetch(`${baseUrl}/api/blockchain/receipt/record`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(validData),
    });
    assert.strictEqual(recordRes.status, 200);
    const recordJson = await recordRes.json();
    assert.strictEqual(recordJson.success, true);
    assert.strictEqual(recordJson.data.orderId, 'BA-TAMPER-TEST-001');

    // 2. Verify with authentic data -> Valid
    const verifyValidRes = await fetch(`${baseUrl}/api/blockchain/receipt/verify/BA-TAMPER-TEST-001`);
    assert.strictEqual(verifyValidRes.status, 200);
    const verifyValidJson = await verifyValidRes.json();
    assert.strictEqual(verifyValidJson.data.isValid, true);

    // 3. Verify with tampered data -> TAMPERED
    const tamperedData = {
      ...validData,
      total: 5000, // Illegally reduced total
    };
    const verifyTamperedRes = await fetch(`${baseUrl}/api/blockchain/receipt/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        orderId: 'BA-TAMPER-TEST-001',
        currentData: tamperedData,
      }),
    });
    const verifyTamperedJson = await verifyTamperedRes.json();
    assert.strictEqual(verifyTamperedJson.data.status, 'TAMPERED');
    assert.strictEqual(verifyTamperedJson.data.isValid, false);
    assert.ok(verifyTamperedJson.data.reason.includes('MANIPULASI'));
  });

  // 7. Idempotency test: Retry does not duplicate or break index
  test('7. Retry pencatatan tidak membuat duplikat receipt (Idempotent)', async () => {
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

    const res1 = await fetch(`${baseUrl}/api/blockchain/receipt/record`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(order),
    });
    const json1 = await res1.json();

    const res2 = await fetch(`${baseUrl}/api/blockchain/receipt/record`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(order),
    });
    const json2 = await res2.json();

    assert.strictEqual(json1.data.txHash, json2.data.txHash);
    assert.strictEqual(json1.data.receiptIndex, json2.data.receiptIndex);
  });

  // 8. Hash Chain Link: Receipt 2 references Receipt 1
  test('8. Previous receipt hash merujuk secara linear pada receipt sebelumnya', async () => {
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

    const res1 = await (await fetch(`${baseUrl}/api/blockchain/receipt/record`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(order1),
    })).json();

    const res2 = await (await fetch(`${baseUrl}/api/blockchain/receipt/record`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(order2),
    })).json();

    // Order 1 is genesis (ZeroHash previousReceiptHash)
    assert.strictEqual(res1.data.previousReceiptHash, '0x0000000000000000000000000000000000000000000000000000000000000000');
    // Order 2 points to Order 1's receiptHash
    assert.strictEqual(res2.data.previousReceiptHash, res1.data.receiptHash);
  });

  // 9. Status endpoint honesty
  test('9. GET /api/blockchain/status melaporkan status kejujuran mode simulasi / live', async () => {
    const res = await fetch(`${baseUrl}/api/blockchain/status`);
    assert.strictEqual(res.status, 200);
    const json = await res.json();
    assert.strictEqual(json.success, true);
    assert.ok(typeof json.data.isLiveConfigured === 'boolean');
    assert.ok(json.data.mode === 'LIVE_SEPOLIA' || json.data.mode === 'SIMULATION_FALLBACK');
  });
});

