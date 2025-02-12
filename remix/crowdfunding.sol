// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Crowdfunding {

    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public campaigns;
    uint256 public id = 0;

    //events
    event CampaignCreated(uint256 id, address owner, string title, uint256 target, uint256 deadline);
    event DonationReceived(uint256 id, address donor, uint256 amount);
    event FundsWithdrawn(uint256 id, address owner, uint256 amount);

    function createCampaign(address _owner, string memory _title, string memory _descriptions, uint256 _target, uint256 _deadline, string memory _image) public returns(uint256) {
        require(_deadline > block.timestamp, "Deadline should be in future");
        
        Campaign storage campaign = campaigns[id];
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _descriptions;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        // emit the event
        emit CampaignCreated(id, _owner, _title, _target, _deadline);

        id++;
        return id - 1;
    }

    function donateToCampaign(uint256 _id) public payable {
        require(_id < id, "Campaign does not exist");

        Campaign storage campaign = campaigns[_id];
        require(block.timestamp < campaign.deadline, "Campaign deadline has passed");

        campaign.donators.push(msg.sender);
        campaign.donations.push(msg.value);
        campaign.amountCollected += msg.value;

        emit DonationReceived(_id, msg.sender, msg.value);
    }

    function withdrawFunds(uint256 _id) public {
        Campaign storage campaign = campaigns[_id];

        require(msg.sender == campaign.owner, "Only the owner can withdraw funds");
        require(block.timestamp >= campaign.deadline, "Campaign deadline has not passed");
        require(campaign.amountCollected >= campaign.target, "Target not met");

        uint256 amountToWithdraw = campaign.amountCollected;
        campaign.amountCollected = 0; // Reset the amount collected before transferring funds

        (bool sent, ) = payable(campaign.owner).call{value: amountToWithdraw}("");

        require(sent, "Failed to send funds");
        emit FundsWithdrawn(_id, campaign.owner, amountToWithdraw);
    }

    function getDonators(uint256 _id) public view returns (address[] memory, uint256[] memory) {
        require(_id < id, "Campaign does not exist");
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (uint256[] memory, address[] memory, string[] memory, uint256[] memory, uint256[] memory) {
        // Create arrays to store campaign details
        uint256[] memory ids = new uint256[](id);
        address[] memory owners = new address[](id);
        string[] memory titles = new string[](id);
        uint256[] memory targets = new uint256[](id);
        uint256[] memory deadlines = new uint256[](id);

        // Populate the arrays with campaign data
        for (uint256 i = 0; i < id; i++) {
            Campaign storage campaign = campaigns[i];
            ids[i] = i;
            owners[i] = campaign.owner;
            titles[i] = campaign.title;
            targets[i] = campaign.target;
            deadlines[i] = campaign.deadline;
        }

        // Return the arrays
        return (ids, owners, titles, targets, deadlines);
    }
}   
