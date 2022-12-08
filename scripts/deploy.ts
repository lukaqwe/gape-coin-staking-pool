import { ethers } from "hardhat";

async function main() {
  const rewardPerStakedAmount = 500; // you get half of your staked amount in exactly
  const withdrawalPeriod = 30; // half a minute
  const vaultAddress = "0xf371efda1a6ebe7947b2e9c5417fd16c30612555";
  const gapeCoinAddress = "0xA0290118D3014F6d9b6f2E9430EAeDe507C949C1";
  // TO THE MOON 🚀🚀🚀

  const stakingPoolFactory = await ethers.getContractFactory("StakingPool");

  const stakingPool = await stakingPoolFactory.deploy(
    rewardPerStakedAmount,
    withdrawalPeriod,
    vaultAddress,
    gapeCoinAddress
  );

  await stakingPool.deployed();

  console.log("StakingPool deployed to:", stakingPool.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});