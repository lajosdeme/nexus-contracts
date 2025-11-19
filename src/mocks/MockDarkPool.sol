// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract MockDarkPool {
    event OrderSubmitted(uint256 orderId, address user, address tokenIn, address tokenOut, uint256 amountIn);

    function submitOrder(uint256 orderId, address user, address tokenIn, address tokenOut, uint256 amountIn) external {
        emit OrderSubmitted(orderId, user, tokenIn, tokenOut, amountIn);
    }
}