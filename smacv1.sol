// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

// ---------------------- Built with 💘 for everyone --------------------------
/// @author Kinois Le Roi
/// @title SmACV1 [Smart Ads Contract V1] - This contract enables addresses to deploy smart ads.
/// Token : Paid Per Click - The winning crypto of the internet.
/// Symbol : PPeC - Spelled [P:E:K]
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
/// @title PPeC : Paid Per Click [ERC20] Interface
// ----------------------------------------------------------------------------
interface PPeC {
    /// Transfer `amount` tokens to `to`.
    function transfer(address to, uint256 amount) external returns (bool);

    /// Get the amount of tokens owned by account `owner`.
    function balanceOf(address owner) external view returns(uint256);

    /// Get treasury address.
    function treasury() external view returns(address);

    /// Get founder address.
    function founder() external view returns(address);
}

// ----------------------------------------------------------------------------
/// @title SmACCor : AdCreator [Smart ads Contract Creator] Interface.
// ----------------------------------------------------------------------------
interface SmACCor {

    function updatePledged(address promoter, uint256 amount) external returns(bool);

    function pledged(address owner) external view returns(uint256);
}

// ----------------------------------------------------------------------------
/// @title Advertisement : Defines the sturcture of an advertisement.
// ----------------------------------------------------------------------------
struct Advertisement {
    string link;
    string title;
    uint256 reach;
    uint256 reward;
    uint256 budget;
    uint256 created;
    uint256 expired;
    uint256 claimers;
    uint256 scamReport;
    address promoter;
}

