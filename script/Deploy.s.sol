// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol"; // Forge standard library
import { VoterRegistry } from "../src/VoterRegistry.sol";
import { AdminActions } from "../src/AdminActions.sol";
import { HelperConfig } from "./HelperConfig.s.sol";

contract DeployVotingSystem is Script {
    address public adminActionsContract;
    address public voterRegistryContract;
    address public helperConfigContract;

    function run() external {
        address admin = msg.sender; // or a predefined address
        vm.startBroadcast(); // Begin broadcasting transactions

        // Deploy AdminActions contract
        AdminActions adminActions = new AdminActions(admin);
        adminActionsContract = address(adminActions);

        // Deploy HelperConfig (optional: add any additional parameters it requires)
        HelperConfig helperConfig = new HelperConfig(adminActionsContract);
        helperConfigContract = address(helperConfig);

        // Deploy VoterRegistry contract with the HelperConfig's address
        VoterRegistry voterRegistry = new VoterRegistry(adminActionsContract);
        voterRegistryContract = address(voterRegistry);

        // Set VoterRegistry in AdminActions contract
        adminActions.setVoterRegistry(voterRegistryContract);

        // Print the deployed contract addresses
        console.log("AdminActions contract deployed at:", adminActionsContract);
        console.log("VoterRegistry contract deployed at:", voterRegistryContract);
        console.log("HelperConfig contract deployed at:", helperConfigContract);

        vm.stopBroadcast(); // End broadcasting transactions
    }
}
