// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {
    ERC4626
} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {IPool} from "./interfaces/IPool.sol";

contract NexusYieldVault is ERC4626 {
    IPool public immutable aavePool;
    IERC20 public immutable aToken;

    event OrderReserved(
        uint256 indexed orderId,
        uint256 amount,
        uint256 deadline
    );
    event TWAPChunkExecuted(uint256 indexed orderId, uint256 amount);

    // Track reserved funds for pending orders
    struct OrderReservation {
        uint256 amount;
        uint256 deadline;
        address owner;
    }

    mapping(uint256 => OrderReservation) public reservations;

    constructor(
        IERC20 asset_,
        IPool aavePool_,
        IERC20 aToken_
    ) ERC4626(asset_) ERC20("Nexus Yield Vault", "nxVLT") {
        aavePool = aavePool_;
        aToken = aToken_;
    }

    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        super._deposit(caller, receiver, assets, shares);

        // Deposit into Aave to earn yield
        IERC20(asset()).approve(address(aavePool), assets);
        aavePool.supply(address(asset()), assets, address(this), 0);
    }

    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        // Withdraw from Aave first
        aavePool.withdraw(address(asset()), assets, address(this));

        super._withdraw(caller, receiver, owner, assets, shares);
    }

    function depositForOrder(
        uint256 orderId,
        uint256 amount,
        uint256 deadline
    ) external returns (uint256 shares) {
        // Deposit assets
        shares = deposit(amount, msg.sender);

        // Reserve for order execution
        reservations[orderId] = OrderReservation({
            amount: amount,
            deadline: deadline,
            owner: msg.sender
        });

        emit OrderReserved(orderId, amount, deadline);
    }

    function executeTWAPChunk(
        uint256 orderId,
        uint256 chunkAmount,
        address swapTarget,
        bytes calldata swapData
    ) external {
        OrderReservation storage reservation = reservations[orderId];
        require(reservation.amount >= chunkAmount, "Insufficient reserved");
        require(block.timestamp <= reservation.deadline, "Order expired");

        // Withdraw from Aave
        uint256 shares = previewWithdraw(chunkAmount);
        aavePool.withdraw(address(asset()), chunkAmount, address(this));

        // Execute swap via Uniswap V4 or other DEX
        IERC20(asset()).approve(swapTarget, chunkAmount);
        (bool success, ) = swapTarget.call(swapData);
        require(success, "Swap failed");

        // Update reservation
        reservation.amount -= chunkAmount;

        // Burn shares from user
        _burn(reservation.owner, shares);

        emit TWAPChunkExecuted(orderId, chunkAmount);
    }

    function totalAssets() public view virtual override returns (uint256) {
        // aToken balance represents our deposits + earned interest
        return aToken.balanceOf(address(this));
    }
}
