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
  console.log('   BUN ATELIER — DEPLOY SMART CONTRACT TO ETHEREUM SEPOLIA       ');
  console.log('================================================================\n');

  const rpcUrl = process.env.BLOCKCHAIN_RPC_URL;
  const privateKey = process.env.BLOCKCHAIN_PRIVATE_KEY;
  const network = process.env.BLOCKCHAIN_NETWORK || 'sepolia';
  const chainId = parseInt(process.env.BLOCKCHAIN_CHAIN_ID || '11155111', 10);

  if (!rpcUrl || !privateKey) {
    console.error('❌ ERROR: Kredensial blockchain belum lengkap di backend/.env\n');
    console.log('Silakan lengkapi environment variables berikut di backend/.env:');
    console.log('----------------------------------------------------------------');
    console.log('BLOCKCHAIN_NETWORK=sepolia');
    console.log('BLOCKCHAIN_CHAIN_ID=11155111');
    console.log('BLOCKCHAIN_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID');
    console.log('BLOCKCHAIN_PRIVATE_KEY=your_wallet_private_key_without_0x');
    console.log('----------------------------------------------------------------\n');
    console.log('Panduan mendapatkan Testnet ETH Sepolia gratis:');
    console.log('1. Buat wallet di MetaMask / Rabby.');
    console.log('2. Salin alamat wallet Anda.');
    console.log('3. Klaim Sepolia ETH gratis di salah satu faucet resmi:');
    console.log('   - https://cloud.google.com/application/web3/faucet/ethereum/sepolia');
    console.log('   - https://sepoliafaucet.com');
    console.log('   - https://faucets.chain.link/sepolia');
    console.log('4. Dapatkan RPC URL gratis di https://www.infura.io atau https://alchemy.com');
    console.log('5. Jalankan script ini kembali: npm run deploy:sepolia\n');
    process.exit(1);
  }

  console.log(`📡 Connecting to RPC: ${rpcUrl} (Chain ID: ${chainId})...`);
  const provider = new ethers.JsonRpcProvider(rpcUrl, chainId);

  const wallet = new ethers.Wallet(privateKey, provider);
  console.log(`🔑 Deployer wallet address: ${wallet.address}`);

  const balance = await provider.getBalance(wallet.address);
  const balanceEth = ethers.formatEther(balance);
  console.log(`💰 Wallet balance: ${balanceEth} Sepolia ETH`);

  if (balance === 0n) {
    console.error('\n❌ Saldo wallet 0 Sepolia ETH. Dibutuhkan sedikit gas fee untuk deploy.');
    console.log('Klaim Sepolia ETH di: https://cloud.google.com/application/web3/faucet/ethereum/sepolia');
    process.exit(1);
  }

  console.log(`\n🚀 Deploying ${CONTRACT_NAME} contract...`);
  const factory = new ethers.ContractFactory(CONTRACT_ABI, CONTRACT_BYTECODE, wallet);
  const contract = await factory.deploy();

  console.log(`⏳ Deployment transaction submitted! Hash: ${contract.deploymentTransaction()?.hash}`);
  console.log('Menunggu konfirmasi block di jaringan Sepolia...');

  await contract.waitForDeployment();
  const contractAddress = await contract.getAddress();
  const txHash = contract.deploymentTransaction()?.hash;

  console.log('\n================================================================');
  console.log('🎉 SMART CONTRACT BERHASIL DI-DEPLOY KE SEPOLIA TESTNET!');
  console.log('================================================================');
  console.log(`📍 Contract Address : ${contractAddress}`);
  console.log(`🔗 Transaction Hash : ${txHash}`);
  console.log(`🔍 Block Explorer   : https://sepolia.etherscan.io/address/${contractAddress}`);
  console.log(`🌐 Tx Explorer      : https://sepolia.etherscan.io/tx/${txHash}`);
  console.log('----------------------------------------------------------------\n');
  console.log('Langkah Terakhir: Masukkan alamat ini ke backend/.env:');
  console.log(`BLOCKCHAIN_CONTRACT_ADDRESS=${contractAddress}\n`);
}

main().catch((err) => {
  console.error('Fatal deployment error:', err);
  process.exit(1);
});

