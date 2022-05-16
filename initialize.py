import time

from web3 import Web3, exceptions
import service
import re
import logging
from prettytable import PrettyTable
import os
import configparser
from deploy_contract import main as deploy


web3: Web3
contract = ''
contract_accounts = ''
logger: logging.Logger = logging.getLogger(__name__)


def initial_all():
    global contract
    # CREATE OBJECT
    config_file = configparser.ConfigParser()
    # READ CONFIG FILE
    config_file.read("configurations.ini")

    if (not os.path.exists("configurations.ini")) or config_file["Settings"]["abi"] == None or config_file["Settings"]["contract_address"].__contains__(""):
        deploy()
    config_file.read("configurations.ini")
    initial_logger(config_file["Logger"]["loglevel"], config_file["Logger"]["logfilename"])
    initial_contract(config_file["Settings"]["Blockchain_IP_address"],
                     config_file["Settings"]["contract_address"],
                     config_file["Settings"]["abi"])
    #time.sleep(2)


def initial_logger(log_level, logfile_path):
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
    return logger


def initial_contract(chain_ip_address, contract_address, abi):
    global web3
    global contract
    global logger
    web3 = Web3(Web3.HTTPProvider(chain_ip_address, request_kwargs={'timeout': 60}))
    logger.info(f'initial web')
    contract = web3.eth.contract(address=contract_address, abi=abi)
    logger.info(f'initial contract')
    web3.eth.defaultAccount = web3.eth.accounts[0]
    logger.info(f'set {web3.eth.defaultAccount} as defaultAccount')
    logger.info(f'Connected to web: {web3.isConnected()}')
    ##вывод содержимого последнего блока
    latest_block = web3.eth.get_block('latest')
    logger.info(f'last block is: {latest_block}')
