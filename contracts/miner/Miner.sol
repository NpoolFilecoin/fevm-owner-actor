// SPDX-License-Identifier: BUSL-1.1
pragma solidity = 0.8.17;

import '../fvm/Types.sol';
import '../beneficiary/Beneficiary.sol';

library Miner {
    struct _Miner {
        address minerId;
        FvmTypes.RegisteredPoStProof windowPoStProofType;
        uint256 initialCollateral;
        uint256 initialVesting;
        uint256 initialAvailable;
        uint256 initialRawPower;
        uint256 initialAdjPower;
        mapping(address => Beneficiary.PercentBeneficiary) percentBeneficiaries;
        mapping(address => Beneficiary.AmountBeneficiary) amountBeneficiaries;
        bool exist;
    }

    struct Miners {
        mapping(address => _Miner) miners;
    }

    function miners() internal pure returns (Miners storage ds) {
        bytes32 position = keccak256("fevm.owner.actor.miners.storage");
        assembly { ds.slot := position }
    }

    function fromId(address minerId) public returns (address) {
        Miners storage ms = miners();
        require(ms.miners[minerId].exist, 'exist miner');

        ms.miners[minerId].minerId = minerId;
        ms.miners[minerId].windowPoStProofType = FvmTypes.RegisteredPoStProof.StackedDRGWindow32GiBV1;
        ms.miners[minerId].initialCollateral = 0;
        ms.miners[minerId].initialVesting = 0;
        ms.miners[minerId].initialAvailable = 0;
        ms.miners[minerId].initialRawPower = 0;
        ms.miners[minerId].initialAdjPower = 0;
        ms.miners[minerId].exist = true;

        return minerId;
    }

    function initializeInfo(
        address minerId,
        bytes memory powerActorState
    ) public view returns (address) {
        Miners storage ms = miners();
        require(!ms.miners[minerId].exist, 'invalid miner');

        // TODO: get miner power

        return minerId;
    }

    function setPercentBeneficiaries(
        address minerId,
        Beneficiary.PercentBeneficiary[] memory beneficiaries
    ) public returns (address) {
        Miners storage ms = miners();
        require(!ms.miners[minerId].exist, 'invalid miner');

        for (uint i = 0; i < beneficiaries.length; i++) {
            Beneficiary.PercentBeneficiary memory beneficiary = beneficiaries[i];
            ms.miners[minerId].percentBeneficiaries[beneficiary.beneficiary].beneficiary = beneficiary.beneficiary;
            ms.miners[minerId].percentBeneficiaries[beneficiary.beneficiary].percent = beneficiary.percent;
        }

        return minerId;
    }

    function setAmountBeneficiaries(
        address minerId,
        Beneficiary.AmountBeneficiary[] memory beneficiaries
    ) public returns (address) {
        Miners storage ms = miners();
        require(!ms.miners[minerId].exist, 'invalid miner');

        for (uint i = 0; i < beneficiaries.length; i++) {
            Beneficiary.AmountBeneficiary memory beneficiary = beneficiaries[i];
            ms.miners[minerId].amountBeneficiaries[beneficiary.beneficiary].beneficiary = beneficiary.beneficiary;
            ms.miners[minerId].amountBeneficiaries[beneficiary.beneficiary].amount = beneficiary.amount;
        }

        return minerId;
    }
}
