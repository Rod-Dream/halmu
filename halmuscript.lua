--[[
627445/974331
obfuscated — UI methods preserved
]]
local bit32=bit32 or bit

-----------------------------------------------------------
-- client protection / detection soften
-----------------------------------------------------------
pcall(function()
    local Players = game:GetService("Players")
    local RS = game:GetService("ReplicatedStorage")
    local LP = Players.LocalPlayer
    local CoreGui = game:GetService("CoreGui")
    local StarterGui = game:GetService("StarterGui")
    local LogService = game:GetService("LogService")
    local ScriptContext = game:GetService("ScriptContext")
    local GuiService = game:GetService("GuiService")

    -- swallow kick/ban style LocalPlayer methods if present
    pcall(function()
        if LP and typeof(LP.Kick) == "function" then
            local oldKick = LP.Kick
            LP.Kick = function(...) end
        end
    end)

    -- block common remote kick/ban namecalls (client-side only; server still authoritative)
    pcall(function()
        if not hookmetamethod or not getnamecallmethod then return end
        local bannedRemoteNames = {
            kick=true, ban=true, punish=true, anticheat=true, detect=true,
            report=true, flag=true, crash=true, log=true, screenshot=true,
            security=true, mod=true, admin=true, watchdog=true, sentinel=true,
        }
        local function isSuspiciousRemoteName(n)
            if type(n) ~= "string" then return false end
            n = string.lower(n)
            for k,_ in pairs(bannedRemoteNames) do
                if string.find(n, k, 1, true) then return true end
            end
            return false
        end
        local old
        old = hookmetamethod(game, "__namecall", newcclosure and newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" or method == "InvokeServer" then
                local name = ""
                pcall(function() name = self.Name end)
                if isSuspiciousRemoteName(name) then
                    return
                end
                -- path check
                local path = ""
                pcall(function()
                    path = self:GetFullName()
                end)
                if isSuspiciousRemoteName(path) then
                    return
                end
            end
            if method == "Kick" or method == "kick" then
                return
            end
            return old(self, ...)
        end) or function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" or method == "InvokeServer" then
                local name = ""
                pcall(function() name = self.Name end)
                if isSuspiciousRemoteName(name) then return end
            end
            if method == "Kick" then return end
            return old(self, ...)
        end)
    end)

    -- hide ScreenGuis from naive CoreGui scanners that look for known cheat UI names
    pcall(function()
        local function randomizeGuiName(inst)
            if not inst then return end
            pcall(function()
                inst.Name = tostring(math.random(100000,999999))
            end)
        end
        task.defer(function()
            task.wait(1)
            for _,n in ipairs({"HalmuESP","HalmuFOV","HalmuIndicators","ExecutorToggleUI","CustomCursorGui"}) do
                local o = CoreGui:FindFirstChild(n)
                if o then randomizeGuiName(o) end
                if LP and LP:FindFirstChild("PlayerGui") then
                    local o2 = LP.PlayerGui:FindFirstChild(n)
                    if o2 then randomizeGuiName(o2) end
                end
            end
        end)
    end)

    -- reduce noisy error spam that some detectors scrape
    pcall(function()
        if ScriptContext and ScriptContext.Error then
            ScriptContext.Error:Connect(function() end)
        end
    end)

    -- soft rate-limit our own combat remotes visually only: no-op placeholder for detectors timing fire bursts
    -- (actual combat still fires; this is just an empty bind so random AC probes don't see nil)
    pcall(function()
        if getconnections then
            -- leave empty; some executors break if we disconnect game connections blindly
        end
    end)

    -- spoof simple identity fields some client ACs read
    pcall(function()
        if setfflag then
            pcall(setfflag, "DebugRunServiceHumanoidCheck", "False")
        end
    end)

    -- prevent simple teleport-flag by keeping HumanoidRootPart network owner local when possible
    pcall(function()
        local RunService = game:GetService("RunService")
        local last = 0
        RunService.Heartbeat:Connect(function()
            if tick() - last < 1 then return end
            last = tick()
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.SetNetworkOwner then
                pcall(function() hrp:SetNetworkOwner(LP) end)
            end
        end)
    end)
end)




local nexlib = {accentclr = Color3.fromRGB(128, 213, 247), dropdownframes = {}, colorpickerframes = {}}

local mouseButtonMap = {[Enum.UserInputType.MouseButton1]="M1",[Enum.UserInputType.MouseButton2]="M2",[Enum.UserInputType.MouseButton3]="M3"}
local keyCodes = {Enum.KeyCode.Unknown,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Up,Enum.KeyCode.Left,Enum.KeyCode.Down,Enum.KeyCode.Right,Enum.KeyCode.Slash,Enum.KeyCode.Tab,Enum.KeyCode.Backspace,Enum.KeyCode.Escape,Enum.KeyCode.RightShift}

local function setListVisible(tbl, sliderValue)
    for k, val in next, tbl do if val == sliderValue or k == sliderValue then return true end end 
end;

local function makeDraggable(clickObject, dragObject)
    pcall(function()
        local isDragging = false;
        local _1297x260, __AOjJzuXUq, _352_117;
        clickObject.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                isDragging = true;
                __AOjJzuXUq = input.Position;
                _352_117 = dragObject.Position;
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then isDragging = false end 
                end)
            end 
        end)
        clickObject.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then _1297x260 = input end 
        end)
        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if input == _1297x260 and isDragging then 
                local _0x3ba8 = input.Position - __AOjJzuXUq;
                dragObject.Position = UDim2.new(_352_117.X.Scale, _352_117.X.Offset + _0x3ba8.X, _352_117.Y.Scale, _352_117.Y.Offset + _0x3ba8.Y)
            end 
        end)
    end)
end;

local uiScreenGui = Instance.new("ScreenGui")
uiScreenGui.Name = "nexlib"
setthreadidentity = setthreadidentity or function() end;
setthreadidentity(8)
uiScreenGui.Parent = game:GetService("CoreGui")
uiScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;

local cursorGui = Instance.new("ScreenGui")
cursorGui.Name = "CustomCursorGui"
cursorGui.ResetOnSpawn = false
cursorGui.Parent = uiScreenGui

local cursorDot = Instance.new("Frame")
cursorDot.Name = "CursorBox"
cursorDot.Size = UDim2.new(0, 6, 0, 6)
cursorDot.BackgroundColor3 = Color3.fromRGB(128, 213, 247)
cursorDot.BorderSizePixel = 0
cursorDot.Visible = false
cursorDot.Parent = cursorGui

local notificationFolder = Instance.new("Folder")
notificationFolder.Name = "NotificationFolder"
notificationFolder.Parent = uiScreenGui;

local notificationQueue = {}
local notifHeight = 22
local notifPadding = 6
local maxNotifs = 8
local defaultNotifDuration = 3
local notifStartPos = 40

local function ensureNotificationFolder()
    local TweenService = game:GetService("TweenService")
    for i, notifData in ipairs(notificationQueue) do
        if notifData.bar and notifData.bar.Parent then
            local targetPos = notifStartPos + (i - 1) * (notifHeight + notifPadding)
            TweenService:Create(notifData.bar, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, 0, 0, targetPos)
            }):Play()
        end
    end
end

function nexlib:Notification(title, desc, duration)
    duration = duration or defaultNotifDuration
    local notifTextFull = tostring(title or "")
    if desc and desc ~= "" then
        notifTextFull = notifTextFull .. "  Â·  " .. tostring(desc)
    end

    local TweenService = game:GetService("TweenService")

    
    while #notificationQueue >= maxNotifs do
        local oldestNotif = table.remove(notificationQueue)
        if oldestNotif and oldestNotif.bar and oldestNotif.bar.Parent then
            local tweenTextOut = TweenService:Create(oldestNotif.label, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                TextTransparency = 1
            })
            local tweenBarOut = TweenService:Create(oldestNotif.bar, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, notifHeight),
                BackgroundTransparency = 1
            })
            local tweenStrokeOut = TweenService:Create(oldestNotif.stroke, TweenInfo.new(0.2), { Transparency = 1 })
            tweenTextOut:Play()
            tweenBarOut:Play()
            tweenStrokeOut:Play()
            tweenBarOut.Completed:Connect(function()
                pcall(function() if oldestNotif.bar then oldestNotif.bar:Destroy() end end)
                ensureNotificationFolder()
            end)
        end
    end

    local notifFrame = Instance.new("Frame")
    notifFrame.Name = "Notification"
    notifFrame.Parent = notificationFolder
    notifFrame.AnchorPoint = Vector2.new(0.5, 0)
    notifFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
    notifFrame.BorderSizePixel = 0
    notifFrame.Position = UDim2.new(0.5, 0, 0, notifStartPos)
    notifFrame.Size = UDim2.new(0, 0, 0, notifHeight)
    notifFrame.ClipsDescendants = true
    notifFrame.BackgroundTransparency = 0.05
    notifFrame.ZIndex = 100

    local fovCircleStroke = Instance.new("UIStroke")
    fovCircleStroke.Parent = notifFrame
    fovCircleStroke.Color = nexlib.accentclr
    fovCircleStroke.Thickness = 1.5
    fovCircleStroke.Transparency = 0.25

    local notifAccent = Instance.new("Frame")
    notifAccent.Name = "AccentLine"
    notifAccent.Parent = notifFrame
    notifAccent.BackgroundColor3 = nexlib.accentclr
    notifAccent.BorderSizePixel = 0
    notifAccent.Size = UDim2.new(0, 3, 1, 0)
    notifAccent.Position = UDim2.new(0, 0, 0, 0)

    local equippedItemName = Instance.new("TextLabel")
    equippedItemName.Parent = notifFrame
    equippedItemName.BackgroundTransparency = 1
    equippedItemName.Position = UDim2.new(0, 14, 0, 0)
    equippedItemName.Size = UDim2.new(1, -28, 1, 0)
    equippedItemName.Font = Enum.Font.Code
    equippedItemName.Text = notifTextFull
    equippedItemName.TextColor3 = Color3.fromRGB(230, 230, 230)
    equippedItemName.TextSize = 13
    equippedItemName.TextXAlignment = Enum.TextXAlignment.Center
    equippedItemName.TextTransparency = 1
    equippedItemName.TextTruncate = Enum.TextTruncate.None

    local TextService = game:GetService("TextService")
    local textSize = TextService:GetTextSize(notifTextFull, 13, Enum.Font.Code, Vector2.new(2000, notifHeight))
    local notifWidth = math.clamp(textSize.X + 48, 200, 480)

    
    table.insert(notificationQueue, 1, {
        notifFrame = notifFrame,
        equippedItemName = equippedItemName,
        fovCircleStroke = fovCircleStroke
    })

    ensureNotificationFolder()

    local tweenBarIn = TweenService:Create(notifFrame, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, notifWidth, 0, notifHeight)
    })
    local tweenTextIn = TweenService:Create(equippedItemName, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    })
    tweenBarIn:Play()
    task.delay(0.08, function() tweenTextIn:Play() end)
    task.delay(duration, function()
        for i, notifData in ipairs(notificationQueue) do
            if notifData.bar == notifFrame then
                table.remove(notificationQueue, i)
                break
            end
        end

        if not notifFrame or not notifFrame.Parent then
            ensureNotificationFolder()
            return
        end

        local tweenTextOut = TweenService:Create(equippedItemName, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            TextTransparency = 1
        })
        local tweenBarOut = TweenService:Create(notifFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, notifHeight),
            BackgroundTransparency = 1
        })
        local tweenStrokeOut = TweenService:Create(fovCircleStroke, TweenInfo.new(0.22), { Transparency = 1 })
        tweenTextOut:Play()
        tweenBarOut:Play()
        tweenStrokeOut:Play()
        tweenBarOut.Completed:Connect(function()
            pcall(function() notifFrame:Destroy() end)
            ensureNotificationFolder()
        end)
    end)
end;

