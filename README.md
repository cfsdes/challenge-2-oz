# Challenge 2 - OZ

## Summary

This repository centralizes all results for the mini-audit challenge. It contains all issues identified and unit/invariant tests used for the target code.

The objective for this test was to audit a smart contract that implements an automated market maker (AMM) using the constant-product invariant for two tokens, following the same model used by [Uniswap V1](https://docs.uniswap.org/contracts/v1/overview) pools.

Target contracts: 
- [https://github.com/cfsdes/challenge-2-oz/blob/main/src/Pool.sol](https://github.com/cfsdes/challenge-2-oz/blob/main/src/Pool.sol)

## Set-up and Running Tests

All tests created during the audit are located in the [test/](https://github.com/cfsdes/challenge-2-oz/tree/main/test) directory.

To run the tests:
```bash
git clone https://github.com/cfsdes/challenge-2-oz.git
forge install 
forge build
forge test -vvv
```