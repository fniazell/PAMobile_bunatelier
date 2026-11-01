import fs from 'fs';
import path from 'path';
import os from 'os';
import { fileURLToPath } from 'url';
import solc from 'solc';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const contractPath = path.resolve(__dirname, '../../contracts/BunAtelierVoucherLedger.sol');

console.log(`Reading contract from ${contractPath}...`);
const source = fs.readFileSync(contractPath, 'utf8');

const input = {
  language: 'Solidity',
  sources: {
    'BunAtelierVoucherLedger.sol': {
      content: source,
    },
  },
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
    outputSelection: {
      '*': {
        '*': ['abi', 'evm.bytecode', 'evm.deployedBytecode'],
      },
    },
  },
};

console.log('Compiling Solidity contract with solc...');
const output = JSON.parse(solc.compile(JSON.stringify(input)));

if (output.errors) {
  let hasError = false;
  for (const err of output.errors) {
    if (err.severity === 'error') {
      console.error('Compiler Error:', err.formattedMessage);
      hasError = true;
    } else {
      console.warn('Compiler Warning:', err.formattedMessage);
    }
  }
  if (hasError) {
    process.exit(1);
  }
}

const contract = output.contracts['BunAtelierVoucherLedger.sol']['BunAtelierVoucherLedger'];
const artifact = {
  contractName: 'BunAtelierVoucherLedger',
  compiler: 'solc ^0.8.20',
  abi: contract.abi,
  bytecode: contract.evm.bytecode.object,
  deployedBytecode: contract.evm.deployedBytecode.object,
  compiledAt: new Date().toISOString(),
};

const tmpPath = path.join(os.tmpdir(), 'BunAtelierVoucherLedger.json');
fs.writeFileSync(tmpPath, JSON.stringify(artifact, null, 2), 'utf8');

console.log(`Compilation successful! Artifact saved to ${tmpPath}`);
console.log(`ABI methods count: ${contract.abi.length}`);
console.log(`Bytecode size: ${artifact.bytecode.length / 2} bytes`);
