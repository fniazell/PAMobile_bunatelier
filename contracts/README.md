# Bun Atelier Voucher Ledger — Smart Contract

Kontrak pintar Solidity untuk mencatat dan memverifikasi:
1. **E-Receipt transaksi pesanan** (SHA-256 hash chain on-chain)
2. **Riwayat penukaran poin menjadi voucher** (redemption)
3. **Penggunaan voucher** (usage)

Semua data tercatat secara transparan dan tidak dapat dimanipulasi (*immutable*) di jaringan Ethereum.

---

## Spesifikasi Kontrak

| Property | Value |
|---|---|
| **Contract Name** | `BunAtelierVoucherLedger` |
| **Solidity Version** | `^0.8.20` |
| **License** | MIT |
| **Target Network** | Ethereum Sepolia Testnet (Chain ID: 11155111) |
| **Compiler** | `solc ^0.8.20` via npm package |

---

## Prinsip Keamanan & Privasi

1. **Zero Personal Identifiable Information (Zero PII):**
   Kontrak tidak menyimpan nama, email, password, nomor telepon, atau data personal pelanggan.

2. **Kerahasiaan Data Transaksi:**
   Data asli transaksi tidak disimpan on-chain. Yang disimpan adalah:
   - `bytes32 orderIdHash` — keccak256 dari Order ID string
   - `bytes32 receiptHash` — SHA-256 dari canonical receipt payload (format `BUN_RECEIPT_V1`)
   - `bytes32 previousReceiptHash` — SHA-256 receipt sebelumnya (hash chain)
   - `uint256 timestamp` — waktu pencatatan

3. **Authorized Backend Signer:**
   Hanya backend resmi Bun Atelier (`authorizedSigner`) yang dapat mengeksekusi fungsi tulis.
   Private key disimpan aman di environment server (`.env`), tidak pernah masuk ke Flutter.

---

## Functions Utama

### E-Receipt Recording & Verification

| Function | Type | Keterangan |
|---|---|---|
| `recordReceipt(bytes32 orderIdHash, bytes32 receiptHash, bytes32 previousReceiptHash)` | Write | Mencatat e-receipt. Cegah duplikasi per order. |
| `verifyReceipt(bytes32 orderIdHash)` | View | Mengembalikan data receipt yang tercatat untuk verifikasi. |
| `getReceiptByIndex(uint256 index)` | View | Ambil receipt berdasarkan urutan index. |
| `getTotalReceiptsCount()` | View | Total receipt yang telah dicatat. |

### Voucher Ledger

| Function | Type | Keterangan |
|---|---|---|
| `recordRedemption(bytes32 referenceId, uint8 discountPercent, uint256 pointsBurned, bytes32 proofHash)` | Write | Catat penukaran poin → voucher. |
| `recordUsage(bytes32 referenceId, bytes32 orderHash, uint8 discountPercent)` | Write | Catat penggunaan voucher pada pesanan. |
| `verifyRedemption(bytes32 referenceId)` | View | Verifikasi data redemption. |
| `verifyUsage(bytes32 referenceId)` | View | Verifikasi data usage voucher. |

### Events

| Event | Deskripsi |
|---|---|
| `ReceiptRecorded(bytes32 indexed orderIdHash, bytes32 indexed receiptHash, bytes32 previousReceiptHash, uint256 timestamp, uint256 indexed receiptIndex)` | Dipancarkan saat receipt dicatat. Dapat di-query via Etherscan. |
| `RedemptionRecorded(bytes32 indexed referenceId, ...)` | Dipancarkan saat voucher ditukar. |
| `UsageRecorded(bytes32 indexed referenceId, ...)` | Dipancarkan saat voucher digunakan. |

---

## Format Canonical Receipt (SHA-256)

Receipt hash dihitung menggunakan format:

```
BUN_RECEIPT_V1|{orderId}|{orderType}|{branchId}|{currency}|{items_sorted_by_name}|{subtotal}|{discount}|{tax}|{deliveryFee}|{total}|{paymentMethod}|{paymentStatus}
```

Contoh:
```
BUN_RECEIPT_V1|BA001|dine-in|branch-main|IDR|OG Main Character:2:30000:60000|60000|0|0|0|60000|QRIS|confirmed
```

