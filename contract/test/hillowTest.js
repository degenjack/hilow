const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("hillowTest", () => {
    let owner;
    let org;
    let admin;
    let addr1;
    let addr2;
    let addr3;
    let creator;
    let hillowContract;
    let cardsContract;
    let automationContract;
    let payoutContract;
    let NakshNFT;
    let nakshNft;

    beforeEach(() =>{
        [owner, org, admin, addr1, addr2, addr3, creator] =
            await ethers.getSigners();
        NakshMarket = await ethers.getContractFactory("lyncrentTime");
        nakshM = await NakshMarket.connect(owner).deploy();
    })

});