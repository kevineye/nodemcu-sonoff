function read_config_json()
    file.open("config.json", "r")
    config = cjson.decode(file.read())
    file.close()
end

function startup()
    if file.open("init.lua") == nil then
        print("Aborting -- init.lua deleted or renamed")
    else
        file.close("init.lua")
        table.insert(MAIN_FILES, 1, "mqtt.lua")
        table.insert(MAIN_FILES, 1, "telnet.lua")
        for i = 1, #MAIN_FILES do
            print("Loading " .. MAIN_FILES[i])
            dofile(MAIN_FILES[i])
        end
    end
end

function wait_for_ready()
    gpio.mode(PIN_LED, gpio.OUTPUT)
    tmr.alarm(TIMER_READY, 3000, tmr.ALARM_AUTO, function()
        if (ready) then
            tmr.unregister(TIMER_READY)
        else
            gpio.serout(PIN_LED, gpio.LOW, { 50000, 50000 }, 3, 1)
        end
    end)
end

function connect_to_wifi(cb)
    print("Connecting to WiFi access point...")
    wifi.setmode(wifi.STATION)
    wifi.sta.config(config.wifi_ssid, config.wifi_password)
    tmr.alarm(TIMER_WIFI, 1000, tmr.ALARM_AUTO, function()
        if wifi.sta.getip() == nil then
            print("Waiting for IP address...")
        else
            tmr.stop(TIMER_WIFI)
            print("WiFi connection established, IP address: " .. wifi.sta.getip())
            print("Waiting to initialize...")
            tmr.alarm(TIMER_STARTUP, 3000, tmr.ALARM_SINGLE, cb)
        end
    end)
end

dofile("config.lua")
wait_for_ready()
read_config_json()
connect_to_wifi(startup)
