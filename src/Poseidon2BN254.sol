// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Poseidon2PermX} from "./Poseidon2PermX.sol";

/// @title Poseidon2 BN254 hash
/// @notice Fixed-length sponge over the BN254 scalar field.
library Poseidon2BN254 {
    /// BN254 scalar-field modulus.
    uint256 internal constant P = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;

    /// @notice Fixed-length hash; IV = inputs.length << 64.
    function hash(uint256[] memory inputs) internal pure returns (uint256 s0) {
        uint256 n = inputs.length;
        uint256 s1;
        uint256 s2;
        uint256 s3 = n << 64;

        if (n <= 3) {
            uint256 c0;
            uint256 c1;
            uint256 c2;
            if (n != 0) c0 = inputs[0];
            if (n > 1) c1 = inputs[1];
            if (n > 2) c2 = inputs[2];
            (s0,,,) = Poseidon2PermX.permute(c0, c1, c2, s3);
            return s0;
        }

        // The initial layer reduces the first block.
        (s0, s1, s2, s3) = Poseidon2PermX.permute(inputs[0], inputs[1], inputs[2], s3);
        uint256 i = 3;
        if (n > 5) {
            uint256 end = n - 2;
            while (i < end) {
                (s0, s1, s2, s3) = Poseidon2PermX.permute(
                    addmod(s0, inputs[i], P), addmod(s1, inputs[i + 1], P), addmod(s2, inputs[i + 2], P), s3
                );
                unchecked {
                    i += 3;
                }
            }
        }

        if (i < n) {
            uint256 c0 = inputs[i];
            uint256 c1;
            unchecked {
                if (i + 1 < n) c1 = inputs[i + 1];
            }
            (s0,,,) = Poseidon2PermX.permute(addmod(s0, c0, P), addmod(s1, c1, P), s2, s3);
        }
    }

    /// @notice Two-input hash equivalent to `hash([a, b])` without array allocation.
    function hash2(uint256 a, uint256 b) internal pure returns (uint256 s0) {
        // The initial layer reduces the inputs.
        (s0,,,) = Poseidon2PermX.permute(a, b, 0, 2 << 64);
    }
}
