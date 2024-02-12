// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./CommitReveal.sol";

contract RPS is CommitReveal {
    struct Player {
        uint choice; // 0 - Rock, 1 - Water, 2 - Air , 3 - Paper , 4 - Sponge , 5 - Scissor, 6 - Fire, 7 - undefined
        address addr;
    }

    uint public numPlayer = 0;
    uint public reward = 0;
    mapping (uint => Player) private player;
    mapping (address => uint) private idx;
    uint public numInput = 0;
    uint public playerReveal = 0;

    function addPlayer() public payable {
        require(numPlayer < 2);
        require(msg.value == 1 ether);
        reward += msg.value;
        player[numPlayer].addr = msg.sender;
        player[numPlayer].choice = 7;
        idx[msg.sender] = numPlayer;
        numPlayer++;
    }

    function input(bytes32 choice) public  {
        require(numPlayer == 2);
        commit(choice);
        numInput++;
    }

    function hashChoice(uint choice, uint salt) external view returns(bytes32) {
        require(choice >= 0 && choice <= 6);
        return getSaltedHash(bytes32(choice),bytes32(salt));
    }

    function revealByUser(uint choice, uint salt) public {
        revealAnswer(bytes32(choice),bytes32(salt));
        player[idx[msg.sender]].choice = choice;
        playerReveal++;
        if(playerReveal == 2){
            _checkWinnerAndPay();
        }
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = player[0].choice;
        uint p1Choice = player[1].choice;
        address payable account0 = payable(player[0].addr);
        address payable account1 = payable(player[1].addr);
        if ((p0Choice + 1) % 7 == p1Choice || (p0Choice + 2) % 7 == p1Choice  || (p0Choice + 3) % 7 == p1Choice ) {
            // to pay player[1]
            account1.transfer(reward);
        }
        else if ((p1Choice + 1) % 7 == p0Choice || (p1Choice + 2) % 7 == p0Choice || (p1Choice + 3) % 7 == p0Choice) {
            // to pay player[0]
            account0.transfer(reward);    
        }
        else {
            // to split reward
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
    }
}
