const BirdOracle = artifacts.require('BirdOracle');

contract('BirdOracle', (accounts) => {
  let birdOracleInstance;
  beforeEach(async () => {
    birdOracleInstance = await BirdOracle.deployed();
  });
  it('is a test', async () => {
    console.log(accounts);
  });
});
