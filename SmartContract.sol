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
		string surname;
		string name;
		string middlename;
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

    struct Shop
    {
		uint index;
        string nameShop;
        address[] sellers;
		string city;
        //Product[] Products;
        mapping(uint => Product) Products;
        uint count;
    }

	struct Request {
		string name;
		uint price;
	}

    mapping(uint => Shop) private shops;
    string[] public shopList;
	mapping(address => User) private users;
    address[] public reg;
    address[] public admins_users;

	struct Event{
		address user;
		uint8 eventType;
		bool isComplet;
	}

    struct BuyEvent{
		address customer;
		uint8 eventType;
		bool isComplet;
        uint shop;
        uint productNumber;
        uint price;
        bool refund;
	}

	struct RefundEvent{
		uint buyEventIndex;
		address customer;
		bool isComplet;
        uint shop;
        uint productNumber;
        uint price;
	}

	Event[] public adminsEvents;
	BuyEvent[] public sellerEvents;
	RefundEvent[] public sellerRefundEvents;


	modifier only_admin { require(users[msg.sender].role == Roles.administrator,"this is admin only"); _; }
	modifier only_seller { require(users[msg.sender].role == Roles.seller,"this is seller only"); _; }
	modifier index_not_ofb(uint _index, uint length) {
		require(length > _index, "index out of bound ");
		_;
	}

	//Common funct
	function regist(string memory _surName, string memory _name, string memory _middleName,
		address _adr, string memory _password,
		uint _balance)
		public
	{
		require(users[_adr].isExist == false, "Users already exist");
		users[_adr] = User(_surName, _name, _middleName,
			keccak256(abi.encodePacked(_password)),
			_balance,
			Roles.customer,
			true
		);
        reg.push(_adr);
	}

	function registrateNewUser(string memory _surName, string memory _name, string memory _middleName,
		address _adr, Roles role, string memory _password,
		uint _balance)
		only_admin public
	{
		require(users[_adr].isExist == false, "Users already exist");
		users[_adr] = User(_surName, _name, _middleName,
			keccak256(abi.encodePacked(_password)),
			_balance,
			role,
			true
		);
        reg.push(_adr);
	}

	function authInSystem(
		string memory _password
		) public view returns(bool)
	{
		require(users[msg.sender].isExist == true, "User doesn't register");
		//return keccak256(abi.encodePacked(_password)) == keccak256(abi.encodePacked(users[msg.sender].password));
		return keccak256(abi.encodePacked(_password)) == users[msg.sender].password;
	}

	//Admins funct
	//запрос на повышение или понижение
	function eventChangeRole() check_exist
		public
	{
		require(users[msg.sender].role != Roles.administrator, "it's seller and buyer functions");
		if(users[msg.sender].role == Roles.seller){
			adminsEvents.push(Event(msg.sender,2,false));
		}
		if(users[msg.sender].role == Roles.customer){
			adminsEvents.push(Event(msg.sender,1,false));
		}
	}
	//выполнить один запрос
	function execChangeRoleEvent(uint eventIndex) only_admin
		public returns (uint)
	{
		if(adminsEvents[eventIndex].isComplet != true){
			if(adminsEvents[eventIndex].eventType == 1)
				updateRole(adminsEvents[eventIndex].user,Roles.seller);
			else
				updateRole(adminsEvents[eventIndex].user,Roles.customer);
			adminsEvents[eventIndex].isComplet = true;
		}
			//removeAE(i-1);
		return adminsEvents.length;
	}

	//выполнить все запросы разом
	function execChangeRoleAllEvents() only_admin
		public returns (uint)
	{
		for(uint i = adminsEvents.length-1;i>=0;i--){
			if(adminsEvents[i].isComplet != true){
				if(adminsEvents[i].eventType == 1)
					updateRole(adminsEvents[i].user,Roles.seller);
				else
					updateRole(adminsEvents[i].user,Roles.customer);
				adminsEvents[i].isComplet = true;
			}
			//removeAE(i-1);
		}
		return adminsEvents.length;
	}
	//дополнительная функция очистки событий после исполнения
	function removeAE(uint _index) private index_not_ofb(_index, adminsEvents.length) {
        //require(_index < adminsEvents.length, "index out of bound");
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

	//utilite functions
    function addShop(string memory _nameShop, string memory _city) only_admin public returns (string[] memory)
	{
        shops[shopList.length].nameShop = _nameShop;
		shops[shopList.length].city = _city;
        shopList.push(_nameShop);
        return shopList;
    }

    function addSellerToShop(uint _indexShop, address seller) only_admin public returns(address[] memory){
		users[seller].role = Roles.seller;
        shops[_indexShop].sellers.push(seller);
        return shops[_indexShop].sellers;
    }

	function deleteShopMap(uint shopIndex) only_admin public returns (string[] memory)
	{
		 for (uint i = 0; i < shops[shopIndex].sellers.length; i++) {
            address seller = shops[shopIndex].sellers[i];
			users[seller].role = Roles.customer;
        }
        delete shops[shopIndex];
       	removeShopArr(shopIndex);
        return shopList;
    }
	function removeShopArr(uint _index) private index_not_ofb(_index, shopList.length) {
        //require(_index < shopList.length, "index out of bound");
        for (uint i = _index; i < shopList.length - 1; i++) {
            shopList[i] = shopList[i + 1];
        }
        shopList.pop();
    }

    constructor(){
		/*
		registrateNewUser("Cage","Adam","Sandler",msg.sender, Roles.administrator,"admin",1000);
    	registrateNewUser("Belfort","Jordan","Ross",0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, Roles.seller,"seller",1000);
        registrateNewUser("Mozby","Teodor","Evelin", 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, Roles.customer,"customer",1000);

        addShop("Petyorochka","St Petersburg");
		addSellerToShop(0,reg[0]);
		addNewProduct(0,"apple",100,2);
        addNewProduct(0,"pear",90,3);
        addNewProduct(0,"peach",80,4);
        addNewProduct(0,"nectarine",70,1);
        addNewProduct(0,"kiwi",120,2);

        addShop("Garden","Moscow");
        addNewProduct(1,"apple_juice",100,2);
        addNewProduct(1,"pear_juice",90,3);
        addNewProduct(1,"peach_juice",80,4);
        addNewProduct(1,"nectarine_juice",70,1);
        addNewProduct(1,"kiwi_juice",120,2);
		*/
		users[msg.sender] = User("Cage","Adam","Sandler",
			keccak256(abi.encodePacked("admin")),
			1000,
			Roles.administrator,
			true
		);
		admins_users.push(msg.sender);
		reg.push(msg.sender);
		users[0x467c2f769E1b96Fd4170c9FD47961822C21C3367] = User("Belfort","Jordan","Ross",
			keccak256(abi.encodePacked("seller")),
			1000,
			Roles.seller,
			true
		);
		reg.push(0x467c2f769E1b96Fd4170c9FD47961822C21C3367);
		users[0x8cDe28232D6e0f3940421c0b15Cbf0584DAc391A] = User("Mozby","Teodor","Evelin",
			keccak256(abi.encodePacked("customer")),
			1000,
			Roles.customer,
			true
		);
		reg.push(0x8cDe28232D6e0f3940421c0b15Cbf0584DAc391A);

		//add shop 1
		shops[shopList.length].nameShop = "Petyorochka";
		shops[shopList.length].city = "St Petersburg";
        shopList.push("Petyorochka");
		//add seller to shop 1
		shops[0].sellers.push(reg[0]);

		//add shop 2
		shops[shopList.length].nameShop = "Garden";
		shops[shopList.length].city = "Moscow";
        shopList.push("Garden");


		//add products
		shops[0].Products[0] = Product("apple",100,2);
		shops[0].Products[1] = Product("pear",90,3);
        shops[0].Products[2] = Product("peach",80,4);
        shops[0].Products[3] = Product("nectarine",70,1);
        shops[0].Products[4] = Product("kiwi",120,2);
		shops[0].count=5;


        shops[1].Products[0] = Product("apple_juice",100,2);
        shops[1].Products[1] = Product("pear_juice",90,3);
        shops[1].Products[2] = Product("peach_juice",80,4);
        shops[1].Products[3] = Product("nectarine_juice",70,1);
        shops[1].Products[4] = Product("kiwi_juice",120,2);


	}

	function addNewProduct(
		uint _shopNum,
		string memory _name,
		uint _price,
		uint _count)
		check_exist public
	{
		//string s1, s2, s3; s3 = bytes.concat(bytes(s1), bytes(s2));
		//require(users[msg.sender].isExist == false, "Users already exist");
        uint count = shops[_shopNum].count;
		shops[_shopNum].Products[count] = Product(_name,_price,_count);
		shops[_shopNum].count++;
	}

	function productList(uint _shopNum) check_exist public view returns(Product[] memory)
	{
        uint count = shops[_shopNum].count;
		require(count > 0, "List of products are empty");
		Product[] memory list = new Product[](count);
        for(uint i = 0; i < count; i++){
            list[i] = (shops[_shopNum].Products[i]);
        }
		return list;
	}

    function updateRole(address _address, Roles role) only_admin public
    {
        users[_address].role = role;
    }


    //private office
	modifier check_exist { require(users[msg.sender].isExist == true, "User not register"); _; }
    function getMeData() public view check_exist returns(
		string memory _surname,
		string memory _name,
		string memory _middlename,
		bytes32 _password,
		uint _balance,
		Roles _role,
		bool _isExist)
	{
		_surname = users[msg.sender].surname;
		_name = users[msg.sender].name;
		_middlename = users[msg.sender].middlename;
		_password = users[msg.sender].password;
		_balance = users[msg.sender].balance;
		_role = users[msg.sender].role;
		_isExist = users[msg.sender].isExist;
	}
	function getUserData(address _addressUser) public view check_exist returns (
		string memory _surname,
		string memory _name,
		string memory _middlename,
		bytes32 _password,
		uint _balance,
		Roles _role,
		bool _isExist)
	{
		_surname = users[_addressUser].surname;
		_name = users[_addressUser].name;
		_middlename = users[_addressUser].middlename;
		_password = users[_addressUser].password;
		_balance = users[_addressUser].balance;
		_role = users[_addressUser].role;
		_isExist = users[_addressUser].isExist;
	}

    function getSellerData(address _addressUser) public view check_exist returns (
		bytes32 _password,
		uint _balance,
		Roles _role,
		bool _isExist)
	{
		_password = users[_addressUser].password;
		_balance = users[_addressUser].balance;
		_role = users[_addressUser].role;
		_isExist = users[_addressUser].isExist;
	}
	struct ShopSeller{
		string nameShop;
        address[] sellers;
	}
	function getAdminData(address _addressUser) public view check_exist returns (
		address _login,
		Event[] memory, string[] memory, ShopSeller[] memory)
	{
		_login = msg.sender;
		string memory surename;
		string memory name;
		string memory middlename;
		string[] memory admins = new string[](admins_users.length);
		for(uint i = 0; i < admins_users.length; i++){
			if(users[admins_users[i]].role == Roles.administrator){
				(surename, name, middlename, , , , ) = getUserData(admins_users[i]);
				admins[i] = string(abi.encodePacked(surename, " ", name, " ", middlename));
			}
		}
		ShopSeller[] memory shopsToSeller = new ShopSeller[](shopList.length);
		for(uint i = 0; i < shopList.length; i++){
			shopsToSeller[i] = ShopSeller(shops[i].nameShop,shops[i].sellers);
		}
		return(_login, adminsEvents, admins, shopsToSeller);
	}

	/*
		В личном кабинете администратора отображается его логин,
		 список запросов от покупателей и продавцов на повышение/понижение роли,
		 список всех администраторов системы,
		 список всех продавцов магазинов (с сортировкой по магазину).
	*/


    //Buyer functions
	//Простая покупка
    function buyProduct(uint shop,  uint productNumber, uint count) check_exist
	private
	{

        require(count > 0,"count is not more then 0");
        if(shop==1){
            shops;
        }
		uint productPrice = shops[shop].Products[productNumber].price;
        require(productPrice * count < users[msg.sender].balance,"account balance not enought");
		users[msg.sender].balance -= shops[shop].Products[productNumber].price * count;
	}

    function buyProductEvent(uint shopIndex,  uint productNumber, uint count) check_exist
	public
	{
        require(count > 0,"count is not more then 0");
		uint productPrice = shops[shopIndex].Products[productNumber].price;
        require(productPrice * count < users[msg.sender].balance,"account balance not enought");
		sellerEvents.push(BuyEvent(msg.sender,4,false,shopIndex,productNumber,productPrice,false));
	}

	//Sellers function
    function confirmBuy(uint eventId) only_seller public
    {
		address customer = sellerEvents[eventId].customer;
        require(sellerEvents[eventId].isComplet == false, "this purchase is complet");
        require(sellerEvents[eventId].price < users[customer].balance,"account balance not enought");
        users[customer].balance -= sellerEvents[eventId].price;
		sellerEvents[eventId].isComplet = true;
    }

	function refundProductEvent(uint _shop,  uint _productNumber) check_exist
	public returns(bool)
	{
		for(uint i = 0;i<sellerEvents.length;i++){
			    if(sellerEvents[i].isComplet == true && sellerEvents[i].customer == msg.sender && sellerEvents[i].refund == false){
                    if(sellerEvents[i].shop == _shop && sellerEvents[i].productNumber == _productNumber){
				        sellerRefundEvents.push(
							RefundEvent(i,msg.sender,false,_shop,_productNumber,sellerEvents[i].price)
						);
						return true;
                    }
			    }
        }
		return false;

	}
    function confirmRefund(uint eventId) only_seller payable public
    {
		require(sellerRefundEvents[eventId].isComplet == false, "this return has already been made");
		uint buyEventIndex = sellerRefundEvents[eventId].buyEventIndex;
		if(sellerEvents[buyEventIndex].isComplet == true
			&& sellerEvents[buyEventIndex].customer == msg.sender
			&& sellerEvents[buyEventIndex].refund == false)
		{
			users[sellerEvents[buyEventIndex].customer].balance += sellerEvents[buyEventIndex].price;
			sellerEvents[buyEventIndex].refund = true;
			sellerRefundEvents[eventId].isComplet = true;
		}

    }


	//отказ от покупк
    function cancleBuy(uint shop,  uint productNumber) check_exist private returns(bool)
    {
        for(uint i = 0;i<sellerEvents.length;i++){
			    if(sellerEvents[i].isComplet == false && sellerEvents[i].customer == msg.sender){
                    if(sellerEvents[i].shop == shop && sellerEvents[i].productNumber == productNumber){
				        //delete sellerEvents[i];
						removeBuyEvent(i);
						return true;
                    }
			    }
        }
		return false;
    }

	function removeBuyEvent(uint _index) private check_exist index_not_ofb(_index, sellerEvents.length) {
        for (uint i = _index; i < sellerEvents.length - 1; i++) {
            sellerEvents[i] = sellerEvents[i + 1];
        }
        sellerEvents.pop();
    }


}