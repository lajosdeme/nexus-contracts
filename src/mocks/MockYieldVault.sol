// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IYieldVault} from "../interfaces/IYieldVault.sol";

contract MockYieldVault is IYieldVault {
    event DepositForOrder(uint256 orderId, uint256 amountIn);

    mapping(uint256 => uint256) public orderDeposits;

    function depositForOrder(uint256 orderId, uint256 amountIn) external override {
        orderDeposits[orderId] = amountIn;
        emit DepositForOrder(orderId, amountIn);

        // Mock implementation - just record the deposit
        // In real implementation, this would deposit into a yield-generating vault
    }

    function getOrderDeposit(uint256 orderId) external view returns (uint256) {
        return orderDeposits[orderId];
    }

    function executeTWAPChunk(
        uint256 orderId,
        uint256 chunkAmount,
        address swapTarget,
        bytes calldata swapData
    ) external {
        
    }
}