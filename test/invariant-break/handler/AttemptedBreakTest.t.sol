// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {HandlerStatefulFuzzCatches} from "src/invariant-break/HandlerStatefulFuzzCatches.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {MockUSDC} from "../../mocks/MockUSDC.sol";
import {YeildERC20} from "../../mocks/YeildERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AttemptedBreakTest is StdInvariant, Test {
    HandlerStatefulFuzzCatches hsfc;
    MockUSDC mockUsdc;
    YeildERC20 mockToken2;
    IERC20[] supportedTokens;

    uint256 startingAmount;

    address user = makeAddr("user");

    function setUp() public {
        vm.prank(user); // Yeild contract mints tokens to the deployer address, hence we mock the user to give him a balance
        mockToken2 = new YeildERC20();
        startingAmount = mockToken2.INITIAL_SUPPLY();

        mockUsdc = new MockUSDC();
        mockUsdc.mint(user, startingAmount); // give usdc to user

        supportedTokens.push(mockUsdc);
        supportedTokens.push(mockToken2);

        hsfc = new HandlerStatefulFuzzCatches(supportedTokens);
        targetContract(address(hsfc)); // set target contract for fuzzing

        vm.startPrank(user);
        mockUsdc.approve(address(hsfc), startingAmount);
        mockToken2.approve(address(hsfc), startingAmount);
        vm.stopPrank();
    }

    function test_startingAmountTheSame() public view {
        assert(startingAmount == mockToken2.balanceOf(user));
        assert(startingAmount == mockUsdc.balanceOf(user));
    }

    // this is calling a lot of stupid random stuff, like tries to deposit with random tokens.
    // to see these, "fail_on_revert" must be true
    // we really want to restrict the randomness that this can do
    function statefulFuzz_invariantBreaks_FailsToFind() public {
        // as a statefull fuzz test, this is gonna randomly call all functions in the target contract, with random input data
        // so we can assume that eventually the deposit() function will be called
        // @note approvals are handled in setUp()
        vm.startPrank(user);
        hsfc.withdrawToken(mockUsdc);
        hsfc.withdrawToken(mockToken2);
        vm.stopPrank();

        assert(mockUsdc.balanceOf(address(hsfc)) == 0);
        assert(mockToken2.balanceOf(address(hsfc)) == 0);

        assert(mockUsdc.balanceOf(user) == startingAmount);
        assert(mockToken2.balanceOf(user) == startingAmount);
    }
}