function nexlib:Window(windowTitle)
    local uiVisible = true;
    local firstTabCreated = false;
    local tabList = {} 
    
    local mainFrame = Instance.new("Frame")
    local S = Instance.new("ImageLabel")
    local mainShadow = Instance.new("ImageLabel")
    local tabContainer = Instance.new("Frame")
    local tabSelector = Instance.new("ScrollingFrame")
    local tabSelectorLayout = Instance.new("UIListLayout")
    local tabSelectorPadding = Instance.new("UIPadding")
    local topBar = Instance.new("Frame")
    local windowTitleLabel = Instance.new("TextLabel")
    local topBarLine = Instance.new("Frame")
    
    mainFrame.Name = "MainFrame"
    mainFrame.Parent = uiScreenGui;
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.BackgroundTransparency = 0.15 
    mainFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
    mainFrame.BorderSizePixel = 0;
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.Size = UDim2.new(0, 525, 0, 631)
    mainFrame.Visible = false
    mainFrame.ClipsDescendants = true
    
    S.Name = "OutlineMainFrame1"
    S.Parent = mainFrame; S.BackgroundTransparency = 1; S.Position = UDim2.new(0, 1, 0, 1)
    S.Size = UDim2.new(1, -2, 1, -2) S.Image = "rbxassetid://2592362371"
    S.ImageColor3 = Color3.fromRGB(60, 60, 60) S.ScaleType = Enum.ScaleType.Slice; S.SliceCenter = Rect.new(2, 2, 62, 62)
    
    mainShadow.Name = "OutlineMainFrame2"
    mainShadow.Parent = mainFrame; mainShadow.BackgroundTransparency = 1; mainShadow.Size = UDim2.new(1, 0, 1, 0)
    mainShadow.Image = "rbxassetid://2592362371" mainShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    mainShadow.ScaleType = Enum.ScaleType.Slice; mainShadow.SliceCenter = Rect.new(2, 2, 62, 62)
    
    tabContainer.Name = "ContainerHolderFrame"
    tabContainer.Parent = mainFrame; tabContainer.AnchorPoint = Vector2.new(0.5, 0)
    tabContainer.BackgroundColor3 = Color3.fromRGB(24, 24, 24) tabContainer.Position = UDim2.new(0.5, 0, 0.071, 10)
    tabContainer.Size = UDim2.new(1, -18, 1, -42)
    tabContainer.BackgroundTransparency = 1
    tabContainer.ClipsDescendants = true
    
    tabSelector.Name = "TabHolderFrame"
    tabSelector.Parent = tabContainer; tabSelector.BackgroundTransparency = 1;
    tabSelector.Size = UDim2.new(1, 0, 0, 32) tabSelector.Visible = true;
    tabSelector.CanvasSize = UDim2.new(0, 700, 0, 0)
    tabSelector.ScrollBarThickness = 0;
    
    tabSelectorLayout.Name = "TabHolderFrameLayout"
    tabSelectorLayout.Parent = tabSelector; tabSelectorLayout.FillDirection = Enum.FillDirection.Horizontal;
    tabSelectorLayout.SortOrder = Enum.SortOrder.LayoutOrder; tabSelectorLayout.Padding = UDim.new(0, 4)
    
    tabSelectorPadding.Name = "TabHolderFramePadding"
    tabSelectorPadding.Parent = tabSelector; tabSelectorPadding.PaddingLeft = UDim.new(0, 5)
    
    topBar.Name = "TopBar"
    topBar.Parent = mainFrame; topBar.AnchorPoint = Vector2.new(0.5, 0)
    topBar.BackgroundColor3 = Color3.fromRGB(24, 24, 24) topBar.BorderSizePixel = 0;
    topBar.Position = UDim2.new(0.5, 0, 0, 2) topBar.Size = UDim2.new(1, -5, 0, 28)
    
    windowTitleLabel.Name = "TopBarTitle"
    windowTitleLabel.Parent = topBar; windowTitleLabel.BackgroundTransparency = 1;
    windowTitleLabel.Position = UDim2.new(0, 7, 0, 5) windowTitleLabel.Size = UDim2.new(0, 0, 0, 16)
    windowTitleLabel.Font = Enum.Font.Code; windowTitleLabel.Text = windowTitle;
    windowTitleLabel.TextColor3 = Color3.fromRGB(230, 230, 230) windowTitleLabel.TextSize = 16; windowTitleLabel.TextXAlignment = Enum.TextXAlignment.Left;
    
    topBarLine.Name = "TopBarLine"
    topBarLine.Parent = topBar; topBarLine.BackgroundColor3 = nexlib.accentclr;
    topBarLine.BorderSizePixel = 0; topBarLine.Position = UDim2.new(0, 0, 0, 27) topBarLine.Size = UDim2.new(1, 0, 0, 1)
    
    makeDraggable(topBar, mainFrame)

    local Lighting = game:GetService("Lighting")
    local blurEffect = Lighting:FindFirstChild("ValkUIBlur") or Instance.new("BlurEffect")
    blurEffect.Name = "ValkUIBlur"
    blurEffect.Size = 0
    blurEffect.Parent = Lighting

    local function refreshWindowLayout()
        mainFrame.Visible = uiVisible
        cursorDot.Visible = uiVisible
        game:GetService("UserInputService").MouseBehavior = uiVisible and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
        
        local TweenService = game:GetService("TweenService")
        if uiVisible then
            TweenService:Create(blurEffect, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 18}):Play()
            mainFrame.BackgroundTransparency = 1
            TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.15}):Play()
        else
            TweenService:Create(blurEffect, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 0}):Play()
        end
    end
    
    game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
        if input.KeyCode == Enum.KeyCode.RightShift then 
            uiVisible = not uiVisible;
            refreshWindowLayout()
        end 
    end)

    local CoreGui = game:GetService("CoreGui")
    if CoreGui:FindFirstChild("ExecutorToggleUI") then
        CoreGui.ExecutorToggleUI:Destroy()
    end

    local toggleUIFolder = Instance.new("ScreenGui")
    toggleUIFolder.Name = "ExecutorToggleUI"
    toggleUIFolder.ResetOnSpawn = false
    toggleUIFolder.Parent = CoreGui

    local toggleUIButton = Instance.new("TextButton")
    toggleUIButton.Name = "ToggleFrame"
    toggleUIButton.Size = UDim2.new(0, 65, 0, 36)
    toggleUIButton.Position = UDim2.new(0, 20, 0, 20)
    toggleUIButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    toggleUIButton.BorderSizePixel = 0
    toggleUIButton.Active = true
    toggleUIButton.Draggable = true
    toggleUIButton.Parent = toggleUIFolder

    local toggleUIStroke = Instance.new("UIStroke")
    toggleUIStroke.Color = nexlib.accentclr 
    toggleUIStroke.Thickness = 2
    toggleUIStroke.Parent = toggleUIButton

    local toggleUIText1 = Instance.new("TextLabel")
    toggleUIText1.Size = UDim2.new(1, -6, 0, 16)
    toggleUIText1.Position = UDim2.new(0, 3, 0, 2)
    toggleUIText1.BackgroundTransparency = 1
    toggleUIText1.Text = "Toggle"
    toggleUIText1.TextColor3 = Color3.fromRGB(230, 230, 230)
    toggleUIText1.TextSize = 12
    toggleUIText1.Font = Enum.Font.GothamBold
    toggleUIText1.TextXAlignment = Enum.TextXAlignment.Left
    toggleUIText1.Parent = toggleUIButton

    local toggleUIText2 = Instance.new("TextLabel")
    toggleUIText2.Size = UDim2.new(1, -6, 0, 16)
    toggleUIText2.Position = UDim2.new(0, 3, 0, 18)
    toggleUIText2.BackgroundTransparency = 1
    toggleUIText2.Text = "Look"
    toggleUIText2.TextColor3 = Color3.fromRGB(230, 230, 230)
    toggleUIText2.TextSize = 12
    toggleUIText2.Font = Enum.Font.GothamBold
    toggleUIText2.TextXAlignment = Enum.TextXAlignment.Left
    toggleUIText2.Parent = toggleUIButton

    toggleUIButton.MouseButton1Click:Connect(function()
        uiVisible = not uiVisible
        refreshWindowLayout()
    end)
    
    coroutine.wrap(function()
        while task.wait() do 
            topBarLine.BackgroundColor3 = nexlib.accentclr 
            toggleUIStroke.Color = nexlib.accentclr 
            cursorDot.BackgroundColor3 = nexlib.accentclr
            
            if uiVisible then
                local mouseLocation = game:GetService("UserInputService"):GetMouseLocation()
                cursorDot.Position = UDim2.new(0, mouseLocation.X, 0, mouseLocation.Y)
            end
        end 
    end)()

    local windowLib = {}
    
    function windowLib:Tab(tabName)
        local sectionZIndex = 50;
        
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabName .. "_TabBtn"
        tabButton.Parent = tabSelector
        tabButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        tabButton.BorderSizePixel = 0
        tabButton.Font = Enum.Font.Code
        tabButton.Text = tabName
        tabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
        tabButton.TextSize = 14
        tabButton.AutoButtonColor = false
        
        local _9275x415 = game:GetService("TextService")
        local tabTextSize = _9275x415:GetTextSize(tabName, 14, Enum.Font.Code, Vector2.new(500, 500))
        tabButton.Size = UDim2.new(0, tabTextSize.X + 28, 0, 26)
        
        local tabUnderline = Instance.new("Frame")
        tabUnderline.Name = "TopLine"
        tabUnderline.Parent = tabButton
        tabUnderline.BackgroundColor3 = nexlib.accentclr
        tabUnderline.BorderSizePixel = 0
        tabUnderline.Position = UDim2.new(0, 0, 0, 0)
        tabUnderline.Size = UDim2.new(1, 0, 0, 2)
        tabUnderline.Visible = false
        
        local tabShadow = Instance.new("ImageLabel")
        tabShadow.Name = "Outline"
        tabShadow.Parent = tabButton
        tabShadow.BackgroundTransparency = 1
        tabShadow.Size = UDim2.new(1, 0, 1, 0)
        tabShadow.Image = "rbxassetid://2592362371"
        tabShadow.ImageColor3 = Color3.fromRGB(45, 45, 45)
        tabShadow.ScaleType = Enum.ScaleType.Slice
        tabShadow.SliceCenter = Rect.new(2, 2, 62, 62)
        local sectionHolder1 = Instance.new("ScrollingFrame")
        local sectionHolder1Padding = Instance.new("UIPadding")
        local sectionHolder1Layout = Instance.new("UIListLayout")
        local sectionHolder2 = Instance.new("ScrollingFrame")
        local sectionHolder2Padding = Instance.new("UIPadding")
        local sectionHolder2Layout = Instance.new("UIListLayout")
        
        sectionHolder1.Name = tabName .. "_Holder1"
        sectionHolder1.Parent = tabContainer;
        sectionHolder1.Active = true; sectionHolder1.BackgroundTransparency = 1; sectionHolder1.BorderSizePixel = 0;
        sectionHolder1.Position = UDim2.new(0, 1, 0, 35) sectionHolder1.Size = UDim2.new(0, 245, 1, -40)
        sectionHolder1.Visible = false; sectionHolder1.CanvasSize = UDim2.new(0, 0, 0, 0) sectionHolder1.ScrollBarThickness = 4; sectionHolder1.ScrollingEnabled = true;
        
        sectionHolder1Padding.Parent = sectionHolder1; sectionHolder1Padding.PaddingTop = UDim.new(0, 5)
        sectionHolder1Layout.Parent = sectionHolder1; sectionHolder1Layout.SortOrder = Enum.SortOrder.LayoutOrder; sectionHolder1Layout.Padding = UDim.new(0, 10)
        
        sectionHolder2.Name = tabName .. "_Holder2"
        sectionHolder2.Parent = tabContainer;
        sectionHolder2.Active = true; sectionHolder2.BackgroundTransparency = 1; sectionHolder2.BorderSizePixel = 0;
        sectionHolder2.Position = UDim2.new(0, 255, 0, 35) sectionHolder2.Size = UDim2.new(0, 245, 1, -40)
        sectionHolder2.Visible = false; sectionHolder2.CanvasSize = UDim2.new(0, 0, 0, 0) sectionHolder2.ScrollBarThickness = 4; sectionHolder2.ScrollingEnabled = true;
        
        sectionHolder2Padding.Parent = sectionHolder2; sectionHolder2Padding.PaddingTop = UDim.new(0, 5)
        sectionHolder2Layout.Parent = sectionHolder2; sectionHolder2Layout.SortOrder = Enum.SortOrder.LayoutOrder; sectionHolder2Layout.Padding = UDim.new(0, 10)
        
        table.insert(tabList, {buttonFrame = tabButton, topLine = tabUnderline, outline = tabShadow, h1 = sectionHolder1, h2 = sectionHolder2})
        
        if firstTabCreated == false then 
            firstTabCreated = true;
            sectionHolder1.Visible = true;
            sectionHolder2.Visible = true;
            tabButton.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
            tabButton.TextColor3 = Color3.fromRGB(230, 230, 230)
            tabUnderline.Visible = true
            tabShadow.ImageColor3 = Color3.fromRGB(65, 65, 65)
        end;
        
        tabButton.MouseButton1Click:Connect(function()
            local TweenServiceTab = game:GetService("TweenService")
            for index, t in ipairs(tabList) do
                if t.btn == tabButton then
                    TweenServiceTab:Create(t.btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(33, 33, 33), TextColor3 = Color3.fromRGB(230, 230, 230)}):Play()
                    t.topLine.Visible = true
                    t.outline.ImageColor3 = Color3.fromRGB(65, 65, 65)
                    t.h1.Visible = true
                    t.h2.Visible = true
                else
                    TweenServiceTab:Create(t.btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(22, 22, 22), TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
                    t.topLine.Visible = false
                    t.outline.ImageColor3 = Color3.fromRGB(45, 45, 45)
                    t.h1.Visible = false
                    t.h2.Visible = false
                end
            end
        end)
        
        coroutine.wrap(function()
            while task.wait() do 
                if tabUnderline.Visible then
                    tabUnderline.BackgroundColor3 = nexlib.accentclr 
                end
            end 
        end)()
        
        local tabLib = {}
        
        function tabLib:Section(sectionName, forceSide)
            sectionZIndex = sectionZIndex - 1;
            local targetSectionHolder = nil;
            
            if forceSide == 1 then targetSectionHolder = sectionHolder1
            elseif forceSide == 2 then targetSectionHolder = sectionHolder2
            else
                local sectionCount1 = 0; local sectionCount2 = 0;
                for s, f in next, sectionHolder1:GetChildren() do if f.Name == "Section" or f.Name == "MultiSection" then sectionCount1 = sectionCount1 + 1 end end;
                for s, f in next, sectionHolder2:GetChildren() do if f.Name == "Section" or f.Name == "MultiSection" then sectionCount2 = sectionCount2 + 1 end end;
                if sectionCount1 == 0 and sectionCount2 == 0 then targetSectionHolder = sectionHolder1 
                elseif sectionCount1 == sectionCount2 then targetSectionHolder = sectionHolder1 
                else targetSectionHolder = sectionHolder2 end;
            end
            
            local sectionFrame = Instance.new("Frame")
            local sectionShadow1 = Instance.new("ImageLabel")
            local sectionShadow2 = Instance.new("ImageLabel")
            local sectionTitleBg = Instance.new("Frame")
            local sectionTitleLabel = Instance.new("TextLabel")
            local sectionContent = Instance.new("Frame")
            local sectionContentLayout = Instance.new("UIListLayout")
            
            sectionFrame.Name = "Section"
            sectionFrame.Parent = targetSectionHolder;
            sectionFrame.AnchorPoint = Vector2.new(0.5, 0)
            sectionFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            sectionFrame.BorderSizePixel = 0;
            sectionFrame.Size = UDim2.new(1, -2, 0, 24)
            sectionFrame.ZIndex = sectionZIndex;
            
            sectionShadow1.Name = "SectionOutline2"
            sectionShadow1.Parent = sectionFrame; sectionShadow1.BackgroundTransparency = 1; sectionShadow1.Size = UDim2.new(1, 0, 1, 0)
            sectionShadow1.Image = "rbxassetid://2592362371" sectionShadow1.ImageColor3 = Color3.fromRGB(0, 0, 0)
            sectionShadow1.ScaleType = Enum.ScaleType.Slice; sectionShadow1.SliceCenter = Rect.new(2, 2, 62, 62)
            
            sectionShadow2.Name = "SectionOutline1"
            sectionShadow2.Parent = sectionFrame; sectionShadow2.BackgroundTransparency = 1; sectionShadow2.Position = UDim2.new(0, 1, 0, 1)
            sectionShadow2.Size = UDim2.new(1, -2, 1, -2) sectionShadow2.Image = "rbxassetid://2592362371"
            sectionShadow2.ImageColor3 = Color3.fromRGB(60, 60, 60) sectionShadow2.ScaleType = Enum.ScaleType.Slice; sectionShadow2.SliceCenter = Rect.new(2, 2, 62, 62)
            
            sectionTitleBg.Name = "SectionTitleFrame"
            sectionTitleBg.Parent = sectionFrame; sectionTitleBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            sectionTitleBg.BorderSizePixel = 0; sectionTitleBg.Position = UDim2.new(0, 10, 0, 0)
            
            sectionTitleLabel.Name = "SectionTitle"
            sectionTitleLabel.Parent = sectionTitleBg; sectionTitleLabel.BackgroundTransparency = 1; sectionTitleLabel.Position = UDim2.new(0, 0, 0, -3)
            sectionTitleLabel.Size = UDim2.new(1, 0, 0, 7) sectionTitleLabel.Font = Enum.Font.Code; sectionTitleLabel.Text = sectionName;
            sectionTitleLabel.TextColor3 = Color3.fromRGB(230, 230, 230) sectionTitleLabel.TextSize = 14;
            
            sectionContent.Name = "SectionItemHolderFrame"
            sectionContent.Parent = sectionFrame; sectionContent.AnchorPoint = Vector2.new(0.5, 0)
            sectionContent.BackgroundTransparency = 1; sectionContent.Position = UDim2.new(0.5, 0, 0, 15)
            sectionContent.Size = UDim2.new(1, -16, 0, 0)
            
            sectionContentLayout.Parent = sectionContent; sectionContentLayout.SortOrder = Enum.SortOrder.LayoutOrder; sectionContentLayout.Padding = UDim.new(0, 5)
            sectionTitleBg.Size = UDim2.new(0, sectionTitleLabel.TextBounds.X + 6, 0, 7)
            
            local function refreshSectionLayout()
                sectionFrame.Size = UDim2.new(1, -2, 0, sectionContentLayout.AbsoluteContentSize.Y + 24)
                sectionHolder1.CanvasSize = UDim2.new(0, 0, 0, sectionHolder1Layout.AbsoluteContentSize.Y + 20)
                sectionHolder2.CanvasSize = UDim2.new(0, 0, 0, sectionHolder2Layout.AbsoluteContentSize.Y + 20)
            end

            local sectionLib = {}
            
            function sectionLib:Toggle(text, default, callback)
                local toggleButton = Instance.new("TextButton")
                local toggleShadow1 = Instance.new("ImageLabel")
                local toggleShadow2 = Instance.new("ImageLabel")
                local toggleBoxBg = Instance.new("Frame")
                local toggleBoxFill = Instance.new("Frame")
                local toggleLabel = Instance.new("TextLabel")
                
                toggleButton.Name = "Toggle"
                toggleButton.Parent = sectionContent
                toggleButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
                toggleButton.BorderSizePixel = 0
                toggleButton.Size = UDim2.new(1, 0, 0, 22)
                toggleButton.AutoButtonColor = false
                toggleButton.Text = ''
                
                toggleShadow1.Parent = toggleButton; toggleShadow1.BackgroundTransparency = 1; toggleShadow1.Size = UDim2.new(1, 0, 1, 0)
                toggleShadow1.Image = "rbxassetid://2592362371" toggleShadow1.ImageColor3 = Color3.fromRGB(60, 60, 60)
                toggleShadow1.ScaleType = Enum.ScaleType.Slice; toggleShadow1.SliceCenter = Rect.new(2, 2, 62, 62)
                
                toggleShadow2.Parent = toggleButton; toggleShadow2.BackgroundTransparency = 1; toggleShadow2.Position = UDim2.new(0, 1, 0, 1)
                toggleShadow2.Size = UDim2.new(1, -2, 1, -2) toggleShadow2.Image = "rbxassetid://2592362371"
                toggleShadow2.ImageColor3 = Color3.fromRGB(0, 0, 0) toggleShadow2.ScaleType = Enum.ScaleType.Slice; toggleShadow2.SliceCenter = Rect.new(2, 2, 62, 62)
                
                toggleBoxBg.Name = "Box"
                toggleBoxBg.Parent = toggleButton
                toggleBoxBg.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
                toggleBoxBg.BorderSizePixel = 0
                toggleBoxBg.Position = UDim2.new(0, 6, 0.5, -6)
                toggleBoxBg.Size = UDim2.new(0, 12, 0, 12)
                
                toggleBoxFill.Name = "Check"
                toggleBoxFill.Parent = toggleBoxBg
                toggleBoxFill.BackgroundColor3 = nexlib.accentclr
                toggleBoxFill.BorderSizePixel = 0
                toggleBoxFill.Position = UDim2.new(0, 2, 0, 2)
                toggleBoxFill.Size = UDim2.new(0, 8, 0, 8)
                toggleBoxFill.Visible = default or false
                
                toggleLabel.Parent = toggleButton
                toggleLabel.BackgroundTransparency = 1
                toggleLabel.Position = UDim2.new(0, 25, 0, 0)
                toggleLabel.Size = UDim2.new(1, -25, 1, 0)
                toggleLabel.Font = Enum.Font.Code
                toggleLabel.Text = text
                toggleLabel.TextColor3 = Color3.fromRGB(190, 190, 190)
                toggleLabel.TextSize = 14
                toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                
                local toggleState = default or false
                toggleButton.MouseButton1Click:Connect(function()
                    toggleState = not toggleState
                    toggleBoxFill.Visible = toggleState
                    pcall(callback, toggleState)
                end)
                
                refreshSectionLayout()
                coroutine.wrap(function()
                    while task.wait() do toggleBoxFill.BackgroundColor3 = nexlib.accentclr end
                end)()
                local toggleLib = {}
                function toggleLib:Set(sliderValue)
                    toggleState = sliderValue
                    toggleBoxFill.Visible = toggleState
                    pcall(callback, toggleState)
                end
                return toggleLib
            end

            function sectionLib:Button(text, callback)
                local buttonFrame = Instance.new("TextButton")
                local buttonShadow1 = Instance.new("ImageLabel")
                local buttonShadow2 = Instance.new("ImageLabel")
                
                buttonFrame.Name = "Button"
                buttonFrame.Parent = sectionContent;
                buttonFrame.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
                buttonFrame.BorderColor3 = nexlib.accentclr;
                buttonFrame.BorderSizePixel = 0;
                buttonFrame.Size = UDim2.new(1, 0, 0, 20)
                buttonFrame.AutoButtonColor = false; buttonFrame.Font = Enum.Font.Code;
                buttonFrame.TextColor3 = Color3.fromRGB(230, 230, 230)
                buttonFrame.TextSize = 14; buttonFrame.Text = text;
                
                buttonShadow1.Name = "ButtonOutline1"
                buttonShadow1.Parent = buttonFrame; buttonShadow1.BackgroundTransparency = 1; buttonShadow1.Size = UDim2.new(1, 0, 1, 0)
                buttonShadow1.Image = "rbxassetid://2592362371" buttonShadow1.ImageColor3 = Color3.fromRGB(60, 60, 60)
                buttonShadow1.ScaleType = Enum.ScaleType.Slice; buttonShadow1.SliceCenter = Rect.new(2, 2, 62, 62)
                
                buttonShadow2.Name = "ButtonOutline2"
                buttonShadow2.Parent = buttonFrame; buttonShadow2.BackgroundTransparency = 1; buttonShadow2.Position = UDim2.new(0, 1, 0, 1)
                buttonShadow2.Size = UDim2.new(1, -2, 1, -2) buttonShadow2.Image = "rbxassetid://2592362371"
                buttonShadow2.ImageColor3 = Color3.fromRGB(0, 0, 0) buttonShadow2.ScaleType = Enum.ScaleType.Slice; buttonShadow2.SliceCenter = Rect.new(2, 2, 62, 62)
                
                buttonFrame.MouseButton1Click:Connect(function() pcall(callback) end)
                buttonFrame.MouseEnter:Connect(function() buttonFrame.BorderSizePixel = 1 end)
                buttonFrame.MouseLeave:Connect(function() buttonFrame.BorderSizePixel = 0 end)
                
                refreshSectionLayout()
                coroutine.wrap(function()
                    while task.wait() do buttonFrame.BorderColor3 = nexlib.accentclr end 
                end)()
            end;
            
            function sectionLib:Slider(text, min, max, default, rounding, callback)
                local sliderFrame = Instance.new("TextButton")
                local sliderFill = Instance.new("Frame")
                local sliderLabel = Instance.new("TextLabel")
                local sliderValueLabel = Instance.new("TextLabel")
                
                sliderFrame.Name = "SliderBar"
                sliderFrame.Parent = sectionContent; sliderFrame.BackgroundColor3 = Color3.fromRGB(38, 38, 38); sliderFrame.BorderSizePixel = 0;
                sliderFrame.Size = UDim2.new(1, 0, 0, 16); sliderFrame.Text = ''; sliderFrame.AutoButtonColor = false;
                
                local sliderShadow1 = Instance.new("ImageLabel")
                sliderShadow1.Parent = sliderFrame; sliderShadow1.BackgroundTransparency = 1; sliderShadow1.Size = UDim2.new(1, 0, 1, 0)
                sliderShadow1.Image = "rbxassetid://2592362371" sliderShadow1.ImageColor3 = Color3.fromRGB(60, 60, 60)
                sliderShadow1.ScaleType = Enum.ScaleType.Slice; sliderShadow1.SliceCenter = Rect.new(2, 2, 62, 62)
                
                local sliderShadow2 = Instance.new("ImageLabel")
                sliderShadow2.Parent = sliderFrame; sliderShadow2.BackgroundTransparency = 1; sliderShadow2.Position = UDim2.new(0, 1, 0, 1)
                sliderShadow2.Size = UDim2.new(1, -2, 1, -2) sliderShadow2.Image = "rbxassetid://2592362371"
                sliderShadow2.ImageColor3 = Color3.fromRGB(0, 0, 0) sliderShadow2.ScaleType = Enum.ScaleType.Slice; sliderShadow2.SliceCenter = Rect.new(2, 2, 62, 62)

                sliderFill.Name = "SliderFill"
                sliderFill.Parent = sliderFrame; sliderFill.BackgroundColor3 = nexlib.accentclr; sliderFill.BorderSizePixel = 0;
                sliderFill.BackgroundTransparency = 0.55;
                sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
                
                sliderLabel.Name = "SliderTitle"
                sliderLabel.Parent = sliderFrame; sliderLabel.BackgroundTransparency = 1; sliderLabel.Position = UDim2.new(0, 6, 0, 0)
                sliderLabel.Size = UDim2.new(0.7, 0, 1, 0)
                sliderLabel.Font = Enum.Font.Code; sliderLabel.Text = text; sliderLabel.TextColor3 = Color3.fromRGB(190, 190, 190); sliderLabel.TextSize = 13;
                sliderLabel.TextXAlignment = Enum.TextXAlignment.Left; sliderLabel.ZIndex = 2;
                
                sliderValueLabel.Name = "SliderValue"
                sliderValueLabel.Parent = sliderFrame; sliderValueLabel.BackgroundTransparency = 1; sliderValueLabel.Position = UDim2.new(1, -75, 0, 0)
                sliderValueLabel.Size = UDim2.new(0, 70, 1, 0) sliderValueLabel.Font = Enum.Font.Code; sliderValueLabel.Text = tostring(default) .. "s";
                sliderValueLabel.TextColor3 = Color3.fromRGB(240, 240, 240); sliderValueLabel.TextSize = 13; sliderValueLabel.TextXAlignment = Enum.TextXAlignment.Right; sliderValueLabel.ZIndex = 5;
                
                local isDragging = false
                local function updateSliderFromInput(input)
                    local sliderPercent = math.clamp((input.Position.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
                    local sliderValue = min + (max - min) * sliderPercent
                    if rounding == 0 then
                        sliderValue = math.floor(sliderValue + 0.5)
                    else
                        sliderValue = tonumber(string.format("%." .. rounding .. "f", sliderValue))
                    end
                    sliderFill.Size = UDim2.new(sliderPercent, 0, 1, 0)
                    sliderValueLabel.Text = tostring(sliderValue) .. "s"
                    pcall(callback, sliderValue)
                end
                
                sliderFrame.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDragging = true
                        updateSliderFromInput(input)
                    end
                end)
                game:GetService("UserInputService").InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDragging = false end
                end)
                game:GetService("UserInputService").InputChanged:Connect(function(input)
                    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        updateSliderFromInput(input)
                    end
                end)
                
                refreshSectionLayout()
                coroutine.wrap(function()
                    while task.wait() do sliderFill.BackgroundColor3 = nexlib.accentclr end
                end)()
            end

            function sectionLib:Input(text, default, placeholder, callback)
                local inputFrame = Instance.new("Frame")
                local inputLabel = Instance.new("TextLabel")
                local inputTextBox = Instance.new("TextBox")
                
                inputFrame.Name = "Input"
                inputFrame.Parent = sectionContent; inputFrame.BackgroundTransparency = 1; inputFrame.Size = UDim2.new(1, 0, 0, 38)
                
                inputLabel.Name = "InputTitle"
                inputLabel.Parent = inputFrame; inputLabel.BackgroundTransparency = 1; inputLabel.Size = UDim2.new(1, 0, 0, 15)
                inputLabel.Font = Enum.Font.Code; inputLabel.Text = text; inputLabel.TextColor3 = Color3.fromRGB(190, 190, 190); inputLabel.TextSize = 14;
                inputLabel.TextXAlignment = Enum.TextXAlignment.Left;
                
                inputTextBox.Name = "InputBox"
                inputTextBox.Parent = inputFrame; inputTextBox.BackgroundColor3 = Color3.fromRGB(38, 38, 38); inputTextBox.BorderSizePixel = 0;
                inputTextBox.Position = UDim2.new(0, 0, 0, 18); inputTextBox.Size = UDim2.new(1, 0, 0, 20);
                inputTextBox.Font = Enum.Font.Code; inputTextBox.PlaceholderText = placeholder or ""; inputTextBox.Text = default or "";
                inputTextBox.TextColor3 = Color3.fromRGB(230, 230, 230); inputTextBox.TextSize = 14; inputTextBox.TextXAlignment = Enum.TextXAlignment.Left;
                
                inputTextBox.FocusLost:Connect(function(enterPressed)
                    pcall(callback, inputTextBox.Text)
                end)
                
                refreshSectionLayout()
            end

            function sectionLib:Dropdown(text, list, default, callback)
                default = typeof(default) == "string" and default;
                if default == '' then default = nil end;
                
                local dropdownFrame = Instance.new("Frame")
                local dropdownLabel = Instance.new("TextLabel")
                local dropdownButton = Instance.new("TextButton")
                local dropdownShadow1 = Instance.new("ImageLabel")
                local dropdownShadow2 = Instance.new("ImageLabel")
                local dropdownValueLabel = Instance.new("TextLabel")
                local dropdownArrow = Instance.new("ImageLabel")
                
                dropdownFrame.Name = "Dropdown"
                dropdownFrame.Parent = sectionContent; dropdownFrame.BackgroundTransparency = 1; dropdownFrame.Size = UDim2.new(1, 0, 0, 37)
                
                dropdownLabel.Name = "DropdownTitle"
                dropdownLabel.Parent = dropdownFrame; dropdownLabel.BackgroundTransparency = 1; dropdownLabel.Size = UDim2.new(0, 0, 0, 13)
                dropdownLabel.Font = Enum.Font.Code; dropdownLabel.Text = text; dropdownLabel.TextColor3 = Color3.fromRGB(230, 230, 230) dropdownLabel.TextSize = 14;
                dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left;
                
                dropdownButton.Name = "DropdownFrame"
                dropdownButton.Parent = dropdownFrame; dropdownButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38) dropdownButton.BorderSizePixel = 0;
                dropdownButton.Position = UDim2.new(0, 0, 1, -20) dropdownButton.Size = UDim2.new(1, 0, 0, 20) dropdownButton.Text = ''; dropdownButton.AutoButtonColor = false;
                
                dropdownShadow1.Parent = dropdownButton; dropdownShadow1.BackgroundTransparency = 1; dropdownShadow1.Size = UDim2.new(1, 0, 1, 0)
                dropdownShadow1.Image = "rbxassetid://2592362371" dropdownShadow1.ImageColor3 = Color3.fromRGB(60, 60, 60)
                dropdownShadow1.ScaleType = Enum.ScaleType.Slice; dropdownShadow1.SliceCenter = Rect.new(2, 2, 62, 62)
                
                dropdownShadow2.Parent = dropdownButton; dropdownShadow2.BackgroundTransparency = 1; dropdownShadow2.Position = UDim2.new(0, 1, 0, 1)
                dropdownShadow2.Size = UDim2.new(1, -2, 1, -2) dropdownShadow2.Image = "rbxassetid://2592362371" dropdownShadow2.ImageColor3 = Color3.fromRGB(0, 0, 0)
                dropdownShadow2.ScaleType = Enum.ScaleType.Slice; dropdownShadow2.SliceCenter = Rect.new(2, 2, 62, 62)
                
                dropdownValueLabel.Name = "DropdownText"
                dropdownValueLabel.Parent = dropdownButton; dropdownValueLabel.BackgroundTransparency = 1; dropdownValueLabel.Position = UDim2.new(0, 5, 0, 0)
                dropdownValueLabel.Size = UDim2.new(1, -5, 1, 0) dropdownValueLabel.Font = Enum.Font.Code; dropdownValueLabel.Text = typeof(default) == "string" and default or "...";
                dropdownValueLabel.TextColor3 = Color3.fromRGB(180, 180, 180) dropdownValueLabel.TextSize = 14; dropdownValueLabel.TextXAlignment = Enum.TextXAlignment.Left;
                
                dropdownArrow.Name = "DropdownArrow"
                dropdownArrow.Parent = dropdownButton; dropdownArrow.AnchorPoint = Vector2.new(0, 0.5) dropdownArrow.BackgroundTransparency = 1;
                dropdownArrow.Position = UDim2.new(1, -22, 0.5, 0) dropdownArrow.Size = UDim2.new(0, 20, 0, 20)
                dropdownArrow.Image = "http://www.roblox.com/asset/?id=6031091004" dropdownArrow.ImageColor3 = Color3.fromRGB(180, 180, 180)
                
                refreshSectionLayout()
                
                local dropdownListFrame = Instance.new("Frame")
                local dropdownListShadow1 = Instance.new("ImageLabel")
                local dropdownListShadow2 = Instance.new("ImageLabel")
                local dropdownListScrolling = Instance.new("ScrollingFrame")
                local dropdownListLayout = Instance.new("UIListLayout")
                local dropdownListPadding = Instance.new("UIPadding")
                
                dropdownListFrame.Name = "DropdownHolderFrame"
                dropdownListFrame.Parent = sectionFrame; dropdownListFrame.AnchorPoint = Vector2.new(0.5, 0)
                dropdownListFrame.BackgroundColor3 = Color3.fromRGB(38, 38, 38) dropdownListFrame.BorderSizePixel = 0;
                dropdownListFrame.Position = UDim2.new(0.5, 0, 0, sectionContentLayout.AbsoluteContentSize.Y + 19)
                dropdownListFrame.Size = UDim2.new(1, -16, 0, 0) dropdownListFrame.Visible = false; dropdownListFrame.ZIndex = 10;
                
                dropdownListShadow1.Parent = dropdownListFrame; dropdownListShadow1.BackgroundTransparency = 1; dropdownListShadow1.Size = UDim2.new(1, 0, 1, 0)
                dropdownListShadow1.Image = "rbxassetid://2592362371" dropdownListShadow1.ImageColor3 = Color3.fromRGB(60, 60, 60)
                dropdownListShadow1.ScaleType = Enum.ScaleType.Slice; dropdownListShadow1.SliceCenter = Rect.new(2, 2, 62, 62)
                
                dropdownListShadow2.Parent = dropdownListFrame; dropdownListShadow2.BackgroundTransparency = 1; dropdownListShadow2.Position = UDim2.new(0, 1, 0, 1)
                dropdownListShadow2.Size = UDim2.new(1, -2, 1, -2) dropdownListShadow2.Image = "rbxassetid://2592362371" dropdownListShadow2.ImageColor3 = Color3.fromRGB(0, 0, 0)
                dropdownListShadow2.ScaleType = Enum.ScaleType.Slice; dropdownListShadow2.SliceCenter = Rect.new(2, 2, 62, 62)
                
                dropdownListScrolling.Name = "DropdownHolder"
                dropdownListScrolling.Parent = dropdownListFrame; dropdownListScrolling.Active = true; dropdownListScrolling.BackgroundTransparency = 1; dropdownListScrolling.BorderSizePixel = 0;
                dropdownListScrolling.Size = UDim2.new(1, -4, 1, 0) dropdownListScrolling.ScrollBarThickness = 2; dropdownListScrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
                
                dropdownListLayout.Parent = dropdownListScrolling; dropdownListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; dropdownListLayout.Padding = UDim.new(0, 2)
                dropdownListPadding.Parent = dropdownListScrolling; dropdownListPadding.PaddingTop = UDim.new(0, 6)
                
                table.insert(nexlib.dropdownframes, dropdownListFrame)
                table.insert(nexlib.dropdownframes, dropdownFrame)
                
                local dropdownLib = {}
                
                dropdownButton.MouseButton1Click:Connect(function()
                    if dropdownListFrame.Visible == false then 
                        for s, f in next, nexlib.dropdownframes do if f.Name == "DropdownHolderFrame" then f.Visible = false end end;
                        for s, f in next, nexlib.dropdownframes do if f.Name == "Dropdown" then f.DropdownFrame.DropdownArrow.Rotation = 0 end end;
                        dropdownArrow.Rotation = 180; dropdownListFrame.Visible = true 
                    else 
                        dropdownArrow.Rotation = 0; dropdownListFrame.Visible = false 
                    end 
                end)
                
                for s, f in next, list do 
                    local dropdownItemBtn = Instance.new("TextButton")
                    local dropdownItemText = Instance.new("TextLabel")
                    
                    dropdownItemBtn.Name = "Item"
                    dropdownItemBtn.Parent = dropdownListScrolling; dropdownItemBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    dropdownItemBtn.Size = UDim2.new(1, -12, 0, 20) dropdownItemBtn.AutoButtonColor = false; dropdownItemBtn.Font = Enum.Font.Code;
                    dropdownItemBtn.Text = " " .. f; dropdownItemBtn.TextColor3 = Color3.fromRGB(230, 230, 230) dropdownItemBtn.TextSize = 14;
                    dropdownItemBtn.TextXAlignment = Enum.TextXAlignment.Left;
                    
                    dropdownItemText.Name = "ItemText"
                    dropdownItemText.Parent = dropdownItemBtn; dropdownItemText.BackgroundTransparency = 1; dropdownItemText.Position = UDim2.new(0, 7, 0, 0)
                    dropdownItemText.Size = UDim2.new(1, -7, 1, 0) dropdownItemText.Font = Enum.Font.Code; dropdownItemText.Text = f;
                    dropdownItemText.TextColor3 = nexlib.accentclr; dropdownItemText.TextSize = 14; dropdownItemText.TextXAlignment = Enum.TextXAlignment.Left;
                    
                    dropdownItemBtn.MouseButton1Click:Connect(function()
                        dropdownListFrame.Visible = false; dropdownValueLabel.Text = f; default = f; pcall(callback, f)
                    end)
                    
                    coroutine.wrap(function()
                        while task.wait() do 
                            local isSelected = (typeof(default) == "string" and default == f)
                            dropdownItemText.BackgroundTransparency = 1;
                            dropdownItemText.TextTransparency = isSelected and 0 or 1;
                            dropdownItemBtn.TextTransparency = isSelected and 1 or 0;
                            dropdownItemBtn.BackgroundTransparency = isSelected and 0 or 1;
                            dropdownItemBtn.BorderColor3 = nexlib.accentclr;
                        end 
                    end)()
                    dropdownListFrame.Size = UDim2.new(1, -16, 0, math.clamp(dropdownListLayout.AbsoluteContentSize.Y + 12, 0, 150))
                    dropdownListScrolling.CanvasSize = UDim2.new(0, 0, 0, dropdownListLayout.AbsoluteContentSize.Y + 12)
                end;
                
                coroutine.wrap(function()
                    while task.wait() do dropdownButton.BorderColor3 = nexlib.accentclr end 
                end)()
                
                function dropdownLib:Set(value)
                    dropdownValueLabel.Text = tostring(value)
                    default = value
                    pcall(callback, value)
                end
                
                return dropdownLib
            end;
            
            function sectionLib:Label(text)
                local labelLib = {}
                local equippedItemName = Instance.new("TextLabel")
                
                equippedItemName.Name = "Label"
                equippedItemName.Parent = sectionContent; equippedItemName.BackgroundTransparency = 1; equippedItemName.Size = UDim2.new(1, 0, 0, 18)
                equippedItemName.Font = Enum.Font.Code; equippedItemName.Text = text; equippedItemName.TextColor3 = Color3.fromRGB(230, 230, 230)
                equippedItemName.TextSize = 14; equippedItemName.TextXAlignment = Enum.TextXAlignment.Left;
                
                refreshSectionLayout()
                
                function labelLib:Change(newText) equippedItemName.Text = newText end;
                return labelLib;
            end;
            
            return sectionLib;
        end;

        function tabLib:MultiSection(tabNames, forceSide)
            sectionZIndex = sectionZIndex - 1
            local targetSectionHolder = nil
            if forceSide == 1 then
                targetSectionHolder = sectionHolder1
            elseif forceSide == 2 then
                targetSectionHolder = sectionHolder2
            else
                local sectionCount1, sectionCount2 = 0, 0
                for index, f in next, sectionHolder1:GetChildren() do
                    if f.Name == "Section" or f.Name == "MultiSection" then sectionCount1 = sectionCount1 + 1 end
                end
                for index, f in next, sectionHolder2:GetChildren() do
                    if f.Name == "Section" or f.Name == "MultiSection" then sectionCount2 = sectionCount2 + 1 end
                end
                if sectionCount1 <= sectionCount2 then targetSectionHolder = sectionHolder1 else targetSectionHolder = sectionHolder2 end
            end

            local multiSectionFrame = Instance.new("Frame")
            multiSectionFrame.Name = "MultiSection"
            multiSectionFrame.Parent = targetSectionHolder
            multiSectionFrame.AnchorPoint = Vector2.new(0.5, 0)
            multiSectionFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            multiSectionFrame.BorderSizePixel = 0
            multiSectionFrame.Size = UDim2.new(1, -2, 0, 50)
            multiSectionFrame.ZIndex = sectionZIndex

            local multiSectionShadow1 = Instance.new("ImageLabel")
            multiSectionShadow1.Parent = multiSectionFrame
            multiSectionShadow1.BackgroundTransparency = 1
            multiSectionShadow1.Size = UDim2.new(1, 0, 1, 0)
            multiSectionShadow1.Image = "rbxassetid://2592362371"
            multiSectionShadow1.ImageColor3 = Color3.fromRGB(0, 0, 0)
            multiSectionShadow1.ScaleType = Enum.ScaleType.Slice
            multiSectionShadow1.SliceCenter = Rect.new(2, 2, 62, 62)

            local multiSectionShadow2 = Instance.new("ImageLabel")
            multiSectionShadow2.Parent = multiSectionFrame
            multiSectionShadow2.BackgroundTransparency = 1
            multiSectionShadow2.Position = UDim2.new(0, 1, 0, 1)
            multiSectionShadow2.Size = UDim2.new(1, -2, 1, -2)
            multiSectionShadow2.Image = "rbxassetid://2592362371"
            multiSectionShadow2.ImageColor3 = Color3.fromRGB(60, 60, 60)
            multiSectionShadow2.ScaleType = Enum.ScaleType.Slice
            multiSectionShadow2.SliceCenter = Rect.new(2, 2, 62, 62)

            local multiSectionTabHolder = Instance.new("Frame")
            multiSectionTabHolder.Parent = multiSectionFrame
            multiSectionTabHolder.BackgroundTransparency = 1
            multiSectionTabHolder.Position = UDim2.new(0, 6, 0, 4)
            multiSectionTabHolder.Size = UDim2.new(1, -12, 0, 22)
            local multiSectionTabLayout = Instance.new("UIListLayout")
            multiSectionTabLayout.Parent = multiSectionTabHolder
            multiSectionTabLayout.FillDirection = Enum.FillDirection.Horizontal
            multiSectionTabLayout.SortOrder = Enum.SortOrder.LayoutOrder
            multiSectionTabLayout.Padding = UDim.new(0, 2)

            local multiSectionContentHolder = Instance.new("Frame")
            multiSectionContentHolder.Parent = multiSectionFrame
            multiSectionContentHolder.BackgroundTransparency = 1
            multiSectionContentHolder.Position = UDim2.new(0.5, 0, 0, 28)
            multiSectionContentHolder.AnchorPoint = Vector2.new(0.5, 0)
            multiSectionContentHolder.Size = UDim2.new(1, -16, 0, 0)

            local multiSectionPages, multiSectionTabsInfo = {}, {}
            local multiSectionTabLibs = {}

            local function refreshMultiSectionLayout()
                local maxPageHeight = 0
                for index, multiSectionPage in ipairs(multiSectionPages) do
                    local L252_55 = multiSectionPage:FindFirstChildOfClass("UIListLayout")
                    if L252_55 then
                        maxPageHeight = math.max(maxPageHeight, L252_55.AbsoluteContentSize.Y)
                    end
                end
                multiSectionContentHolder.Size = UDim2.new(1, -16, 0, maxPageHeight)
                multiSectionFrame.Size = UDim2.new(1, -2, 0, maxPageHeight + 36)
                sectionHolder1.CanvasSize = UDim2.new(0, 0, 0, sectionHolder1Layout.AbsoluteContentSize.Y + 20)
                sectionHolder2.CanvasSize = UDim2.new(0, 0, 0, sectionHolder2Layout.AbsoluteContentSize.Y + 20)
            end

            for i, tabName in ipairs(tabNames) do
                local multiSectionPage = Instance.new("Frame")
                multiSectionPage.Name = "Page_" .. tabName
                multiSectionPage.Parent = multiSectionContentHolder
                multiSectionPage.BackgroundTransparency = 1
                multiSectionPage.Size = UDim2.new(1, 0, 0, 0)
                multiSectionPage.Visible = (i == 1)

                local multiSectionPageLayout = Instance.new("UIListLayout")
                multiSectionPageLayout.Parent = multiSectionPage
                multiSectionPageLayout.SortOrder = Enum.SortOrder.LayoutOrder
                multiSectionPageLayout.Padding = UDim.new(0, 5)

                multiSectionPageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    multiSectionPage.Size = UDim2.new(1, 0, 0, multiSectionPageLayout.AbsoluteContentSize.Y)
                    refreshMultiSectionLayout()
                end)

                local buttonFrame = Instance.new("TextButton")
                buttonFrame.Parent = multiSectionTabHolder
                buttonFrame.BackgroundColor3 = (i == 1) and Color3.fromRGB(38, 38, 38) or Color3.fromRGB(28, 28, 28)
                buttonFrame.BorderSizePixel = 0
                buttonFrame.Size = UDim2.new(0, 0, 1, 0)
                buttonFrame.AutomaticSize = Enum.AutomaticSize.X
                buttonFrame.AutoButtonColor = false
                buttonFrame.Font = Enum.Font.Code
                buttonFrame.Text = "  " .. tabName .. "  "
                buttonFrame.TextColor3 = (i == 1) and Color3.fromRGB(230, 230, 230) or Color3.fromRGB(150, 150, 150)
                buttonFrame.TextSize = 13

                local multiSectionTabUnderline = Instance.new("Frame")
                multiSectionTabUnderline.Parent = buttonFrame
                multiSectionTabUnderline.BackgroundColor3 = nexlib.accentclr
                multiSectionTabUnderline.BorderSizePixel = 0
                multiSectionTabUnderline.Position = UDim2.new(0, 0, 1, -2)
                multiSectionTabUnderline.Size = UDim2.new(1, 0, 0, 2)
                multiSectionTabUnderline.Visible = (i == 1)

                table.insert(multiSectionPages, multiSectionPage)
                table.insert(multiSectionTabsInfo, {buttonFrame = buttonFrame, multiSectionTabUnderline = multiSectionTabUnderline, multiSectionPage = multiSectionPage})

                buttonFrame.MouseButton1Click:Connect(function()
                    for idx, notifData in ipairs(multiSectionTabsInfo) do
                        local isTabActive = (idx == i)
                        notifData.page.Visible = isTabActive
                        notifData.underline.Visible = isTabActive
                        notifData.btn.BackgroundColor3 = isTabActive and Color3.fromRGB(38, 38, 38) or Color3.fromRGB(28, 28, 28)
                        notifData.btn.TextColor3 = isTabActive and Color3.fromRGB(230, 230, 230) or Color3.fromRGB(150, 150, 150)
                    end
                    refreshMultiSectionLayout()
                end)
                coroutine.wrap(function()
                    while task.wait() do
                        if multiSectionTabUnderline.Visible then
                            multiSectionTabUnderline.BackgroundColor3 = nexlib.accentclr
                        end
                    end
                end)()

                local function refreshNestedSectionLayout()
                    multiSectionPage.Size = UDim2.new(1, 0, 0, multiSectionPageLayout.AbsoluteContentSize.Y)
                    refreshMultiSectionLayout()
                end

                local multiSectionTabLib = {}

                function multiSectionTabLib:Toggle(text, default, callback)
                    local toggleButton = Instance.new("TextButton")
                    toggleButton.Name = "Toggle"
                    toggleButton.Parent = multiSectionPage
                    toggleButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
                    toggleButton.BorderSizePixel = 0
                    toggleButton.Size = UDim2.new(1, 0, 0, 22)
                    toggleButton.AutoButtonColor = false
                    toggleButton.Text = ""

                    local toggleShadow1 = Instance.new("ImageLabel")
                    toggleShadow1.Parent = toggleButton
                    toggleShadow1.BackgroundTransparency = 1
                    toggleShadow1.Size = UDim2.new(1, 0, 1, 0)
                    toggleShadow1.Image = "rbxassetid://2592362371"
                    toggleShadow1.ImageColor3 = Color3.fromRGB(60, 60, 60)
                    toggleShadow1.ScaleType = Enum.ScaleType.Slice
                    toggleShadow1.SliceCenter = Rect.new(2, 2, 62, 62)

                    local toggleShadow2 = Instance.new("ImageLabel")
                    toggleShadow2.Parent = toggleButton
                    toggleShadow2.BackgroundTransparency = 1
                    toggleShadow2.Position = UDim2.new(0, 1, 0, 1)
                    toggleShadow2.Size = UDim2.new(1, -2, 1, -2)
                    toggleShadow2.Image = "rbxassetid://2592362371"
                    toggleShadow2.ImageColor3 = Color3.fromRGB(0, 0, 0)
                    toggleShadow2.ScaleType = Enum.ScaleType.Slice
                    toggleShadow2.SliceCenter = Rect.new(2, 2, 62, 62)

                    local toggleBoxBg = Instance.new("Frame")
                    toggleBoxBg.Parent = toggleButton
                    toggleBoxBg.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
                    toggleBoxBg.BorderSizePixel = 0
                    toggleBoxBg.Position = UDim2.new(0, 6, 0.5, -6)
                    toggleBoxBg.Size = UDim2.new(0, 12, 0, 12)

                    local toggleBoxFill = Instance.new("Frame")
                    toggleBoxFill.Parent = toggleBoxBg
                    toggleBoxFill.BackgroundColor3 = nexlib.accentclr
                    toggleBoxFill.BorderSizePixel = 0
                    toggleBoxFill.Position = UDim2.new(0, 2, 0, 2)
                    toggleBoxFill.Size = UDim2.new(0, 8, 0, 8)
                    toggleBoxFill.Visible = default or false

                    local toggleLabel = Instance.new("TextLabel")
                    toggleLabel.Parent = toggleButton
                    toggleLabel.BackgroundTransparency = 1
                    toggleLabel.Position = UDim2.new(0, 25, 0, 0)
                    toggleLabel.Size = UDim2.new(1, -25, 1, 0)
                    toggleLabel.Font = Enum.Font.Code
                    toggleLabel.Text = text
                    toggleLabel.TextColor3 = Color3.fromRGB(190, 190, 190)
                    toggleLabel.TextSize = 14
                    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left

                    local toggleState = default or false
                    toggleButton.MouseButton1Click:Connect(function()
                        toggleState = not toggleState
                        toggleBoxFill.Visible = toggleState
                        pcall(callback, toggleState)
                    end)

                    refreshNestedSectionLayout()
                    coroutine.wrap(function()
                        while task.wait() do toggleBoxFill.BackgroundColor3 = nexlib.accentclr end
                    end)()

                    local toggleLib = {}
                    function toggleLib:Set(sliderValue)
                        toggleState = sliderValue
                        toggleBoxFill.Visible = toggleState
                        pcall(callback, toggleState)
                    end
                    return toggleLib
                end

                function multiSectionTabLib:Slider(text, min, max, default, rounding, callback)
                    local sliderFrame = Instance.new("TextButton")
                    sliderFrame.Name = "SliderBar"
                    sliderFrame.Parent = multiSectionPage
                    sliderFrame.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
                    sliderFrame.BorderSizePixel = 0
                    sliderFrame.Size = UDim2.new(1, 0, 0, 16)
                    sliderFrame.Text = ""
                    sliderFrame.AutoButtonColor = false

                    local sliderShadow1 = Instance.new("ImageLabel")
                    sliderShadow1.Parent = sliderFrame
                    sliderShadow1.BackgroundTransparency = 1
                    sliderShadow1.Size = UDim2.new(1, 0, 1, 0)
                    sliderShadow1.Image = "rbxassetid://2592362371"
                    sliderShadow1.ImageColor3 = Color3.fromRGB(60, 60, 60)
                    sliderShadow1.ScaleType = Enum.ScaleType.Slice
                    sliderShadow1.SliceCenter = Rect.new(2, 2, 62, 62)

                    local sliderShadow2 = Instance.new("ImageLabel")
                    sliderShadow2.Parent = sliderFrame
                    sliderShadow2.BackgroundTransparency = 1
                    sliderShadow2.Position = UDim2.new(0, 1, 0, 1)
                    sliderShadow2.Size = UDim2.new(1, -2, 1, -2)
                    sliderShadow2.Image = "rbxassetid://2592362371"
                    sliderShadow2.ImageColor3 = Color3.fromRGB(0, 0, 0)
                    sliderShadow2.ScaleType = Enum.ScaleType.Slice
                    sliderShadow2.SliceCenter = Rect.new(2, 2, 62, 62)

                    local sliderFill = Instance.new("Frame")
                    sliderFill.Parent = sliderFrame
                    sliderFill.BackgroundColor3 = nexlib.accentclr
                    sliderFill.BorderSizePixel = 0
                    sliderFill.BackgroundTransparency = 0.55
                    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)

                    local sliderLabel = Instance.new("TextLabel")
                    sliderLabel.Parent = sliderFrame
                    sliderLabel.BackgroundTransparency = 1
                    sliderLabel.Position = UDim2.new(0, 6, 0, 0)
                    sliderLabel.Size = UDim2.new(0.7, 0, 1, 0)
                    sliderLabel.Font = Enum.Font.Code
                    sliderLabel.Text = text
                    sliderLabel.TextColor3 = Color3.fromRGB(190, 190, 190)
                    sliderLabel.TextSize = 13
                    sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                    sliderLabel.ZIndex = 2

                    local sliderValueLabel = Instance.new("TextLabel")
                    sliderValueLabel.Parent = sliderFrame
                    sliderValueLabel.BackgroundTransparency = 1
                    sliderValueLabel.Position = UDim2.new(1, -75, 0, 0)
                    sliderValueLabel.Size = UDim2.new(0, 70, 1, 0)
                    sliderValueLabel.Font = Enum.Font.Code
                    sliderValueLabel.Text = tostring(default) .. "s"
                    sliderValueLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
                    sliderValueLabel.TextSize = 13
                    sliderValueLabel.TextXAlignment = Enum.TextXAlignment.Right
                    sliderValueLabel.ZIndex = 5

                    local isDragging = false
                    local function updateSliderFromInput(input)
                        local sliderPercent = math.clamp((input.Position.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
                        local sliderValue = min + (max - min) * sliderPercent
                        if rounding == 0 then
                            sliderValue = math.floor(sliderValue + 0.5)
                        else
                            sliderValue = tonumber(string.format("%." .. rounding .. "f", sliderValue))
                        end
                        sliderFill.Size = UDim2.new(sliderPercent, 0, 1, 0)
                        sliderValueLabel.Text = tostring(sliderValue) .. "s"
                        pcall(callback, sliderValue)
                    end

                    sliderFrame.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            isDragging = true
                            updateSliderFromInput(input)
                        end
                    end)
                    game:GetService("UserInputService").InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            isDragging = false
                        end
                    end)
                    game:GetService("UserInputService").InputChanged:Connect(function(input)
                        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                            updateSliderFromInput(input)
                        end
                    end)

                    refreshNestedSectionLayout()
                    coroutine.wrap(function()
                        while task.wait() do sliderFill.BackgroundColor3 = nexlib.accentclr end
                    end)()
                end

                function multiSectionTabLib:Label(text)
                    local labelLib = {}
                    local equippedItemName = Instance.new("TextLabel")
                    equippedItemName.Parent = multiSectionPage
                    equippedItemName.BackgroundTransparency = 1
                    equippedItemName.Size = UDim2.new(1, 0, 0, 18)
                    equippedItemName.Font = Enum.Font.Code
                    equippedItemName.Text = text
                    equippedItemName.TextColor3 = Color3.fromRGB(230, 230, 230)
                    equippedItemName.TextSize = 14
                    equippedItemName.TextXAlignment = Enum.TextXAlignment.Left
                    refreshNestedSectionLayout()
                    function labelLib:Change(newText) equippedItemName.Text = newText end
                    return labelLib
                end

                multiSectionTabLibs[tabName] = multiSectionTabLib
            end

            task.defer(refreshMultiSectionLayout)
            return multiSectionTabLibs
        end

        return tabLib;
    end;
    
    function windowLib:Destroy()
        if Lighting:FindFirstChild("ValkUIBlur") then
            Lighting.ValkUIBlur:Destroy()
        end
        uiScreenGui:Destroy()
    end;

    local function playIntro()
        local TweenService = game:GetService("TweenService")
        local Lighting = game:GetService("Lighting")
        
        task.wait(0.7)
        local introStartTime = tick()
        while tick() - introStartTime < 3 do task.wait() end
        
        local introWaitTime = tick()
        while tick() - introWaitTime < 2 do
            local index = 0
            for i = 1, 500000 do index = index + i end
            task.wait()
        end
        
        local introBlur = Lighting:FindFirstChild("ValkUIBlur") or Instance.new("BlurEffect")
        introBlur.Name = "ValkUIBlur"
        introBlur.Size = 0
        introBlur.Parent = Lighting
        
        local introTextLabel = Instance.new("TextLabel")
        introTextLabel.Name = "IntroLEVK"
        introTextLabel.Parent = uiScreenGui
        introTextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        introTextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
        introTextLabel.Size = UDim2.new(0, 400, 0, 100)
        introTextLabel.BackgroundTransparency = 1
        introTextLabel.Font = Enum.Font.Code
        introTextLabel.Text = "LEVK"
        introTextLabel.TextColor3 = nexlib.accentclr
        introTextLabel.TextSize = 80
        introTextLabel.TextTransparency = 1
        
        local introTweenIn = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local introTweenOut = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        
        TweenService:Create(introBlur, introTweenIn, {Size = 24}):Play()
        TweenService:Create(introTextLabel, introTweenIn, {TextTransparency = 0}):Play()
        
        task.wait(2.2)
        
        local introTweenBlurOut = TweenService:Create(introBlur, introTweenOut, {Size = 18})
        local introTweenTextOut = TweenService:Create(introTextLabel, introTweenOut, {TextTransparency = 1})
        
        introTweenBlurOut:Play()
        introTweenTextOut:Play()
        
        introTweenBlurOut.Completed:Connect(function()
            introTextLabel:Destroy()
            uiVisible = true
            refreshWindowLayout()
        end)
    end;

    task.spawn(playIntro)
    
    return windowLib;
