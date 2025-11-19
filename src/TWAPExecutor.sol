// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IYieldVault} from "./interfaces/IYieldVault.sol";

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";

contract TWAPExecutor {
    IYieldVault public vault;
    IPoolManager public poolManager;

    struct TWAPOrder {
        uint256 orderId;
        address user;
        address tokenIn;
        address tokenOut;
        uint256 totalAmount;
        uint256 executedAmount;
        uint256 numChunks;
        uint256 intervalSeconds;
        uint256 startTime;
        uint256 lastExecutionTime;
        bool isComplete;
    }

    mapping(uint256 => TWAPOrder) public twapOrders;

    event TWAPScheduled(uint256 indexed orderId, uint256 numChunks);
    event TWAPChunkExecuted(
        uint256 indexed orderId,
        uint256 chunk,
        uint256 amount
    );

    function scheduleTWAP(
        uint256 orderId,
        address user,
        address tokenIn,
        address tokenOut,
        uint256 amount
    ) external {
        // Simple: 5 chunks over 1 hour = execute every 12 minutes
        uint256 numChunks = 5;
        uint256 intervalSeconds = 12 minutes;

        twapOrders[orderId] = TWAPOrder({
            orderId: orderId,
            user: user,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            totalAmount: amount,
            executedAmount: 0,
            numChunks: numChunks,
            intervalSeconds: intervalSeconds,
            startTime: block.timestamp,
            lastExecutionTime: 0,
            isComplete: false
        });

        emit TWAPScheduled(orderId, numChunks);
    }

    // Anyone can call this to execute next chunk (could use Chainlink Automation)
    function executeNextChunk(uint256 orderId) external {
        TWAPOrder storage order = twapOrders[orderId];
        require(!order.isComplete, "TWAP complete");

        // Check if enough time passed since last execution
        require(
            block.timestamp >= order.lastExecutionTime + order.intervalSeconds,
            "Too soon"
        );

        // Calculate chunk size
        uint256 remainingChunks = order.numChunks -
            ((order.executedAmount * order.numChunks) / order.totalAmount);
        uint256 chunkSize = order.totalAmount / order.numChunks;

        // Execute swap from vault
        bytes memory swapData = _buildSwapData(
            order.tokenIn,
            order.tokenOut,
            chunkSize
        );
        vault.executeTWAPChunk(
            orderId,
            chunkSize,
            address(poolManager),
            swapData
        );

        // Update state
        order.executedAmount += chunkSize;
        order.lastExecutionTime = block.timestamp;

        if (order.executedAmount >= order.totalAmount) {
            order.isComplete = true;
        }

        emit TWAPChunkExecuted(
            orderId,
            order.executedAmount / chunkSize,
            chunkSize
        );
    }

    function _buildSwapData(
        address tokenIn,
        address tokenOut,
        uint256 amount
    ) internal pure returns (bytes memory) {
        // Build Uniswap V4 swap calldata
        // Simplified for demo
        return
            abi.encodeWithSignature(
                "swap(address,address,uint256)",
                tokenIn,
                tokenOut,
                amount
            );
    }
}
