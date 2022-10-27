// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Imports
// ========================================================
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./lib/GenesisUtils.sol";
import "./interfaces/ICircuitValidator.sol";
import "./verifiers/ZKPVerifier.sol";

// Main Contract
// ========================================================
contract ERC20Verifier is ERC20, ZKPVerifier {
    // Variables
    uint64 public constant TRANSFER_REQUEST_ID = 1;
    uint256 public TOKEN_AMOUNT_FOR_AIRDROP_PER_ID =
        5 * 10**uint256(decimals());
    mapping(uint256 => address) public idToAddress;
    mapping(address => uint256) public addressToId;

    // Functions
    /**
     * @dev constructor
     */
    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

    /**
     * @dev _beforeProofSubmit
     */
    function _beforeProofSubmit(
        uint64, /* requestId */
        uint256[] memory inputs,
        ICircuitValidator validator
    ) internal view override {
        // check that challenge input of the proof is equal to the msg.sender
        address addr = GenesisUtils.int256ToAddress(
            inputs[validator.getChallengeInputIndex()]
        );
        require(
            _msgSender() == addr,
            "address in proof is not a sender address"
        );
    }

    /**
     * @dev _afterProofSubmit
     */
    function _afterProofSubmit(
        uint64 requestId,
        uint256[] memory inputs,
        ICircuitValidator validator
    ) internal override {
        require(
            requestId == TRANSFER_REQUEST_ID && addressToId[_msgSender()] == 0,
            "proof can not be submitted more than once"
        );

        uint256 id = inputs[validator.getChallengeInputIndex()];
        // execute the airdrop
        if (idToAddress[id] == address(0)) {
            super._mint(_msgSender(), TOKEN_AMOUNT_FOR_AIRDROP_PER_ID);
            addressToId[_msgSender()] = id;
            idToAddress[id] = _msgSender();
        }
    }

    /**
     * @dev _beforeTokenTransfer
     */
    function _beforeTokenTransfer(
        address, /* from */
        address to,
        uint256 /* amount */
    ) internal view override {
        require(
            proofs[to][TRANSFER_REQUEST_ID] == true,
            "only identities who provided proof are allowed to receive tokens"
        );
    }
}
