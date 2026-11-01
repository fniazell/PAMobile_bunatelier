import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import { ethers } from 'ethers';
import { CONTRACT_ABI, CONTRACT_BYTECODE, CONTRACT_NAME } from '../src/contracts/contractArtifact.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '../.env') });

async function main() {
  console.log('================================================================');
  console.log('   BUN ATELIER — DEPLOY SMART CONTRACT TO POLYGON AMOY TESTNET  ');
  console.log('================================================================\n');

  const rpcUrl = process.env.BLOCKCHAIN_RPC_URL || 'https://rpc-amoy.polygon.technology';
  const privateKey = process.env.BLOCKCHAIN_PRIVATE_KEY;
  const network = process.env.BLOCKCHAIN_NETWORK || 'polygon-amoy';
  const chainId = parseInt(process.env.BLOCKCHAIN_CHAIN_ID || '80002', 10);

  if (!privateKey || privateKey.includes('your_wallet_private_key') || privateKey.includes('private_key_wallet_anda')) {
    console.error('❌ ERROR: Kredensial blockchain belum lengkap di backend/.env\n');
    console.log('Silakan lengkapi environment variables berikut di backend/.env:');
    console.log('----------------------------------------------------------------');
    console.log('BLOCKCHAIN_NETWORK=amoy');
    console.log('BLOCKCHAIN_CHAIN_ID=80002');
    console.log('BLOCKCHAIN_RPC_URL=https://rpc-amoy.polygon.technology');
    console.log('BLOCKCHAIN_PRIVATE_KEY=your_wallet_private_key_without_0x');
    console.log('----------------------------------------------------------------\n');
    console.log('Panduan mendapatkan Testnet POL Polygon Amoy gratis:');
    console.log('1. Buat/gunakan wallet di MetaMask.');
    console.log('2. Salin alamat wallet Anda.');
    console.log('3. Klaim POL gratis untuk Polygon Amoy di salah satu faucet resmi:');
    console.log('   - https://faucet.polygon.technology/');
    console.log('   - https://cloud.google.com/application/web3/faucet/polygon/amoy');
    console.log('   - https://alchemy.com/faucets/polygon-amoy');
    console.log('4. Jalankan script ini kembali: npm run deploy:amoy\n');
    process.exit(1);
  }

  console.log(`📡 Menghubungkan ke Polygon Amoy RPC: ${rpcUrl} (Chain ID: ${chainId})...`);
  const provider = new ethers.JsonRpcProvider(rpcUrl, chainId);

  const wallet = new ethers.Wallet(privateKey, provider);
  console.log(`🔑 Deployer wallet address: ${wallet.address}`);

  const balance = await provider.getBalance(wallet.address);
  const balancePol = ethers.formatEther(balance);
  console.log(`💰 Wallet balance: ${balancePol} POL`);

  if (balance === 0n) {
    console.error('\n❌ Saldo wallet 0 POL. Dibutuhkan gas fee untuk deploy kontrak ke Polygon Amoy.');
    console.log('Klaim POL gratis di: https://faucet.polygon.technology/');
    process.exit(1);
  }

  console.log(`\n🚀 Mendistribusikan kontrak pintar ${CONTRACT_NAME}...`);
  const factory = new ethers.ContractFactory(CONTRACT_ABI, CONTRACT_BYTECODE, wallet);
  const contract = await factory.deploy();

  console.log(`⏳ Transaksi deployment dikirim! Tx Hash: ${contract.deploymentTransaction()?.hash}`);
  console.log('Menunggu konfirmasi block di jaringan Polygon Amoy...');

  await contract.waitForDeployment();
  const contractAddress = await contract.getAddress();
  const txHash = contract.deploymentTransaction()?.hash;

  console.log('\n================================================================');
  console.log('🎉 SMART CONTRACT BERHASIL DI-DEPLOY KE POLYGON AMOY TESTNET!');
  console.log('================================================================');
  console.log(`📍 Contract Address : ${contractAddress}`);
  console.log(`🔗 Transaction Hash : ${txHash}`);
  console.log(`🔍 Block Explorer   : https://amoy.polygonscan.com/address/${contractAddress}`);
  console.log(`🌐 Tx Explorer      : https://amoy.polygonscan.com/tx/${txHash}`);
  console.log('----------------------------------------------------------------\n');
  console.log('Langkah Terakhir: Masukkan alamat ini ke backend/.env:');
  console.log(`BLOCKCHAIN_CONTRACT_ADDRESS=${contractAddress}\n`);
}

main().catch((err) => {
  console.error('Fatal deployment error:', err);
  process.exit(1);
});

