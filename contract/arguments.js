require("dotenv").config();

module.exports = [
  process.env.CHAINLINK_VRF_SUBSCRIPTION_ID,
  process.env.TEAM_CONTRACT_ADDRESS,
  process.env.NFT_CONTRACT_ADDRESS,
];
