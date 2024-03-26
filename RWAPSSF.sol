// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./CommitReveal.sol";

contract RPS is CommitReveal {
    struct Player {
        uint choice; // 0 - Rock, 1 - Water, 2 - Air , 3 - Paper , 4 - Sponge , 5 - Scissor, 6 - Fire, 7 - undefined
        address addr;
        uint point;
    }

    uint public numPlayer = 0;
    uint public reward = 0;
    mapping (uint => Player) public player;
    mapping (address => uint) private idx;
    mapping (uint => bool) public Revealed;
    uint public numInput = 0;
    uint public playerReveal = 0;
    uint public startTime = 0;
    uint private maxPoint = 0;
    uint private maxCount = 0;

    function addPlayer() public payable {
        require(numPlayer < 3);
        require(msg.value == 1 ether);
        reward += msg.value;
        player[numPlayer].addr = msg.sender;
        player[numPlayer].choice = 7;
        idx[msg.sender] = numPlayer;
        if(numPlayer == 0){
            startTime = block.timestamp;
        }
        numPlayer++;
    }

    function input(bytes32 choice) public  {
        require(numPlayer == 3);
        commit(choice);
        numInput++;
    }

    function hashChoice(uint choice, uint salt) external view returns(bytes32) {
        // user hash thier choice and put in input
        require(choice >= 0 && choice <= 6);
        return getSaltedHash(bytes32(choice),bytes32(salt));
    }

    function revealByUser(uint choice, uint salt) public {
        require(numInput == 3);
        revealAnswer(bytes32(choice),bytes32(salt));
        player[idx[msg.sender]].choice = choice;
        Revealed[idx[msg.sender]] = true;
        playerReveal++;
        if(playerReveal == 3){
            _checkWinnerAndPay();
        }
    }

    function checkStatus() public {
        if(block.timestamp > startTime + 1 days){
            //check 1 day
            _handleOvertime();
        }
    } 

    function _handleOvertime() private {
        require(block.timestamp > startTime + 1 days, "Not overtime yet");
        if (playerReveal != 0){ 
            uint amount = reward/playerReveal;
            for(uint i=0; i<numPlayer ; i++){
                if(Revealed[i] == true){
                    address payable playerAddress = payable (player[i].addr);
                    reward -= amount;
                    playerAddress.transfer(amount);
                }
            _resetGame();
            }
        }
    }

    function _checkWinnerAndPay() private {
        for(uint i=0; i<numPlayer ; i++){
            uint ci = player[i].choice;
            for(uint j=0; i<numPlayer ; j++){
                uint cj = player[j].choice;
                if(i != j){
                    if ((ci + 1) % 7 == cj || (ci + 2) % 7 == cj  || (ci + 3) % 7 == cj ) {
                        // to pay player[1]
                    }
                    else if ((cj + 1) % 7 == ci || (cj + 2) % 7 == ci || (cj + 3) % 7 == ci) {
                        // to pay player[0]
                        player[i].point += 3;
                    }
                    else {
                        player[i].point += 1;
                    }
                }
            }
            if(player[i].point > maxPoint){
                maxPoint = player[i].point;
                maxCount = 1;
            }
            else if(player[i].point > maxPoint){
                maxCount += 1;
            }
        }

        uint pay = reward/maxCount;
        for(uint i=0; i<numPlayer ; i++){
            if(player[i].point == maxPoint && reward != 0){
                reward -= pay;
                (payable(player[i].addr)).transfer(pay);
            }
        }



    }

    function _resetGame() private {
        numPlayer = 0;
        reward = 0;
        numInput = 0;
        playerReveal = 0;
        startTime = 0;
        for(uint i=0; i<numPlayer ; i++){
            player[i].addr = address(0);
            player[i].choice = 7;
            player[i].point = 0;
            Revealed[i] = false;
        }
    }
}
