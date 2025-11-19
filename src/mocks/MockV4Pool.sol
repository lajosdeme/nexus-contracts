// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {
    PoolKey
} from "../../lib/uniswap-hooks/lib/v4-core/src/types/PoolKey.sol";
import {
    BalanceDelta
} from "../../lib/uniswap-hooks/lib/v4-core/src/types/BalanceDelta.sol";
import {
    SwapParams
} from "../../lib/uniswap-hooks/lib/v4-core/src/types/PoolOperation.sol";
import {
    BeforeSwapDelta,
    BeforeSwapDeltaLibrary
} from "../../lib/uniswap-hooks/lib/v4-core/src/types/BeforeSwapDelta.sol";

import {NexusHook} from "../NexusHook.sol";

import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";

import {IHooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";


// Mock V4 Pool for testing - simulates swapping and calls beforeSwap hook
contract MockV4Pool {
    PoolKey public key;

    NexusHook public hook;

    constructor(address _hook, address token1, address token2) {
        hook = NexusHook(_hook);
        key = PoolKey({
            currency0: Currency.wrap(token1),
            currency1: Currency.wrap(token2),
            fee: 0,
            tickSpacing: 0,
            hooks: IHooks(_hook)
        });
    }

    // Mock swap function that calls the beforeSwap hook if present
    function swap(
        SwapParams memory params,
        bytes calldata hookData
    ) external returns (BalanceDelta) {
        (bytes4 selector, BeforeSwapDelta beforeDelta, uint24 fee) = hook
            .beforeSwap(msg.sender, key, params, hookData);
        // Return a mock balance delta (e.g., amount0 swapped for amount1)
        // For simplicity, return zero delta
        return BalanceDelta.wrap(0);
    }

    // Additional mock functions can be added as needed
}
