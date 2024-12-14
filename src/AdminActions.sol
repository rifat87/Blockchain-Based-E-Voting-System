// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract AdminActions {
    // Struct to store candidate details
    struct Candidate {
        string name;     // Candidate's name
        uint nid;        // Candidate's unique NID number
        uint votes;      // Total votes for the candidate
    }

    // Admin address
    address public admin;

    // Address of the VoterRegistry contract
    address public voterRegistryContract;

    // Mapping to store candidates by their ID
    mapping(uint => Candidate) public candidates;

    // Counter for the number of candidates
    uint public totalCandidates;

    // Custom errors
    error OnlyAdmin();
    error OnlyAdminOrVoterRegistry();
    error CandidateAlreadyExists();
    error InvalidAddress();
    error InvalidCandidateName();
    error InvalidCandidateNid(); // Newly added error
    error InvalidVoterRegistry();
    error CandidateNotFound();

    // Events
    event CandidateAdded(uint indexed nid, string name);
    event VoteAdded(uint indexed nid, string name, uint totalVotes);

    // Constructor
    // constructor() {
    //     admin = msg.sender; // Set the deployer as the admin
    // }

    constructor(address _admin) {
    admin = _admin;
}


    // Modifier to restrict access to admin only
    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert OnlyAdmin();
        }
        _;
    }
    function setAdmin(address _admin) external {
        require(admin == address(0), "Admin already set"); // Prevent setting admin again
        admin = _admin;
    }


    // Modifier to allow access to admin or VoterRegistry
    modifier onlyAdminOrVoterRegistry() {
        if (msg.sender != admin && msg.sender != voterRegistryContract) {
            revert OnlyAdminOrVoterRegistry();
        }
        _;
    }

    /**
     * @dev Sets the address of the VoterRegistry contract.
     * @param _voterRegistryContract The address of the VoterRegistry contract.
     */
    function setVoterRegistry(address _voterRegistryContract) external onlyAdmin {
        if (_voterRegistryContract == address(0) || _voterRegistryContract == voterRegistryContract) {
            revert InvalidAddress();
            revert InvalidVoterRegistry();
        }
        voterRegistryContract = _voterRegistryContract;
    }

    /**
     * @dev Adds a new candidate.
     * @param _nid The candidate's NID.
     * @param _name The candidate's name.
     */
    function addCandidate(uint _nid, string calldata _name) external onlyAdmin {
        if (_nid == 0) {
            revert InvalidCandidateNid(); // Validate that NID is non-zero
        }
        
        if (bytes(_name).length == 0) {
            revert InvalidCandidateName(); // Validate candidate name is not empty
        }
       
        // Ensure candidate doesn't already exist
        if (bytes(candidates[_nid].name).length != 0) {
            revert CandidateAlreadyExists();
        }

        // Add the candidate
        candidates[_nid] = Candidate(_name, _nid, 0);
        totalCandidates++;

        // Emit event
        emit CandidateAdded(_nid, _name);
    }

    /**
     * @dev Adds a vote to a candidate. Callable by admin or VoterRegistry.
     * @param _nid The candidate's NID.
     */
    function addVoteToCandidate(uint _nid) external onlyAdminOrVoterRegistry {
        if (voterRegistryContract == address(0)) {
        revert InvalidVoterRegistry();
        revert CandidateNotFound();
    }
        
        Candidate storage candidate = candidates[_nid];
        
        candidate.votes++;

        emit VoteAdded(_nid, candidate.name, candidate.votes);
    }

    /**
     * @dev Returns the details of a candidate by NID.
     * @param _nid The candidate's NID.
     * @return Candidate struct containing details.
     */
    function getCandidate(uint _nid) external view returns (Candidate memory) {
        return candidates[_nid];
    }
}
