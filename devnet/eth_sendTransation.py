import random
from web3 import Web3
import time
from scipy.stats import norm, poisson
import os
import tempfile
import mmap
from multiprocessing.shared_memory import SharedMemory
import atexit


FILE_PATH = "/dev/shm/counter.dat"
SIZE = 4 

def init_counter_file():
    with open(FILE_PATH, "wb") as f:
        f.write(b"\x00" * SIZE)

def write_counter(count: int):
    with open(FILE_PATH, "r+b") as f: 
        with mmap.mmap(f.fileno(), SIZE) as mm:
            mm.seek(0)
            mm.write(count.to_bytes(SIZE, byteorder="little"))

def save_transaction_count(count, flag):
    file_path = 'devnet/script/transaction_count.txt'
    
    try:
        with tempfile.NamedTemporaryFile('w', dir=os.path.dirname(file_path), delete=False) as temp_file:
            temp_filename = temp_file.name 
            temp_file.write(f"{count} {flag}")


        os.replace(temp_filename, file_path)
    except Exception as e:
        if 'temp_filename' in locals() and os.path.exists(temp_filename):
            os.remove(temp_filename)


w3 = Web3(Web3.HTTPProvider('http://localhost:8547'))
w3_bro = Web3(Web3.HTTPProvider('http://localhost:8549'))

if not w3.is_connected():
    exit()
if not w3_bro.is_connected():
    exit()


from_address = '0x123463a4b065722e99115d6c222f267d9cabb524'
checksum_from_address = Web3.to_checksum_address(from_address)

from_address2 = '0x0E829892aD3964024C0e15854e663A7c900D174B'
checksum_from_address2 = Web3.to_checksum_address(from_address2)

recipients = [
  '0x0E829892aD3964024C0e15854e663A7c900D174B',
  '0x123463a4b065722e99115d6c222f267d9cabb524',
]


count_tx = 0 
count = 0

init_counter_file()

while True:
    rate_public_mean = 0.082
    rate_public_sd = 0

    public_lambda = norm.rvs(loc=rate_public_mean, scale=rate_public_sd)

    new_public_signal = poisson.rvs(mu=public_lambda)
    for _ in range(new_public_signal) :
        count = count % 2
        checksum_recipient = Web3.to_checksum_address(recipients[count])
        count += 1

        gas_limit = random.randint(23000, 60000)
        gas_price = random.randint(10, 50)
        value = round(random.uniform(0.01, 1), 4)

        params = {
            'from': checksum_from_address,
            'to': checksum_recipient,
            'gas': gas_limit,
            'gasPrice': w3.to_wei(gas_price, 'gwei'),
            'value': w3.to_wei(value, 'ether'),
            'input': '0xfad2709d0bb03bf0e8ba3c99bea194575d3e98863133d1af638ed056d1d59345',
        }

        params2 = {
            'from': checksum_from_address2,
            'to': checksum_recipient,
            'gas': gas_limit,
            'gasPrice': w3_bro.to_wei(gas_price, 'gwei'),
            'value': w3_bro.to_wei(value, 'ether'),
            'input': '0xf7f19a39ec1211a4b757a0ef789a2ca4f10c527ca9a0869487c4c404aece5480',
        }

        tx_hash = w3.eth.send_transaction(params)
        tx_hash2 = w3_bro.eth.send_transaction(params2) 

        count_tx += 2
        write_counter(count_tx)
        
    time.sleep(0.01) 

    