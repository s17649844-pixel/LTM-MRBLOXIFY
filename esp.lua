loadstring(game:HttpGet("https://star-scripts.com/api/run/rTyHmBnkkcD8KvZUuGj1YsTJ5N7kqUAd"))()
-- LocalScript: полёт + единое перетаскиваемое окно + темы из HamsterHub
-- Куда класть: StarterPlayer > StarterPlayerScripts
--
-- Управление:
--   E (зажать)  - лететь вверх
--   W A S D     - двигаться (во время полёта с той же скоростью)
--   Кнопка 🎨   - открыть / закрыть выбор темы
-- Скорость регулируется слайдером или вводом числа в окне.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")
local ContentProvider = game:GetService("ContentProvider")

----------------------------------------------------------------
-- НАСТРОЙКИ
----------------------------------------------------------------
local MIN_SPEED = 10
local MAX_SPEED = 200
local START_SPEED = 50
local TITLE = "Hamster & Mrbloxify LTM Hub"
local DISCORD_LABEL = "Наш Discord-сервер"
local DISCORD_LINK = "https://discord.gg/6UhNkgjhm8"

local WINDOW_WIDTH = 270
local TITLE_HEIGHT = 34
local CONTENT_HEIGHT = 192
local THEME_HEIGHT = 216

local SOUND_VOLUME = 0.5 -- общая громкость звуков интерфейса
-- Звук нажатия кнопок (взят из main.lua). Можно заменить на свой ID.
-- Если оставить пустым ("") - звук соберётся из встроенных.
local CLICK_SOUND_ID = "rbxassetid://6895079853" -- тот же звук, что в main.lua
-- Встроенные звуки Roblox. Любой можно заменить на свой: "rbxassetid://123456"
local SOUND_IDS = {
	click  = "rbxasset://sounds/button.wav",     -- нажатие кнопок
	toggle = "rbxasset://sounds/switch.wav",     -- сворачивание / панель тем
	tick   = "rbxasset://sounds/clickfast.wav",  -- ползунок скорости
	swoosh = "rbxasset://sounds/swoosh.wav",     -- появление окна
}
----------------------------------------------------------------

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("FlyPanelGui")
if old then old:Destroy() end

local speed = START_SPEED
player:SetAttribute("FlySpeed", speed)

----------------------------------------------------------------
-- СОХРАНЕНИЕ ТЕМЫ (работает только там, где есть writefile/readfile)
----------------------------------------------------------------
local SETTINGS_FILE = "FlyPanel_settings.json"
local settings = {
	theme = "dark",   -- purple / dark / light / newyear / halloween / custom
	hue = 0.555,
	sat = 1,
	sound = true,     -- звуки интерфейса вкл/выкл
}

pcall(function()
	if isfile and isfile(SETTINGS_FILE) then
		local data = HttpService:JSONDecode(readfile(SETTINGS_FILE))
		for key, value in pairs(data) do
			if settings[key] ~= nil and type(value) == type(settings[key]) then
				settings[key] = value
			end
		end
	end
end)

local function saveSettings()
	pcall(function()
		if writefile then
			writefile(SETTINGS_FILE, HttpService:JSONEncode(settings))
		end
	end)
end

----------------------------------------------------------------
-- ТЕМЫ (взяты из main.lua)
----------------------------------------------------------------
settings.hue = math.clamp(settings.hue, 0, 1)
settings.sat = math.clamp(settings.sat, 0, 1)

-- Роли цветов для своей темы: {насыщенность, яркость}. Оттенок берётся из settings.hue
local THEME_ROLES = {
	bg          = {0.118, 1.00},
	bar         = {0.220, 0.98},
	button      = {0.245, 0.96},
	hover       = {0.333, 0.94},
	active      = {0.470, 0.96},
	input       = {0.196, 1.00},
	stroke      = {0.390, 0.96},
	text        = {0.770, 0.51},
	textMain    = {0.830, 0.47},
	textInput   = {0.840, 0.37},
	textSub     = {0.610, 0.71},
	placeholder = {0.420, 0.75},
}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- Готовые темы с фиксированными цветами
local THEME_PRESETS = {
	purple = {
		bg = rgb(45, 20, 65),       bar = rgb(75, 35, 105),
		button = rgb(75, 35, 105),  hover = rgb(105, 55, 140),
		active = rgb(70, 180, 100), input = rgb(75, 35, 105),
		stroke = rgb(75, 35, 105),  text = rgb(210, 160, 255),
		textMain = rgb(200, 140, 255), textInput = rgb(240, 225, 250),
		textSub = rgb(190, 120, 255),  textSoft = rgb(205, 180, 225),
		placeholder = rgb(175, 145, 195),
	},
	dark = {
		bg = rgb(24, 24, 28),       bar = rgb(34, 34, 40),
		button = rgb(48, 48, 56),   hover = rgb(68, 68, 80),
		active = rgb(60, 110, 190), input = rgb(36, 36, 42),
		stroke = rgb(80, 80, 94),   text = rgb(230, 230, 236),
		textMain = rgb(240, 240, 246), textInput = rgb(255, 255, 255),
		textSub = rgb(160, 160, 172),  placeholder = rgb(120, 120, 134),
	},
	light = {
		bg = rgb(255, 255, 255),    bar = rgb(240, 240, 245),
		button = rgb(230, 230, 238), hover = rgb(212, 212, 224),
		active = rgb(170, 195, 235), input = rgb(246, 246, 250),
		stroke = rgb(200, 200, 212), text = rgb(40, 40, 48),
		textMain = rgb(30, 30, 38),  textInput = rgb(15, 15, 22),
		textSub = rgb(110, 110, 124), placeholder = rgb(150, 150, 164),
	},
	newyear = {
		bg = rgb(16, 52, 40),       bar = rgb(150, 28, 38),
		button = rgb(36, 96, 68),   hover = rgb(190, 44, 56),
		active = rgb(30, 140, 75),  input = rgb(12, 40, 32),
		stroke = rgb(232, 192, 72), text = rgb(255, 245, 225),
		textMain = rgb(255, 255, 255), textInput = rgb(255, 250, 235),
		textSub = rgb(242, 204, 126),  placeholder = rgb(150, 190, 170),
	},
	halloween = {
		bg = rgb(20, 14, 26),       bar = rgb(52, 24, 74),
		button = rgb(64, 34, 92),   hover = rgb(112, 52, 142),
		active = rgb(190, 80, 10),  input = rgb(32, 20, 42),
		stroke = rgb(255, 122, 22), text = rgb(255, 140, 30),
		textMain = rgb(255, 236, 205), textInput = rgb(255, 205, 125),
		textSub = rgb(184, 134, 224),  placeholder = rgb(130, 100, 152),
	},
}

