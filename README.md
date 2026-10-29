# Nerves System for reComputer Industrial R20xx (64-bit)

[![REUSE status](https://api.reuse.software/badge/github.com/alde103/nerves_system_recomputer_r20xx)](https://api.reuse.software/info/github.com/alde103/nerves_system_recomputer_r20xx)

This is a Nerves System for the [Seeed Studio reComputer Industrial
R20xx](https://wiki.seeedstudio.com/recomputer_industrial_r20xx_getting_start/)
series (for example the
[R2035-10](https://www.seeedstudio.com/reComputer-Industrial-R2035-10-p-6543.html)),
a fanless DIN-rail edge controller built around the Raspberry Pi Compute Module 5.

It is a fork of [nerves_system_rpi5](https://github.com/nerves-project/nerves_system_rpi5)
with the reComputer specific device tree overlay, RTC/watchdog driver and kernel
options added on top. The `upstream` remote tracks the official system, so
updates are merged from there.

| Feature        | Description |
| -------------- | ----------- |
| CPU            | Broadcom BCM2712 quad-core Cortex-A76 @ 2.4 GHz (Raspberry Pi CM5) |
| Memory         | 2 GB to 16 GB LPDDR4X (model dependent) |
| Storage        | 16 GB to 64 GB eMMC (model dependent), M.2 M-key 2280 NVMe slot |
| Linux kernel   | 6.18 w/ Raspberry Pi patches |
| IEx terminal   | HDMI and USB keyboard (can be changed to UART) |
| Ethernet       | ETH0 10/100/1000 (PoE PD), ETH1 10/100 (USB) |
| Serial         | 1x RS232, 3x RS485 (isolated, USB CDC ACM) |
| Digital I/O    | 8x isolated DI (5-24 V DC), 8x isolated DO (< 60 V DC) |
| USB            | 3x USB-A 3.0, 1x USB-A 2.0, 1x USB-C (flashing only) |
| Display        | 2x HDMI 2.0 |
| WiFi/Bluetooth | On-module CYW43455 (`brcmfmac`) - VintageNet |
| RTC            | PCF8563 with supercapacitor backup, also used as a hardware watchdog |
| Security       | ATECC608A, optional TPM 2.0 (Infineon SLB9670) |
| Other          | RGB user LED, buzzer, M.2 B-key (4G/5G), Mini-PCIe (4G/LoRa), M.2 M-key (Hailo-8 on -12 models) |

## Using

Add the system to your project's `mix.exs`:

```elixir
@all_targets [:recomputer_r20xx]

def deps do
  [
    {:nerves_system_recomputer_r20xx,
     github: "alde103/nerves_system_recomputer_r20xx",
     runtime: false,
     targets: :recomputer_r20xx}
  ]
end
```

Then build with `MIX_TARGET=recomputer_r20xx`. See the [Getting started
guide](https://nerves.hexdocs.pm/getting-started.html#creating-a-new-nerves-app)
for more information.

When working on the system itself, clone it next to your project and use a path
dependency so that the system is compiled locally:

```elixir
{:nerves_system_recomputer_r20xx,
 path: "../nerves_system_recomputer_r20xx",
 runtime: false,
 targets: :recomputer_r20xx,
 nerves: [compile: true]}
```

See [Customizing systems](https://nerves.hexdocs.pm/customizing-systems.html)
for more details.

## Flashing the eMMC

The R20xx boots from its internal eMMC. To write firmware to it the first time:

1. Move the boot switch to the `BOOT` position (nRPI_BOOT low).
2. Connect the USB-C port to your computer and power the device.
3. Run `sudo rpiboot -d mass-storage-gadget64` from
   [raspberrypi/usbboot](https://github.com/raspberrypi/usbboot). The eMMC
   shows up as a USB mass storage device.
4. Run `mix burn` (or `fwup` with your `.fw` file) and select that device.
5. Power off, move the boot switch back to its normal position and power on.

After that, use `mix upload` or NervesHub for updates.

**IMPORTANT:** Automatic rollback uses the Raspberry Pi `tryboot` feature,
which needs a recent bootloader EEPROM. If your CM5 has an old bootloader,
update it using `rpiboot -d recovery5` from usbboot before relying on
auto-revert in the field.

## Digital I/O

The DI/DO mapping below is derived from the Seeed wiki's Linux GPIO numbers
(RP1 base 569, PCA9535 base 623, PCA9554 base 639). **It still needs to be
confirmed on hardware.** Open lines by label with
[Circuits.GPIO](https://hexdocs.pm/circuits_gpio), and use
`Circuits.GPIO.enumerate()` to check the names on your device.

| Port | Line                     | Seeed wiki GPIO |
| ---- | ------------------------ | --------------- |
| DI1  | RP1 GPIO19               | 588 |
| DI2  | RP1 GPIO20               | 589 |
| DI3  | RP1 GPIO21               | 590 |
| DI4  | RP1 GPIO26               | 595 |
| DI5  | RP1 GPIO4                | 573 |
| DI6  | RP1 GPIO5                | 574 |
| DI7  | RP1 GPIO6                | 575 |
| DI8  | RP1 GPIO7                | 576 |
| DO1  | PCA9535 line 15 (`DO_1`) | 638 |
| DO2  | PCA9535 line 14 (`DO_2`) | 637 |
| DO3  | PCA9535 line 13 (`DO_3`) | 636 |
| DO4  | PCA9535 line 12 (`DO_4`) | 635 |
| DO5  | RP1 GPIO8                | 577 |
| DO6  | RP1 GPIO9                | 578 |
| DO7  | RP1 GPIO25               | 594 |
| DO8  | RP1 GPIO27               | 596 |

```elixir
{:ok, do1} = Circuits.GPIO.open("DO_1", :output)
Circuits.GPIO.write(do1, 1)
```

Other named lines on the I/O expanders include `485_1_120R_EN` and
`485_2_120R_EN` (RS485 termination), `SIM_MUX_SEL`, `M2B_POWER_OFF` and the
LoRaWAN reset lines. `RS485_POWER_EN`, `CH344_RST` and `TPM_RST` are held high by
the device tree.

## Serial ports

The isolated serial ports come from a WCH CH344 USB to quad UART chip handled by
the `cdc_acm` driver:

| Port    | Device         |
| ------- | -------------- |
| RS232-1 | `/dev/ttyACM0` |
| RS485-2 | `/dev/ttyACM1` |
| RS485-3 | `/dev/ttyACM2` |
| RS485-4 | `/dev/ttyACM3` |

The numbering shifts if other CDC ACM devices (such as an expansion board) enumerate first.

## LEDs and buzzer

The RGB user LED is available as `led-red`, `led-green` and `led-blue` under
`/sys/class/leds`. The buzzer is a `gpio-beeper` input device.

## RTC and watchdog

The PCF8563 is handled by Seeed's `rtc-pcf8563w` driver (in `package/rtc-pcf8563w`).
The driver also registers the RTC timer as a second hardware watchdog
(120 s default timeout). Nerves' `heart` uses the BCM2712 watchdog
(`/dev/watchdog0`), so the RTC watchdog stays idle unless you open it.
`CONFIG_WATCHDOG_NOWAYOUT` is enabled, so once it is opened it can't be stopped.

## UPS

The optional supercapacitor UPS signals power loss on GPIO16 (active low). Watch
it with Circuits.GPIO interrupts and shut down cleanly from your application.

## Status

This system has not been tested on hardware yet. Expected to work: boot from eMMC, A/B updates with automatic
rollback, ETH0, WiFi, I/O expanders, DI/DO, RS232/RS485, RTC, LEDs, buzzer,
EEPROM, NVMe.

To verify on hardware:

* DI/DO line mapping (table above)
* ETH1 USB Ethernet chip (`CONFIG_USB_NET_SMSC95XX` is enabled, matching the R11xx)
* TPM 2.0 (`tpm_tis_spi` on SPI2 CS1)

Not supported yet: Hailo-8, 4G/5G modules, LoRaWAN, UPS shutdown helper.

## Provisioning devices

This system supports storing provisioning information in a small key-value store
outside of any filesystem. Provisioning is an optional step and reasonable
defaults are provided if this is missing.

Provisioning information can be queried using the Nerves.Runtime KV store's
[`Nerves.Runtime.KV.get/1`](https://nerves-runtime.hexdocs.pm/Nerves.Runtime.KV.html#get/1)
function.

Keys used by this system are:

Key                    | Example Value     | Description
:--------------------- | :---------------- | :----------
`nerves_serial_number` | `"12345678"`      | By default, this string is used to create unique hostnames and Erlang node names. If unset, it defaults to part of the Raspberry Pi's device ID.

The normal procedure would be to set these keys once in manufacturing or before
deployment and then leave them alone.

For example, to provision a serial number on a running device, run the following
and reboot:

```elixir
iex> cmd("fw_setenv nerves_serial_number 12345678")
```

This system supports setting the serial number offline. To do this, set the
`NERVES_SERIAL_NUMBER` environment variable when burning the firmware. If you're
programming the eMMC using `fwup`, the commandline is:

```sh
sudo NERVES_SERIAL_NUMBER=12345678 fwup path_to_firmware.fw
```

Serial numbers are stored on the eMMC, so reflashing with the `complete` task
will require reprogramming them. The numbers are stored
in a U-boot environment block. This is a special region that is separate from
the application partition so reformatting the application partition will not
lose the serial number or any other data stored in this block.

Additional key value pairs can be provisioned by overriding the default
provisioning.conf file location by setting the environment variable
`NERVES_PROVISIONING=/path/to/provisioning.conf`. The default provisioning.conf
will set the `nerves_serial_number`, if you override the location to this file,
you will be responsible for setting this yourself.

## Linux kernel and RPi firmware/userland

There's a subtle coupling between the `nerves_system_br` version and the Linux
kernel version used here. `nerves_system_br` provides the versions of
`rpi-userland` and `rpi-firmware` that get installed. I prefer to match them to
the Linux kernel to avoid any issues. Unfortunately, none of these are tagged by
the Raspberry Pi Foundation so I either attempt to match what's in Raspbian or
take versions of the repositories that have similar commit times.

## Linux kernel configuration

The Linux kernel compiled for Nerves is a stripped down version of the default
Raspberry Pi Linux kernel. This is done to remove unnecessary features, select
some Nerves-specific features like F2FS and SquashFS support, and to save space.

