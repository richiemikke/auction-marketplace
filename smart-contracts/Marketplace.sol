// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import './MarketAuction.sol';


//create Market to faciliate bidding and transfer of ownership or original items using ERC-721 NFTs
contract Market is ERC721, ERC721URIStorage, Ownable {
    constructor() ERC721("Market", "MKT") {}
    
   
    using Counters for Counters.Counter;
    Counters.Counter token_ids;

    mapping(uint => MarketAuction) public auctions;

    mapping(uint => bool) isAuctioned;

    //item registered - check if it exists
    modifier itemRegistered(uint token_id) {
        require(_exists(token_id), "item not registered!");
        _;
    }

    function createAuction(uint token_id, address _owner) public itemRegistered(token_id) onlyOwner {
        require(!isAuctioned[token_id], "Token is already auctioned");
        auctions[token_id] = new MarketAuction(payable(_owner));
        isAuctioned[token_id] = true;
    }

    function getAuction(uint token_id) public view itemRegistered(token_id) returns(MarketAuction auction) {
        return auctions[token_id];
    }
    
    //pass on URI that contains metadata about the item.  only owner can call this to register the item
    //token_ids.increment();  //create new token id.. increment by 1
    //uint token_id = token_ids.current();  //unique token_id (1 higher than previous)
    function registerItem(address to, string memory _tokenURI) public payable onlyOwner {
        require(bytes(_tokenURI).length > 0, "Enter a valid token URI");
        uint _id = token_ids.current();
        token_ids.increment();
        _mint(to, _id);  //mint token and pass on id
        _setTokenURI(_id, _tokenURI);  //set URI
        createAuction(_id, to);  //run create auction function
    }

    //end aunction for particular token id.  itemRegistered checks if token already exists
    function endAuction(uint token_id) public payable onlyOwner itemRegistered(token_id) {
        MarketAuction auction = getAuction(token_id);
        (bool success) = auction.auctionEnd();
        require(success, "Failed to end auction");
        safeTransferFrom(ownerOf(token_id), auction.highestBidder(), token_id);
        isAuctioned[token_id] = false;
    }

    function auctionEnded(uint token_id) public view returns(bool) {
        MarketAuction auction = auctions[token_id];
        return auction.ended();
    }

    function highestBid(uint token_id) public view itemRegistered(token_id) returns(uint) {
        MarketAuction auction = auctions[token_id];
        return auction.highestBid();
    }

    function pendingReturn(uint token_id, address sender) public view itemRegistered(token_id) returns(uint) {
        MarketAuction auction = auctions[token_id];
        return auction.pendingReturn(sender);
    }

    function withdraw(uint token_id) public payable itemRegistered(token_id) {
        MarketAuction auction = auctions[token_id];
        require(auction.pendingReturn(msg.sender) > 0, "No amount to withdraw");
        (bool success) = auction.withdraw();
        require(success, "Withdrawal failed");

    }
    
    //allows users to send in ether and send to aunction contract
    //function sould be public payable to accept ether
    function bid(uint token_id) public payable itemRegistered(token_id) {
        MarketAuction auction = auctions[token_id];
        //accepting the address from the msg.sender
        auction.bid{value: msg.value}(payable(msg.sender));
    }


    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }


}