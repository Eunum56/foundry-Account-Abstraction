// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {EthAA} from "../src/Ethereum/EthAA.sol";
import {DeployEthAA} from "../script/DeployEthAA.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {ERC20Mock} from "openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract EthAATest is Test {
    DeployEthAA deployer;
    HelperConfig config;
    EthAA ethAA;
    ERC20Mock usdc;

    uint256 constant AMOUNT = 1e18;

    function setUp() public {
        deployer = new DeployEthAA();
        (config, ethAA) = deployer.deployEthAA();
        usdc = new ERC20Mock();
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
}