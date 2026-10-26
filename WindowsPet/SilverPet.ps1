Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class SilverPetNative {
    [DllImport("user32.dll")] public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint modifiers, uint virtualKey);
    [DllImport("user32.dll")] public static extern bool UnregisterHotKey(IntPtr hWnd, int id);
}
"@

$ErrorActionPreference = "Stop"
$script:Root = $PSScriptRoot
$script:Frames = @{}
$script:Mode = "Idle"
$script:Animation = ""
$script:Sequence = @()
$script:SequenceIndex = 0
$script:LoopFrom = -1
$script:FrameMilliseconds = 200
$script:NextFrameAt = [DateTime]::Now
$script:Completion = "Idle"
$script:Hovering = $false
$script:ShowingShy = $false
$script:HoverStarted = [DateTime]::MinValue
$script:LastActivity = [DateTime]::Now
$script:LastScheduleKey = ""
$script:LastClick = [DateTime]::MinValue
$script:RapidClicks = 0
$script:AngerUntil = [DateTime]::MinValue
$script:Dragging = $false
$script:DragStarted = $false
$script:DragPoint = $null
$script:LastDragMotion = [DateTime]::MinValue
$script:Sitting = $false
$script:Sleeping = $false

function Import-FrameSet([string]$Name, [string]$Folder) {
    $items = [System.Collections.Generic.List[System.Windows.Media.Imaging.BitmapImage]]::new()
    foreach ($number in 1..16) {
        $path = Join-Path $script:Root ("Resources\Animations\{0}\frame_{1:00}.png" -f $Folder, $number)
        if (-not (Test-Path $path)) { throw "缺少动画资源：$path" }
        $bitmap = [System.Windows.Media.Imaging.BitmapImage]::new()
        $bitmap.BeginInit()
        $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bitmap.UriSource = [Uri]::new($path)
        $bitmap.EndInit()
        $bitmap.Freeze()
        $items.Add($bitmap)
    }
    $script:Frames[$Name] = $items
}

foreach ($name in @("Idle", "Eat", "Sleep", "Raised", "Sit", "Anger", "Question", "Shy")) {
    Import-FrameSet $name $name
}

$closedPath = Join-Path $script:Root "Resources\Frames\closed_eyes.png"
$script:ClosedEyes = [System.Windows.Media.Imaging.BitmapImage]::new()
$script:ClosedEyes.BeginInit()
$script:ClosedEyes.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
$script:ClosedEyes.UriSource = [Uri]::new($closedPath)
$script:ClosedEyes.EndInit()
$script:ClosedEyes.Freeze()

$window = [System.Windows.Window]::new()
$window.Title = "银灰发少年桌宠"
$window.Width = 330
$window.Height = 260
$window.WindowStyle = [System.Windows.WindowStyle]::None
$window.ResizeMode = [System.Windows.ResizeMode]::NoResize
$window.AllowsTransparency = $true
$window.Background = [System.Windows.Media.Brushes]::Transparent
$window.Topmost = $true
$window.ShowInTaskbar = $false
$window.SizeToContent = [System.Windows.SizeToContent]::Manual
$window.Left = [System.Windows.SystemParameters]::WorkArea.Right - 358
$window.Top = [System.Windows.SystemParameters]::WorkArea.Bottom - 288

$canvas = [System.Windows.Controls.Canvas]::new()
$canvas.Background = [System.Windows.Media.Brushes]::Transparent
$image = [System.Windows.Controls.Image]::new()
$image.Width = 260
$image.Height = 260
$image.Stretch = [System.Windows.Media.Stretch]::Uniform
[System.Windows.Controls.Canvas]::SetLeft($image, 0)
[System.Windows.Controls.Canvas]::SetTop($image, 0)
$canvas.Children.Add($image) | Out-Null

function Add-ActionButton([string]$Text, [double]$Top, [scriptblock]$Action) {
    $button = [System.Windows.Controls.Button]::new()
    $button.Content = $Text
    $button.Width = 64
    $button.Height = 34
    $button.FontSize = 11
    $button.Tag = $Action
    [System.Windows.Controls.Canvas]::SetLeft($button, 264)
    [System.Windows.Controls.Canvas]::SetTop($button, $Top)
    $button.Add_Click({ param($sender, $eventArgs) & ([scriptblock]$sender.Tag) })
    $canvas.Children.Add($button) | Out-Null
}

