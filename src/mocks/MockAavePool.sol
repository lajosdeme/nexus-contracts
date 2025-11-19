// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IPool} from "../interfaces/IPool.sol";

// Mock Aave Pool for testing - simulates supply and withdraw operations
contract MockAavePool is IPool {
    // Mock supply function - does nothing, just for testing
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external {
        // Mock: do nothing
        // In a real implementation, this would deposit assets into Aave
    }

    // Mock withdraw function - returns the requested amount
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256) {
        // Mock: return the amount requested
        // In a real implementation, this would withdraw from Aave and transfer to 'to'
        return amount;
    }
}