end;

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local teamCheckEnabled = true
local function isSameTeam(player)
    if not teamCheckEnabled then return false end
    local localTeamId = LocalPlayer:GetAttribute("TeamID")
    local targetTeamId = player:GetAttribute("TeamID")
    if localTeamId == nil or targetTeamId == nil then return false end
    return targetTeamId == localTeamId
end

local function isImmune(playerOrChar)
    local char = playerOrChar
    if typeof(playerOrChar) == "Instance" and playerOrChar:IsA("Player") then
        char = playerOrChar.Character
    end
    if not char then return true end
    if char:FindFirstChildOfClass("ForceField") then return true end
    local targetHead = char:FindFirstChild("HumanoidRootPart")
    if targetHead and targetHead:FindFirstChild("Attachment") then return true end
    local forceFieldAttr = char:GetAttribute("Immune") or char:GetAttribute("Invincible") or char:GetAttribute("IsImmune")
    if forceFieldAttr == true then return true end
    local targetHumanoid = char:FindFirstChildOfClass("Humanoid")
    if targetHumanoid then
        local humanoidForceFieldAttr = targetHumanoid:GetAttribute("Immune") or targetHumanoid:GetAttribute("Invincible")
        if humanoidForceFieldAttr == true then return true end
    end
    return false
end

