// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAdminActions {
    function addVoteToCandidate(uint _nid) external;
}

contract VoterRegistry {
    uint256 public voteCount = 0;
    // Struct to store voter details
    struct Voter {
        bytes32 fingerprintHash; // Hash of the fingerprint
        bool hasVoted;           // Voting status
    }

    // State variables
    address public admin;          // Admin who deploys the contract
    mapping(bytes32 => Voter) public voters; // Mapping of fingerprint hashes to voter data

    address public adminActionsContract; // Address of AdminActions contract

    // Custom errors for better gas efficiency
    error OnlyAdmin();
    error VoterNotRegistered();
    error VoterAlreadyRegistered();
    error VoterAlreadyVoted();

    // Events for logging
    event VoterRegistered(bytes32 indexed fingerprintHash);
    event VoterVoted(bytes32 indexed fingerprintHash);

    // Constructor: Sets the deployer as the admin
    constructor(address _adminActionsContract) {
        admin = msg.sender;
        adminActionsContract = _adminActionsContract;
    }

    /**
     * @dev Registers a new voter.
     * @param fingerprintHash The hash of the voter's fingerprint.
     */
    function registerVoter(bytes32 fingerprintHash) external {
        // Only admin can register voters
        if (msg.sender != admin) {
            revert OnlyAdmin();
        }

        // Ensure the voter is not already registered
        if (voters[fingerprintHash].fingerprintHash != 0) {
            revert VoterAlreadyRegistered();
        }

        // Register the voter
        voters[fingerprintHash] = Voter(fingerprintHash, false);

        // Emit event
        emit VoterRegistered(fingerprintHash);
    }

    /**
     * @dev Marks a voter as having voted after fingerprint verification.
     * @param fingerprintHash The hash of the voter's fingerprint.
     * @param candidateNid The NID of the candidate being voted for.
     */
    function markAsVoted(bytes32 fingerprintHash, uint candidateNid) external {
        // Verify voter registration
        Voter storage voter = voters[fingerprintHash];

        // Check if the voter is registered
        if (voter.fingerprintHash == 0) {
            revert VoterNotRegistered();
        }

        // Check if the voter has already voted
        if (voter.hasVoted) {
            revert VoterAlreadyVoted();
        }

        // Mark the voter as having voted
        voter.hasVoted = true;
        voteCount += 1;

        // Add vote to the candidate in AdminActions
        IAdminActions(adminActionsContract).addVoteToCandidate(candidateNid);

        // Emit the event to log the voting action
        emit VoterVoted(fingerprintHash);
    }

    /**
     * @dev Returns whether a fingerprint has voted.
     * @param fingerprintHash The hash of the voter's fingerprint.
     * @return bool indicating if the voter has voted.
     */
    function hasVoted(bytes32 fingerprintHash) external view returns (bool) {
        return voters[fingerprintHash].hasVoted;
    }
}
