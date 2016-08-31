PIN_SWITCH = 6
PIN_BUTTON = 3
onoff = false

m = mqtt.Client(config.mqtt_clientid, 60, config.mqtt_user, config.mqtt_password)
m:lwt(config.mqtt_prefix .. "/status", '{"status":"offline"}', 0, 1)

sendonoff = function()
    local msg = '{"state":"' .. (onoff and "ON" or "OFF") .. '"}'
    m:publish(config.mqtt_prefix .. "/switch", msg, 0, 1)
end

sendstatus = function()
    local msg = '{"status":"online","ip":"' .. wifi.sta.getip() .. '","heap":' .. node.heap() .. ',"minutesOnline":' .. math.floor(tmr.now() / 60000000) .. '}'
    print("Sending " .. config.mqtt_prefix .. "/status " .. msg)
    m:publish(config.mqtt_prefix .. "/status", msg, 0, 1)
end

gpio.mode(PIN_SWITCH, gpio.OUTPUT)
gpio.write(PIN_SWITCH, gpio.LOW)
turnonoff = function(state)
    onoff = state
    print("Switching " .. (onoff and "on" or "off"))
    gpio.write(PIN_SWITCH, onoff and gpio.HIGH or gpio.LOW)
    gpio.serout(PIN_LED, gpio.LOW, { 200000, 200000 }, 2, 1)
    sendonoff()
end

m:on("connect", function(m)
    print("Connected to MQTT host " .. config.mqtt_host .. ":" .. config.mqtt_port .. "\n")
    m:subscribe(config.mqtt_prefix .. "/ping", 0)
    m:subscribe(config.mqtt_prefix .. "/config", 0)
    m:subscribe(config.mqtt_prefix .. "/switch/toggle", 0)
    m:subscribe(config.mqtt_prefix .. "/switch/set", 0)
    ready = true
    sendstatus()
    sendonoff()
end)

m:on("offline", function(m)
    print("\n\nDisconnected from MQTT")
    print("Heap: ", node.heap())
end)

m:on("message", function(m, t, pl)
    print("Received MQTT topic '" .. t .. "', payload '" .. pl .. "'")
    if (t == config.mqtt_prefix .. "/ping") then
        sendstatus()
    elseif (t == config.mqtt_prefix .. "/config") then
        if (pl == "ping") then
            local msg = cjson.encode(config)
            print("Sending " .. config.mqtt_prefix .. "/config/json " .. msg)
            m:publish(config.mqtt_prefix .. "/config/json", msg, 0, 0)
        else
            local key, value = string.match(pl, "([^=]+)=(.*)")
            config[key] = value
            file.remove("config.json")
            file.open("config.json", "w")
            file.write(cjson.encode(config))
            file.close()
            print("Updated config " .. key .. " = " .. value)
        end
    elseif (t == config.mqtt_prefix .. "/switch/toggle") then
        turnonoff(not onoff)
    elseif (t == config.mqtt_prefix .. "/switch/set") then
        turnonoff(string.upper(pl) == "ON")
    end
end)

tmr.alarm(0, 5 * 60000, tmr.ALARM_AUTO, sendstatus)

m:connect(config.mqtt_host, config.mqtt_port, 0, 1)

function debounce(func)
    local last = 0
    local delay = 50000 -- 50ms * 1000 as tmr.now() has μs resolution

    return function(...)
        local now = tmr.now()
        local delta = now - last
        if delta < 0 then delta = delta + 2147483647 end; -- proposed because of delta rolling over, https://github.com/hackhitchin/esp8266-co-uk/issues/2
        if delta < delay then return end;

        last = now
        return func(...)
    end
end

function buttonPress()
    local down = gpio.read(PIN_BUTTON) == gpio.LOW
    if (down) then
        turnonoff(not onoff)
    end
end

gpio.mode(PIN_BUTTON, gpio.INT, gpio.PULLUP) -- see https://github.com/hackhitchin/esp8266-co-uk/pull/1
gpio.trig(PIN_BUTTON, 'both', debounce(buttonPress))
