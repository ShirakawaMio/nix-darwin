-- init.lua

pcall(require, "hs.ipc")

local config = require("modules.config")
local karabiner = require("modules.karabiner").new(config.karabiner)
local inputMethod = require("modules.input_method").new(config.inputMethods)
local watchers = require("modules.watchers")

if _G.MIO_HS_RUNTIME and _G.MIO_HS_RUNTIME.stop then
    _G.MIO_HS_RUNTIME.stop()
end

_G.MIO_HS_RUNTIME = watchers.start({
    config = config,
    karabiner = karabiner,
    inputMethod = inputMethod,
})
