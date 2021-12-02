
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

//    NinjaToken public token;
//    address public ninjaAddr;
//    address[] public WhiteLists;
//    bool public pauseFlag;
//
//    struct LicenseData {
//        bool used;
//        uint32 nDays;
//    }
//    //issue addr, random id,
//    mapping(address=>mapping(bytes32=>LicenseData)) public Licenses;
//
//    struct UserData {
//        uint64 EndDays;
//        uint32 TotalCoins;
//    }
//    //user id,
//    mapping(bytes32=>UserData) public UserLicenses;
//
//    event GenerateLicenseEvent(
//        address indexed issueAddr,
//        bytes32 id,
//        uint32  nDays
//    );
//
//    event BindLicenseEvent(address indexed issueAddr, bytes32 recvAddr, bytes32 id, uint32 nDays);
//
//    event ChargeUserEvent(address indexed payerAddr, bytes32 userAddr, uint32 nDays);
//
//    event TransferLicenseEvent(address indexed executeAddr, bytes32 from, bytes32 to, uint32 nDays);
//
//    constructor(address tAddr, address nAddr) {
//        token = NinjaToken(tAddr);
//        ninjaAddr = nAddr;
//        pauseFlag = false;
//    }
//
//    modifier notPaused {
//        require(pauseFlag == false,"contract have been paused");
//        _;
//    }
//
//    function AddWhiteListAddress(address executeAddr) external onlyOwner{
//        for(uint i=0;i<WhiteLists.length;i++){
//            if (WhiteLists[i] == executeAddr){
//                revert("address already in whitelist");
//            }
//        }
//
//        WhiteLists.push(executeAddr);
//    }
//
//    function DelWhiteListAddress(address executeAddr) external onlyOwner{
//        uint idx = 0x00FFFFFF;
//
//        for(uint i=0;i<WhiteLists.length;i++){
//            if (WhiteLists[i] == executeAddr){
//                idx = i;
//                break;
//            }
//        }
//
//        if(idx >= 0x00FFFFFF){
//            revert("address not found");
//        }
//        WhiteLists[idx]=WhiteLists[WhiteLists.length-1];
//        WhiteLists.pop();
//    }
//
//
//    function SetTokenAddr(address tAddr) external onlyOwner{
//        token = NinjaToken(tAddr);
//    }
//
//    function SetNinjaAddr(address nAddr) external onlyOwner{
//        ninjaAddr = nAddr;
//    }
//
//    function Setting(address tAddr, address nAddr) external onlyOwner{
//        token = NinjaToken(tAddr);
//        ninjaAddr = nAddr;
//    }
//
//    function SetPauseFlag(bool pflag) external onlyOwner{
//        pauseFlag = pflag;
//    }
//
//    function GetSettings() external view returns(address, address){
//        return (address(token),ninjaAddr);
//    }
//
//    function GenerateLicense(bytes32 id, uint32 nDays) external notPaused{
//
//        require(nDays > 0,"time must large than 0");
//
//        LicenseData memory ld = Licenses[msg.sender][id];
//        require(ld.nDays == 0, "id is used");
//
//        token.transferFrom(msg.sender,ninjaAddr, nDays*10**(token.decimals()));
//
//        Licenses[msg.sender][id] = LicenseData(false, nDays);
//
//        emit GenerateLicenseEvent(msg.sender, id, nDays);
//    }
//
//    function GetUserLicense(bytes32 userAddr) external view returns (uint64, uint32){
//        UserData memory ud = UserLicenses[userAddr];
//
//        return (ud.EndDays,ud.TotalCoins);
//    }
//
//    function ChargeUser(bytes32 userAddr, uint32 nDays) external notPaused{
//        require(nDays > 0,"time must large than 0");
//
//        token.transferFrom(msg.sender,ninjaAddr, nDays*10**(token.decimals()));
//
//        UserData memory ud = UserLicenses[userAddr];
//
//        uint curTime = block.timestamp;
//
//        if (curTime  > ud.EndDays){
//            UserLicenses[userAddr] = UserData(uint64(curTime+(3600*24*nDays)),ud.TotalCoins+nDays);
//        }else{
//            UserLicenses[userAddr] = UserData(uint64(ud.EndDays+(3600*24*nDays)),ud.TotalCoins+nDays);
//        }
//
//        emit ChargeUserEvent(msg.sender, userAddr, nDays);
//    }
//
//    function BindLicense(address issueAddr, bytes32 recvAddr, bytes32 id, uint32 nDays, bytes memory signature) external notPaused{
//        LicenseData memory ld = Licenses[issueAddr][id];
//        require(ld.used == false, "id is used");
//        require(ld.nDays == nDays, "nDays not matched");
//
//        bytes32 message = keccak256(abi.encode(this,issueAddr, id, nDays));
//        bytes32 msgHash = prefixed(message);
//        require(recoverSigner(msgHash, signature) == issueAddr);
//
//        Licenses[issueAddr][id] = LicenseData(true, ld.nDays);
//
//        UserData memory ud = UserLicenses[recvAddr];
//
//        uint curTime = block.timestamp;
//
//        if (curTime  > ud.EndDays){
//            UserLicenses[recvAddr] = UserData(uint64(curTime+(86400*nDays)),ud.TotalCoins+nDays);
//        }else{
//            UserLicenses[recvAddr] = UserData(uint64(ud.EndDays+(86400*nDays)),ud.TotalCoins+nDays);
//        }
//
//        emit BindLicenseEvent(issueAddr, recvAddr, id, nDays);
//    }
//
//    function TransferLicense(bytes32 from, bytes32 to, uint32 nDays) external notPaused{
//
//        require(nDays > 0,"nDays must large than 0");
//        bool find = false;
//        for (uint i=0;i<WhiteLists.length;i++){
//            if (WhiteLists[i] == msg.sender){
//                find = true;
//                break;
//            }
//        }
//        require(find == true,"not a valid address");
//
//        UserData memory udfrom = UserLicenses[from];
//        uint curTime = block.timestamp;
//
//        require(udfrom.EndDays > curTime,"End day must large than curTime");
//        uint udfromnDays = (udfrom.EndDays - curTime)/86400;
//
//        require(udfromnDays > nDays,"day time not enough");
//
//        UserLicenses[from] = UserData(udfrom.EndDays-(nDays*86400),udfrom.TotalCoins-nDays);
//
//        if (curTime  >  UserLicenses[to].EndDays){
//            UserLicenses[to] = UserData(uint64(curTime+(86400*nDays)),UserLicenses[to].TotalCoins+nDays);
//        }else{
//            UserLicenses[to] = UserData(uint64(UserLicenses[to].EndDays+(86400*nDays)),UserLicenses[to].TotalCoins+nDays);
//        }
//        emit TransferLicenseEvent(msg.sender, from, to, nDays);
//    }
//
//
//    function prefixed(bytes32 hash) internal pure returns (bytes32) {
//        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
//    }
//    function recoverSigner(bytes32 message, bytes memory sig) internal pure  returns (address) {
//        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
//        return ecrecover(message, v, r, s);
//    }
//    /// signature methods.
//    function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
//        require(sig.length == 65);
//        assembly {
//        // first 32 bytes, after the length prefix.
//            r := mload(add(sig, 32))
//        // second 32 bytes.
//            s := mload(add(sig, 64))
//        // final byte (first byte of the next 32 bytes).
//            v := byte(0, mload(add(sig, 96)))
//        }
//        return (v, r, s);
//    }

