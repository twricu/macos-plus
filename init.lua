---@diagnostic disable: undefined-global
hs.alert.show("Config loaded")


-- 输入法枚举
InputMethodEnum = {
  -- mac自带的，无法删除的输入法，以键盘布局存在
  english = {
    id = "com.apple.keylayout.ABC",
    name = "ABC"
  },
  pinyin = {
    id = "com.apple.inputmethod.SCIM.ITABC",
    name = "拼音"
  },
  shuangpin = {
    id = "com.apple.inputmethod.SCIM.Shuangpin",
    name = "双拼"
  },
  sougou = {
    id = "com.sogou.inputmethod.sogou.pinyin",
    name = "搜狗"
  },
}


--------------------------------------------------------------------------------
-- 功能实现
--------------------------------------------------------------------------------


-- 触发指定的键
local function sendKey(modifier, key)
  hs.eventtap.keyStroke(modifier, key, 0)
end


-- 使用系统命令复制文件
local function copyFile(source, target)
  return os.execute(string.format("/bin/cp '%s' '%s'", source, target))
end


-- 使用系统命令创建目录
local function makeDir(path)
  return os.execute(string.format("/bin/mkdir -p '%s'", path))
end


-- 使用系统命令删除文件
local function removeFile(path)
  return os.execute(string.format("/bin/rm '%s'", path))
end


-- 读取目录下的所有文件
local function readDirFiles(dir)
  local files = {}
  for file in hs.fs.dir(dir) do
    if file ~= "." and file ~= ".." then
      local path = dir .. "/" .. file
      local attr = hs.fs.attributes(path)
      if attr then
        table.insert(files, { path = path, time = attr.modification })
      end
    end
  end
  return files
end


-- 创建 F13 模态环境
F13Modal = hs.hotkey.modal.new()
-- F13 热键绑定
F13HotkeyBinding = nil
-- 将 CapsLock 映射到 F13
local function remapCapsLockToF13()
  -- 将 CapsLock (0x700000039) 重映射到 F13 (0x700000068)
  local command =
  "hidutil property --set '{\"UserKeyMapping\":[{\"HIDKeyboardModifierMappingSrc\": 0x700000039, \"HIDKeyboardModifierMappingDst\": 0x700000068}]}'"
  local success = os.execute(command)

  if success then
    hs.alert.show("CapsLock 映射为 F13")
  else
    hs.alert.show("CapsLock 映射为 F13 失败")
    return
  end

  F13HotkeyBinding = hs.hotkey.bind({}, 'f13', function()
    F13Modal:enter()
  end, function()
    F13Modal:exit()
  end)
end


-- 撤销 CapsLock 映射到 F13
local function removeCapsLockToF13()
  -- 设置空的映射数组来清除所有映射
  local command = "hidutil property --set '{\"UserKeyMapping\":[]}'"
  local success = os.execute(command)

  if success then
    hs.alert.show("撤销 CapsLock 映射为 F13")
  else
    hs.alert.show("撤销 CapsLock 映射为 F13 失败")
  end

  -- 清除 F13 热键绑定（是否必要存疑，为了逻辑完整性）
  if F13HotkeyBinding then
    F13HotkeyBinding:delete()
    F13HotkeyBinding = nil
  end

  -- 退出模态
  F13Modal:exit()
end


-- 绑定 F13 按键，支持按键重复
local function bindF13Key(key, fn, shouldRepeat)
  shouldRepeat = shouldRepeat or false
  if shouldRepeat then
    F13Modal:bind({}, key,
      -- pressedfn (按下时触发)
      function() fn() end,
      -- releasedfn (松开时触发)
      function() end,
      -- repeatfn (重复时触发)
      function() fn() end
    )
  else
    F13Modal:bind({}, key,
      -- pressedfn (按下时触发)
      function() fn() end,
      -- releasedfn (松开时触发)
      function() end,
      -- repeatfn (重复时触发)
      function() end
    )
  end
end


-- 改变窗口布局
local function changeWindowLayout(mode)
  local win = hs.window.focusedWindow()
  if win == nil then
    return
  end

  local id = win:id()
  if id == nil then
    return
  end

  if win:isFullScreen() and mode ~= "fullScreen" then
    win:setFullScreen(false)
  end

  if mode == "fullScreen" then
    win:setFullScreen(true)
  elseif mode == "maximize" then
    win:maximize()
  elseif mode == "left" then
    win:moveToUnit({ 0, 0, 0.5, 1 })
  elseif mode == "right" then
    win:moveToUnit({ 0.5, 0, 0.5, 1 })
  end
end