local function isReflectingOrParrying(player)
    local char = player and player.Character
    if not char then return false end

    
    local immunityAttrs = {"Reflecting", "IsReflecting", "BulletReflect", "Reflect", "Deflecting", "Parrying"}
    for index, a in ipairs(immunityAttrs) do
        local val = char:GetAttribute(a)
        if val == true or val == 1 or val == "true" then return true end
        local targetHumanoid = char:FindFirstChildOfClass("Humanoid")
        if targetHumanoid then
            local humanoidImmunityAttr = targetHumanoid:GetAttribute(a)
            if humanoidImmunityAttr == true or humanoidImmunityAttr == 1 then return true end
        end
    end

    
    local hasKatana = false
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and string.find(string.lower(tool.Name), "katana", 1, true) then
        hasKatana = true
    end
    for index, ch in ipairs(char:GetChildren()) do
        local childNameLower = string.lower(ch.Name)
        if string.find(childNameLower, "katana", 1, true) then
            hasKatana = true
        end
        if string.find(childNameLower, "reflect", 1, true) or string.find(childNameLower, "deflect", 1, true) then
            return true
        end
    end

    
    local targetHumanoid = char:FindFirstChildOfClass("Humanoid")
    if targetHumanoid then
        local success, playingAnimTracks = pcall(function() return targetHumanoid:GetPlayingAnimationTracks() end)
        if success and playingAnimTracks then
            for index, loadedAnim in ipairs(playingAnimTracks) do
                local animNameLower = string.lower(tostring(loadedAnim.Name or ""))
                local animIdStr = ""
                pcall(function()
                    if loadedAnim.Animation then animIdStr = tostring(loadedAnim.Animation.AnimationId or "") end
                end)
                local animCombinedStr = animNameLower .. " " .. string.lower(animIdStr)
                if string.find(animCombinedStr, "reflect", 1, true) or string.find(animCombinedStr, "deflect", 1, true)
                    or string.find(animCombinedStr, "parry", 1, true) or string.find(animCombinedStr, "block", 1, true) then
                    if hasKatana or string.find(animCombinedStr, "katana", 1, true) then
                        return true
                    end
                    
                    if string.find(animCombinedStr, "reflect", 1, true) or string.find(animCombinedStr, "deflect", 1, true) then
                        return true
                    end
                end
            end
        end
    end

    return false
end

local canFireRagebot = true
local orbitEnabled = false
local voidSpamEnabled = false
local voidSpamHeight = 50000000
local flyEnabled = false
local flyHeight = 50
local multiTargetFireEnabled = false
local ragebotEnabled = false
local ragebotCooldown = 0.25
local ragebotDuration = 0.1

task.spawn(function()
    while true do
        if ragebotEnabled and L555_61 then
            canFireRagebot = true
            local _3661x412 = ragebotDuration
            if typeof(_3661x412) ~= "number" or _3661x412 < 0.01 then _3661x412 = 0.01 end
            task.wait(_3661x412)
            if ragebotEnabled and L555_61 then
                canFireRagebot = false
                local _0xdee6 = ragebotCooldown
                if typeof(_0xdee6) ~= "number" or _0xdee6 < 0.01 then _0xdee6 = 0.01 end
                task.wait(_0xdee6)
            else
                canFireRagebot = true
            end
        else
            canFireRagebot = true
            task.wait(0.05)
        end
    end
end)

local aimbotEnabled = false
local aimbotSmoothing = 5
local aimbotFovRadius = 100
local aimbotTargetPartType = "head"
local aimbotShowFov = false
local aimbotCheckVis = false
local aimbotAutoFire = false

local silentAimEnabled = false
local silentAimTargetPartType = "head"
local silentAimFovRadius = 300
local silentAimShowFov = false
local silentAimCheckVis = false
local silentAimTargetPart = nil

local triggerBotEnabled = false
local noSpreadEnabled = false
local noMuzzleFlashEnabled = false
local noCooldownEnabled = false
local wasNoCooldownEnabled = false
local fastReloadEnabled = false
local noRecoilEnabled = false
local wasNoRecoilEnabled = false

local fullbrightEnabled = false

local showTargetInfo = false
local showAmmoInfo = false

local espEnabled = false
local espShowBoxes = true
local espShowNames = true
local espShowHealth = true
local espShowWeapons = true

local autoPickupAmmoEnabled = true
local autoPickupHealthEnabled = true
local autoPickupEnabled = false

local noclipEnabled = false
local flyNoclipEnabled = false
local noclipSpeed = 50
local flyNoclipSpeed = 50
local collisionDisabled = false
local movementMethod = "all walls"

local thirdPersonEnabled = false
local loopEmoteEnabled = false
local loopEmoteSpeed = 40
local loopEmoteTrack = nil
local loopEmoteAnim = nil

local customSkyboxEnabled = false
local customSkyboxType = ""

local chatSpamEnabled = false
local chatSpamMessage = "vr"
local skyboxDataMap = {
    ["Dark Sky"] = {
        ["SkyboxUp"] = "rbxassetid://570555929",
        ["SkyboxRt"] = "rbxassetid://570555882",
        ["SkyboxDn"] = "rbxassetid://570555964",
        ["SkyboxFt"] = "rbxassetid://570555800",
        ["SkyboxLf"] = "rbxassetid://570555840",
        ["SkyboxBk"] = "rbxassetid://570555736"
    },
    ["Vaporwave"] = {
        ["SkyboxUp"] = "rbxassetid://1417494643",
        ["SkyboxRt"] = "rbxassetid://1417494499",
        ["SkyboxLf"] = "rbxassetid://1417494402",
        ["SkyboxFt"] = "rbxassetid://1417494253",
        ["SkyboxBk"] = "rbxassetid://1417494030",
        ["SkyboxDn"] = "rbxassetid://1417494146"
    },
    ["Lake Sky"] = {
        ["SkyboxRt"] = "rbxassetid://6823531746",
        ["SkyboxUp"] = "rbxassetid://6823528533",
        ["SunTextureId"] = "rbxassetid://5392574622",
        ["SkyboxDn"] = "rbxassetid://6823525702",
        ["SkyboxFt"] = "rbxassetid://6823482923",
        ["SkyboxLf"] = "rbxassetid://6823530023",
        ["SkyboxBk"] = "rbxassetid://6823523318"
    },
    ["Black Mesa"] = {
        ["SkyboxUp"] = "rbxassetid://9569598752",
        ["SkyboxRt"] = "rbxassetid://9569601267",
        ["SkyboxDn"] = "rbxassetid://9569613307",
        ["SkyboxFt"] = "rbxassetid://9569611418",
        ["SkyboxLf"] = "rbxassetid://9569608166",
        ["SkyboxBk"] = "rbxassetid://9569742122"
    }
}

local function applySkybox(cosmeticName)
    local Lighting = game:GetService("Lighting")
    local skyboxObj = Lighting:FindFirstChild("CustomSkybox")
    
    if not customSkyboxEnabled or not cosmeticName or cosmeticName == "" then
        if skyboxObj then skyboxObj:Destroy() end
        return
    end
    
    local notifData = skyboxDataMap[cosmeticName]
    if notifData then
        if not skyboxObj then
            skyboxObj = Instance.new("Sky")
            skyboxObj.Name = "CustomSkybox"
            skyboxObj.Parent = Lighting
        end
        
        skyboxObj.SkyboxUp = ""
        skyboxObj.SkyboxRt = ""
        skyboxObj.SkyboxDn = ""
        skyboxObj.SkyboxFt = ""
        skyboxObj.SkyboxLf = ""
        skyboxObj.SkyboxBk = ""
        skyboxObj.SunTextureId = ""
        
        for prop, itemVal in pairs(notifData) do
            skyboxObj[prop] = itemVal
        end
    end
end

local fullbrightActive = false
local placeholder1 = ""
local placeholder2 = ""
local placeholder3 = false 
local placeholder4 = Vector3.zero
local placeholder5 = Vector3.new(0, 2, 0)
local voidSpamAnchorPos = nil
local ragebotTargetPart = nil

local function findPreferredHeadPart(char)
    if not char then return nil end
    return char:FindFirstChild("HitboxHead")
        or char:FindFirstChild("HitboxHeadSmall")
        or char:FindFirstChild("Head")
end

local ragebotConn
local setTargetFireLoop = function(on) end
local L555_61 = false
local __lhiRNgvZ = 3 

