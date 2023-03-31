// SPDX-License-Identifier: BUSL-1.1
pragma solidity = 0.8.17;

import "../fvm/Types.sol";
import "../beneficiary/Beneficiary.sol";
import "../utils/Uint2Str.sol";
import "../utils/Bytes2Uint.sol";

import "https://github.com/Zondax/filecoin-solidity/blob/master/contracts/v0.8/MinerAPI.sol";
import "https://github.com/Zondax/filecoin-solidity/blob/master/contracts/v0.8/types/MinerTypes.sol";
import "https://github.com/Zondax/filecoin-solidity/blob/master/contracts/v0.8/PowerAPI.sol";
import "https://github.com/Zondax/filecoin-solidity/blob/master/contracts/v0.8/types/PowerTypes.sol";
import "https://github.com/Zondax/filecoin-solidity/blob/master/contracts/v0.8/types/CommonTypes.sol";
import "https://github.com/Zondax/filecoin-solidity/blob/master/contracts/v0.8/utils/FilAddresses.sol";
import "https://github.com/Zondax/filecoin-solidity/blob/master/contracts/v0.8/utils/BigInts.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";

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

        // TODO: this two should be got from miner but we cannot get it now
        uint64 worker;
        uint64 postControl;

        uint256 vestingAmount;
        CommonTypes.ChainEpoch vestingEndEpoch;

        bool exist;
    }

    function init(_Miner storage miner, uint64 minerId) public {
        miner.minerId = minerId;
        miner.windowPoStProofType = FvmTypes.RegisteredPoStProof.StackedDRGWindow32GiBV1;
        miner.exist = false;
    }

    function initializeInfo(_Miner storage miner) public {
        CommonTypes.FilActorId actorId = CommonTypes.FilActorId.wrap(miner.minerId);
        CommonTypes.BigInt memory ret1 = MinerAPI.getAvailableBalance(actorId);
        uint256 initialAvailable = Bytes2Uint.toUint256(ret1.val);
        if (ret1.neg) {
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
    ) public {
        for (uint i = 0; i < beneficiaries.length; i++) {
            Beneficiary.Percent memory beneficiary = beneficiaries[i];
            require(beneficiary.percent < 100 && beneficiary.percent > 0, "Miner: invalid percent");
            miner.percentBeneficiaries[beneficiary.beneficiary].beneficiary = beneficiary.beneficiary;
            miner.percentBeneficiaries[beneficiary.beneficiary].percent = beneficiary.percent;
            miner.percentBeneficiaries[beneficiary.beneficiary].staking = beneficiary.staking;
            miner.percentBeneficiaryAddresses.push(beneficiary.beneficiary);
        }
    }

    function setPercentBeneficiary(
        _Miner storage miner,
        Beneficiary.Percent memory beneficiary
    ) public {
        Beneficiary.Percent memory oldBeneficiary = miner.percentBeneficiaries[beneficiary.beneficiary];
        require(beneficiary.percent <= 100, "Miner: invalid percent");

        bool exist = false;

        for (uint i = 0; i < miner.percentBeneficiaryAddresses.length; i++) {
            address _beneficiary = miner.percentBeneficiaryAddresses[i];
            if (_beneficiary == beneficiary.beneficiary) {
                exist = true;
                continue;
            }
            miner.percentBeneficiaries[_beneficiary].percent *= (100 - beneficiary.percent);
            miner.percentBeneficiaries[_beneficiary].percent /= (100 - oldBeneficiary.percent);
        }

        miner.percentBeneficiaries[beneficiary.beneficiary].beneficiary = beneficiary.beneficiary;
        miner.percentBeneficiaries[beneficiary.beneficiary].percent = beneficiary.percent;
        miner.percentBeneficiaries[beneficiary.beneficiary].staking = beneficiary.staking;

        if (!exist) {
            miner.percentBeneficiaryAddresses.push(beneficiary.beneficiary);
        }
    }

    function custody(_Miner storage miner) public {
        CommonTypes.FilActorId actorId = CommonTypes.FilActorId.wrap(miner.minerId);
        MinerTypes.GetOwnerReturn memory ret1 = MinerAPI.getOwner(actorId);
        miner.custodyOwner = uint64(Bytes2Uint.toUint256(ret1.owner.data));
        MinerAPI.changeOwnerAddress(actorId, ret1.proposed);
    }

    function escape(_Miner storage miner, uint64 newOwner) public {
        CommonTypes.FilActorId actorId = CommonTypes.FilActorId.wrap(miner.minerId);
        CommonTypes.FilAddress memory addr = FilAddresses.fromActorID(newOwner);
        MinerAPI.changeOwnerAddress(actorId, addr);
    }

    function withdraw(_Miner storage miner) public returns (uint256) {
        CommonTypes.FilActorId actorId = CommonTypes.FilActorId.wrap(miner.minerId);
        CommonTypes.BigInt memory balance = MinerAPI.getAvailableBalance(actorId);
        MinerAPI.withdrawBalance(actorId, balance);

        uint256 lastVestingAmount = miner.vestingAmount;

        MinerTypes.GetVestingFundsReturn memory vestings = MinerAPI.getVestingFunds(actorId);
        if (vestings.vesting_funds.length == 0) {
            miner.vestingAmount = 0;
            miner.vestingEndEpoch = CommonTypes.ChainEpoch.wrap(0);
            return lastVestingAmount;
        }

        miner.vestingAmount = 0;
        uint256 lastVestingEndAmount = 0;
        CommonTypes.ChainEpoch lastVestingEndEpoch = miner.vestingEndEpoch;

        for (uint32 i = 0; i < vestings.vesting_funds.length; i++) {
            MinerTypes.VestingFunds memory vesting = vestings.vesting_funds[i];
            (uint256 _amount, bool _converted) = BigInts.toUint256(vesting.amount);
            require(_converted, "Miner: cannot convert amount to uint256");
            miner.vestingAmount += _amount;
            miner.vestingEndEpoch = vesting.epoch;
            if (CommonTypes.ChainEpoch.unwrap(vesting.epoch) <= CommonTypes.ChainEpoch.unwrap(lastVestingEndEpoch)) {
                lastVestingEndAmount += _amount;
            }
        }

        return lastVestingAmount - lastVestingEndAmount;
    }

    function withdrawReward(_Miner storage miner, address beneficiary, uint256 amount) public {
        miner.percentBeneficiaries[beneficiary].balance -= amount;
    }

    function redeem(_Miner storage miner, address beneficiary, uint256 amount) public {
        miner.percentBeneficiaries[beneficiary].staking -= amount;
    }

    function accounting(_Miner storage miner, uint256 amount) public {
        for (uint32 i = 0; i < miner.percentBeneficiaryAddresses.length; i++) {
            Beneficiary.Percent memory beneficiary = miner.percentBeneficiaries[miner.percentBeneficiaryAddresses[i]];
            miner.percentBeneficiaries[miner.percentBeneficiaryAddresses[i]].balance += amount * beneficiary.percent;
        }
    }

    function balanceOfReward(_Miner storage miner) public view returns (uint256) {
        uint256 amount = 0;
        for (uint32 i = 0; i < miner.percentBeneficiaryAddresses.length; i++) {
            amount += miner.percentBeneficiaries[miner.percentBeneficiaryAddresses[i]].balance;
        }
        return amount;
    }

    function balanceOfBeneficiary(_Miner storage miner, address beneficiary) public view returns (uint256) {
        return miner.percentBeneficiaries[beneficiary].balance;
    }

    function stakingOfBeneficiary(_Miner storage miner, address beneficiary) public view returns (uint256) {
        return miner.percentBeneficiaries[beneficiary].staking;
    }

    function setWorker(_Miner storage miner, uint64 newWorkerActorId) public {
        miner.worker = newWorkerActorId;
    }

    function _worker(_Miner storage miner) public view returns (uint64) {
        return miner.worker;
    }

    function setPoStControl(_Miner storage miner, uint64 newControlActorId) public {
        miner.postControl = newControlActorId;
    }

    function _postControl(_Miner storage miner) public view returns (uint64) {
        return miner.postControl;
    }

    function toString(_Miner storage miner) public view returns (string memory) {
        string memory percentBeneficiary = "[";
        for (uint32 i = 0; i < miner.percentBeneficiaryAddresses.length; i++) {
            Beneficiary.Percent memory value = miner.percentBeneficiaries[miner.percentBeneficiaryAddresses[i]];

            if (i > 0) {
                percentBeneficiary = string(bytes.concat(bytes(percentBeneficiary), bytes(",")));
            }

            percentBeneficiary = string(bytes.concat(bytes(percentBeneficiary), bytes("{\"Address\":\"")));
            percentBeneficiary = string(bytes.concat(bytes(percentBeneficiary), bytes(Strings.toHexString(uint256(uint160(value.beneficiary)), 20))));

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

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"Worker\":\"t0")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(Uint2Str.toString(uint256(miner.worker)))));

        minerStr = string(bytes.concat(bytes(minerStr), bytes("\",\"PostControl\":\"t0")));
        minerStr = string(bytes.concat(bytes(minerStr), bytes(Uint2Str.toString(uint256(miner.postControl)))));

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
