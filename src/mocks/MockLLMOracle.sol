// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ILLMOracle} from "../interfaces/ILLMOracle.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";

contract MockLLMOracle is ILLMOracle {
    event RoutingRequested(uint256 orderId, PoolKey key, uint256 amount);

    // Mock decision - can be set by tests
    string public mockDecision = "dark_pool";

    function setMockDecision(string memory decision) external {
        mockDecision = decision;
    }

    function requestRouting(
        uint256 orderId,
        PoolKey calldata key,
        uint256 amount
    ) external override {
        emit RoutingRequested(orderId, key, amount);

        // In a real implementation, this would call an LLM and then call back
        // For testing, we'll simulate the callback immediately
        // This would normally be done by an off-chain service
    }

    // Mock function to simulate LLM decision callback
    function simulateLLMDecision(address nexusHook, uint256 orderId) external {
        // Call back to NexusHook with the mock decision
        (bool success,) = nexusHook.call(
            abi.encodeWithSignature("executeLLMDecision(uint256,string)", orderId, mockDecision)
        );
        require(success, "LLM decision execution failed");
    }
}