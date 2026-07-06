local function createRevIndex(values)
    local revIndex = {}
    for index, value in ipairs(values) do
        revIndex[value] = index
    end
    return revIndex
end

local Karabiner = {}
Karabiner.__index = Karabiner

function Karabiner.new(config)
    return setmetatable({
        cliPath = config.cliPath,
        inputProfile = config.inputProfile,
        normalProfile = config.normalProfile,
        layerProfiles = config.layerProfiles,
        layerIndex = createRevIndex(config.layerProfiles),
        currentProfile = nil,
    }, Karabiner)
end

function Karabiner:switchTo(profileName)
    if self.currentProfile == profileName then
        return
    end

    self.currentProfile = profileName
    local cmd = string.format('"%s" --select-profile "%s"', self.cliPath, profileName)
    os.execute(cmd)
end

function Karabiner:switchToInputProfile()
    self:switchTo(self.inputProfile)
end

function Karabiner:switchToNormalProfile()
    self:switchTo(self.normalProfile)
end

function Karabiner:cycleLayerProfile()
    local currentIndex = self.layerIndex[self.currentProfile] or 0
    local nextIndex = (currentIndex % #self.layerProfiles) + 1
    self:switchTo(self.layerProfiles[nextIndex])
end

return {
    new = Karabiner.new,
}
