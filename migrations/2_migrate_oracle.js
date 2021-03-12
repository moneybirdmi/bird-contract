const BirdOracle = artifacts.require('BirdOracle');
const BirdToken = artifacts.require('BirdToken');

const localDeployScript = async (deployer) => {
  console.log('Deploying to ganache');
  //todo what not running at once?
  await deployer.deploy(BirdToken);
  await deployer.deploy(BirdOracle, BirdToken.address);
  console.log('done');
};

const kovanDeployScript = async (deployer) => {
  console.log('Deploying to kovan');
  const birdTokenAddress = '0xee426697da6885e7c8c0d48255de85ac412dd7b9';
  await deployer.deploy(BirdOracle, birdTokenAddress);
};
module.exports = async (deployer, network) => {
  switch (network) {
    case 'development':
    case 'develop':
      localDeployScript(deployer);
      break;

    case 'kovan':
      kovanDeployScript(deployer);
      break;

    default:
      console.log('default: ', network);
  }
};
