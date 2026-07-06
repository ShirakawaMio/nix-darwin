local config = {}

config.karabiner = {
    cliPath = "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli",
    inputProfile = "test",
    layerProfiles = {
        "test",
        "ctrl",
        "Sym",
    },
}

config.inputMethods = {
    english = "com.apple.keylayout.ABC",
    chinese = "com.tencent.inputmethod.wetype.pinyin",
    cycle = {
        "com.apple.keylayout.ABC",
        "com.tencent.inputmethod.wetype.pinyin",
    },
}

config.apps = {
    chineseInput = {
        ["com.tencent.xinWeChat"] = true,
        ["net.whatsapp.WhatsApp"] = true,
        ["com.openai.chat"] = true,
    },
    inputProfile = {
        ["com.microsoft.VSCode"] = true,
        ["com.microsoft.Outlook"] = true,
        ["com.microsoft.Word"] = true,
        ["com.microsoft.Excel"] = true,
        ["com.microsoft.Powerpoint"] = true,
        ["com.microsoft.onenote.mac"] = true,
        ["org.mozilla.nightly"] = true,
        ["org.mozilla.firefox"] = true,
        ["com.apple.Safari"] = true,
        ["com.apple.Terminal"] = true,
        ["com.googlecode.iterm2"] = true,
        ["com.apple.mail"] = true,
        ["com.apple.ScreenContinuity"] = true,
        ["com.tencent.xinWeChat"] = true,
        ["com.openai.chat"] = true,
        ["com.valvesoftware.steam"] = true,
        ["com.valvesoftware.steam.helper"] = true,
        ["org.tabby"] = true,
        ["com.vivaldi.Vivaldi"] = true,
        ["com.google.Chrome"] = true,
        ["com.apple.TextEdit"] = true,
    },
}

config.features = {
    focusProfileSwitching = false,
}

config.timing = {
    modifierDoubleTapSeconds = 0.3,
    focusPollSeconds = 1,
}

config.windowLayout = {
    settingKey = "mio.windowLayout.snapshot",
    standardWindowsOnly = true,
    visibleWindowsOnly = true,
    preserveZOrder = true,
    restoreDuration = 0,
    newSpaceFillDuration = 0,
    newSpaceFillPollSeconds = 0.15,
    newSpaceFillMaxAttempts = 20,
    newSpaceFillFocusDelaySeconds = 0.25,
    hotkeys = {
        save = {
            mods = { "ctrl", "alt", "cmd" },
            key = "s",
        },
        restore = {
            mods = { "ctrl", "alt", "cmd" },
            key = "r",
        },
        newSpaceFill = {
            mods = { "fn", "shift" },
            key = "f",
        },
    },
}

return config