Format ini identik antara backend (TypeScript: `receiptCanonicalizer.ts`) dan Flutter (Dart: `receipt_canonicalizer.dart`).

---

## Kompilasi Kontrak

```bash
# Dari root project:
cd backend
node scripts/compile.js
```

Output:
- Artifact JSON: `%TEMP%\BunAtelierVoucherLedger.json`
- TypeScript artifact: `backend/src/contracts/contractArtifact.ts` (ABI + Bytecode embedded)

---

## Deployment ke Sepolia Testnet

### Langkah 1: Persiapan

1. **Buat wallet** (MetaMask/Rabby) — simpan private key dengan aman
2. **Klaim Sepolia ETH gratis** di:
   - https://cloud.google.com/application/web3/faucet/ethereum/sepolia
   - https://sepoliafaucet.com
3. **Daftar Infura** (gratis): https://www.infura.io → buat project → copy RPC URL

### Langkah 2: Konfigurasi

Isi `backend/.env` (salin dari `.env.example`):
```env
BLOCKCHAIN_NETWORK=sepolia
BLOCKCHAIN_CHAIN_ID=11155111
BLOCKCHAIN_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID
BLOCKCHAIN_PRIVATE_KEY=your_wallet_private_key_WITHOUT_0x_prefix
BLOCKCHAIN_CONTRACT_ADDRESS=   # Kosongkan dulu, isi setelah deploy
```

### Langkah 3: Deploy

```bash
cd backend
npm run compile:contracts   # Kompilasi ulang kontrak
npm run deploy:sepolia      # Deploy ke Sepolia
```

Output sukses:
```
✅ Contract deployed successfully!
Contract Address: 0xABCDEF...
Transaction Hash: 0x123456...
Block Number: 7890123
Network: sepolia (Chain ID: 11155111)
Explorer: https://sepolia.etherscan.io/address/0xABCDEF...
```

### Langkah 4: Finalisasi

```env
# Tambahkan ke backend/.env setelah deploy:
BLOCKCHAIN_CONTRACT_ADDRESS=0xABCDEF...    # Dari output deploy
```

Restart backend server, sekarang mode berubah dari `SIMULATION_FALLBACK` ke `LIVE`.

---

## Verifikasi di Block Explorer

Setelah deploy, cek transaksi di:
- **Contract**: `https://sepolia.etherscan.io/address/<CONTRACT_ADDRESS>`
- **Transaksi**: `https://sepolia.etherscan.io/tx/<TX_HASH>`
- **Events (ReceiptRecorded)**: `https://sepolia.etherscan.io/address/<CONTRACT_ADDRESS>#events`

---

## Status Blockchain di Aplikasi

| Status | Deskripsi |
|---|---|
| `SIMULATION_FALLBACK` | `.env` belum diisi — data disimpan lokal saja |
| `LIVE` | Terhubung ke Sepolia — transaksi nyata on-chain |
| `VERIFIED` | Hash receipt cocok dengan catatan on-chain |
| `TAMPERED` | Hash berbeda — data receipt telah dimodifikasi |
| `PENDING` | Transaksi dikirim, menunggu konfirmasi blok |
| `NOT_RECORDED` | Belum ada catatan on-chain untuk order ini |
| `VERIFIED_SIMULATED` | Verifikasi berhasil di mode simulator lokal |

---

## Deployment Status (Akademik)

> ⚠️ **Saat ini: SIMULATION_FALLBACK**
>
> Kontrak belum di-deploy ke jaringan live. Semua data tersimpan lokal di:
> `%TEMP%\bun_atelier_receipts.json`
>
> Untuk mengaktifkan mode live, ikuti panduan deployment di atas.

Setelah deploy nyata berhasil, update tabel ini:

| Property | Value |
|---|---|
| Contract Address | *(belum di-deploy)* |
| Deployment Tx Hash | *(belum di-deploy)* |
| Block Number | *(belum di-deploy)* |
| Network | Ethereum Sepolia Testnet |
| Chain ID | 11155111 |
| Deployer Address | *(wallet kamu)* |
| Deploy Date | *(tanggal deploy)* |
