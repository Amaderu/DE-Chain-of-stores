from web3 import Web3, exceptions
import service
import re
import logging
from prettytable import PrettyTable
import os

if os.path.exists("logfile.log"):
    os.remove("logfile.log")
logger = ''
web3 = ''
contract = ''
contract_accounts = ''


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


def initial_logger():
    global logger
    # Gets or creates a logger
    logger = logging.getLogger(__name__)
    # set log level
    logger.setLevel(logging.DEBUG)
    # define file handler and set formatter
    file_handler = logging.FileHandler('logfile.log')
    formatter = logging.Formatter('%(asctime)s : %(levelname)s : %(name)s : %(message)s')
    file_handler.setFormatter(formatter)
    # add file handler to logger
    logger.addHandler(file_handler)


def accounts_list(bool_print):
    table = PrettyTable(['address', 'balance'])
    contract_accounts = web3.eth._get_accounts()
    for address in contract_accounts:
        balance = web3.fromWei(web3.eth.getBalance(address), "ether");
        table.add_row([address, balance])
    if bool_print:
        print(table)
    return contract_accounts


def inital_contract():
    global web3
    global contract
    web3 = Web3(Web3.HTTPProvider(service.Blockchain_IP_address, request_kwargs={'timeout': 60}))
    logger.info(f'initial web')
    contract = web3.eth.contract(address=service.contract_address, abi=service.abi)
    logger.info(f'initial contract')
    web3.eth.defaultAccount = web3.eth.accounts[0]
    logger.info(f'set {web3.eth.defaultAccount} as defaultAccount')
    logger.info(f'Connected to web: {web3.isConnected()}')
    ##вывод содержимого последнего блока
    latest_block = web3.eth.get_block('latest')
    logger.info(f'last block is: {latest_block}')


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
            l.append(Web3.toText(elem))
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


print('to terminate program print exit()\n')
initial_logger()
inital_contract()
contract_accounts = accounts_list(False)
app_state_running = False

result = contract.functions.authInSystem(input()).call({'from': web3.eth._get_accounts()[0]})
app_state_running = result

# admin_functions = '1. Повысить обычного покупателя до роли продавец\n2. Понизить продавца до роли покупатель\n3. Переключится к роли покупатель\n4. Внести в систему администратора.'
while app_state_running:
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
    account = input(f'input the account\n')
    if not account in web3.eth._get_accounts():
        if account in 'exit()':
            break
        else:
            continue
    # state_mutability in abi check
    exec_fun_call('getMeData', **{'from': account})
    exec_fun_call('productList', 0, **{'from': account})
    # exec_fun_transact('registrateNewUser', 'byuer', 10000,**{'from': account})
    # contract.functions.registrateNewUser('byuer', 10000).transact({'from': web3.eth._get_accounts()[1]})
    accounts_list(False)
    app_state_running = input(
        'Press anu key for continue or if you want to run the program again\n  print \'exit()\'\n') != 'exit()'
print('The program will now terminate.')
