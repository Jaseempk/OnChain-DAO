//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;

contract FakeNFTMarketPlace{

    mapping(uint256=>address)public tokens;

    uint256 public constant price=0.1 ether;


    function purchase(uint256 _tokenId)public payable{

        require(msg.value>=price,"have to pay the minimum price");
        tokens[_tokenId]=msg.sender;

    }

    function getPrice() public view returns(uint256){
        return price;
    }

    function available(uint256 _tokenId)public returns(bool){
        if(tokens[_tokenId]==address(0)){
            return true;
        }
        return false;
    } 


}