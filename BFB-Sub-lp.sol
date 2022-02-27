
pragma solidity >=0.5.11;

import "./owner.sol";
import "./SafeMath.sol";
import "./ITRC20.sol";

contract BFBSubMiningContract is owned{
    using SafeMath for uint256;

    uint private __onedaySeconds=86400;

    ITRC20 public __bfbToken;
    uint256 public __Reward = 4000000*(10**6);        //400w

    ITRC20 public __subLpToken;
    uint256 public __totalBfbLPToken;

    uint public __lastTime;
    uint public __beginTime;
    uint public __expireTime;
    bool public __withdrawFlag;
    bool public __startReward;


    struct DepositInfo {
        uint256 DepositTokenAmount;
        uint    TimeStamp;
    }

    struct DepositList {
        address Recommend;
        uint256 TotalAmount;
        DepositInfo[] Depositlist;
    }

    mapping(address=>DepositList) __depositUsers;
    address[] public __depositUserAddress;



    struct RewardInfo{
        uint256 Reward;
        uint256 OfferReward;
        uint    TimeStamp;
    }

    mapping(address=>RewardInfo) __rewardInfos;
    address[] public __rewardUserAddress;

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



    function DepositSubLP(address referee, uint256 lpAmount) external startReward{


        emit ev_deposit(msg.sender, referee, lpAmount,block.timestamp);
    }

    function WithdrawSubLP() external startWithdraw {
        uint256 amount = 0;
        uint256 reward = 0;
        uint256 offerReward = 0;

        emit ev_withdrawLp(msg.sender,reward,offerReward);
    }
    //lp token, reward, offerReward
    function GetReward(address user) external view returns(uint256,uint256,uint256,uint256,uint256){
        return ;
    }

}


