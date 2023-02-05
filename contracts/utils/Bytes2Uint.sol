// SPDX-License-Identifier: BUSL-1.1
pragma solidity = 0.8.17;

library Bytes2Uint {
    /* @notice      Convert bytes to uint256
    *  @param _b    Source bytes should have length of 32
    *  @return      uint256
    */
    function toUint256(bytes memory _bytes) internal pure returns (uint256) {
        uint256 number;
        for (uint i = 0; i < _bytes.length; i++) {
            number = number + uint(uint8(_bytes[i])) * (2 ** (8 * (_bytes.length - (i + 1))));
        }
        return number;
    }

    /* @notice      Convert bytes to uint256
    *  @param _b    Source bytes must have length of 32
    *  @return      uint256
    */
    function toUint256Opt(bytes memory _bytes) internal pure returns (uint256) {
        require(_bytes.length == 32, "toUint256_outOfBounds");
        uint256 tempUint;
        assembly {
            tempUint := mload(add(add(_bytes, 0x20), 0))
        }
        require(tempUint <= 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, "toUint256_outOfRange");

        return tempUint;
    }
}