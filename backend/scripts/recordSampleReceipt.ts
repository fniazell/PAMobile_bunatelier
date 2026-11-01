import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import { ethers } from 'ethers';
import { CONTRACT_ABI } from '../src/contracts/contractArtifact.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '../.env') });

async function main() {
  console.log('================================================================');
  console.log('   BUN ATELIER — MENCATAT E-RECEIPT SAMPLE KE POLYGON AMOY      ');
  console.log('================================================================\n');

  const rpcUrl = process.env.BLOCKCHAIN_RPC_URL || 'https://polygon-amoy-bor-rpc.publicnode.com';
  const rawKey = process.env.BLOCKCHAIN_PRIVATE_KEY || '';
  let privateKey = rawKey.startsWith('0x') ? rawKey.substring(2) : rawKey;
  if (privateKey.length === 63) privateKey = '0' + privateKey;

  const contractAddress = process.env.BLOCKCHAIN_CONTRACT_ADDRESS || '0x31609e04652f548403ae87757d509a73beaf48a3';
  const chainId = 80002;

  const provider = new ethers.JsonRpcProvider(rpcUrl, chainId);
  const wallet = new ethers.Wallet(privateKey, provider);
  const contract = new ethers.Contract(contractAddress, CONTRACT_ABI, wallet);

  console.log(`📡 Menghubungkan ke Polygon Amoy...`);
  console.log(`🔑 Signer (MetaMask) : ${wallet.address}`);
  console.log(`📍 Contract Address   : ${contractAddress}`);

  const orderId = `BUN-AMOY-${Date.now().toString().slice(-4)}`;
  const orderIdHash = ethers.keccak256(ethers.toUtf8Bytes(orderId));
  const receiptHash = ethers.keccak256(ethers.toUtf8Bytes(`RECEIPT|${orderId}|Double Beef Bun|75000|PAID`));
  const previousReceiptHash = await contract.latestReceiptHash();

  console.log(`\n📝 Mengirim bukti e-receipt transaksi ${orderId} ke Smart Contract...`);
  const tx = await contract.recordReceipt(orderIdHash, receiptHash, previousReceiptHash);
  console.log(`⏳ Transaksi terkirim! Tx Hash: ${tx.hash}`);
  console.log('Menunggu konfirmasi block...');

  const receipt = await tx.wait(1);
  console.log(`\n🎉 BERHASIL DICATAT ON-CHAIN DI POLYGON AMOY!`);
  console.log(`📦 Block Number     : ${receipt.blockNumber}`);
  console.log(`🔗 Transaction Hash : ${tx.hash}`);
  console.log(`🔍 Buka di Explorer : https://amoy.polygonscan.com/tx/${tx.hash}`);
  console.log(`📍 Buka di Kontrak  : https://amoy.polygonscan.com/address/${contractAddress}\n`);
}

main().catch(console.error);

