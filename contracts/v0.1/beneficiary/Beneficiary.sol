// SPDX-License-Identifier: BUSL-1.1
pragma solidity = 0.8.17;

/// @title Beneficiary definition
library Beneficiary {
    /// @title Beneficiary caculated by percent definition
    /// @author web3eye.io
    struct FeeBeneficiary {
        address beneficiary;
        uint8 percent;
    }

    /// @title Beneficiary caculated by deposited amount definition
    /// @author web3eye.io
    struct RewardBeneficiary {
        address beneficiary;
        uint256 amount;
    }
}