function Set-PetFrame([string]$Name, [int]$Number) {
    if ($script:Frames.ContainsKey($Name) -and $Number -ge 1 -and $Number -le 16) {
        $image.Source = $script:Frames[$Name][$Number - 1]
    }
}

function Start-Animation(
    [string]$Name,
    [int[]]$Order,
    [int]$Milliseconds,
    [int]$LoopFrom,
    [string]$Completion
) {
    $script:Animation = $Name
    $script:Sequence = $Order
    $script:SequenceIndex = 0
    $script:LoopFrom = $LoopFrom
    $script:FrameMilliseconds = $Milliseconds
    $script:NextFrameAt = [DateTime]::Now
    $script:Completion = $Completion
}

function Start-Idle {
    $script:Mode = "Idle"
    $script:Sitting = $false
    $script:Sleeping = $false
    Start-Animation "Idle" ([int[]](1..16)) 230 0 "Idle"
}

function Return-ToContext {
    if ($script:Hovering) { Start-Question } else { Start-Idle }
}

function Start-Question {
    if ($script:Mode -in @("Dragging", "Angry", "Sleeping", "Sitting")) { return }
    $script:Mode = "Hover"
    $script:ShowingShy = $false
    $script:HoverStarted = [DateTime]::Now
    Start-Animation "Question" ([int[]](1..12)) 170 4 "Hover"
}

function Start-Shy {
    if (-not $script:Hovering -or $script:Mode -ne "Hover") { return }
    $script:ShowingShy = $true
    Start-Animation "Shy" ([int[]](1..12)) 180 4 "Hover"
}

function End-Hover {
    if ($script:Mode -ne "Hover") { return }
    $name = if ($script:ShowingShy) { "Shy" } else { "Question" }
    $script:Mode = "Reacting"
    Start-Animation $name ([int[]](13..16)) 150 -1 "Idle"
}

function Start-Eat {
    if ($script:Mode -eq "Angry") { return }
    $script:LastActivity = [DateTime]::Now
    $script:Mode = "Reacting"
    $order = [System.Collections.Generic.List[int]]::new()
    foreach ($n in 1..4) { $order.Add($n) }
    foreach ($repeat in 1..2) { foreach ($n in 5..12) { $order.Add($n) } }
    foreach ($n in 13..16) { $order.Add($n) }
    Start-Animation "Eat" $order.ToArray() 200 -1 "Context"
}

function Start-Sleep {
    if ($script:Mode -eq "Angry") { return }
    $script:Mode = "Sleeping"
    $script:Sleeping = $true
    Start-Animation "Sleep" ([int[]](1..12)) 240 4 "Sleeping"
}

function Wake-Sleep {
    if (-not $script:Sleeping) { return }
    $script:Sleeping = $false
    $script:Mode = "Reacting"
    Start-Animation "Sleep" ([int[]](13..16)) 240 -1 "Context"
}

function Start-Sit {
    if ($script:Mode -eq "Angry") { return }
    $script:Mode = "Sitting"
    $script:Sitting = $true
    Start-Animation "Sit" ([int[]](1..5)) 210 -1 "Sitting"
}

function End-Sit {
    if (-not $script:Sitting) { return }
    $script:Sitting = $false
    $script:Mode = "Reacting"
    Start-Animation "Sit" ([int[]](13..16)) 180 -1 "Context"
}

function Start-Anger {
    $script:Mode = "Angry"
    $script:AngerUntil = [DateTime]::Now.AddSeconds(1.8)
    Start-Animation "Anger" ([int[]](1..12)) 170 4 "Angry"
}

function Begin-Raised {
    $script:Mode = "Dragging"
    $script:Dragging = $true
    Start-Animation "Raised" ([int[]](1..4)) 110 -1 "RaisedHold"
}

function Drop-Raised {
    $script:Dragging = $false
    $script:Mode = "Reacting"
    Start-Animation "Raised" ([int[]](11..16)) 130 -1 "Context"
}

