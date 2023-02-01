// SPDX-License-Identifier: BUSL-1.1
pragma solidity = 0.8.17;

import "../fvm/Types.sol";
import "../beneficiary/Beneficiary.sol";
import "../utils/Uint2Str.sol";

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

    function init(_Miner storage miner, uint64 minerId) internal {
        miner.minerId = minerId;
        miner.windowPoStProofType = FvmTypes.RegisteredPoStProof.StackedDRGWindow32GiBV1;
        miner.exist = true;
    }

    function initializeInfo(_Miner storage miner) internal {
        require(miner.exist, "Invalid miner");

        // TODO: get miner power
        PowerTypes.MinerRawPowerReturn memory ret = PowerAPI.minerRawPower(miner.minerId);
        emit RawPowerReturn(ret);
    }

    function setFeeBeneficiaries(
        _Miner storage miner,
        Beneficiary.FeeBeneficiary[] memory beneficiaries
    ) internal {
        require(miner.exist, "Invalid miner");

        for (uint i = 0; i < beneficiaries.length; i++) {
            Beneficiary.FeeBeneficiary memory beneficiary = beneficiaries[i];
            miner.feeBeneficiaries[beneficiary.beneficiary].beneficiary = beneficiary.beneficiary;
            miner.feeBeneficiaries[beneficiary.beneficiary].percent = beneficiary.percent;
            miner.feeAddresses.push(beneficiary.beneficiary);
        }
    }

    function setRewardBeneficiaries(
        _Miner storage miner,
        Beneficiary.RewardBeneficiary[] memory beneficiaries
    ) internal {
        require(miner.exist, "Invalid miner");

        for (uint i = 0; i < beneficiaries.length; i++) {
            Beneficiary.RewardBeneficiary memory beneficiary = beneficiaries[i];
            miner.rewardBeneficiaries[beneficiary.beneficiary].beneficiary = beneficiary.beneficiary;
            miner.rewardBeneficiaries[beneficiary.beneficiary].amount = beneficiary.amount;
            miner.rewardAddresses.push(beneficiary.beneficiary);
        }
    }

    function toString(_Miner storage miner) internal view returns (string memory) {
        require(miner.exist, "Invalid miner");

        string memory feeBeneficiary = "[";
        for (uint32 i = 0; i < miner.feeAddresses.length; i++) {
            Beneficiary.FeeBeneficiary memory value = miner.feeBeneficiaries[miner.feeAddresses[i]];

            feeBeneficiary = string(bytes.concat(bytes(feeBeneficiary), bytes("{\"Address\":\"")));
            feeBeneficiary = string(bytes.concat(bytes(feeBeneficiary), abi.encode(value.beneficiary)));

            feeBeneficiary = string(bytes.concat(bytes(feeBeneficiary), bytes("\",\"Percent\":")));
            feeBeneficiary = string(bytes.concat(bytes(feeBeneficiary), bytes(Uint2Str.toString(value.percent))));

            feeBeneficiary = string(bytes.concat(bytes(feeBeneficiary), bytes("}")));
        }
        feeBeneficiary = string(bytes.concat(bytes(feeBeneficiary), bytes("]")));

        string memory rewardBeneficiary = "[";
        for (uint32 i = 0; i < miner.rewardAddresses.length; i++) {
            Beneficiary.RewardBeneficiary memory value = miner.rewardBeneficiaries[miner.rewardAddresses[i]];

            rewardBeneficiary = string(bytes.concat(bytes(rewardBeneficiary), bytes("{\"Address\":\"")));
            rewardBeneficiary = string(bytes.concat(bytes(rewardBeneficiary), abi.encode(value.beneficiary)));

            rewardBeneficiary = string(bytes.concat(bytes(rewardBeneficiary), bytes("\",\"Amount\":\"")));
            rewardBeneficiary = string(bytes.concat(bytes(rewardBeneficiary), bytes(Uint2Str.toString(value.amount))));

            rewardBeneficiary = string(bytes.concat(bytes(rewardBeneficiary), bytes("\"}")));
        }
        rewardBeneficiary = string(bytes.concat(bytes(rewardBeneficiary), bytes("]")));

        string memory minerStr = "{";

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\"MinerID\":\"t0")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(Uint2Str.toString(miner.minerId))));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"WindowPoStProofType\":\"")));
        if (miner.windowPoStProofType == FvmTypes.RegisteredPoStProof.StackedDRGWindow32GiBV1) {
            minerStr = string(bytes.concat(bytes(minerStr), bytes("StackedDRGWindow32GiBV1")));
        } else if (miner.windowPoStProofType == FvmTypes.RegisteredPoStProof.StackedDRGWindow64GiBV1) {
            minerStr = string(bytes.concat(bytes(minerStr), bytes("StackedDRGWindow64GiBV1")));
        } else {
            revert("Invalid window post proof type");
        }

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"InitialCollateral\":\"")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(Uint2Str.toString(miner.initialCollateral))));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"InitialVesting\":\"")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(Uint2Str.toString(miner.initialVesting))));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"InitialAvailable\":\"")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(Uint2Str.toString(miner.initialAvailable))));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"InitialCollateral\":\"")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(Uint2Str.toString(miner.initialRawPower))));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"InitialAdjPower\":\"")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(Uint2Str.toString(miner.initialAdjPower))));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"FeeBeneficiaries\":\"")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(feeBeneficiary)));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"RewardBeneficiaries\":\"")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(rewardBeneficiary)));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\"}")));

        return minerStr;
    }
}
