// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CourierToken is ERC721, Ownable {
    uint ctr;
    constructor(address initialOwner)
        ERC721("CourierToken", "CRK")
        Ownable(initialOwner)
    {
        ctr = 0;
    }

    function safeMint(address to) public onlyOwner {
        _safeMint(to, ctr);
        ctr += 1;
    }
}