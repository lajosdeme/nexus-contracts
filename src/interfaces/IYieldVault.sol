// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IYieldVault {
    function depositForOrder(uint256 orderId, uint256 amountIn) external;
}