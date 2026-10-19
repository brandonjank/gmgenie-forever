--This file is part of Game Master Genie.
--Copyright 2011-2014 Chocochaos

--Game Master Genie is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 of the License.
--Game Master Genie is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
--You should have received a copy of the GNU General Public License along with Game Master Genie. If not, see <http://www.gnu.org/licenses/>.

GMGenie.Macros.Mail = {};

GMGenie.Macros.Mail.curMailMessage = '';


-- The core's legacy mail parser uses strtok on literal quotes; backslash escaping
-- cannot represent an embedded quote. Reject it before sending any part of a macro.
function GMGenie.Macros.Mail.build(name,subject,text)
    if type(name)~="string" then return nil,"Enter a player first name or Forever display name."; end
    if GMGenie.CommandForms then
        local canonical=GMGenie.CommandForms.encode({kind="player",name="player"},name);
        if not canonical then return nil,"Enter a player first name or Forever display name."; end
        name=canonical;
    elseif name:match("^[%a\128-\255]+$") then -- legacy callers without the form module
    else return nil,"Use the player's unique first name."; end
    if type(subject)~="string" or type(text)~="string" then return nil,"Mail needs a subject and message."; end
    if subject:find('[%z\1-\31\127|"]') or text:gsub("\n",""):find('[%z\1-\31\127|"]') then
        return nil,"Mail cannot contain straight double quotes, chat markup or control characters. Use curly quotation marks instead.";
    end
    if subject=="" or text=="" then return nil,"Mail needs a non-empty subject and message."; end
    local lines={strsplit("\n",text)}; local commands={};
    for index,line in ipairs(lines) do
        line=line:gsub("NAME",function() return name; end);
        if line=="" then return nil,"Remove empty mail lines; each line becomes a separate mail."; end
        local title=subject..(#lines>1 and (" "..index.."/"..#lines) or "");
        local command='.send mail '..name..' "'..title..'" "'..line..'"';
        if #command>255 then return nil,"A mail line exceeds the 255-byte command limit. Shorten the subject or message."; end
        commands[#commands+1]=command;
    end
    return commands;
end

function GMGenie.Macros.Mail.run(name, title)
    local mail=GMGenie_SavedVars.mail[title];
    local commands,err=GMGenie.Macros.Mail.build(name,mail and mail.subject,mail and mail.macro);
    if not commands then GMGenie.showGMMessage("Mail not sent: "..err); return false; end
    for _,command in ipairs(commands) do
        if GMGenieForever.SendChatMessage(command,"GUILD")==false then GMGenie.showGMMessage("Mail send stopped. Check chat before retrying; earlier lines may already have been sent."); return false; end
    end
    return true;
end

function GMGenie.Macros.Mail.runFromSpy(self)
    CloseDropDownMenus();
    if GMGenie.Spy.currentRequest["name"] then
        GMGenie.Macros.Mail.run(GMGenie.Spy.currentRequest["name"], self.value);
    end
end

function GMGenie.Macros.Mail.addToUnitMenu()
    GMGenieForever.popupMenus["GMGenie_Mail"] = {};
    local MailTemp = GMGenie.pairsByKeys2(GMGenie_SavedVars.mail);
    for _, name in pairs(MailTemp) do
        table.insert(GMGenieForever.popupMenus["GMGenie_Mail"], "GMGenie_Mail_" .. name);
        GMGenieForever.popupButtons["GMGenie_Mail_" .. name] = { text = name, dist = 0, };
    end

    table.insert(GMGenieForever.popupMenus["GMGenie_Mail"], "GMGenie_MailOptions");
    GMGenieForever.popupButtons["GMGenie_MailOptions"] = { text = "Manage macros", dist = 0, };
end

function GMGenie.Macros.Mail.loadDropdown(_, level)
    local info = UIDropDownMenu_CreateInfo();
    info.hasArrow = false;
    info.notCheckable = true;
    info.isTitle = true;
    info.text = "Mail Macros";
    UIDropDownMenu_AddButton(info, level);

    local MailTemp = GMGenie.pairsByKeys2(GMGenie_SavedVars.mail);
    for _, name in pairs(MailTemp) do
        local info = UIDropDownMenu_CreateInfo();
        info.hasArrow = false;
        info.notCheckable = true;
        info.text = name;
        info.func = GMGenie.Macros.Mail.runFromSpy;
        info.value = name;
        UIDropDownMenu_AddButton(info, level);
    end

    local info = UIDropDownMenu_CreateInfo();
    info.hasArrow = false;
    info.notCheckable = true;
    info.text = "Manage Macros";
    info.func = GMGenie.Macros.Mail.showOptions;
    UIDropDownMenu_AddButton(info, level);
end
