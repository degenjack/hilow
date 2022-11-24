const hre = require("hardhat");
require("dotenv").config();
const main = async () => {
    // const verify = async (_adrs, _args) => {
    //     await hre.run("verify:verify", {
    //         address: _adrs,
    //         constructorArguments: [_args],
    //     });
    // };
    const HilowFactory = await hre.ethers.getContractFactory("Hilow");
    const Hilow = await HilowFactory.deploy(
        process.env.CHAINLINK_VRF_SUBSCRIPTION_ID,
        "0x3EC2279AFFC8b8B110ff670E1a2BB1BB79626abA",
        "0x5525355d86f20b2B63e78FB9e567aB1DCab61CBF",
        "0x6BcFc80272F141eED6402F28E875082ea9b395b6",
        process.env.MAX_WORDS,
        {
            value: hre.ethers.utils.parseEther("0.1"),
        }
    );
    await Hilow.deployed();
    console.log("Game deployed to -", Hilow.address);

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