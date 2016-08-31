PIN_LED         = 7

file.open("config.json", "r")
config = cjson.decode(file.read())
file.close()

function startup()
    if file.open("init.lua") == nil then
        print("init.lua deleted or renamed")
    else
        print("Running")
        file.close("init.lua")
        dofile("telnet.lua")
        dofile("main.lua")
    end
end

ready = false
gpio.mode(PIN_LED, gpio.OUTPUT)
tmr.alarm(2, 3000, tmr.ALARM_AUTO, function()
    if (ready) then
        tmr.unregister(2)
    else
        gpio.serout(PIN_LED, gpio.LOW, { 50000, 50000 }, 3, 1)
    end
end)

print("Connecting to WiFi access point...")
wifi.setmode(wifi.STATION)
wifi.sta.config(config.wifi_ssid, config.wifi_password)
tmr.alarm(1, 1000, tmr.ALARM_AUTO, function()
    if wifi.sta.getip() == nil then
        print("Waiting for IP address...")
    else
        tmr.stop(1)
        print("WiFi connection established, IP address: " .. wifi.sta.getip())
        print("You have 3 seconds to abort")
        print("Waiting...")
        tmr.alarm(0, 3000, tmr.ALARM_SINGLE, startup)
    end
end)
