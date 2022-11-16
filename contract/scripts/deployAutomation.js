const hre = require("hardhat");
const main = async () => {
    const verify = async (_adrs, _args) => {
        await hre.run("verify:verify", {
            address: _adrs,
            constructorArguments: [_args],
        });
    };
    // const [deployer] = await ethers.getSigners(); //get the account to deploy the contract

    // console.log("Deploying contracts with the account:", deployer.address);

    const counterFactory = await ethers.getContractFactory('Counter')
    const charCollection = await counterFactory.deploy(10, "0x1B617fE902E982FBd3c28680AEDe0Cc7098c8b2A")
    await charCollection.deployed()
    console.log('Automation Contract deployed to:', charCollection.address)
    // await charCollection.deployed();
    // await hre.run("verify:verify", {
    //     address: charCollection.address,
    //     constructorArguments: [15, "0x66Dd3f2E70a7B5f9Ea040D10f564199D08378F39"],
    // });
}

const runMain = async () => {
    try {
        await main()
        process.exit(0)
    } catch (error) {
        console.log(error)
        process.exit(1)
    }
}

runMain()