const Token = artifacts.require('./Token.sol');

const ether = (n) => new web3.BigNumber(web3.toWei(n,'ether'));

module.exports = async function(deployer, network, accounts) {
    const _name = "Token";
    const _symbol = "TKN";
    const _decimals = 18;
    const _totalSupply = 1000;

    await deployer.deploy(Token, _name, _symbol, _decimals,_totalSupply);
    const deployedToken = await Token.deployed();

    return true;
};