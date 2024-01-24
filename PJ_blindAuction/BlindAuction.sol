// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// msg.sender == beneficiary.
// beneficiary 가 경매 단계 변경 가능.
// init -> bidding -> reveal -> done.
// 입찰자는 한번씩 입찰가능.
// 입찰은 입찰가와 비밀번호를 이용한 해시값으로 한다 it is blind.
// 입찰시 입찰가 이상의 예치금을 전송해야함.
// reveal 단계.
// 각 입찰자는 자신의 입찰가를 공개한다. 
// 입찰가와 비밀번호의 해시값을 확인해 다르면, 예치금을 돌려준다.
// 예치금에서 입찰가를 뺀 나머지는 되돌려준다.
// 최고 입찰가를 비교한다.
// 최고 입찰가보다 작으면, 입찰 탈락자의 입찰금 반환을 위한 매핑을 추가한다.
// done 단계 
// 최고 입찰가를 beneficiary에게 전송한다.
// 입찰 탈락자는 자신의 입찰금을 출금한다. 

// 사용자는 bidding 전에, 자신의 비밀번호와 입찰가를 해시해서 blinded bid를 생성해야하나?
// bid -> blinded bid(해시값??), deposit(예치금)
// reveal -> 자신의 bidding 을 공개 + 비밀번호(본인이 해시 할 때 사용했던 비밀번호)
//        -> 공개된 bidding을 사용해서 최대값 구함

contract BlindAuction{
    struct Bid {
        bytes32 blindedBid;
        uint deposit;
        bool done;
    }

    // Init - 0; Bidding - 1; Reveal - 2; Done - 3
    enum Phase { Init, Bidding, Reveal, Done}
    Phase public currentPhase = Phase.Init;

    // 소유자
    address payable public beneficiary;

    // 최고 입찰가, 입찰자
    bool public transfer_bid = false;
    bool public first_highest = true;

    address public highestBidder;
    uint public highestBid = 0;

    // 입찰자의 입찰 해시값과 예치금에 대한 매핑
    mapping(address => Bid) public bids;

    // 입찰금 반환을 위한 매핑
    mapping(address => uint) pendingReturns;

    // Events
    event AuctionEnded(address winner, uint highestBid);
    event BiddingStarted();
    event RevealStarted();
    event AuctionInit();
    event SuccessWithdraw();

    // Modifiers
    // 경매 단계별로 실행 가능한 함수를 제한하는 modifier
    // 소유자만 실행 가능하게 제어함

    modifier onlyOwner () {
        require(beneficiary == msg.sender, "Only sender can access!");
        _;
    }

   modifier onlyBidding(){ // Bidding 단계만 가능
        require(currentPhase == Phase.Bidding, "This function can be excuted when Phase Bidding");
        _;
   }

   modifier onlyReveal(){ // Reveal 단계만 가능
        require(currentPhase == Phase.Reveal,"This function can be excuted when Phase Reveal");
        _;
   }

   modifier onlyDone(){
        require(currentPhase == Phase.Done, "This function can be excuted when Phase Done");
        _;
   }

    constructor(){
        beneficiary = payable(msg.sender);
    }


    // 경매 단계 변경, 각 단계에 맞게 이벤트 발생(BiddingStarted, RevealStarted, AuctionInit) 
    // AuctionEnded 이벤트는 auctionEnd() 함수에서 발생
    function AdvancePhase() public onlyOwner {  // beneficiary만 가능 button[advancePhase]
        if(currentPhase == Phase.Init){
            currentPhase = Phase.Bidding;
            emit BiddingStarted();
        }
        else if(currentPhase == Phase.Bidding){
            currentPhase = Phase.Reveal;
            emit RevealStarted();
        }
        else if(currentPhase == Phase.Reveal){
            currentPhase = Phase.Done;
        }
        else{ //currentPhase == Phase.Done
            currentPhase = Phase.Init;
            emit AuctionInit();
        }
    }

    function Hashing(uint value, bytes32 secret) public pure returns(bytes32 Hashed){
        //uint value = _value * 1 ether;
        Hashed = keccak256(abi.encodePacked(value, secret));
        return Hashed;
    }

    // 입찰 정보 저장
    // Bidding Phase
    // 입찰할 때 blindBid와 예치금을 입찰함
    function bid(bytes32 _blindBid) public payable onlyBidding{ // button[bid]
        require(bids[msg.sender].done == false, "You Already Bidding!");

        bids[msg.sender].done = true; // bidding 함
        bids[msg.sender].blindedBid = _blindBid;
        bids[msg.sender].deposit = msg.value;
    }

    // 입찰가와 비밀번호 확인
    // 예치금에서 입찰가를 뺀 나머지는 되돌려준다
    // 최고 입찰가를 비교
    // 최고 입찰가보다 작으면 입찰 탈락자의 입찰금 반환을 위한 매핑을 추가
    function reveal(uint _value, bytes32 secret) public payable onlyReveal { // button[reveal]
        uint value = _value * 1 ether;
        uint refund = 0; // 환불금
        // 이전에 받았던 해시값과, reveal 단계에서 제출한 값을 해시한 값을 비교함
        if(bids[msg.sender].blindedBid == keccak256(abi.encodePacked(_value, secret))){
            refund = bids[msg.sender].deposit - value; // 예치금 - 입찰가
            // 예치금에서 입찰가를 뺀 나머지는 되돌려준다. 
            payable(msg.sender).transfer(refund);
            if(value > highestBid){ // 입찰가가 최고 입찰가인 경우 + 최고입찰자가 바뀐 경우
                if(first_highest == false) // 만약 처음이라면 highestBidder가 NULL이기 때문에 
                    pendingReturns[highestBidder] = highestBid; // 최고 입찰자가 바뀌었으니 돌려줘야지

                first_highest = false; // 이제는 처음이 아니기 때문,,,
                highestBid = value;
                highestBidder = msg.sender;
            }
            else{ // 최고 입찰가가 아닌 경우
                pendingReturns[msg.sender] = value;
            }
        }
        else{
            // 해시 값이 다르면 예치금을 되돌려준다. 
            payable(msg.sender).transfer(bids[msg.sender].deposit);
            revert("Wrong password or others");
        }
    }

    // 낙찰되지 않은 입찰금 반환
    function withdraw() public onlyDone payable { //button[withdraw]
        //var cash_withdraw = pendingReturns[msg.sender];
        if(pendingReturns[msg.sender] > 0){
            payable(msg.sender).transfer(pendingReturns[msg.sender]);
            pendingReturns[msg.sender] = 0;
            emit SuccessWithdraw();
        }
        else{ // 이미 출금했거나, winner인 경우에는 반환할 돈이 없음.
            revert("You already withraw or you are winner");
        }
    }

    // 소유자(수혜자)에게 가장 높은 입찰가를 보내고 경매를 종료 
    // AuctionEnded 이벤트 발생
    function auctionEnd() public onlyDone { //button[show winning bid]
        if(transfer_bid == false){ // 한번도 show_winning bid 가 눌리지 않은 상태
            beneficiary.transfer(highestBid); 
        }
        transfer_bid = true; 
        emit AuctionEnded(highestBidder, highestBid);
    }
}
