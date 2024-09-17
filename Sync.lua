-- QuestSyncPro_Sync.lua
function QuestSyncPro:SyncWithGroup()
    -- Логика для синхронизации данных квестов с другими членами группы
    if IsInGroup() then
        print("Syncing quest data with group...")
        self:SendQuestDataToGroup()
    else
        print("Not in a group.")
    end
end

-- Функция для создания паузы
local function Sleep(seconds, callback)
    C_Timer.After(seconds, callback)
end

local function SendMessagesWithRateLimit(messages, delay)
    local index = 1

    local function sendNextMessage()
        if index <= #messages then
            C_ChatInfo.SendAddonMessage("QuestSyncPro", messages[index], "PARTY")
            index = index + 1
            Sleep(delay, sendNextMessage) -- Задержка перед следующим сообщением
        end
    end

    sendNextMessage() -- Старт отправки сообщений
end

function QuestSyncPro:SendQuestDataToGroupPart()
    if IsInGroup() then
        local playerQuestData = self:GetPlayerQuestData()

        local playerName = UnitName("player")
        local dataToSend = {}
        if QuestData[playerName] then
            for _, quest in pairs(playerQuestData) do
                if not QuestData[playerName][quest.questID] or QuestData[playerName][quest.questID].progress ~=
                    quest.progress then
                    dataToSend[quest.questID] = quest
                end
            end
            dataToSend = {}
        else
            dataToSend = playerQuestData
        end

        local data = self:SerializeQuestData(dataToSend)

        SendMessagesWithRateLimit(data, 0.3)

        -- Отправляем данные другим игрокам в группе
        -- C_ChatInfo.SendAddonMessage("QuestSyncPro", serializedData, "PARTY")
    end
end


function QuestSyncPro:SendQuestDataToGroup()
    if IsInGroup() then
        local playerQuestData = self:GetPlayerQuestData()

        local data = self:SerializeQuestData(playerQuestData)

        SendMessagesWithRateLimit(data, 0.3)
    end
end

function QuestSyncPro:SerializeQuestData(QuestData)
    -- Преобразуем таблицу с данными в строку для отправки
    local data = {}
    for _, quest in pairs(QuestData) do
        local campaingID = quest.campaingID
        if not campaingID then
            campaingID = -1
        end
        local message = quest.questName .. "#" .. quest.progress .. "#" .. quest.questID .. "#" .. campaingID .. ";"

        table.insert(data, message)

        -- Отправляем данные другим игрокам в группе
        -- C_ChatInfo.SendAddonMessage("QuestSyncPro", data, "PARTY")
    end
    return data
end

function QuestSyncPro:GetPlayerQuestData()
    local playerQuestData = {}

    -- Используем новую функцию для получения количества квестов в журнале
    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader then
            local progress = ""
            local objectives = C_QuestLog.GetQuestObjectives(info.questID)

            for _, objective in ipairs(objectives) do
                progress = "- " .. progress .. objective.text .. "\n" -- .. " (" .. objective.numFulfilled .. "/" .. objective.numRequired .. ")\n"
            end

            if C_QuestLog.IsComplete(info.questID) then
                progress = "|cff00FF00 Completed |r"
            end

            playerQuestData[info.questID] = {
                questName = info.title,
                progress = progress,
                questID = info.questID,
                campaingID = info.campaignID
            }
        end
    end

    return playerQuestData
end

function QuestSyncPro:ReceiveQuestDataFromPlayer(playerName, data)
    if not QuestData[playerName] then
        QuestData[playerName] = {}
    end

    for questString in string.gmatch(data, "([^;]+)") do
        local questName, progress, questID, campaingID = strsplit("#", questString)
        if questID ~= nil then
            if campaingID == "-1" then
                campaingID = nil
            end
            -- Сохраняем данные квестов для игрока
            QuestData[playerName][questID] = {
                questName = questName,
                progress = progress,
                questID = questID,
                campaingID = campaingID
            }
            PartyPlayersQuests[questID] = true
        end
    end

    -- Обновляем интерфейс
    self:UpdateUI()
end

function QuestSyncPro:SyncQuestData()
    -- Отправляем данные другим игрокам
    self:SendQuestDataToGroupPart()

    -- Собираем собственные данные
    local playerName = UnitName("player")
    QuestData[playerName] = self:GetPlayerQuestData()

    -- Обновляем интерфейс
    self:UpdateUI()
end
