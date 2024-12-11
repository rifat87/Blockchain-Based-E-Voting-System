// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol"; // Import Forge standard script library
import { VoterRegistry } from "../src/VoterRegistry.sol";
import { AdminActions } from "../src/AdminActions.sol";
import { HelperConfig } from "./HelperConfig.s.sol";

contract DeployHelpers is Script {
    address public adminActionsContract;
    address public voterRegistryContract;
    address public helperConfigContract;

    function run() external {
        // Get the deployer's private key from environment variables
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        // Derive the deployer address
        address deployer = vm.addr(deployerPrivateKey);

        // Start broadcasting transactions to the network
        vm.startBroadcast(deployerPrivateKey);

        // Deploy AdminActions contract with the deployer as admin
        AdminActions adminActions = new AdminActions(deployer);
        adminActionsContract = address(adminActions);

        // Deploy HelperConfig contract with the address of the AdminActions contract
        HelperConfig helperConfig = new HelperConfig(adminActionsContract);
        helperConfigContract = address(helperConfig);

        // Deploy VoterRegistry contract with the address of the AdminActions contract
        VoterRegistry voterRegistry = new VoterRegistry(adminActionsContract);
        voterRegistryContract = address(voterRegistry);

        // Set the VoterRegistry contract address in AdminActions
        adminActions.setVoterRegistry(voterRegistryContract);

        // Output the deployed contract addresses to the console
        console.log("AdminActions contract deployed at:", adminActionsContract);
        console.log("VoterRegistry contract deployed at:", voterRegistryContract);
        console.log("HelperConfig contract deployed at:", helperConfigContract);

        // Stop broadcasting the transactions after deployment
        vm.stopBroadcast();
    }
}
