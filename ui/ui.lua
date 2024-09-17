function QuestSyncPro:CreateInterfaceButton()
    -- Создаем кнопку
    local button = CreateFrame("Button", "QuestSyncProButton", UIParent, "UIPanelButtonTemplate")
    button:SetSize(80, 30) -- Размер кнопки
    button:SetText("QuestSync") -- Текст на кнопке
    button:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", -10, -10) -- Позиция рядом с миникартой

    -- Устанавливаем поведение при нажатии
    button:SetScript("OnClick", function()
        if QuestSyncPro.uiFrame and QuestSyncPro.uiFrame:IsShown() then
            QuestSyncPro:HideUI()
        else
            QuestSyncPro:ShowUI()
        end
    end)

    -- Перетаскивание кнопки
    button:SetMovable(true)
    button:EnableMouse(true)
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", button.StartMoving)
    button:SetScript("OnDragStop", button.StopMovingOrSizing)
end
