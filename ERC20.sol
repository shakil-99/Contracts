pragma solidity ^0.8.0;

import "./IERC20.sol";

contract ERC20 is IERC20{

    string public name;
    string public symbol;
    uint public decimals;

    uint  totalsupply = 1000;
    address owner;

    
    mapping (address => uint) balances;
    mapping(address => mapping(address => uint)) _allowances;

    modifier Owner{
        owner == msg.sender;
        _;
    }

    constructor(string memory _name,string memory _symbol,uint _decimals){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        mint(msg.sender,100 *1e18);
    }


    function totalSupply()public view  override returns(uint){
        return totalsupply;
    }

    function balanceOf(address owner) public view override returns(uint){
       return balances[owner];
    }

    function transfer(address to, uint token)public  override returns(bool){
        // require(token>=,"Send atleast 1 ether");
        balances[msg.sender] -= token;
        balances[to] += token;
        
    }

    function transferfrom(address from ,address to, uint token)public  override returns(bool){
        // require(_allowances[from] [msg.sender] >= token,"please send 1 ether or high");
        _allowances[from][msg.sender] -= token;
        balances[from] -= token;
        balances[to]+= token;
        emit Transfer(from,to,token);
    }

    function allowance(address owner,address spender)public view override returns(uint){
        return _allowances[owner][spender];
    }

    function approve(address spender, uint token)public  override returns(bool success){
         _allowances[msg.sender][spender] = token;
        emit Approve(msg.sender,spender,token);
        return true;
    }

    function mint(address owner, uint tokenTobeMint)internal Owner{
        require(owner == msg.sender,"Only owner can mint");
        totalsupply += tokenTobeMint;
        balances[owner] += tokenTobeMint;
        emit Transfer(address(0),owner,tokenTobeMint);
        approve(msg.sender,balances[msg.sender]);
    }

    function burn(address owner,uint tokenToBeBurn)public Owner{
        require(owner == msg.sender,"only owner can burn");
        totalsupply -= tokenToBeBurn;
        balances[owner]-= tokenToBeBurn;
        emit Transfer(owner,address(0),tokenToBeBurn);
    }
}