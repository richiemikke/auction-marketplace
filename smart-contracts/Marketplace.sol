// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import './MarketAuction.sol';


//create Market to faciliate bidding and transfer of ownership or original items using ERC-721 NFTs
contract Market is ERC721, ERC721URIStorage {
    constructor() ERC721("Market", "MKT") public {}
    
   
    // this contract is designed to have the owner of this contract (foundation) to pay for most of the function calls
    //deployer of the contract - address of the foundation
    // (all but bid and withdraw)
    address payable foundation_address = address(uint160(ownerOf()));

    //using Counters for Counters.Counter;
    //Counters.Counter token_ids;

    mapping(uint => MarketAuction) public auctions;

    //item registered - check if it exists
    modifier itemRegistered(uint token_id) {
        require(_exists(token_id), "item not registered!");
        _;
    }

    function createAuction(uint token_id) public onlyOwner {
        auctions[token_id] = new MarketAuction(foundation_address);
    }

    function getAuction(uint token_id) public view itemRegistered(token_id) returns(MarketAuction auction) {
        return auctions[token_id];
    }
    
    //pass on URI that contains metadata about the item.  only owner can call this to register the item
    //token_ids.increment();  //create new token id.. increment by 1
    //uint token_id = token_ids.current();  //unique token_id (1 higher than previous)
    function registerItem(string memory tokenURI) public payable onlyOwner {
        uint _id = totalSupply();
        _mint(msg.sender, _id);  //mint token and pass on id
        _setTokenURI(_id, tokenURI);  //set URI
        createAuction(_id);  //run create aunction function
    }

    //end aunction for particular token id.  checked to see if it exists first
    function endAuction(uint token_id) public onlyOwner itemRegistered(token_id) {
        MarketAuction auction = getAuction(token_id);
        auction.auctionEnd();
        safeTransferFrom(owner(), auction.highestBidder(), token_id);
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
    
    //allows users to send in ether and send to aunction contract
    //function sould be public payable to accept ether
    function bid(uint token_id) public payable itemRegistered(token_id) {
        MarketAuction auction = auctions[token_id];
        //accepting the address from the msg.sender
        auction.bid.value(msg.value)(msg.sender);
    }

}