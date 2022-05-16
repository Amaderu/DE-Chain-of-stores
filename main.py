from web3 import Web3, exceptions as contract_exception
import service
import re
import logging
import initialize
from prettytable import PrettyTable
import os
import configparser
from deploy_contract import main as deploy

logger = ''
web3 = ''
contract = ''
contract_accounts = ''
if os.path.exists("logfile.log"):
    os.remove("logfile.log")

#
# def read_config():
#     global contract
#     # CREATE OBJECT
#     config_file = configparser.ConfigParser()
#     # READ CONFIG FILE
#     config_file.read("configurations.ini")
#     # UPDATE A FIELD VALUE
#     #config_file["Logger"]["LogLevel"] = "Debug"
#
#     if (not os.path.exists("configurations.ini")) or config_file["Settings"]["abi"] == [] or config_file["Settings"]["contract_address"].__contains__(""):
#         deploy()
#     config_file.read("configurations.ini")
#     initial_logger(config_file["Logger"]["loglevel"], config_file["Logger"]["logfilename"])
#     inital_contract(config_file["Settings"]["Blockchain_IP_address"],
#                     config_file["Settings"]["contract_address"],
#                     config_file["Settings"]["abi"])
#
#     # # PRINT FILE CONTENT
#     # read_file = open("configurations.ini", "r")
#     # content = read_file.read()
#     # print("Content of the config file are:\n")
#     # print(content)
#     # read_file.flush()
#     # read_file.close()
#
# def initial_logger(log_level, logfile_path):
#     global logger
#     # Gets or creates a logger
#     logger = logging.getLogger(__name__)
#     # set log level
#     logger.setLevel(logging.DEBUG)
#     # define file handler and set formatter
#     file_handler = logging.FileHandler('logfile.log')
#     formatter = logging.Formatter('%(asctime)s : %(levelname)s : %(name)s : %(message)s')
#     file_handler.setFormatter(formatter)
#     # add file handler to logger
#     logger.addHandler(file_handler)
#
#
#
# def inital_contract(chain_ip_address, contract_address, abi):
#     global web3
#     global contract
#     global logger
#     web3 = Web3(Web3.HTTPProvider(chain_ip_address, request_kwargs={'timeout': 60}))
#     logger.info(f'initial web')
#     contract = web3.eth.contract(address=contract_address, abi=abi)
#     logger.info(f'initial contract')
#     web3.eth.defaultAccount = web3.eth.accounts[0]
#     logger.info(f'set {web3.eth.defaultAccount} as defaultAccount')
#     logger.info(f'Connected to web: {web3.isConnected()}')
#     ##вывод содержимого последнего блока
#     latest_block = web3.eth.get_block('latest')
#     logger.info(f'last block is: {latest_block}')





def print_table(f_name, data_row):
    l = []
    dict_data = service.abi
    function = ''
    for function in dict_data:
        if not 'function' in function["type"]:
            continue
        if f_name in function["name"]:
            if 'components' in function["outputs"][0]:
                for elem in function["outputs"][0]["components"]:
                    l.append(elem["name"])
            else:
                for elem in function["outputs"]:
                    l.append(elem["name"])
    table = PrettyTable(l)
    if len(data_row) > len(l):
        table.add_rows(data_row)
    else:
        table.add_row(data_row)
    print(table)


def accounts_list(bool_print):
    table = PrettyTable(['address', 'balance'])
    contract_accounts = web3.eth._get_accounts()
    for address in contract_accounts:
        balance = web3.fromWei(web3.eth.getBalance(address), "ether");
        table.add_row([address, balance])
    if bool_print:
        print(table)
    return contract_accounts


##print(latest_block.strip())
##print('\n'.join(latest_block.strip() for latest_block in re.findall(r'.{1,40}(?:\s+|$)', latest_block)))
##print(latest_block)


def require_types():
    global web3
    global contract
# if isinstance(web3,Web3):
#  print(f'{web3}')
# if isinstance(contract,Web3.contract):
#  print(f'{contract}')
# isinstance(contract,web3._utils.datatypes.Contract)

def getUserData():
    # counter.functions.read().call()
    # txn_hash = counter.functions.increment().transact({"from": me})
    # web3.eth.wait_for_transaction_receipt(txn_hash)
    # counter.functions.read().call()

    func_to_call = 'getMeData'
    getData = contract.functions[func_to_call]
    address = web3.eth._get_accounts()[0]
    print(f'user address: {address}')
    ##result = addParticipant(service.ADMIN_ACCOUNT,0).transact(  {'from': service.ADMIN_ACCOUNT, 'gasLimit': '6000000', 'gasPrice': '0', 'gas': 600000})
    ##web3.eth.waitForTransactionReceipt(result)
    result = getData().call({'from': address})
    l = []
    for elem in result:
        if isinstance(elem, bytes):
            l.append(Web3.toText(elem))
        else:
            l.append(elem)
    print_table("getMeData", l)
    # Web3.toText(bytes_content)


def exec_fun_call(func_to_call, *args, **kwargs):
    funct = contract.functions[func_to_call]
    address = web3.eth._get_accounts()[0]
    print(f'sending call from user address: {address}')
    ##result = addParticipant(service.ADMIN_ACCOUNT,0).transact(  {'from': service.ADMIN_ACCOUNT, 'gasLimit': '6000000', 'gasPrice': '0', 'gas': 600000})
    ##web3.eth.waitForTransactionReceipt(result)
    result = funct(*args).call(kwargs)
    l = []
    if type(result) != tuple and type(result) != list and type(result) != dict:
        l.append(result)
        print_table(func_to_call, l)
        return
    for elem in result:
        if isinstance(elem, bytes):
            l.append(Web3.toBytes(elem))
        else:
            l.append(elem)
    print_table(func_to_call, l)
    # Web3.toText(bytes_content)


