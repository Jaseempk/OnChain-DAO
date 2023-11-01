//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";


interface IFakeNFTMarketPlace{

    function available(uint256 _tokenId)external view returns(bool);
    function getPrice() external view returns(uint256) ;
    function purchase(uint256 _tokenId)external payable;
}
interface ICryptoDevsNFT{
    function balanceOf(address owner)external view returns(uint256);
    //returns tokenId of different NFTs owned by same owner in different indexes
    function tokenOfOwnerByIndex(address owner,uint256 index)external view returns(uint256);
}
contract CryptoDevsDAO is Ownable{

    //enum 
    enum Vote{
        Yay,
        Nay
    }

    struct Proposal{
        uint256 nftTokenId;
        uint256 deadline;
        uint256 yayVotes;
        uint256 nayVotes;
        bool executed;
        mapping(uint256=>bool)voters;
    }

    

    IFakeNFTMarketPlace fakeNFTMarketPlace;
    ICryptoDevsNFT cryptoDevsNft;
    uint256 public numProposals;


    mapping(uint256=>Proposal)idToProposal;

    //Modifiers
    modifier onlyDaoMember{
        require(
            cryptoDevsNft.balanceOf(msg.sender)>0,
        "Only members have access"
        );
        _;
    }
    modifier activeProposalOnly(uint256 _proposalIndex){
        require(
            idToProposal[_proposalIndex].deadline>block.timestamp,
        "timeline for voting exceeded"
        );
        _;
    }
    modifier inactiveProposalsOnly(uint256 _proposalIndex){
        require(
            idToProposal[_proposalIndex].deadline<block.timestamp,
        "Wait until the expiry"
        );
        require(
        idToProposal[_proposalIndex].executed==false,
        "proposal already executed"
        );
        _;
    }

    constructor(address _fakeNftmarketPlace,address _cryptoDevsNt)payable{
        fakeNFTMarketPlace=IFakeNFTMarketPlace(_fakeNftmarketPlace);
        cryptoDevsNft=ICryptoDevsNFT(_cryptoDevsNt);
    }

    function createProposal(uint256 _tokenId)public onlyDaoMember returns(uint256){

        require(fakeNFTMarketPlace.available(_tokenId),"NFT_NOT_FOR_SALE");
        Proposal storage  proposal =idToProposal[numProposals];

        proposal.nftTokenId=_tokenId;
        proposal.deadline=block.timestamp + 5 minutes;

        numProposals++;

        return numProposals-1;
    }
    function voteForProposals(uint256 _proposalIndex,Vote vote)public onlyDaoMember activeProposalOnly(_proposalIndex){

        Proposal storage proposal=idToProposal[_proposalIndex];

        uint256 voterNFTBalance=cryptoDevsNft.balanceOf(msg.sender);
        uint256 numVotes=0;

        for(uint i=0;i<voterNFTBalance;i++){
            uint256 tokenId=cryptoDevsNft.tokenOfOwnerByIndex(msg.sender,i);

            if(proposal.voters[tokenId]==false){
                numVotes++;
                proposal.voters[tokenId]=true;
            }
        }
        require(numVotes>0,"You need to vote first");

        if(vote==Vote.Yay){
            proposal.yayVotes+=numVotes;
        }else{
            proposal.nayVotes+=numVotes;
        }
    }
    function executeProposal(uint256 _proposalIndex) external onlyDaoMember inactiveProposalsOnly(_proposalIndex){

        Proposal storage proposal=idToProposal[_proposalIndex];
        uint256 priceOfNft=fakeNFTMarketPlace.getPrice();

        if(proposal.yayVotes>proposal.nayVotes){

            require(address(this).balance>=priceOfNft,"insufficient funds");
            fakeNFTMarketPlace.purchase{value:priceOfNft}(proposal.nftTokenId);

        }
        proposal.executed=true;
    }

    function withdrawEther()public onlyOwner{
        uint256 amount=address(this).balance;
        require(amount>0,"there is nothing to withdraw,Deposit some ETH");
        (bool sent,)=payable(owner()).call{value:amount}("");
        require(sent,"Withdraw failed");

    }

    receive()external payable{}
    fallback()external payable{}


}