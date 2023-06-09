
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/RareSkillsNFT.sol";
import "../src/NFTStaker.sol";
import "../src/StakeRewardToken.sol";



contract NFTStakerTest is Test {
    NFTStaker public stakingContract;
    RareSkillsNFT public rareSkillsNFT;
    StakeRewardToken public stakeRewardToken;
    address owner;
    address user;
    uint256 constant testTokenId = 0;
    bytes32[] proof;

    function setUp() public{
        owner = address(this);
        user = address(1);
        rareSkillsNFT = new RareSkillsNFT(0xf95c14e6953c95195639e8266ab1a6850864d59a829da9f9b13602ee522f672b);
        stakeRewardToken = new StakeRewardToken();
        stakingContract = new NFTStaker(rareSkillsNFT, address(stakeRewardToken));
        proof.push(0xd52688a8f926c816ca1e079067caba944f158e764817b83fc43594370ca9cf62);
    }

    function testMintAndDeposit() public{
        vm.startPrank(user);
        rareSkillsNFT.whiteListMerkleMint(proof);
        rareSkillsNFT.approve(address(stakingContract), testTokenId);
        stakingContract.depositNFT(testTokenId);

        assertEq(rareSkillsNFT.balanceOf(user), 0);
        assertEq(rareSkillsNFT.balanceOf(address(stakingContract)),1);
        vm.stopPrank();
    }

    function testWithdrawAfterDeposit() public {
        testMintAndDeposit();
        vm.prank(user);
        stakingContract.withdrawNFT(testTokenId);
        
        assertEq(rareSkillsNFT.balanceOf(user), 1);
        assertEq(rareSkillsNFT.balanceOf(address(stakingContract)), 0);
    }

    function testAndTransfer() public{
        vm.startPrank(user);
        rareSkillsNFT.whiteListMerkleMint(proof);
        rareSkillsNFT.safeTransferFrom(user, address(stakingContract), 0);

        assertEq(rareSkillsNFT.balanceOf(user), 0);
        assertEq(rareSkillsNFT.balanceOf(address(stakingContract)), 1);
        vm.stopPrank();
    }

    function testWithdrawAfterTransfer() public {
        testAndTransfer();
        vm.prank(user);
        stakingContract.withdrawNFT(testTokenId);
        
        assertEq(rareSkillsNFT.balanceOf(user), 1);
        assertEq(rareSkillsNFT.balanceOf(address(stakingContract)), 0);
    }

    function testStakeAndReward() public {
        testAndTransfer();
        (uint256 reward, uint256 remainder) = stakingContract.calculateReward(user);
        assertEq(reward, 0);
        assertEq(stakingContract.getStakerInfo(user).nftsStaked, 1);

        vm.warp(block.timestamp + 60*60*24);
        (reward,) = stakingContract.calculateReward(user);
        assertEq(reward, 10*10**18);

        vm.expectRevert("not allowed to mint");
        vm.prank(user);
        stakingContract.collectRewards();

        stakeRewardToken.allowToMint(address(stakingContract));

        vm.prank(user);
        stakingContract.collectRewards();
        uint256 leftovers = stakingContract.getStakerInfo(user).leftover;
        (reward, remainder) = stakingContract.calculateReward(user);
        assertEq(reward, 0);
        assertEq(remainder, leftovers);
        assertEq(stakeRewardToken.balanceOf(user), 10*10**18);
    }

}