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

function QuestSyncPro:SendQuestDataToGroup()
    if IsInGroup() then
        local playerQuestData = self:GetPlayerQuestData()
        local serializedData = self:SerializeQuestData(playerQuestData)

        -- Отправляем данные другим игрокам в группе
        C_ChatInfo.SendAddonMessage("QuestSyncPro", serializedData, "PARTY")
    end
end

function QuestSyncPro:SerializeQuestData(QuestData)
    -- Преобразуем таблицу с данными в строку для отправки
    local data = ""
    for _, quest in ipairs(QuestData) do
        local campaingID = quest.campaingID
        if not campaingID then
            campaingID = -1
        end
        data = data .. quest.questName .. "#" .. quest.progress .. "#" .. quest.questID .. "#" .. campaingID .. ";"
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

            table.insert(playerQuestData, {
                questName = info.title,
                progress = progress,
                questID = info.questID,
                campaingID = info.campaignID
            })
        end
    end

    return playerQuestData
end

-- function QuestSyncPro:GetFakePlayerQuestData()
--     local playerQuestData = {}
--     PartyPlayersQuests = {}

--     -- Используем новую функцию для получения количества квестов в журнале
--     local numEntries = C_QuestLog.GetNumQuestLogEntries()
--     for i = 1, numEntries do
--         local info = C_QuestLog.GetInfo(i)
--         if info and not info.isHeader and info.questID ~= 53916 then
--             local progress = ""
--             local objectives = C_QuestLog.GetQuestObjectives(info.questID)

--             for _, objective in ipairs(objectives) do
--                 progress = "- " .. progress .. objective.text .. "\n" -- .. " (" .. objective.numFulfilled .. "/" .. objective.numRequired .. ")\n"
--             end

--             if C_QuestLog.IsComplete(info.questID) then
--                 progress = "|cff00FF00 Completed |r"
--             end

--             table.insert(playerQuestData, {
--                 questName = info.title,
--                 progress = progress,
--                 questID = info.questID,
--                 campaingID = info.campaignID
--             })

--             PartyPlayersQuests[info.questID] = true
--         end
--     end

--     table.insert(playerQuestData, {
--         questName = "Секретный квест",
--         progress = "Доехать до Варшавы 0/1",
--         questID = "1234",
--         campaingID = 4
--     })

--     return playerQuestData
-- end

function QuestSyncPro:ReceiveQuestDataFromPlayer(playerName, data)
    -- Преобразуем строку обратно в таблицу и сохраняем для игрока
    local playerQuestData = {}
    for questString in string.gmatch(data, "([^;]+)") do
        local questName, progress, questID, campaingID = strsplit("#", questString)
        if campaingID == 0 then
            campaingID = nil
        end
        table.insert(playerQuestData, {
            questName = questName,
            progress = progress,
            questID = questID,
            campaingID = campaingID
        })
        -- PartyPlayersQuests[questID] = true
    end

    -- Сохраняем данные квестов для игрока
    QuestData[playerName] = playerQuestData

    -- Обновляем интерфейс
    self:UpdateUI()
end

function QuestSyncPro:SyncQuestData()
    -- Отправляем данные другим игрокам
    self:SendQuestDataToGroup()

    -- Собираем собственные данные
    local playerName = UnitName("player")
    QuestData[playerName] = self:GetPlayerQuestData()
    -- QuestData["ТестовыйЧел"] = self:GetFakePlayerQuestData()

    -- Обновляем интерфейс
    self:UpdateUI()
end
