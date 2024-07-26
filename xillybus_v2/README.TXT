README file for a custom Xillybus IP core bundle
================================================

Core ID: 18100 ("atri_bootload_v2" by allison.122@osu.edu)
Target: Xilinx Spartan 6

This is a kit for modifying the demo bundle into the custom configuration
(which is detailed below). Please follow the three steps below.

(1) Replace the existing xillybus.v and xillybus_core.v files with the ones
    in this bundle.

(2) Replace the xillybus_core.ngc file in the demo bundle's core/ subdirectory
    with the one in this bundle.

(3) Edit xillydemo.v (or xillydemo.vhd) to reflect the desired application
    of this custom IP core. The template.v (or template.vhd) file in the
    "instantiation templates" directory of this bundle contains the signal
    outline and instantiation format. Note that unlike its xillydemo.*
    counterpart, there is no application logic (e.g. loopback FIFOs) in
    the instantiation templates. It's however recommended to follow the
    spirit of the xillydemo.* examples when attaching the application logic
    to the core.

To modify a design other than the demo bundle, equivalent actions should be
taken on the design's hierarchy. It's recommended to first delete the
xillybus_core.ngc file, and attempt to build the project, just to verify
that the build fails as the file is missing. Only then add the new
replacement.

The device files and their attributes are listed below. These are detected
automatically by the host's driver, so there is no specific driver for the
IP core attached.

NOTE: The DMA buffers mentioned are allocated on the host's RAM, not from
      resources on the FPGA.

------- /dev/xillybus_spi_in or \\.\xillybus_spi_in

  Downstream (host to FPGA):
    Data width: 8 bits
    DMA buffers: 16 x 4 kB = 64 kB
    Flow control: Synchronous
    Seekable: No
    FPGA RAM for DMA acceleration: None

------- /dev/xillybus_spi_out or \\.\xillybus_spi_out

  Upstream (FPGA to host):
    Data width: 8 bits
    DMA buffers: 16 x 4 kB = 64 kB
    Flow control: Synchronous
    Seekable: No

------- /dev/xillybus_icap_in or \\.\xillybus_icap_in

  Downstream (host to FPGA):
    Data width: 16 bits
    DMA buffers: 16 x 4 kB = 64 kB
    Flow control: Synchronous
    Seekable: No
    FPGA RAM for DMA acceleration: None

