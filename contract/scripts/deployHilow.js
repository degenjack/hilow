const hre = require("hardhat");
const main = async () => {
    const verify = async (_adrs, _args) => {
        await hre.run("verify:verify", {
            address: _adrs,
            constructorArguments: [_args],
        });
    };
    const HilowFactory = await hre.ethers.getContractFactory("Hilow");
    const Hilow = await HilowFactory.deploy(
        "0xE8C5A03f58fD66956e4eB52aD76B46E593464fbc",
        "0xCE78Ac298d7Fbeb60E552591e68eF23694160C72",
        "0xB093A21Bbe37BaB5fb0373254b3D8a2923462A8E",
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