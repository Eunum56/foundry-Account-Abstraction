// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// Type declarations
// errors
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

import {IAccount} from "account-abstraction/interfaces/IAccount.sol";
import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "account-abstraction/core/Helpers.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";

import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
import {MessageHashUtils} from "openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Signature is valid, if it's minimal account owner!
contract EthAA is IAccount, Ownable {
    // ERRORS
    error EthAA__NotFromEntryPoint();
    error EthAA__NotFromEntryPointOrOwner();
    error EthAA__CallFailed(bytes);

    // STATE VARIABLES
    IEntryPoint private immutable i_entryPoint;

    // EVENTS

    // MODIFIERS
    modifier requireFromEntryPoint() {
        if (msg.sender != address(i_entryPoint)) {
            revert EthAA__NotFromEntryPoint();
        }
        _;
    }

    modifier requireFromEntryPointOrOwner() {
        if (msg.sender != address(i_entryPoint) && msg.sender != owner()) {
            revert EthAA__NotFromEntryPointOrOwner();
        }
        _;
    }

    // FUNCTIONS
    constructor(address entryPoint) Ownable(msg.sender) {
        i_entryPoint = IEntryPoint(entryPoint);
    }

    receive() external payable {}

    // EXTERNAL FUNCTIONS
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        requireFromEntryPoint
        returns (uint256 validationData)
    {
        validationData = _validateSignature(userOp, userOpHash);
        // _validateNounce();
        _payPreFund(missingAccountFunds);
    }

    function execute(address destination, uint256 amountValue, bytes calldata functionData)
        external
        requireFromEntryPointOrOwner
    {
        (bool success, bytes memory data) = payable(destination).call{value: amountValue}(functionData);
        require(success, EthAA__CallFailed(data));
    }

    // PUBLIC FUNCTIONS

    // INTERNAL FUNCTIONS
    // EIP-191 version of the Signed Hash
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        returns (uint256)
    {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);
        if (signer != owner()) {
            return SIG_VALIDATION_FAILED; //1
        }
        return SIG_VALIDATION_SUCCESS; //0
    }

    function _payPreFund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            require(success);
        }
    }

    // PRIVATE FUNCTIONS

    // VIEW AND PURE FUNCTION
    function getEntryPoint() external view returns (IEntryPoint) {
        return i_entryPoint;
    }
}
