-- WoW Forever starter macros. GPL-3.0, like GM Genie.
-- Keep messages short: each newline is a separate whisper or mail.
-- NAME is replaced with the recipient; SUBJECT prompts for text in whispers.
-- Discipline durations are editable examples, not server policy.
GMGenie.starterMacros = {
    whispers = {
        ["Support - First reply"] = "Hello NAME, a GM is reviewing your request. Are you available to help us investigate?\nPlease describe what happened and what you expected to happen.",
        ["Support - More details"] = "NAME, please send the quest, NPC or item name, your location, and the steps that caused the issue. A screenshot or exact error message also helps.",
        ["Support - Before teleport"] = "NAME, may I teleport you to help with your request? Please leave combat and tell me when you are ready.",
        ["Support - Stuck character"] = "NAME, please describe where you are stuck. If a relog does not help, I can move you to a safe location with your permission.",
        ["Support - Resolved"] = "Thanks for your help, NAME. Is the issue resolved now? If it happens again, please submit a new report with the steps to reproduce it.",
        ["Warning - Chat conduct"] = "NAME, please stop the disruptive chat and keep discussion respectful. Continued disruption may result in a mute.",
        ["Example - Custom topic (prompt)"] = "Hello NAME, I am following up about SUBJECT. Please let me know when you are available.",
    },
    mail = {
        ["Support - Offline follow-up"] = {
            subject = "Support follow-up",
            macro = "Hello NAME, a GM tried to reach you about your report. Please contact a GM when you are online and include the report details so we can continue investigating.",
        },
        ["Support - Bug details"] = {
            subject = "More details for your report",
            macro = "Hello NAME, please update your bug report with the quest, NPC or item name, location, steps to reproduce, and expected result. Screenshots or exact errors help us investigate.",
        },
        ["Warning - Conduct reminder"] = {
            subject = "Conduct reminder",
            macro = "Hello NAME, please keep chat respectful and avoid spam or harassment. If you believe a moderation action was made in error, contact a GM with the details for review.",
        },
        ["Example - Two-part welcome"] = {
            subject = "Welcome to the server",
            macro = "Welcome to the server, NAME! If you need help, contact a GM or submit an issue report with a clear description.\nFor bug reports, include your location, the quest or NPC name, what you expected, and what happened instead. Thank you for helping improve the server.",
        },
    },
    -- Example game_tele names; verify these against your server database. These move the selected player.
    tele = {
        ["Return - Before GM teleport"] = "RECALL",
        ["GM - GM Island"] = "GMIsland",
        ["Alliance - Stormwind"] = "Stormwind",
        ["Alliance - Ironforge"] = "Ironforge",
        ["Alliance - Darnassus"] = "Darnassus",
        ["Horde - Orgrimmar"] = "Orgrimmar",
        ["Horde - Thunder Bluff"] = "ThunderBluff",
        ["Horde - Undercity"] = "Undercity",
        ["Neutral - Booty Bay"] = "BootyBay",
        ["Neutral - Ratchet"] = "Ratchet",
    },
    -- Mute durations are minutes; ban durations use s/m/h/d. No permanent bans.
    -- false uses GM-only announcements, rather than a server-wide announcement.
    mute = {
        ["Spam - 5 minutes"] = { duration = "5", reason = "Repeated chat spam", announceToServer = false },
        ["Disruptive chat - 15 minutes"] = { duration = "15", reason = "Disruptive chat after a warning", announceToServer = false },
        ["Harassment - 60 minutes"] = { duration = "60", reason = "Harassment after a warning", announceToServer = false },
    },
    charBan = {
        ["Disruption - 1 hour"] = { duration = "1h", reason = "Repeated disruption after a warning", announceToServer = false },
        ["Exploit abuse - 1 day"] = { duration = "1d", reason = "Confirmed exploit abuse", announceToServer = false },
    },
    accBan = {
        ["Cheating - 1 day"] = { duration = "1d", reason = "Confirmed cheating", announceToServer = false },
    },
    ipBan = {
        ["Spam source - 1 hour"] = { duration = "1h", reason = "Repeated spam from this IP", announceToServer = false },
    },
};

function GMGenie.installStarterMacros()
    for category, examples in pairs(GMGenie.starterMacros) do
        GMGenie_SavedVars[category] = GMGenie_SavedVars[category] or {};
        for name, value in pairs(examples) do
            if GMGenie_SavedVars[category][name] == nil then
                GMGenie_SavedVars[category][name] = type(value) == "table" and CopyTable(value) or value;
            end
        end
    end
    GMGenie_SavedVars.starterMacrosVersion = 1;
end
