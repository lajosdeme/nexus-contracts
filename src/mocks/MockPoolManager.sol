// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IPoolManager} from "../../lib/uniswap-hooks/lib/v4-core/src/interfaces/IPoolManager.sol";
import {Currency} from "../../lib/uniswap-hooks/lib/v4-core/src/types/Currency.sol";
import {PoolKey} from "../../lib/uniswap-hooks/lib/v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "../../lib/uniswap-hooks/lib/v4-core/src/types/BalanceDelta.sol";
import {PoolId} from "../../lib/uniswap-hooks/lib/v4-core/src/types/PoolId.sol";
import {ModifyLiquidityParams, SwapParams} from "../../lib/uniswap-hooks/lib/v4-core/src/types/PoolOperation.sol";

// Mock implementation of IPoolManager for testing
contract MockPoolManager is IPoolManager {
    // Mock storage
    mapping(bytes32 => uint128) public liquidity;

    // IPoolManager functions
    function unlock(bytes calldata data) external returns (bytes memory) {
        // Mock: do nothing, return empty
        return "";
    }

    function initialize(PoolKey memory key, uint160 sqrtPriceX96) external returns (int24 tick) {
        // Mock: return 0
        return 0;
    }

    function modifyLiquidity(PoolKey memory key, ModifyLiquidityParams memory params, bytes calldata hookData)
        external
        returns (BalanceDelta callerDelta, BalanceDelta feesAccrued)
    {
        // Mock: return zeros
        return (BalanceDelta.wrap(0), BalanceDelta.wrap(0));
    }

    function swap(PoolKey memory key, SwapParams memory params, bytes calldata hookData)
        external
        returns (BalanceDelta swapDelta)
    {
        // Mock: return zero
        return BalanceDelta.wrap(0);
    }

    function donate(PoolKey memory key, uint256 amount0, uint256 amount1, bytes calldata hookData)
        external
        returns (BalanceDelta)
    {
        // Mock: return zero
        return BalanceDelta.wrap(0);
    }

    function sync(Currency currency) external {
        // Mock: do nothing
    }

    function take(Currency currency, address to, uint256 amount) external {
        // Mock: do nothing
    }

    function settle() external payable returns (uint256 paid) {
        // Mock: return 0
        return 0;
    }

    function settleFor(address recipient) external payable returns (uint256 paid) {
        // Mock: return 0
        return 0;
    }

    function clear(Currency currency, uint256 amount) external {
        // Mock: do nothing
    }

    function mint(address to, uint256 id, uint256 amount) external {
        // Mock: do nothing
    }

    function burn(address from, uint256 id, uint256 amount) external {
        // Mock: do nothing
    }

    function updateDynamicLPFee(PoolKey memory key, uint24 newDynamicLPFee) external {
        // Mock: do nothing
    }

    // IProtocolFees functions
    function protocolFeesAccrued(Currency currency) external view returns (uint256 amount) {
        return 0;
    }

    function setProtocolFee(PoolKey memory key, uint24 newProtocolFee) external {
        // Mock: do nothing
    }

    function setProtocolFeeController(address controller) external {
        // Mock: do nothing
    }

    function collectProtocolFees(address recipient, Currency currency, uint256 amount)
        external
        returns (uint256 amountCollected)
    {
        return 0;
    }

    function protocolFeeController() external view returns (address) {
        return address(0);
    }

    // IERC6909Claims functions
    function balanceOf(address owner, uint256 id) external view returns (uint256 amount) {
        return 0;
    }

    function allowance(address owner, address spender, uint256 id) external view returns (uint256 amount) {
        return 0;
    }

    function isOperator(address owner, address spender) external view returns (bool approved) {
        return false;
    }

    function transfer(address receiver, uint256 id, uint256 amount) external returns (bool) {
        return true;
    }

    function transferFrom(address sender, address receiver, uint256 id, uint256 amount) external returns (bool) {
        return true;
    }

    function approve(address spender, uint256 id, uint256 amount) external returns (bool) {
        return true;
    }

    function setOperator(address operator, bool approved) external returns (bool) {
        return true;
    }

    // IExtsload functions
    function extsload(bytes32 slot) external view returns (bytes32 value) {
        return bytes32(0);
    }

    function extsload(bytes32 startSlot, uint256 nSlots) external view returns (bytes32[] memory values) {
        return new bytes32[](nSlots);
    }

    function extsload(bytes32[] calldata slots) external view returns (bytes32[] memory values) {
        return new bytes32[](slots.length);
    }

    // IExttload functions
    function exttload(bytes32 slot) external view returns (bytes32 value) {
        return bytes32(0);
    }

    function exttload(bytes32[] calldata slots) external view returns (bytes32[] memory values) {
        return new bytes32[](slots.length);
    }

    // Additional mock functions for testing
    function setLiquidity(bytes32 poolId, uint128 _liquidity) external {
        liquidity[poolId] = _liquidity;
    }

    function getLiquidity(bytes32 poolId) external view returns (uint128) {
        return liquidity[poolId];
    }

    function validateHookAddress(address hook) external pure returns (bool) {
        return true;
    }
}