-- 移动窗口到下一个屏幕
local function moveWindowNextScreen()
  local allScreens = hs.screen.allScreens()

  if #allScreens == 0 then
    return
  end

  local win = hs.window.focusedWindow()
  if win == nil then
    return
  end

  win:moveToScreen(win:screen():next())
end


-- 上一个标签页
local function prevTab()
  sendKey({ "cmd", "shift" }, "[")
end


-- 下一个标签页
local function nextTab()
  sendKey({ "cmd", "shift" }, "]")
end


-- 开关音量
local function toggleAudio()
  local outputDevice = hs.audiodevice.defaultOutputDevice()
  if outputDevice == nil then
    return
  end

  local outputState = outputDevice:outputMuted()
  if outputState == nil then
    return
  end

  outputState = not outputState
  outputDevice:setOutputMuted(outputState)

  if outputState then
    hs.alert.show("静音")
  else
    local outputVolume = outputDevice:outputVolume()
    if outputVolume == nil then
      return
    end
    outputVolume = string.format("%.2f", outputVolume .. "")
    hs.alert.show("开启声音：" .. outputVolume .. "%")
  end
end


-- 上次使用的输入法id
LastInputSourceId = nil
-- 输入法切换弹窗
local function inputMethodSwitchAlert()
  hs.keycodes.inputSourceChanged(function()
    local currentSourceID = hs.keycodes.currentSourceID()
    if currentSourceID == LastInputSourceId then
      return
    end

    -- 0居中 1顶部 2底部
    if currentSourceID == InputMethodEnum.english.id then
      hs.alert.show(InputMethodEnum.english.name, { atScreenEdge = 2 }, 0.6)
    elseif currentSourceID == InputMethodEnum.pinyin.id then
      hs.alert.show(InputMethodEnum.pinyin.name, { atScreenEdge = 2 }, 0.6)
    elseif currentSourceID == InputMethodEnum.shuangpin.id then
      hs.alert.show(InputMethodEnum.shuangpin.name, { atScreenEdge = 2 }, 0.6)
    elseif currentSourceID == InputMethodEnum.sougou.id then
      hs.alert.show(InputMethodEnum.sougou.name, { atScreenEdge = 2 }, 0.6)
    else
      hs.alert.show("未知的输入法：" .. currentSourceID)
    end

    LastInputSourceId = currentSourceID
  end)
end


ClipboardTool = nil
-- 剪切板
local function toggleClipboard(hotkey)
  ClipboardTool = hs.loadSpoon("ClipboardTool")
  -- 显示最大长度
  ClipboardTool.display_max_length = 200
  -- 历史大小
  ClipboardTool.hist_size = 30
  -- 选择时粘贴
  ClipboardTool.paste_on_select = true
  -- 显示复制警报
  ClipboardTool.show_copied_alert = false
  -- 在菜单中显示
  ClipboardTool.show_in_menubar = false

  ClipboardTool:start()

  -- 触发剪贴板界面显示
  bindF13Key(hotkey, function() ClipboardTool:toggleClipboard() end)
end


-- 启动App
local function launchApp(app)
  hs.application.launchOrFocus(app)
end


SwitchInputMethodWatcher = nil
-- 聚焦app时切换指定输入法
local function focusAppSwitchInputMethod(appMapping)
  SwitchInputMethodWatcher = hs.application.watcher.new(function(name, event, app)
    if app == nil then
      return
    end

    if (event ~= hs.application.watcher.activated and event ~= hs.application.watcher.launched) then
      return
    end

    local inputMethod = appMapping[app:path()]
    if inputMethod == nil then
      return
    end

    hs.keycodes.currentSourceID(inputMethod.id)
  end)
  SwitchInputMethodWatcher:start()
end


MouseLinearReverseScrollEvent = nil
-- 反向鼠标滚动
local function mouseLinearReverseScroll()
  MouseLinearReverseScrollEvent = hs.eventtap.new({ hs.eventtap.event.types.scrollWheel }, function(event)
    -- 触控板不进行更改
    local isTrackpad = event:getProperty(hs.eventtap.event.properties.scrollWheelEventIsContinuous)
    if isTrackpad == 1 then
      return false
    end

    -- 按下 option 键则变速
    local speedModifier = 1
    local flags = event:getFlags()
    if flags:contain({ "alt" }) then
      speedModifier = 8

      local newFlags = {}
      for k, v in pairs(flags) do
        if k ~= 'alt' then
          newFlags[k] = v
        end
      end
      event:setFlags(newFlags)
    end

    -- scrollWheelEventDeltaAxis1的值应该是行，不是像素
    local delta = event:getProperty(hs.eventtap.event.properties.scrollWheelEventDeltaAxis1)
    -- 线性加变为每次滚动3行
    event:setProperty(hs.eventtap.event.properties.scrollWheelEventDeltaAxis1,
      delta > 0 and -3 * speedModifier or 3 * speedModifier)

    -- 不阻止默认的事件
    return false
  end)
  MouseLinearReverseScrollEvent:start()