def exec_fun_transact(func_to_transact, *args, **kwargs):
    funct = contract.functions[func_to_transact]
    print(f'{funct}')
    address = web3.eth._get_accounts()[0]
    print(f'sending transact from user address: {address}')
    ##result = addParticipant(service.ADMIN_ACCOUNT,0).transact(  {'from': service.ADMIN_ACCOUNT, 'gasLimit': '6000000', 'gasPrice': '0', 'gas': 600000})
    ##web3.eth.waitForTransactionReceipt(result)
    txn_hash = funct(*args).transact(kwargs)
    # txn_hash = funct(*args).transact({"from": address})
    # tx_receipt  = web3.eth.wait_for_transaction_receipt(txn_hash)
    tx_receipt = web3.eth.waitForTransactionReceipt(txn_hash)
    assert tx_receipt.status == 1


def admin_menu():
    while True:
        os.system('cls')
        for i in range(0, 2):
            print(contract.functions.shoplist(i).call({'from': service.current_user_address}))
        print("Главное меню")
        print("1 - Узнать баланс")
        print("2 - Повысить пользователя")
        print("3 - Повысить до продавца")
        print("4 - Понизить продавца до покупателя")
        print("0 - Close")

        user_choice = int(input())
        if user_choice == 1:
            print(contract.functions.getMeData().call({'from': service.current_user_address})[1])
            print("Any key to continue")
            input()
        elif user_choice == 2:
            print('Enter address: ')
            address = input()
            try:
                contract.functions.PromotionToAdmin(address).transact({'from': service.current_user_address})
            except contract_exception.ContractLogicError as err:
                print(err)
        elif user_choice == 3:
            print('Enter address: ')
            address = input()
            try:
                contract.functions.PromotionToSeller(address).transact({'from': service.current_user_address})
            except contract_exception.ContractLogicError as err:
                print(err)
        elif user_choice == 4:
            print('Enter address: ')
            address = input()
            try:
                contract.functions.DemotionSellerToBuyer(address).transact({'from': service.current_user_address})
            except contract_exception.ContractLogicError as err:
                print(err)
        elif user_choice == 0:
            break
        else:
            break


def seller_menu():
    pass


def buyer_menu():
    pass


def auth():
    print('Enter address:')
    address = input()
    if not address.__contains__("0x") or address.__len__() != 42:
        print('invalid address')
        return
    print('Enter password:')
    password = str(input())

    if address != '' and password != '':
        try:
            auth_user = contract.functions.authInSystem(password).call({'from': address})
            if auth_user:
                print('You auth')
                logger.info(f"auth in account {address}")
                os.system('cls')
                service.current_user_address = address
                service.current_user_data = contract.functions.getMeData().call({'from': address})
                if service.current_user_data[2] == 0:
                    admin_menu()
                elif service.current_user_data[2] == 1:
                    seller_menu()
                elif service.current_user_data[2] == 2:
                    buyer_menu()
            else:
                print('No auth')
                return
        except contract_exception.ContractLogicError as err:
            print(err)



print('to terminate program print exit()\n')
initialize.initial_all()
logger = initialize.logger
web3 = initialize.web3
contract = initialize.contract

contract_accounts = accounts_list(True)
app_state_running = True

# admin_functions = '1. Повысить обычного покупателя до роли продавец\n2. Понизить продавца до роли покупатель\n3. Переключится к роли покупатель\n4. Внести в систему администратора.'
while app_state_running:
    # result = contract.functions.authInSystem(str(input("Input the account password\n"))).call(
    #     {'from': web3.eth._get_accounts()[0]})
    # print(result)
    # app_state_running = result
    print("Hi")
    print("1 - Auth")
    print("2 - Reg")
    print("0 - Close")
    user_choice = int(input())

    if user_choice == 1:
        auth()
    elif user_choice == 2:
        #reg()
        pass
    elif user_choice == 0:
        break
    else:
        break

    # try:
    # 	getUserData()
    # 	account = input(f'input the account\n')
    # 	if not account in web3.eth._get_accounts():
    # 		if account in 'exit()': break
    # 		else: continue
    # 	#state_mutability in abi check
    # 	exec_fun_call('getMeData',**{'from': account})
    # 	exec_fun_call('productList',0,**{'from': account})
    # 	# exec_fun_transact('registrateNewUser', 'byuer', 10000,**{'from': account})
    # 	# contract.functions.registrateNewUser('byuer', 10000).transact({'from': web3.eth._get_accounts()[1]})
    # 	accounts_list(False)
    # except exceptions.SolidityError as errors:
    #     print(error)
    # except Exception as errors:
    # 	logger.error(f'{errors}',exc_info=True)
    # account = input(f'input the account\n')
    # if not account in web3.eth._get_accounts():
    #     if account in 'exit()':
    #         break
    #     else:
    #         continue
    # # state_mutability in abi check
    # exec_fun_call('getMeData', **{'from': account})
    # exec_fun_call('productList', 0, **{'from': account})
    # # exec_fun_transact('registrateNewUser', 'byuer', 10000,**{'from': account})
    # # contract.functions.registrateNewUser('byuer', 10000).transact({'from': web3.eth._get_accounts()[1]})
    # accounts_list(True)
    app_state_running = input(
        'Press anu key for continue or if you want to run the program again\n  print \'exit()\'\n') != 'exit()'


print('The program now is terminate.')


