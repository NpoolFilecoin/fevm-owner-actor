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

    /// @notice Specific function let invoker know this is a peggy contract
    function checkPeggy() public pure returns (string memory) {
        /// @notice For anyone who copy peggy smart contract and want to be compatible to official peggy, this flag must be same
        return "Peggy TZJCLSYW 09231006 .--.----.--....--..--";
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