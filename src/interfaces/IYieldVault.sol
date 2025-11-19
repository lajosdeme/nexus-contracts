// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IYieldVault {
    function depositForOrder(uint256 orderId, uint256 amount, uint256 deadline) external returns (uint256 shares);

    function executeTWAPChunk(
        uint256 orderId,
        uint256 chunkAmount,
        address swapTarget,
        bytes calldata swapData
    ) external;
}