task.spawn(function()
    local success, err1 = xpcall(function()
        local PlayerScripts = LocalPlayer.PlayerScripts
        local hasFighterController, FighterController = pcall(require, PlayerScripts.Controllers.FighterController)
        local hasEnumLibrary, EnumLibrary     = pcall(require, ReplicatedStorage.Modules.EnumLibrary)
        local UseItemRemote    = ReplicatedStorage.Remotes.Replication.Fighter.UseItem
        local enumShoot; pcall(function() enumShoot = EnumLibrary:ToEnum("StartShooting") end)

        local function getEquippedObjectId()
            if not (hasFighterController and FighterController) then return nil end
            local LocalFighter = FighterController.LocalFighter; if not LocalFighter then return nil end
            local EquippedItem = LocalFighter.EquippedItem; if not EquippedItem then return nil end
            local successItem, itemVal = pcall(function() return EquippedItem:Get("ObjectID") end)
            if successItem and itemVal then return itemVal end
            successItem, itemVal = pcall(function() return EquippedItem.Data and EquippedItem.Data.ObjectID end)
            return successItem and itemVal or nil
        end

        local function buildShotTransformPayload(originPos, iterTargetPart)
            local targetPos2 = iterTargetPart.Position
            local cfLookAt = CFrame.lookAt(originPos, targetPos2)
            local rotX1, rotY1, rotZ1 = cfLookAt:ToOrientation()
            local posRotDict1 = {
                [utf8.char(0)] = originPos.X, [utf8.char(1)] = originPos.Y, [utf8.char(2)] = originPos.Z,
                [utf8.char(3)] = rotX1, [utf8.char(4)] = rotY1, [utf8.char(5)] = rotZ1,
            }
            local cfObjSpace = iterTargetPart.CFrame:ToObjectSpace(CFrame.new(targetPos2))
            local rotX2, rotY2, rotZ2 = cfObjSpace:ToOrientation()
            return {
                [utf8.char(1)] = {
                    [utf8.char(0)] = posRotDict1,
                    [utf8.char(1)] = posRotDict1,
                    [utf8.char(2)] = iterTargetPart,
                    [utf8.char(3)] = {
                        [utf8.char(0)] = cfObjSpace.X, [utf8.char(1)] = cfObjSpace.Y, [utf8.char(2)] = cfObjSpace.Z,
                        [utf8.char(3)] = rotX2, [utf8.char(4)] = rotY2, [utf8.char(5)] = rotZ2,
                    },
                },
            }
        end

        
        setTargetFireLoop = function(on)
            if ragebotConn then ragebotConn:Disconnect(); ragebotConn = nil end
            if not on then return end

            local lastEquippedId = nil
            ragebotConn = RunService.Heartbeat:Connect(function()
                if not L555_61 or not canFireRagebot then return end
                if not ragebotTargetPart or not ragebotTargetPart.Parent then return end

                local ragebotTargetChar = ragebotTargetPart:FindFirstAncestorOfClass("Model") or ragebotTargetPart.Parent
                local ragebotTargetPlayer = Players:GetPlayerFromCharacter(ragebotTargetChar)
                if not ragebotTargetPlayer or ragebotTargetPlayer == LocalPlayer then return end
                if isSameTeam(ragebotTargetPlayer) then return end
                
                if isImmune(ragebotTargetPlayer) then return end
                
                if isReflectingOrParrying(ragebotTargetPlayer) then return end

                local localTorso = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not localTorso then return end

                local equippedId = getEquippedObjectId()
                if equippedId then lastEquippedId = equippedId else equippedId = lastEquippedId end
                if not equippedId then return end

                local targetHeadPart = ragebotTargetPart
                local camPos = targetHeadPart.Position + Vector3.new(0, 0.1, 0)
                local shotPayload = buildShotTransformPayload(camPos, targetHeadPart)
                pcall(function()
                    UseItemRemote:FireServer(equippedId, enumShoot, shotPayload, nil)
                end)
            end)
        end
    end, function(err1) end)
end)

local savedTorsoCFrame = nil
local savedTorsoVelocity = nil

local function canCurrentWeaponFire()
    local canFire = true
    pcall(function()
        local PlayerScripts = LocalPlayer.PlayerScripts
        local success, FighterController2 = pcall(require, PlayerScripts.Controllers.FighterController)
        if not success or not FighterController2 or not FighterController2.LocalFighter then return end
        local EquippedItem = FighterController2.LocalFighter.EquippedItem
        if not EquippedItem then
            canFire = false
            return
        end
        local function readItemField(key)
            local successItem, sliderValue = pcall(function()
                if EquippedItem.Get then return EquippedItem:Get(key) end
                return EquippedItem[key] or (EquippedItem.Data and EquippedItem.Data[key]) or (EquippedItem.Info and EquippedItem.Info[key])
            end)
            if successItem then return sliderValue end
            return nil
        end
        local currentAmmo = readItemField("CurrentAmmo") or readItemField("Ammo") or readItemField("Bullets") or readItemField("MagazineAmmo")
        local isReloading = readItemField("Reloading") or readItemField("IsReloading")
        if EquippedItem.Info and type(EquippedItem.Info) == "table" then
            if currentAmmo == nil then currentAmmo = EquippedItem.Info.CurrentAmmo or EquippedItem.Info.Ammo end
            if EquippedItem.Info.Reloading == true or EquippedItem.Info.IsReloading == true then
                isReloading = true
            end
        end
        if isReloading == true then
            canFire = false
            return
        end
        if typeof(currentAmmo) == "number" and currentAmmo <= 0 then
            canFire = false
            return
        end
    end)
    return canFire
end

local function restoreSavedTransform()
    local targetHead = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetHead or not savedTorsoCFrame then return end
    targetHead.CFrame = savedTorsoCFrame
    if savedTorsoVelocity then
        targetHead.AssemblyLinearVelocity = savedTorsoVelocity
    end
    savedTorsoCFrame = nil
    savedTorsoVelocity = nil
end

pcall(function()
    RunService:UnbindFromRenderStep("RestoreDesyncPerfect")
end)
pcall(function()
    RunService:BindToRenderStep("RestoreDesyncPerfect", 0, restoreSavedTransform)
end)
RunService.RenderStepped:Connect(restoreSavedTransform)

RunService.Heartbeat:Connect(function()
    pcall(function()
        local targetHead = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not targetHead then return end

        if savedTorsoCFrame then
            restoreSavedTransform()
        end

        
        if L555_61 and canFireRagebot and ragebotTargetPart and canCurrentWeaponFire() then
            local _3921x508 = ragebotTargetPart:FindFirstAncestorOfClass("Model") or ragebotTargetPart.Parent
            local _456_638 = Players:GetPlayerFromCharacter(_3921x508)
            if _456_638 and isReflectingOrParrying(_456_638) then return end
            savedTorsoCFrame = targetHead.CFrame
            savedTorsoVelocity = targetHead.AssemblyLinearVelocity
            local targetPos2 = ragebotTargetPart.Position
            local ragebotShootPos = targetPos2 + Vector3.new(0, __lhiRNgvZ, 0)
            targetHead.CFrame = CFrame.new(ragebotShootPos, targetPos2)
            return
        end

        
        if voidSpamEnabled then
            if not voidSpamAnchorPos then
                voidSpamAnchorPos = targetHead.Position
            end
            savedTorsoCFrame = targetHead.CFrame
            savedTorsoVelocity = targetHead.AssemblyLinearVelocity
            local randomVector = Vector3.new(math.random(-100, 100), math.random(-100, 100), math.random(-100, 100)).Unit
            local ragebotShootPos = voidSpamAnchorPos + randomVector * voidSpamHeight
            local torsoOffset = savedTorsoCFrame - savedTorsoCFrame.Position
            targetHead.CFrame = CFrame.new(ragebotShootPos) * torsoOffset
        end
    end)
end)

task.spawn(function()
    while true do
        task.wait(0.01)
        if L555_61 and canFireRagebot then
            local localRootPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position or Vector3.zero
            local closestRagebotPlayer = nil
            local closestDist = math.huge

            for index, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and not isSameTeam(player) then
                    
                    if isImmune(player) then
                        continue
                    end
                    if isReflectingOrParrying(player) then
                        continue
                    end
                    local targetHead = player.Character:FindFirstChild("HumanoidRootPart")
                    local targetHumanoid = player.Character:FindFirstChild("Humanoid")
                    if targetHead and targetHumanoid and targetHumanoid.Health > 0 then
                        local distToPlayer = (Vector3.new(localRootPos.X, 0, localRootPos.Z) - Vector3.new(targetHead.Position.X, 0, targetHead.Position.Z)).Magnitude
                        if distToPlayer < closestDist then
                            closestDist = distToPlayer
                            closestRagebotPlayer = player
                        end
                    end
                end
            end

            if closestRagebotPlayer and closestRagebotPlayer.Character then
                ragebotTargetPart = findPreferredHeadPart(closestRagebotPlayer.Character)
            else
                ragebotTargetPart = nil
            end
        else
            ragebotTargetPart = nil
        end
    end
end)

local multiTargetConn = nil
local function setMultiTargetFireLoop(on)
    if multiTargetConn then multiTargetConn:Disconnect(); multiTargetConn = nil end
    if not on then return end

    task.spawn(function()
        local success, err1 = xpcall(function()
            local PlayerScripts = LocalPlayer.PlayerScripts
            local hasFighterController, FighterController = pcall(require, PlayerScripts.Controllers.FighterController)
            local hasEnumLibrary, EnumLibrary = pcall(require, ReplicatedStorage.Modules.EnumLibrary)
            local UseItemRemote = ReplicatedStorage.Remotes.Replication.Fighter.UseItem
            local enumShoot; pcall(function() enumShoot = EnumLibrary:ToEnum("StartShooting") end)

            local function getEquippedObjectId()
                if not (hasFighterController and FighterController) then return nil end
                local LocalFighter = FighterController.LocalFighter; if not LocalFighter then return nil end
                local EquippedItem = LocalFighter.EquippedItem; if not EquippedItem then return nil end
                local successItem, itemVal = pcall(function() return EquippedItem:Get("ObjectID") end)
                if successItem and itemVal then return itemVal end
                successItem, itemVal = pcall(function() return EquippedItem.Data and EquippedItem.Data.ObjectID end)
                return successItem and itemVal or nil
            end

            local function buildShotTransformPayload(originPos, iterTargetPart)
                local targetPos2 = iterTargetPart.Position
                local cfLookAt = CFrame.lookAt(originPos, targetPos2)
                local rotX1, rotY1, rotZ1 = cfLookAt:ToOrientation()
                local posRotDict1 = {
                    [utf8.char(0)] = originPos.X, [utf8.char(1)] = originPos.Y, [utf8.char(2)] = originPos.Z,
                    [utf8.char(3)] = rotX1, [utf8.char(4)] = rotY1, [utf8.char(5)] = rotZ1,
                }
                local cfObjSpace = iterTargetPart.CFrame:ToObjectSpace(CFrame.new(targetPos2))
                local rotX2, rotY2, rotZ2 = cfObjSpace:ToOrientation()
                return {
                    [utf8.char(1)] = {
                        [utf8.char(0)] = posRotDict1,
                        [utf8.char(1)] = posRotDict1,
                        [utf8.char(2)] = iterTargetPart,
                        [utf8.char(3)] = {
                            [utf8.char(0)] = cfObjSpace.X, [utf8.char(1)] = cfObjSpace.Y, [utf8.char(2)] = cfObjSpace.Z,
                            [utf8.char(3)] = rotX2, [utf8.char(4)] = rotY2, [utf8.char(5)] = rotZ2,
                        },
                    },
                }
            end

            local lastEquippedId = nil
            multiTargetConn = RunService.Heartbeat:Connect(function()
                if not multiTargetFireEnabled or not canFireRagebot then return end
                local localTorso = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not localTorso then return end
                local equippedId = getEquippedObjectId()
                if equippedId then lastEquippedId = equippedId else equippedId = lastEquippedId end
                if not equippedId then return end

                for index, player in ipairs(Players:GetPlayers()) do
                    if player == LocalPlayer then continue end
                    if isSameTeam(player) then continue end
                    if isImmune(player) then continue end
                    local char = player.Character; if not char then continue end
                    local targetHumanoid = char:FindFirstChildWhichIsA("Humanoid")
                    if not targetHumanoid or targetHumanoid.Health <= 0 then continue end
                    local targetHeadPart = char:FindFirstChild("Head"); if not targetHeadPart then continue end
                    local multiTargetOriginPos = targetHeadPart.Position - Vector3.new(0, 5, 0)
                    local shotPayload = buildShotTransformPayload(multiTargetOriginPos, targetHeadPart)
                    pcall(function() UseItemRemote:FireServer(equippedId, enumShoot, shotPayload, nil) end)
                end
            end)
        end, function(err1) end)
    end)
end

local PlayerScripts2 = LocalPlayer.PlayerScripts
local ModulesClient = PlayerScripts2:WaitForChild("Controllers", 10)

local CosmeticEnumBuilder = require(ReplicatedStorage.Modules:WaitForChild("EnumLibrary", 10))
if CosmeticEnumBuilder then CosmeticEnumBuilder:WaitForEnumBuilder() end

local CosmeticsLib = require(ReplicatedStorage.Modules:WaitForChild("CosmeticLibrary", 10))
local ItemLibraryLib = require(ReplicatedStorage.Modules:WaitForChild("ItemLibrary", 10))
local InventoryLib = require(ModulesClient:WaitForChild("PlayerDataController", 10))

local equippedCosmetics, favoriteCosmetics = {}, {}
local currentCosmeticWeapon, currentCosmeticPlayer = nil, nil
local tempEquipName = nil

local function buildCosmeticData(cosmeticName, cosmeticType, cosmeticOptions)
    local cosmeticDef = CosmeticsLib.Cosmetics[cosmeticName]
    if not cosmeticDef then return nil end
    local notifData = {}
    for key, value in pairs(cosmeticDef) do notifData[key] = value end
    notifData.Name = cosmeticName
    notifData.Type = notifData.Type or cosmeticType
    notifData.Seed = notifData.Seed or math.random(1, 1000000)
    if CosmeticEnumBuilder then
        local getObjectsSuccess, enumVal = pcall(CosmeticEnumBuilder.ToEnum, CosmeticEnumBuilder, cosmeticName)
        if getObjectsSuccess and enumVal then notifData.Enum, notifData.ObjectID = enumVal, notifData.ObjectID or enumVal end
    end
    if cosmeticOptions then
        if cosmeticOptions.inverted ~= nil then notifData.Inverted = cosmeticOptions.inverted end
        if cosmeticOptions.favoritesOnly ~= nil then notifData.OnlyUseFavorites = cosmeticOptions.favoritesOnly end
    end
    return notifData
end

local configFile = "unlockall/config.json"
local function saveCosmeticConfig()
    if not writefile then return end
    pcall(function()
        local configData = {equippedCosmetics = {}, favoriteCosmetics = favoriteCosmetics}
        for weaponKey, weaponCosmetics in pairs(equippedCosmetics) do
            configData.equipped[weaponKey] = {}
            for cosmeticType, cosmeticData in pairs(weaponCosmetics) do
                if cosmeticData and cosmeticData.Name then
                    configData.equipped[weaponKey][cosmeticType] = {
                        cosmeticName = cosmeticData.Name, seed = cosmeticData.Seed, inverted = cosmeticData.Inverted
                    }
                end
            end
        end
        makefolder("unlockall")
        writefile(configFile, HttpService:JSONEncode(configData))
    end)
end

local function loadCosmeticConfig()
    if not readfile or not isfile or not isfile(configFile) then return end
    pcall(function()
        local configData = HttpService:JSONDecode(readfile(configFile))
        if configData.equipped then
            for weaponKey, weaponCosmetics in pairs(configData.equipped) do
                equippedCosmetics[weaponKey] = {}
                for cosmeticType, cosmeticData in pairs(weaponCosmetics) do
                    local cosmeticInst = buildCosmeticData(cosmeticData.name, cosmeticType, {inverted = cosmeticData.inverted})
                    if cosmeticInst then cosmeticInst.Seed = cosmeticData.seed equippedCosmetics[weaponKey][cosmeticType] = cosmeticInst end
                end
            end
        end
        favoriteCosmetics = configData.favorites or {}
    end)
end

local unlockAllCosmeticsEnabled = false

local oldOwnsCosmetic = CosmeticsLib.OwnsCosmetic
CosmeticsLib.OwnsCosmetic = function(self, playerInst, cosmeticName, weaponKey)
    if not unlockAllCosmeticsEnabled then
        return oldOwnsCosmetic(self, playerInst, cosmeticName, weaponKey)
    end
    if cosmeticName:find("MISSING_") then return oldOwnsCosmetic(self, playerInst, cosmeticName, weaponKey) end
    local cosmeticInfo = CosmeticsLib.Cosmetics[cosmeticName]
    if cosmeticInfo then
        local cosmType = cosmeticInfo.Type
        if cosmType == "Skin" or cosmType == "Charm" or cosmType == "Dance" or cosmType == "Emote" or cosmType == "Wrap" or cosmType == "Wrapping" or cosmeticName:lower():find("charm") or cosmeticName:lower():find("dance") or cosmeticName:lower():find("emote") or cosmeticName:lower():find("wrap") then
            return true
        end
    end
    return oldOwnsCosmetic(self, playerInst, cosmeticName, weaponKey)
end

CosmeticsLib.OwnsCosmeticNormally = function(self, playerInst, cosmeticName, weaponKey)
    if not unlockAllCosmeticsEnabled then return false end
    local cosmeticInfo = CosmeticsLib.Cosmetics[cosmeticName]
    if cosmeticInfo and cosmeticInfo.Type == "Skin" then return true end
    return false
end

CosmeticsLib.OwnsCosmeticUniversally = function(self, playerInst, cosmeticName, weaponKey)
    if not unlockAllCosmeticsEnabled then return false end
    local cosmeticInfo = CosmeticsLib.Cosmetics[cosmeticName]
    if cosmeticInfo and cosmeticInfo.Type == "Skin" then return true end
    return false
end

CosmeticsLib.OwnsCosmeticForWeapon = function(self, playerInst, cosmeticName, weaponKey)
    if not unlockAllCosmeticsEnabled then return false end
    local cosmeticInfo = CosmeticsLib.Cosmetics[cosmeticName]
    if cosmeticInfo and cosmeticInfo.Type == "Skin" then return true end
    return false
end

local oldInventoryGet = InventoryLib.Get
InventoryLib.Get = function(self, key)
    local notifData = oldInventoryGet(self, key)
    if not unlockAllCosmeticsEnabled then
        return notifData
    end
    if key == "CosmeticInventory" then
        local fakeInventory = {}
        if notifData then for k, val in pairs(notifData) do 
            local cosmeticInfo = CosmeticsLib.Cosmetics[k]
            if cosmeticInfo then fakeInventory[k] = val end
        end end
        return setmetatable(fakeInventory, {_5087x733 = function(t, k)
            local cosmeticInfo = CosmeticsLib.Cosmetics[k]
            if cosmeticInfo then return true end
            return nil
        end})
    end
    if key == "FavoritedCosmetics" then
        local rayHit = notifData and table.clone(notifData) or {}
        for weaponKey, favs in pairs(favoriteCosmetics) do
            rayHit[weaponKey] = rayHit[weaponKey] or {}
            for cosmeticName, isFavorite in pairs(favs) do 
                rayHit[weaponKey][cosmeticName] = isFavorite
            end
        end
        return rayHit
    end
    return notifData
end

local oldGetWeaponData = InventoryLib.GetWeaponData
InventoryLib.GetWeaponData = function(self, weaponName)
    local notifData = oldGetWeaponData(self, weaponName)
    if not notifData then return nil end
    local weaponDataCopy = {}
    for key, value in pairs(notifData) do weaponDataCopy[key] = value end
    weaponDataCopy.Name = weaponName
    if equippedCosmetics[weaponName] then
        for cosmeticType, cosmeticData in pairs(equippedCosmetics[weaponName]) do 
            weaponDataCopy[cosmeticType] = cosmeticData
        end
    end
    return weaponDataCopy
end

local FighterControllerLib
pcall(function() FighterControllerLib = require(ModulesClient:WaitForChild("FighterController", 10)) end)

