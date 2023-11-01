const hre=require("hardhat");


async function sleep(ms){
  await new Promise((resolve)=>setTimeout(resolve,ms))
}

async function main(){

  //Deploy CryptoDevsNFT conrtact
  const cryptoDevsNFT=await hre.ethers.deployContract("CryptoDevsNFT");
  await cryptoDevsNFT.waitForDeployment()
  console.log("deployed contract address of cryptoDevsNFT:",cryptoDevsNFT.target);

  //Deploy FakeNFTMarketplace contract
  const fakeNFTMarketPlace=await hre.ethers.deployContract("FakeNFTMarketPlace");
  await fakeNFTMarketPlace.waitForDeployment();
  console.log("deployed fakeNFTMarketPlace address:",fakeNFTMarketPlace.target);

  //Deploy CryotoDevsDAO contract
  const amount=hre.ethers.parseEther("0.05");
  const cryptoDevsDAO=await hre.ethers.deployContract("CryptoDevsDAO",[fakeNFTMarketPlace.target,cryptoDevsNFT.target],{value:amount});
  await cryptoDevsDAO.waitForDeployment();
  console.log("CryptoDevsDAO deployed to:",cryptoDevsDAO.target);

  //sleep to let the etherscan catch up deployments
  await sleep(30*1000);

  //verifying cryptoDevsNFT
  await hre.run("verify:verify",{
    address:cryptoDevsNFT.target,
    constructorArguments:[],
  })

  //verifying FakeNFTmarketPlace
  await hre.run("verify:verify",{
    address:fakeNFTMarketPlace.target,
    constructorArguments:[]
  })

  //verifying CryptoDevsDAO
  await hre.run("verify:verify", {
    address: cryptoDevsDAO.target,
    constructorArguments: [
      fakeNFTMarketPlace.target,
      cryptoDevsNFT.target,
    ],
  });
}
main().catch((e)=>{
  console.error(e);
  process.exit=1;
})