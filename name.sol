// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract name{
    // 컨트랙트 정보를 나타낼 구조체
    struct ContractInfo {
        address contractOwner;
        address contractAddress;
        string description;
    }
    // 등록된 컨트랙트 수
    uint public numContracts;
    // 등록한 컨트랙트들을 저장할 매핑 (이름 -> 컨트랙트 정보 구조체)
    mapping(string => ContractInfo) public registeredContracts;

    // 등록한 컨트랙트 정보는 등록한 소유자만 변경 가능
    modifier onlyOwner(string memory _name) {
        require(registeredContracts[_name].contractOwner == msg.sender);
        _;
    }


    constructor(){
        numContracts = 0;
    }
    // 신규 등록 함수
    function registerContract(string memory _name, address _contractAddress, string memory _description) public{
        require(registeredContracts[_name].contractAddress == address(0), "Already exists!"); //20byte 주소가 전부 0으로 차있다 = address(0)
        registeredContracts[_name] = ContractInfo(msg.sender, _contractAddress, _description);
        numContracts++;
    }

    // 컨트랙트 삭제
    function unregisterContract(string memory _name) public onlyOwner(_name){
        require(registeredContracts[_name].contractAddress != address(0), "contract with this name does not exist");
        delete registeredContracts[_name];
        numContracts--;
    }

    // 컨트랙트 소유자 정보 변경
    function changeOwner(string memory _name, address _newOwner) public onlyOwner(_name) {
        registeredContracts[_name].contractOwner = _newOwner;
    }

    // 컨트랙트 소유자 정보 확인
    function getOwner(string memory _name) public view returns (address) {
        return registeredContracts[_name].contractOwner;
    }

    // 컨트랙트 어드레스 변경
    function setAddr(string memory _name, address _addr) public onlyOwner(_name) {
        registeredContracts[_name].contractAddress = _addr;
    }

    // 컨트랙트 어드레스 확인
    function getAddr(string memory _name)public view returns (address) {
        return registeredContracts[_name].contractAddress;
    }

    // 컨트랙트 설명 변경
    function setDiscription(string memory _name, string memory _description) public onlyOwner(_name){
        registeredContracts[_name].description = _description;
    }

    //컨트랙트 설명 확인
    function getDiscription(string memory _name) public view returns(string memory){
        return registeredContracts[_name].description;
    } 

}
