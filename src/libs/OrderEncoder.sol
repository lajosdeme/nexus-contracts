// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

library OrderEncoder {
    function encodeOrder(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
            tokenIn, tokenOut, amountIn, minAmountOut, block.timestamp
        ));
    }
}