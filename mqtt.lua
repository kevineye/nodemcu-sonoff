m = mqtt.Client(config.mqtt_clientid, 60, config.mqtt_user, config.mqtt_password)
m:lwt(config.mqtt_prefix .. "/status", '{"status":"offline"}', 0, 1)

mqtt_cb = {}

mqtt_cb.connect = function(m)
    print("Connected to MQTT host " .. config.mqtt_host .. ":" .. config.mqtt_port .. "\n")
    ready = true
    m:subscribe(config.mqtt_prefix .. "/ping", 0)
    m:subscribe(config.mqtt_prefix .. "/config", 0)
    sendstatus()
end

mqtt_cb.offline = function(m)
    print("\n\nDisconnected from MQTT")
    print("Heap: ", node.heap())
end

mqtt_cb.message = function(m, t, pl)
    print("Received MQTT topic '" .. t .. "', payload '" .. pl .. "'")
    if (t == config.mqtt_prefix .. "/ping") then
        sendstatus()
    elseif (t == config.mqtt_prefix .. "/config") then
        if (pl == "ping") then
            local msg = cjson.encode(config)
            print("Sending " .. config.mqtt_prefix .. "/config/json " .. msg)
            m:publish(config.mqtt_prefix .. "/config/json", msg, 0, 0)
        elseif (pl == "restart") then
            node.restart()
        else
            local key, value = string.match(pl, "([^=]+)=(.*)")
            if (key) then
                config[key] = value
                file.remove("config.json")
                file.open("config.json", "w")
                file.write(cjson.encode(config))
                file.close()
                print("Updated config " .. key .. " = " .. value)
            end
        end
    end
end

function sendstatus()
    local msg = '{"status":"online","ip":"' .. wifi.sta.getip() .. '","heap":' .. node.heap() .. ',"minutesOnline":' .. math.floor(tmr.now() / 60000000) .. '}'
    print("Sending " .. config.mqtt_prefix .. "/status " .. msg)
    m:publish(config.mqtt_prefix .. "/status", msg, 0, 1)
end

tmr.alarm(TIMER_STATUS, 5 * 60000, tmr.ALARM_AUTO, sendstatus)

m:on("connect", mqtt_cb.connect)
m:on("offline", mqtt_cb.offline)
m:on("message", mqtt_cb.message)

m:connect(config.mqtt_host, config.mqtt_port, 0, 1)
