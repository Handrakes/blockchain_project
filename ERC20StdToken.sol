// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ERC20StdToken{
    mapping (address => uint256) balances; // 각 계정이 소유한 토큰 수 저장
    mapping (address => mapping (address => uint256)) allowed; // 대리 전송할 수 있도록 허용한 토큰 수 저장
    
    uint256 private total; // 총 발행 토큰 수
    string public name;
    string public symbol;
    uint8 public decimals;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor (string memory _name, string memory _symbol, uint _totalSupply) {
        total = _totalSupply; //총 공급량
        name = _name;
        symbol = _symbol;
        decimals = 0; // 더 나눌 수 없도록(쪼갤 수 없음)
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0x0), msg.sender, _totalSupply); // 모든 토큰을 배포자(msg.seder)가 가지는 것
    }

    function totalySupply() public view returns (uint256) {
        return total; // 발행한 총 토큰 수 return
    }

    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner]; // owner가 소유한 토큰 수 return
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender]; //spender가 owner로 부터 대리 인출할 수 있는 토큰 수 변환
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balances[msg.sender] >= _value, "balance is not enough!");
        if( (balances[_to] + _value) >= balances[_to] ){ // for over-flow
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        else{
            return false;
            //revert("transfer is disallowed!");
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(allowed[_from][msg.sender] >= _value && balances[_from] >= _value, "lack of balances");
        if( (balances[_to] + _value) >= balances[_to] ){
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        }
        else{
            return false;
        }
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}