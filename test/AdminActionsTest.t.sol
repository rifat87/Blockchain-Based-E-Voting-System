// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import { VoterRegistry } from "../src/VoterRegistry.sol";
import { AdminActions } from "../src/AdminActions.sol";

contract AdminActionsTest is Test {
    AdminActions public adminActions;
    VoterRegistry public voterRegistry;

    address admin = address(1);
    address nonAdmin = address(2);

    uint candidateNid = 12345;
    string candidateName = "Candidate 1";
    uint newCandidateNid = 67890; // New NID for the second candidate
    string newCandidateName = "Candidate 2";

    function setUp() public {
        // Deploy AdminActions contract with the test contract address as the admin
        adminActions = new AdminActions(address(this)); // Pass address(this) as admin

        // Deploy VoterRegistry contract and set its address in AdminActions
        voterRegistry = new VoterRegistry(address(adminActions));
        adminActions.setVoterRegistry(address(voterRegistry));

        // Add a candidate (ensure this is called by the admin)
        vm.prank(address(this)); // Ensure the caller is the admin
        adminActions.addCandidate(candidateNid, candidateName);
    }

    // Test if only the admin can add a candidate
    function testOnlyAdminCanAddCandidate() public {
        vm.prank(address(this)); // Ensure the caller is the admin
        adminActions.addCandidate(newCandidateNid, newCandidateName); // Add a different candidate with a new NID

        // Check if the first candidate exists
        AdminActions.Candidate memory candidate = adminActions.getCandidate(candidateNid);
        assertEq(candidate.name, candidateName, "Candidate name mismatch");
        assertEq(candidate.nid, candidateNid, "Candidate NID mismatch");
        assertEq(candidate.votes, 0, "Initial votes should be zero");

        // Check if the new candidate exists
        AdminActions.Candidate memory newCandidate = adminActions.getCandidate(newCandidateNid);
        assertEq(newCandidate.name, newCandidateName, "New Candidate name mismatch");
        assertEq(newCandidate.nid, newCandidateNid, "New Candidate NID mismatch");
        assertEq(newCandidate.votes, 0, "Initial votes should be zero");

        // Try adding the same candidate again and expect the revert
        vm.prank(nonAdmin); // Non-admin attempts to add a candidate
        vm.expectRevert(AdminActions.OnlyAdmin.selector);
        adminActions.addCandidate(candidateNid, "Duplicate Candidate");
    }

    // Test if only the admin or voterRegistry can add votes
    function testOnlyAdminOrVoterRegistryCanAddVote() public {
        vm.prank(address(this)); // Ensure the caller is the admin
        adminActions.addVoteToCandidate(candidateNid);

        // Check if votes are added
        AdminActions.Candidate memory candidate = adminActions.getCandidate(candidateNid);
        assertEq(candidate.votes, 1);

        vm.prank(nonAdmin); // Non-admin attempts to add vote
        vm.expectRevert(AdminActions.OnlyAdminOrVoterRegistry.selector);
        adminActions.addVoteToCandidate(candidateNid);
    }

    // Test setting voter registry address
    function testSetVoterRegistry() public {
        address newVoterRegistry = address(new VoterRegistry(address(adminActions)));
        adminActions.setVoterRegistry(newVoterRegistry);

        assertEq(adminActions.voterRegistryContract(), newVoterRegistry);
    }

    // Test candidate existence check
    function testCandidateExists() public {
        adminActions.addCandidate(100, "Candidate 100");

        AdminActions.Candidate memory candidate = adminActions.getCandidate(100);
        assertEq(candidate.name, "Candidate 100");
        assertEq(candidate.nid, 100);
        assertEq(candidate.votes, 0);
    }

    // Branch coverage tests

        // Test setting the admin with a valid address during initialization
    function testSetAdminDuringInitialization() public {
        AdminActions tempAdminActions = new AdminActions(address(this));
        assertEq(tempAdminActions.admin(), address(this), "Admin not set correctly during initialization");
    }

    // Test setting voter registry with a zero address
    function testSetVoterRegistryFailsWithZeroAddress() public {
        vm.expectRevert(AdminActions.InvalidAddress.selector);
        adminActions.setVoterRegistry(address(0));
    }

    // Test adding a candidate with an empty name
    function testAddCandidateFailsWithEmptyName() public {
        vm.expectRevert(AdminActions.InvalidCandidateName.selector);
        adminActions.addCandidate(45678, "");
    }

    // Test adding a candidate with zero NID
    function testAddCandidateFailsWithZeroNid() public {
        vm.expectRevert(AdminActions.InvalidCandidateNid.selector);
        adminActions.addCandidate(0, "Zero NID Candidate");
    }

    // Test adding a vote with a valid voterRegistry
    function testAddVoteViaVoterRegistry() public {
        // Set the VoterRegistry as the caller
        vm.prank(address(voterRegistry));
        adminActions.addVoteToCandidate(candidateNid);

        // Validate the vote count
        AdminActions.Candidate memory candidate = adminActions.getCandidate(candidateNid);
        assertEq(candidate.votes, 1, "Vote count mismatch after registry call");
    }

    // Test adding a vote fails for uninitialized voter registry
    function testAddVoteFailsWithoutVoterRegistry() public {
        AdminActions tempAdminActions = new AdminActions(address(this)); // New contract without voterRegistry

        vm.expectRevert(AdminActions.InvalidVoterRegistry.selector);
        tempAdminActions.addVoteToCandidate(candidateNid);
    }

    // Test adding a candidate after voterRegistry change
    function testAddCandidateAfterRegistryUpdate() public {
        // Deploy a new voterRegistry and set it
        VoterRegistry newRegistry = new VoterRegistry(address(adminActions));
        adminActions.setVoterRegistry(address(newRegistry));

        // Add a new candidate and validate
        uint updatedNid = 78901;
        string memory updatedName = "Updated Candidate";
        adminActions.addCandidate(updatedNid, updatedName);

        AdminActions.Candidate memory updatedCandidate = adminActions.getCandidate(updatedNid);
        assertEq(updatedCandidate.name, updatedName, "Candidate name mismatch after registry update");
        assertEq(updatedCandidate.nid, updatedNid, "Candidate NID mismatch after registry update");
        assertEq(updatedCandidate.votes, 0, "Initial votes should be zero after registry update");
    }

    // Test updating voterRegistry to the same address
    function testSetVoterRegistryWithSameAddress() public {
        // Attempt to set the same voterRegistry again
        vm.expectRevert(AdminActions.InvalidAddress.selector);
        adminActions.setVoterRegistry(address(voterRegistry));
    }

    // Test adding a vote to an uninitialized candidate
    // function testAddVoteFailsForUninitializedCandidate() public {
    //     uint uninitializedNid = 99999;

    //     vm.expectRevert(AdminActions.CandidateNotFound.selector);
    //     adminActions.addVoteToCandidate(uninitializedNid);
    // }
}
