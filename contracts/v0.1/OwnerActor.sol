// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./controller/Controllable.sol";
import "./miner/Miner.sol";
import "./beneficiary/Beneficiary.sol";

// import "https://github.com/Zondax/filecoin-solidity/blob/v4.0.2/contracts/v0.8/PowerAPI.sol";
// import "https://github.com/Zondax/filecoin-solidity/blob/v4.0.2/contracts/v0.8/types/PowerTypes.sol";

// TODO: we cannot detect method 0 within runtime contract
//     so we have to let a genesis account to record the deposit
//     in that way we have to confirm the deposit action in a offline/centralized way
//     and if the genesis account is hacked, then everything is gg

/// @title FEVM Owner actor
/// @notice Owner actor implementation of Filecoin miner
contract OwnerActor is Controllable {
    Miner._Miner private _miner;

    constructor() {
    }

    /// @notice Specific function let invoker know this is a peggy contract
    function checkPeggy() public pure returns (string memory) {
        /// @notice For anyone who copy peggy smart contract and want to be compatible to official peggy, this flag must be same
        return "Peggy TZJCLSYW 09231006 .--././--./--./-.--/-/--../.---/-.-./.-../.../-.--/.--/-----/----./..---/...--/.----/-----/-----/-....";
    }

    function version() public pure returns (string memory) {
        return "v0.1.0";
    }

    /// @notice Get custodied miner
    function getMiner() public view returns (string memory) {
        require(_miner.exist, "Owner: there is no miner custodied");
        string memory minerStr = Miner.toString(_miner);
        return minerStr;
    }

    /// @notice Change Owner of specific miner to this running contract
    function custodyMiner(
        uint64 minerId,
        Beneficiary.Percent[] memory percentBeneficiaries
    ) public onlyController {
        require(!_miner.exist, "Owner: only allow to custody one miner");

        Miner.init(_miner, minerId);
        Miner.initializeInfo(_miner);

        Miner.setPercentBeneficiaries(_miner, percentBeneficiaries);

        uint256 totalAmount = _miner.initialCollateral;

        uint8 totalPercent = 0;
        for (uint i = 0; i < percentBeneficiaries.length; i++) {
            require(percentBeneficiaries[i].percent > 0 && percentBeneficiaries[i].percent <= 100, "Owner: invalid percent");
            totalPercent += percentBeneficiaries[i].percent;
        }

        if (totalAmount > 0) {
            require(totalPercent == 100, "Owner: invalid total percent");
        }

        Miner.custody(_miner);

        _miner.exist = true;
    }

    function escapeMiner(address newOwner) public onlyController {
        require(_miner.exist, "Owner: there is no miner custodied");
        require(newOwner != address(0), "Owner: new owner must set for the miner");
        Miner.escape(_miner, newOwner);
    }

    function accounting() public onlyController {
        require(_miner.exist, "Owner: there is no miner custodied");
        uint256 amount = Miner.withdraw(_miner);
        if (amount == 0) {
            return;
        }
        Miner.accounting(_miner, amount);
    }

    function setWorker(address newWorkerActorId) public onlyController {
        require(_miner.exist, "Owner: there is no miner custodied");
        require(newWorkerActorId != address(0), "Owner: invalid actor id");
        Miner.setWorker(_miner, newWorkerActorId);
    }

    function setPoStControl(address newControlActorId) public onlyController {
        require(_miner.exist, "Owner: there is no miner custodied");
        require(newControlActorId != address(0), "Owner: invalid actor id");
        Miner.setPoStControl(_miner, newControlActorId);
    }

    function withdraw(uint256 amount) public {
        address payable _to = payable(msg.sender);
        uint256 balance = Miner.balanceOfBeneficiary(_miner, _to);
        require(balance > amount, "Owner: insufficient funds - account");
        require(address(this).balance > amount, "Owner: insufficient funds - contract");
        _to.transfer(amount);
        Miner.withdrawReward(_miner, _to, amount);
    }

    function sendToWorker(uint256 amount) public onlyController {
        require(_miner.exist, "Owner: there is no miner custodied");
        address payable worker = payable(Miner._worker(_miner));
        require(worker != address(0), "Owner: invalid worker");
        require(address(this).balance > amount, "Owner: insufficient funds - contract");
        worker.transfer(amount);
    }

    function sendToPoStControl(uint256 amount) public onlyController {
        require(_miner.exist, "Owner: there is no miner custodied");
        address payable postControl = payable(Miner._postControl(_miner));
        require(postControl != address(0), "Owner: invalid PoSt control");
        require(address(this).balance > amount, "Owner: insufficient funds - contract");
        postControl.transfer(amount);
    }

    function setBeneficiary(
        Beneficiary.Percent memory percentBeneficiary
    ) public onlyController {
        require(_miner.exist, "Owner: there is no miner custodied");
        require(percentBeneficiary.percent < 100 && percentBeneficiary.percent > 0, "Owner: invalid percent");
        Miner.setPercentBeneficiary(_miner, percentBeneficiary);
    }
}