// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./smac.sol";

// ---------------------- Built with 💘 for everyone --------------------------
/// @author Kinois Le Roi
/// @title SmACV1 [Smart Ads Contract V1] - This contract enables addresses to deploy smart ads.
/// Token : Paid Per Click - The winning crypto of the internet.
/// Symbol : PPeC - Spelled [P:E:K]
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
/// @title AdCreator : Smart Ads Contract Creator [SmACCor] - Enables addresses to publish Ads.
/// @notice Smart Ads cannot be updated once promoted.
// ----------------------------------------------------------------------------
contract AdCreator {

    // Define public constant variables.
    address PPeCAddress = 0xa1E607C05462D8b642C8BbdB0c87EdfE2aE67071;
    address public founder;
    address public treasury;
    uint256 public minClaimerBalance;
    uint256 public minReward;
    uint256 public promoterFee;
    uint256 public claimerFee;
    bool public paused = false;
    mapping(address => uint256) public pledged;
    mapping(address => bool) public delegateContract;
    mapping(address => SmACV1[]) public promoterAds;
    SmACV1[] public advertisements;    
    
    // Set immutable values.
    constructor(uint256 minReward_, uint256 minBalance_) {
        founder = PPeC(PPeCAddress).founder();
        treasury = PPeC(PPeCAddress).treasury();
        minClaimerBalance = minBalance_;
        minReward = minReward_;
        promoterFee = 2000;
        claimerFee = 5000;
    }

    // Events that will be emitted on changes.    
    event Pause();
    event Unpause();
    event RemoveAd();
    event LaunchAd(
        string link, 
        string title, 
        uint256 reach, 
        uint256 reward, 
        uint256 budget, 
        uint256 indexed created,
        address indexed promoter, 
        address indexed adsContract
    );

    // Errors that describe failures.

    // The triple-slash comments are so-called natspec
    // comments. They will be shown when the user
    // is asked to confirm a transaction or
    // when an error is displayed. (source: solidity.org)

    /// The budget exceeds your balance.
    /// Your budget is `budget`, however your balance is `balance`.
    error BudgetExceedBalance(uint256 budget, uint256 balance);
    /// Your balance pledged `pledged` cannot exceeds your balance `balance`.
    error PledgeExceedBalance(uint256 pledged, uint256 balance);
    /// Your reward `reward` is lower than (`minReward`) the minimum required.
    error RewardTooLow(uint256 reward, uint256 minReward);
    /// The index entered `index` is out of bound.
    error IndexOutOfBound(uint256 index);
    /// You are not a delegate Contract.
    error NotDelegateContract();

    /// Make a function callable only when the contract is not paused.
    modifier whenNotPaused() {
        require(paused == false, "All publications have been paused.");
        _;
    }

    /// Make a function callable only when the contract is paused.
    modifier whenPaused() {
        require(paused);
        _;
    }

    /// Make a function callable only by the founder.
    modifier onlyFounder() {
        require(msg.sender == founder, "Your are not the Founder.");
        _;
    }

    /// Launch a smart advertisement.
    function launchAd(string memory title, string memory link, uint256 reach, uint256 reward)
    whenNotPaused
    public
    returns(bool success) 
    {
        require(reach >= 30, "You must enter at least 30.");

        uint256 PromoterBalance = PPeC(PPeCAddress).balanceOf(msg.sender);
        uint256 balancePledged = pledged[msg.sender];  

        uint256 budget = reach * reward;
        
        if (budget > PromoterBalance)
            revert BudgetExceedBalance(budget, PromoterBalance); 
 
        if (balancePledged + budget > PromoterBalance)
            revert PledgeExceedBalance(balancePledged, PromoterBalance);

        if (reward < minReward)
            revert RewardTooLow(reward, minReward);
  
        pledged[msg.sender] += budget; 

        SmACV1 newAdvertisement = new SmACV1(
            msg.sender,
            PPeCAddress,
            link,
            title,
            reach,
            reward,
            minReward,
            claimerFee,
            promoterFee,
            minClaimerBalance
        );

        advertisements.push(newAdvertisement);
        promoterAds[msg.sender].push(newAdvertisement);

        delegateContract[address(newAdvertisement)] = true;
        
        // See {event LaunchAds}
        emit LaunchAd(
            link, 
            title, 
            reach, 
            reward, 
            budget, 
            block.timestamp,
            msg.sender,
            address(newAdvertisement)
        );       
        return true;
    }
    
    /// Remove an advertisement from the array.
    function removeAd(uint256 index) public onlyFounder returns(bool removed) {

        if (index >= advertisements.length)
            revert IndexOutOfBound(index);

        for (uint256 i = index; i < advertisements.length - 1; i++) {
            advertisements[i] = advertisements[i + 1];
        }
        
        advertisements.pop(); 

        emit RemoveAd(); 
        return true;
    }

    /// Update promoter's pledged balance.
    function updatePledged(address promoter, uint256 amount) public returns(bool success) {   

        if (delegateContract[msg.sender] != true)
            revert NotDelegateContract();

        pledged[promoter] = amount; 
        return true;
    }

    /// Change minimum reward to `newMin`.
    function setMinReward(uint256 newMin) public onlyFounder returns(bool success) {
        minReward = newMin; 
        return true;
    }

    /// Change the minimum balance a claimer must have before claiming rewards to `newMin`.
    function setMinClaimerBalance(uint256 newMin) public onlyFounder returns(bool success) {        
        minClaimerBalance = newMin; 
        return true;
    }

    /// Change promoters' fee to `newFee`.
    function setPromoterFee(uint256 newFee) public onlyFounder returns(bool success) {
        promoterFee = newFee; 
        return true;
    }

    /// Change claimers' fee to `newFee`.
    function setClaimerFee(uint256 newFee) public onlyFounder returns(bool success) {  
        claimerFee = newFee; 
        return true;
    }
    
    /// Pause advertisement publication.
    function pause() public onlyFounder whenNotPaused returns(bool success) {
        paused = true; 
        
        // See {event Pause}        
        emit Pause(); 
        return true;
    }
    
    /// Unpause advertisement publication.
    function unpause() public  onlyFounder whenPaused returns(bool success) {
        paused = false; 

        // See {event Unpause}        
        emit Unpause();
        return true;
    }

    /// Get the number of advertisements in our array.
    function promotionCount() public view returns(uint256) {
        return advertisements.length;
    }

    /// Get the amount of tokens owned by account `owner`.
    function balanceOf(address owner) public view returns(uint256) {
        return PPeC(PPeCAddress).balanceOf(owner);
    }

    /// Get the number of advertisements for `promoter`.
    function promoterAdCount(address promoter) public view returns(uint256) {
        return promoterAds[promoter].length;
    }

    /// Get the balances and ad count of `owner`.
    function ownerInfo(address owner) public view returns(uint256 wallet, uint256 pledge, uint256 adCount) {
        return (
            PPeC(PPeCAddress).balanceOf(owner),
            pledged[owner],
            promoterAds[owner].length
        );
    }

    /// Get the contract information.
    function contractInfo() public view returns(uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
            PPeC(PPeCAddress).balanceOf(treasury),
            advertisements.length,
            minClaimerBalance,
            promoterFee, 
            claimerFee,
            minReward
        );
    }
}