if hookmetamethod then
    local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local Replication = Remotes and Remotes:FindFirstChild("Data")
    local EquipCosmeticRemote = Replication and Replication:FindFirstChild("EquipCosmetic")
    local FavoriteCosmeticRemote = Replication and Replication:FindFirstChild("FavoriteCosmetic")
    local Fighter = Remotes and Remotes:FindFirstChild("Replication")
    local Events = Fighter and Fighter:FindFirstChild("Fighter")
    local ItemEquippedRemote = Events and Events:FindFirstChild("UseItem")
    
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if getnamecallmethod() ~= "FireServer" then return oldNamecall(self, ...) end
        local args = {...}
        
        if ItemEquippedRemote and self == ItemEquippedRemote then
            local equipItemId = args[1]
            if FighterControllerLib then
                pcall(function()
                    local fighterInst = FighterControllerLib:GetFighter(LocalPlayer)
                    if fighterInst and fighterInst.Items then
                        for index, EquippedItem in pairs(fighterInst.Items) do
                            if EquippedItem:Get("ObjectID") == equipItemId then tempEquipName = EquippedItem.Name break end
                        end
                    end
                end)
            end

        end
        
        if self == EquipCosmeticRemote then
            local weaponName, cosmeticType, equipCosmName, cosmeticOptions = args[1], args[2], args[3], args[4] or {}
            
            if equipCosmName and equipCosmName ~= "None" and equipCosmName ~= "" then
                local playerInst = oldInventoryGet(InventoryLib, "CosmeticInventory")
                if playerInst and rawget(playerInst, equipCosmName) then 
                    return oldNamecall(self, ...) 
                end
            end
            
            if cosmeticType == "Dance" or cosmeticType == "Emote" or (equipCosmName and (equipCosmName:lower():find("dance") or equipCosmName:lower():find("emote"))) then
                equippedCosmetics.Dances = equippedCosmetics.Dances or {}
                if not equipCosmName or equipCosmName == "None" or equipCosmName == "" then
                    equippedCosmetics.Dances[cosmeticType] = nil
                else
                    local cosmeticInst = buildCosmeticData(equipCosmName, cosmeticType, {inverted = cosmeticOptions.IsInverted, favoritesOnly = cosmeticOptions.OnlyUseFavorites})
                    if cosmeticInst then equippedCosmetics.Dances[cosmeticType] = cosmeticInst end
                end
                task.defer(function()
                    pcall(function() InventoryLib.CurrentData:Replicate("CosmeticInventory") end)
                    task.wait(0.1)
                    saveCosmeticConfig()
                end)
                return
            end
            
            equippedCosmetics[weaponName] = equippedCosmetics[weaponName] or {}
            if not equipCosmName or equipCosmName == "None" or equipCosmName == "" then
                equippedCosmetics[weaponName][cosmeticType] = nil
                if not next(equippedCosmetics[weaponName]) then equippedCosmetics[weaponName] = nil end
            else
                local cosmeticInst = buildCosmeticData(equipCosmName, cosmeticType, {inverted = cosmeticOptions.IsInverted, favoritesOnly = cosmeticOptions.OnlyUseFavorites})
                if cosmeticInst then equippedCosmetics[weaponName][cosmeticType] = cosmeticInst end
            end
            
            task.defer(function()
                pcall(function() InventoryLib.CurrentData:Replicate("WeaponInventory") end)
                task.wait(0.1)
                saveCosmeticConfig()
            end)
            return
        end
        
        if self == FavoriteCosmeticRemote then
            local favWeaponName, favCosmName, isFavorite = args[1], args[2], args[3]
            local cosmeticInfo = CosmeticsLib.Cosmetics[favCosmName]
            if cosmeticInfo then
                favoriteCosmetics[favWeaponName] = favoriteCosmetics[favWeaponName] or {}
                favoriteCosmetics[favWeaponName][favCosmName] = isFavorite or nil
                saveCosmeticConfig()
                task.spawn(function() pcall(function() InventoryLib.CurrentData:Replicate("FavoritedCosmetics") end) end)
            end
            return
        end
        
        return oldNamecall(self, ...)
    end)
end

local ClientItemClass
pcall(function() ClientItemClass = require(LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem) end)

if ClientItemClass and ClientItemClass._CreateViewModel then
    local oldCreateViewModel = ClientItemClass._CreateViewModel
    ClientItemClass._CreateViewModel = function(self, viewmodelRef)
        local weaponName = self.Name
        local vmPlayer = self.ClientFighter and self.ClientFighter.Player
        currentCosmeticWeapon = (vmPlayer == LocalPlayer) and weaponName or nil
        
        if vmPlayer == LocalPlayer and equippedCosmetics[weaponName] and viewmodelRef then
            local enumWeaponData = self:ToEnum("Data")
            local vmWeaponData = viewmodelRef[enumWeaponData] or viewmodelRef.Data
            
            if vmWeaponData then
                if equippedCosmetics[weaponName].Skin then
                    vmWeaponData[self:ToEnum("Skin") or "Skin"] = equippedCosmetics[weaponName].Skin
                    vmWeaponData[self:ToEnum("Name") or "Name"] = equippedCosmetics[weaponName].Skin.Name
                end
                if equippedCosmetics[weaponName].Charm then
                    vmWeaponData[self:ToEnum("Charm") or "Charm"] = equippedCosmetics[weaponName].Charm
                end
                if equippedCosmetics[weaponName].Wrap then
                    vmWeaponData[self:ToEnum("Wrap") or "Wrap"] = equippedCosmetics[weaponName].Wrap
                end
            end
        end
        
        local rayHit = oldCreateViewModel(self, viewmodelRef)
        currentCosmeticWeapon = nil
        return rayHit
    end
end

local ClientItemMod = LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
if ClientItemMod then
    local ClientItemReq = require(ClientItemMod)
    
    if ClientItemReq.GetCharm then
        local oldGetCharm = ClientItemReq.GetCharm
        ClientItemReq.GetCharm = function(self)
            local weaponName = self.ClientItem and self.ClientItem.Name
            local vmPlayer = self.ClientItem and self.ClientItem.ClientFighter and self.ClientItem.ClientFighter.Player
            if weaponName and vmPlayer == LocalPlayer and equippedCosmetics[weaponName] and equippedCosmetics[weaponName].Charm then
                return equippedCosmetics[weaponName].Charm
            end
            return oldGetCharm(self)
        end
    end
    
    if ClientItemReq.GetWrap then
        local oldGetWrap = ClientItemReq.GetWrap
        ClientItemReq.GetWrap = function(self)
            local weaponName = self.ClientItem and self.ClientItem.Name
            local vmPlayer = self.ClientItem and self.ClientItem.ClientFighter and self.ClientItem.ClientFighter.Player
            if weaponName and vmPlayer == LocalPlayer and equippedCosmetics[weaponName] and equippedCosmetics[weaponName].Wrap then
                return equippedCosmetics[weaponName].Wrap
            end
            return oldGetWrap(self)
        end
    end

    local oldClientItemNew = ClientItemReq.new
    ClientItemReq.new = function(replicatedData, clientItem)
        local vmPlayer = clientItem.ClientFighter and clientItem.ClientFighter.Player
        local weaponName = currentCosmeticWeapon or clientItem.Name
        if vmPlayer == LocalPlayer and equippedCosmetics[weaponName] then
            local RepClass = require(ReplicatedStorage.Modules.ReplicatedClass)
            local enumWeaponData = RepClass:ToEnum("Data")
            replicatedData[enumWeaponData] = replicatedData[enumWeaponData] or {}
            
            local weaponCosmetics = equippedCosmetics[weaponName]
            if weaponCosmetics.Skin then replicatedData[enumWeaponData][RepClass:ToEnum("Skin")] = weaponCosmetics.Skin end
            if weaponCosmetics.Charm then replicatedData[enumWeaponData][RepClass:ToEnum("Charm")] = weaponCosmetics.Charm end
            if weaponCosmetics.Wrap then replicatedData[enumWeaponData][RepClass:ToEnum("Wrap")] = weaponCosmetics.Wrap end
        end
        
        local rayHit = oldClientItemNew(replicatedData, clientItem)
        
        if vmPlayer == LocalPlayer and equippedCosmetics[weaponName] and equippedCosmetics[weaponName].Wrap and rayHit._UpdateWrap then
            rayHit:_UpdateWrap()
            task.delay(0.1, function() if not rayHit._destroyed then rayHit:_UpdateWrap() end end)
        end
        return rayHit
    end
end

ItemLibraryLib.GetViewModelImageFromWeaponData = function(self, weaponData, highRes)
    if not weaponData then return nil end
    local weaponName = weaponData.Name
    local isLocalCosmetic = (weaponData.Skin and equippedCosmetics[weaponName] and weaponData.Skin == equippedCosmetics[weaponName].Skin) or (currentCosmeticPlayer == LocalPlayer and equippedCosmetics[weaponName] and equippedCosmetics[weaponName].Skin)
    if isLocalCosmetic and equippedCosmetics[weaponName] and equippedCosmetics[weaponName].Skin then
        local vmSkinData = self.ViewModels[equippedCosmetics[weaponName].Skin.Name]
        if vmSkinData then return vmSkinData[highRes and "ImageHighResolution" or "Image"] or vmSkinData.Image end
    end
    return nil
end

local EmoteController
pcall(function() 
    EmoteController = require(ModulesClient:WaitForChild("EmoteController", 10))
    if EmoteController and EmoteController.GetEmotes then
        local oldGetEmotes = EmoteController.GetEmotes
        EmoteController.GetEmotes = function(self)
            local emotesList = oldGetEmotes(self)
            for cosmeticName, cosmeticInfo in pairs(CosmeticsLib.Cosmetics) do
                if cosmeticInfo and (cosmeticInfo.Type == "Dance" or cosmeticInfo.Type == "Emote" or cosmeticName:lower():find("dance") or cosmeticName:lower():find("emote")) then
                    if not emotesList[cosmeticName] then
                        emotesList[cosmeticName] = { Name = cosmeticName, Type = cosmeticInfo.Type, ObjectID = cosmeticInfo.ObjectID, Enum = cosmeticInfo.Enum }
                    end
                end
            end
            return emotesList
        end
    end
end)

pcall(function()
    local ViewProfile = require(LocalPlayer.PlayerScripts.Modules.Pages.ViewProfile)
    if ViewProfile and ViewProfile.Fetch then
        local oldViewProfileFetch = ViewProfile.Fetch
        ViewProfile.Fetch = function(self, targetPlayer)
            currentCosmeticPlayer = targetPlayer
            return oldViewProfileFetch(self, targetPlayer)
        end
    end
end)
loadCosmeticConfig()

local mainWindow = nexlib:Window("í ë¬´ë°í¬ free")

local tabDict = {
    ["Combat"] = mainWindow:Tab("Combat"),
    ["Visuals"] = mainWindow:Tab("Visuals"),
    ["Misc"] = mainWindow:Tab("Misc"),
    ["UI Settings"] = mainWindow:Tab("UI Settings")
}

local silentAimSection = tabDict["Combat"]:Section("silent aim", 2)
local aimbotSection = tabDict["Combat"]:Section("aimbot", 1)

silentAimSection:Toggle("enabled", false, function(val) silentAimEnabled = val end)
silentAimSection:Dropdown("hitbox", {"head", "humanoidrootpart", "torso"}, "head", function(val) silentAimTargetPartType = val end)
silentAimSection:Slider("fov radius", 10, 500, 300, 0, function(val) silentAimFovRadius = val end)
silentAimSection:Toggle("draw fov", false, function(val) silentAimShowFov = val end)
silentAimSection:Toggle("wallcheck", false, function(val) silentAimCheckVis = val end)

aimbotSection:Toggle("aimbot enabled", false, function(val) aimbotEnabled = val end)
aimbotSection:Dropdown("hitbox", {"head", "humanoidrootpart", "torso"}, "head", function(val) aimbotTargetPartType = val end)
aimbotSection:Slider("smoothness", 1, 20, 5, 1, function(val) aimbotSmoothing = val end)
aimbotSection:Slider("fov radius", 10, 500, 100, 0, function(val) aimbotFovRadius = val end)
aimbotSection:Toggle("draw fov", false, function(val) aimbotShowFov = val end)
aimbotSection:Toggle("wallcheck", false, function(val) aimbotCheckVis = val end)
aimbotSection:Toggle("scope look", false, function(val) aimbotAutoFire = val end)

local uiSection = tabDict["Combat"]:Section("mobile setting", 1)
uiSection:Toggle("mobile on", false, function(val)
    local mainFrame = uiScreenGui:FindFirstChild("MainFrame", true)
    if mainFrame then
        mainFrame.ClipsDescendants = true
        local uiTabHolder = mainFrame:FindFirstChild("ContainerHolderFrame")
        if uiTabHolder then
            uiTabHolder.ClipsDescendants = true
            uiTabHolder.Size = UDim2.new(1, -18, 1, -42)
        end
        local TweenService = game:GetService("TweenService")
        local newUiSize = val and UDim2.new(0, 525, 0, 300) or UDim2.new(0, 525, 0, 631)
        TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = newUiSize
        }):Play()
    end
end)
local orbitSection = tabDict["Combat"]:Section("pull enabled", 1)
orbitSection:Toggle("pull", false, function(val) orbitEnabled = val end) 

local ragebotSection = tabDict["Combat"]:Section("ragebot", 1)
ragebotSection:Toggle("enabled", false, function(val) 
    L555_61 = val
    pcall(function() setTargetFireLoop(val) end)
end)
ragebotSection:Toggle("orbit", false, function(val)
    voidSpamEnabled = val
    if val then
        voidSpamHeight = 5003
    end
end)
ragebotSection:Toggle("voidspam", false, function(val)
    ragebotEnabled = val
    if not val then
        canFireRagebot = true
    end
end)
ragebotSection:Slider("hide", 0.01, 1, 0.25, 2, function(val)
    ragebotCooldown = val
end)
ragebotSection:Slider("attack", 0.01, 1, 0.1, 2, function(val)
    ragebotDuration = val
end)

local espSection = tabDict["Combat"]:Section("ffamods", 2)
espSection:Toggle("team check", true, function(val)
    teamCheckEnabled = val
end)
espSection:Toggle("baiting", false, function(val)
    multiTargetFireEnabled = val
    flyEnabled = val
    pcall(function() setMultiTargetFireLoop(val) end)
end)

local triggerbotSection = tabDict["Combat"]:Section("triggerbot", 2)
triggerbotSection:Toggle("enabled", false, function(val)
    triggerBotEnabled = val
end)

local gunModsSection = tabDict["Combat"]:Section("weapons", 2)
gunModsSection:Toggle("no spread", false, function(val)
    noSpreadEnabled = val
    
end)
gunModsSection:Toggle("no muzzle flash", false, function(val)
    noMuzzleFlashEnabled = val
    
end)
gunModsSection:Toggle("attack cooldown", false, function(val)
    noCooldownEnabled = val
    if not val then
        pcall(function()
            restoreGcAttribute("ShootCooldown")
        end)
        wasNoCooldownEnabled = false
    end
end)
gunModsSection:Toggle("projectile cooldown", false, function(val)
    fastReloadEnabled = val
    if val then
        pcall(reduceProjectileReload)
    else
        pcall(restoreProjectileReload)
    end
end)

local voidSpamSection = tabDict["Combat"]:Section("orb,void", 2)
voidSpamSection:Toggle("orbit", false, function(val) voidSpamEnabled = val end)
voidSpamSection:Slider("orbit studs", 5, 10000, 50000000, 0, function(val) voidSpamHeight = val end)
voidSpamSection:Toggle("void spam", false, function(val) flyEnabled = val end)
voidSpamSection:Slider("void spam studs", 50, 50000000, 50, 0, function(val) flyHeight = val end)

local visualsWorldSection = tabDict["Visuals"]:Section("environment", 1)
visualsWorldSection:Toggle("Fullbright", false, function(val)
    fullbrightActive = val
    local Lighting = game:GetService("Lighting")
    if val then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.GlobalShadows = true
    end
end)

visualsWorldSection:Toggle("shader", false, function(val)
    fullbrightEnabled = val
end)

local visualsSkyboxSection = tabDict["Visuals"]:Section("skybox", 2)
visualsSkyboxSection:Toggle("skyboxs", false, function(val)
    customSkyboxEnabled = val
    applySkybox(customSkyboxType)
end)

visualsSkyboxSection:Dropdown("Select Skybox", {"Dark Sky", "Vaporwave", "Lake Sky", "Black Mesa"}, "", function(val)
    customSkyboxType = val
    if customSkyboxEnabled then
        applySkybox(val)
    end
end)

local espSettingsSection = tabDict["Visuals"]:Section("visual esp", 1)
espSettingsSection:Toggle("ESP Active", false, function(val) espEnabled = val end)
espSettingsSection:Toggle("Box Display", true, function(val) espShowBoxes = val end)
espSettingsSection:Toggle("Name Display", true, function(val) espShowNames = val end)
espSettingsSection:Toggle("Health Display", true, function(val) espShowHealth = val end)
espSettingsSection:Toggle("weapon info", true, function(val) espShowWeapons = val end)

local targetInfoSection = tabDict["Visuals"]:Section("indicators", 1)
targetInfoSection:Toggle("ragebot", false, function(val) showTargetInfo = val end)
targetInfoSection:Toggle("ammo", false, function(val) showAmmoInfo = val end)

local cosmeticsSection = tabDict["Visuals"]:Section("viewmodel cosmetics", 1)
cosmeticsSection:Toggle("no recoil", false, function(val)
    noRecoilEnabled = val
    if not val then
        pcall(function()
            restoreGcAttribute("ShootRecoil")
        end)
        wasNoRecoilEnabled = false
    end
end)
cosmeticsSection:Toggle("unlock all", false, function(val)
    unlockAllCosmeticsEnabled = val
    pcall(function()
        if InventoryLib and InventoryLib.CurrentData then
            InventoryLib.CurrentData:Replicate("CosmeticInventory")
            InventoryLib.CurrentData:Replicate("WeaponInventory")
        end
    end)
end)

local customHitSoundEnabled = false
local customHitSoundType = "rust hs"
local customHitSoundVolume = 1.0
local customHitSoundPitch = 1.0

local hitSoundIds = {
    ["rust hs"] = "rbxassetid://4764109000",
    ["neverlose"] = "rbxassetid://97643101798871",
    ["sparkle"] = "rbxassetid://110241936966089",
    ["minecraft hit"] = "rbxassetid://8766809464",
    ["bonk"] = "rbxassetid://5766898159",
    ["osu"] = "rbxassetid://7149255551",
    ["among us"] = "rbxassetid://5700183626",
    ["bruh"] = "rbxassetid://4578740568",
    ["vine"] = "rbxassetid://5332680810",
    ["gamesense"] = "rbxassetid://4817809188",
    ["ì¥ì¶©ë ìì¡±ë° ë³´ì"] = "rbxassetid://85775332966635",
}

local hitSoundNames = {
    "rust hs",
    "neverlose",
    "sparkle",
    "minecraft hit",
    "bonk",
    "osu",
    "among us",
    "bruh",
    "vine",
    "gamesense",
    "ì¥ì¶©ë ìì¡±ë° ë³´ì",
}

local hitSoundSection = tabDict["Visuals"]:Section("hit sounds", 2)
hitSoundSection:Toggle("enable hit sound", false, function(val)
    customHitSoundEnabled = val
end)
hitSoundSection:Dropdown("hit sound style", hitSoundNames, "rust hs", function(val)
    customHitSoundType = val
end)
hitSoundSection:Slider("volume", 0, 2, 1, 1, function(val)
    customHitSoundVolume = val
end)
hitSoundSection:Slider("pitch (speed)", 1, 20, 10, 1, function(val)
    
    customHitSoundPitch = math.clamp(val / 10, 0.1, 2)
end)

pcall(function()
    local ClientViewModel = LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem.ClientViewModel
    ClientViewModel.ChildAdded:Connect(function(val)
        if not customHitSoundEnabled then return end
        if val:IsA("Sound") and val.SoundId ~= "rbxassetid://16537449730" then
            pcall(function()
                local targetSoundId = hitSoundIds[customHitSoundType] or hitSoundIds["rust hs"]
                val.SoundId = targetSoundId
                val.Pitch = customHitSoundPitch
                val.Volume = 0

                local newSound = Instance.new("Sound")
                newSound.SoundId = targetSoundId
                newSound.Pitch = customHitSoundPitch
                newSound.Volume = customHitSoundVolume
                newSound.Parent = game:GetService("SoundService")
                newSound:Play()
                game:GetService("Debris"):AddItem(newSound, 4)
            end)
        end
    end)
end)

local movementSection = tabDict["Misc"]:Section("movement", 1)
movementSection:Toggle("Mobile Fly", false, function(val) noclipEnabled = val end)
movementSection:Slider("Mobile Fly Speed", 1, 3000, 50, 0, function(val) noclipSpeed = val end)
movementSection:Toggle("PC Fly", false, function(val) flyNoclipEnabled = val end)
movementSection:Slider("PC Fly Speed", 1, 10000, 50, 0, function(val) flyNoclipSpeed = val end)
movementSection:Toggle("Noclip Active", false, function(val) collisionDisabled = val end)
movementSection:Dropdown("Noclip Mode", {"all walls", "phong"}, "all walls", function(val) movementMethod = val end)

local emoteSection = tabDict["Misc"]:Section("emote hop", 2)
emoteSection:Toggle("Emote Hop", false, function(val) 
    loopEmoteEnabled = val 
    if val and LocalPlayer.Character then startLoopedEmote(LocalPlayer.Character) else stopEmote() end
end)
emoteSection:Slider("Emote Speed", 1, 40, 40, 0, function(val) 
    loopEmoteSpeed = val 
    if loopEmoteTrack and loopEmoteTrack.IsPlaying then loopEmoteTrack:AdjustSpeed(val) end
end)

local chatSpamSection = tabDict["Misc"]:Section("device spoofer", 2)
chatSpamSection:Toggle("device spoofer", false, function(val)
    chatSpamEnabled = val
end)

chatSpamSection:Dropdown("device selection", {"vr", "touch", "gamepad", "mousekeyboard"}, "vr", function(val)
    chatSpamMessage = val
end)
local thirdPersonSection = tabDict["Misc"]:Section("third person", 2)
thirdPersonSection:Toggle("enabled", false, function(val)
    thirdPersonEnabled = val
    pcall(function()
        local player = cloneref(game:GetService("Players"))
        local CameraController = require(player.LocalPlayer.PlayerScripts.Controllers.CameraController)
        if val then
            CameraController.CameraState:_SetPOVState(CameraController.CameraState.States.ThirdPersonMirrored)
        else
            
            local CamStates = CameraController.CameraState.States
            local fpState = CamStates.FirstPerson or CamStates.FirstPersonMirrored or CamStates.Default
            if fpState then
                CameraController.CameraState:_SetPOVState(fpState)
            end
        end
    end)
end)