function Complete-Animation {
    switch ($script:Completion) {
        "Idle" { Start-Idle }
        "Context" { Return-ToContext }
        "RaisedHold" { $script:Animation = ""; Set-PetFrame "Raised" 8 }
        default { }
    }
}

Add-ActionButton "🍙 吃饭" 183 { Start-Eat }
Add-ActionButton "💤 睡觉" 137 { if ($script:Sleeping) { Wake-Sleep } else { Start-Sleep } }
Add-ActionButton "🪑 坐下" 91 { if ($script:Sitting) { End-Sit } else { Start-Sit } }
$window.Content = $canvas

$menu = [System.Windows.Controls.ContextMenu]::new()
$hideItem = [System.Windows.Controls.MenuItem]::new()
$hideItem.Header = "隐藏桌宠（Ctrl+Alt+H）"
$hideItem.Add_Click({ $window.Hide() })
$menu.Items.Add($hideItem) | Out-Null
$quitItem = [System.Windows.Controls.MenuItem]::new()
$quitItem.Header = "退出桌宠（Ctrl+Alt+Q）"
$quitItem.Add_Click({ $window.Close() })
$menu.Items.Add($quitItem) | Out-Null
$image.ContextMenu = $menu

$image.Add_MouseEnter({
    $script:Hovering = $true
    $script:LastActivity = [DateTime]::Now
    if ($script:Sleeping) { Wake-Sleep } elseif ($script:Mode -notin @("Dragging", "Reacting", "Sitting", "Angry")) { Start-Question }
})

$image.Add_MouseLeave({
    $script:Hovering = $false
    $script:LastActivity = [DateTime]::Now
    if ($script:Mode -eq "Hover") { End-Hover }
})

$image.Add_PreviewMouseLeftButtonDown({ param($sender, $eventArgs)
    $script:LastActivity = [DateTime]::Now
    if ($script:Sleeping) { Wake-Sleep; return }
    if ($script:Sitting) { End-Sit; return }
    $script:DragStarted = $false
    $script:Dragging = $false
    $script:DragPoint = [System.Windows.Forms.Cursor]::Position
    $sender.CaptureMouse() | Out-Null
})

$image.Add_PreviewMouseMove({ param($sender, $eventArgs)
    if ($eventArgs.LeftButton -ne [System.Windows.Input.MouseButtonState]::Pressed -or $null -eq $script:DragPoint) { return }
    $current = [System.Windows.Forms.Cursor]::Position
    $dx = $current.X - $script:DragPoint.X
    $dy = $current.Y - $script:DragPoint.Y
    if (-not $script:DragStarted -and [Math]::Sqrt($dx * $dx + $dy * $dy) -gt 2) {
        $script:DragStarted = $true
        Begin-Raised
    }
    if (-not $script:DragStarted) { return }
    $window.Left += $dx
    $window.Top += $dy
    if ([Math]::Abs($dx) -gt 0) {
        if ($dx -gt 0) { Set-PetFrame "Raised" $(if ([Math]::Abs($dx) -gt 7) { 7 } else { 6 }) }
        else { Set-PetFrame "Raised" $(if ([Math]::Abs($dx) -gt 7) { 10 } else { 9 }) }
        $script:LastDragMotion = [DateTime]::Now
    }
    $script:DragPoint = $current
    $script:LastActivity = [DateTime]::Now
})

$image.Add_PreviewMouseLeftButtonUp({ param($sender, $eventArgs)
    $sender.ReleaseMouseCapture()
    $script:DragPoint = $null
    $script:LastActivity = [DateTime]::Now
    if ($script:DragStarted) {
        $script:DragStarted = $false
        Drop-Raised
        return
    }
    $now = [DateTime]::Now
    if (($now - $script:LastClick).TotalMilliseconds -lt 550) { $script:RapidClicks++ } else { $script:RapidClicks = 1 }
    $script:LastClick = $now
    if ($script:Mode -eq "Angry") {
        $script:AngerUntil = $now.AddSeconds(1.8)
    } elseif ($script:RapidClicks -ge 3) {
        Start-Anger
    }
})

