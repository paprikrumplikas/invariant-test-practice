/*
 * ./src/invariant-break/FormalVerificationCatches.sol 
 *
 * Certora Formal Verification Spec
 */ 

 methods {
    function hellFunc(uint128) external returns uint256 envfree;
 }

// Invariant: hellFunc must never revert
 rule hellFuncMustNeverRevert(uint128 number) {
    hellFunc(number);
    assert(lastReverted == false);
 }