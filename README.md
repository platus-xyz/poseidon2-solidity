# Poseidon2 Solidity

Gas-optimized [Poseidon2](https://eprint.iacr.org/2023/323) for the BN254 scalar field, implemented in Solidity and inline Yul. The implementation is unaudited.

## Parameters

| Parameter | Value |
| --- | --- |
| State width | 4 |
| Rate / capacity | 3 / 1 |
| S-box | `x^5` |
| Rounds | 8 full (4 + 4), 56 partial |
| Domain tag | `inputs.length << 64` in the capacity lane |

Inputs are `uint256` values reduced modulo the BN254 scalar-field modulus. The construction and test vectors match the [TypeScript reference implementation](https://github.com/platus-xyz/poseidon2).

## API

The `Poseidon2BN254` library provides an allocation-free fixed-arity path and a variable-length sponge:

```solidity
import {Poseidon2BN254} from "contracts/Poseidon2BN254.sol";

uint256 twoInputs = Poseidon2BN254.hash2(left, right);
uint256 variableLength = Poseidon2BN254.hash(inputs);
```

`Poseidon2` is a selector-less contract. Call it with zero or more packed 32-byte words (`abi.encodePacked(...)`); it returns one 32-byte digest and rejects calldata whose length is not a multiple of 32. The optimized width-4 permutation is kept internal to the hashing paths.

## Benchmarks

| Input words | Gas usage |
| ---: | ---: |
| 0 | 19,637 |
| 1 | 19,640 |
| 2 | 19,646 |
| 3 | 19,652 |
| 4 | 36,415 |
| 5 | 36,421 |
| 6 | 36,427 |
| 7 | 53,190 |
| 9 | 53,202 |
| 10 | 69,965 |
| 12 | 69,977 |
| 20 | 120,297 |
| 32 | 187,398 |
| 64 | 371,924 |

For comparison, the original implementation: [circomlib-compatible Poseidon Solidity implementation](https://github.com/vocdoni/poseidon-solidity):

|  Inputs |        Original Poseidon | Poseidon2 |       Difference |
| ------: | -----------------------: | ----------------------: | ---------------: |
| 2 words | `PoseidonT3`: 21,064 gas |              19,646 gas |   −1,418 (−6.7%) |
| 3 words | `PoseidonT4`: 37,595 gas |              19,652 gas | −17,943 (−47.7%) |

## Development

Requirements: Foundry and pnpm.

```sh
forge build --sizes
forge test
forge test --gas-report -vv
pnpm lint
```

MIT licensed. Review and audit the code before production use.
