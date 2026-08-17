// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test} from "forge-std/Test.sol";
import {Poseidon2} from "contracts/Poseidon2.sol";

contract Poseidon2GasMeter {
    function measure(address target, bytes calldata data) external view returns (uint256 used) {
        uint256 codeSize;
        assembly ("memory-safe") {
            codeSize := extcodesize(target)
        }
        require(codeSize != 0, "measurement target has no code");
        uint256 before = gasleft();
        (bool ok, bytes memory ret) = target.staticcall(data);
        used = before - gasleft();
        require(ok && ret.length == 32, "measurement call failed");
    }
}

contract Poseidon2BenchmarkTest is Test {
    Poseidon2 internal poseidon;
    Poseidon2GasMeter internal meter;

    function setUp() public {
        poseidon = new Poseidon2();
        meter = new Poseidon2GasMeter();
    }

    function _data(uint256 n) internal pure returns (bytes memory data) {
        data = new bytes(n * 32);
        for (uint256 i; i < n; ++i) {
            uint256 value = i + 1;
            assembly ("memory-safe") {
                mstore(add(add(data, 32), mul(i, 32)), value)
            }
        }
    }

    function test_benchmarkFallback() public {
        uint256[14] memory lengths = [uint256(0), 1, 2, 3, 4, 5, 6, 7, 9, 10, 12, 20, 32, 64];
        for (uint256 i; i < lengths.length; ++i) {
            bytes memory data = _data(lengths[i]);
            uint256 warm = meter.measure(address(poseidon), data);

            emit log_named_uint("length", lengths[i]);
            emit log_named_uint("warm gas", warm);
            emit log_named_uint("cold gas (inferred)", warm + 2500);
        }
    }
}
