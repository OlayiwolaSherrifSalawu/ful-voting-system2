const hre = require("hardhat");

async function main() {
  console.log("Deploying FUL Voting System...");
  
  const FULVotingSystem = await hre.ethers.getContractFactory("FULVotingSystem");
  const votingSystem = await FULVotingSystem.deploy();
  
  await votingSystem.waitForDeployment();
  
  console.log("Contract deployed to:", await votingSystem.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});