const BigNumber = web3.BigNumber;

const Token = artifacts.require('./Token.sol');

require('chai')
    .use(require('chai-bignumber')(BigNumber))
    .should();

contract('Token', accounts => {
    const _name = "Token";
    const _symbol = 'TKN';
    const _decimals = 18;

beforeEach(async function () {
    this.token = await Token.new(_name, _symbol, _decimals);
});

describe('Token has correct constructor arguements', function() {
    it('Has correct token name', async function() {
        const name = await this.token.name();
        name.should.equal(_name);
    });
});
});