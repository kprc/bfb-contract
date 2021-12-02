
pragma solidity >=0.5.11;

import "./owned.sol";
import "./Safemath.sol";
import "./ITRC20.sol";

contract BFBMiningContract is owned{
    using SafeMath for uint256;

    ITRC20 public __bfbToken;
    uint256 public __bfbReward = 68000*(10**18);        //68000
    uint256 public __parentReward = 100000*(10**18);   //100000
    ITRC20 public __pLpToken;
    ITRC20 public __bLpToken;

    uint public __startReward = false;
    uint public __beginTime;
    uint public __bfbWithdrawPause = false;
    uint public __parentWithdrawPause = false;
    uint public __lastTime;

    mapping(address=>uint256) public __parentLPToken;
    address[] public __parentLPUsers;
    uint256 public __totalParentLPToken;
    mapping(address=>uint256) public __bfbLPToken;
    address[] public __bfbLPUsers;
    uint256 public __totalBfbLPToken;

    mapping(address=>uint256) public __rewardFromParent;
    mapping(address=>uint256) public __rewardFromBfb;
    mapping(address=>uint256) public __rewardFromRefer;

    mapping(address=>address[]) public __referee;
    address[] public __refereeUsers;

    event ev_depositParent(address user,address referee, uint256 amount);
    event ev_depositBFB(address user,address referee, uint256 amount);
    constructor (address parentlpToken, address bfbToken,address bfblpToken) public{
        __pLpToken = ITRC20(parentlpToken);
        __bfbToken = ITRC20(bfbToken);
        __bLpToken = ITRC20(bfblpToken);
    }

    modifier startReward {
        require(__startReward == true,"reward have not begin");
        _;
    }

    modifier parentWithdraw{
        require(__parentWithdrawPause==true,"wait to withdraw...");
        _;
    }

    modifier bfbWithdraw{
        require(__bfbWithdrawPause==true,"wait to withdraw...");
        _;
    }

    function setStartReward(bool switch) external onlyOwner{
        __startReward = switch;
    }

    function setStartTime(uint beginTime) external onlyOwner{
        if (beginTime == 0){
            beginTime = block.timestamp;
        }
        __beginTime = beginTime;
        __lastTime = beginTime;
    }

    function setParentWithdraw(bool flag) external onlyOwner{
        __parentWithdrawPause = flag;
    }

    function setBfbWithdraw(bool flag) external onlyOwner{
        __bfbWithdrawPause = flag;
    }

    function _addReferee(address referee, address user) internal {
        if (referee == address(0)){
            return;
        }

        address[] memory list = __referee[referee];
        bool memory found = false;
        for(uint256 i = 0; i<list.length; i++){
            if (list[i] == user){
                found = true;
                break;
            }
        }
        if (found == false){
            __referee[referee] = list.push(user);
        }

        for(uint256 i = 0;i<__refereeUsers.length;i++){
            if (referee == __refereeUsers[i]){
                return;
            }
        }
        __refereeUsers.push(referee);
    }

    function _reward() internal {
        uint memory nowTime = block.timestamp;
        if ( (nowTime - __lastTime) < 86400){
            return;
        }

        uint memory ndays = (nowTime - __lastTime) / 86400;
        uint256 memory pr = (__parentReward/uint256(180)) * uint256(ndays);
        uint256 memory br = (__bfbReward/uint256(180))*uint256(ndays);

        for(uint256 i=0;i<__parentLPUsers.length;i++){
            __rewardFromParent[__parentLPUsers[i]] = __rewardFromParent[__parentLPUsers[i]] + pr * __parentLPToken[__parentLPUsers[i]] / __totalParentLPToken;
        }

        for (uint256 i=0;i<__bfbLPUsers.length;i++){
            __rewardFromBfb[__bfbLPUsers[i]] = __rewardFromBfb[__bfbLPUsers[i]] + br * __bfbLPToken[__bfbLPUsers[i]] / __totalBfbLPToken;
        }

        for(uint256 i=0;i<__refereeUsers.length;i++){
            address[] memory list = __referee[referee];
            uint256 memory bonus = 0;
            for(uint256 i = 0; i<list.length; i++){
                bonus += __rewardFromBfb[list[i]];
                bonus += __rewardFromParent[list[i]];
            }

            __rewardFromRefer[__refereeUsers[i]] = bonus / 10;
        }

        __lastTime = __lastTime + uint(ndays) * 86400;
    }

    function DepositParent(address referee, uint256 parentLPAmount) external startReward{
        require(__pLpToken.balanceOf(msg.sender) >= parentLPAmount,"not enough lp token");
        _reward();
        _addReferee(referee, msg.sender);

        __pLpToken.transfer(address(this),parentLPAmount);

        if(__parentLPToken[msg.sender] == 0){
            __parentLPUsers.push(msg.sender);
        }
        __parentLPToken[msg.sender] = __parentLPToken[msg.sender] + parentLPAmount;
        __totalParentLPToken += parentLPAmount;

        ev_depositParent(msg.sender, referee, parentLPAmount);
    }

    function DepositBFB(address referee, uint256 bfbAmount) external startReward{
        require(__bLpToken.balanceOf(msg.sender)>=bfbAmount, "token not enough");
        _reward();
        _addReferee(referee,msg.sender);

        __bLpToken.transfer(_address(this), bfbAmount);

        if (__bfbLPToken[msg.sender] == 0){
            __bfbLPUsers.push(msg.sender);
        }

        __bfbLPToken[msg.sender] = __bfbLPToken[msg.sender] + bfbAmount;
        __totalBfbLPToken += bfbAmount;

        ev_depositBFB(msg.sender, referee, bfbAmount);
    }


}


