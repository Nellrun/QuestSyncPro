local function CreateQuestSyncUI()
    -- Создаем основное окно аддона
    local frame = CreateFrame("Frame", "QuestSyncProMainFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(400, 600)
    frame:SetPoint("CENTER")
    frame:Hide()

    tinsert(UISpecialFrames, frame:GetName())

    -- Moving
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Overlay
    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlight")
    frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 5, 0)
    frame.title:SetText("QuestSync Pro")

    -- Создаем список для отображения квестов группы
    local questList = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    questList:SetPoint("TOPLEFT", 10, -70)
    questList:SetSize(360, 520)

    local scrollChild = CreateFrame("Frame", nil, questList)
    scrollChild:SetSize(360, 520)
    questList:SetScrollChild(scrollChild)

    frame.questList = questList
    frame.scrollChild = scrollChild

    -- Создаем кнопки фильтра
    local allButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    allButton:SetPoint("TOPLEFT", 10, -30)
    allButton:SetSize(120, 30)
    allButton:SetText("All")
    allButton:SetScript("OnClick", function()
        QuestSyncPro:SetFilter("All")
    end)

    local storyButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    storyButton:SetPoint("TOP", 0, -30)
    storyButton:SetSize(120, 30)
    storyButton:SetText("Campaign")
    storyButton:SetScript("OnClick", function()
        QuestSyncPro:SetFilter("Campaign")
    end)

    local sideButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    sideButton:SetPoint("TOPRIGHT", -10, -30)
    sideButton:SetSize(120, 30)
    sideButton:SetText("Side quests")
    sideButton:SetScript("OnClick", function()
        QuestSyncPro:SetFilter("Side")
    end)

    frame.allButton = allButton
    frame.storyButton = storyButton
    frame.sideButton = sideButton

    return frame
end

function QuestSyncPro:UpdateFilterButtons()
    if (QuestSyncProDB.filter == "All") then
        self.uiFrame.allButton:Disable()
        self.uiFrame.storyButton:Enable()
        self.uiFrame.sideButton:Enable()
    end
    if (QuestSyncProDB.filter == "Campaign") then
        self.uiFrame.allButton:Enable()
        self.uiFrame.storyButton:Disable()
        self.uiFrame.sideButton:Enable()
    end
    if (QuestSyncProDB.filter == "Side") then
        self.uiFrame.allButton:Enable()
        self.uiFrame.storyButton:Enable()
        self.uiFrame.sideButton:Disable()
    end
end

function QuestSyncPro:DrawPlayerQuests(parentFrame, yOffset, playerName, playerQuestData)
    -- Создаем блок с фоном для каждого игрока
    local blockFrame = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    blockFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {
            left = 4,
            right = 4,
            top = 4,
            bottom = 4
        }
    })
    blockFrame:SetBackdropColor(0, 0, 0, 0.5) -- Фон блока
    blockFrame:SetPoint("TOPLEFT", 0, yOffset)
    blockFrame:SetSize(360, 1) -- Начальный размер блока, будет расширяться

    -- Отображаем имя игрока
    local playerText = blockFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerText:SetPoint("TOPLEFT", 10, -10)
    playerText:SetText(playerName .. " - Quests:")
    playerText:SetTextColor(1, 0.8, 0) -- Цвет текста

    local blockYOffset = -30 -- Отступ внутри блока

    -- Отображаем каждый квест и его прогресс
    for _, quest in ipairs(playerQuestData) do
        if not (Helpers:IsQuestFiltered(quest)) and quest.questID ~= nil  then
            local questText = blockFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            questText:SetPoint("TOPLEFT", 40, blockYOffset)
            questText:SetWidth(280) -- Максимальная ширина текста (уменьшена, чтобы добавить кнопку справа)
            questText:SetJustifyH("LEFT")
            questText:SetWordWrap(true) -- Перенос текста

            local questStyle = "|cffFFFF00"


            if not Helpers:IsPlayerName(playerName) then
                if not Helpers:PlayerHasQuest(quest.questID) then
                    questStyle = "|cffFF0000"
                end
            end

            questText:SetText(questStyle .. quest.questName .. "|r \n" .. quest.progress)

            if (quest.progress == "|cff00FF00 Completed |r") then
                local completeButton = CreateFrame("Button", nil, blockFrame, "UIPanelButtonTemplate")
                completeButton:SetSize(20, 20)
                completeButton:SetPoint("TOPRIGHT", -10, blockYOffset)

                completeButton:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Check") -- Пример иконки
            end

            if C_QuestLog.IsPushableQuest(quest.questID) and not PartyPlayersQuests[quest.questID] then
                -- Добавляем кнопку для обмена квестом с иконкой
                local shareButton = CreateFrame("Button", nil, blockFrame, "UIPanelButtonTemplate")
                shareButton:SetSize(20, 20)
                shareButton:SetPoint("TOPLEFT", 10, blockYOffset)

                -- Устанавливаем иконку для кнопки
                shareButton:SetNormalTexture("Interface\\FriendsFrame\\BroadcastIcon") -- Пример иконки
                shareButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square") -- Подсветка при наведении

                shareButton:SetScript("OnClick", function()
                    Helpers:ShareQuest(quest.questID)
                end)
            end

            blockYOffset = blockYOffset - questText:GetStringHeight() - 10
        end
    end

    -- Обновляем высоту блока в зависимости от содержимого
    blockFrame:SetHeight(-blockYOffset + 20)
    yOffset = yOffset - blockFrame:GetHeight() - 10 -- Отступ между блоками
    return yOffset
end

function QuestSyncPro:UpdateUI()
    if not self.uiFrame then
        return
    end

    -- Полностью пересоздаем scrollChild
    if self.uiFrame.scrollChild then
        self.uiFrame.scrollChild:Hide() -- Скрываем старый фрейм
        self.uiFrame.scrollChild:SetParent(nil) -- Отсоединяем его от родителя
    end

    self:UpdateFilterButtons()

    -- Создаем новый scrollChild
    local scrollChild = CreateFrame("Frame", nil, self.uiFrame.questList)
    scrollChild:SetSize(380, 500) -- Устанавливаем новый размер
    self.uiFrame.questList:SetScrollChild(scrollChild)
    self.uiFrame.scrollChild = scrollChild

    local yOffset = -10

    yOffset = self:DrawPlayerQuests(scrollChild, yOffset, UnitName("player"), QuestData[UnitName("player")])
    for playerName, playerQuestData in pairs(QuestData) do
        if playerName ~= UnitName("player") then
            yOffset = self:DrawPlayerQuests(scrollChild, yOffset, playerName, playerQuestData)
        end
    end

    -- Обновляем высоту scrollChild в зависимости от данных
    scrollChild:SetHeight(-yOffset + 20)
end

function QuestSyncPro:SetFilter(filter)
    QuestSyncProDB.filter = filter
    self:UpdateUI()
end

function QuestSyncPro:ShowUI()
    if not self.uiFrame then
        self.uiFrame = CreateQuestSyncUI()
    end

    -- Синхронизируем данные при открытии окна
    self:SyncQuestData()

    -- Показываем окно
    self.uiFrame:Show()
end

function QuestSyncPro:HideUI()
    if self.uiFrame then
        self.uiFrame:Hide()
    end
end
