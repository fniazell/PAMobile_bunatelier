import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import { ethers } from 'ethers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '../.env') });

async function checkWallet() {
  console.log('================================================================');
  console.log('   BUN ATELIER — CEK KONEKSI METAMASK & POLYGON AMOY TESTNET    ');
  console.log('================================================================\n');

  const rpcUrl = process.env.BLOCKCHAIN_RPC_URL || 'https://rpc-amoy.polygon.technology';
  const privateKey = process.env.BLOCKCHAIN_PRIVATE_KEY || '';
  const contractAddress = process.env.BLOCKCHAIN_CONTRACT_ADDRESS || '';
  const chainId = parseInt(process.env.BLOCKCHAIN_CHAIN_ID || '80002', 10);

  console.log(`📡 RPC Endpoint : ${rpcUrl}`);
  console.log(`🆔 Chain ID     : ${chainId} (Polygon Amoy Testnet)`);
  console.log(`🔍 Explorer     : https://amoy.polygonscan.com\n`);

  try {
    const provider = new ethers.JsonRpcProvider(rpcUrl, chainId);
    const network = await provider.getNetwork();
    console.log(`✅ Berhasil terhubung ke jaringan: Chain ID ${network.chainId}`);

    const isPlaceholderKey =
      !privateKey ||
      privateKey.includes('your_') ||
      privateKey.includes('private_key_wallet_anda');

    if (isPlaceholderKey) {
      console.log('\n⚠️  STATUS: Private key MetaMask belum dimasukkan di backend/.env');
      console.log('Silakan masukkan Private Key dari akun MetaMask Anda ke file backend/.env:');
      console.log('BLOCKCHAIN_PRIVATE_KEY=your_private_key_without_0x\n');
      return;
    }

    const cleanKey = privateKey.startsWith('0x') ? privateKey.substring(2) : privateKey;
    const wallet = new ethers.Wallet(cleanKey, provider);
    console.log(`\n🔑 Alamat Akun MetaMask : ${wallet.address}`);

    const balanceWei = await provider.getBalance(wallet.address);
    const balancePol = ethers.formatEther(balanceWei);
    console.log(`💰 Saldo Akun MetaMask  : ${balancePol} POL`);

    if (balanceWei === 0n) {
      console.log('\n⚠️  Saldo POL masih 0. Dapatkan POL gratis (faucet) untuk deploy & gas fee:');
      console.log('   1. Buka: https://faucet.polygon.technology/');
      console.log('   2. Masukkan alamat akun Anda:', wallet.address);
      console.log('   3. Klaim POL gratis');
    } else {
      console.log('\n🎉 Akun MetaMask siap bertransaksi di Polygon Amoy!');
    }

    if (contractAddress && ethers.isAddress(contractAddress)) {
      console.log(`\n📍 Smart Contract Terpasang : ${contractAddress}`);
      console.log(`🔗 Link Explorer Contract   : https://amoy.polygonscan.com/address/${contractAddress}`);
    } else {
      console.log('\n📝 Smart Contract belum di-deploy. Jalankan: npm run deploy:amoy');
    }
  } catch (err: any) {
    console.error('❌ Gagal menghubungi RPC Polygon Amoy:', err?.message || err);
  }
  console.log('\n================================================================\n');
}

checkWallet();

