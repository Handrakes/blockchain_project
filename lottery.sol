// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract lottery{
    address public manager; // 관리자(배포자)
    address[] public players; // 플레이어

    enum Status {OK_Enter, NOT_Enter}
    Status public step; 

    event Winner(address winner, uint prize);
    event players_in(address[] player);

    constructor(){
        manager = msg.sender;
        step = Status.OK_Enter;
    }

    modifier restricted(){
        require(msg.sender == manager, "Only manager can do!");
        _;
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.number, block.timestamp, players.length)));
    }

    function enter() public payable{
        require(step == Status.OK_Enter, "Now step is Pick! Not Entering"); // entering 인 경우에만 참여 가능
        require(msg.sender != manager, "manager can't enter this lottery!"); // manager는 참여 불가
        require(msg.value == 1 ether, "Only 1 ether is available");
        uint flag = 0;
        for(uint i = 0; i < players.length; i++){
            if(players[i] == msg.sender)
                flag++; // 이미 있는 주소값인 경우
        }
        if(flag == 0){
            players.push(msg.sender);
            emit players_in(players); // 참여자 정보 event
        }
        else{
            revert("already exist");
        }
    }

    function Enter_to_Pick() public restricted {
        if(step == Status.OK_Enter)
            step = Status.NOT_Enter;
        else 
            revert("Statis must be Enter, But it is Not Enter");
    }

    function Pick_to_Enter() public restricted {
        if(step == Status.NOT_Enter)
            step = Status.OK_Enter;
        else
            revert("Status must be NOT Enter, But it is Enter");
    }

    function pickWinner() public restricted {
        require(step == Status.NOT_Enter, "Now step is Entering! Not Pick");
        uint tmp = random();
        uint result = tmp % players.length;
        address winner = players[result];
        delete players; // 배열 초기화
        payable(winner).transfer(address(this).balance);
        emit Winner(winner, address(this).balance); // 우승자 이벤트  
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }
}
