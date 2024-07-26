# ATRI Bootloader

This is the basic firmware that the "no FX2" ATRI boots into at
power on. It's currently still a work in progress but close to
the point it needs to be at.

It's based on the Xillybus PCIe core and requires the Xillybus
driver. When present you see two device files at the moment:

* /dev/xillybus_spi_in - takes data going TO the SPI device
* /dev/xillybus_spi_out - received data FROM the SPI device

A third will be added (/dev/xillybus_icap_in) shortly to add
the reboot functionality.

There will be a basic Python interface to this firmware added
soon, but the overall interface is easy. The chip is selected
(CS goes low) when /dev/xillybus_spi_in _and_ /dev/xillybus_spi_out
are both open. Then you write bytes to /dev/xillybus_spi_in,
and read bytes from /dev/xillybus_spi_out.

So to send an SPI flash command, you need to open both files,
then write the bytes (plus dummy bytes for data you want to read!)
to /dev/xillybus_spi_in and then read from /dev/xillybus_spi_out.

There are FIFOs in and out, so the commands can be large, but
you should limit yourself to 512 bytes at a time: as in,
you can write a full 512 bytes to the device, but you should
read the 512 bytes from the device before sending more.
(Xillybus actually has even larger buffers but it probably
makes sense to batch it this way anyway).
