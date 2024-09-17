-- QuestSyncPro.lua
QuestSyncPro = CreateFrame("Frame")
QuestSyncPro:RegisterEvent("ADDON_LOADED")
QuestSyncPro:RegisterEvent("GROUP_ROSTER_UPDATE")
QuestSyncPro:RegisterEvent("QUEST_LOG_UPDATE")

QuestData = {} -- Данные о квестах каждого члена группы
PartyPlayersQuests = {}

SLASH_QUESTSYNCPRO1 = "/qspro"
SlashCmdList["QUESTSYNCPRO"] = function(msg)
    if QuestSyncPro.uiFrame and QuestSyncPro.uiFrame:IsShown() then
        QuestSyncPro:HideUI()
    else
        QuestSyncPro:ShowUI()
    end
end

function QuestSyncPro:Initialize()
    -- Инициализация аддона
    print("Initializing QuestSync Pro...")

    if not QuestSyncProDB then
        QuestSyncProDB = {
            filter = "All" -- Фильтр по умолчанию
        }
    end

    -- Регистрируем обработку сообщений аддона
    C_ChatInfo.RegisterAddonMessagePrefix("QuestSyncPro")
    self:RegisterEvent("CHAT_MSG_ADDON")

    -- Синхронизируем данные с группой при изменении состава группы
    self:RegisterEvent("GROUP_ROSTER_UPDATE")

    -- Создаем кнопку в интерфейсе
    self:CreateInterfaceButton()

    QuestSyncPro:SyncQuestData()
end

-- Обработчик событий
QuestSyncPro:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == "QuestSyncPro" then
        print("QuestSync Pro Loaded!")
        QuestSyncPro:Initialize()
    elseif event == "GROUP_ROSTER_UPDATE" then
        QuestSyncPro:SyncWithGroup()
    elseif event == "QUEST_LOG_UPDATE" then
        QuestSyncPro:SyncQuestData()
    elseif event == "CHAT_MSG_ADDON" then
        QuestSyncPro:OnEvent(event, arg1, ...)
    end
end)

function QuestSyncPro:OnEvent(event, prefix, message, channel, sender)
    if event == "CHAT_MSG_ADDON" and prefix == "QuestSyncPro" then
        local playerName, server = strsplit("-", sender)
        if playerName ~= UnitName("player") then
            PartyPlayersQuests = {}
            self:ReceiveQuestDataFromPlayer(sender, message)
        end
    end
end

