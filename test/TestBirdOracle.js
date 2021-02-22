const BirdOracle = artifacts.require('BirdOracle');

contract('BirdOracle', (accounts) => {
  let birdOracleInstance;
  beforeEach(async () => {
    birdOracleInstance = await BirdOracle.deployed();
  });
  it('is a call', async () => {
    const balance = await birdOracleInstance.getLoan.call();
    console.log(balance.toNumber());
  });
  it('is a transaction', async () => {
    await birdOracleInstance.getLoan.sendTransaction();
  });
});
