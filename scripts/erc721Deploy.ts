// Imports
// ========================================================
import { ethers } from "hardhat";

// Deployment Script
// ========================================================
const main = async () => {
  // Replace these variables as needed  
  const verifierContract = "ERC721Verifier";
  const verifierName = "ERC721zkMint";
  const verifierSymbol = "zkERC721";

  // Deploy contract
  const ERC721Verifier = await ethers.getContractFactory(verifierContract);
  const erc721Verifier = await ERC721Verifier.deploy(
    verifierName,
    verifierSymbol
  );
  await erc721Verifier.deployed();

  // Output result
  console.log(`${verifierName} deployed to ${erc721Verifier.address}`);
}

// Init
// ========================================================
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.log(error?.message);
  console.error(error);
  process.exitCode = 1;
});
