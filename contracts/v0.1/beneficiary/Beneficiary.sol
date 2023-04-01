// SPDX-License-Identifier: BUSL-1.1
pragma solidity = 0.8.17;

/// @title Beneficiary definition
library Beneficiary {
    /// @title Beneficiary caculated by percent definition
    /// @author web3eye.io
    struct Percent {
        address beneficiary;
        uint16 percent;
        uint256 balance;
        uint256 staking;
    }
}
