
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/RareSkillsNFT.sol";


contract RareSkillsNFTTest is Test {
    RareSkillsNFT public rareSkillsNFT;
    address owner;
    address user;
    bytes32[] proof;

    function setUp() public{
        owner = address(this);
        user = address(1);
        rareSkillsNFT = new RareSkillsNFT(0xf95c14e6953c95195639e8266ab1a6850864d59a829da9f9b13602ee522f672b);
        proof.push(0xd52688a8f926c816ca1e079067caba944f158e764817b83fc43594370ca9cf62);
    }

    function testWhiteListMerkleMint() public{
        vm.prank(user);
        rareSkillsNFT.whiteListMerkleMint(proof);
        assertEq(rareSkillsNFT.tokenSupply(),1);
        assertEq(rareSkillsNFT.balanceOf(user),1);
        assertEq(rareSkillsNFT.tokenURI(0), "ipfs://QmZZzC4v7M6ZTYnuEgfA5qwHQUTm1DwRF8j3CQKtY6EXMF/0");
    }

    function testDigitalSignatureMint() public{
        vm.prank(0xA3FE755e8FB7cFB97FAda75567cF9d7cef04B6f6);
        rareSkillsNFT.whiteListDigitalSignatureMint(vm.parseBytes('0xbc7e05b0b14d35e7afe90898edb706c04e8bafa50b1a27cb7d777e81aae3521f4a4285a17c83d25621d1f0f89a42d1c9cb9ed882273ca305e97aad90185206fc1b'),0);
        assertEq(rareSkillsNFT.tokenSupply(),1);
        assertEq(rareSkillsNFT.balanceOf(0xA3FE755e8FB7cFB97FAda75567cF9d7cef04B6f6),1);
        assertEq(rareSkillsNFT.tokenURI(0), "ipfs://QmZZzC4v7M6ZTYnuEgfA5qwHQUTm1DwRF8j3CQKtY6EXMF/0");
    }

    function testDigitalSignatureRemint() public{
        vm.prank(0xA3FE755e8FB7cFB97FAda75567cF9d7cef04B6f6);
        rareSkillsNFT.whiteListDigitalSignatureMint(vm.parseBytes('0xbc7e05b0b14d35e7afe90898edb706c04e8bafa50b1a27cb7d777e81aae3521f4a4285a17c83d25621d1f0f89a42d1c9cb9ed882273ca305e97aad90185206fc1b'),0);
        vm.expectRevert('already taken');
        rareSkillsNFT.whiteListDigitalSignatureMint(vm.parseBytes('0xbc7e05b0b14d35e7afe90898edb706c04e8bafa50b1a27cb7d777e81aae3521f4a4285a17c83d25621d1f0f89a42d1c9cb9ed882273ca305e97aad90185206fc1b'),0);
    }

    function testDigitalSignatureNotAllocatedMint() public{
        vm.expectRevert('Ticket not allocated to minter');
        vm.prank(0xA3FE755e8FB7cFB97FAda75567cF9d7cef04B6f6);
        rareSkillsNFT.whiteListDigitalSignatureMint(vm.parseBytes('0xbc7e05b0b14d35e7afe90898edb706c04e8bafa50b1a27cb7d777e81aae3521f4a4285a17c83d25621d1f0f89a42d1c9cb9ed882273ca305e97aad90185206fc1b'),3);
    }

    function testPublicSaleMint() public{
        rareSkillsNFT.openPublicSale();
        vm.prank(user);
        rareSkillsNFT.mint();
        assertEq(rareSkillsNFT.tokenSupply(),1);
        assertEq(rareSkillsNFT.balanceOf(user),1);
        assertEq(rareSkillsNFT.tokenURI(0), "ipfs://QmZZzC4v7M6ZTYnuEgfA5qwHQUTm1DwRF8j3CQKtY6EXMF/0");
    }

    function testRoyalties() public{
        (address x, uint256 fee) = rareSkillsNFT.royaltyInfo(0, 100);
        assertEq(x, owner);
        assertEq(fee, 2_500_000_000_000_000_000); 
    }

    function testOwnerShipTransfer() public{
        // accept ownership without ownership transfer
        vm.expectRevert('no pending ownership transfer');
        vm.prank(user);
        rareSkillsNFT.acceptOwnership();
        rareSkillsNFT.transferOwnership(user);

        // call owner only before accepting ownership
        vm.expectRevert('OnlyOwner: caller is not the Owner');
        vm.prank(user);
        rareSkillsNFT.openPublicSale();

        // try to take pending ownership from another address
        vm.prank(address(2));
        vm.expectRevert('no ownership invitation for you!');
        rareSkillsNFT.acceptOwnership();

        // legit ownership acceptance
        vm.prank(user);
        rareSkillsNFT.acceptOwnership();
        vm.prank(user);
        rareSkillsNFT.openPublicSale();

        assertEq(rareSkillsNFT.publicSaleOpen(), true);
    }
}