import crypto from 'crypto';
import { ethers } from 'ethers';

export interface CanonicalReceiptItem {
  name: string;
  quantity: number;
  price: number;
  subtotal: number;
}

export interface CanonicalReceiptData {
  orderId: string;
  orderType: string;
  branchId: string;
  currency: string;
  items: CanonicalReceiptItem[];
  subtotal: number;
  discount: number;
  tax: number;
  deliveryFee: number;
  total: number;
  paymentMethod: string;
  paymentStatus: string;
}

/**
 * Normalizes e-receipt data into a strictly deterministic canonical string.
 * Any modification to items, quantity, prices, taxes, or status will produce a different string.
 */
export function buildCanonicalReceiptString(data: CanonicalReceiptData): string {
  // Sort items deterministically by name
  const sortedItems = [...(data.items || [])]
    .sort((a, b) => a.name.localeCompare(b.name))
    .map((item) => {
      const cleanName = item.name.trim();
      const qty = Math.max(0, Math.floor(Number(item.quantity) || 0));
      const price = Math.max(0, Math.floor(Number(item.price) || 0));
      const sub = Math.max(0, Math.floor(Number(item.subtotal) || qty * price));
      return `${cleanName}:${qty}:${price}:${sub}`;
    })
    .join(';');

  const orderId = (data.orderId || '').trim();
  const orderType = (data.orderType || 'PICKUP').trim().toUpperCase();
  const branchId = (data.branchId || 'out-1').trim();
  const currency = (data.currency || 'IDR').trim().toUpperCase();
  const subtotal = Math.max(0, Math.floor(Number(data.subtotal) || 0));
  const discount = Math.max(0, Math.floor(Number(data.discount) || 0));
  const tax = Math.max(0, Math.floor(Number(data.tax) || 0));
  const deliveryFee = Math.max(0, Math.floor(Number(data.deliveryFee) || 0));
  const total = Math.max(0, Math.floor(Number(data.total) || 0));
  const paymentMethod = (data.paymentMethod || 'QRIS').trim().toUpperCase();
  const paymentStatus = (data.paymentStatus || 'PAID').trim().toUpperCase();

  return [
    'BUN_RECEIPT_V1',
    orderId,
    orderType,
    branchId,
    currency,
    sortedItems,
    subtotal.toString(),
    discount.toString(),
    tax.toString(),
    deliveryFee.toString(),
    total.toString(),
    paymentMethod,
    paymentStatus,
  ].join('|');
}

/**
 * Computes standard SHA-256 hash of the canonical receipt string.
 * Formatted as 0x + 64 hex characters (32 bytes).
 */
export function computeReceiptHash(data: CanonicalReceiptData): string {
  const canonical = buildCanonicalReceiptString(data);
  const hashHex = crypto.createHash('sha256').update(canonical, 'utf8').digest('hex');
  return `0x${hashHex.toLowerCase()}`;
}

/**
 * Computes keccak256 hash of the Order ID for smart contract mapping lookup.
 */
export function computeOrderIdHash(orderId: string): string {
  const cleanId = (orderId || '').trim();
  return ethers.keccak256(ethers.toUtf8Bytes(cleanId));
}

