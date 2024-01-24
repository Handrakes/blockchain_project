// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Bank{
    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed withdrawer, uint256 amount);
    address private owner;

    mapping(address => uint256) public balances; //address => uint256으로 mapping하는 것을 balances로 명명

    constructor() { //최초 배포
        owner = msg.sender; //owner가 sender와 같은지 확인
    }

    modifier onlyOwner(){
        require(owner == msg.sender, "Only owner"); //owner인 경우에만 실행!
        _;
    }

    function deposit() public payable{ //payable : 함수가 돈을 받기 위해서 선언하는 것
        require(msg.value > 0 , "Deposit amount must be greater than 0"); 
        balances[msg.sender] += msg.value; // contract balance 값 추가
        emit Deposit(msg.sender, msg.value); //event 발생
    }

    function withdraw(uint256 amount) public{
        require(balances[msg.sender] >= amount, "Insufficient balance"); //인출할 돈보다 잔액이 많아야 함
        balances[msg.sender] -= amount; //잔액에서 인출금액 빼기
        payable(msg.sender).transfer(amount); //amount transfer
        emit Withdrawal(msg.sender, amount);
    }

    function getBalance() public view returns(uint256){ //본인 계좌 잔고 확인
        return balances[msg.sender];
    }

    function getContractBalance() public view onlyOwner returns (uint256){ //현재 contract의 잔고 확인
        return address(this).balance; //this : this contract 
    }
}

