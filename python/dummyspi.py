import time
from spiflash import SPIFlash
try:
    from codecs import encode
    def my_hexlify(val):
        return codecs.encode(val, 'hex')
except ImportError:
    def my_hexlify(val):
        return codecs.getencoder('hex_codec')(val)[0]

try:
    from binascii import hexlify
except ImportError:
    hexlify = my_hexlify


# dummy SPI flash for testing purposes
# verbose spews out details about what's going on
# if delay is not None, it sleeps at each
# erase/program, just to add a bit of behavior.
#
# "countdown" specifies the number of RDSR commands
# that need to happen after a sector erase or page
# program before the operation completes.
class dummyspi:
    def __init__(self, vendor=b'\x20', memtype=b'\xBA', capacity=b'\x18', verbose=True, delay = None, countdown=5):
        self.vendor = vendor
        self.memtype = memtype
        self.capacity = capacity
        self.status = 0
        self.verbose = verbose
        self.delay = delay
        self.countdown_max = countdown
        self.countdown = 0
        
    def command(self, code, dummy, readbytes, data_in = bytearray()):
        if code == SPIFlash.cmd['RDID']:
            return self.vendor + self.memtype + self.capacity

        if code == SPIFlash.cmd['RES']:
            return b'\x00'

        if code == SPIFlash.cmd['WREN']:
            self.status = self.status | 0x2

        if code == SPIFlash.cmd['WRDI']:
            self.status = self.status & 0xFD

        if code == SPIFlash.cmd['RDSR']:
            if self.status & 0x1:
                if self.countdown == self.countdown_max:
                    self.status = 0
                    self.countdown = 0
                else:
                    self.countdown = self.countdown + 1
            return bytes([self.status])

        if code == SPIFlash.cmd['3SE']:
            if not (self.status & 0x2):
                print("wtf are you doing, no write enable set")
                return
            if self.verbose:
                print("erasing sector", hexlify(data_in))
            if self.delay:
                time.sleep(self.delay)
            if self.countdown_max:
                self.status = 0x1
                self.countdown = 0
            else:
                self.status = 0

        if code == SPIFlash.cmd['3PP']:
            if not (self.status & 0x2):
                print("wtf are you doing, no write enable set")
                return
            if self.verbose:
                print("programming page", hexlify(data_in[0:3]))
            if self.delay:
                time.sleep(self.delay)
            if self.countdown_max:
                self.status = 0x1
                self.countdown = 0
            else:
                self.status = 0

        if code == SPIFlash.cmd['3READ']:
            # whatever
            return bytes(readbytes)
