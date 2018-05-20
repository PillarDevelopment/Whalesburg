var WhalesburgToken = artifacts.require("WhalesburgToken");

module.exports = function(deployer) {
  deployer.deploy(WhalesburgToken);
  // const startTime = web3.eth.getBlock(web3.eth.blockNumber).timestamp + 10;
  // const endTime = web3.eth.getBlock(web3.eth.blockNumber).timestamp + 3000;
  // const rate = new web3.BigNumber(1000);
  // const goal = new web3.BigNumber(200);
  // const cap = new web3.BigNumber(2000);
  // const wallet = web3.eth.accounts[0]; // 0x76393ad6569272385963bc9a135356456bbe3f83;
  // deployer.deploy(SampleCrowdsale, startTime, endTime, rate, goal, cap, wallet);
};
