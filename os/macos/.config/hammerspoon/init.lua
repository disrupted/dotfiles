local plexamp = 'tv.plex.plexamp'
local plexamp_size = { w = 235, h = 490 }

hs.window.animationDuration = 0

local function secondary_screen()
    local primary = hs.screen.primaryScreen():id()
    for _, screen in ipairs(hs.screen.allScreens()) do
        if screen:id() ~= primary then
            return screen
        end
    end
end

local function place_plexamp()
    local app = hs.application.get(plexamp)
    local win = app and app:mainWindow()
    if not win then
        return false
    end
    local secondary = secondary_screen()
    local screen = secondary or hs.screen.primaryScreen()
    local visible, full = screen:frame(), screen:fullFrame()
    win:setFrame({
        x = secondary and visible.x or visible.x + visible.w - plexamp_size.w,
        y = full.y + full.h - plexamp_size.h,
        w = plexamp_size.w,
        h = plexamp_size.h,
    })
    return true
end

local function apply_layout()
    local autohide = #hs.screen.allScreens() == 1
    hs.osascript.applescript(
        ('tell application "System Events" to set the autohide of the dock preferences to %s'):format(
            autohide
        )
    )
    place_plexamp()
end

-- global so the watchers and timers aren't garbage collected
Handles = {}

Handles.layout = hs.timer.delayed.new(0.2, apply_layout)

Handles.screens = hs.screen.watcher
    .new(function()
        Handles.layout:start()
    end)
    :start()

Handles.wake = hs.caffeinate.watcher
    .new(function(event)
        if event ~= hs.caffeinate.watcher.systemDidWake then
            return
        end
        local output = hs.audiodevice.defaultOutputDevice()
        if output then
            output:setOutputMuted(true)
        end
        Handles.layout:start()
    end)
    :start()

Handles.apps = hs.application.watcher
    .new(function(_, event, app)
        if event ~= hs.application.watcher.launched or app:bundleID() ~= plexamp then
            return
        end
        local attempts = 0
        local timer
        timer = hs.timer.doEvery(0.5, function()
            attempts = attempts + 1
            if place_plexamp() or attempts >= 20 then
                timer:stop()
            end
        end)
        Handles.plexamp_launch = timer
    end)
    :start()

hs.hotkey.bind({ 'alt', 'cmd' }, 'm', function()
    hs.application.launchOrFocusByBundleID(plexamp)
    place_plexamp()
end)
