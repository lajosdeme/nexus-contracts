// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {BaseHook} from "@openzeppelin/uniswap-hooks/src/base/BaseHook.sol";

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IStateView} from "@uniswap/v4-periphery/src/interfaces/IStateView.sol";

import {
    BeforeSwapDelta,
    BeforeSwapDeltaLibrary,
    toBeforeSwapDelta
} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";

import {
    IPoolManager,
    SwapParams,
    ModifyLiquidityParams
} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";

import {ILLMOracle} from "./interfaces/ILLMOracle.sol";
import {IDarkPool} from "./interfaces/IDarkPool.sol";
import {ITWAPExecutor} from "./interfaces/ITWAPExecutor.sol";
import {IYieldVault} from "./interfaces/IYieldVault.sol";

contract NexusHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    // Threshold for "large order" - $10,000 equivalent
    uint256 public constant LARGE_ORDER_THRESHOLD = 10_000 ether; // USDC

    // Maximum immediate execution without routing (10% of liquidity or $1000)
    uint256 public constant IMMEDIATE_EXECUTION_LIMIT = 1_000 ether;

    IStateView immutable STATE_VIEW;

    ILLMOracle public llmOracle;
    IDarkPool public darkPool;
    IYieldVault public yieldVault;
    ITWAPExecutor public twapExecutor;

    uint256 swapLiqPct = 500; // e.g., 500 = 5%

    event OrderRouted(uint256 indexed orderId, uint256 amount);
    event LLMDecisionExecuted(uint256 indexed orderId, string decision);

    struct PendingOrder {
        address user;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountExecuted;
        uint256 deadline;
        bool isActive;
    }

    mapping(uint256 => PendingOrder) public pendingOrders;
    uint256 public orderIdCounter;

    constructor(IPoolManager _poolManager, IStateView _stateView) BaseHook(_poolManager) {
        STATE_VIEW = _stateView;
    }

    function setLLMOracle(ILLMOracle _llmOracle) external {
        llmOracle = _llmOracle;
    }

    function setDarkPool(IDarkPool _darkPool) external {
        darkPool = _darkPool;
    }

    function setYieldVault(IYieldVault _yieldVault) external {
        yieldVault = _yieldVault;
    }

    function setTWAPExecutor(ITWAPExecutor _twapExecutor) external {
        twapExecutor = _twapExecutor;
    }

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: false,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: true, // We need this
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }

    function beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    ) external override returns (bytes4, BeforeSwapDelta, uint24) {
        uint256 amountIn = params.amountSpecified > 0
            ? uint256(params.amountSpecified)
            : uint256(-params.amountSpecified);

        // Check if this is a large order
        bool isLargeOrder = amountIn >= LARGE_ORDER_THRESHOLD;

        if (!isLargeOrder) {
            return (this.beforeSwap.selector, toBeforeSwapDelta(0, 0), 0);
        }

        // Execute small portion immediately
        uint256 immediateAmount = _calculateImmediateAmount(key, amountIn);
        uint256 remainingAmount = amountIn - immediateAmount;

        uint256 orderId = ++orderIdCounter;

        // Store pending order
        pendingOrders[orderId] = PendingOrder({
            user: sender,
            tokenIn: Currency.unwrap(key.currency0),
            tokenOut: Currency.unwrap(key.currency1),
            amountIn: remainingAmount,
            amountExecuted: immediateAmount,
            deadline: block.timestamp + 1 hours,
            isActive: true
        });

        // Call LLM oracle to decide routing
        _routeToLLM(orderId, key, remainingAmount);

        // Return: allow immediate amount to execute, block the rest
        return (
            this.beforeSwap.selector,
            toBeforeSwapDelta(int128(int256(immediateAmount)), 0),
            0
        );
    }

    function executeLLMDecision(uint256 orderId, string memory decision) external {
        require(msg.sender == address(llmOracle), "only LLM oracle");

        PendingOrder storage order = pendingOrders[orderId];
        require(order.isActive, "order not active");

        if (keccak256(bytes(decision)) == keccak256("dark_pool")) {
            _routeToDarkPool(orderId);
        } else if (keccak256(bytes(decision)) == keccak256("twap_vault")) {
            _routeToTWAPVault(orderId);
        }

        emit LLMDecisionExecuted(orderId, decision);
    }

    function _calculateImmediateAmount(
        PoolKey calldata key,
        uint256 totalAmount
    ) internal view returns (uint256) {
        // Fow now simple heuristic, execute up to X% of liquidity
        uint256 L = _getPoolLiquidity(key);
        return uint128((L * swapLiqPct) / 10_000);
    }

    function _getPoolLiquidity(
        PoolKey calldata key
    ) internal view returns (uint256) {
        PoolId poolId = key.toId();
        return STATE_VIEW.getLiquidity(poolId);
    }

    function _routeToLLM(
        uint256 orderId,
        PoolKey calldata key,
        uint256 amount
    ) internal {
        llmOracle.requestRouting(orderId, key, amount);

        emit OrderRouted(orderId, amount);
    }

    function _routeToDarkPool(uint256 orderId) internal {
        PendingOrder memory order = pendingOrders[orderId];
        darkPool.submitOrder(orderId, order.user, order.tokenIn, order.tokenOut, order.amountIn);
    }

    function _routeToTWAPVault(uint256 orderId) internal {
        PendingOrder storage order = pendingOrders[orderId];
        
        // Deposit in vault
        yieldVault.depositForOrder(orderId, order.amountIn, order.deadline);
        
        // Schedule TWAP execution
        twapExecutor.scheduleTWAP(orderId, order);
    }
}
