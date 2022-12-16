// SPDX-License-Identifier: BUSL-1.1
pragma solidity = 0.8.17;

import './beneficiary/Beneficiary.sol';
import './miner/Miner.sol';

/// @title FEVM Owner actor
/// @notice Owner actor implementation of Filecoin miner
contract OwnerActor {
    address public creator;

    constructor() {
        creator = msg.sender;
    }

    /// @notice Change Owner of specific miner to this running contract with initial condition
    function custodyMiner(
        address minerId,
        bytes memory powerActorState,
        Beneficiary.PercentBeneficiary[] memory percentBeneficiaries,
        Beneficiary.AmountBeneficiary[] memory amountBeneficiaries
    ) public returns (address) {
        Miner.fromId(minerId);
        Miner.initializeInfo(minerId, powerActorState);
        Miner.setPercentBeneficiaries(minerId, percentBeneficiaries);
        Miner.setAmountBeneficiaries(minerId, amountBeneficiaries);
        return minerId;
    }
}
