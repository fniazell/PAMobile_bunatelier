import fs from 'fs';
import path from 'path';
import os from 'os';

const tmpJson = path.join(os.tmpdir(), 'BunAtelierVoucherLedger.json');
const d = JSON.parse(fs.readFileSync(tmpJson, 'utf8'));

const tsContent = `// Auto-generated from Solidity compiler solc ^0.8.20
export const CONTRACT_NAME = "BunAtelierVoucherLedger";
export const CONTRACT_COMPILER = "solc ^0.8.20";
export const CONTRACT_BYTECODE = "0x${d.bytecode}";
export const CONTRACT_ABI = ${JSON.stringify(d.abi, null, 2)} as const;
`;

const outTs = path.join(os.tmpdir(), 'contractArtifact.ts');
fs.writeFileSync(outTs, tsContent, 'utf8');
console.log('Successfully written contractArtifact.ts to tmp, bytes:', tsContent.length);

