// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract KnowledgeSharingHub {
    // State variables
    address public owner;
    uint256 public totalContributions;
    uint256 public rewardPerUpvote;
    
    // Structs
    struct Contribution {
        uint256 id;
        address author;
        string title;
        string content;
        string category;
        uint256 timestamp;
        uint256 upvotes;
        uint256 downvotes;
        bool isActive;
        uint256 rewardsClaimed;
    }
    
    struct User {
        address userAddress;
        uint256 totalContributions;
        uint256 totalRewards;
        uint256 reputation;
        bool isRegistered;
    }
    
    // Mappings
    mapping(uint256 => Contribution) public contributions;
    mapping(address => User) public users;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(address => uint256[]) public userContributions;
    
    // Events
    event UserRegistered(address indexed user, uint256 timestamp);
    event ContributionAdded(uint256 indexed contributionId, address indexed author, string title);
    event ContributionVoted(uint256 indexed contributionId, address indexed voter, bool isUpvote);
    event RewardsClaimed(address indexed user, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyRegistered() {
        require(users[msg.sender].isRegistered, "User must be registered");
        _;
    }
    
    modifier contributionExists(uint256 _contributionId) {
        require(_contributionId > 0 && _contributionId <= totalContributions, "Contribution does not exist");
        _;
    }
    
    // Constructor
    constructor(uint256 _rewardPerUpvote) {
        owner = msg.sender;
        rewardPerUpvote = _rewardPerUpvote == 0 ? 1000000000000000 : _rewardPerUpvote; // Default 0.001 ETH if 0 provided
        
        // Register the owner
        users[owner] = User({
            userAddress: owner,
            totalContributions: 0,
            totalRewards: 0,
            reputation: 100, // Start with base reputation
            isRegistered: true
        });
    }
    
    // Core Function 1: Register User
    function registerUser() external {
        require(!users[msg.sender].isRegistered, "User already registered");
        
        users[msg.sender] = User({
            userAddress: msg.sender,
            totalContributions: 0,
            totalRewards: 0,
            reputation: 50, // New users start with base reputation
            isRegistered: true
        });
        
        emit UserRegistered(msg.sender, block.timestamp);
    }
    
    // Core Function 2: Add Knowledge Contribution
    function addContribution(
        string memory _title,
        string memory _content,
        string memory _category
    ) external onlyRegistered {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_content).length > 0, "Content cannot be empty");
        require(bytes(_category).length > 0, "Category cannot be empty");
        
        totalContributions++;
        
        contributions[totalContributions] = Contribution({
            id: totalContributions,
            author: msg.sender,
            title: _title,
            content: _content,
            category: _category,
            timestamp: block.timestamp,
            upvotes: 0,
            downvotes: 0,
            isActive: true,
            rewardsClaimed: 0
        });
        
        // Update user stats
        users[msg.sender].totalContributions++;
        users[msg.sender].reputation += 5; // Bonus for contributing
        userContributions[msg.sender].push(totalContributions);
        
        emit ContributionAdded(totalContributions, msg.sender, _title);
    }
    
    // Core Function 3: Vote on Contributions
    function voteOnContribution(uint256 _contributionId, bool _isUpvote) 
        external 
        onlyRegistered 
        contributionExists(_contributionId) 
    {
        require(!hasVoted[_contributionId][msg.sender], "User has already voted on this contribution");
        require(contributions[_contributionId].author != msg.sender, "Cannot vote on your own contribution");
        require(contributions[_contributionId].isActive, "Contribution is not active");
        
        hasVoted[_contributionId][msg.sender] = true;
        
        if (_isUpvote) {
            contributions[_contributionId].upvotes++;
            // Reward the author
            users[contributions[_contributionId].author].totalRewards += rewardPerUpvote;
            users[contributions[_contributionId].author].reputation += 2;
        } else {
            contributions[_contributionId].downvotes++;
            // Slightly reduce author's reputation for downvotes
            if (users[contributions[_contributionId].author].reputation > 1) {
                users[contributions[_contributionId].author].reputation -= 1;
            }
        }
        
        // Voter gets small reputation boost for participating
        users[msg.sender].reputation += 1;
        
        emit ContributionVoted(_contributionId, msg.sender, _isUpvote);
    }
    
    // Additional helper functions
    function getContribution(uint256 _contributionId) 
        external 
        view 
        contributionExists(_contributionId) 
        returns (
            address author,
            string memory title,
            string memory content,
            string memory category,
            uint256 timestamp,
            uint256 upvotes,
            uint256 downvotes,
            bool isActive
        ) 
    {
        Contribution memory contrib = contributions[_contributionId];
        return (
            contrib.author,
            contrib.title,
            contrib.content,
            contrib.category,
            contrib.timestamp,
            contrib.upvotes,
            contrib.downvotes,
            contrib.isActive
        );
    }
    
    function getUserStats(address _user) 
        external 
        view 
        returns (
            uint256 userTotalContributions,
            uint256 userTotalRewards,
            uint256 userReputation,
            bool userIsRegistered
        ) 
    {
        User memory user = users[_user];
        return (
            user.totalContributions,
            user.totalRewards,
            user.reputation,
            user.isRegistered
        );
    }
    
    function getUserContributions(address _user) external view returns (uint256[] memory) {
        return userContributions[_user];
    }
    
    // Owner functions
    function setRewardPerUpvote(uint256 _newReward) external onlyOwner {
        rewardPerUpvote = _newReward;
    }
    
    function deactivateContribution(uint256 _contributionId) 
        external 
        onlyOwner 
        contributionExists(_contributionId) 
    {
        contributions[_contributionId].isActive = false;
    }
    
    // Function to receive Ether
    receive() external payable {}
    
    // Fallback function
    fallback() external payable {}
}
