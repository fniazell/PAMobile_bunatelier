import { ethers } from 'ethers';

async function checkAddress(address: string) {
  const rpcUrl = 'https://polygon-amoy-bor-rpc.publicnode.com';
  console.log(`Checking balance for: ${address}`);
  console.log(`RPC: ${rpcUrl}`);
  try {
    const provider = new ethers.JsonRpcProvider(rpcUrl, 80002);
    const balance = await provider.getBalance(address);
    console.log(`Balance: ${ethers.formatEther(balance)} POL`);
  } catch (err: any) {
    console.error('Error querying balance:', err.message);
  }
}

const target = process.argv[2] || '0x4f8a1bDf0C78C641c4a82525130b8d653C34CdB1';
checkAddress(target);

