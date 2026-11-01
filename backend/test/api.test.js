import { test, describe, before, after } from 'node:test';
import assert from 'node:assert';
import http from 'node:http';
import app from '../dist/app.js';

let server;
let baseUrl;

describe('Bun Atelier Backend Chatbot & Health API Tests', () => {
  before(async () => {
    // Start server on a random free port for testing
    await new Promise((resolve) => {
      server = app.listen(0, () => {
        const address = server.address();
        const port = typeof address === 'object' && address ? address.port : 3001;
        baseUrl = `http://127.0.0.1:${port}`;
        resolve(null);
      });
    });
  });

  after(async () => {
    if (server) {
      await new Promise((resolve) => server.close(resolve));
    }
  });

  test('GET /api/health returns 200 and ok status', async () => {
    const res = await fetch(`${baseUrl}/api/health`);
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.strictEqual(body.status, 'ok');
    assert.strictEqual(body.service, 'Bun Atelier Backend API');
    assert.ok(typeof body.geminiConfigured === 'boolean');
  });

  test('POST /api/support/chat returns 400 when message is missing', async () => {
    const res = await fetch(`${baseUrl}/api/support/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    });
    assert.strictEqual(res.status, 400);
    const body = await res.json();
    assert.strictEqual(body.success, false);
    assert.ok(body.error.includes('message'));
  });

  test('POST /api/support/chat returns 400 when message is empty or whitespace', async () => {
    const res = await fetch(`${baseUrl}/api/support/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: '   ' }),
    });
    assert.strictEqual(res.status, 400);
    const body = await res.json();
    assert.strictEqual(body.success, false);
    assert.ok(body.error.includes('kosong'));
  });

  test('POST /api/support/chat returns 400 when message exceeds max length', async () => {
    const longMsg = 'A'.repeat(1005);
    const res = await fetch(`${baseUrl}/api/support/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: longMsg }),
    });
    assert.strictEqual(res.status, 400);
    const body = await res.json();
    assert.strictEqual(body.success, false);
    assert.ok(body.error.includes('terlalu panjang'));
  });

  test('POST /api/support/chat returns 200 and reply for valid message', async () => {
    const res = await fetch(`${baseUrl}/api/support/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        message: 'Halo, outlet Senopati buka jam berapa?',
        history: [{ role: 'user', text: 'Halo' }],
      }),
    });
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.strictEqual(body.success, true);
    assert.ok(typeof body.reply === 'string' && body.reply.length > 0);
  });

  test('POST /api/ai/chat (alias) works identically', async () => {
    const res = await fetch(`${baseUrl}/api/ai/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        message: 'Apakah ada menu burger pedas?',
      }),
    });
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.strictEqual(body.success, true);
    assert.ok(typeof body.reply === 'string' && body.reply.length > 0);
  });
});
