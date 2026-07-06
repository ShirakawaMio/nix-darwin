local function createRevIndex(values)
    local revIndex = {}
    for index, value in ipairs(values) do
        revIndex[value] = index
    end
    return revIndex
end

local InputMethod = {}
InputMethod.__index = InputMethod

function InputMethod.new(config)
    return setmetatable({
        english = config.english,
        chinese = config.chinese,
        cycleSources = config.cycle,
        cycleIndex = createRevIndex(config.cycle),
    }, InputMethod)
end

function InputMethod:switchTo(sourceID)
    if hs.keycodes.currentSourceID() ~= sourceID then
        hs.keycodes.currentSourceID(sourceID)
    end
end

function InputMethod:switchToEnglish()
    self:switchTo(self.english)
end

function InputMethod:switchToChinese()
    self:switchTo(self.chinese)
end

function InputMethod:cycle()
    local current = hs.keycodes.currentSourceID()
    local currentIndex = self.cycleIndex[current] or 0
    local nextIndex = (currentIndex % #self.cycleSources) + 1
    self:switchTo(self.cycleSources[nextIndex])
end

return {
    new = InputMethod.new,
}
