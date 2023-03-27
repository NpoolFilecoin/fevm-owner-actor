// SPDX-License-Identifier: BUSL-1.1
pragma solidity = 0.8.17;

import "../fvm/Types.sol";
import "../beneficiary/Beneficiary.sol";
import "../utils/Uint2Str.sol";
import "../utils/Bytes2Uint.sol";
import "../controller/Controllable.sol";

import "https://github.com/Zondax/filecoin-solidity/blob/master/contracts/v0.8/MinerAPI.sol";
import "https://github.com/Zondax/filecoin-solidity/blob/master/contracts/v0.8/types/MinerTypes.sol";
import "https://github.com/Zondax/filecoin-solidity/blob/master/contracts/v0.8/PowerAPI.sol";
import "https://github.com/Zondax/filecoin-solidity/blob/master/contracts/v0.8/types/PowerTypes.sol";

// TODO: it's better to custody all control addresses to contract, but cannot currently
//     then operator who hold the control addresses may withdraw funds
//     or destroy the sectors. from point of economy they won't destroy the sectors
//     due to that will also hurt their benefit. but they still have motivation to withdraw the balance
//     which will be transferred for sealing from our contract

library Miner {
    struct _Miner {
        uint64 minerId;
        FvmTypes.RegisteredPoStProof windowPoStProofType;
        // TODO: we cannot get collateral currently
        uint256 initialCollateral;
        uint256 initialVesting;
        int256 initialAvailable;
        uint256 initialRawPower;
        // TODO: we cannot get adj power currently
        uint256 initialAdjPower;
        mapping(address => Beneficiary.Percent) percentBeneficiaries;
        address[] percentBeneficiaryAddresses;
        uint64 custodyOwner;
        bool exist;
    }

    function init(_Miner storage miner, uint64 minerId) internal onlyController {
        miner.minerId = minerId;
        miner.windowPoStProofType = FvmTypes.RegisteredPoStProof.StackedDRGWindow32GiBV1;
        miner.exist = false;
    }

    function initializeInfo(_Miner storage miner) internal onlyController {
        MinerTypes.GetAvailableBalanceReturn memory ret1 = MinerAPI.getAvailableBalance(miner.minerId);
        uint256 initialAvailable = Bytes2Uint.toUint256(ret1.available_balance.val);
        if (ret1.available_balance.neg) {
            miner.initialAvailable = int256(initialAvailable) * -1;
        } else {
            miner.initialAvailable = int256(initialAvailable);
        }

        /* TODO: commented due to this call is error
        MinerTypes.GetVestingFundsReturn memory ret2 = MinerAPI.getVestingFunds(miner.minerId);
        uint256 initialVesting = 0;
        for (uint32 i = 0; i < ret2.vesting_funds.length; i++) {
            initialVesting += Bytes2Uint.toUint256(ret2.vesting_funds[i].amount.val);
        }
        miner.initialVesting = initialVesting;
        */

        PowerTypes.MinerRawPowerReturn memory ret3 = PowerAPI.minerRawPower(miner.minerId);
        miner.initialRawPower = Bytes2Uint.toUint256(ret3.raw_byte_power.val);
    }

    function setPercentBeneficiaries(
        _Miner storage miner,
        Beneficiary.Percent[] memory beneficiaries
    ) internal onlyController {
        for (uint i = 0; i < beneficiaries.length; i++) {
            Beneficiary.Percent memory beneficiary = beneficiaries[i];
            miner.percentBeneficiaries[beneficiary.beneficiary].beneficiary = beneficiary.beneficiary;
            miner.percentBeneficiaries[beneficiary.beneficiary].percent = beneficiary.percent;
            miner.percentBeneficiaryAddresses.push(beneficiary.beneficiary);
        }
    }

    function custody(_Miner storage miner) internal onlyController {
        MinerTypes.GetOwnerReturn memory ret1 = MinerAPI.getOwner(miner.minerId);
        miner.custodyOwner = uint64(Bytes2Uint.toUint256(ret1.owner));
        MinerAPI.changeOwnerAddress(miner.minerId, ret1.proposed);
    }

    function toString(_Miner storage miner) internal view returns (string memory) {
        string memory percentBeneficiary = "[";
        for (uint32 i = 0; i < miner.feeAddresses.length; i++) {
            Beneficiary.Percent memory value = miner.PercentBeneficiaries[miner.feeAddresses[i]];

            if (i > 0) {
                percentBeneficiary = string(bytes.concat(bytes(percentBeneficiary), bytes(",")));
            }

            percentBeneficiary = string(bytes.concat(bytes(percentBeneficiary), bytes("{\"Address\":\"")));
            percentBeneficiary = string(bytes.concat(bytes(percentBeneficiary), abi.encode(value.beneficiary)));

            percentBeneficiary = string(bytes.concat(bytes(percentBeneficiary), bytes("\",\"Percent\":")));
            percentBeneficiary = string(bytes.concat(bytes(percentBeneficiary), bytes(Uint2Str.toString(value.percent))));

            percentBeneficiary = string(bytes.concat(bytes(percentBeneficiary), bytes("}")));
        }
        percentBeneficiary = string(bytes.concat(bytes(percentBeneficiary), bytes("]")));

        string memory minerStr = "{";

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\"MinerID\":\"t0")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(Uint2Str.toString(miner.minerId))));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"CustodyOwner\":\"")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(Uint2Str.toString(miner.custodyOwner))));

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
        minerStr = string(bytes.concat(bytes(minerStr), bytes(Uint2Str.toString(uint256(miner.initialAvailable)))));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"InitialCollateral\":\"")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(Uint2Str.toString(miner.initialRawPower))));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"InitialAdjPower\":\"")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(Uint2Str.toString(miner.initialAdjPower))));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"PercentBeneficiaries\":")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(percentBeneficiary)));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("}")));

        return minerStr;
    }
}
