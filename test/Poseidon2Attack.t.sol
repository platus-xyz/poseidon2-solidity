// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test} from "forge-std/Test.sol";
import {Poseidon2BN254} from "contracts/Poseidon2BN254.sol";
import {Poseidon2} from "contracts/Poseidon2.sol";

/// @notice Domain, malleability, and fallback tests.
contract Poseidon2AttackTest is Test {
    uint256 internal constant P = Poseidon2BN254.P;
    Poseidon2 internal poseidon;

    function setUp() public {
        poseidon = new Poseidon2();
    }

    function testFuzz_outputInField(uint256 x, uint256 y, uint256 z) public pure {
        uint256[] memory a = new uint256[](3);
        a[0] = x; a[1] = y; a[2] = z;
        assertLt(Poseidon2BN254.hash(a), P);
    }

    function test_malleability_inputModP() public pure {
        uint256[] memory a = new uint256[](1);
        a[0] = 5;
        uint256[] memory b = new uint256[](1);
        b[0] = 5 + P; // < 2^256.
        assertEq(Poseidon2BN254.hash(a), Poseidon2BN254.hash(b));
    }

    function test_fallback_rejectsSelectorTypedCall() public {
        bytes memory cd = abi.encodeWithSignature("hash(uint256[])", new uint256[](1));
        (bool ok, ) = address(poseidon).staticcall(cd);
        assertFalse(ok, "selector-typed call should revert (len % 32 != 0)");
    }

    function test_fallback_emptyCalldataReturnsEmptyHash() public view {
        (bool ok, bytes memory ret) = address(poseidon).staticcall("");
        assertTrue(ok);
        uint256 got = abi.decode(ret, (uint256));
        uint256[] memory empty = new uint256[](0);
        assertEq(got, Poseidon2BN254.hash(empty));
    }

    function test_fallback_packedMatchesLibrary() public view {
        uint256[] memory a = new uint256[](2);
        a[0] = 111; a[1] = 222;
        (bool ok, bytes memory ret) = address(poseidon).staticcall(abi.encodePacked(a));
        assertTrue(ok);
        assertEq(abi.decode(ret, (uint256)), Poseidon2BN254.hash(a));
    }
}
