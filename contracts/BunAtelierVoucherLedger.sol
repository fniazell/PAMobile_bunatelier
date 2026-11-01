// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BunAtelierVoucherLedger
 * @author Bun Atelier Engineering Team
 * @notice Smart contract for immutable auditing of voucher redemptions, usage, and order e-receipts.
 * @dev Protects customer privacy by recording only cryptographic hashes and anonymous reference IDs.
 *      Never stores names, emails, raw promo codes, or raw payment details on-chain.
 */
contract BunAtelierVoucherLedger {
    address public owner;
    address public authorizedSigner;

    // ── VOUCHER AUDIT STRUCTS ───────────────────────────────────────────────
    struct RedemptionRecord {
        bytes32 referenceId;      // Unique non-sensitive reference ID (e.g. keccak256(voucherId))
        uint8 discountPercent;    // 5, 15, or 20 percent
        uint256 pointsBurned;     // 15, 350, or 500 points
        bytes32 proofHash;        // SHA-256 / Keccak-256 proof hash
        uint256 timestamp;        // Block timestamp
        bool exists;
    }

    struct UsageRecord {
        bytes32 referenceId;      // Unique voucher reference ID
        bytes32 orderHash;        // Hash of order summary (non-sensitive)
        uint8 discountPercent;    // Discount applied
        uint256 timestamp;        // Block timestamp
        bool exists;
    }

    // ── E-RECEIPT HASH CHAIN STRUCT ─────────────────────────────────────────
    struct ReceiptRecord {
        bytes32 orderIdHash;          // keccak256 of order ID (e.g. "BA-20261028-001")
        bytes32 receiptHash;          // SHA-256 hash of canonical order e-receipt payload
        bytes32 previousReceiptHash;  // Hash of previous receipt (genesis: bytes32(0))
        uint256 blockNumber;          // Block number when mined
        uint256 timestamp;            // Block timestamp
        bool exists;
    }

    // Mappings for tamper-proof lookup
    mapping(bytes32 => RedemptionRecord) private _redemptions;
    mapping(bytes32 => UsageRecord) private _usages;
    mapping(bytes32 => ReceiptRecord) private _receipts;
    mapping(uint256 => bytes32) private _receiptHistory;

    // Chain metadata
    bytes32 public latestReceiptHash;
    uint256 public totalReceiptsCount;

    // ── EVENTS ─────────────────────────────────────────────────────────────
    event VoucherRedeemed(
        bytes32 indexed referenceId,
        uint8 indexed discountPercent,
        uint256 pointsBurned,
        bytes32 proofHash,
        uint256 timestamp
    );

    event VoucherUsed(
        bytes32 indexed referenceId,
        bytes32 indexed orderHash,
        uint8 discountPercent,
        uint256 timestamp
    );

    event ReceiptRecorded(
        bytes32 indexed orderIdHash,
        bytes32 indexed receiptHash,
        bytes32 indexed previousReceiptHash,
        uint256 receiptIndex,
        uint256 blockNumber,
        uint256 timestamp
    );

    event AuthorizedSignerUpdated(address indexed oldSigner, address indexed newSigner);

    // ── MODIFIERS ───────────────────────────────────────────────────────────
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner may call this");
        _;
    }

    modifier onlyAuthorized() {
        require(
            msg.sender == owner || msg.sender == authorizedSigner,
            "Caller is not authorized backend signer"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
        authorizedSigner = msg.sender;
    }

    function setAuthorizedSigner(address newSigner) external onlyOwner {
        require(newSigner != address(0), "Invalid signer address");
        emit AuthorizedSignerUpdated(authorizedSigner, newSigner);
        authorizedSigner = newSigner;
    }

    // ── VOUCHER FUNCTIONS ───────────────────────────────────────────────────

    /**
     * @notice Records a voucher redemption onto the blockchain ledger.
     */
    function recordRedemption(
        bytes32 referenceId,
        uint8 discountPercent,
        uint256 pointsBurned,
        bytes32 proofHash
    ) external onlyAuthorized returns (bool) {
        require(referenceId != bytes32(0), "Reference ID cannot be empty");
        require(!_redemptions[referenceId].exists, "Voucher redemption already recorded");
        require(discountPercent == 5 || discountPercent == 15 || discountPercent == 20, "Invalid discount tier");

        _redemptions[referenceId] = RedemptionRecord({
            referenceId: referenceId,
            discountPercent: discountPercent,
            pointsBurned: pointsBurned,
            proofHash: proofHash,
            timestamp: block.timestamp,
            exists: true
        });

        emit VoucherRedeemed(
            referenceId,
            discountPercent,
            pointsBurned,
            proofHash,
            block.timestamp
        );

        return true;
    }

    /**
     * @notice Records the usage of a redeemed voucher during checkout.
     */
    function recordUsage(
        bytes32 referenceId,
        bytes32 orderHash,
        uint8 discountPercent
    ) external onlyAuthorized returns (bool) {
        require(referenceId != bytes32(0), "Reference ID cannot be empty");
        require(!_usages[referenceId].exists, "Voucher already consumed on-chain");

        _usages[referenceId] = UsageRecord({
            referenceId: referenceId,
            orderHash: orderHash,
            discountPercent: discountPercent,
            timestamp: block.timestamp,
            exists: true
        });

        emit VoucherUsed(
            referenceId,
            orderHash,
            discountPercent,
            block.timestamp
        );

        return true;
    }

    function verifyRedemption(bytes32 referenceId)
        external
        view
        returns (
            bool isRecorded,
            uint8 discountPercent,
            uint256 pointsBurned,
            bytes32 proofHash,
            uint256 timestamp
        )
    {
        RedemptionRecord memory r = _redemptions[referenceId];
        return (r.exists, r.discountPercent, r.pointsBurned, r.proofHash, r.timestamp);
    }

    function verifyUsage(bytes32 referenceId)
        external
        view
        returns (
            bool isUsed,
            bytes32 orderHash,
            uint8 discountPercent,
            uint256 timestamp
        )
    {
        UsageRecord memory u = _usages[referenceId];
        return (u.exists, u.orderHash, u.discountPercent, u.timestamp);
    }

    // ── ORDER E-RECEIPT HASH CHAIN FUNCTIONS ────────────────────────────────

    /**
     * @notice Records an immutable e-receipt hash to the blockchain ledger.
     * @param orderIdHash keccak256 hash of the order ID.
     * @param receiptHash SHA-256 canonical hash of the completed transaction e-receipt.
     * @param previousReceiptHash Hash of the previous receipt in the linear chain.
     */
    function recordReceipt(
        bytes32 orderIdHash,
        bytes32 receiptHash,
        bytes32 previousReceiptHash
    ) external onlyAuthorized returns (bool) {
        require(orderIdHash != bytes32(0), "Order ID hash cannot be empty");
        require(receiptHash != bytes32(0), "Receipt hash cannot be empty");
        require(!_receipts[orderIdHash].exists, "Order receipt already recorded");

        // Strict hash chain validation
        // First receipt (totalReceiptsCount == 0) must link to bytes32(0) genesis
        // Subsequent receipts must strictly match latestReceiptHash
        require(previousReceiptHash == latestReceiptHash, "Previous receipt hash mismatch");

        _receipts[orderIdHash] = ReceiptRecord({
            orderIdHash: orderIdHash,
            receiptHash: receiptHash,
            previousReceiptHash: previousReceiptHash,
            blockNumber: block.number,
            timestamp: block.timestamp,
            exists: true
        });

        _receiptHistory[totalReceiptsCount] = receiptHash;
        latestReceiptHash = receiptHash;
        totalReceiptsCount += 1;

        emit ReceiptRecorded(
            orderIdHash,
            receiptHash,
            previousReceiptHash,
            totalReceiptsCount - 1,
            block.number,
            block.timestamp
        );

        return true;
    }

    /**
     * @notice Verifies an order e-receipt on-chain by orderIdHash.
     */
    function verifyReceipt(bytes32 orderIdHash)
        external
        view
        returns (
            bool isRecorded,
            bytes32 receiptHash,
            bytes32 previousReceiptHash,
            uint256 blockNumber,
            uint256 timestamp
        )
    {
        ReceiptRecord memory r = _receipts[orderIdHash];
        return (r.exists, r.receiptHash, r.previousReceiptHash, r.blockNumber, r.timestamp);
    }

    /**
     * @notice Gets the total count of recorded receipts.
     */
    function getTotalReceiptsCount() external view returns (uint256) {
        return totalReceiptsCount;
    }

    /**
     * @notice Retrieves receipt hash by chain index.
     */
    function getReceiptByIndex(uint256 index) external view returns (bytes32) {
        require(index < totalReceiptsCount, "Index out of bounds");
        return _receiptHistory[index];
    }
}
