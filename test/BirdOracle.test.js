const { time } = require('@openzeppelin/test-helpers');

const BirdToken = artifacts.require('BirdToken');
const BirdOracle = artifacts.require('BirdOracle');

contract('BirdOracle', (accounts) => {
  let birdToken, birdOracle, startTime;
  beforeEach(async () => {
    startTime = (await time.latest()).add(time.duration.hours(1));
    birdToken = await BirdToken.new();
    birdOracle = await BirdOracle.new(birdToken.address);
  });

  // Main Test:
  // pay bird to oracle and able to read ratings and create request of any address rating.
  it('pay bird to oracle, read any address ratings, create request for any address.', async () => {
    //address and balance
    // const account = accounts[0];
    // const anyAddress = accounts[1];
    // const MAX_AMOUNT = '1000';
    // checkBalance('before ', birdToken, account);
    // await birdToken.approve(birdOracle.address, toWei(MAX_AMOUNT));
    // await birdOracle.sendPayment({ from: account }); //give 1 BIRD to oracle contract
    // checkBalance('after ', birdToken, account);
    // await birdOracle.newChainRequest(anyAddress, 'bird_rating');
    // const rating = await birdOracle.getRatingByAddress(anyAddress);
    // console.log('rating: ', rating.toNumber());
  });

  it('can read rating in due data and can not read after due date.', async () => {
    const account = accounts[0];
    const anyAddress = accounts[1];
    const MAX_AMOUNT = '1000';

    checkBalance('before ', birdToken, account);
    await birdToken.approve(birdOracle.address, toWei(MAX_AMOUNT));
    await birdOracle.sendPayment({ from: account }); //give 1 BIRD to oracle contract
    checkBalance('after ', birdToken, account);

    console.log('in time operations: ');
    await birdOracle.newChainRequest(anyAddress, 'bird_rating');
    let rating = await birdOracle.getRatingByAddress(anyAddress);
    console.log('rating: ', rating.toNumber());

    console.log('due time: ', (await birdOracle.dueDateOf(account)).toString());
    console.log('cur time: ', (await birdOracle.time()).toString());
    console.log('30 days time: ', (await birdOracle.time1()).toString());
    console.log('cur + 30 days time: ', (await birdOracle.time2()).toString());
    await time.increaseTo(
      (await birdOracle.time()).add(time.duration.days(235))
    );
    console.log('cur time: ', (await birdOracle.time()).toString());
    console.log('due time: ', (await birdOracle.dueDateOf(account)).toString());

    console.log('after time operations: ');
    await birdOracle.newChainRequest(anyAddress, 'bird_rating');
    rating = await birdOracle.getRatingByAddress(anyAddress);
    console.log('rating: ', rating.toNumber());
  });
});

const checkBalance = (msg, token, account) =>
  token
    .balanceOf(account)
    .then((b) => console.log(msg, 'balance: ', fromWei(b.toString())));

const checkAllowance = (token, owner, spender) =>
  token
    .allowance(owner, spender)
    .then((b) => console.log('allowed: ', fromWei(b.toString())));

const toWei = (eth) => web3.utils.toWei(eth);
const fromWei = (eth) => web3.utils.fromWei(eth);

//Some other test:
// call all functions in contract
// able to read my rating.
// able to create request on my rating.
// not able to read other rating.
// not able to create request on some other rating.
// able to read other rating after paying bird
// able to create request on other rating after paying bird
