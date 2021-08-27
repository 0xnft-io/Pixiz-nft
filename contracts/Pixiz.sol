
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract OwnableDelegateProxy {}

abstract contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/*
    The God of Pixiz has created 10000 unique Pixiz on the Ethereum Blockchain.
    Every Pixiz is a winner.
    Like all living things even Pixiz must pass away.
    Once the sale has completed the contract will:
    - automatically reward the dev address & creator address with 30% of the contract balance
    - leaving 70% of Ether raised during the sale in the contract
    We have removed the withdraw functionality.
    Only holders of Pixiz will reap the contract rewards.
    Every hour one Pixiz must... DIE!
    The owner of the dead Pixiz receives a death rebate. A value proportionally determined by the Ether balance in the contract.
    IE. Each Pixiz death the rebate would be contract-balance / totalSupply()
    @dev
*/
contract Pixiz is AccessControlEnumerable, ERC721Enumerable, ERC721Burnable, ERC721Pausable {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _totalReserveSupply;

    string private _baseTokenURI;
    address proxyRegistryAddress;
    address payable developerAddress;
    address payable creatorAddress;
    event SaleOver(uint256 indexed balance);
    event Death(address indexed owner, uint256 indexed tokenId, uint256 indexed payout);

    string public PROVENANCE = "";

    uint256 public constant MAX_TOKENS = 9840;

    // max 9840 + reserve 160 = 10000 pixiz
    uint256 public constant RESERVE_TOKENS = 160;

    uint256 public constant MAX_TOKENS_PER_PURCHASE = 10;

    uint256 private constant price = 25000000000000000; // 0.025 Ether

    bool public locked = true;
    bool public saleOver = false;

    constructor(string memory baseURI, address payable devAddress, address payable createAddress, address proxyRegistryAddr) public ERC721 (
        "Pixiz", "PIXIZ"
    )
    {
        _baseTokenURI = baseURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
        developerAddress = devAddress;
        creatorAddress = createAddress;
        proxyRegistryAddress = proxyRegistryAddr;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function contractURI() public pure returns (string memory) {
        return "https://pixiz.xzy/api/contract";
    }

    function setProvenanceHash(string memory _provenanceHash) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role to set provenance hash");
        PROVENANCE = _provenanceHash;
    }

    function mint(uint256 _count) public payable {
        require(!locked, "Sale is not active" );
        require(_count > 0, "Invalid count to mint" );
        require(_count <= MAX_TOKENS_PER_PURCHASE, "Exceeds maximum tokens you can purchase in a single transaction");
        require(msg.value >= price * _count, "Ether value sent is not correct");

        for(uint256 i = 0; i < _count; i++){
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, _tokenIdTracker.current() + i);
                _tokenIdTracker.increment();
            } else {
                uint256 contractBalance = address(this).balance;
                uint256 payout = contractBalance/15;
                developerAddress.transfer(payout);
                creatorAddress.transfer(payout);
                saleOver = true;
                emit SaleOver(address(this).balance);
            }
        }
    }

    function flipLock() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role to withdraw tokens");
        locked = !locked;
    }

    function mintTo(address _to, uint256 _count) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "must have minter role to mint reserve tokens");
        for (uint i = 0; i < _count; i++) {
            if (_totalReserveSupply.current() < RESERVE_TOKENS) {
                _safeMint(_to, _tokenIdTracker.current());
                _totalReserveSupply.increment();
                _tokenIdTracker.increment();
            }
        }
    }

    function pixizDeath(uint256 seed) public payable {
        require(hasRole(BURNER_ROLE, _msgSender()), "must have burner role to kill a pixiz");
        require(saleOver, "sale must be over before pixiz death clock begins");
        // todo determine if totalSupply is correct
        uint256 livingPixizCount = totalSupply();
        for (uint256 i = 0; i <= livingPixizCount; i++){
            uint256 tokenId = (seed * (i+1)) / livingPixizCount;
            if (_exists(tokenId)) {
                address payable tokenOwner = payable(ownerOf(tokenId));
                uint256 payout = address(this).balance / livingPixizCount;
                tokenOwner.transfer(payout);
                burn(tokenId);
                emit Death(tokenOwner, tokenId, payout);
                break;
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual
    override(AccessControlEnumerable, ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override(ERC721) returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function burn(uint256 tokenId) public virtual override (ERC721Burnable) {
        require(hasRole(BURNER_ROLE, _msgSender()), "must have burner role to withdraw tokens");
        super.burn(tokenId);
    }
}