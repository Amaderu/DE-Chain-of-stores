import logging
from logging import Logger

from web3 import Web3
import solcx
import os
import configparser

import initialize

def create_config(contract_address, bytecode, abi):
    if os.path.exists("configurations.ini"):
        return

    config_file = configparser.ConfigParser()

    # ADD SECTION
    main_section = 'Settings'
    config_file.add_section(main_section)
    # ADD SETTINGS TO SECTION
    config_file.set(main_section, "Blockchain_IP_address", "http://127.0.0.1:7545")
    config_file.set(main_section, "contract_address", f"{contract_address}")
    config_file.set(main_section, "bytecode", bytecode)

    string = ",".join([str(item) for item in abi]).replace('\'', '\"').replace("False,", "\"false\",")
    string = "[" + string + "]"
    config_file.set(main_section, "abi", f"{string}")

    # ADD NEW SECTION AND SETTINGS
    # 10 - logging.DEBUG
    config_file["Logger"] = {
        "LogFilePath": "",
        "LogFileName": "logfile.log",
        "LogLevel": "10"
    }

    # SAVE CONFIG FILE
    with open(r"configurations.ini", 'w') as configfileObj:
        config_file.write(configfileObj)
        configfileObj.flush()
        configfileObj.close()
    print("Config file 'configurations.ini' created")


def compile_source_file(file_path):
    solcx.install_solc(version='0.8.9')
    solcx.set_solc_version('0.8.9')
    with open(file_path, 'r') as f:
        source = f.read()
        # print(source)
    # return compiled_sol = solcx.compile_source(Path(fr'{file_path}'),output_values=['abi', 'bin'],solc_version="0.7.0")
    return solcx.compile_source(source)


def deploy():
    compiled_sol = compile_source_file(r'.\SmartContract.sol')
    contract_name, contract_interface = compiled_sol.popitem()

    config_file = configparser.ConfigParser()
    config_file.read("configurations.ini")

    bytecode = contract_interface['bin']
    abi = contract_interface['abi']
    w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:7545"))
    # set pre-funded account as sender
    w3.eth.default_account = w3.eth.accounts[0]
    smart_contract = w3.eth.contract(abi=abi, bytecode=bytecode)

    # Submit the transaction that deploys the contract
    tx_hash = smart_contract.constructor().transact()
    # Wait for the transaction to be mined, and get the transaction receipt
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

    # logger = initialize.initial_logger(config_file["Logger"]["loglevel"], config_file["Logger"]["logfilename"])
    logger = initialize.logger
    logger.info(f'contract_name file is {contract_name}')
    try:
        if not config_file.get("Settings", "contract_address").__eq__(""):
            logger.info(f'contract successfully connected by: {tx_receipt.contractAddress}')
            return
    except configparser.NoSectionError:
        create_config(tx_receipt.contractAddress, bytecode, abi)
        logger.info(f'contract_id is {contract_name}')
        logger.info(f'contract successfully deployed by: {tx_receipt.contractAddress}')
        print(f'contract successfully deployed by\n{tx_receipt.contractAddress}')


def main():
    deploy()


if __name__ == '__main__':
    main()
