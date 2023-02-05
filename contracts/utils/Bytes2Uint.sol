// SPDX-License-Identifier: BUSL-1.1
pragma solidity = 0.8.17;

library Bytes2Uint {
    /* @notice      Convert bytes to uint256
    *  @param _b    Source bytes should have length of 32
    *  @return      uint256
    */
    function toUint256(bytes memory _bs) internal pure returns (uint256 value) {
        require(_bs.length == 32, "bytes length is not 32.");
        assembly {
            // load 32 bytes from memory starting from position _bs + 32
            value := mload(add(_bs, 0x20))
        }
        require(value <= 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, "Value exceeds the range");
    }
}