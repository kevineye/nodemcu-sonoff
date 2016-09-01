# NodeMCU Sonoff MQTT Controller

MQTT controller for Sonoff devices.


## Hardware

[Sonoff](https://www.itead.cc/sonoff-wifi-wireless-switch.html) is fairly high quality, low cost ESP8266-based WiFi IoT device to switch AC current on and off. It comes with software, but can be disassembled and reprogrammed.

There is also a variant called Sonoff RF which has RF-based remote control in addition to WiFi. This software does not have programming for the RF features, but they probably do not get in the way.

### Programming the hardware

Refer to this blog post about how to connect the Sonoff to an FTDI cable for reprogramming:

  * http://tech.scargill.net/itead-slampher-and-sonoff/


## Software

The lua-based NodeMCU firmware must be built and flashed to the ESP8266 in the sonoff. Then the code is uploaded to the firmware's filesystem.

### Build NodeMCU firmware

Build the firmware using the [NodeMCU cloud build service](https://nodemcu-build.com/). Select the following modules:

  * CJSON
  * file (default)
  * GPIO (default)
  * MQTT
  * net (default)
  * node (default)
  * timer (default)
  * UART (default)
  * WiFi (default)

Download the "float" version of the build.

### Upload firmware (serial)

Download [esptool,py](https://github.com/themadinventor/esptool) to flash firmware.

    export NODEMCU_DEV=/dev/tty.usbserial*
    alias esptool='esptool.py --port $NODEMCU_DEV --baud 115200'
    
    # upgrade esp SDK
    esptool erase_flash
    esptool write_flash -fm dio -fs 32m 0x00000 nodemcu-master-....bin 0x3fc000 esp_init_data_default.bin
    
    # or just flash
    esptool write_flash -fm dio -fs 32m 0x00000 nodemcu-master-....bin

The sonoff may need to be powered on with the button held down to enter reprogramming mode where it will respond to esptool commands.

### Terminal monitor/REPL (serial)

    miniterm.py $NODEMCU_DEV 115200

### Local upload all files (serial)

Download [nodemcu-uploader.py](https://github.com/kmpm/nodemcu-uploader) for local (USB/serial) management.

    export NODEMCU_DEV=/dev/tty.usbserial*
    alias nodemcu-uploader='nodemcu-uploader --port $NODEMCU_DEV'

    nodemcu-uploader upload --restart *.lua *.json && \
    nodemcu-uploader terminal

### Remote management (wifi)

Download [loatool.py](https://github.com/4refr0nt/luatool) for remote (telnet) management.

    export NODEMCU_HOST=<device-ip>
    export NODEMCU_PORT=2323
    alias luatool='luatool --ip $NODEMCU_HOST:$NODEMCU_PORT'

    luatool --restart --src <file.lua>
  
    telnet $NODEMCU_HOST $NODEMCU_PORT
    nc $NODEMCU_HOST $NODEMCU_PORT

These commands only work if a telnet server is running on the device. If the device is otherwise inaccessible, be very
careful not to upload code (such as a broken init.lua) that will fail to connect to wifi, have an error before running 
the telnet server or reboot without allowing time to send some commands.


## Operation

The reprogrammed Sonoff will connect to WiFi and MQTT with the settings in config.json. Make sure these are correct before transferring to the device.

### Feedback

When powered on, the LED will give three quick flashes every three seconds until it is successfully connected to WiFi and MQTT. The LED will give two slower flashes when the relay is switched.

### Button

Pushing the button will toggle the relay (and flash the LED and send the appropriate MQTT messages).

### MQTT

The device will subscribe and publish with a configurable root path, called "/sonoff" below.

| Topic                   | Pub/Sub   | Payload   | Description |
|-------------------------|-----------|-----------|-------------|
| `/sonoff/switch`        | publish   | *JSON*    | State of relay is published at connect and when relay switches. Retained. |
| `/sonoff/switch/toggle` | subscribe | *any*     | Toggles relay. Same as pushing the button. |
| `/sonoff/switch/set`    | subscribe | ON or OFF | Turns relay on or off. |
| `/sonoff/ping`          | subscribe | *any*     | Triggers publishing status message. |
| `/sonoff/status`        | publish   | *JSON*    | Status info is published at connect and retained. Contains IP address and other info. Marked offline when device is not connected. Retained. |
| `/sonoff/config`        | subscribe | key=value | Persistently sets a configuration value in config.json. |
| `/sonoff/config`        | subscribe | ping      | Triggers publishing config JSON dump. |
| `/sonoff/config`        | subscribe | restart   | Restarts the device. |
| `/sonoff/config/json`   | publish   | *JSON*    | Configuration values (initially from config.json) are dumped in response to config ping. |
