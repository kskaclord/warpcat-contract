// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * WarpCat — Base (8453) NFT
 * - maxSupply = 10_000
 * - mint(uint256 fid) external payable
 * - each FID can mint only once (1 FID = 1 NFT)
 * - fixed mintPrice (owner can update)
 * - owner withdraw
 * - baseURI settable (tokenURI = baseURI + tokenId)
 */

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract WarpCat is ERC721Enumerable, Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 10_000;

    uint256 public mintPrice = 0.0005 ether;
    bool    public mintEnabled = true;

    string private _baseTokenURI;
    string public contractURI; // collection-level metadata (optional)

    // Farcaster: 1 FID = 1 mint
    mapping(uint256 => bool) public fidMinted;

    event Minted(address indexed minter, uint256 indexed tokenId, uint256 indexed fid);
    event MintEnabled(bool enabled);
    event MintPriceUpdated(uint256 newPrice);
    event BaseURIUpdated(string newBaseURI);
    event ContractURIUpdated(string newContractURI);
    event Withdraw(address indexed to, uint256 amount);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        _baseTokenURI = baseURI_;
        contractURI = contractURI_;
    }

    // --- mint ---
    function mint(uint256 fid) external payable nonReentrant {
        require(mintEnabled, "Mint disabled");
        require(totalSupply() < MAX_SUPPLY, "Sold out");
        require(!fidMinted[fid], "Already minted");
        require(msg.value == mintPrice, "Wrong price");

        fidMinted[fid] = true;

        uint256 tokenId = totalSupply() + 1;
        _safeMint(msg.sender, tokenId);

        emit Minted(msg.sender, tokenId, fid);
    }

    // --- owner admin ---
    function setMintEnabled(bool enabled) external onlyOwner {
        mintEnabled = enabled;
        emit MintEnabled(enabled);
    }

    function setMintPrice(uint256 newPriceWei) external onlyOwner {
        mintPrice = newPriceWei;
        emit MintPriceUpdated(newPriceWei);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    function setContractURI(string calldata newContractURI) external onlyOwner {
        contractURI = newContractURI;
        emit ContractURIUpdated(newContractURI);
    }

    function ownerMint(address to, uint256 qty) external onlyOwner {
        for (uint256 i = 0; i < qty; i++) {
            require(totalSupply() < MAX_SUPPLY, "Sold out");
            uint256 tokenId = totalSupply() + 1;
            _safeMint(to, tokenId);
            emit Minted(to, tokenId, 0); // fid=0 (reserved)
        }
    }

    function withdraw(address payable to) external onlyOwner {
        uint256 bal = address(this).balance;
        (bool ok, ) = to.call{value: bal}("");
        require(ok, "Withdraw failed");
        emit Withdraw(to, bal);
    }

    // --- metadata ---
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}
