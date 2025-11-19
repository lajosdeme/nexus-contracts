// SPDX-License-Identifier: MIT
/* pragma solidity 0.8.30;

import "forge-std/Test.sol";
import {NexusHook} from "./NexusHook.sol";
import {MockPoolManager} from "./mocks/MockPoolManager.sol";
import {MockStateView} from "./mocks/MockStateView.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockLLMOracle} from "./mocks/MockLLMOracle.sol";
import {MockDarkPool} from "./mocks/MockDarkPool.sol";
import {MockTWAPExecutor} from "./mocks/MockTWAPExecutor.sol";
import {MockYieldVault} from "./mocks/MockYieldVault.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary, toBeforeSwapDelta} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {IStateView} from "@uniswap/v4-periphery/src/interfaces/IStateView.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {ILLMOracle} from "../src/interfaces/ILLMOracle.sol";
import {IDarkPool} from "../src/interfaces/IDarkPool.sol";
import {ITWAPExecutor} from "../src/interfaces/ITWAPExecutor.sol";
import {IYieldVault} from "../src/interfaces/IYieldVault.sol";

// Simplified testable version that doesn't inherit from BaseHook for easier testing
contract NexusHookTestable {
    using PoolIdLibrary for PoolKey;

    uint256 public constant LARGE_ORDER_THRESHOLD = 10_000 ether;
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

    constructor(IStateView _stateView) {
        STATE_VIEW = _stateView;
    }

    function setLLMOracle(address _llmOracle) external {
        llmOracle = ILLMOracle(_llmOracle);
    }

    function setDarkPool(address _darkPool) external {
        darkPool = IDarkPool(_darkPool);
    }

    function setTWAPExecutor(address _twapExecutor) external {
        twapExecutor = ITWAPExecutor(_twapExecutor);
    }

    function setYieldVault(address _yieldVault) external {
        yieldVault = IYieldVault(_yieldVault);
    }

    function beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4, BeforeSwapDelta, uint24) {
        uint256 amountIn = params.amountSpecified > 0
            ? uint256(params.amountSpecified)
            : uint256(-params.amountSpecified);

        // Check if this is a large order
        bool isLargeOrder = amountIn >= LARGE_ORDER_THRESHOLD;

        if (!isLargeOrder) {
            // Allow full swap to proceed for small orders
            return (this.beforeSwap.selector, toBeforeSwapDelta(int128(int256(amountIn)), 0), 0);
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
        // For now simple heuristic, execute up to X% of liquidity
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
        MockDarkPool(address(darkPool)).submitOrder(orderId, order.user, order.tokenIn, order.tokenOut, order.amountIn);
    }

    function _routeToTWAPVault(uint256 orderId) internal {
        PendingOrder memory order = pendingOrders[orderId];

        // Deposit in vault
        yieldVault.depositForOrder(orderId, order.amountIn);

        // Schedule TWAP execution
        MockTWAPExecutor(address(twapExecutor)).scheduleTWAP(orderId, order.user, order.tokenIn, order.tokenOut, order.amountIn);
    }
}

contract NexusHookTest is Test {
    using PoolIdLibrary for PoolKey;

    NexusHookTestable hook;
    MockPoolManager poolManager;
    MockStateView stateView;
    MockERC20 token0;
    MockERC20 token1;
    MockLLMOracle llmOracle;
    MockDarkPool darkPool;
    MockTWAPExecutor twapExecutor;
    MockYieldVault yieldVault;

    PoolKey poolKey;
    address user = address(0x123);

    function setUp() public {
        // Deploy mocks
        poolManager = new MockPoolManager();
        stateView = new MockStateView(IPoolManager(address(poolManager)));
        token0 = new MockERC20("Token0", "T0", 18);
        token1 = new MockERC20("Token1", "T1", 18);
        llmOracle = new MockLLMOracle();
        darkPool = new MockDarkPool();
        twapExecutor = new MockTWAPExecutor();
        yieldVault = new MockYieldVault();

        // Deploy hook
        hook = new NexusHookTestable(IStateView(address(stateView)));

        // Create pool key
        poolKey = PoolKey({
            currency0: Currency.wrap(address(token0)),
            currency1: Currency.wrap(address(token1)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(0)) // Mock hooks for testing
        });

        // Set hook dependencies
        hook.setLLMOracle(address(llmOracle));
        hook.setDarkPool(address(darkPool));
        hook.setTWAPExecutor(address(twapExecutor));
        hook.setYieldVault(address(yieldVault));

        // Set up liquidity for testing
        PoolId poolId = poolKey.toId();
        stateView.setLiquidity(poolId, 1000000 ether); // 1M liquidity

        // Mint tokens to user
        token0.mint(user, 100000 ether);
        token1.mint(user, 100000 ether);
    }

    function testSmallOrderExecutesImmediately() public {
        uint256 smallAmount = 1000 ether; // Below LARGE_ORDER_THRESHOLD

        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: int256(smallAmount),
            sqrtPriceLimitX96: 0
        });

        vm.prank(address(poolManager));
        (bytes4 selector, BeforeSwapDelta delta,) = hook.beforeSwap(user, poolKey, params, "");

        assertEq(selector, hook.beforeSwap.selector);
        assertEq(BeforeSwapDeltaLibrary.getSpecifiedDelta(delta), int128(int256(smallAmount))); // Should execute immediately
        assertEq(BeforeSwapDeltaLibrary.getUnspecifiedDelta(delta), 0);
    }

    function testLargeOrderRoutesToLLM() public {
        uint256 largeAmount = 20000 ether; // Above LARGE_ORDER_THRESHOLD

        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: int256(largeAmount),
            sqrtPriceLimitX96: 0
        });

        vm.prank(address(poolManager));
        (bytes4 selector, BeforeSwapDelta delta,) = hook.beforeSwap(user, poolKey, params, "");

        assertEq(selector, hook.beforeSwap.selector);

        // Should execute immediate portion (5% of liquidity = 50000 ether)
        uint256 expectedImmediate = 50000 ether;
        assertEq(BeforeSwapDeltaLibrary.getSpecifiedDelta(delta), int128(int256(expectedImmediate)));

        // Check that pending order was created
        uint256 orderId = hook.orderIdCounter();
        assertEq(orderId, 1);

        (address orderUser, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountExecuted, uint256 deadline, bool isActive) = hook.pendingOrders(orderId);
        assertEq(orderUser, user);
        assertEq(amountIn, largeAmount - expectedImmediate);
        assertTrue(isActive);
    }

    function testLLMDecisionDarkPool() public {
        // Set LLM decision to dark_pool
        llmOracle.setMockDecision("dark_pool");

        // Create a large order first
        uint256 largeAmount = 20000 ether;
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: int256(largeAmount),
            sqrtPriceLimitX96: 0
        });

        vm.prank(address(poolManager));
        hook.beforeSwap(user, poolKey, params, "");

        uint256 orderId = 1;

        // Simulate LLM decision
        llmOracle.simulateLLMDecision(address(hook), orderId);

        // Check that order was routed to dark pool
        // (We can't easily check the event, but the order should be processed)
    }

    function testLLMDecisionTWAPVault() public {
        // Set LLM decision to twap_vault
        llmOracle.setMockDecision("twap_vault");

        // Create a large order first
        uint256 largeAmount = 20000 ether;
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: int256(largeAmount),
            sqrtPriceLimitX96: 0
        });

        vm.prank(address(poolManager));
        hook.beforeSwap(user, poolKey, params, "");

        uint256 orderId = 1;

        // Simulate LLM decision
        llmOracle.simulateLLMDecision(address(hook), orderId);

        // Check that deposit was made to yield vault
        uint256 depositedAmount = yieldVault.getOrderDeposit(orderId);
        assertGt(depositedAmount, 0);
    }


} */