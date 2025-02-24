// 1. Deploy mocks when we are on a local anvil chain
// 2. keep track of contract address across different chains

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    uint8 public constant DECIMAL = 8;
    int256 public constant INIT_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed; // ETH/USD price feed address
    }
    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() private pure returns (NetworkConfig memory) {
        // ETH/USD price feed address for sepolia eth -> 0x694AA1769357215DE4FAC081bf1f309aDC325306
        return
            NetworkConfig({
                priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
            });
    }

    function getMainnetEthConfig() private pure returns (NetworkConfig memory) {
        // ETH/USD price feed address for mainnet eth -> 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        return
            NetworkConfig({
                priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
            });
    }

    function getOrCreateAnvilEthConfig()
        private
        returns (NetworkConfig memory)
    {
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        // 1. Deploy the mocks
        // 2. Return the mock address

        vm.startBroadcast();
        MockV3Aggregator mockAggregator = new MockV3Aggregator(
            DECIMAL,
            INIT_PRICE
        );
        vm.stopBroadcast();
        return NetworkConfig({priceFeed: address(mockAggregator)});
    }
}
