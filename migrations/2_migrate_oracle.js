const BirdOracle = artifacts.require('BirdOracle');

module.exports = async (deployer) => {
  const birdTokenAddress = '0xee426697da6885e7c8c0d48255de85ac412dd7b9';
  await deployer.deploy(BirdOracle, birdTokenAddress);
};
