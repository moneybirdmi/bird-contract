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

const mainnetDeployScript = async (deployer) => {
  console.log('Deploying to mainnet');
  const usdtAddress = '0xdac17f958d2ee523a2206206994597c13d831ec7';
  await deployer.deploy(BirdOracle, usdtAddress);
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

    case 'mainnet':
      mainnetDeployScript(deployer);
      break;

    default:
      console.log('default: ', network);
  }
};
