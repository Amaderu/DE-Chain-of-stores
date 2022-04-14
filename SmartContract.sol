 /**
 * The SmartContract contract chain of stores IS 
 */
 //SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;
contract SmartContract {
    enum Roles {
		administrator, seller, customer
	}

    struct User {
		bytes32 password;
		uint balance;
		Roles role;
		bool isExist;
	}

	struct Product {
		string name;
		uint price;
		uint count;
	}

	struct Request {
		string name;
		uint price;
	}

	mapping (address => Request) afasf;
	//Возможно поменять ключ на string
	mapping(uint => uint) productCount;
    mapping(uint => mapping(uint => Product)) private shops;
	mapping(address => User) private users;

	//Пользователь подал запрос на смену роли
	event UserWantChangeRole(address addr);                                
    //Администратор выполнил запрос на смену роли
    event UserWantChangeRole_admin(address _addr, uint _newRole);
    //Пользователь хочет купить товар
    event UserWantBuyProduct(address addr, uint shop, uint productNumber);                                
    //Продавец подтвердил покупку товара
    event UserBuyPtoduct_seller(address _seller, address _byuer, uint shop, uint productNumber, uint price);
	//1 - понизить 2 - повысить  3 - купить 4 - продать
	struct Event{
		address user;
		uint8 eventType;
		bool isComplet;
	}
    struct BuyEvent{
		address user;
		uint8 eventType;
		bool isComplet;
        uint shop;
        uint productNumber;
        uint price;
        bool refund;
	}
	modifier only_admin { require(users[msg.sender].role == Roles.administrator); _; }
	modifier only_seller { require(users[msg.sender].role == Roles.seller); _; }

	Event[] public adminsEvents;
	BuyEvent[] public sellerEvents;

	//запрос на повышение или понижение
	function eventChangeRole()
		public 
	{
		require(users[msg.sender].role != Roles.administrator, "it's seller and buyer functions");
		if(users[msg.sender].role == Roles.seller){
			adminsEvents.push(Event(msg.sender,2,false));
			emit UserWantChangeRole(msg.sender);
		}
		if(users[msg.sender].role == Roles.customer){
			adminsEvents.push(Event(msg.sender,1,false));
			emit UserWantChangeRole(msg.sender);
		}
	}

	function ChangeRoleAllEvents() only_admin
		public returns (uint)
	{
		for(uint i = adminsEvents.length-1;i>=0;i--){
			if(adminsEvents[i].isComplet != true){
				if(adminsEvents[i].eventType == 1) 
					updateRole(adminsEvents[i].user,Roles.seller);
				else 
					updateRole(adminsEvents[i].user,Roles.customer);
			} 
			remove(i-1);
			//adminsEvents.pop();
			// if(adminsEvents.length>1)
			// 	adminsEvents.pop();
			// else delete adminsEvents[i];
		}
		return adminsEvents.length;
	}

	function remove(uint _index) private {
        require(_index < adminsEvents.length, "index out of bound");

        for (uint i = _index; i < adminsEvents.length - 1; i++) {
            adminsEvents[i] = adminsEvents[i + 1];
        }
        adminsEvents.pop();
    }

	

	
    /*constructor() public {
        //address public owner = msg.sender;
    	registrateAdmin(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, "admin", 0);
        registrateAdmin(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, "seller", 0);
        updateRole(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, Roles.seller);
        registrateAdmin(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, "customer", 0);
        updateRole(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, Roles.customer);

	}*/
    constructor() {
        //address public owner = msg.sender;
    	users[msg.sender] = User(keccak256(abi.encodePacked("admin")), 1000, Roles.administrator, true);
		//registrateAdmin(0x7F3e3F2Cb4D538df7C01b9a95BC626a9f150fd2a,admin,100);
    	users[0xd8c33DC6aa71dc5dF0Cb2638bD889D33C92eeF5c] = User("seller", 0, Roles.seller, true);
        users[0xE2b9B07a218262fc55439F60320FdDa9692086A1] = User("customer", 0, Roles.customer, true);
        shops[0][0] = Product("apple",100,2);
        shops[0][1] = Product("pear",90,3);
        shops[0][2] = Product("peach",80,4);
        shops[0][3] = Product("nectarine",70,1);
        shops[0][4] = Product("kiwi",120,2);
        productCount[0] = 5;
		// Product[] memory d;
		// d = pr;
		// shops2.push(Shop(pr,1));
			/*
		shops2.push(Shop({
                product: d,
                count: 1
            }));*/
			
	}

	function pushNewProduct(
		uint _shopNum,
		string memory _name,
		uint _price,
		uint _count)
		public 
	{
		//string s1, s2, s3; s3 = bytes.concat(bytes(s1), bytes(s2));
		//require(users[msg.sender].isExist == false, "Users already exist");
		shops[_shopNum][productCount[_shopNum]] = Product(_name,_price,_count);
		productCount[_shopNum]++; 
	}

	function productList(uint _shopNum) public view returns(Product[] memory)
	{
		require(productCount[_shopNum] > 0, "List of products are empty");
		//list.length = productCount[_shopNum];
		Product[] memory list = new Product[](productCount[_shopNum]);
        for(uint i = 0; i < productCount[_shopNum]; i++){
            //(name,price) = shops[_shopNum][productCount[_shopNum]];
			//Product[] memory list = shops[_shopNum][productCount[_shopNum]];
            list[i] = (shops[_shopNum][i]);
        }
		return list; 
	}
	function lastProductInList(uint _shopNum) public view returns(Product memory)
	{
		require(productCount[_shopNum] > 0, "List of products are empty");
		return shops[_shopNum][productCount[_shopNum]-1]; 
	}
	
	function registrateNewUser(
		string memory _password,
		uint _balance)
		public 
	{
		require(users[msg.sender].isExist == false, "Users already exist");
		//string memory password = keccak256(abi.encodePacked(_password));
		users[msg.sender] = User(
			keccak256(abi.encodePacked(_password)),
			_balance,
			Roles.customer,
			true
		);
	}

	function authInSystem(
		string memory _password
		) public view returns(bool) 
	{
		require(users[msg.sender].isExist == true, "User doesn't register");
		//return keccak256(abi.encodePacked(_password)) == keccak256(abi.encodePacked(users[msg.sender].password));
		return keccak256(abi.encodePacked(_password)) == users[msg.sender].password;
	}

    function updateRole(address _address, Roles role) only_admin public
    {
        users[_address].role = role;
    }

    function registrateAdmin(
        address _address, 
		string memory _password,
		uint _balance)
		public 
	{
		require(users[_address].isExist == false, "Users already exist");
		users[_address] = User(
			 keccak256(abi.encodePacked(_password)),
			_balance,
			Roles.administrator,
			true
		);
	}
	

    //dataget
    function getMeData() public view returns(
		bytes32 _password,
		uint _balance,
		Roles _role,
		bool _isExist) 
	{
		require(users[msg.sender].isExist == true, "User not exist");
		_password = users[msg.sender].password;
		_balance = users[msg.sender].balance;
		_role = users[msg.sender].role;
		_isExist = users[msg.sender].isExist;
	}
	function getUserData(address _addressUser) public view returns (
		bytes32 _password,
		uint _balance,
		Roles _role,
		bool _isExist) 
	{
		require(users[_addressUser].isExist == true, "User not exist");
		_password = users[_addressUser].password;
		_balance = users[_addressUser].balance;
		_role = users[_addressUser].role;
		_isExist = users[_addressUser].isExist;
	}

    //buyer
    function buyProduct(uint shop,  uint productNumber, uint count)
	public
	{
        
        require(count > 0,"count is not more then 0");
        if(shop==1){
            shops;
        }
		uint productPrice = shops[shop][productNumber].price;
        require(productPrice * count < users[msg.sender].balance,"account balance not enought");
		users[msg.sender].balance -= shops[shop][productNumber].price * count;
		//(_firstName,_lastName,balance) = getMyData();
	}

    /*
    Может подтверждать или отклонять запрос покупателя на покупку, возврат товара, оформление брака.
        struct BuyEvent{
		address user;
		uint8 eventType;
		bool isComplet;
        uint8 shop;
        uint8 productNumber;
        uint8 count;
        bool refund;
	}
    event UserWantBuyProduct(addres addr, uint8 shop, uint8 productNumber);                                
    //Продавец подтвердил покупку товара
    event UserBuyPtoduct_seller(adress _seller, address _byuer, uint8 shop, uint8 productNumber, uint8 price);
    */
    function buyProductEvent(uint shop,  uint productNumber, uint count)
	public
	{
        require(count > 0,"count is not more then 0");
		uint productPrice = shops[shop][productNumber].price;
        require(productPrice * count < users[msg.sender].balance,"account balance not enought");
		sellerEvents.push(BuyEvent(msg.sender,4,false,shop,productNumber,productPrice,false));
		emit UserWantBuyProduct(msg.sender,shop,productNumber);
	}

    function confirmBuy(uint eventId) only_seller payable public
    {
        require(sellerEvents[eventId].isComplet == false, "this purchase is complet");
        require(sellerEvents[eventId].price < users[sellerEvents[eventId].user].balance,"account balance not enought");
        users[sellerEvents[eventId].user].balance -= sellerEvents[eventId].price;
		sellerEvents[eventId].isComplet = true;
		emit UserBuyPtoduct_seller(msg.sender, sellerEvents[eventId].user, sellerEvents[eventId].shop, sellerEvents[eventId].productNumber, sellerEvents[eventId].price);
    }
	event UserWantRefudProduct(address addr, uint shop, uint productNumber, uint position);

	function refundProductEvent(uint shop,  uint productNumber)
	public
	{
		for(uint i = 0;i<sellerEvents.length;i++){
			    if(sellerEvents[i].isComplet == true && sellerEvents[i].user == msg.sender && sellerEvents[i].refund == false){
                    if(sellerEvents[i].shop == shop && sellerEvents[i].productNumber == productNumber){
				        emit UserWantRefudProduct(msg.sender, shop, productNumber, i);
                    }
			    } 
        }
		
	}
    function confirmRefund(uint eventId) only_seller payable public
    {
        require(sellerEvents[eventId].isComplet == true, "this purchase is not complet");
        require(sellerEvents[eventId].refund == false, "this refund is complite");
        users[sellerEvents[eventId].user].balance += sellerEvents[eventId].price;
		sellerEvents[eventId].refund = true;
		emit UserBuyPtoduct_seller(msg.sender, sellerEvents[eventId].user, sellerEvents[eventId].shop, sellerEvents[eventId].productNumber, sellerEvents[eventId].price);
    }

    function cancleBuy(uint shop,  uint productNumber) payable public
    {
        for(uint i = 0;i<sellerEvents.length;i++){
			    if(sellerEvents[i].isComplet == false && sellerEvents[i].user == msg.sender){
                    if(sellerEvents[i].shop == shop && sellerEvents[i].productNumber == productNumber){
				        delete sellerEvents[i];

                    }
			    } 
        }
		emit UserWantBuyProduct(msg.sender, shop, productNumber);
    }


	function del() public
	{
		delete shops[0][0];
	}

}