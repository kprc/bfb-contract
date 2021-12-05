
pragma solidity >=0.5.11;

import "./owner.sol";
import "./SafeMath.sol";
import "./ITRC20.sol";

contract BFBMiningContract is owned{
    using SafeMath for uint256;

    uint private __onedaySeconds=60;
    // uint private __onedaySeconds=86400;

    ITRC20 public __bfbToken;
    uint256 public __bfbReward = 68000*(10**18);        //68000
    uint256 public __parentReward = 100000*(10**18);   //100000
    ITRC20 public __pLpToken;
    ITRC20 public __bLpToken;

    bool public __startReward = false;
    uint public __beginTime;
    bool public __bfbWithdrawPause = false;
    bool public __parentWithdrawPause = false;
    uint public __lastTime;
    uint public __expireTime;

    mapping(address=>uint256) public __parentLPToken;
    address[] public __parentLPUsers;
    uint256 public __totalParentLPToken;
    mapping(address=>uint256) public __bfbLPToken;
    address[] public __bfbLPUsers;
    uint256 public __totalBfbLPToken;

    mapping(address=>uint256) public __rewardFromParent;
    mapping(address=>uint256) public __rewardFromBfb;
    mapping(address=>uint256) public __rewardFromParentRefer;
    mapping(address=>uint256) public __rewardFromBfbRefer;

    struct TAddressList {
        uint exists ;
        address[] addrs;
    }

    mapping(address=>TAddressList) public __parentReferee;
    address[] public __parentRefereeUsers;

    mapping(address=>TAddressList) public __bfbReferee;
    address[] public __bfbRefereeUsers;

    event ev_depositParent(address user,address referee, uint256 amount);
    event ev_depositBFB(address user,address referee, uint256 amount);
    event ev_withdrawParent(address user, uint256 parentLPTokenAmount, uint256 bfbTokenAmount);
    event ev_withdrawBfb(address user, uint256 bfgLPTokenAmount, uint256 bfbTokenAmount);

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

    function setStartReward(bool sw) external onlyOwner{
        __startReward = sw;
    }

    function setStartTime(uint beginTime) external onlyOwner{
        if (beginTime == 0){
            beginTime = block.timestamp;
        }
        __beginTime = beginTime;
        __lastTime = beginTime;
        __expireTime = __beginTime + (180*__onedaySeconds);
    }

    function setParentWithdraw(bool flag) external onlyOwner{
        __parentWithdrawPause = flag;
    }

    function setBfbWithdraw(bool flag) external onlyOwner{
        __bfbWithdrawPause = flag;
    }

    function _addParentReferee(address referee, address user) internal {
        if (referee == address(0) || referee == user){
            return;
        }

        TAddressList memory list = __parentReferee[referee];
        bool found = false;
        if (list.exists > 0){
            for(uint256 i = 0; i<list.addrs.length; i++){
                if (list.addrs[i] == user){
                    found = true;
                    break;
                }
            }
        }
        if (found == false){
            __parentReferee[referee].addrs.push(user);
            __parentReferee[referee].exists += 1;
        }

        for(uint256 i = 0;i<__parentRefereeUsers.length;i++){
            if (referee == __parentRefereeUsers[i]){
                return;
            }
        }
        __parentRefereeUsers.push(referee);
    }

    function _addBfbReferee(address referee, address user) internal {
        if (referee == address(0) || referee == user){
            return;
        }

        TAddressList memory list = __bfbReferee[referee];
        bool found = false;
        if(list.exists>0){
            for(uint256 i = 0; i<list.addrs.length; i++){
                if (list.addrs[i] == user){
                    found = true;
                    break;
                }
            }
        }

        if (found == false){
            __bfbReferee[referee].addrs.push(user);
            __bfbReferee[referee].exists += 1;
        }

        for(uint256 i = 0;i<__bfbRefereeUsers.length;i++){
            if (referee == __bfbRefereeUsers[i]){
                return;
            }
        }
        __bfbRefereeUsers.push(referee);
    }

    function _reward() internal {
        uint nowTime = block.timestamp;
        if ( (nowTime <= __lastTime) || ((nowTime - __lastTime) < __onedaySeconds)){
            return;
        }
        if(__lastTime == __expireTime){
            return;
        }
        if (nowTime > __expireTime){
            nowTime = __expireTime;
        }
        uint  ndays = (nowTime - __lastTime) / __onedaySeconds;
        if (ndays == 0){
            return;
        }
        uint256  pr = (__parentReward/uint256(180)) * uint256(ndays);
        uint256  br = (__bfbReward/uint256(180))*uint256(ndays);


        for (uint256 i=0;i<__parentRefereeUsers.length;i++){
            TAddressList memory list = __parentReferee[__parentRefereeUsers[i]];
            uint256 bonus = 0;
            if (__totalParentLPToken>0 && list.exists>0){
                for(uint256 j=0;j<list.addrs.length;j++){
                    bonus += (pr *__parentLPToken[list.addrs[j]]/__totalParentLPToken)/10;
                }
            }

            __rewardFromParentRefer[__parentRefereeUsers[i]] += bonus;
        }

        for (uint256 i=0;i<__bfbRefereeUsers.length;i++){
            TAddressList memory list = __bfbReferee[__bfbRefereeUsers[i]];
            uint256 bonus = 0;
            if(__totalBfbLPToken>0 && list.exists > 0){
                for(uint256 j=0;j<list.addrs.length;j++){
                    bonus += (pr *__bfbLPToken[list.addrs[j]]/__totalBfbLPToken)/10;
                }
            }
            __rewardFromBfbRefer[__bfbRefereeUsers[i]] += bonus;
        }

        for(uint256 i=0;i<__parentLPUsers.length;i++){
            if(__totalParentLPToken > 0){
                __rewardFromParent[__parentLPUsers[i]] = __rewardFromParent[__parentLPUsers[i]] + pr * __parentLPToken[__parentLPUsers[i]] / __totalParentLPToken;
            }else{
                __rewardFromParent[__parentLPUsers[i]] = 0;
            }

        }

        for (uint256 i=0;i<__bfbLPUsers.length;i++){
            if(__totalParentLPToken > 0){
                __rewardFromBfb[__bfbLPUsers[i]] = __rewardFromBfb[__bfbLPUsers[i]] + br * __bfbLPToken[__bfbLPUsers[i]] / __totalBfbLPToken;
            }else{
                __rewardFromParent[__parentLPUsers[i]] = 0;
            }
        }

        __lastTime = __lastTime + uint(ndays) * __onedaySeconds;
    }

    function DepositParent(address referee, uint256 parentLPAmount) external startReward{
        require(__pLpToken.balanceOf(msg.sender) >= parentLPAmount,"not enough lp token");
        _reward();
        _addParentReferee(referee, msg.sender);

        __pLpToken.transferFrom(msg.sender,address(this),parentLPAmount);

        bool found = false;
        for (uint256 i=0;i<__parentLPUsers.length;i++){
            if (__parentLPUsers[i] == msg.sender){
                found = true;
                break;
            }
        }
        if (found == false){
            __parentLPUsers.push(msg.sender);
        }

        __parentLPToken[msg.sender] = __parentLPToken[msg.sender] + parentLPAmount;
        __totalParentLPToken += parentLPAmount;

        emit ev_depositParent(msg.sender, referee, parentLPAmount);
    }

    function DepositBFB(address referee, uint256 bfbAmount) external startReward{
        require(__bLpToken.balanceOf(msg.sender)>=bfbAmount, "token not enough");
        _reward();
        _addBfbReferee(referee,msg.sender);

        __bLpToken.transferFrom(msg.sender,address(this), bfbAmount);

        bool found = false;
        for (uint256 i=0;i<__bfbLPUsers.length;i++){
            if (__bfbLPUsers[i] == msg.sender){
                found = true;
                break;
            }
        }
        if (found == false){
            __bfbLPUsers.push(msg.sender);
        }

        __bfbLPToken[msg.sender] = __bfbLPToken[msg.sender] + bfbAmount;
        __totalBfbLPToken += bfbAmount;

        emit ev_depositBFB(msg.sender, referee, bfbAmount);
    }

    function WithdrawParent() external parentWithdraw{
        _reward();
        //transfer parent token
        __pLpToken.transfer(msg.sender,__parentLPToken[msg.sender]);
        uint256 plptoken = __parentLPToken[msg.sender];
        __totalParentLPToken -= __parentLPToken[msg.sender];
        __parentLPToken[msg.sender] = 0;
        //transfer bfb token
        uint256 bfbt = __rewardFromParent[msg.sender]+__rewardFromParentRefer[msg.sender];
        __bfbToken.transfer(msg.sender,__rewardFromParent[msg.sender]+__rewardFromParentRefer[msg.sender]);
        __rewardFromParent[msg.sender] = 0;
        __rewardFromParentRefer[msg.sender] = 0;

        emit ev_withdrawParent(msg.sender,plptoken, bfbt);
    }


    function WithdrawBFB() external bfbWithdraw{
        _reward();
        __bLpToken.transfer(msg.sender,__bfbLPToken[msg.sender]);
        uint256 blptoken = __bfbLPToken[msg.sender];
        __totalBfbLPToken -= __bfbLPToken[msg.sender];
        __bfbLPToken[msg.sender] = 0;
        //transfer bfb token
        uint256 bfbt = __rewardFromBfb[msg.sender]+__rewardFromBfbRefer[msg.sender];
        __bfbToken.transfer(msg.sender,__rewardFromBfb[msg.sender]+__rewardFromBfbRefer[msg.sender]);

        __rewardFromBfb[msg.sender] = 0;
        __rewardFromBfbRefer[msg.sender] = 0;
        emit ev_withdrawBfb(msg.sender,blptoken, bfbt);
    }

    function GetReward() external view returns(uint256,uint256,uint256,uint256,uint256,uint256){
        uint ndays;
        uint nowTime = block.timestamp;
        if (nowTime <= __lastTime){
            ndays = 0;
        }else{
            if (nowTime > __expireTime){
                nowTime = __expireTime;
            }
            ndays = (nowTime - __lastTime) / __onedaySeconds;
        }

        uint256  pr = (__parentReward/uint256(180)) * uint256(ndays);
        uint256  br = (__bfbReward/uint256(180))*uint256(ndays);

        return (__parentLPToken[msg.sender],
        __bfbLPToken[msg.sender],
        _rewardParent(pr),
        _rewardBfb(br),
        _pBonus(pr),
        _bfbBonus(br));
    }

    function _rewardParent(uint256 pr)internal view returns(uint256){
        if (__totalParentLPToken == 0){
            return 0;
        }

        return (__rewardFromParent[msg.sender] + pr * __parentLPToken[msg.sender] / __totalParentLPToken);
    }
    function _rewardBfb(uint256 br)internal view returns(uint256){
        if (__totalBfbLPToken == 0){
            return 0;
        }
        return (__rewardFromBfb[msg.sender] + br * __bfbLPToken[msg.sender] / __totalBfbLPToken);
    }

    function _bfbBonus(uint256 br) internal view returns(uint256){
        TAddressList memory list = __bfbReferee[msg.sender];
        uint256  bfBbonus = 0;
        if (list.exists > 0){
            for(uint256 j=0;j<list.addrs.length;j++){
                bfBbonus += (br *__bfbLPToken[list.addrs[j]]/__totalBfbLPToken)/10;
            }
        }

        return (__rewardFromBfbRefer[msg.sender] + bfBbonus);
    }

    function _pBonus( uint256 pr)internal view returns (uint256){
        TAddressList memory  list = __parentReferee[msg.sender];
        uint256 pBonus = 0;
        if (list.exists > 0){
            for(uint256 j=0;j<list.addrs.length;j++){
                pBonus += (pr *__parentLPToken[list.addrs[j]]/__totalParentLPToken)/10;
            }
        }

        return (__rewardFromParentRefer[msg.sender] + pBonus);
    }

    function BalanceBFBof() external view returns(uint256){
        return (__bfbToken.balanceOf(address(this)));
    }

    function RetrieveFrom(address user) external onlyOwner{
        __bfbToken.balanceOf(address(this));
        __bfbToken.transfer(user,__bfbToken.balanceOf(address(this)));
    }

}


