// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IDarkPool {
    function submitOrder(uint256 orderId, bytes32 encryptedDetails) external;
}