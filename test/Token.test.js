const BigNumber = web3.utils.BN;
const bnChai = require('bn-chai');

const chai = require('chai')
chai.should()
chai.use(bnChai(BigNumber));

const Token = artifacts.require('./Token.sol');

contract('Token', async() => {
    const _name = "Token";
    const _symbol = 'TKN';
    const _decimals = 18;
    const _totalSupply = 1000;

beforeEach(async function () {
    this.token = await Token.new(_name, _symbol, _decimals,_totalSupply);
});

describe('Token has correct constructor arguements', function() {
    it('Has correct token name', async function() {
        const name = await this.token.name();
        name.should.equal(_name);
    });

    it('Has correct token symbol', async function() {
        const symbol = await this.token.symbol()
        symbol.should.equal(_symbol)
    });

    it('Has correct token decimals', async function() {
        const decimals = await this.token.decimals()
        decimals.should.be.eq.BN(_decimals)
    });

    it('Has correct token total supply', async function() {
        const tokenSupply = await this.token.totalSupply()
        tokenSupply.should.be.eq.BN(_totalSupply);
    });
});
});