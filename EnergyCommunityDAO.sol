// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EnergyCommunityDAO {
    
    // Structure to represent a community member
    struct Member {
        address memberAddress;
        uint256 shares; // Shares represent voting power
        bool isMember; // Membership status
        uint256 memberEnergyProduced; // in kWh
        uint256 memberEnergyConsumed; // in kWh
        uint256 memberEvChargingUsage; // in kWh 
    }

    // Structure to represent a proposal for DAO governance
    struct Proposal {
        uint256 id;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 deadline;
        mapping(address => bool) voted;
    }

    // PV Energy Production and Consumption
    uint256 public totalEnergyProduced; // in kWh
    uint256 public totalEnergyConsumed; // in kWh
    mapping(address => uint256) public energyBalances; // Tracks energy balance of each member

    // EV Charging
    mapping(address => uint256) public evChargingUsage; // Tracks EV charging usage

    // Governance
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => Member) public members;
    address[] public memberList;
    uint256 public minimumQuorum; // Minimum votes required for proposal execution
    address public owner;

    // Events
    event NewProposal(uint256 indexed id, string description);
    event Vote(uint256 indexed proposalId, address indexed voter, bool support);

    modifier onlyMember() {
        require(members[msg.sender].isMember, "Not a DAO member");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor(uint256 _minimumQuorum) {
        owner = msg.sender;
        minimumQuorum = _minimumQuorum;
    }

    // Function to add a new member
    function addMember(address _member, uint256 _shares) public onlyOwner {
        require(!members[_member].isMember, "Already a member");
        members[_member] = Member({
            memberAddress: _member,
            shares: _shares,
            isMember: true,
            memberEnergyProduced: 0,
            memberEnergyConsumed: 0,
            memberEvChargingUsage: 0
        });
        memberList.push(_member);
    }

    // Function to create a new proposal
    function createProposal(string memory _description) public onlyMember {
        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.description = _description;
        newProposal.deadline = block.timestamp + 7 days; // Proposal duration
        emit NewProposal(proposalCount, _description);
    }

    // Function to vote on a proposal
    function vote(uint256 _proposalId, bool _support) public onlyMember {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp < proposal.deadline, "Voting period has ended");
        require(!proposal.voted[msg.sender], "Already voted");

        proposal.voted[msg.sender] = true;

        if (_support) {
            proposal.votesFor += members[msg.sender].shares;
        } else {
            proposal.votesAgainst += members[msg.sender].shares;
        }

        emit Vote(_proposalId, msg.sender, _support);
    }

    // Function to update energy production
    function updateEnergyConsumption(uint256 _amount, address _member) public onlyMember {
        totalEnergyConsumed += _amount;
        energyBalances[msg.sender] -= _amount;
        members[_member].memberEnergyConsumed -= _amount;
    }

    // Function to update energy production
    function updateEnergyProduction(uint256 _amount, address _member) public onlyMember {
        totalEnergyProduced += _amount;
        energyBalances[msg.sender] += _amount;
        members[_member].memberEnergyProduced += _amount;
    }

    // Function to charge EV
    function chargeEV(uint256 _amount, address _member) public onlyMember {
        evChargingUsage[msg.sender] += _amount;
        energyBalances[msg.sender] -= _amount;
        members[_member].memberEnergyConsumed -= _amount;
        
    }

    //Function to withdraw funds
    function withdrawFunds() public  {
        payable(owner).transfer(address(this).balance);
    }

    // Fallback function to accept Ether payments
    receive() external payable {}
}