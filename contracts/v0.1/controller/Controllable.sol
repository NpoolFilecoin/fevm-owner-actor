// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Controllable {
    mapping(address => bool) private _controllers;
    address[] private __controllers;
    uint8 private _controllers_count;
    mapping(address => uint8) private _addingControllers;
    mapping(address => uint8) private _deletingControllers;
    mapping(address => mapping(address => bool)) private _addingApprovers;
    mapping(address => mapping(address => bool)) private _deletingApprovers;
    mapping(address => address[]) private __addingApprovers;
    mapping(address => address[]) private __deletingApprovers;

    event ControllerAdded(address indexed proposer, address indexed controller);
    event ControllerDeleted(address indexed approver, address indexed controller);
    event ControllerConfirmed(address indexed controller);

    /**
     * @dev Initializes the contract setting the deployer as the initial controller.
     */
    constructor () {
        address msgSender = msg.sender;
        _controllers[msgSender] = true;
        __controllers.push(msgSender);
        _controllers_count += 1;
        emit ControllerAdded(msgSender, msgSender);
    }

    /**
     * @dev Returns the addresses of the current controllers.
     */
    function controllers() public view returns (address[] memory) {
        return __controllers;
    }

    /**
     * @dev Throws if called by any account other than the controllers.
     */
    modifier onlyController() {
        require(isController(), "Controllable: caller is not the controller");
        _;
    }

    /**
     * @dev Returns true if the caller is the current controllers.
     */
    function isController() public view returns (bool) {
        address msgSender = msg.sender;
        return _controllers[msgSender];
    }

    /**
     * @dev Propose to add a new controller
     */
    function addController(address controller) public onlyController {
        address msgSender = msg.sender;
        require(!_controllers[controller], "Controllable: address is already a controller");
        require(_deletingControllers[controller] == 0, "Controllable: address is deleting");
        require(!_addingApprovers[controller][msgSender], "Controllable: sender already approved");
        _addingControllers[msgSender] += 1;
        _addingApprovers[controller][msgSender] = true;
        __addingApprovers[controller].push(msgSender);
        emit ControllerAdded(msgSender, controller);
    }

    /**
     * @dev Propose to delete a new controller
     */
    function deleteController(address controller) public onlyController {
        address msgSender = msg.sender;
        require(_controllers[controller], "Controllable: address is not a controller");
        require(_addingControllers[controller] == 0, "Controllable: address is adding");
        require(_deletingControllers[controller] == 0, "Controllable: address is deleting");
        require(!_deletingApprovers[controller][msgSender], "Controllable: sender already approved");
        require(_controllers_count > 1, "Controllable: only one controller exist");
        _deletingControllers[controller] += 1;
        _deletingApprovers[controller][msgSender] = true;
        __deletingApprovers[controller].push(msgSender);
        if (_deletingControllers[controller] > _controllers_count * 2 / 3) {
            _controllers_count -= 1;
            _deletingControllers[controller] = 0;
            _controllers[controller] = false;

            for (uint8 i = 0; i < __deletingApprovers[controller].length; i++) {
                _deletingApprovers[controller][__deletingApprovers[controller][i]] = false;
            }
            for (uint8 i = 0; i < __deletingApprovers[controller].length; i++) {
                __deletingApprovers[controller].pop();
            }
        }
        emit ControllerDeleted(msgSender, controller);
    }

    /**
     * @dev Confirm to be a controller
     */
    function confirmController() public {
        address msgSender = msg.sender;
        require(!_controllers[msgSender], "Controllable: address is already a controller");
        require(_addingControllers[msgSender] > _controllers_count * 2 / 3, "Controllable: address is voting");
        require(_deletingControllers[msgSender] == 0, "Controllable: address is deleting");
        _controllers_count += 1;
        _addingControllers[msgSender] = 0;
        _controllers[msgSender] = true;
        __controllers.push(msgSender);
        for (uint8 i = 0; i < __addingApprovers[msgSender].length; i++) {
            _addingApprovers[msgSender][__addingApprovers[msgSender][i]] = false;
        }
        for (uint8 i = 0; i < __addingApprovers[msgSender].length; i++) {
            __addingApprovers[msgSender].pop();
        }
        emit ControllerConfirmed(msgSender);
    }
}