end


ClickMouseSideEvent = nil
-- 点击鼠标侧键切换桌面
local function clickMouseSideButtonSwitchDesktop()
  ClickMouseSideEvent = hs.eventtap.new({ hs.eventtap.event.types.otherMouseDown }, function(event)
    local buttonNumber = event:getProperty(hs.eventtap.event.properties.mouseEventButtonNumber)

    if buttonNumber == 3 then
      sendKey({ "ctrl", "fn" }, "right")
      return true
    elseif buttonNumber == 4 then
      sendKey({ "ctrl", "fn" }, "left")
      return true
    end

    -- 不阻止默认的事件
    return false
  end)
  ClickMouseSideEvent:start()
end


-- 获取所有输入法
local function getAllInputSources()
  local sources = {}

  -- 获取所有键盘布局
  local layouts = hs.keycodes.layouts(true)
  for _, sourceID in pairs(layouts) do
    table.insert(sources, sourceID)
  end

  -- 获取所有输入法
  local methods = hs.keycodes.methods(true)
  for _, sourceID in pairs(methods) do
    table.insert(sources, sourceID)
  end

  return sources
end


-- 循环切换输入法
local function switchInputMethod()
  local sources = getAllInputSources()
  if #sources == 0 then
    return
  end

  local currentID = hs.keycodes.currentSourceID()

  -- 获取当前输入法的索引
  local currentIndex = 1
  for i, id in ipairs(sources) do
    if id == currentID then
      currentIndex = i
      break
    end
  end

  -- 获取下一个输入法的索引
  local nextIndex = currentIndex % #sources + 1
  hs.keycodes.currentSourceID(sources[nextIndex])
end


ShiftDownEvent = nil
KeyDownEvent = nil
ShiftDownFlag = false
OtherKeyDownFlag = false
-- shift按键状态纠错机制定时器
ShiftStateCorrectionTimer = nil
-- 单击shift切换输入法
local function clickShiftSwitchInputMethod()
  -- 监听修饰键更改事件
  ShiftDownEvent = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(event)
    local keyCode = event:getProperty(hs.eventtap.event.properties.keyboardEventKeycode)

    -- keyCode = 56(left shift), 60(right shift)
    if keyCode == 56 or keyCode == 60 then
      if not ShiftDownFlag then
        -- shift按下
        ShiftDownFlag = true
        OtherKeyDownFlag = false
      else
        -- shift松开
        if not OtherKeyDownFlag then
          switchInputMethod()
        end
        ShiftDownFlag = false
      end
    end

    -- 不阻止默认的事件
    return false
  end)
  ShiftDownEvent:start()

  -- 监听修饰键以外的按键按下事件
  KeyDownEvent = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    OtherKeyDownFlag = true
    -- 不阻止默认的事件
    return false
  end)
  KeyDownEvent:start()

  -- 启动纠错机制
  -- ShiftStateCorrectionTimer = hs.timer.doEvery(5, function()
  --   local currentFlags = hs.eventtap.checkKeyboardModifiers()
  --   if ShiftDownFlag and not currentFlags.shift then
  --     hs.alert.show("触发 shift 按键状态纠错机制")
  --     -- 如果内部状态显示 shift 按下，但实际上已松开，则重置状态变量
  --     ShiftDownFlag = false
  --     OtherKeyDownFlag = false
  --   end
  -- end)
end


PreventSleepState = false
PreventSleepMenuBar = nil
-- 防止系统休眠
local function createPreventSleepModule()
  return function()
    PreventSleepState = not PreventSleepState
    if PreventSleepState then
      hs.caffeinate.set("displayIdle", true, true)
      if not PreventSleepMenuBar then
        PreventSleepMenuBar = hs.menubar.new()
      end
      PreventSleepMenuBar:setTitle("⏳")
      PreventSleepMenuBar:setTooltip("防休眠已开启")
      hs.alert("防休眠已开启 ⏳")
    else
      hs.caffeinate.set("displayIdle", false, false)
      if PreventSleepMenuBar then
        PreventSleepMenuBar:delete()
        PreventSleepMenuBar = nil
      end
      hs.alert("防休眠已关闭 💤")
    end
  end
