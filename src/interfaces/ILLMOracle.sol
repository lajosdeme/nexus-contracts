// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";

interface ILLMOracle {
    function requestRouting(
        uint256 orderId,
        PoolKey calldata key,
        uint256 amount
    ) external;
}
