
pragma solidity >=0.5.11;

import "./owner.sol";
import "./SafeMath.sol";
import "./ITRC20.sol";

contract BFBSubMiningContract is owned{
    using SafeMath for uint256;

    uint private __onedaySeconds=86400;

    ITRC20 public __bfbToken;
    uint256 public __Reward = 3600000*(10**6);        //400w
    uint256 public __OfferReward =  400000*(10**6);        //40w


    ITRC20 public __subLpToken;
    uint256 public __totalBfbLPToken;

    uint public __lastTime;
    uint public __beginTime;
    uint public __expireTime;
    uint public __withdrawLeftTime;
    bool public __withdrawFlag;
    bool public __startReward;


    struct DepositInfo {
        uint256 DepositTokenAmount;
        uint    TimeStamp;
    }

    struct DepositList {
        address Recommend;
        uint256 TotalAmount;
        uint256 index;
        DepositInfo[] arrDeposit;
    }

    mapping(address=>DepositList) public __depositUsers;
    address[] public __depositUserAddress;

    struct RewardInfo{
        uint256 Reward;
        uint256 OfferReward;
        uint    TimeStamp;
    }

    mapping(address=>RewardInfo) public __rewardInfos;

    event ev_deposit(address user,address referee, uint256 amount,uint timestamp);
    event ev_withdrawLp(address user,uint256 reward, uint256 offerReward);

    constructor (address subLpToken, address bfbToken) public{
        __xmfLpToken = ITRC20(subLpToken);
        __bfbToken = ITRC20(bfbToken);
    }

    function setStartTime(uint beginTime) external onlyOwner{
        if (beginTime == 0){
            beginTime = block.timestamp;
        }
        __beginTime = beginTime;
        __lastTime = beginTime;
        __expireTime = __beginTime + (720*__onedaySeconds);//2 years, 30 day per one month
        __withdrawLeftTime = __expireTime + (30*__onedaySeconds);
        __startReward = true;
    }


    function setWithdrawFlag(bool flag) external onlyOwner{
        __withdrawFlag = flag;
    }

    function setStartReward(bool sw) external onlyOwner{
        __startReward = sw;
    }

    modifier startReward {
        require(__startReward == true,"reward have not begin");
        _;
    }

    modifier startWithdraw{
        require(Withdraw==true,"wait to withdraw...");
        _;
    }

    function getReward(address user) external view returns(uint256,uint256,uint){
        RewardInfo memory d = __rewardInfos[user];
        return (d.Reward,d.OfferReward,d.TimeStamp);
    }

    function CalcSetReward(address[] memory users, uint256[] memory reward,uint256[] memory offerReward) external onlyOwner{
        require(block.timestamp > (____lastTime + (30*__onedaySeconds)));

        for (uint256 i=0;i<users.length;i++){
            __rewardInfos[users[i]].Reward = reward[i];
            __rewardInfos[users[i]].OfferReward = offerReward[i];
            __rewardInfos[users[i]].TimeStamp = block.timestamp;
        }

    }


    function DepositSubLP(address referee, uint256 lpAmount) external startReward{
        
        emit ev_deposit(msg.sender, referee, lpAmount,block.timestamp);
    }

    function WithdrawSubLP() external startWithdraw {

        uint256 memory amount = __rewardInfos[msg.sender].Reward + __rewardInfos[msg.sender].OfferReward;

        require(__depositUsers[msg.sender].TotalAmount > 0, "no lp token in contract");

        require(__subLpToken.balanceOf(this) >= __depositUsers[msg.sender].TotalAmount,"not enough lp token");

        require(__bfbToken.balanceOf(this)>=amount);

        //transfer lp
        __subLpToken.transfer(msg.sender,__depositUsers[msg.sender].TotalAmount);
        __totalBfbLPToken -= __depositUsers[msg.sender].TotalAmount;
        __depositUsers[msg.sender].TotalAmount = 0;
        delete __depositUsers[msg.sender].arrDeposit;
        removeIndex(__depositUsers[msg.sender].index);

        //transfer bfb
        __bfbToken.transfer(msg.sender,amount);

        __rewardInfos[msg.sender] = RewardInfo(0,0,0);

        emit ev_withdrawLp(msg.sender,__rewardInfos[msg.sender].Reward,__rewardInfos[msg.sender].OfferReward);
    }

    function removeIndex(uint256 index) internal {
        if (idx >= __depositUserAddress.length){
            return;
        }

        for (uint256 i=0;i<__depositUserAddress.length-1;i++){
            __depositUserAddress[i] = __depositUserAddress[i+1];
        }

        delete __depositUserAddress[__depositUserAddress.length-1];
        __depositUserAddress.length --;

    }

    //lp token, reward, offerReward
    function GetReward(address user) external view returns(uint256,uint256,uint256,uint256,uint256){
        return ;
    }

    function WithDrawLeftBfb(address user) external onlyOwner{
        require(block.timestamp > __withdrawLeftTime, "only time after withdraw left time can do it");

        __bfbToken.balanceOf(address(this));
        __bfbToken.transfer(user,__bfbToken.balanceOf(address(this)));
    }

}


