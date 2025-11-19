// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {IDarkPool} from "../src/interfaces/IDarkPool.sol";
import {IYieldVault} from "../src/interfaces/IYieldVault.sol";
import {ITWAPExecutor} from "../src/interfaces/ITWAPExecutor.sol";

import {MockERC20} from "../src/mocks/MockERC20.sol";
import {MockPoolManager} from "../src/mocks/MockPoolManager.sol";
import {MockStateView} from "../src/mocks/MockStateView.sol";
import {MockAavePool} from "../src/mocks/MockAavePool.sol";
import {DarkPool} from "../src/DarkPool.sol";
import {NexusYieldVault} from "../src/NexusYieldVault.sol";
import {TWAPExecutor} from "../src/TWAPExecutor.sol";
import {NexusHook} from "../src/NexusHook.sol";
import {MockLLMOracle} from "../src/mocks/MockLLMOracle.sol";

import {MockV4Pool} from "../src/mocks/MockV4Pool.sol";

import {SwapParams} from "../lib/uniswap-hooks/lib/v4-core/src/types/PoolOperation.sol";



/* 
USDC: 0x613106b0cF1C765e877ae5cD8a8D40CfEE98EB62
  NXX: 0x8e99D58dE0140e07331Fb388722906AE2499584c

  POOL: 0x71c34113a6A3E18C36db14D2D756dD6A7f08daC0
 */
 
contract Deploy is Script {
    function run() external {
        uint256 deployerPrivKey = vm.envUint("KEY");
        vm.startBroadcast(deployerPrivKey);

        // Deploy mock ERC20 tokens
        MockERC20 usdc = new MockERC20("USD Coin", "USDC", 18);
        MockERC20 nxx = new MockERC20("Nexus Token", "NXX", 18);
        MockERC20 aUsdc = new MockERC20("Aave USD Coin", "aUSDC", 18);

        // Deploy mocks
        MockPoolManager poolManager = new MockPoolManager();
        MockStateView stateView = new MockStateView(poolManager);
        MockAavePool aavePool = new MockAavePool();

        // Deploy actual contracts
        DarkPool darkPool = new DarkPool();
        NexusYieldVault yieldVault = new NexusYieldVault(usdc, aavePool, aUsdc);
        TWAPExecutor twapExecutor = new TWAPExecutor();
        MockLLMOracle llmOracle = new MockLLMOracle();

        // Set TWAPExecutor dependencies
        twapExecutor.setVault(yieldVault);
        twapExecutor.setPoolManager(poolManager);

        // Deploy NexusHook
        NexusHook nexusHook = new NexusHook(poolManager, stateView);

        // Set NexusHook dependencies
        nexusHook.setLLMOracle(llmOracle);
        nexusHook.setDarkPool(IDarkPool(address(darkPool)));
        nexusHook.setYieldVault(IYieldVault(address(yieldVault)));
        nexusHook.setTWAPExecutor(ITWAPExecutor(address(twapExecutor)));

        MockV4Pool pool = new MockV4Pool(address(nexusHook), address(usdc), address(nxx));

        // Log addresses
        console2.log("USDC:", address(usdc));
        console2.log("NXX:", address(nxx));
        console2.log("aUSDC:", address(aUsdc));
        console2.log("MockPoolManager:", address(poolManager));
        console2.log("MockStateView:", address(stateView));
        console2.log("MockAavePool:", address(aavePool));
        console2.log("DarkPool:", address(darkPool));
        console2.log("NexusYieldVault:", address(yieldVault));
        console2.log("TWAPExecutor:", address(twapExecutor));
        console2.log("MockLLMOracle:", address(llmOracle));
        console2.log("NexusHook:", address(nexusHook));
        console2.log("POOL:", address(pool));

        bytes memory dummy;
        pool.swap(
            SwapParams({
            zeroForOne: true,
            amountSpecified: 1_000_000 ether,
            sqrtPriceLimitX96: 0
        }), dummy);

        nexusHook.pendingOrders(1);


        vm.stopBroadcast();
    }
}