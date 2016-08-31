# NodeMCU Base

Overall NodeMCU docs:

 * https://nodemcu.readthedocs.io/en/dev/

## Lua firmware setup

#### Build firmware
 
 * https://nodemcu-build.com/
 
#### Upload firmware

Download [esptool,py](https://github.com/themadinventor/esptool) to flash firmware.

    export NODEMCU_DEV=/dev/tty.wchusbserial*
    alias esptool='esptool.py --port $NODEMCU_DEV --baud 115200'
    
    # upgrade esp SDK
    esptool erase_flash
    esptool write_flash -fm dio -fs 32m 0x00000 nodemcu-master-....bin 0x3fc000 esp_init_data_default.bin
    
    # or just flash
    esptool write_flash -fm dio -fs 32m 0x00000 nodemcu-master-....bin

#### Simple terminal monitor/REPL

    miniterm.py $NODEMCU_DEV 115200

## File management

#### Local upload all files

Download [nodemcu-uploader.py](https://github.com/kmpm/nodemcu-uploader) for local (USB/serial) management.

    export NODEMCU_DEV=/dev/tty.wchusbserial*
    alias nodemcu-uploader='nodemcu-uploader --port $NODEMCU_DEV'

    nodemcu-uploader upload --restart *.lua && \
    nodemcu-uploader terminal

#### Remote upload one file

Download [loatool.py](https://github.com/4refr0nt/luatool) for remote (telnet) management.

    export NODEMCU_HOST=192.168.1.104
    export NODEMCU_PORT=2323
    alias luatool='luatool --ip $NODEMCU_HOST:$NODEMCU_PORT'

    luatool --restart --src <file.lua>
  
    nc $NODEMCU_HOST $NODEMCU_PORT
