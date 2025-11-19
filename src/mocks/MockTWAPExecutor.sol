// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract MockTWAPExecutor {
    event TWAPScheduled(uint256 orderId, address user, address tokenIn, address tokenOut, uint256 amountIn);

    function scheduleTWAP(uint256 orderId, address user, address tokenIn, address tokenOut, uint256 amountIn) external {
        emit TWAPScheduled(orderId, user, tokenIn, tokenOut, amountIn);
    }
}