end


-- 文件同步实现
SyncFilesTimers = {}
local function syncFileToICloud(fileMapping)
  local function createSyncTask(config)
    return function()
      -- 检查源文件
      local sourceAttr = hs.fs.attributes(config.sourceFile)
      if not sourceAttr then
        print("[文件同步] 源文件不存在: " .. config.sourceFile)
        return
      end

      -- 解析路径
      local fileName = string.match(config.sourceFile, "([^/]+)$")
      local baseName = string.match(fileName, "(.+)%.")
      local ext = string.match(fileName, "%.([^%.]+)$")

      -- 创建并复制到备份目录
      local backupDir = config.targetDir .. "/" .. baseName
      makeDir(backupDir)
      local newTarget = string.format("%s/%s_%s.%s", backupDir, baseName, os.date("%y%m%d%H%M%S"), ext)

      if copyFile(config.sourceFile, newTarget) then
        print("[文件同步] 成功: " .. newTarget)
        -- 清理旧备份
        if config.maxBackupNumber then
          local files = readDirFiles(backupDir)
          table.sort(files, function(a, b) return a.time > b.time end)
          for i = config.maxBackupNumber + 1, #files do
            removeFile(files[i].path)
          end
        end
      else
        print("[文件同步] 失败: " .. config.sourceFile)
      end
    end
  end

  -- 清理旧的定时器
  for _, timer in pairs(SyncFilesTimers) do
    timer:stop()
  end
  SyncFilesTimers = {}

  -- 为每个配置创建定时器
  for _, config in ipairs(fileMapping) do
    if config.backupIntervalSeconds then
      local timer = hs.timer.doEvery(config.backupIntervalSeconds, createSyncTask(config))
      timer:start()
      table.insert(SyncFilesTimers, timer)
      -- 立即执行一次
      createSyncTask(config)()
    end
  end
end



--------------------------------------------------------------------------------
-- 开启配置
--------------------------------------------------------------------------------

-- 将 CapsLock 键映射为 F13 键
remapCapsLockToF13()

-- 防止系统休眠
bindF13Key("p", createPreventSleepModule())

-- 开关音量
bindF13Key("g", toggleAudio)

-- 快捷启动应用
bindF13Key("r", function() launchApp("Terminal") end)
bindF13Key("f", function() launchApp("Finder") end)
bindF13Key("space", function() launchApp("Launchpad") end)
toggleClipboard("v")

bindF13Key("w", function() launchApp("/Applications/WeChat.app") end)
bindF13Key("s", function() launchApp("/Applications/Visual Studio Code.app") end)
bindF13Key("d", function() launchApp("/Applications/网易有道翻译.app") end)
bindF13Key("c", function() launchApp("/Applications/Google Chrome.app") end)

-- 实现支持重复的 Vim 风格方向键
bindF13Key("h", function() sendKey({}, "left") end, true)
bindF13Key("j", function() sendKey({}, "down") end, true)
bindF13Key("k", function() sendKey({}, "up") end, true)
bindF13Key("l", function() sendKey({}, "right") end, true)

-- 切换标签页
bindF13Key("i", prevTab)
bindF13Key("o", nextTab)

-- 改变窗口布局
bindF13Key("up", function() changeWindowLayout("maximize") end)
bindF13Key("down", function() changeWindowLayout("fullScreen") end)
bindF13Key("left", function() changeWindowLayout("left") end)
bindF13Key("right", function() changeWindowLayout("right") end)

-- 移动窗口到下一个屏幕
bindF13Key("u", moveWindowNextScreen)

-- 单击shift切换输入法
clickShiftSwitchInputMethod()

-- 输入法切换弹窗
inputMethodSwitchAlert()

-- 聚焦app时切换指定输入法
focusAppSwitchInputMethod({
  ['/System/Applications/Utilities/Terminal.app'] = InputMethodEnum.english,
})

-- 鼠标线性反向滚动
mouseLinearReverseScroll()

-- 点击鼠标侧键切换桌面
clickMouseSideButtonSwitchDesktop()

-- 定时同步文件到iCloud
-- syncFileToICloud({
--   {
--     sourceFile = "/Users/qdz/Desktop/temp.txt",
--     targetDir = os.getenv("HOME") .. "/Library/Mobile Documents/com~apple~CloudDocs",
--     maxBackupNumber = 5,
--     backupIntervalSeconds = 60 * 30
--   },
-- })

-- 在Hammerspoon退出时执行相关操作
hs.shutdownCallback = function()
  -- 撤销 CapsLock 映射到 F13
  removeCapsLockToF13()
end
