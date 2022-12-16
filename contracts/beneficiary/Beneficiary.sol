// SPDX-License-Identifier: BUSL-1.1
pragma solidity = 0.8.17;

/// @title Beneficiary definition
library Beneficiary {
    /// @title Beneficiary caculated by percent definition
    /// @author web3eye.io
    struct PercentBeneficiary {
        address beneficiary;
        uint32 percent;
    }

    /// @title Beneficiary caculated by deposited amount definition
    /// @author web3eye.io
    struct AmountBeneficiary {
        address beneficiary;
        uint256 amount;
    }
}
