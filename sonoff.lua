-- mqtt ------------------------------------------------------------------

m:on("connect", function(m)
    mqtt_cb.connect(m)
    m:subscribe(config.mqtt_prefix .. "/switch/toggle", 0)
    m:subscribe(config.mqtt_prefix .. "/switch/set", 0)
end)

m:on("message", function(m, t, pl)
    mqtt_cb.message(m, t, pl)
    if (t == config.mqtt_prefix .. "/switch/toggle") then
        turnonoff(not onoff)
    elseif (t == config.mqtt_prefix .. "/switch/set") then
        turnonoff(string.upper(pl) == "ON")
    end
end)

function publishonoff()
    local msg = '{"state":"' .. (onoff and "ON" or "OFF") .. '"}'
    m:publish(config.mqtt_prefix .. "/switch", msg, 0, 1)
end


-- relay -----------------------------------------------------------------

gpio.mode(PIN_SWITCH, gpio.OUTPUT)
gpio.write(PIN_SWITCH, gpio.LOW)

function turnonoff(state)
    onoff = state
    print("Switching " .. (onoff and "on" or "off"))
    gpio.write(PIN_SWITCH, onoff and gpio.HIGH or gpio.LOW)
    gpio.serout(PIN_LED, gpio.LOW, { 200000, 200000 }, 2, 1)
    publishonoff()
end


-- button ----------------------------------------------------------------

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

function buttonpress()
    local down = gpio.read(PIN_BUTTON) == gpio.LOW
    if (down) then
        turnonoff(not onoff)
    end
end

gpio.mode(PIN_BUTTON, gpio.INT, gpio.PULLUP) -- see https://github.com/hackhitchin/esp8266-co-uk/pull/1
gpio.trig(PIN_BUTTON, 'both', debounce(buttonpress))
