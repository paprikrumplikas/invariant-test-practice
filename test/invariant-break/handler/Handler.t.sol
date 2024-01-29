// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * The handler contract is what we are going to do fuzz tests on.
 * It restricts the randomness during fuzz runs to make them a lot more sensical.
 * If filters are unsable stupid calls.
 */

import {Test} from "forge-std/Test.sol";
// this contract is gonna be the wrapper (basically the proxy) to HandlerStatefulFuzzCatches
import {HandlerStatefulFuzzCatches} from "src/invariant-break/HandlerStatefulFuzzCatches.sol";
import {MockUSDC} from "../../mocks/MockUSDC.sol";
import {YeildERC20} from "../../mocks/YeildERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Handler is Test {
    HandlerStatefulFuzzCatches handlerStatefulFuzzCatches;
    MockUSDC mockUsdc;
    YeildERC20 mockToken2;
    address user;

    // i.e. the other contract is deployed elsewhere, not here
    constructor(
        HandlerStatefulFuzzCatches _handlerStatefulFuzzCatches,
        MockUSDC _mockUsdc,
        YeildERC20 _mockToken2,
        address _user
    ) {
        handlerStatefulFuzzCatches = _handlerStatefulFuzzCatches;
        mockUsdc = _mockUsdc; // restricting randomization
        mockToken2 = _mockToken2; // restricting randomization
        user = _user; // restricting randomization
    }

    function depositMockUsdc(uint256 _amount) public {
        uint256 amount = bound(_amount, 0, mockUsdc.balanceOf(user)); // restricting randomization
        vm.startPrank(user); // we restrint randomization by saying that only the user calls these
        mockUsdc.approve(address(handlerStatefulFuzzCatches), amount);
        handlerStatefulFuzzCatches.depositToken(mockUsdc, amount);
        vm.stopPrank();
    }

    function depositMockToken2(uint256 _amount) public {
        uint256 amount = bound(_amount, 0, mockToken2.balanceOf(user)); // restricting randomization
        vm.startPrank(user); // we restrint randomization by saying that only the user calls these
        mockToken2.approve(address(handlerStatefulFuzzCatches), amount);
        handlerStatefulFuzzCatches.depositToken(mockToken2, amount);
        vm.stopPrank();
    }

    function withdrawMockUsdc() public {
        vm.prank(user);
        handlerStatefulFuzzCatches.withdrawToken(mockUsdc);
    }

    function withdrawMockToken2() public {
        vm.prank(user);
        handlerStatefulFuzzCatches.withdrawToken(mockToken2);
    }
}
