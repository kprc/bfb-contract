
pragma solidity >=0.5.11;

import "./owner.sol";
import "./SafeMath.sol";
import "./ITRC20.sol";

contract BFBSubMiningContract is owned{
    using SafeMath for uint256;

    uint private __onedaySeconds=86400;


    ITRC20 public __RewardTokenContract;
    uint256 public __TotalReward = 4000000*(10**6);        //400w

    ITRC20 public __LpTokenContract;
    uint256 public __TotalLPToken;


    uint public __lastTime;
    uint public __beginTime;
    uint public __expireTime;           //begin time + 720 days
    uint public __withdrawLeftTime;
    bool public __withdrawFlag;
    bool public __startReward;

    struct DepositItem {
        uint256 DepositLPAmount;
        uint    TimeStamp;
    }


    struct UserDepositInfo {
        address Recommend;
        uint256 TotalDepositAmount;
        DepositItem[] items;
    }

    mapping(address=>UserDepositInfo) public __globalUserDeposits;
    address[] public __globalUserDepositsAddr;


    struct UserRewardItem{
        uint256 Reward;
        uint256 OfferReward;
        uint    TimeStamp;
    }


    mapping(address=>RewardInfo) public __globalUserReward;


    event ev_deposit(address user,address referee, uint256 amount,uint timestamp);
    event ev_withdrawLp(address user);


    constructor (address lpTokenAddr, address rewardToken) public{
        __LpTokenContract = ITRC20(lpTokenAddr);
        __RewardTokenContract = ITRC20(rewardToken);
    }

    function getUserTotalDeposit(address user) external view returns (uint256){
        return (__globalUserDeposits[user].TotalDepositAmount);

    }

    function setStartTime(uint beginTime) external onlyOwner{
        if (beginTime == 0){
            beginTime = block.timestamp;
        }
        __beginTime = beginTime;
        __lastTime = beginTime;
        __expireTime = __beginTime + (720*__onedaySeconds);//2 years, 30 day per one month
        __withdrawLeftTime = __expireTime + (30*__onedaySeconds);
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


    function CalcSetReward(address[] memory users, uint256[] memory reward,uint256[] memory offerReward) external onlyOwner{
        require(block.timestamp > (__lastTime + (30*__onedaySeconds)));

        for (uint256 i=0;i<users.length;i++){
            __globalUserReward[users[i]] = RewardInfo(reward[i],offerReward[i],block.timestamp);
        }
        __lastTime += 30*__onedaySeconds;
    }


    function DepositLPToken(address referee, uint256 lpAmount) external startReward{

        require(lpAmount>0,"lp amount must large than 0");
        require(__LpTokenContract.balanceOf(msg.sender)>=lpAmount," lp amount not enough");

        if (__globalUserDeposits[msg.sender].TotalDepositAmount == 0){
            __globalUserDepositsAddr.push(msg.sender);
        }

        __globalUserDeposits[msg.sender].TotalDepositAmount += lpAmount;
        if (address(0) == __globalUserDeposits[msg.sender].Recommend && referee != address (0)){
            __globalUserDeposits[msg.sender].Recommend = referee;
        }

        __globalUserDeposits[msg.sender].items.push(DepositItem(lpAmount,block.timestamp));

        __RewardTokenContract.transferFrom(msg.sender,address(this), lpAmount);
        __TotalLPToken = __TotalLPToken + lpAmount;

        emit ev_deposit(msg.sender, referee, lpAmount,block.timestamp);
    }


    function WithdrawAll(uint256 addrIdx) external startWithdraw {

        uint256 memory amount = __globalUserReward[msg.sender].Reward + __globalUserReward[msg.sender].OfferReward;

        require(__globalUserDeposits[msg.sender].TotalDepositAmount > 0, "no lp token in contract");

        require(__RewardTokenContract.balanceOf(this) >= __globalUserDeposits[msg.sender].TotalDepositAmount,"not enough lp token");

        require(__RewardTokenContract.balanceOf(this)>=amount);

        //transfer lp
        __LpTokenContract.transfer(msg.sender,__globalUserDeposits[msg.sender].TotalDepositAmount);
        __TotalLPToken -= __globalUserDeposits[msg.sender].TotalDepositAmount;


        __globalUserDeposits[msg.sender].TotalDepositAmount = 0;
        delete __globalUserDeposits[msg.sender].arrDeposit;
        removeAddr(msg.sender);

        //transfer bfb
        if (amount>0){
            __RewardTokenContract.transfer(msg.sender,amount);
        }

        __globalUserReward[msg.sender] = RewardInfo(0,0,0);

        emit ev_withdrawLp(msg.sender);
    }

    function removeAddr(address user) internal {
        uint256 memory idx = __globalUserDepositsAddr.length;

        for (uint256 i=0;i<__globalUserDepositsAddr.length; i++){
            if (user == __globalUserDepositsAddr[i]){
                idx = i;
            }
        }
        if (idx == __globalUserDepositsAddr.length){
            return;
        }

        for (uint256 i=idx;i<__globalUserDepositsAddr.length-1;i++){
            __globalUserDepositsAddr[i] = __globalUserDepositsAddr[i+1];
        }

        delete __globalUserDepositsAddr[__depositUserAddress.length-1];
        __globalUserDepositsAddr.length --;
    }

    //lp token, reward, offerReward
    function GetReward(address user) external view returns(uint256,uint256,uint256){

        return (__globalUserDeposits[user].TotalDepositAmount,__globalUserReward[user].Reward,__globalUserReward[user].OfferReward);
    }

    function WithDrawLeft(address user) external onlyOwner{
        require(block.timestamp > __withdrawLeftTime, "only time after withdraw left time can do it");
        __RewardTokenContract.transfer(user,__RewardTokenContract.balanceOf(address(this)));
    }

}


