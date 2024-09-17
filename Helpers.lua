Helpers = {}


function Helpers:IsQuestFiltered(quest)
    if (QuestSyncProDB.filter == "All") then
        return false
    end
    if (QuestSyncProDB.filter == "Campaign" and quest.campaingID) then
        return false
    end
    if (QuestSyncProDB.filter == "Side" and not quest.campaingID) then
        return false
    end
    return true
end

function Helpers:IsPlayerName(name)
    local playerName = UnitName("player")
    return playerName == name
end

function Helpers:PlayerHasQuest(questID)
    if C_QuestLog.IsComplete(questID) then
        return true
    end

    local playerName = UnitName("player")
    for _, quest in ipairs(QuestData[playerName]) do
        if quest.questID == questID then
            return true
        end
    end

    return false
end


function Helpers:ShareQuest(questID)
    -- Пытаемся передать квест другим игрокам в группе
    if C_QuestLog.IsPushableQuest(questID) then
        QuestLogPushQuest()
        print("Sharing quest ID: " .. questID)
    else
        print("Cannot share quest ID: " .. questID)
    end
end