// ----------------------------------------------------------------------------
/// @title SmACV1 : Smart Ads Contract [SmAC V1] Version 1.
// ----------------------------------------------------------------------------
contract SmACV1 {

    // Define public constant variables.
    address PPeCAddress;
    address public adCreatorAddress;
    uint256 public minClaimerBalance;
    uint256 public minReward;
    uint256 promoterFee;
    uint256 claimerFee;
    Advertisement public Ads;
    mapping(address => mapping(address => bool)) claimed;

    // Set immutable values.
    constructor(
        address eoa,
        address PPeCAddress_,
        string memory link_,
        string memory title_, 
        uint256 reach_,
        uint256 reward_,
        uint256 minReward_,
        uint256 claimerFee_,
        uint256 promoterFee_,
        uint256 minClaimerBalance_
        ) {            
            Ads.link  = link_;
            Ads.title = title_;
            Ads.promoter = eoa;
            Ads.reach =  reach_;
            Ads.budget = reach_ * reward_;
            Ads.reward =  reward_;
            Ads.created = block.timestamp;
            Ads.expired = Ads.created + 15 days;
            Ads.claimers = 0;
            Ads.scamReport = 0;
            minReward = minReward_;
            claimerFee = claimerFee_;
            PPeCAddress = PPeCAddress_;
            promoterFee = promoterFee_;
            adCreatorAddress = msg.sender;
            minClaimerBalance = minClaimerBalance_;
    }

    // Events that will be emitted on changes.
    event Scam();
    event Destroy();
    event ScamReport();
    event Claim(address indexed claimer, uint256 reward);
    event DelegateCleaner(address indexed claimer, uint256 reward);

    /// You have already claimed the reward.
    error Claimed();
    /// You do not have enough tokens to claim rewards.
    error NotEnoughTokens(uint256 minBalance, uint256 balance);
    /// Reward exceed coffer balance.
    error NotEnoughReward(uint256 reward, uint256 coffer);
    /// The promotion has expired.
    error PromotionEnded();
    /// The promotion has not expired.
    error PromotionRunning();
    /// The promoter refund/claim date has not passed.
    error CannotClean();

    /// @dev Make a function not callable by the founder nor the promoter.
    modifier notOwners() {
        require(msg.sender != Ads.promoter, "Your are the Promoter.");
        require(msg.sender != PPeC(PPeCAddress).founder(), "Your are the Founder.");
        _;
    }

    /// @dev Make a function callable only by the founder.
    modifier onlyFounder() {
        require(msg.sender == PPeC(PPeCAddress).founder(), "Your are not the Founder.");
        _;
    }

    /// @dev Make a function callable only by the promoter.
    modifier onlyPromoter() {
        require(msg.sender == Ads.promoter, "Your are not the Promoter.");
        _;
    }

    /// Claim rewards.
    function claim() public notOwners {

        uint256 claimerBalance = PPeC(PPeCAddress).balanceOf(msg.sender); 
        bool claimedStatus = claimed[address(this)][msg.sender]; 

        if (claimedStatus == true)
            revert Claimed();

        if (minClaimerBalance > claimerBalance)
            revert NotEnoughTokens(minClaimerBalance, claimerBalance);

        if (Ads.reward > cofferBalance() || Ads.reward > Ads.budget)
            revert NotEnoughReward(Ads.reward, cofferBalance());

        if (block.timestamp > Ads.expired)
            revert PromotionEnded();

        claimed[address(this)][msg.sender] = true;
 
        Ads.claimers += 1;

        _transfer(msg.sender, claimerFee, Ads.reward, Ads.reward);

        // feedback.
        emit Claim(msg.sender, Ads.reward);
    }

    /// Claim leftover rewards after advertisement expires.
    function destroy() public onlyPromoter {

        if (block.timestamp < Ads.expired)
            revert PromotionRunning();

        _extraTokenCheck(Ads.promoter, promoterFee, cofferBalance());  

        // feedback.
        emit Destroy();
    }

    /// Claim leftover tokens 4 days after advertisement expires.
    function delegateCleaner() public notOwners {

        if (block.timestamp < Ads.expired + 4 days)
            revert CannotClean();

        _extraTokenCheck(msg.sender, claimerFee, cofferBalance());  

        // feedback.
        emit DelegateCleaner(msg.sender, cofferBalance());
    }

    /// Empty the contract's tokens and make it harder for 
    /// the promoter to advertise.
    function scam() public onlyFounder returns (bool success) {

        SmACCor(adCreatorAddress).updatePledged(Ads.promoter, 10000000000E18);

        PPeC(PPeCAddress).transfer(PPeC(PPeCAddress).treasury(), cofferBalance());

        Ads.budget = 0;

        // feedbacks.
        emit Scam();
        return true;
    }

    /// Report this SmAC as a scam.
    function scamReport() public returns (bool reported) {

        uint256 claimerBalance = PPeC(PPeCAddress).balanceOf(msg.sender);

        bool claimedStatus = claimed[address(this)][msg.sender]; 

        if (claimedStatus == true)
            revert Claimed();

        if (minClaimerBalance > claimerBalance)
            revert NotEnoughTokens(minClaimerBalance, claimerBalance);

        if (block.timestamp > Ads.expired)
            revert PromotionEnded();

        claimed[address(this)][msg.sender] = true;

        Ads.scamReport += 1;

        // feedbacks.
        emit ScamReport();
        return true;
    }

    // Reusable function
    function _transfer(address receiver, uint256 fee, uint256 reward, uint256 unPledged)
    internal
    virtual
    returns(bool success)
    {

        uint256 treasuryShare = ((reward * 100) * fee) / 1000000;
        uint256 receiverShare = reward - treasuryShare;

        uint256 pledged = SmACCor(adCreatorAddress).pledged(Ads.promoter); 

        SmACCor(adCreatorAddress).updatePledged(Ads.promoter, pledged - unPledged);

        Ads.budget -= unPledged;

        PPeC(PPeCAddress).transfer(PPeC(PPeCAddress).treasury(), treasuryShare);
        PPeC(PPeCAddress).transfer(receiver, receiverShare);

        return true;
    }

    // Reusable function
    function _extraTokenCheck(address receiver, uint256 fee, uint256 balance)
    internal
    virtual 
    {  
        uint256 reward;

        uint256 extraToken;

        uint256 pledge;
        
        if (balance > Ads.budget){
            
            extraToken = balance - Ads.budget;
            
            reward = balance - extraToken;
            
            pledge = reward;
        } 

        else if (balance < Ads.budget) {
            
            extraToken = 0;
            
            reward = balance;
            
            pledge = Ads.budget;
        }
        
        else {
            
            reward = balance;
            
            extraToken = 0;
            
            pledge = balance;
        }  

        _transfer(receiver, fee, reward, pledge);

        PPeC(PPeCAddress).transfer(Ads.promoter, extraToken);
    }

    /// Get claimer's claim status.
    function claimStatus() public view returns(bool) {
        return claimed[address(this)][msg.sender];
    }   

    /// Get the contract [coffer] balance.
    function cofferBalance() public view returns(uint256) {
        return PPeC(PPeCAddress).balanceOf(address(this));
    }

    /// Get the promoter's pledged balance.
    function pledgedBalance() public view returns(uint256) {
        return SmACCor(adCreatorAddress).pledged(Ads.promoter); 
    }

    /// Get important advertisement information.
    function getInfo() 
    public 
    view 
    returns(string memory, string memory, uint256,  uint256, uint256, uint256, uint256, uint256, uint256,  uint256, bool, address)
    {
        return (
            Ads.title,
            Ads.link,
            Ads.reach,
            Ads.reward,
            Ads.scamReport,
            Ads.created,
            Ads.expired,
            Ads.claimers,           
            Ads.budget,
            PPeC(PPeCAddress).balanceOf(address(this)),
            claimed[address(this)][msg.sender],
            Ads.promoter
        ); 
    }
}
