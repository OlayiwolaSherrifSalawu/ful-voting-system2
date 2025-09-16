// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title FULVotingSystem
 * @dev Blockchain-based electoral voting system for Federal University Lokoja
 * @author Maduka Eustes Chimereze (SCI20CSC077)
 */
contract FULVotingSystem {
    
    // Structs
    struct Candidate {
        uint256 id;
        string name;
        string studentId;
        uint256 voteCount;
        bool exists;
    }
    
    struct Voter {
        string studentId;
        bool hasVoted;
        bool isRegistered;
        uint256 votedCandidateId;
    }
    
    struct Election {
        string title;
        string description;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        bool exists;
    }
    
    // State variables
    address public admin;
    uint256 public candidateCount;
    uint256 public voterCount;
    uint256 public totalVotes;
    bool public votingStarted;
    bool public votingEnded;
    
    // Mappings
    mapping(uint256 => Candidate) public candidates;
    mapping(string => Voter) public voters; // studentId => Voter
    mapping(address => string) public voterAddresses; // address => studentId
    mapping(string => bool) public registeredStudentIds;
    
    Election public currentElection;
    
    // Events
    event VoterRegistered(string studentId, address voterAddress);
    event CandidateAdded(uint256 candidateId, string name, string studentId);
    event VoteCast(string voterStudentId, uint256 candidateId);
    event ElectionStarted(string title, uint256 startTime);
    event ElectionEnded(uint256 endTime);
    event ElectionReset();
    
    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier votingActive() {
        require(votingStarted && !votingEnded, "Voting is not active");
        require(block.timestamp >= currentElection.startTime && 
                block.timestamp <= currentElection.endTime, "Election not in progress");
        _;
    }
    
    modifier votingNotStarted() {
        require(!votingStarted, "Voting has already started");
        _;
    }
    
    modifier validVoter(string memory studentId) {
        require(voters[studentId].isRegistered, "Voter not registered");
        require(!voters[studentId].hasVoted, "Voter has already voted");
        require(keccak256(bytes(voterAddresses[msg.sender])) == keccak256(bytes(studentId)), 
                "Sender address doesn't match registered student ID");
        _;
    }
    
    // Constructor
    constructor() {
        admin = msg.sender;
        candidateCount = 0;
        voterCount = 0;
        totalVotes = 0;
        votingStarted = false;
        votingEnded = false;
        
        // Initialize current election
        currentElection = Election({
            title: "Student Union Executive Elections 2024",
            description: "Election for Student Union President at Federal University Lokoja",
            startTime: 0,
            endTime: 0,
            isActive: false,
            exists: true
        });
    }
    
    /**
     * @dev Register a new voter (only admin)
     * @param studentId Student ID (e.g., SCI20CSC077)
     * @param voterAddress Ethereum address of the voter
     */
    function registerVoter(string memory studentId, address voterAddress) 
        public 
        onlyAdmin 
        votingNotStarted 
    {
        require(!registeredStudentIds[studentId], "Student ID already registered");
        require(bytes(voterAddresses[voterAddress]).length == 0, "Address already registered");
        require(bytes(studentId).length > 0, "Invalid student ID");
        
        voters[studentId] = Voter({
            studentId: studentId,
            hasVoted: false,
            isRegistered: true,
            votedCandidateId: 0
        });
        
        voterAddresses[voterAddress] = studentId;
        registeredStudentIds[studentId] = true;
        voterCount++;
        
        emit VoterRegistered(studentId, voterAddress);
    }
    
    /**
     * @dev Add a new candidate (only admin)
     * @param name Candidate's full name
     * @param studentId Candidate's student ID
     */
    function addCandidate(string memory name, string memory studentId) 
        public 
        onlyAdmin 
        votingNotStarted 
    {
        require(bytes(name).length > 0, "Candidate name cannot be empty");
        require(bytes(studentId).length > 0, "Student ID cannot be empty");
        
        candidateCount++;
        candidates[candidateCount] = Candidate({
            id: candidateCount,
            name: name,
            studentId: studentId,
            voteCount: 0,
            exists: true
        });
        
        emit CandidateAdded(candidateCount, name, studentId);
    }
    
    /**
     * @dev Start the election (only admin)
     * @param durationInMinutes Election duration in minutes
     */
    function startElection(uint256 durationInMinutes) public onlyAdmin votingNotStarted {
        require(candidateCount > 0, "No candidates registered");
        require(voterCount > 0, "No voters registered");
        require(durationInMinutes > 0, "Invalid duration");
        
        currentElection.startTime = block.timestamp;
        currentElection.endTime = block.timestamp + (durationInMinutes * 60);
        currentElection.isActive = true;
        
        votingStarted = true;
        votingEnded = false;
        
        emit ElectionStarted(currentElection.title, currentElection.startTime);
    }
    
    /**
     * @dev End the election (only admin)
     */
    function endElection() public onlyAdmin {
        require(votingStarted, "Voting hasn't started yet");
        require(!votingEnded, "Voting already ended");
        
        votingEnded = true;
        currentElection.isActive = false;
        currentElection.endTime = block.timestamp;
        
        emit ElectionEnded(block.timestamp);
    }
    
    /**
     * @dev Cast a vote
     * @param candidateId ID of the candidate to vote for
     * @param voterStudentId Student ID of the voter
     */
    function vote(uint256 candidateId, string memory voterStudentId) 
        public 
        votingActive 
        validVoter(voterStudentId)
    {
        require(candidates[candidateId].exists, "Invalid candidate");
        require(candidateId <= candidateCount && candidateId > 0, "Candidate does not exist");
        
        // Record the vote
        voters[voterStudentId].hasVoted = true;
        voters[voterStudentId].votedCandidateId = candidateId;
        candidates[candidateId].voteCount++;
        totalVotes++;
        
        emit VoteCast(voterStudentId, candidateId);
    }
    
    /**
     * @dev Get candidate information
     * @param candidateId ID of the candidate
     * @return id, name, studentId, voteCount
     */
    function getCandidate(uint256 candidateId) 
        public 
        view 
        returns (uint256, string memory, string memory, uint256) 
    {
        require(candidates[candidateId].exists, "Candidate does not exist");
        Candidate memory candidate = candidates[candidateId];
        return (candidate.id, candidate.name, candidate.studentId, candidate.voteCount);
    }
    
    /**
     * @dev Get all candidates (returns arrays)
     * @return Arrays of candidate data
     */
    function getAllCandidates() 
        public 
        view 
        returns (uint256[] memory, string[] memory, string[] memory, uint256[] memory) 
    {
        uint256[] memory ids = new uint256[](candidateCount);
        string[] memory names = new string[](candidateCount);
        string[] memory studentIds = new string[](candidateCount);
        uint256[] memory voteCounts = new uint256[](candidateCount);
        
        for (uint256 i = 1; i <= candidateCount; i++) {
            if (candidates[i].exists) {
                ids[i-1] = candidates[i].id;
                names[i-1] = candidates[i].name;
                studentIds[i-1] = candidates[i].studentId;
                voteCounts[i-1] = candidates[i].voteCount;
            }
        }
        
        return (ids, names, studentIds, voteCounts);
    }
    
    /**
     * @dev Get voter information
     * @param studentId Student ID of the voter
     * @return studentId, hasVoted, votedCandidateId
     */
    function getVoter(string memory studentId) 
        public 
        view 
        returns (string memory, bool, uint256) 
    {
        require(voters[studentId].isRegistered, "Voter not registered");
        Voter memory voter = voters[studentId];
        return (voter.studentId, voter.hasVoted, voter.votedCandidateId);
    }
    
    /**
     * @dev Get election information
     * @return title, description, startTime, endTime, isActive
     */
    function getElectionInfo() 
        public 
        view 
        returns (string memory, string memory, uint256, uint256, bool) 
    {
        return (
            currentElection.title,
            currentElection.description,
            currentElection.startTime,
            currentElection.endTime,
            currentElection.isActive
        );
    }
    
    /**
     * @dev Get election statistics
     * @return candidateCount, voterCount, totalVotes, votingStarted, votingEnded
     */
    function getElectionStats() 
        public 
        view 
        returns (uint256, uint256, uint256, bool, bool) 
    {
        return (candidateCount, voterCount, totalVotes, votingStarted, votingEnded);
    }
    
    /**
     * @dev Get winning candidate (only after voting ends or admin)
     * @return winningCandidateId, winningCandidateName, winningVoteCount
     */
    function getWinner() 
        public 
        view 
        returns (uint256, string memory, uint256) 
    {
        require(votingEnded || msg.sender == admin, "Voting still in progress");
        require(totalVotes > 0, "No votes cast");
        
        uint256 winningVoteCount = 0;
        uint256 winningCandidateId = 0;
        
        for (uint256 i = 1; i <= candidateCount; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winningCandidateId = i;
            }
        }
        
        return (winningCandidateId, candidates[winningCandidateId].name, winningVoteCount);
    }
    
    /**
     * @dev Reset election (only admin) - for testing purposes
     */
    function resetElection() public onlyAdmin {
        // Reset all candidates
        for (uint256 i = 1; i <= candidateCount; i++) {
            delete candidates[i];
        }
        
        // Reset voters (keep them registered but reset vote status)
        votingStarted = false;
        votingEnded = false;
        candidateCount = 0;
        totalVotes = 0;
        
        currentElection.startTime = 0;
        currentElection.endTime = 0;
        currentElection.isActive = false;
        
        emit ElectionReset();
    }
    
    /**
     * @dev Check if voter can vote
     * @param studentId Student ID to check
     * @return canVote boolean
     */
    function canVote(string memory studentId) public view returns (bool) {
        return (voters[studentId].isRegistered && 
                !voters[studentId].hasVoted && 
                votingStarted && 
                !votingEnded &&
                block.timestamp >= currentElection.startTime &&
                block.timestamp <= currentElection.endTime);
    }
    
    /**
     * @dev Get time remaining in election (in seconds)
     * @return timeRemaining
     */
    function getTimeRemaining() public view returns (uint256) {
        if (!votingStarted || votingEnded) {
            return 0;
        }
        
        if (block.timestamp >= currentElection.endTime) {
            return 0;
        }
        
        return currentElection.endTime - block.timestamp;
    }
    
    /**
     * @dev Emergency stop (only admin)
     */
    function emergencyStop() public onlyAdmin {
        votingEnded = true;
        currentElection.isActive = false;
    }
    
    /**
     * @dev Transfer admin rights (only current admin)
     * @param newAdmin Address of the new admin
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "Invalid admin address");
        admin = newAdmin;
    }
}