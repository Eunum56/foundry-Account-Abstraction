// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";


contract SendPackedUserOp is Script {
    using MessageHashUtils for bytes32;

    function run() public {} 

    function generateSignedUserOperation(bytes memory callData, HelperConfig.NetworkConfig memory config, address ethAA) public view returns(PackedUserOperation memory) {
        // 1. Generate unsigned data
        uint256 nonce = vm.getNonce(ethAA) - 1;
        PackedUserOperation memory userOp = _generateUnsignedUserOperation(callData,ethAA, nonce);

        // 2. Get the user OP hash
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        bytes32 digest = userOpHash.toEthSignedMessageHash();

        // 3. Signed It and return it
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        if(block.chainid == 31337) {
            (v, r, s) = vm.sign(DEFAULT_ANVIL_KEY, digest);
        } else {
        (v, r, s) = vm.sign(config.account, digest);
        }
        userOp.signature = abi.encodePacked(r, s, v);
        return userOp;
    }

    function _generateUnsignedUserOperation(bytes memory callData, address sender, uint256 nonce) public pure returns(PackedUserOperation memory) {
        // struct PackedUserOperation {
        //     address sender;
        //     uint256 nonce;
        //     bytes initCode;
        //     bytes callData;
        //     bytes32 accountGasLimits;
        //     uint256 preVerificationGas;
        //     bytes32 gasFees;
        //     bytes paymasterAndData;
        //     bytes signature;
        // }

        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;

        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;

        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
    }
}
