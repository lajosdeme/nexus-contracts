// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IStateView} from "@uniswap/v4-periphery/src/interfaces/IStateView.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolId} from "@uniswap/v4-core/src/types/PoolId.sol";

contract MockStateView is IStateView {
    IPoolManager public immutable poolManager;

    mapping(PoolId => uint128) public liquidity;

    constructor(IPoolManager _poolManager) {
        poolManager = _poolManager;
    }

    function setLiquidity(PoolId poolId, uint128 _liquidity) external {
        liquidity[poolId] = _liquidity;
    }

    function getLiquidity(PoolId poolId) external view override returns (uint128) {
        return liquidity[poolId];
    }

    // Minimal implementations for other methods (not used in NexusHook)
    function getSlot0(PoolId poolId) external view override returns (uint160 sqrtPriceX96, int24 tick, uint24 protocolFee, uint24 lpFee) {
        return (79228162514264337593543950336, 0, 0, 0);
    }

    function getTickInfo(PoolId poolId, int24 tick) external view override returns (
        uint128 liquidityGross,
        int128 liquidityNet,
        uint256 feeGrowthOutside0X128,
        uint256 feeGrowthOutside1X128
    ) {
        return (0, 0, 0, 0);
    }

    function getTickLiquidity(PoolId poolId, int24 tick) external view override returns (uint128 liquidityGross, int128 liquidityNet) {
        return (0, 0);
    }

    function getTickFeeGrowthOutside(PoolId poolId, int24 tick) external view override returns (uint256 feeGrowthOutside0X128, uint256 feeGrowthOutside1X128) {
        return (0, 0);
    }

    function getFeeGrowthGlobals(PoolId poolId) external view override returns (uint256 feeGrowthGlobal0, uint256 feeGrowthGlobal1) {
        return (0, 0);
    }

    function getTickBitmap(PoolId poolId, int16 tick) external view override returns (uint256 tickBitmap) {
        return 0;
    }

    function getPositionInfo(PoolId poolId, address owner, int24 tickLower, int24 tickUpper, bytes32 salt) external view override returns (uint128 _liquidity, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128) {
        return (0, 0, 0);
    }

    function getPositionInfo(PoolId poolId, bytes32 positionId) external view override returns (uint128 _liquidity, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128) {
        return (0, 0, 0);
    }

    function getPositionLiquidity(PoolId poolId, bytes32 positionId) external view override returns (uint128 _liquidity) {
        return 0;
    }

    function getFeeGrowthInside(PoolId poolId, int24 tickLower, int24 tickUpper) external view override returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) {
        return (0, 0);
    }
}