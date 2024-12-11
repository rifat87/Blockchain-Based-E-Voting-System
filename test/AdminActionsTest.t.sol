// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/AdminActions.sol";
import "../src/VoterRegistry.sol";

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
}
