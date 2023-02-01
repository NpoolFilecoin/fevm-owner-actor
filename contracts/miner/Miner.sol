// SPDX-License-Identifier: BUSL-1.1
pragma solidity = 0.8.17;

import "../fvm/Types.sol";
import "../beneficiary/Beneficiary.sol";
// import "https://github.com/Zondax/filecoin-solidity/blob/v0.4.0-beta.1/contracts/v0.8/MinerAPI.sol";
// import "https://github.com/Zondax/filecoin-solidity/blob/v0.4.0-beta.1/contracts/v0.8/types/MinerTypes.sol";
import "https://github.com/Zondax/filecoin-solidity/blob/v0.4.0-beta.1/contracts/v0.8/PowerAPI.sol";
import "https://github.com/Zondax/filecoin-solidity/blob/v0.4.0-beta.1/contracts/v0.8/types/PowerTypes.sol";

library Miner {
    struct _Miner {
        uint64 minerId;
        FvmTypes.RegisteredPoStProof windowPoStProofType;
        uint256 initialCollateral;
        uint256 initialVesting;
        uint256 initialAvailable;
        uint256 initialRawPower;
        uint256 initialAdjPower;
        mapping(address => Beneficiary.FeeBeneficiary) feeBeneficiaries;
        address[] feeAddresses;
        mapping(address => Beneficiary.RewardBeneficiary) rewardBeneficiaries;
        address[] rewardAddresses;
        bool exist;
    }
    event RawPowerReturn(PowerTypes.MinerRawPowerReturn ret);

    struct Miners {
        mapping(uint64 => _Miner) miners;
    }

    function miners() internal pure returns (Miners storage ds) {
        bytes32 position = keccak256("fevm.owner.actor.miners.storage");
        assembly { ds.slot := position }
    }

    function fromId(uint64 minerId) internal {
        Miners storage ms = miners();
        require(ms.miners[minerId].exist, "Exist miner");

        ms.miners[minerId].minerId = minerId;
        ms.miners[minerId].windowPoStProofType = FvmTypes.RegisteredPoStProof.StackedDRGWindow32GiBV1;
        ms.miners[minerId].initialCollateral = 0;
        ms.miners[minerId].initialVesting = 0;
        ms.miners[minerId].initialAvailable = 0;
        ms.miners[minerId].initialRawPower = 0;
        ms.miners[minerId].initialAdjPower = 0;
        ms.miners[minerId].exist = true;
    }

    function initializeInfo(uint64 minerId) internal {
        Miners storage ms = miners();
        require(!ms.miners[minerId].exist, "Invalid miner");

        // TODO: get miner power
        PowerTypes.MinerRawPowerReturn memory ret = PowerAPI.minerRawPower(7824);
        emit RawPowerReturn(ret);
    }

    function setFeeBeneficiaries(
        uint64 minerId,
        Beneficiary.FeeBeneficiary[] memory beneficiaries
    ) internal {
        Miners storage ms = miners();
        require(!ms.miners[minerId].exist, "Invalid miner");

        for (uint i = 0; i < beneficiaries.length; i++) {
            Beneficiary.FeeBeneficiary memory beneficiary = beneficiaries[i];
            ms.miners[minerId].feeBeneficiaries[beneficiary.beneficiary].beneficiary = beneficiary.beneficiary;
            ms.miners[minerId].feeBeneficiaries[beneficiary.beneficiary].percent = beneficiary.percent;
            ms.miners[minerId].feeAddresses.push(beneficiary.beneficiary);
        }
    }

    function setRewardBeneficiaries(
        uint64 minerId,
        Beneficiary.RewardBeneficiary[] memory beneficiaries
    ) internal {
        Miners storage ms = miners();
        require(!ms.miners[minerId].exist, "Invalid miner");

        for (uint i = 0; i < beneficiaries.length; i++) {
            Beneficiary.RewardBeneficiary memory beneficiary = beneficiaries[i];
            ms.miners[minerId].rewardBeneficiaries[beneficiary.beneficiary].beneficiary = beneficiary.beneficiary;
            ms.miners[minerId].rewardBeneficiaries[beneficiary.beneficiary].amount = beneficiary.amount;
            ms.miners[minerId].rewardAddresses.push(beneficiary.beneficiary);
        }
    }

    function toString(uint64 minerId) internal view returns (string memory) {
        Miners storage ms = miners();
        require(!ms.miners[minerId].exist, "Invalid miner");

        string memory feeBeneficiary = "Fee Beneficiaries  ";
        for (uint32 i = 0; i < ms.miners[minerId].feeAddresses.length; i++) {
            Beneficiary.FeeBeneficiary memory value = ms.miners[minerId].feeBeneficiaries[ms.miners[minerId].feeAddresses[i]];
            feeBeneficiary = string(abi.encodePacked(feeBeneficiary, value.beneficiary, value.percent));
        }

        string memory rewardBeneficiary = "Reward Beneficiaries  ";
        for (uint32 i = 0; i < ms.miners[minerId].rewardAddresses.length; i++) {
            Beneficiary.RewardBeneficiary memory value = ms.miners[minerId].rewardBeneficiaries[ms.miners[minerId].rewardAddresses[i]];
            rewardBeneficiary = string(abi.encodePacked(rewardBeneficiary, value.beneficiary, value.amount));
        }

        return string(abi.encodePacked(
            ms.miners[minerId].minerId,
            ms.miners[minerId].windowPoStProofType,
            ms.miners[minerId].initialCollateral,
            ms.miners[minerId].initialVesting,
            ms.miners[minerId].initialAvailable,
            ms.miners[minerId].initialRawPower,
            ms.miners[minerId].initialAdjPower,
            feeBeneficiary,
            rewardBeneficiary
        ));
    }
}
