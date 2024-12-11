// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract HelperConfig {
    // Define the address of the AdminActions contract
    address public adminActionsContract;

    constructor(address _adminActionsContract) {
        adminActionsContract = _adminActionsContract;
    }

    // Getter function to access the adminActionsContract
    function getAdminActionsContract() public view returns (address) {
        return adminActionsContract;
    }
}
