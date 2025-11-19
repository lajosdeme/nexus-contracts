// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {NexusHook} from "../NexusHook.sol";

interface ITWAPExecutor {
    function scheduleTWAP(uint256 orderId, NexusHook.PendingOrder memory order) external;
}