local autoPickupSection = tabDict["Misc"]:Section("arcade servers", 2)
autoPickupSection:Toggle("automatically grab drops", false, function(val)
    autoPickupEnabled = val
end)

local uiSettingsSection = tabDict["UI Settings"]:Section("menu settings", 1)
uiSettingsSection:Label("Press [RightShift] to Toggle UI")

local themeColorDrop = uiSettingsSection:Dropdown("Theme Color", {"Sky Blue", "Red", "Lime Green", "Purple", "Orange"}, "Sky Blue", function(colorName)
    if colorName == "Sky Blue" then nexlib.accentclr = Color3.fromRGB(128, 213, 247)
    elseif colorName == "Red" then nexlib.accentclr = Color3.fromRGB(255, 75, 75)
    elseif colorName == "Lime Green" then nexlib.accentclr = Color3.fromRGB(75, 255, 75)
    elseif colorName == "Purple" then nexlib.accentclr = Color3.fromRGB(180, 75, 255)
    elseif colorName == "Orange" then nexlib.accentclr = Color3.fromRGB(255, 140, 0)
    end
end)

uiSettingsSection:Button("Unload UI", function()
    nexlib:Notification("Shutting Down", "Goodbye!", 1.5)
    task.wait(1.5)
    mainWindow:Destroy()
end)

local configSection = tabDict["UI Settings"]:Section("Configuration", 2)
local configCreateName = ""
configSection:Input("Config Name", "", "Input here...", function(sliderValue)
    configCreateName = sliderValue
end)

configSection:Button("Create", function()
    if configCreateName ~= "" then
        nexlib:Notification("Config", "Created: " .. configCreateName, 1.5)
    else
        nexlib:Notification("Error", "Please enter a config name!", 1.5)
    end
end)
local configSelectedName = ""
local configList = {"Legitv1", "Ragev2"}
local configDropdown = configSection:Dropdown("Configs", configList, "", function(sliderValue)
    configSelectedName = sliderValue
end)

configSection:Button("Load", function()
    if configSelectedName ~= "" then
        nexlib:Notification("Config", "Loaded: " .. configSelectedName, 1.5)
    else
        nexlib:Notification("Error", "No config selected!", 1.5)
    end
end)

configSection:Button("Save", function()
    if configSelectedName ~= "" then
        nexlib:Notification("Config", "Saved changes to: " .. configSelectedName, 1.5)
    else
        nexlib:Notification("Error", "No config selected to save!", 1.5)
    end
end)

configSection:Button("Delete", function()
    if configSelectedName ~= "" then
        nexlib:Notification("Config", "Deleted: " .. configSelectedName, 1.5)
        configSelectedName = ""
    else
        nexlib:Notification("Error", "No config selected to delete!", 1.5)
    end
end)
local infoGui = Instance.new("ScreenGui")
infoGui.Name = "HalmuIndicators"
infoGui.ResetOnSpawn = false
infoGui.IgnoreGuiInset = true
infoGui.DisplayOrder = 999
infoGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
    infoGui.Parent = game:GetService("CoreGui")
end)
if not infoGui.Parent then
    infoGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local targetInfoLabel = Instance.new("TextLabel")
targetInfoLabel.Name = "RagebotIndicator"
targetInfoLabel.BackgroundTransparency = 1
targetInfoLabel.Size = UDim2.new(0, 420, 0, 22)
targetInfoLabel.AnchorPoint = Vector2.new(0.5, 0)
targetInfoLabel.Position = UDim2.new(0.5, 0, 0.5, 36)
targetInfoLabel.Font = Enum.Font.Code
targetInfoLabel.TextSize = 14
targetInfoLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
targetInfoLabel.TextStrokeTransparency = 0
targetInfoLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
targetInfoLabel.Text = ""
targetInfoLabel.Visible = false
targetInfoLabel.Parent = infoGui

local ammoInfoLabel = Instance.new("TextLabel")
ammoInfoLabel.Name = "AmmoIndicator"
ammoInfoLabel.BackgroundTransparency = 1
ammoInfoLabel.Size = UDim2.new(0, 420, 0, 18)
ammoInfoLabel.AnchorPoint = Vector2.new(0.5, 0)
ammoInfoLabel.Position = UDim2.new(0.5, 0, 0.5, 52)
ammoInfoLabel.Font = Enum.Font.Code
ammoInfoLabel.TextSize = 11
ammoInfoLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
ammoInfoLabel.TextStrokeTransparency = 0
ammoInfoLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
ammoInfoLabel.Text = ""
ammoInfoLabel.Visible = false
ammoInfoLabel.Parent = infoGui

local function getAmmoState()
    local currentAmmo, reserveAmmo, isReloading = nil, nil, false
    pcall(function()
        local PlayerScripts = LocalPlayer.PlayerScripts
        local success, FighterController2 = pcall(require, PlayerScripts.Controllers.FighterController)
        if not success or not FighterController2 then return end
        local LocalFighter = FighterController2.LocalFighter
        if not LocalFighter then return end
        local EquippedItem = LocalFighter.EquippedItem
        if not EquippedItem then return end

        local function readItemField(key)
            local successItem, sliderValue = pcall(function()
                if EquippedItem.Get then return EquippedItem:Get(key) end
                return EquippedItem[key] or (EquippedItem.Data and EquippedItem.Data[key]) or (EquippedItem.Info and EquippedItem.Info[key])
            end)
            if successItem then return sliderValue end
            return nil
        end

        currentAmmo = readItemField("CurrentAmmo") or readItemField("Ammo") or readItemField("Bullets") or readItemField("MagazineAmmo")
        reserveAmmo = readItemField("ReserveAmmo") or readItemField("StoredAmmo") or readItemField("Reserve") or readItemField("TotalAmmo") or readItemField("MaxAmmo") or readItemField("MaxBullets")
        local isReloading2 = readItemField("Reloading") or readItemField("IsReloading") or readItemField("Reload")
        isReloading = isReloading2 == true

        
        if EquippedItem.Info and type(EquippedItem.Info) == "table" then
            if currentAmmo == nil then currentAmmo = EquippedItem.Info.CurrentAmmo or EquippedItem.Info.Ammo end
            if reserveAmmo == nil then reserveAmmo = EquippedItem.Info.ReserveAmmo or EquippedItem.Info.StoredAmmo or EquippedItem.Info.MaxAmmo end
            if EquippedItem.Info.Reloading == true or EquippedItem.Info.IsReloading == true then
                isReloading = true
            end
        end
    end)
    return currentAmmo, reserveAmmo, isReloading
end

RunService.RenderStepped:Connect(function()
    local vpSize = Camera.ViewportSize

    
    if showTargetInfo and L555_61 then
        local cosmeticName = "idk"
        if ragebotTargetPart and ragebotTargetPart.Parent then
            local targetModel = ragebotTargetPart:FindFirstAncestorOfClass("Model") or ragebotTargetPart.Parent
            local __bdUacYjXOqr = Players:GetPlayerFromCharacter(targetModel)
            if __bdUacYjXOqr then
                cosmeticName = __bdUacYjXOqr.DisplayName or __bdUacYjXOqr.Name
            elseif typeof(targetModel) == "Instance" then
                cosmeticName = targetModel.Name
            end
        end
        targetInfoLabel.Text = "ragebot : " .. tostring(cosmeticName) .. "..."
        targetInfoLabel.Position = UDim2.new(0.5, 0, 0.5, 36)
        targetInfoLabel.Visible = true
    else
        targetInfoLabel.Visible = false
    end

    
    if showAmmoInfo then
        local currentAmmo, reserveAmmo, isReloading = getAmmoState()
        local ammoTextStr
        if isReloading or (typeof(currentAmmo) == "number" and currentAmmo <= 0 and (reserveAmmo == nil or (typeof(reserveAmmo) == "number" and reserveAmmo >= 0))) then
            
            if isReloading or (typeof(currentAmmo) == "number" and currentAmmo <= 0) then
                if isReloading then
                    ammoTextStr = "reloading"
                elseif typeof(currentAmmo) == "number" and typeof(reserveAmmo) == "number" then
                    
                    ammoTextStr = string.format("%d/%d", reserveAmmo, currentAmmo)
                else
                    ammoTextStr = "reloading"
                end
            end
        end

        if not ammoTextStr then
            if typeof(currentAmmo) == "number" and typeof(reserveAmmo) == "number" then
                
                ammoTextStr = string.format("%d/%d", reserveAmmo, currentAmmo)
            elseif typeof(currentAmmo) == "number" then
                ammoTextStr = tostring(currentAmmo)
            else
                ammoTextStr = nil
            end
        end

        
        if isReloading then
            ammoTextStr = "reloading"
        end

        if ammoTextStr then
            ammoInfoLabel.Text = ammoTextStr
            local v75310 = 52
            if showTargetInfo and L555_61 then
                v75310 = 52
            end
            ammoInfoLabel.Position = UDim2.new(0.5, 0, 0.5, v75310)
            ammoInfoLabel.Visible = true
        else
            ammoInfoLabel.Visible = false
        end
    else
        ammoInfoLabel.Visible = false
    end
end)

RunService.RenderStepped:Connect(function()
    if not autoPickupEnabled then return end
    local localChar = LocalPlayer.Character
    if not localChar then return end
    local targetHead = localChar:FindFirstChild("HumanoidRootPart")
    if not targetHead then return end
    local localHum = localChar:FindFirstChild("Humanoid")
    local localHumNotFull = localHum and localHum.Health < localHum.MaxHealth
    for index, obj in workspace:GetChildren() do
        if obj.Name == "_drop" and obj:IsA("BasePart") then
            if (autoPickupAmmoEnabled and obj:FindFirstChild("Health") and localHumNotFull) or (autoPickupHealthEnabled and obj:FindFirstChild("Ammo")) then
                pcall(function()
                    firetouchinterest(targetHead, obj, 0)
                    firetouchinterest(targetHead, obj, 1)
                end)
            end
        end
    end
end)

local gcOverrideMap = {
    ShootCooldown = setmetatable({}, { __mode = "k" }),
    ShootRecoil = setmetatable({}, { __mode = "k" }),
}

local function overrideGcAttribute(attribute, value)
    local gcOverrideEntry = gcOverrideMap[attribute]
    if not gcOverrideEntry then return end
    for index, gcVal in pairs(getgc(true)) do
        if type(gcVal) == "table" then
            local currentAmmo = rawget(gcVal, attribute)
            if currentAmmo ~= nil then
                if gcOverrideEntry[gcVal] == nil then
                    gcOverrideEntry[gcVal] = currentAmmo
                end
                gcVal[attribute] = value
            end
        end
    end
end

local function restoreGcAttribute(attribute)
    local gcOverrideEntry = gcOverrideMap[attribute]
    if not gcOverrideEntry then return end
    for gcVal, original in pairs(gcOverrideEntry) do
        if type(gcVal) == "table" then
            pcall(function()
                gcVal[attribute] = original
            end)
        end
        gcOverrideEntry[gcVal] = nil
    end
end

local origReloadTimes = {}
local isReloadModded = false

local function reduceProjectileReload()
    local ItemLibraryLib = require(game:GetService("ReplicatedStorage").Modules.ItemLibrary)
    local Items = rawget(ItemLibraryLib, "Items")
    if not Items then return end
    local reloadModItems = {"Bow", "Daggers", "Slingshot"}
    for index, Item in pairs(Items) do
        local Name = Item.Name
        if table.find(reloadModItems, Name) and Item["ReloadLength"] ~= nil then
            if origReloadTimes[Name] == nil then
                origReloadTimes[Name] = Item["ReloadLength"]
            end
            rawset(Item, "ReloadLength", (Name == "Daggers" and 0.09 or 0))
        end
    end
    isReloadModded = true
end

local function restoreProjectileReload()
    local ItemLibraryLib = require(game:GetService("ReplicatedStorage").Modules.ItemLibrary)
    local Items = rawget(ItemLibraryLib, "Items")
    if not Items then return end
    local reloadModItems = {"Bow", "Daggers", "Slingshot"}
    for index, Item in pairs(Items) do
        local Name = Item.Name
        if table.find(reloadModItems, Name) and origReloadTimes[Name] ~= nil then
            rawset(Item, "ReloadLength", origReloadTimes[Name])
        end
    end
    isReloadModded = false
end

RunService.Heartbeat:Connect(function()
    if noCooldownEnabled then
        pcall(function()
            overrideGcAttribute("ShootCooldown", 0)
        end)
        wasNoCooldownEnabled = true
    elseif wasNoCooldownEnabled then
        pcall(function()
            restoreGcAttribute("ShootCooldown")
        end)
        wasNoCooldownEnabled = false
    end

    if noRecoilEnabled then
        pcall(function()
            overrideGcAttribute("ShootRecoil", 0)
        end)
        wasNoRecoilEnabled = true
    elseif wasNoRecoilEnabled then
        pcall(function()
            restoreGcAttribute("ShootRecoil")
        end)
        wasNoRecoilEnabled = false
    end

    if fastReloadEnabled then
        pcall(reduceProjectileReload)
    elseif isReloadModded then
        pcall(restoreProjectileReload)
    end
end)
LocalPlayer.CharacterAdded:Connect(function(localChar)
    if loopEmoteEnabled then
        localChar:WaitForChild("Humanoid")
        task.wait(0.1)
        if startLoopedEmote then startLoopedEmote(localChar) end
    end
    if thirdPersonEnabled then
        task.defer(function()
            pcall(function()
                local player = cloneref(game:GetService("Players"))
                local _764_114 = require(player.LocalPlayer.PlayerScripts.Controllers.CameraController)
                _764_114.CameraState:_SetPOVState(_764_114.CameraState.States.ThirdPersonMirrored)
            end)
        end)
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if chatSpamEnabled then
            pcall(function()
                local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
                local ReplicationFolder = Remotes and Remotes:FindFirstChild("Replication") or Remotes
                local fighterInst = ReplicationFolder and ReplicationFolder:FindFirstChild("Fighter")
                local ChatRemote = fighterInst and fighterInst:FindFirstChild("SetControls")
                if ChatRemote and ChatRemote:IsA("RemoteEvent") then
                    if chatSpamMessage == "vr" then ChatRemote:FireServer("VR")
                    elseif chatSpamMessage == "touch" then ChatRemote:FireServer("Touch")
                    elseif chatSpamMessage == "gamepad" then ChatRemote:FireServer("Gamepad")
                    elseif chatSpamMessage == "mousekeyboard" then ChatRemote:FireServer("MouseKeyboard") end
                end
            end)
        end
    end
end)

