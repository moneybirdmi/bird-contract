const BirdOracle = artifacts.require('BirdOracle');

module.exports = function (deployer) {
  deployer.deploy(BirdOracle);
};
