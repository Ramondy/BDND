pragma solidity >=0.4.25;

interface ERC20 {

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    function totalSupply() external constant returns (uint);
    function balanceOf(address tokenOwner) external constant returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function allowance(address tokenOwner, address spender) external constant returns (uint remaining);
}

contract myToken is ERC20 {

    // Optional variables in ERC20:
    string public constant name = "DatActors Token";
    string public constant symbol = "DAX";
    uint8 public constant decimals = 18;  // 18 is the most common number of decimal places

    // necessary variables to implement ERC-20:
    uint _totalSupply; // store total supply
    mapping (address => uint) balances; // keep track of each account's balance
    mapping (address => mapping (address => uint)) allowances; // keep track of allowances granted by each account to other accounts

    // note: events are inherited from interface, no need to repeat code

    constructor(uint amount) public {
        _totalSupply = amount;
        balances[msg.sender] = amount;
    }

    // implement interface functions:
    // getter for _totalSupply
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    // getter for individual balance
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    // transfer from own account
    function transfer(address to, uint tokens) public returns (bool success) {
        if (balances[msg.sender] >= tokens) {
            balances[msg.sender] -= tokens;
            balances[to] += tokens;
            emit Transfer(msg.sender, to, tokens);
            return true;
        }
        else {
            revert();
        }
    }

    // transfer from third-party account, subject to allowance
    function transferFrom(address from, address to, uint tokens) external returns (bool success) {
        if (balances[from] >= tokens && allowances[from][msg.sender] >= tokens) {
            balances[from] -= tokens;
            allowances[from][msg.sender] -= tokens;
            balances[to] += tokens;
            emit Transfer(msg.sender, to, tokens);
            return true;
        }
        else {
            revert();
        }
    }

    // approve allowance to a third-party spender
    function approve(address spender, uint tokens) external returns (bool success) {
        allowances[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) external constant returns (uint remaining) {
        return allowances[tokenOwner][spender];
    }

}