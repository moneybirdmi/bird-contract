const BirdOracle = artifacts.require('BirdOracle');
const BirdToken = artifacts.require('BirdToken');

module.exports = async (deployer) => {
  await deployer.deploy(BirdToken);
  await deployer.deploy(BirdOracle, BirdToken.address);
};