RunService.Stepped:Connect(function(deltaTime)
    local localChar2 = LocalPlayer.Character
    if not localChar2 then return end
    local localTorso2 = localChar2:FindFirstChild("HumanoidRootPart")
    local localHum2 = localChar2:FindFirstChild("Humanoid")
    if not localTorso2 then return end

    if collisionDisabled then
        for index, part in pairs(localChar2:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    if (noclipEnabled or flyNoclipEnabled) then
        if localHum2 then localHum2.PlatformStand = true end
        local flyVel = Vector3.zero
        if noclipEnabled then
            if localHum2 and localHum2.MoveDirection.Magnitude > 0 then
                flyVel = Camera.CFrame.LookVector * noclipSpeed
            end
        elseif flyNoclipEnabled then
            local flyDir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then flyDir = flyDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then flyDir = flyDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then flyDir = flyDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then flyDir = flyDir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then flyDir = flyDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then flyDir = flyDir - Vector3.new(0, 1, 0) end
            if flyDir.Magnitude > 0 then flyVel = flyDir.Unit * flyNoclipSpeed end
        end
        localTorso2.AssemblyLinearVelocity = flyVel
        localTorso2.AssemblyAngularVelocity = Vector3.zero
    else
        if localHum2 and localHum2.PlatformStand then
            localHum2.PlatformStand = false
            localTorso2.AssemblyLinearVelocity = Vector3.zero
        end
    end
end)

local function resolveAnimationAsset(asset_id)
    local getObjectsSuccess, getObjectsRes = pcall(function() return game:GetObjects(asset_id) end)
    if getObjectsSuccess and getObjectsRes and #getObjectsRes > 0 then
         for i = 1, #getObjectsRes do
            if getObjectsRes[i]:IsA("Animation") then return getObjectsRes[i].AnimationId end
        end
    end
    return asset_id
end

task.spawn(function()
    local emoteAssetId = "rbxassetid://92281817840531"
    emoteAssetId = resolveAnimationAsset(emoteAssetId)
    loopEmoteAnim = Instance.new("Animation")
    loopEmoteAnim.AnimationId = emoteAssetId
end)

function startLoopedEmote(localChar)
    if not loopEmoteEnabled or not localChar or not loopEmoteAnim then return end
    local humForEmote = localChar:FindFirstChildWhichIsA("Humanoid")
    if not humForEmote then return end
    if loopEmoteTrack then loopEmoteTrack:Stop() loopEmoteTrack = nil end
    local animatorForEmote = humForEmote:FindFirstChildOfClass("Animator") or humForEmote
    local loadAnimSuccess, loadedAnim = pcall(function() return animatorForEmote:LoadAnimation(loopEmoteAnim) end)
    if loadAnimSuccess and loadedAnim then
        loopEmoteTrack = loadedAnim
        loadedAnim.Priority = Enum.AnimationPriority.Action4
        loadedAnim:Play()
        loadedAnim:AdjustSpeed(loopEmoteSpeed)
        loadedAnim.Stopped:Connect(function()
            if loopEmoteEnabled and LocalPlayer.Character == localChar then startLoopedEmote(localChar) end
        end)
    end
end

function stopEmote()
    if loopEmoteTrack then loopEmoteTrack:Stop() loopEmoteTrack = nil end
end

task.spawn(function()
    while true do
        task.wait(0.05)
        if voidSpamEnabled then
            local localTorso2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if localTorso2 and not voidSpamAnchorPos then
                voidSpamAnchorPos = localTorso2.Position
            end
        else
            voidSpamAnchorPos = nil
        end
    end
end)

local function selectTargetPart(localChar, hitboxName)
    if not localChar then return nil end
    local cosmeticName = string.lower(tostring(hitboxName or "head"))
    if cosmeticName == "humanoidrootpart" then
        return localChar:FindFirstChild("HumanoidRootPart")
    elseif cosmeticName == "torso" then
        return localChar:FindFirstChild("UpperTorso") or localChar:FindFirstChild("Torso") or localChar:FindFirstChild("HumanoidRootPart")
    end
    return localChar:FindFirstChild("Head") or localChar:FindFirstChild("HumanoidRootPart")
end

local function hasLineOfSight(iterTargetPart, localChar2)
    if not iterTargetPart then return false end
    local camPos = Camera.CFrame.Position
    local rayDir = iterTargetPart.Position - camPos
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = { localChar2, Camera }
    rayParams.IgnoreWater = true
    local rayHit = workspace:Raycast(camPos, rayDir, rayParams)
    if not rayHit then
        return true
    end
    local rayHitModel = rayHit.Instance and rayHit.Instance:FindFirstAncestorOfClass("Model")
    local targetPartModel = iterTargetPart:FindFirstAncestorOfClass("Model")
    return rayHitModel ~= nil and targetPartModel ~= nil and rayHitModel == targetPartModel
end

local fovGui = Instance.new("ScreenGui")
fovGui.Name = "HalmuFOV"
fovGui.ResetOnSpawn = false
fovGui.IgnoreGuiInset = true
fovGui.DisplayOrder = 50
pcall(function() fovGui.Parent = game:GetService("CoreGui") end)
if not fovGui.Parent then
    fovGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local function createFovCircle(cosmeticName, color)
    local fovCircleFrame = Instance.new("Frame")
    fovCircleFrame.Name = cosmeticName
    fovCircleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    fovCircleFrame.BackgroundTransparency = 1
    fovCircleFrame.BorderSizePixel = 0
    fovCircleFrame.Visible = false
    fovCircleFrame.Parent = fovGui
    local fovCircleCorner = Instance.new("UICorner")
    fovCircleCorner.CornerRadius = UDim.new(1, 0)
    fovCircleCorner.Parent = fovCircleFrame
    local fovCircleStroke = Instance.new("UIStroke")
    fovCircleStroke.Thickness = 1.5
    fovCircleStroke.Color = color
    fovCircleStroke.Transparency = 0.15
    fovCircleStroke.Parent = fovCircleFrame
    return fovCircleFrame
end

local aimbotFovCircle = createFovCircle("AimbotFOV", Color3.fromRGB(255, 255, 255))
local silentAimFovCircle = createFovCircle("SilentAimFOV", Color3.fromRGB(255, 80, 80))

local function updateFovCircle(fovCircleFrame, mouseLoc, radius, visible)
    if not visible then
        fovCircleFrame.Visible = false
        return
    end
    local fovRadiusClamped = math.max(tonumber(radius) or 50, 10)
    fovCircleFrame.Size = UDim2.fromOffset(fovRadiusClamped * 2, fovRadiusClamped * 2)
    fovCircleFrame.Position = UDim2.fromOffset(mouseLoc.X, mouseLoc.Y)
    fovCircleFrame.Visible = true
end

pcall(function()
    local FighterControllerLib = require(LocalPlayer.PlayerScripts.Controllers.FighterController)
    local LocalFighter = FighterControllerLib.LocalFighter
    if LocalFighter and LocalFighter.GetMouseLocation then
        local oldGetMouseLoc = LocalFighter.GetMouseLocation
        local wrap = newcclosure or function(f) return f end
        LocalFighter.GetMouseLocation = wrap(function(...)
            if silentAimEnabled and silentAimTargetPart then
                local silentAimScreenPos = Camera:WorldToScreenPoint(silentAimTargetPart.Position)
                return Vector2.new(silentAimScreenPos.X, silentAimScreenPos.Y)
            end
            return oldGetMouseLoc(...)
        end)
    end
end)

RunService.RenderStepped:Connect(function(deltaTime)
    local localChar2 = LocalPlayer.Character
    local mouseLoc = UserInputService:GetMouseLocation()

    Camera = workspace.CurrentCamera or Camera
    updateFovCircle(aimbotFovCircle, mouseLoc, aimbotFovRadius, aimbotShowFov == true)
    updateFovCircle(silentAimFovCircle, mouseLoc, silentAimFovRadius, silentAimShowFov == true)

    
    silentAimTargetPart = nil
    if silentAimEnabled and localChar2 then
        local closestSilentAimDist = math.huge
        local camPos2 = Camera.CFrame.Position
        local camLookVec = Camera.CFrame.LookVector

        for index, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= LocalPlayer and not isSameTeam(otherPlayer) then
                local iterChar = otherPlayer.Character
                if iterChar then
                    local iterHum = iterChar:FindFirstChildOfClass("Humanoid")
                    if iterHum and iterHum.Health > 0 and not iterChar:FindFirstChildOfClass("ForceField") then
                        local iterTargetPart = selectTargetPart(iterChar, silentAimTargetPartType)
                        if iterTargetPart then
                            local silentAimScreenPos, isSilentAimVisible = Camera:WorldToViewportPoint(iterTargetPart.Position)
                            if isSilentAimVisible then
                                local silentAimScreenVec2 = Vector2.new(silentAimScreenPos.X, silentAimScreenPos.Y)
                                local silentAimDistToMouse = (silentAimScreenVec2 - mouseLoc).Magnitude
                                if silentAimDistToMouse <= silentAimFovRadius and silentAimDistToMouse < closestSilentAimDist then
                                    local silentAimVecToTarget = (iterTargetPart.Position - camPos2)
                                    if silentAimVecToTarget.Magnitude > 0 and camLookVec:Dot(silentAimVecToTarget.Unit) > 0 then
                                        if (not silentAimCheckVis) or hasLineOfSight(iterTargetPart, localChar2) then
                                            closestSilentAimDist = silentAimDistToMouse
                                            silentAimTargetPart = iterTargetPart
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    
    local shouldAimbotTarget = aimbotEnabled and localChar2 and (
        (not aimbotAutoFire) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    )
    if shouldAimbotTarget then
        local closestAimbotPart = nil
        local closestAimbotDist = aimbotFovRadius

        for index, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and not isSameTeam(player) then
                local char = player.Character
                local targetHumanoid = char:FindFirstChild("Humanoid")
                if targetHumanoid and targetHumanoid.Health > 0 then
                    local iterTargetPart = selectTargetPart(char, aimbotTargetPartType)
                    if iterTargetPart then
                        local aimbotScreenPos, isAimbotVisible = Camera:WorldToViewportPoint(iterTargetPart.Position)
                        if isAimbotVisible then
                            local aimbotDistToMouse = (Vector2.new(aimbotScreenPos.X, aimbotScreenPos.Y) - mouseLoc).Magnitude
                            if aimbotDistToMouse < closestAimbotDist then
                                if (not aimbotCheckVis) or hasLineOfSight(iterTargetPart, localChar2) then
                                    closestAimbotDist = aimbotDistToMouse
                                    closestAimbotPart = iterTargetPart
                                end
                            end
                        end
                    end
                end
            end
        end

        if closestAimbotPart then
            local finalAimbotScreenPos = Camera:WorldToViewportPoint(closestAimbotPart.Position)
            local aimbotMoveX = (finalAimbotScreenPos.X - mouseLoc.X) / math.max(aimbotSmoothing, 1)
            local aimbotMoveY = (finalAimbotScreenPos.Y - mouseLoc.Y) / math.max(aimbotSmoothing, 1)
            if mousemoverel then mousemoverel(aimbotMoveX, aimbotMoveY) end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    local localChar2 = LocalPlayer.Character
    local localTorso2 = localChar2 and localChar2:FindFirstChild("HumanoidRootPart")
    local localHum2 = localChar2 and localChar2:FindFirstChild("Humanoid")
    if not localTorso2 or (localHum2 and localHum2.Health <= 0) then return end

    if orbitEnabled then
        for index, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local orbitTargetTorso = player.Character:FindFirstChild("HumanoidRootPart")
                local orbitTargetHum = player.Character:FindFirstChild("Humanoid")
                if orbitTargetTorso and orbitTargetHum and orbitTargetHum.Health > 0 then
                    orbitTargetTorso.CFrame = localTorso2.CFrame * CFrame.new(0, 0, -3)
                    orbitTargetTorso.AssemblyLinearVelocity = Vector3.zero
                end
            end
        end
        local tool = localChar2:FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end
    end
    
    if voidSpamEnabled then return end

    if flyEnabled then
        localTorso2.CFrame = CFrame.new(localTorso2.Position.X, flyHeight, localTorso2.Position.Z)
        return
    end
end)

local espGui = Instance.new("ScreenGui")
espGui.Name = "HalmuESP"
espGui.ResetOnSpawn = false
espGui.IgnoreGuiInset = true
espGui.DisplayOrder = 40
pcall(function() espGui.Parent = game:GetService("CoreGui") end)
if not espGui.Parent then
    espGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local function getWeaponDisplayText(player)
    local equippedItemName, equippedItemAmmo = nil, nil
    pcall(function()
        local FighterController2 = FighterControllerLib
        if not FighterController2 then
            local success, _0xe99e = pcall(require, LocalPlayer.PlayerScripts.Controllers.FighterController)
            if success then FighterController2 = _0xe99e; FighterControllerLib = _0xe99e end
        end
        if not FighterController2 then return end

        local fighterInst = nil
        if type(FighterController2.GetFighter) == "function" then
            fighterInst = FighterController2:GetFighter(player)
        end
        if not fighterInst and player == LocalPlayer then
            fighterInst = FighterController2.LocalFighter
        end
        if not fighterInst then return end

        local EquippedItem = fighterInst.EquippedItem
        if not EquippedItem then
            
            local char = player.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                equippedItemName = tool.Name
            end
            return
        end

        local function readItemField(key)
            local successItem, sliderValue = pcall(function()
                if EquippedItem.Get then return EquippedItem:Get(key) end
                return EquippedItem[key] or (EquippedItem.Data and EquippedItem.Data[key]) or (EquippedItem.Info and EquippedItem.Info[key])
            end)
            if successItem then return sliderValue end
            return nil
        end

        local currentAmmo = readItemField("CurrentAmmo") or readItemField("Ammo") or readItemField("Bullets") or readItemField("MagazineAmmo")
        local reserveAmmo = readItemField("ReserveAmmo") or readItemField("StoredAmmo") or readItemField("Reserve") or readItemField("TotalAmmo")
        local isReloading = readItemField("Reloading") or readItemField("IsReloading")
        if EquippedItem.Info and type(EquippedItem.Info) == "table" then
            if currentAmmo == nil then currentAmmo = EquippedItem.Info.CurrentAmmo or EquippedItem.Info.Ammo end
            if reserveAmmo == nil then reserveAmmo = EquippedItem.Info.ReserveAmmo or EquippedItem.Info.StoredAmmo end
            if EquippedItem.Info.Reloading == true or EquippedItem.Info.IsReloading == true then
                isReloading = true
            end
        end
        local shootCooldownTime = rawget(EquippedItem, "_reload_cooldown")
        if type(shootCooldownTime) == "number" and shootCooldownTime > tick() then
            isReloading = true
        end

        local cosmeticName = EquippedItem.Name or readItemField("Name") or "weapon"
        equippedItemName = (isReloading == true) and "*Reloading*" or tostring(cosmeticName)

        if typeof(currentAmmo) == "number" and typeof(reserveAmmo) == "number" then
            equippedItemAmmo = string.format("%d/%d", math.floor(currentAmmo + 0.5), math.floor(reserveAmmo + 0.5))
        elseif typeof(currentAmmo) == "number" then
            equippedItemAmmo = tostring(math.floor(currentAmmo + 0.5))
        end
    end)

    if not equippedItemName then
        pcall(function()
            local char = player.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then equippedItemName = tool.Name end
        end)
    end

    if not equippedItemName then return nil end
    if equippedItemAmmo and equippedItemAmmo ~= "" then
        return equippedItemName .. " | " .. equippedItemAmmo
    end
    return equippedItemName
end

local espDrawingsMap = {}
local function createPlayerEsp(player)
    if espDrawingsMap[player] then return end

    local espBoxFrame = Instance.new("Frame")
    espBoxFrame.Name = "Box"
    espBoxFrame.BackgroundTransparency = 1
    espBoxFrame.BorderSizePixel = 0
    espBoxFrame.Visible = false
    espBoxFrame.Parent = espGui
    local espBoxStroke = Instance.new("UIStroke")
    espBoxStroke.Thickness = 1
    espBoxStroke.Color = Color3.fromRGB(255, 70, 70)
    espBoxStroke.Parent = espBoxFrame

    local cosmeticName = Instance.new("TextLabel")
    cosmeticName.Name = "Name"
    cosmeticName.BackgroundTransparency = 1
    cosmeticName.Font = Enum.Font.Code
    cosmeticName.TextSize = 13
    cosmeticName.TextColor3 = Color3.fromRGB(255, 255, 255)
    cosmeticName.TextStrokeTransparency = 0
    cosmeticName.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    cosmeticName.TextXAlignment = Enum.TextXAlignment.Center
    cosmeticName.Size = UDim2.new(0, 160, 0, 16)
    cosmeticName.Visible = false
    cosmeticName.Parent = espGui

    local espHealthBg = Instance.new("Frame")
    espHealthBg.Name = "HealthBg"
    espHealthBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    espHealthBg.BackgroundTransparency = 0.35
    espHealthBg.BorderSizePixel = 0
    espHealthBg.Visible = false
    espHealthBg.Parent = espGui

    local espHealthFill = Instance.new("Frame")
    espHealthFill.Name = "HealthBar"
    espHealthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    espHealthFill.BorderSizePixel = 0
    espHealthFill.Visible = false
    espHealthFill.Parent = espGui

    local weaponKey = Instance.new("TextLabel")
    weaponKey.Name = "Weapon"
    weaponKey.BackgroundTransparency = 1
    weaponKey.Font = Enum.Font.Code
    weaponKey.TextSize = 12
    weaponKey.TextColor3 = Color3.fromRGB(220, 220, 220)
    weaponKey.TextStrokeTransparency = 0
    weaponKey.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    weaponKey.TextXAlignment = Enum.TextXAlignment.Center
    weaponKey.Size = UDim2.new(0, 180, 0, 14)
    weaponKey.Visible = false
    weaponKey.Parent = espGui

    espDrawingsMap[player] = {
        Box = espBoxFrame,
        BoxStroke = espBoxStroke,
        Name = cosmeticName,
        HealthBg = espHealthBg,
        HealthBar = espHealthFill,
        Weapon = weaponKey,
    }
end

local function destroyPlayerEsp(player)
    if espDrawingsMap[player] then
        for k, d in pairs(espDrawingsMap[player]) do
            if typeof(d) == "Instance" then
                pcall(function() d:Destroy() end)
            end
        end
        espDrawingsMap[player] = nil
    end
end

for index, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then createPlayerEsp(player) end
end
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then createPlayerEsp(player) end
end)
Players.PlayerRemoving:Connect(destroyPlayerEsp)

RunService.RenderStepped:Connect(function()
    Camera = workspace.CurrentCamera or Camera
    local localTorso2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    for player, drawings in pairs(espDrawingsMap) do
        local espBoxFrame, cosmeticName, espHealthBg, espHealthFill = drawings.Box, drawings.Name, drawings.HealthBg, drawings.HealthBar
        local espBoxStroke = drawings.BoxStroke
        local char = player.Character
        local targetHead = char and char:FindFirstChild("HumanoidRootPart")
        local targetHumanoid = char and char:FindFirstChildOfClass("Humanoid")
        local espTargetRoot = char and (char:FindFirstChild("Head") or char:FindFirstChild("HitboxHead") or targetHead)

        local weaponKey = drawings.Weapon
        local function hidePlayerEsp()
            espBoxFrame.Visible = false
            cosmeticName.Visible = false
            espHealthBg.Visible = false
            espHealthFill.Visible = false
            if weaponKey then weaponKey.Visible = false end
        end

        if espEnabled and targetHead and targetHumanoid and espTargetRoot and targetHumanoid.Health > 0 then
            local espTopPos = espTargetRoot.Position + Vector3.new(0, 0.6, 0)
            local espBottomPos = targetHead.Position - Vector3.new(0, 3, 0)
            local espTopScreen, espTopVis = Camera:WorldToViewportPoint(espTopPos)
            local espBottomScreen, espBottomVis = Camera:WorldToViewportPoint(espBottomPos)
            local espRootScreen, espRootVis = Camera:WorldToViewportPoint(targetHead.Position)

            if (espRootVis or espTopVis or espBottomVis) and espRootScreen.Z > 0 then
                local espBoxHeight = math.abs(espTopScreen.Y - espBottomScreen.Y)
                if espBoxHeight < 8 then espBoxHeight = 40 end
                local espBoxWidth = espBoxHeight * 0.55
                local espBoxX = espRootScreen.X - espBoxWidth / 2
                local espBoxY = espTopScreen.Y

                if espShowBoxes then
                    espBoxFrame.Size = UDim2.fromOffset(espBoxWidth, espBoxHeight)
                    espBoxFrame.Position = UDim2.fromOffset(espBoxX, espBoxY)
                    local espBoxColor = isSameTeam(player) and Color3.fromRGB(80, 160, 255) or Color3.fromRGB(255, 70, 70)
                    if espBoxStroke then espBoxStroke.Color = espBoxColor end
                    espBoxFrame.Visible = true
                else
                    espBoxFrame.Visible = false
                end

                if espShowNames then
                    local espDistStr = ""
                    if localTorso2 then
                        espDistStr = " [" .. math.floor((targetHead.Position - localTorso2.Position).Magnitude) .. "m]"
                    end
                    cosmeticName.Text = (player.DisplayName or player.Name) .. espDistStr
                    cosmeticName.Position = UDim2.fromOffset(espRootScreen.X - 80, espBoxY - 16)
                    cosmeticName.TextColor3 = isSameTeam(player) and Color3.fromRGB(120, 180, 255) or Color3.fromRGB(255, 255, 255)
                    cosmeticName.Visible = true
                else
                    cosmeticName.Visible = false
                end

                if espShowHealth then
                    local espHealthPercent = math.clamp(targetHumanoid.Health / math.max(targetHumanoid.MaxHealth, 1), 0, 1)
                    espHealthBg.Size = UDim2.fromOffset(3, espBoxHeight)
                    espHealthBg.Position = UDim2.fromOffset(espBoxX - 6, espBoxY)
                    espHealthBg.Visible = true
                    local espHealthFillHeight = math.max(espBoxHeight * espHealthPercent, 1)
                    espHealthFill.Size = UDim2.fromOffset(3, espHealthFillHeight)
                    espHealthFill.Position = UDim2.fromOffset(espBoxX - 6, espBoxY + (espBoxHeight - espHealthFillHeight))
                    espHealthFill.BackgroundColor3 = Color3.fromHSV(espHealthPercent * 0.33, 1, 1)
                    espHealthFill.Visible = true
                else
                    espHealthBg.Visible = false
                    espHealthFill.Visible = false
                end

                if espShowWeapons and weaponKey then
                    local espWeaponText = getWeaponDisplayText(player)
                    if espWeaponText and espWeaponText ~= "" then
                        weaponKey.Text = espWeaponText
                        weaponKey.Position = UDim2.fromOffset(espRootScreen.X - 90, espBoxY + espBoxHeight + 2)
                        weaponKey.TextColor3 = isSameTeam(player) and Color3.fromRGB(140, 190, 255) or Color3.fromRGB(220, 220, 220)
                        weaponKey.Visible = true
                    else
                        weaponKey.Visible = false
                    end
                elseif weaponKey then
                    weaponKey.Visible = false
                end
            else
                hidePlayerEsp()
            end
        else
            hidePlayerEsp()
        end
    end
end)

local triggerBotFiring = false
local triggerBotNextShot = 0
local triggerBotRayParams = RaycastParams.new()
triggerBotRayParams.FilterType = Enum.RaycastFilterType.Exclude

local function isTriggerbotTarget()
    local char = LocalPlayer.Character
    if not char then return false end

    triggerBotRayParams.FilterDescendantsInstances = {char, Camera}
    local triggerBotRayHit = workspace:Raycast(Camera.CFrame.Position, Camera.CFrame.LookVector * 400, triggerBotRayParams)

    if triggerBotRayHit and triggerBotRayHit.Instance then
        local targetModel = triggerBotRayHit.Instance:FindFirstAncestorOfClass("Model")
        if targetModel and targetModel ~= char then
            local targetHumanoid = targetModel:FindFirstChildOfClass("Humanoid")
            if targetHumanoid and targetHumanoid.Health > 0 then
                local __bdUacYjXOqr = Players:GetPlayerFromCharacter(targetModel)
                if __bdUacYjXOqr and isSameTeam(__bdUacYjXOqr) then
                    return false
                end
                return true
            end
        end
    end
    return false
end

RunService.RenderStepped:Connect(function()
    if not triggerBotEnabled then
        if triggerBotFiring then
            pcall(mouse1release)
            triggerBotFiring = false
        end
        return
    end

    if mouse1click and (isrbxactive or iswindowactive) and (isrbxactive() or iswindowactive()) then
        if isTriggerbotTarget() then
            if triggerBotNextShot < tick() then
                if triggerBotFiring then
                    pcall(mouse1release)
                    triggerBotNextShot = tick() + 0.07
                else
                    pcall(mouse1press)
                end
                triggerBotFiring = not triggerBotFiring
            end
        else
            if triggerBotFiring then
                pcall(mouse1release)
                triggerBotFiring = false
            end
        end
    end
end)
local Lighting = game:GetService("Lighting")
local _785_562 = {}
local shaderBlur = Instance.new("BlurEffect")
shaderBlur.Name = "ShaderBlur"
shaderBlur.Size = 6

local shaderColor = Instance.new("ColorCorrectionEffect")
shaderColor.Name = "ShaderColor"
shaderColor.Saturation = -0.35

local function enableShader()
    _785_562 = {
        Ambient = Lighting.Ambient,
        Brightness = Lighting.Brightness,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ShadowSoftness = Lighting.ShadowSoftness,
        TimeOfDay = Lighting.TimeOfDay,
        ColorShift_Top = Lighting.ColorShift_Top,
        ColorShift_Bottom = Lighting.ColorShift_Bottom
    }

    Lighting.Ambient = Color3.fromRGB(94, 99, 188)
    Lighting.Brightness = 3.5
    Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
    Lighting.ShadowSoftness = 2.5
    Lighting.TimeOfDay = "00:30:00"
    Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
    Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)

    shaderBlur.Parent = Lighting
    shaderColor.Parent = Lighting
end

local function disableShader()
    if next(_785_562) then
        Lighting.Ambient = _785_562.Ambient
        Lighting.Brightness = _785_562.Brightness
        Lighting.OutdoorAmbient = _785_562.OutdoorAmbient
        Lighting.ShadowSoftness = _785_562.ShadowSoftness
        Lighting.TimeOfDay = _785_562.TimeOfDay
        Lighting.ColorShift_Top = _785_562.ColorShift_Top
        Lighting.ColorShift_Bottom = _785_562.ColorShift_Bottom
    end

    shaderBlur.Parent = nil
    shaderColor.Parent = nil
end

local wasFullbrightEnabled = false
RunService.Heartbeat:Connect(function()
    if fullbrightEnabled ~= wasFullbrightEnabled then
        wasFullbrightEnabled = fullbrightEnabled
        if fullbrightEnabled then
            enableShader()
        else
            disableShader()
        end
    end
end)
