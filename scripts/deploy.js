// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const fs = require("fs");

async function main() {
  const taxFee = 5;
  const CROWDFUND = await hre.ethers.getContractFactory("CrowdFund");
  const crowdFund = await CROWDFUND.deploy(taxFee);

  await crowdFund.deployed();

  const address = JSON.stringify({ address: crowdFund.address }, null, 4);

  console.log(address);
  fs.writeFile(
    "./src/artifacts/contractAddress.json",
    address,
    "utf8",
    (err) => {
      if (err) {
        return;
      }
    }
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
