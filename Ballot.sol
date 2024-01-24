// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Ballot{
    struct Voter{
        uint weight; // 가중치
        bool voted; // 투표 여부
        uint vote; // 투표 value
    }

    struct Proposal{
        uint voteCount; // 투표수
    }

    address chairperson;
    mapping(address => Voter) public voters; // 투표자 주소를 푸툐자 상세정보로 매핑
    Proposal[] public proposals; // 제안들을 담는 배열

    enum Phase{Init, Regs, Vote, Done} // 단계 설정
    Phase public currentPhase = Phase.Init; // 단계를 나타내는 변수 

    modifier onlyChair() { // 의장만 호출
        require(chairperson == msg.sender, "Only for Owner!");
        _;
    }

    modifier validVoter() { // 등록된 투표자
        require(voters[msg.sender].weight > 0, "Not a Registered Voter");
        _;
    }
    modifier validPhase(Phase reqPhase) {
        require(currentPhase == reqPhase, "phaseError");
        _;
    }

    constructor (uint numProposals) { // numProposals 후보자의 갯수
        chairperson = msg.sender;
        for(uint8 i = 0; i < numProposals; i++){
            proposals.push(Proposal(0)); // **제안 갯수만큼 proposals 배열 초기화
        }
    }

    function register(address voter) public validPhase(Phase.Regs) onlyChair{ // 투표자 주소 등록
        require(currentPhase == Phase.Regs, "It must be the Regsiter Phase");
        if(voter == chairperson){
            voters[voter].weight = 2;
        }
        else{
            voters[voter].weight = 1;
        }
        voters[voter].voted = false; 
    }

    function vote(uint votting) public validPhase(Phase.Vote) validVoter {
        require(currentPhase == Phase.Vote, "It must be the Votting Phase");
        require(voters[msg.sender].voted == false, "Already Voted!");
        require(votting < proposals.length);
        
        voters[msg.sender].vote = votting;
        proposals[votting].voteCount += voters[msg.sender].weight;
        voters[msg.sender].voted = true;
    }

    function reqWinner() public view validPhase(Phase.Done) returns(uint winningProposal){
        require(currentPhase == Phase.Done, "It must be Done Phase");
        uint winning = 0;
        for(uint8 i = 0 ; i < proposals.length ; i++){
            if(proposals[i].voteCount > winning){
                winning = proposals[i].voteCount;
                winningProposal = i;
            }
        }
    }
    
    function advancePhase() public onlyChair{
        if(currentPhase == Phase.Init){
            currentPhase = Phase.Regs;
        }
        else if(currentPhase == Phase.Regs){
            currentPhase = Phase.Vote;
        }
        else if(currentPhase == Phase.Vote){
            currentPhase = Phase.Done;
        }
        else{
            currentPhase = Phase.Init;
        }
    }
}
