local focus = require("modules.focus")
local modifierTaps = require("modules.modifier_taps")

local watchers = {}

local function buildWatchKeycodes()
    local keycodes = hs.keycodes.map
    return {
        [keycodes.tab] = true,
        [keycodes["return"]] = true,
        [keycodes.up] = true,
        [keycodes.down] = true,
        [keycodes.left] = true,
        [keycodes.right] = true,
    }
end

local function handleFocusEvent(event, watchKeycodes, karabiner)
    local eventType = event:getType()

    if eventType == hs.eventtap.event.types.keyUp then
        if watchKeycodes[event:getKeyCode()] then
            focus.switchForFocusedElement(karabiner)
        end
    else
        focus.switchForFocusedElement(karabiner)
    end

    return false
end

local function createEventTap(runtime)
    local eventTypes = {
        hs.eventtap.event.types.flagsChanged,
    }

    local watchKeycodes = nil
    if runtime.config.features.focusProfileSwitching then
        watchKeycodes = buildWatchKeycodes()
        eventTypes = {
            hs.eventtap.event.types.keyUp,
            hs.eventtap.event.types.keyDown,
            hs.eventtap.event.types.flagsChanged,
            hs.eventtap.event.types.leftMouseUp,
            hs.eventtap.event.types.rightMouseUp,
        }
    end

    local commandTap = modifierTaps.leftCommand(runtime.config.timing.modifierDoubleTapSeconds, function()
        runtime.karabiner:cycleLayerProfile()
    end)

    local optionTap = modifierTaps.leftOption(runtime.config.timing.modifierDoubleTapSeconds, function()
        runtime.inputMethod:cycle()
    end)

    return hs.eventtap.new(eventTypes, function(event)
        if commandTap:handle(event) then
            return true
        end

        if optionTap:handle(event) then
            return true
        end

        if runtime.config.features.focusProfileSwitching then
            return handleFocusEvent(event, watchKeycodes, runtime.karabiner)
        end

        return false
    end)
end

local function createAppWatcher(runtime)
    return hs.application.watcher.new(function(_, eventType, app)
        if eventType ~= hs.application.watcher.activated or not app then
            return
        end

        local bundleID = app:bundleID()
        if runtime.config.apps.chineseInput[bundleID] then
            runtime.inputMethod:switchToChinese()
        else
            runtime.inputMethod:switchToEnglish()
        end
    end)
end

local function createFocusPollTimer(runtime)
    return hs.timer.new(runtime.config.timing.focusPollSeconds, function()
        focus.switchForFocusedElement(runtime.karabiner)
    end)
end

function watchers.start(runtime)
    local refs = {
        eventTap = createEventTap(runtime),
        appWatcher = createAppWatcher(runtime),
        focusPollTimer = createFocusPollTimer(runtime),
    }

    refs.eventTap:start()
    refs.appWatcher:start()

    if runtime.config.features.focusProfileSwitching then
        refs.focusPollTimer:start()
    end

    if runtime.windowLayout then
        refs.windowLayout = runtime.windowLayout:start()
    end

    function refs.stop()
        refs.eventTap:stop()
        refs.appWatcher:stop()
        refs.focusPollTimer:stop()

        if refs.windowLayout and refs.windowLayout.stop then
            refs.windowLayout.stop()
        end

        if refs.caffeinateWatcher then
            refs.caffeinateWatcher:stop()
        end
    end

    refs.caffeinateWatcher = hs.caffeinate.watcher.new(function(eventType)
        if eventType == hs.caffeinate.watcher.systemDidWake then
            refs.eventTap:start()
            refs.appWatcher:start()

            if runtime.config.features.focusProfileSwitching then
                refs.focusPollTimer:start()
            end

            if refs.windowLayout and refs.windowLayout.start then
                refs.windowLayout.start()
            end
        end
    end)
    refs.caffeinateWatcher:start()

    return refs
end

return watchers
