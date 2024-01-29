// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {HandlerStatefulFuzzCatches} from "src/invariant-break/HandlerStatefulFuzzCatches.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {MockUSDC} from "../../mocks/MockUSDC.sol";
import {YeildERC20} from "../../mocks/YeildERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Handler} from "./Handler.t.sol";

contract Invariant is StdInvariant, Test {
    HandlerStatefulFuzzCatches hsfc;
    MockUSDC mockUsdc;
    YeildERC20 mockToken2;
    Handler handler;

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

        // We will not fuzz on the original contract because there would be many stupid, unusable calls
        // targetContract(address(hsfc)); // set target contract for fuzzing

        // instead, we fuzz on the handler
        handler = new Handler(hsfc, mockUsdc, mockToken2, user);

        // but instead of defining just the target contract, we define the target contract and target selectors
        bytes4[] memory selectors = new bytes4[](4); // for vars defined in memory, we need to specify the size at declararion

        selectors[0] = handler.depositMockToken2.selector;
        selectors[1] = handler.depositMockUsdc.selector;
        selectors[2] = handler.withdrawMockToken2.selector;
        selectors[3] = handler.withdrawMockUsdc.selector;

        targetContract(address(handler));
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    // invariant: users should always be able to withdraw all there tokens
    /**
     * This finds an issue: insufficient balance for mockToken2 withdrawal.
     * Resaon: on YeildMock20.sol, we call deposit, withdraw, deposit, withdraw...
     * On the 10th time, a fee is taken upon withdrawal (transfer).
     * This is one kind of "weird ERC20" (irregular ERC20 that plagues the web3 scene) token: a fee on transfer ERC20.
     *
     */
    function statefulFuzz_invariantBreaksHandler() public {
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
