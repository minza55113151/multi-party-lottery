// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract lottery {
    uint public T1;
    uint public T2;
    uint public T3;
    uint public playerMax;
    address public owner;
    mapping(address => bytes32) private playersHash;
    mapping(address => uint) private playersValue;
    mapping(address => bool) private playersReveal;
    mapping(address => uint) private playersIndex;
    mapping(uint => address) private players;

    uint public playerCount = 0;
    uint public reward = 0;
    uint public gameStartTimestamp;
    bool public isGameStart = false;

    constructor(uint _T1, uint _T2, uint _T3, uint _playerMax) {                  
        T1 = _T1;
        T2 = _T2;
        T3 = _T3;
        playerMax = _playerMax;
        owner = msg.sender;
    }

    function resetGameState() private {
        for (uint i=0; i<playerCount; i++) 
        {
            address playerAddress = players[i];
            players[i] = address(0);
            playersHash[playerAddress] = 0;
            playersValue[playerAddress] = 0;
            playersReveal[playerAddress] = false;
            playersIndex[playerAddress] = 0;
        }
        playerCount = 0;
        reward = 0;
        isGameStart = false;
    }

    function gameState() external view returns (uint) {
        if (isGameStart == false){
            return 0;
        }
        else if (block.timestamp <= gameStartTimestamp + T1){
            return 1;
        }
        else if (block.timestamp <= gameStartTimestamp + T1 + T2){
            return 2;
        }
        else if (block.timestamp <= gameStartTimestamp + T1 + T2 + T3){
            return 3;
        }
        else{
            return 4;
        }
    }

    function hashWithSalt(uint value, string memory salt) public pure returns (bytes32) {
        require(value >= 0 && value <= 999, "Please enter value between 0 and 999");
        return keccak256(abi.encodePacked(value, salt));
    }

    function stage1(bytes32 hash) public payable {
        require(msg.value == 0.001 ether, "Pls send value = 0.001 ether");
        require(!isGameStart || (block.timestamp <= gameStartTimestamp + T1), "End stage 1");
        require(playerCount < playerMax, "Player reach max");
        require(msg.sender != players[playersIndex[msg.sender]], "You are already in the game");

        reward += 0.001 ether;
        playersHash[msg.sender] = hash;
        playersValue[msg.sender] = 1000;
        playersReveal[msg.sender] = false;
        playersIndex[msg.sender] = playerCount;
        players[playerCount] = msg.sender;

        if (playerCount == 0){
            gameStartTimestamp = block.timestamp;
            isGameStart = true;
        }

        playerCount += 1;
    }

    function stage2(uint value, string memory salt) public {
        require(block.timestamp > gameStartTimestamp + T1 && block.timestamp <= gameStartTimestamp + T1 + T2, "Not in stage 2");
        require(value >= 0 && value <= 999, "Please enter value between 0 and 999");
        require(playersHash[msg.sender] == hashWithSalt(value, salt), "Hash is not match with your reveal value");
        playersReveal[msg.sender] = true;
        playersValue[msg.sender] = value;
    }

    function stage3() public payable {
        require(msg.sender == owner, "You need to be owner to call this function");
        require(block.timestamp > gameStartTimestamp + T1 + T2 && block.timestamp <= gameStartTimestamp + T1 + T2 + T3, "Not in stage 3");
        uint xorResult = 0;
        uint revealPlayerCount = 0;
        for (uint i=0; i<playerCount; i++) 
        {
            address playerAddress = players[i];
            if (playersReveal[playerAddress]) {
                xorResult ^= playersValue[playerAddress];
                revealPlayerCount += 1;
            }
        }
        if (revealPlayerCount == 0){
            payable(owner).transfer(reward);
        }
        else{
            uint result = uint(keccak256(abi.encodePacked(xorResult))) % revealPlayerCount;
            address payable winnerAddress = payable(players[result]);
            winnerAddress.transfer(reward * 98 / 100);
            payable(owner).transfer(reward * 2 / 100);
        }
        resetGameState();
    }

    function stage4() public {
        require(block.timestamp > gameStartTimestamp + T1 + T2 + T3, "Not in stage 4");
        require(msg.sender == players[playersIndex[msg.sender]]);
        assert(reward > 0 ether);
        players[playersIndex[msg.sender]] = address(0);
        playersIndex[msg.sender] = 0;
        reward -= 0.001 ether;
        playerCount -= 1;
        payable(msg.sender).transfer(0.001 ether);
        if (playerCount == 0){
            resetGameState();
        }
    }
}