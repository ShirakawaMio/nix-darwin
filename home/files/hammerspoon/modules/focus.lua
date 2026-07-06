local focus = {}

local textRoles = {
    AXTextField = true,
    AXTextArea = true,
    AXTextView = true,
}

function focus.isTextInputFocused()
    local focused = hs.uielement.focusedElement()
    if not focused then
        return false
    end

    return textRoles[focused:role()] == true
end

function focus.switchForFocusedElement(karabiner)
    if focus.isTextInputFocused() then
        karabiner:switchToInputProfile()
    else
        karabiner:switchToNormalProfile()
    end
end

return focus
