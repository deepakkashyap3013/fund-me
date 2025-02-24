// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // 1 ETH ?

        // 2000_000000000000000000
        uint256 ethPrice = getPrice(priceFeed);

        // (2000_000000000000000000 * 1_000000000000000000) / 1e18
        uint256 ethPriceInUsd = (ethPrice * ethAmount) / 1e18;

        // 2000_000000000000000000 or $2000 with 18 decimals
        return ethPriceInUsd;
    }

    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // ETH/USD sepolia 8 decimals -> 0x694AA1769357215DE4FAC081bf1f309aDC325306
        (, int answer, , , ) = priceFeed.latestRoundData();

        // ans is 1e8 to match msg.value which is 1e18 we need to multiply 1e10
        return (uint256)(answer * 1e10);
    }

    function getVersion(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        return priceFeed.version();
    }
}
