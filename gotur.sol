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

    mapping(address => Store) stores;
    address[] storeOwners;

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
        uint nextItemId;
        uint[] itemIds;
        uint[] orders;
    }

    event newOrder(address store);
    uint nextOrderId;
    Order[] orders;

    mapping(address => uint[]) orderHistory;


    function getMenu(address ownerAddr) public view isCustomer returns (Item[] memory){
        //TODO: Iterate over itemIds and return items presented at those key values in the map
        Store storage store = stores[ownerAddr];
        Item[] memory ret = new Item[](store.nextItemId);
        for (uint i = 0; i < store.nextItemId; i++) {
            if (store.items[i].isAvailable) {
                ret[i] = store.items[i];
            }
        }
        return ret;
    }

    function addItem(string memory _name, uint _price, uint _quantity) public isStore {
        //TODO: Add the specified item to store's menu
        Store storage store = stores[msg.sender];
        Item storage itm = store.items[store.nextItemId];
        itm.name = _name;
        itm.price = _price;
        itm.isAvailable = true;
        itm.quantity = _quantity;
        store.nextItemId += 1;
    }

    function setQuantity(string memory name, uint quantity) public isStore {

    }

    function disableItem(uint itemId) public isStore {
        //TODO: Iterate through itemIds, change the first match with the name
        Store storage store = stores[msg.sender];
        Item storage itm = store.items[itemId];
        itm.isAvailable = !itm.isAvailable;
    }
    struct Order {
        uint orderId;
        address customer;
        address store;
        address courier;
        uint totalPrice;
        uint courierFee;
        uint[] itemIds;
        uint[] quantitities;
        bool couirerFound;
        bool storeApproved;
        bool courierPickedUp;
        bool isDelivered;
        bool isCanceled;
        bool isComplete;
        string mapAddress;
        uint issuetime;
        uint storeApproveTime;
    }

    function placeOrder(address storeAddress, uint[] memory _itemIds, uint[] memory _quantities, string memory _mapAddress, uint _courierFee, uint _totalPrice) public isNotStore isNotCourier {
        require(balances[msg.sender] >= _totalPrice, "Insufficient funds");
        Order memory order;
        order.customer = msg.sender;
        require(storeToken.balanceOf(storeAddress) == 1, "Invalid store address!");
        order.store = storeAddress;
        order.courierFee = _courierFee;
        order.totalPrice = _totalPrice;
        order.issuetime = block.timestamp;
        order.itemIds = _itemIds;
        order.quantitities = _quantities;
        order.mapAddress = _mapAddress;
        order.orderId = nextOrderId;

        nextOrderId += 1;

        orders.push(order);
        orderHistory[msg.sender].push(order.orderId);

        balances[msg.sender] -= _totalPrice;

        emit newOrder(storeAddress);
        
    }

    function approveOrder(uint _orderId) public isStore {
        Store storage store = stores[msg.sender];
        Order memory order;
        for (uint i = 0; i < store.orders.length; i++) {
            if (store.orders[i] == _orderId) {
                order  = orders[i];
            }
        }
        if (order.orderId != _orderId) {
            revert("Order not found");
        }
        if (order.isCanceled) {
            revert("Order was canceled by the user");
        } else {
            order.storeApproved = true;
            order.storeApproveTime = block.timestamp;
        }
        
    }

    function cancelOrder(uint _orderId) public isCustomer {
        Order memory order;
        uint[] memory orderHist = orderHistory[msg.sender];
        for (uint i = 0; i < orderHist.length; i++) {
            if (orderHist[i] == _orderId) {
                order = orders[orderHist[i]];
            }
        }
        if (order.orderId != _orderId) {
            revert("Order not found");
        }
        if (order.storeApproved) {
            revert("Store alreaady approved your order and is preparing!");
        } else {
            order.isCanceled = true;
        }
    }

    function makeCustomer() public isNotCourier isNotStore{
        customerToken.safeMint(msg.sender);
    }

    function makeStore(string memory _name) public isNotCustomer isNotCourier {
        require(balances[msg.sender] >= 1000, "1000 FTK required to become a store!");
        storeToken.safeMint(msg.sender);
        stakes[msg.sender] += 1000;
        balances[msg.sender] -= 1000;

        stores[msg.sender].name = _name;
        stores[msg.sender].owner = msg.sender;
        stores[msg.sender].nextItemId = 0;
        storeOwners.push(msg.sender);
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