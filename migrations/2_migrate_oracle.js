const BirdOracle = artifacts.require('BirdOracle');
const BirdToken = artifacts.require('BirdToken');

module.exports = async (deployer) => {
  const birdTokenAddress = '0xac12....';
  await deployer.deploy(BirdOracle, birdTokenAddress);
};

// await deployer.deploy(BirdToken);
// await deployer.deploy(BirdOracle, BirdToken.address);