$animationTimer = [System.Windows.Threading.DispatcherTimer]::new()
$animationTimer.Interval = [TimeSpan]::FromMilliseconds(40)
$animationTimer.Add_Tick({
    $now = [DateTime]::Now
    if ($script:Mode -eq "Angry" -and $now -ge $script:AngerUntil) {
        $script:RapidClicks = 0
        $script:Mode = "Reacting"
        Start-Animation "Anger" ([int[]](13..16)) 160 -1 "Context"
    }
    if ($script:Mode -eq "Hover" -and -not $script:ShowingShy -and ($now - $script:HoverStarted).TotalSeconds -ge 3.5) {
        if ((Get-Random -Minimum 0 -Maximum 100) -lt 55) { Start-Shy } else { $script:HoverStarted = $now.AddYears(10) }
    }
    if ($script:Mode -eq "Dragging" -and $script:Animation -eq "" -and ($now - $script:LastDragMotion).TotalMilliseconds -ge 120) {
        Set-PetFrame "Raised" 8
    }
    if ($script:Animation -eq "" -or $now -lt $script:NextFrameAt) { return }
    Set-PetFrame $script:Animation $script:Sequence[$script:SequenceIndex]
    $script:SequenceIndex++
    $script:NextFrameAt = $now.AddMilliseconds($script:FrameMilliseconds)
    if ($script:SequenceIndex -ge $script:Sequence.Count) {
        if ($script:LoopFrom -ge 0) { $script:SequenceIndex = $script:LoopFrom }
        else { $script:Animation = ""; Complete-Animation }
    }
})

$idleTimer = [System.Windows.Threading.DispatcherTimer]::new()
$idleTimer.Interval = [TimeSpan]::FromMilliseconds(500)
$idleTimer.Add_Tick({
    if ($script:Mode -ne "Idle") { return }
    $now = [DateTime]::Now
    $quiet = ($now - $script:LastActivity).TotalSeconds
    if ($quiet -ge 120) { Start-Sleep; return }
    if ($quiet -ge 30) {
        $script:Animation = ""
        $image.Source = $script:ClosedEyes
        return
    }
    $key = $now.ToString("yyyy-MM-dd-HH")
    if ($key -ne $script:LastScheduleKey) {
        $script:LastScheduleKey = $key
        if ($now.Hour -eq 12 -or $now.Hour -eq 18 -or ($now.Hour -ge 7 -and $now.Hour -lt 9)) { Start-Eat; return }
        if ($now.Hour -eq 13) { Start-Sit; return }
        if ($now.Hour -ge 23 -or $now.Hour -lt 7) { Start-Sleep; return }
    }
})

$window.Add_SourceInitialized({
    $helper = [System.Windows.Interop.WindowInteropHelper]::new($window)
    $script:WindowHandle = $helper.Handle
    $source = [System.Windows.Interop.HwndSource]::FromHwnd($script:WindowHandle)
    $script:HotKeyHook = [System.Windows.Interop.HwndSourceHook]{
        param($hwnd, $message, $wParam, $lParam, [ref]$handled)
        if ($message -eq 0x0312) {
            if ($wParam.ToInt32() -eq 1) { $window.Close(); $handled.Value = $true }
            elseif ($wParam.ToInt32() -eq 2) {
                if ($window.IsVisible) { $window.Hide() } else { $window.Show(); $window.Topmost = $true }
                $handled.Value = $true
            }
        }
        return [IntPtr]::Zero
    }
    $source.AddHook($script:HotKeyHook)
    [SilverPetNative]::RegisterHotKey($script:WindowHandle, 1, 0x0003, 0x51) | Out-Null
    [SilverPetNative]::RegisterHotKey($script:WindowHandle, 2, 0x0003, 0x48) | Out-Null
})

$window.Add_Closed({
    if ($script:WindowHandle) {
        [SilverPetNative]::UnregisterHotKey($script:WindowHandle, 1) | Out-Null
        [SilverPetNative]::UnregisterHotKey($script:WindowHandle, 2) | Out-Null
    }
    $animationTimer.Stop()
    $idleTimer.Stop()
})

Start-Idle
$animationTimer.Start()
$idleTimer.Start()
$window.ShowDialog() | Out-Null
