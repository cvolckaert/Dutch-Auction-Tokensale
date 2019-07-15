pragma solidity ^0.5.8;

import "node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";

contract Token is ERC20,ERC20Detailed{
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint _totalSupply)
    ERC20Detailed(_name, _symbol, _decimals)
        public
        {
            _mint(msg.sender,_totalSupply);

        }


}