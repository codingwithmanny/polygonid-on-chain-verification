// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Imports
// ========================================================
import "./ERC721.sol";
import "./Counters.sol";
import "./GenesisUtils.sol";
import "./ICircuitValidator.sol";
import "./ZKPVerifier.sol";

// Main Contract
// ========================================================
contract ERC721Verifier is ERC721, ZKPVerifier {
    // Variables
    uint64 public constant TRANSFER_REQUEST_ID = 1;
    string private erc721Name;
    string private erc721Symbol;
    mapping(uint256 => address) public idToAddress;
    mapping(address => uint256) public addressToId;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    // Constants
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    // Functions
    /**
     * @dev constructor
     */
    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {
        erc721Name = name_;
        erc721Symbol = symbol_;
    }

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
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(_msgSender(), tokenId);
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

    /**
     * Inspired by Java code
     * Converts a decimal value to a hex value without the #
     */
    function uintToHex(uint256 decimalValue)
        public
        pure
        returns (bytes memory)
    {
        uint256 remainder;
        bytes memory hexResult = "";
        string[16] memory hexDictionary = [
            "0",
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
            "7",
            "8",
            "9",
            "A",
            "B",
            "C",
            "D",
            "E",
            "F"
        ];

        while (decimalValue > 0) {
            remainder = decimalValue % 16;
            string memory hexValue = hexDictionary[remainder];
            hexResult = abi.encodePacked(hexValue, hexResult);
            decimalValue = decimalValue / 16;
        }

        // Account for missing leading zeros
        uint256 len = hexResult.length;

        if (len == 5) {
            hexResult = abi.encodePacked("0", hexResult);
        } else if (len == 4) {
            hexResult = abi.encodePacked("00", hexResult);
        } else if (len == 3) {
            hexResult = abi.encodePacked("000", hexResult);
        } else if (len == 4) {
            hexResult = abi.encodePacked("0000", hexResult);
        }

        return hexResult;
    }

    /**
     */
    function base64Encode(bytes memory data)
        internal
        pure
        returns (string memory)
    {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    /**
     * Inspired by OraclizeAPI's implementation - MIT license
     * https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * Returns metadata associated to token
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        // Validate if tokenId exists
        require(_exists(tokenId), "Token ID does not exist.");

        string memory hexValue = string(uintToHex(tokenId));

        string memory json = base64Encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"id": ',
                        toString(tokenId),
                        ", ",
                        '"name": "#',
                        hexValue,
                        '", ',
                        '"token_name": "',
                        erc721Name,
                        '", ',
                        '"token_symbol": "',
                        erc721Symbol,
                        '", ',
                        '"background_color": "FFFFFF", ',
                        '"image": "data:image/svg+xml;base64,',
                        base64Encode(
                            bytes(
                                string(
                                    abi.encodePacked(
                                        '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><rect width="100%" height="100%" /><rect y="0" width="100%" height="100%" fill="#',
                                        hexValue,
                                        '" /></svg>'
                                    )
                                )
                            )
                        ),
                        '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
