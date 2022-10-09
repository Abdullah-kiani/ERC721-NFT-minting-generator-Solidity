// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Naruto is ERC721, Pausable, ERC721URIStorage, Ownable {

    constructor() ERC721("Naruto", "LEAF") {
        setPrice(10 wei);
        setwhitelistPrice(1 wei);
        setTotalsupply(100);
        setWhitelistLimit(40);
        setplatformLimit(10);
        setperaddressLimit(5);
    }
    
    //  mappings
    
    mapping (address => bool) whitelistedAddresses;
    mapping (address => bool) adminAddresses;
    mapping (uint => bool) tokenids;

    //    variables 

    uint public TotalSupply;
    uint public price;
    uint public whitelistprice;
    uint public whitelistCount;
    uint public publicCount;
    uint public adminCount;
    uint public whitelistLimit;
    uint public platformLimit; 
    uint public peraddressLimit;   
    bool public publicsalesStatus;
    bool public presalesStatus = true;
    
    //events
    event NFTminted(uint _tokenid, address _address);

    /*
    these functions are used to set price, total supply and minting limit by owner
    */
    function setPrice(uint _price) public onlyOwner {
        price = _price;
    }
    function setwhitelistPrice(uint _price) public onlyOwner {
        whitelistprice = _price;
    }
    function setTotalsupply(uint _supply) public onlyOwner {
        TotalSupply = _supply;
    }
    function setWhitelistLimit(uint _limit) public onlyOwner {
        require(_limit <= (TotalSupply - platformLimit ),"enter less than total supply available");
        whitelistLimit = _limit;
    }
    function setplatformLimit(uint _limit) public onlyOwner {
        require(_limit <= (TotalSupply - whitelistLimit ),"enter less than total supply available");
        platformLimit = _limit;
    }
    function setperaddressLimit(uint _limit) public onlyOwner {
        peraddressLimit = _limit;
    }

    /*
    *modifiers used to grant access in minting functions
    *limiting the number of nfts minted as requirement
    */

    modifier isWhitelisted() {
        require(whitelistedAddresses[msg.sender], "not a whitelisted user");
        _;
    }
    modifier ispublicUser() {
        require(!whitelistedAddresses[msg.sender] || !adminAddresses[msg.sender], "NOt a public user");
        _;
    }
     modifier onlyPlatform() {
        require(adminAddresses[msg.sender] || msg.sender == Ownable.owner(), "Unauthorized Address");
        _;
    }
    modifier mintLimit(){
        require(balanceOf(msg.sender)<peraddressLimit);
        _;
    }

    /*
        functions for owner to add / remove:
        *whitelist admins
        *whitelist users 
    */
   function addAdminAddress(address _Address) public onlyOwner {
       adminAddresses[_Address] = true;
   }
   
   function removeAdminAddress(address _Address) public onlyOwner{
       adminAddresses[_Address] = false;
   }
   
    function addWhitelistedAddress(address _Address) public onlyOwner {
       whitelistedAddresses[_Address] = true;
   }
   
   function removeWhitelistedAddress(address _Address) public onlyOwner{
       whitelistedAddresses[_Address] = false;
   }
   /*
   Function to set the sale status
   */
    function FlipsalesStatus (bool _status) public onlyOwner{
        if (_status){
            publicsalesStatus = true;
            presalesStatus = false;
        }
        else{
            publicsalesStatus = false;
            presalesStatus = true;
        }
    }
    /*
    pause and unpause functions
    */
    function updateContractpausestatus (bool _status) public onlyOwner {
        if (_status) {
        _pause();    
        }
        else {
        _unpause();
        }
    }
    /*
    minting functions
    * these require to be in limit set in the set platformlimit function

    *requires sales status to be true

    *the token id is required to be unique then those already registered

    *count limit updates after each mint

    *the minting and settokenURI functions are executed 

    *event is triggered

    * whitelist and Public minting are payable function 
    */
    function platformMint(uint tokenid,string memory uri) public onlyPlatform  {
        require( presalesStatus ,"Pre-sales are not On");
        require(adminCount <= platformLimit,'limit reached');
        adminCount +=1;
        Mint(tokenid, uri);
    }

    function whitelistuserMint(uint tokenid, string memory uri) public payable isWhitelisted {
        require(presalesStatus ,"Pre-sales are not On");
        require(whitelistCount <= whitelistLimit,'limit reached');
        require(msg.value >= whitelistprice,"Ether value sent is not correct");
        whitelistCount +=1;
        Mint(tokenid, uri);
    }
    function publicuserMint(uint tokenid,string memory uri) payable public ispublicUser {
        require(publicsalesStatus == true ,"public sales are not On");
        require(msg.value >= price,"Ether value sent is not correct");
        require(publicCount <= (TotalSupply -(adminCount + whitelistCount)),'limit reached');
        publicCount +=1;
        Mint(tokenid, uri);
    }
// this mint is used to do the repetititive code in the Minting functions
    function Mint(uint _tokenid, string memory _uri) internal mintLimit whenNotPaused{
        require(!tokenids[_tokenid],'token id already acquired');
        _mint(msg.sender , _tokenid);
        _setTokenURI(_tokenid, _uri);
        emit NFTminted(_tokenid, msg.sender);
        tokenids[_tokenid]=true;
    }
    // withdraw function transfer contract balance to owner
    
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
}
// Required by Solidity 
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

}
