// SPDX-License-Identifier:  MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {StatefulFuzzCatches} from "src/invariant-break/StatefulFuzzCatches.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

// inheritence order matters
contract StatefulFuzzCacthesTest is StdInvariant, Test {
    StatefulFuzzCatches statefulFuzzCatches;

    function setUp() public {
        statefulFuzzCatches = new StatefulFuzzCatches();
        targetContract(address(statefulFuzzCatches));
    }

    // this is actually statLESS fuzzzing, despite the contract name
    function test_doMoreMathAgain(uint128 randomNumber) public {
        assert(statefulFuzzCatches.doMoreMathAgain(randomNumber) != 0);
    }

    // this will (most porbably) revert with the arithmetic overflow / underflow error, as we will assign too large a value to a uin126
    // to ignore this and focus only on cases breaking the invariant, set the "fail_on_revert" in foundry.toml to "false"
    // @note statful fuzzing without a handler (restrictions) will most of the time be useless: just too many stupid random calls will be made
    function statefulFuzz_catchesInvariant() public view {
        // this is what would lead to the violation of the invariant
        assert(statefulFuzzCatches.storedValue() != 0);
    }
}
