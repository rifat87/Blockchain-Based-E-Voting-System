// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import { AdminActions } from "../src/AdminActions.sol";
import { VoterRegistry } from "../src/VoterRegistry.sol";

contract VoterRegistryTest is Test {
    VoterRegistry public voterRegistry;
    AdminActions public adminActions;
    address deployer = address(1);

    address admin = address(1);
    address nonAdmin = address(2);

    // Sample fingerprint hash and NID
    bytes32 fingerprintHash = keccak256("fingerprint123");
    uint candidateNid = 12345;

    function setUp() public {
        // Label the deployer for easier debugging
        vm.label(deployer, "Deployer");

        // Assign deployer account some ETH for testing
        vm.deal(deployer, 1 ether);

        // Deploy AdminActions with deployer as admin
        vm.startPrank(deployer);
        adminActions = new AdminActions(deployer); // Admin is set via constructor

        // Deploy VoterRegistry with the AdminActions contract's address
        voterRegistry = new VoterRegistry(address(adminActions));

        // Set the voter registry in AdminActions
        adminActions.setVoterRegistry(address(voterRegistry));
        vm.stopPrank();
    }

    // Test if only the admin can register a voter
    function testOnlyAdminCanRegisterVoter() public {
        vm.prank(admin);
        voterRegistry.registerVoter(fingerprintHash);

        // Test if registration was successful
        assertTrue(voterRegistry.hasVoted(fingerprintHash) == false);

        vm.prank(nonAdmin);
        vm.expectRevert(VoterRegistry.OnlyAdmin.selector);
        voterRegistry.registerVoter(fingerprintHash);
    }

    // Test if voter registration works correctly
    function testVoterRegistration() public {
        vm.prank(admin);
        voterRegistry.registerVoter(fingerprintHash);

        // Ensure voter is registered
        assertTrue(voterRegistry.hasVoted(fingerprintHash) == false);
    }

    // Test if voter can vote after registration
    function testVoterCanVote() public {
        vm.prank(admin);
        voterRegistry.registerVoter(fingerprintHash);

        // Mark the voter as voted
        vm.prank(admin);
        voterRegistry.markAsVoted(fingerprintHash, candidateNid);

        // Check if the voter has voted
        assertTrue(voterRegistry.hasVoted(fingerprintHash) == true);
    }

    // Test if an error is thrown when voting again
    function testCannotVoteTwice() public {
        vm.prank(admin);
        voterRegistry.registerVoter(fingerprintHash);

        // First vote should succeed
        voterRegistry.markAsVoted(fingerprintHash, candidateNid);

        // Second vote should fail
        vm.expectRevert(VoterRegistry.VoterAlreadyVoted.selector);
        voterRegistry.markAsVoted(fingerprintHash, candidateNid);
    }
}
