// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <=0.9.0;

import "./FoodToken.sol";
import "./CustomerToken.sol";
import "./StoreToken.sol";
import "./CourierToken.sol";

contract Gotur {
    FoodToken public token;
    CourierToken public courierToken;
    CustomerToken public customerToken;
    StoreToken public storeToken;

    mapping(address => uint256) private balances;
    mapping(address => uint256) private stakes;

    mapping(uint => Store) stores;
    uint[] storeIds;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    modifier isNotCustomer() {
        require(customerToken.balanceOf(msg.sender) == 0, "You are already registered as a customer!");
        _;
    }

    modifier isNotStore() {
        require(storeToken.balanceOf(msg.sender) == 0, "You are already registered as a store!");
        _;
    }

    modifier isNotCourier() {
        require(courierToken.balanceOf(msg.sender) == 0, "You are already registered as a courier!");
        _;
    }

    modifier isCustomer() {
        require(customerToken.balanceOf(msg.sender) == 1, "You are not registered as a customer!");
        _;
    }

    modifier isStore() {
        require(storeToken.balanceOf(msg.sender) == 1, "You are not registered as a store!");
        _;
    }

    modifier isCourier() {
        require(courierToken.balanceOf(msg.sender) == 1, "You are not registered as a courier!");
        _;
    }

    constructor(address token20, address courierT, address customerT, address storeT) {
        courierToken = CourierToken(courierT);
        customerToken = CustomerToken(customerT);
        storeToken = StoreToken(storeT);
        token = FoodToken(token20);
    }

    struct Item {
        string name;
        uint price;
        bool isAvailable;
        uint quantity;
    }

    struct Store {
        string name;
        address owner;
        mapping(uint => Item) items;
        uint[] itemIds;
    }

    function getMenu(address ownerAddr) {
        //TODO: Iterate over itemIds and return items presented at those key values in the map
    }

    function addItem(string name, uint price) isStore {
        //TODO: Add the specified item to store's menu
    }

    function disableItem(string name) isStore {
        //TODO: Iterate through itemIds, change the first match with the name
    }
    struct Order {
        //TODO:
        address payable customer;
        address payable store;
        address payable courier;
        uint totalPrice;
        uint courierFee;
    }

    function makeCustomer() public isNotCourier isNotStore{
        customerToken.safeMint(msg.sender);
    }

    function makeStore() public isNotCustomer isNotCourier {
        require(balances[msg.sender] >= 1000, "1000 FTK required to become a store!");
        storeToken.safeMint(msg.sender);
        stakes[msg.sender] += 1000;
        balances[msg.sender] -= 1000;
    }

    function makeCourier() public isNotCustomer isNotStore{
        require(balances[msg.sender] >= 500, "500 FTK required to becoma a courier");
        courierToken.safeMint(msg.sender);
        stakes[msg.sender] += 500;
        balances[msg.sender] -= 500;
    }


    //-------------------Token Functions-------------------------

    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        balances[msg.sender] += amount;

        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        require(token.transfer(msg.sender, amount), "Token transfer failed");

        emit Withdraw(msg.sender, amount);
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}