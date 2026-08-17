// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Poseidon2PermX} from "./Poseidon2PermX.sol";

/// @title Poseidon2
/// @notice Selector-less, rate-3 Poseidon2 sponge over the BN254 scalar field.
contract Poseidon2 {
    uint256 private constant P = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;

    fallback() external {
        uint256 size;
        assembly ("memory-safe") {
            size := calldatasize()
            if and(size, 31) {
                // Error("Poseidon2: calldata must be 32-byte words").
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(4, 32)
                mstore(36, 41)
                mstore(68, 0x506f736569646f6e323a2063616c6c64617461206d7573742062652033322d62)
                mstore(100, 0x79746520776f7264730000000000000000000000000000000000000000000000)
                revert(0, 132)
            }
        }

        uint256 s0;
        uint256 s1;
        uint256 s2;
        uint256 s3;
        assembly ("memory-safe") {
            // size / 32 << 64 == size << 59.
            s0 := calldataload(0)
            s1 := calldataload(32)
            s2 := calldataload(64)
            s3 := shl(59, size)
        }

        // The initial linear layer reduces the first block.
        (s0, s1, s2, s3) = Poseidon2PermX.permute(s0, s1, s2, s3);

        uint256 c0;
        uint256 c1;
        uint256 c2;
        uint256 offset = 96;
        while (offset < size) {
            assembly ("memory-safe") {
                c0 := calldataload(offset)
                c1 := calldataload(add(offset, 32))
                c2 := calldataload(add(offset, 64))
            }
            (s0, s1, s2, s3) = Poseidon2PermX.permute(addmod(s0, c0, P), addmod(s1, c1, P), addmod(s2, c2, P), s3);
            unchecked {
                offset += 96;
            }
        }

        assembly ("memory-safe") {
            mstore(0, s0)
            return(0, 32)
        }
    }
}