if settings.theme ~= "custom" and not THEME_PRESETS[settings.theme] then
	settings.theme = "dark"
end

local themed = {}

local function getColor(role)
	local preset = settings.theme ~= "custom" and THEME_PRESETS[settings.theme]
	if preset then
		return preset[role] or preset.text
	end

	local part = THEME_ROLES[role] or THEME_ROLES.text
	return Color3.fromHSV(settings.hue, part[1] * settings.sat, part[2])
end

-- Регистрирует свойство объекта, которое меняет цвет вместе с темой
local function themeReg(object, property, role)
	themed[#themed + 1] = {object, property, role}
	object[property] = getColor(role)
end

----------------------------------------------------------------
-- ИНТЕРФЕЙС: ScreenGui, звуки, вспомогательные функции
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "FlyPanelGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- Звуки: каждый раз создаётся короткий Sound, чтобы быстрые нажатия накладывались друг на друга
local soundFolder = Instance.new("Folder")
soundFolder.Name = "UiSounds"
soundFolder.Parent = gui

local function playOne(id, pitch, volume)
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = SOUND_VOLUME * (volume or 1)
	sound.PlaybackSpeed = pitch or 1
	sound.Parent = soundFolder
	sound:Play()
	Debris:AddItem(sound, 3)
end

local function playSound(key, pitch, volume)
	if not settings.sound then return end

	-- нажатие кнопок: мягкий АСМР-звук (чуть разный тон каждый раз)
	if key == "click" then
		local vol = volume or 1
		if CLICK_SOUND_ID ~= "" then
			playOne(CLICK_SOUND_ID, 1, vol)
		else
			-- нежное касание и следом тихий шорох чуть выше тоном
			playOne(SOUND_IDS.tick, 1.15 + math.random() * 0.2, 0.4 * vol)
			task.delay(0.035, function()
				playOne(SOUND_IDS.click, 1.7 + math.random() * 0.3, 0.18 * vol)
			end)
		end
		return
	end

	local id = SOUND_IDS[key]
	if not id then return end
	playOne(id, pitch or (0.95 + math.random() * 0.1), volume)
end

-- Подгружаем звуки заранее, чтобы первое нажатие не было беззвучным
task.spawn(function()
	local preload = {}
	local ids = {}
	for _, id in pairs(SOUND_IDS) do ids[#ids + 1] = id end
	if CLICK_SOUND_ID ~= "" then ids[#ids + 1] = CLICK_SOUND_ID end
	for _, id in ipairs(ids) do
		local s = Instance.new("Sound")
		s.SoundId = id
		preload[#preload + 1] = s
	end
	pcall(function()
		ContentProvider:PreloadAsync(preload)
	end)
	for _, s in ipairs(preload) do
		s:Destroy()
	end
end)

local function addCorner(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = object
	return corner
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

-- Эффекты кнопки: подсветка при наведении, "вдавливание" и звук при нажатии
-- inset - на сколько пикселей с каждой стороны кнопка сжимается при нажатии
local HOVER_TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PRESS_TWEEN = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RELEASE_TWEEN = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function addButtonFx(button, soundKey, inset)
	button.AutoButtonColor = false
	inset = inset or Vector2.new(2, 1)

	local basePos, baseSize = button.Position, button.Size
	local anchor = button.AnchorPoint
	local pressedPos = basePos + UDim2.fromOffset(inset.X * (1 - 2 * anchor.X), inset.Y * (1 - 2 * anchor.Y))
	local pressedSize = baseSize - UDim2.fromOffset(inset.X * 2, inset.Y * 2)

	local overlay = Instance.new("Frame")
	overlay.Name = "HoverOverlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(1, 1, 1)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.Active = false
	overlay.ZIndex = button.ZIndex + 1
	overlay.Parent = button
	local corner = button:FindFirstChildOfClass("UICorner")
	if corner then
		corner:Clone().Parent = overlay
	end

	local hovered, pressed = false, false
	local sizeTween

	local function moveTo(position, size, info)
		if sizeTween then sizeTween:Cancel() end
		sizeTween = TweenService:Create(button, info, {Position = position, Size = size})
		sizeTween:Play()
	end

	local function setHover(on)
		hovered = on
		local light = settings.theme == "light"
		overlay.BackgroundColor3 = light and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
		TweenService:Create(overlay, HOVER_TWEEN, {
			BackgroundTransparency = on and (light and 0.9 or 0.85) or 1,
		}):Play()
	end

	local function release()
		if pressed then
			pressed = false
			moveTo(basePos, baseSize, RELEASE_TWEEN)
		end
	end

	button.MouseEnter:Connect(function()
		setHover(true)
	end)

	button.MouseLeave:Connect(function()
		setHover(false)
		release()
	end)

	button.MouseButton1Down:Connect(function()
		pressed = true
		moveTo(pressedPos, pressedSize, PRESS_TWEEN)
		playSound(soundKey or "click")
	end)

	button.MouseButton1Up:Connect(release)
end

----------------------------------------------------------------
-- ОКНО
----------------------------------------------------------------
local window = Instance.new("Frame")
window.Name = "Window"
window.Size = UDim2.new(0, WINDOW_WIDTH, 0, TITLE_HEIGHT + CONTENT_HEIGHT)
window.Position = UDim2.new(1, -(WINDOW_WIDTH + 24), 0, 90)
window.BackgroundTransparency = 0.05
window.BorderSizePixel = 0
window.ClipsDescendants = true
window.Parent = gui
themeReg(window, "BackgroundColor3", "bg")
addCorner(window, 12)

local windowStroke = Instance.new("UIStroke")
windowStroke.Thickness = 1.5
windowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
windowStroke.Transparency = 0.4
windowStroke.Parent = window
themeReg(windowStroke, "Color", "stroke")

----------------------------------------------------------------
-- ДЕКОР ДЛЯ НОВОГОДНЕЙ И ХЭЛЛОУИНСКОЙ ТЕМ
----------------------------------------------------------------
local decorShown, decorToken, decorItems = {}, {}, {}
local decorControls = {} -- элементы, которые становятся полупрозрачными поверх декора

local function makeDecor(name, list)
	local decor = Instance.new("Frame")
	decor.Name = name
	decor.BackgroundTransparency = 1
	decor.Size = UDim2.fromScale(1, 1)
	decor.Visible = false
	decor.Active = false
	decor.Parent = window

	local items = {}
	for i, entry in ipairs(list) do
		local label = Instance.new("TextLabel")
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromOffset(entry.size, entry.size)
		label.Position = UDim2.new(entry.x, 0, 0, entry.y)
		label.Font = Enum.Font.Gotham
		label.Text = entry.icon
		label.TextSize = entry.size
		label.TextTransparency = entry.alpha
		label.Parent = decor

		items[#items + 1] = {label = label, pos = label.Position, transparency = entry.alpha}

		-- бесконечное плавное покачивание
		TweenService:Create(label, TweenInfo.new(1.8 + i * 0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			Rotation = entry.sway,
		}):Play()
	end

	decorItems[decor] = items
	return decor
end

local xmasDecor = makeDecor("XmasDecor", {
	{icon = "🎄", x = 0.07, y = 205, size = 24, alpha = 0.30, sway = 8},
	{icon = "❄️", x = 0.93, y = 62,  size = 18, alpha = 0.35, sway = -12},
	{icon = "⭐", x = 0.90, y = 200, size = 20, alpha = 0.30, sway = 14},
	{icon = "🎁", x = 0.08, y = 100, size = 18, alpha = 0.40, sway = -6},
	{icon = "🔔", x = 0.50, y = 60,  size = 16, alpha = 0.45, sway = 10},
})

local halloweenDecor = makeDecor("HalloweenDecor", {
	{icon = "🎃", x = 0.07, y = 205, size = 24, alpha = 0.30, sway = 8},
	{icon = "🦇", x = 0.92, y = 60,  size = 20, alpha = 0.35, sway = -14},
	{icon = "👻", x = 0.90, y = 200, size = 22, alpha = 0.30, sway = 10},
	{icon = "🕸️", x = 0.08, y = 100, size = 18, alpha = 0.40, sway = -6},
	{icon = "🕷️", x = 0.50, y = 62,  size = 16, alpha = 0.45, sway = 12},
})

local refreshDecor -- задаётся ниже

-- Плавная смена темы: все цвета "перетекают" в новые
local THEME_TWEEN = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local themeTweens = {}

-- instant = true: цвета ставятся сразу (при перетаскивании ползунка оттенка)
local function applyTheme(instant)
	for index, entry in ipairs(themed) do
		local object, property, role = entry[1], entry[2], entry[3]
		local color = getColor(role)

		if themeTweens[index] then
			themeTweens[index]:Cancel()
			themeTweens[index] = nil
		end

		if instant then
			object[property] = color
		else
			local tween = TweenService:Create(object, THEME_TWEEN, {[property] = color})
			themeTweens[index] = tween
			tween:Play()
		end
	end

	refreshDecor()
end

local lastDecorated -- были ли элементы управления прозрачными (nil = ещё не задано)

-- Показывает/прячет декор: значки по очереди "всплывают" снизу и гаснут
local function setDecor(decor, shown)
	if decorShown[decor] == shown then return end

	local first = decorShown[decor] == nil
	decorShown[decor] = shown
	decorToken[decor] = (decorToken[decor] or 0) + 1
	local token = decorToken[decor]
	local items = decorItems[decor]

	if shown then
		decor.Visible = true
		for i, item in ipairs(items) do
			local label = item.label
			if first then
				label.TextTransparency = item.transparency
				label.Position = item.pos
			else
				label.TextTransparency = 1
				label.Position = item.pos + UDim2.fromOffset(0, 12)
				task.delay((i - 1) * 0.025, function()
					if decorToken[decor] ~= token then return end
					TweenService:Create(label, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
						TextTransparency = item.transparency,
						Position = item.pos,
					}):Play()
				end)
			end
		end
	elseif first then
		decor.Visible = false
	else
		for _, item in ipairs(items) do
			TweenService:Create(item.label, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 1,
			}):Play()
		end
		task.delay(0.25, function()
			if decorToken[decor] == token then
				decor.Visible = false
			end
		end)
	end
end

refreshDecor = function()
	local xmas = settings.theme == "newyear"
	local halloween = settings.theme == "halloween"
	setDecor(xmasDecor, xmas)
	setDecor(halloweenDecor, halloween)

	local decorated = xmas or halloween
	if decorated ~= lastDecorated then
		local first = lastDecorated == nil
		lastDecorated = decorated

		local target = decorated and 0.35 or 0
		for _, control in ipairs(decorControls) do
			if first then
				control.BackgroundTransparency = target
			else
				TweenService:Create(control, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundTransparency = target,
				}):Play()
			end
		end
	end
end
refreshDecor()

-- Заголовок (за него окно двигается)
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, TITLE_HEIGHT)
titleBar.BackgroundTransparency = 0.1
titleBar.BorderSizePixel = 0
titleBar.Parent = window
themeReg(titleBar, "BackgroundColor3", "bar")
addCorner(titleBar)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -86, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.Font = Enum.Font.GothamBold
title.TextSize = 12 -- чуть меньше, чтобы длинное название влезало до кнопок
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextTruncate = Enum.TextTruncate.AtEnd
title.Text = TITLE
title.Parent = titleBar
themeReg(title, "TextColor3", "textMain")

local minBtn = Instance.new("TextButton")
minBtn.AnchorPoint = Vector2.new(1, 0.5)
minBtn.Size = UDim2.new(0, 26, 0, 22)
minBtn.Position = UDim2.new(1, -8, 0.5, 0)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.Text = "–"
minBtn.Parent = titleBar
themeReg(minBtn, "BackgroundColor3", "hover")
themeReg(minBtn, "TextColor3", "textMain")
addCorner(minBtn, 6)
addButtonFx(minBtn, "click")

local themeBtn = Instance.new("TextButton")
themeBtn.AnchorPoint = Vector2.new(1, 0.5)
themeBtn.Size = UDim2.new(0, 26, 0, 22)
themeBtn.Position = UDim2.new(1, -40, 0.5, 0)
themeBtn.Font = Enum.Font.GothamBold
themeBtn.TextSize = 13
themeBtn.Text = "🎨"
themeBtn.Parent = titleBar
themeReg(themeBtn, "BackgroundColor3", "hover")
themeReg(themeBtn, "TextColor3", "textMain")
addCorner(themeBtn, 6)
addButtonFx(themeBtn, "click")

-- Содержимое
local content = Instance.new("CanvasGroup")
content.Name = "Content"
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 0, 0, TITLE_HEIGHT)
content.Size = UDim2.new(1, 0, 0, CONTENT_HEIGHT)
content.Parent = window

-- Discord (вверху)
local discordLabel = Instance.new("TextLabel")
discordLabel.BackgroundTransparency = 1
discordLabel.Position = UDim2.new(0, 14, 0, 6)
discordLabel.Size = UDim2.new(1, -28, 0, 18)
discordLabel.Font = Enum.Font.GothamBold
discordLabel.TextSize = 14
discordLabel.TextXAlignment = Enum.TextXAlignment.Left
discordLabel.Text = DISCORD_LABEL
discordLabel.Parent = content
themeReg(discordLabel, "TextColor3", "textSub")

-- Ссылка в поле: выделяется и копируется (Ctrl+C / долгое нажатие)
local linkBox = Instance.new("TextBox")
linkBox.Position = UDim2.new(0, 14, 0, 26)
linkBox.Size = UDim2.new(1, -28, 0, 26)
linkBox.Font = Enum.Font.Gotham
linkBox.TextSize = 14
linkBox.ClearTextOnFocus = false
linkBox.Text = DISCORD_LINK
linkBox.Parent = content
themeReg(linkBox, "BackgroundColor3", "input")
themeReg(linkBox, "TextColor3", "text")
addCorner(linkBox, 6)

-- Roblox не даёт скрипту игры писать в буфер обмена напрямую,
-- поэтому по клику ссылка выделяется целиком: остаётся нажать Ctrl+C
-- (на телефоне - "Копировать" во всплывающем меню).
linkBox.Focused:Connect(function()
	discordLabel.Text = "Выделено - нажми Ctrl+C"
	task.defer(function()
		linkBox.SelectionStart = 1
		linkBox.CursorPosition = #linkBox.Text + 1
	end)
end)

linkBox.FocusLost:Connect(function()
	linkBox.Text = DISCORD_LINK
	discordLabel.Text = DISCORD_LABEL
end)

linkBox.Focused:Connect(function()
	playSound("click")
end)

-- нельзя случайно испортить ссылку
linkBox:GetPropertyChangedSignal("Text"):Connect(function()
	if linkBox.Text ~= DISCORD_LINK then
		linkBox.Text = DISCORD_LINK
		task.defer(function()
			linkBox.SelectionStart = 1
			linkBox.CursorPosition = #linkBox.Text + 1
		end)
	end
end)

local divider = Instance.new("Frame")
divider.Position = UDim2.new(0, 14, 0, 60)
divider.Size = UDim2.new(1, -28, 0, 1)
divider.BorderSizePixel = 0
divider.Parent = content
themeReg(divider, "BackgroundColor3", "stroke")

-- Значение скорости
local valueBox = Instance.new("TextBox")
valueBox.Size = UDim2.new(0, 90, 0, 28)
valueBox.Position = UDim2.new(0.5, -45, 0, 68)
valueBox.Font = Enum.Font.GothamBold
valueBox.TextSize = 20
valueBox.ClearTextOnFocus = true
valueBox.Parent = content
themeReg(valueBox, "BackgroundColor3", "button")
themeReg(valueBox, "TextColor3", "textInput")
addCorner(valueBox, 6)

-- Слайдер
local track = Instance.new("Frame")
track.Size = UDim2.new(1, -50, 0, 8)
track.Position = UDim2.new(0, 25, 0, 118)
track.Parent = content
themeReg(track, "BackgroundColor3", "button")
addCorner(track, 4)

local fill = Instance.new("Frame")
fill.Size = UDim2.new(0, 0, 1, 0)
fill.Parent = track
themeReg(fill, "BackgroundColor3", "active")
addCorner(fill, 4)

local knob = Instance.new("Frame")
knob.AnchorPoint = Vector2.new(0.5, 0.5)
knob.Size = UDim2.new(0, 22, 0, 22)
knob.Position = UDim2.new(0, 0, 0.5, 0)
knob.Parent = track
themeReg(knob, "BackgroundColor3", "textInput")
addCorner(knob, 11)
knob:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0.5, 0)

