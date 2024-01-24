// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract funding{
    struct Investor{
        address addr; //투자자 주소
        uint amount;  //투자액
    }

    mapping (uint => Investor) public investors; //투자자 추가할 때 key 값 증가

    address public owner;     // 컨트랙트 소유자
    uint public numInvestors; // 투자자 수
    uint public deadline;     // 마감일
    string public status;     // 모금 활동 상태
    bool public ended;        // 모금 종료 여부
    uint public goalAmount;   // 목표액
    uint public totalAmount;  // 총 투자액

    modifier onlyOwner() {
        require(owner == msg.sender, "Only for Owner!");
        _;
    }

    constructor(uint _duration, uint _goalAmount){
        owner = msg.sender;

        deadline = block.timestamp + _duration;
        goalAmount = _goalAmount * 1 ether;

        status = "Funding";
        ended = false;
        numInvestors = 0;
        totalAmount = 0;
    }

    function fund() public payable{
        require(ended == false, "Funding is over!");
    
        investors[numInvestors].addr = msg.sender;
        investors[numInvestors].amount = msg.value;

        totalAmount += msg.value;
        numInvestors++;

    }

    function checkGoalReached () public onlyOwner{
        require(ended == false, "funding is over"); //모금이 끝났으면 
        require(block.timestamp >= deadline, "funding is keep going"); //아직 마감시간이 안지났으면

        if(totalAmount >= goalAmount) { // 모금 성공인 경우
            payable(owner).transfer(totalAmount);
            //payable(owner).transfer(address(this).balance);
            status = "Campagin Succedded";
        }
        else{ //모금 실패한 경우
            status = "Campagin Failed";
            for(uint i = 0; i < numInvestors; i++){
                payable(investors[i].addr).transfer(investors[i].amount);
            }
        }
        ended = true;
    }
}
