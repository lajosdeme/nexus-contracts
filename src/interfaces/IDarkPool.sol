// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IDarkPool {
    function submitOrder(bytes32 encryptedDetails) external returns (uint256 orderId);
    function submitOrder(uint256 orderId, address user, address tokenIn, address tokenOut, uint256 amountIn) external;
}