local function edgeLabel(text, alignment, x)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(0, 50, 0, 16)
	l.Position = UDim2.new(0, x, 0, 130)
	l.Font = Enum.Font.Gotham
	l.TextSize = 12
	l.TextXAlignment = alignment
	l.Text = text
	l.Parent = content
	themeReg(l, "TextColor3", "textSub")
end
edgeLabel(tostring(MIN_SPEED), Enum.TextXAlignment.Left, 25)
edgeLabel(tostring(MAX_SPEED), Enum.TextXAlignment.Right, WINDOW_WIDTH - 75)

-- Кнопка подъёма (для телефона; на ПК работает клавиша E)
local flyBtn = Instance.new("TextButton")
flyBtn.Position = UDim2.new(0, 14, 0, 152)
flyBtn.Size = UDim2.new(1, -28, 0, 32)
flyBtn.Font = Enum.Font.GothamBold
flyBtn.TextSize = 14
flyBtn.AutoButtonColor = true
flyBtn.Text = "▲ Вверх (зажми E)"
flyBtn.Parent = content
themeReg(flyBtn, "BackgroundColor3", "active")
themeReg(flyBtn, "TextColor3", "textMain")
addCorner(flyBtn, 8)

decorControls[#decorControls + 1] = linkBox
decorControls[#decorControls + 1] = valueBox
decorControls[#decorControls + 1] = flyBtn
lastDecorated = nil -- применить прозрачность к только что добавленным элементам
refreshDecor()
addButtonFx(flyBtn, "click")

----------------------------------------------------------------
-- ПАНЕЛЬ ТЕМ
----------------------------------------------------------------
local themePanel = Instance.new("CanvasGroup")
themePanel.Name = "ThemePanel"
themePanel.BackgroundTransparency = 1
themePanel.Position = UDim2.new(0, 0, 0, TITLE_HEIGHT)
themePanel.Size = UDim2.new(1, 0, 0, THEME_HEIGHT)
themePanel.Visible = false
themePanel.GroupTransparency = 1
themePanel.Parent = window

local swatches = {}
local specials = {}
local hueKnob -- создаётся ниже

-- Рамка выбранной темы/цвета плавно появляется и гаснет
local STROKE_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function setStrokeOn(item, on)
	if item.on == on then return end
	item.on = on
	TweenService:Create(item.stroke, STROKE_TWEEN, {Transparency = on and 0 or 1}):Play()
end

local function refreshSwatches()
	for _, item in ipairs(swatches) do
		setStrokeOn(item, settings.theme == "custom"
			and math.abs(settings.hue - item.hue) < 0.005
			and math.abs(settings.sat - item.sat) < 0.005)
	end

	for _, item in ipairs(specials) do
		setStrokeOn(item, settings.theme == item.key)
	end
end

local function pressEffect(button)
	button.AutoButtonColor = false
end

-- Особые темы (2 колонки)
local specialList = {
	{"purple", "💜 Фиолетовая"},
	{"dark", "🌑 Чёрная"},
	{"light", "☀️ Белая"},
	{"newyear", "🎄 Новогодняя"},
	{"halloween", "🎃 Хэллоуин"},
}

for i, entry in ipairs(specialList) do
	local key, label = entry[1], entry[2]
	local column = (i - 1) % 2
	local row = math.floor((i - 1) / 2)
	local preset = THEME_PRESETS[key]

	local special = Instance.new("TextButton")
	special.Size = UDim2.fromOffset(118, 26)
	special.Position = UDim2.fromOffset(14 + column * 124, 6 + row * 30)
	special.BackgroundColor3 = preset.bar
	special.BorderSizePixel = 0
	special.Font = Enum.Font.GothamBold
	special.Text = label
	special.TextColor3 = key == "light" and preset.text or preset.textMain
	special.TextSize = 11
	special.Parent = themePanel
	pressEffect(special)
	addCorner(special, 10)
	addButtonFx(special, "click", Vector2.new(3, 1))

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Transparency = 1
	stroke.Parent = special
	themeReg(stroke, "Color", "text")

	specials[#specials + 1] = {key = key, stroke = stroke, on = false}

	special.MouseButton1Click:Connect(function()
		settings.theme = key
		applyTheme(false)
		refreshSwatches()
		saveSettings()
	end)
end

-- Кнопка звуков: занимает свободное место справа от последней темы
local soundBtn = Instance.new("TextButton")
soundBtn.Size = UDim2.fromOffset(118, 26)
soundBtn.Position = UDim2.fromOffset(14 + 124, 6 + 2 * 30)
soundBtn.BorderSizePixel = 0
soundBtn.Font = Enum.Font.GothamBold
soundBtn.TextSize = 11
soundBtn.AutoButtonColor = false
soundBtn.Parent = themePanel
themeReg(soundBtn, "BackgroundColor3", "button")
themeReg(soundBtn, "TextColor3", "textMain")
addCorner(soundBtn, 10)
addButtonFx(soundBtn, "click", Vector2.new(3, 1))

local function refreshSoundBtn()
	soundBtn.Text = settings.sound and "🔊 Звуки: вкл" or "🔇 Звуки: выкл"
end
refreshSoundBtn()

soundBtn.MouseButton1Click:Connect(function()
	settings.sound = not settings.sound
	refreshSoundBtn()
	saveSettings()
	playSound("toggle")
end)

local colorsLabel = Instance.new("TextLabel")
colorsLabel.Size = UDim2.new(1, -24, 0, 14)
colorsLabel.Position = UDim2.fromOffset(12, 98)
colorsLabel.BackgroundTransparency = 1
colorsLabel.Font = Enum.Font.GothamBold
colorsLabel.Text = "Цвета"
colorsLabel.TextSize = 10
colorsLabel.TextXAlignment = Enum.TextXAlignment.Left
colorsLabel.Parent = themePanel
themeReg(colorsLabel, "TextColor3", "textSub")

-- Готовые цвета {оттенок, насыщенность}
local colorPresets = {
	{0.78, 1},  {0.555, 1}, {0.49, 1}, {0.40, 1},
	{0.30, 1},  {0.20, 1},  {0.14, 1}, {0.07, 1},
	{0.00, 1},  {0.96, 1},  {0.91, 1}, {0.86, 1},
	{0.72, 1},  {0.65, 1},  {0.60, 1}, {0.00, 0},
}

local hueBar -- создаётся ниже, нужен swatch-кнопкам

for i, preset in ipairs(colorPresets) do
	local column = (i - 1) % 8
	local row = math.floor((i - 1) / 8)

	local swatch = Instance.new("TextButton")
	swatch.Size = UDim2.fromOffset(26, 22)
	swatch.Position = UDim2.fromOffset(14 + column * 31, 114 + row * 28)
	swatch.BackgroundColor3 = Color3.fromHSV(preset[1], preset[2] * 0.6, 0.85)
	swatch.BorderSizePixel = 0
	swatch.Text = ""
	swatch.Parent = themePanel
	pressEffect(swatch)
	addCorner(swatch, 8)
	addButtonFx(swatch, "click", Vector2.new(2, 2))

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Transparency = 1
	stroke.Parent = swatch
	themeReg(stroke, "Color", "text")

	swatches[#swatches + 1] = {hue = preset[1], sat = preset[2], stroke = stroke, on = false}

	swatch.MouseButton1Click:Connect(function()
		settings.theme = "custom"
		settings.hue = preset[1]
		settings.sat = preset[2]
		if hueKnob then
			hueKnob.Position = UDim2.new(settings.hue, 0, 0.5, 0)
		end

		applyTheme(false)
		refreshSwatches()
		saveSettings()
	end)
end

-- Ползунок оттенка (радуга)
local hueLabel = Instance.new("TextLabel")
hueLabel.Size = UDim2.new(1, -24, 0, 14)
hueLabel.Position = UDim2.fromOffset(12, 170)
hueLabel.BackgroundTransparency = 1
hueLabel.Font = Enum.Font.GothamBold
hueLabel.Text = "Свой оттенок"
hueLabel.TextSize = 10
hueLabel.TextXAlignment = Enum.TextXAlignment.Left
hueLabel.Parent = themePanel
themeReg(hueLabel, "TextColor3", "textSub")

hueBar = Instance.new("Frame")
hueBar.Size = UDim2.new(1, -28, 0, 14)
hueBar.Position = UDim2.fromOffset(14, 190)
hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
hueBar.BorderSizePixel = 0
hueBar.Parent = themePanel
addCorner(hueBar, 7)

local keypoints = {}
for i = 0, 6 do
	keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.6, 0.95))
end

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new(keypoints)
gradient.Parent = hueBar

hueKnob = Instance.new("Frame")
hueKnob.Size = UDim2.fromOffset(8, 20)
hueKnob.AnchorPoint = Vector2.new(0.5, 0.5)
hueKnob.Position = UDim2.new(settings.hue, 0, 0.5, 0)
hueKnob.BackgroundColor3 = Color3.new(1, 1, 1)
hueKnob.BorderSizePixel = 0
hueKnob.ZIndex = 2
hueKnob.Parent = hueBar
addCorner(hueKnob, 4)

local hueKnobStroke = Instance.new("UIStroke")
hueKnobStroke.Thickness = 1.5
hueKnobStroke.Parent = hueKnob
themeReg(hueKnobStroke, "Color", "text")

refreshSwatches()

----------------------------------------------------------------
-- СКОРОСТЬ
----------------------------------------------------------------
local SLIDER_TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local fillTween, knobTween

-- animate = true: ползунок плавно "доезжает" (клик по полосе, ввод числа);
-- при перетаскивании значение ставится сразу, чтобы не отставать от пальца
local function setSpeed(value, animate)
	speed = math.clamp(math.floor(value + 0.5), MIN_SPEED, MAX_SPEED)
	local t = (speed - MIN_SPEED) / (MAX_SPEED - MIN_SPEED)

	if fillTween then fillTween:Cancel() end
	if knobTween then knobTween:Cancel() end

	if animate then
		fillTween = TweenService:Create(fill, SLIDER_TWEEN, {Size = UDim2.new(t, 0, 1, 0)})
		knobTween = TweenService:Create(knob, SLIDER_TWEEN, {Position = UDim2.new(t, 0, 0.5, 0)})
		fillTween:Play()
		knobTween:Play()
	else
		fill.Size = UDim2.new(t, 0, 1, 0)
		knob.Position = UDim2.new(t, 0, 0.5, 0)
	end

	valueBox.Text = tostring(speed)
	player:SetAttribute("FlySpeed", speed)
end

local lastTick = 0

local function setFromX(x, animate)
	local t = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
	local before = speed
	setSpeed(MIN_SPEED + t * (MAX_SPEED - MIN_SPEED), animate)

	-- тихий "тик", тон растёт вместе со скоростью
	if speed ~= before and os.clock() - lastTick > 0.05 then
		lastTick = os.clock()
		playSound("tick", 0.8 + t * 0.7, 0.6)
	end
end

valueBox.Focused:Connect(function()
	playSound("click")
end)

valueBox.FocusLost:Connect(function()
	setSpeed(tonumber(valueBox.Text) or speed, true)
end)

----------------------------------------------------------------
-- ВВОД ОКНА: слайдеры + перетаскивание
----------------------------------------------------------------
local draggingSlider = false
local draggingHue = false
local draggingWindow = false
local dragStartPos = Vector2.zero
local windowStartPos = Vector2.zero
local introTween -- анимация появления окна (создаётся в конце скрипта)

-- Ползунки слегка увеличиваются, пока их держат
local GRAB_TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function setKnobGrab(grabbed)
	local size = grabbed and 28 or 22
	TweenService:Create(knob, GRAB_TWEEN, {Size = UDim2.fromOffset(size, size)}):Play()
end

local function setHueGrab(grabbed)
	TweenService:Create(hueKnob, GRAB_TWEEN, {
		Size = grabbed and UDim2.fromOffset(11, 26) or UDim2.fromOffset(8, 20),
	}):Play()
end

local function setHueFromX(x)
	local width = hueBar.AbsoluteSize.X
	if width <= 0 then return end

	local value = math.clamp((x - hueBar.AbsolutePosition.X) / width, 0, 1)
	settings.theme = "custom"
	settings.hue = value
	settings.sat = 1
	hueKnob.Position = UDim2.new(value, 0, 0.5, 0)

	applyTheme(true)
	refreshSwatches()
end

track.InputBegan:Connect(function(input)
	if isPress(input) then
		draggingSlider = true
		setKnobGrab(true)
		setFromX(input.Position.X, true)
	end
end)

knob.InputBegan:Connect(function(input)
	if isPress(input) then
		draggingSlider = true
		setKnobGrab(true)
	end
end)

hueBar.InputBegan:Connect(function(input)
	if isPress(input) then
		draggingHue = true
		setHueGrab(true)
		playSound("click")
		setHueFromX(input.Position.X)
	end
end)

titleBar.InputBegan:Connect(function(input)
	if isPress(input) then
		if introTween then introTween:Cancel() end
		draggingWindow = true
		dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
		windowStartPos = window.AbsolutePosition
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not isMove(input) then return end

	if draggingSlider then
		setFromX(input.Position.X)
	elseif draggingHue then
		setHueFromX(input.Position.X)
	elseif draggingWindow then
		local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStartPos
		local target = windowStartPos + delta
		local screen = gui.AbsoluteSize
		local size = window.AbsoluteSize
		window.Position = UDim2.fromOffset(
			math.clamp(target.X, 0, math.max(0, screen.X - size.X)),
			math.clamp(target.Y, 0, math.max(0, screen.Y - size.Y))
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if isPress(input) then
		if draggingHue then
			saveSettings()
			setHueGrab(false)
		end
		if draggingSlider then
			setKnobGrab(false)
		end
		draggingSlider = false
		draggingHue = false
		draggingWindow = false
	end
end)

----------------------------------------------------------------
-- СВОРАЧИВАНИЕ / ПЕРЕКЛЮЧЕНИЕ ТЕМ
----------------------------------------------------------------
local minimized = false
local themeOpen = false

local windowTween
local panelTokens = {}
local PANEL_POSITION = UDim2.new(0, 0, 0, TITLE_HEIGHT)

-- Панель плавно проявляется (с лёгким сдвигом вверх) или растворяется
local function setPanelShown(panel, shown)
	panelTokens[panel] = (panelTokens[panel] or 0) + 1
	local token = panelTokens[panel]

	if shown then
		if not panel.Visible then
			panel.Position = PANEL_POSITION + UDim2.fromOffset(0, 10)
		end
		panel.Visible = true
		TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			GroupTransparency = 0,
			Position = PANEL_POSITION,
		}):Play()
	elseif panel.Visible then
		local tween = TweenService:Create(panel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			GroupTransparency = 1,
		})
		tween.Completed:Connect(function()
			if panelTokens[panel] == token then
				panel.Visible = false
			end
		end)
		tween:Play()
	end
end

local function updateWindow()
	setPanelShown(content, not minimized and not themeOpen)
	setPanelShown(themePanel, not minimized and themeOpen)

	local bodyHeight = themeOpen and THEME_HEIGHT or CONTENT_HEIGHT
	local height = minimized and TITLE_HEIGHT or (TITLE_HEIGHT + bodyHeight)

	if windowTween then windowTween:Cancel() end
	windowTween = TweenService:Create(window, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, WINDOW_WIDTH, 0, height),
	})
	windowTween:Play()

	minBtn.Text = minimized and "+" or "–"
