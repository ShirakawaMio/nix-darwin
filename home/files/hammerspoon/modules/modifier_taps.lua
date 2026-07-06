local modifierTaps = {}

local LEFT_COMMAND_FLAG = 0x08
local LEFT_OPTION_FLAG = 0x20

local modifierDefinitions = {
    leftCommand = {
        flagName = "cmd",
        rawFlag = LEFT_COMMAND_FLAG,
    },
    leftOption = {
        flagName = "alt",
        rawFlag = LEFT_OPTION_FLAG,
    },
}

local Detector = {}
Detector.__index = Detector

function Detector.new(definition, intervalSeconds, action)
    return setmetatable({
        definition = definition,
        intervalSeconds = intervalSeconds,
        action = action,
        wasPressed = false,
        pendingTap = false,
        lastTapTime = 0,
    }, Detector)
end

function Detector:handle(event)
    if event:getType() ~= hs.eventtap.event.types.flagsChanged then
        return false
    end

    local flags = event:getFlags()
    local rawFlags = event:getRawEventData().CGEventData.flags
    local isTargetSide = (rawFlags & self.definition.rawFlag) ~= 0
    local isPressed = flags[self.definition.flagName] and isTargetSide

    if isPressed then
        self.wasPressed = true
        return false
    end

    if not self.wasPressed or flags[self.definition.flagName] then
        return false
    end

    self.wasPressed = false

    local now = hs.timer.secondsSinceEpoch()
    if self.pendingTap and (now - self.lastTapTime) < self.intervalSeconds then
        self.pendingTap = false
        self.action()
        return true
    end

    self.pendingTap = true
    self.lastTapTime = now
    hs.timer.doAfter(self.intervalSeconds, function()
        self.pendingTap = false
    end)

    return false
end

function modifierTaps.leftCommand(intervalSeconds, action)
    return Detector.new(modifierDefinitions.leftCommand, intervalSeconds, action)
end

function modifierTaps.leftOption(intervalSeconds, action)
    return Detector.new(modifierDefinitions.leftOption, intervalSeconds, action)
end

return modifierTaps
