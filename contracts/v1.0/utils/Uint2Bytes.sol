// SPDX-License-Identifier: BUSL-1.1
pragma solidity = 0.8.17;

library Uint2Bytes {
    function toBytes(uint _num) public pure returns (bytes memory _ret) {
      assembly {
        _ret := mload(0x10)
        mstore(_ret, 0x20)
        mstore(add(_ret, 0x20), _num)
        }
    }
}