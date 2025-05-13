// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {EthAA} from "../src/Ethereum/EthAA.sol";
import {DeployEthAA} from "../script/DeployEthAA.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {ERC20Mock} from "openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {SendPackedUserOp, PackedUserOperation, IEntryPoint} from "../script/SendPackedUserOp.s.sol";
import {ECDSA} from "openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract EthAATest is Test {
    using MessageHashUtils for bytes32;

    DeployEthAA deployer;
    HelperConfig config;
    EthAA ethAA;
    ERC20Mock usdc;
    SendPackedUserOp sendPackedUserOp;

    uint256 constant AMOUNT = 1e18;
    address user = makeAddr("user");

    function setUp() public {
        deployer = new DeployEthAA();
        (config, ethAA) = deployer.deployEthAA();
        usdc = new ERC20Mock();
        sendPackedUserOp = new SendPackedUserOp();
    }

    // USDC Mint

    // msg. sender —> MinimalAccount
    // approve some amount
    // USDC contract
    // come from the entrypoint
    function testOwnerCanExecuteCommands() public {
        // Arrange
        assertEq(usdc.balanceOf(address(ethAA)), 0);
        address destination = address(usdc);
        uint256 amountValue = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(ethAA), AMOUNT);

        // Act
        vm.prank(ethAA.owner());
        ethAA.execute(destination, amountValue, functionData);

        // Assert
        assertEq(usdc.balanceOf(address(ethAA)), AMOUNT);
    }

    function testNonOwnerCannotExecuteCommands() public {
       // Arrange
        assertEq(usdc.balanceOf(address(ethAA)), 0);
        address destination = address(usdc);
        uint256 amountValue = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(ethAA), AMOUNT);

        // Act
        vm.prank(user);
        vm.expectRevert(EthAA.EthAA__NotFromEntryPointOrOwner.selector);
        ethAA.execute(destination, amountValue, functionData);
    }

    function testRecoverSignedOp() public {
        // Arrange
        assertEq(usdc.balanceOf(address(ethAA)), 0);
        address destination = address(usdc);
        uint256 amountValue = 0;
        bytes memory funcationData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(ethAA), AMOUNT);
        bytes memory executeCallData = abi.encodeWithSelector(ethAA.execute.selector, destination, amountValue, funcationData);
        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(executeCallData, config.getConfig(), address(ethAA));
        bytes32 userOperationHash = IEntryPoint(config.getConfig().entryPoint).getUserOpHash(packedUserOp);

        // Act
        address actualSigner = ECDSA.recover(userOperationHash.toEthSignedMessageHash(), packedUserOp.signature);

        // Asseert
        assertEq(actualSigner, ethAA.owner());
    }

    // 1. sign the userop
    // 2. Call validate userops
    // 3. assert the return is correct
    function testValidationOfUserOp() public {
        // Arrange
        assertEq(usdc.balanceOf(address(ethAA)), 0);
        address destination = address(usdc);
        uint256 amountValue = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(ethAA), AMOUNT);
        bytes memory executeCallData = abi.encodeWithSelector(ethAA.execute.selector, destination, amountValue, functionData);
        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(executeCallData, config.getConfig(), address(ethAA));
        bytes32 userOperationHash = IEntryPoint(config.getConfig().entryPoint).getUserOpHash(packedUserOp);
        uint256 missingAccountFunds = 1e18;

        // Act
        vm.prank(config.getConfig().entryPoint);
        uint256 validationData = ethAA.validateUserOp(packedUserOp, userOperationHash, missingAccountFunds);

        // Assert
        assertEq(validationData, 0);
    }

    function testEntryPointCanExecuteCommands() public {
        // Arrange
        assertEq(usdc.balanceOf(address(ethAA)), 0);
        address destination = address(usdc);
        uint256 amountValue = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(ethAA), AMOUNT);
        bytes memory executeCallData = abi.encodeWithSelector(ethAA.execute.selector, destination, amountValue, functionData);
        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(executeCallData, config.getConfig(), address(ethAA));

        vm.deal(address(ethAA), AMOUNT);
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOp;

        // Act
        vm.prank(user);
        IEntryPoint(config.getConfig().entryPoint).handleOps(ops, payable(user));

        // Assert
        assertEq(usdc.balanceOf(address(ethAA)), AMOUNT);
    }
}