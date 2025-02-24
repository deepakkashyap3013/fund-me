// Get funds from user
// Owner should be able to withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity ^0.8.28;

// 2. Imports
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

// 3. Interfaces, Libraries, Contracts (none)

/**
 * @title A sample Funding Contract
 * @author Deepak Kashyap
 * @notice This contract is for creating a sample funding contract
 * @dev This implements price feeds as per chainlink library
 */
contract FundMe {
    // library usage read more about this 👉 https://solidity-by-example.org/library/
    // Type Declarations
    using PriceConverter for uint256;

    // State variables
    uint256 public constant MINIMUM_USD = 5 * 1e18; // $5 with 18 decimals
    address private immutable i_owner;
    address[] private s_funders;
    mapping(address funder => uint256 amountFunded)
        private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    // Events (we have none!)

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == i_owner, "Sender must be owner");
        _;
    }

    // Functions Order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /// @notice Funds our contract based on the ETH/USD price
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "didn't send enough eth"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value; // saved in terms of wei or 1e18
    }

    function withdraw() public onlyOwner {
        uint fundersLen = s_funders.length;
        for (uint i = 0; i < fundersLen; i++) {
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        require(callSuccess, "funds withdraw failed");
    }

    /**
     * Getter Functions
     */

    /**
     * @notice Gets the amount that an address has funded
     *  @param fundingAddress the address of the funder
     *  @return the amount funded
     */
    function getAddressToAmountFunded(
        address fundingAddress
    ) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