end

minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	updateWindow()
end)

themeBtn.MouseButton1Click:Connect(function()
	themeOpen = not themeOpen
	minimized = false
	updateWindow()
end)

----------------------------------------------------------------
-- ПОЛЁТ
----------------------------------------------------------------
local upHeld = false      -- клавиша E
local buttonHeld = false  -- экранная кнопка

local attachment, linearVelocity

local function setupCharacter(character)
	local root = character:WaitForChild("HumanoidRootPart")

	attachment = Instance.new("Attachment")
	attachment.Name = "FlyAttachment"
	attachment.Parent = root

	linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "FlyVelocity"
	linearVelocity.Attachment0 = attachment
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	linearVelocity.MaxForce = math.huge
	linearVelocity.VectorVelocity = Vector3.zero
	linearVelocity.Enabled = false
	linearVelocity.Parent = root
end

if player.Character then
	task.spawn(setupCharacter, player.Character)
end
player.CharacterAdded:Connect(setupCharacter)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.E then
		upHeld = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.E then
		upHeld = false
	end
end)

flyBtn.InputBegan:Connect(function(input)
	if isPress(input) then buttonHeld = true end
end)
flyBtn.InputEnded:Connect(function(input)
	if isPress(input) then buttonHeld = false end
end)

RunService.Heartbeat:Connect(function()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (humanoid and linearVelocity and linearVelocity.Parent) then return end

	if not (upHeld or buttonHeld) then
		linearVelocity.Enabled = false
		return
	end

	local flySpeed = player:GetAttribute("FlySpeed") or speed
	local move = humanoid.MoveDirection * flySpeed
	linearVelocity.VectorVelocity = Vector3.new(move.X, flySpeed, move.Z)
	linearVelocity.Enabled = true
end)

setSpeed(speed)

-- Появление окна: выезжает справа с лёгким "отскоком"
do
	local finalPosition = window.Position
	window.Position = finalPosition + UDim2.fromOffset(WINDOW_WIDTH + 40, 0)
	introTween = TweenService:Create(window, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = finalPosition,
	})
	introTween:Play()
	playSound("swoosh", 1.25, 0.35)
end
