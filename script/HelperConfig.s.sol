// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainID();

    struct NetworkConfig {
        address entryPoint;
        address account;
    }

    uint256 constant ETH_SEPOLIA_CHAINID = 11155111;
    uint256 constant ZKSYNC_SEPOLIA_CHAINID = 300;
    uint256 constant LOCAL_CHAINID = 31337;

    address constant BURNER_WALLET = 0xf511E1029dE5295f6D0dE05f4431DdA203e63607; // main wallet address
    address constant FOUNDRY_DEFAULT_WALLET = 0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D;

    mapping(uint256 chainid => NetworkConfig) public networkConfigs;

    NetworkConfig public localNetworkConfig;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAINID] = getEthSepoliaChainId();
    }

    function getConfig() public view returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public view returns (NetworkConfig memory) {
        if (chainId == LOCAL_CHAINID) {
            return getOrCreateAnvil();
        } else if (networkConfigs[chainId].account != address(0)) {
            return networkConfigs[chainId];
        } else {
            revert HelperConfig__InvalidChainID();
        }
    }

    function getEthSepoliaChainId() public pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789, account: BURNER_WALLET});
    }

    function getZKSyncSepoliaChainId() public pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: address(0), account: BURNER_WALLET});
    }

    function getOrCreateAnvil() public view returns (NetworkConfig memory) {
        if (localNetworkConfig.account != address(0)) {
            return localNetworkConfig;
        }
        //deploy a mocks

        return NetworkConfig({entryPoint: address(0), account: FOUNDRY_DEFAULT_WALLET});
    }
}
