local Slab = require 'Slab'
local nativefs = require 'nativefs'

function love.load(args)
    Slab.SetINIStatePath(nil)
    Grid = love.graphics.newImage("grid.png")
    Grid:setWrap('repeat', 'repeat')
    Grid:setFilter('linear', 'nearest')
    
    ImageList = {}
    CurrentImageIndex = 0
    ImagePos = {X = 0, Y = 0}
    ImageScale = 1
    OpenFile = false
    CurrentFileName = ""
    CurrentlySaving = false
    SaveMessageIsDisplayed = 0
    DoneSaving = false
    ShowOriginal = false
    DitherParameters = {Strength = 1.0, Brightness = 0.0, Contrast = 0.0}
    ParameterChanged = false
    SliderUpdateTimer = 0.0
    ChannelUpdateTimer = 0.0
    ToolbarElementWidth = 150
    PreviewWindowWidth = 0
    ImageData = love.image.newImageData(1, 1)
    ImageDataSize = {Width = 0, Height = 0}

    SplitChannelEnabled = false
    ColorChannels = {Red = 0.30, Green = 0.59, Blue = 0.11}
    ChannelChanged = false

    CurrentScale = 1

    SelectedDitherType = 'Bayer Matrix'
    DitherTypes = {'Bayer Matrix', 'Ordered Dithering Matrix', 'Error Diffusion Matrix', 'Random'}

    SelectedBayerType = '8x8'
    SelectedBayerType1 = '8'
    SelectedBayerType2 = '8'
    BayerTypes = {'2x2', '3x3', '3x5', '5x3', '4x4', '8x8', '16x16', '32x32', '64x64'}
    CustomBayerTypes = {'2', '4', '8', '16', '32', '64'}
    UseCustomBayerType = false

    SelectedOrderedType = 'ClusteredDot4x4'
    OrderedTypes = {
        'Vertical5x3',
        'Horizontal3x5',
        'ClusteredDotVerticalLine',
        'ClusteredDotHorizontalLine',
        'ClusteredDot4x4',
        'ClusteredDotSpiral5x5',
        'ClusteredDot6x6',
        'ClusteredDot6x6-2',
        'ClusteredDot6x6-3',
        'ClusteredDotDiagonal6x6',
        'ClusteredDot8x8',
        'ClusteredDotDiagonal8x8',
        'ClusteredDotDiagonal8x8-2',
        'ClusteredDotDiagonal8x8-3',
        'ClusteredDotDiagonal16x16'
    }

    SelectedErrorType = 'FloydSteinberg'
    ErrorTypes = {
        'Simple2D',
        'FloydSteinberg',
        'FalseFloydSteinberg',
        'JarvisJudiceNinke',
        'Atkinson',
        'Stucki',
        'Burkes',
        'Sierra',
        'TwoRowSierra',
        'SierraLite',
        'StevenPigeon'
    }
    Serpentine = false

    RandomMin = -0.5
    RandomMax = 0.5

    love.window.setMode(1280, 720, {resizable = true})
    --love.window.maximize()
    ResizeWindows()
    --LoadImage()

    Slab.SetScrollSpeed(30)
    Slab.SetINIStatePath(nil)
    Slab.Initialize(args)
end

--__________________________START UPDATE_____________________________
-- The update function draws the entire UI
function love.update(dt)
    Slab.Update(dt)

    if ChannelChanged and ChannelUpdateTimer ~= 0.0 then
        if love.timer.getTime() - ChannelUpdateTimer >= 0.1 then
            ChannelChanged = false
            ChannelUpdateTimer = 0.0
            SplitChannel()
        end
    end

    if ParameterChanged and SliderUpdateTimer ~= 0.0 then
        if love.timer.getTime() - SliderUpdateTimer >= 0.1 then
            ParameterChanged = false
            SliderUpdateTimer = 0.0
            DitherImage()
        end
    end

    -- This if statement handles the file browser, which allows opening a single image or multiple images using shift or control
    if OpenFile then
        local Result = Slab.FileDialog({Type = 'openfile', AllowMultiSelect = true})
    
        if Result.Button == "OK" then
            if #(Result.Files) ~= 0 then
                ImageList = {}
                for i = 1, #(Result.Files) do
                    local fileName = Result.Files[i]
                    if Result.Files[i] and (string.lower(string.sub(fileName, #fileName - 3, #fileName)) == '.png' or string.lower(string.sub(fileName, #fileName - 3, #fileName)) == '.jpg' or string.lower(string.sub(fileName, #fileName - 4, #fileName)) == '.jpeg') then
                        print('Loaded ' .. fileName)
                        ImageList[#ImageList + 1] = fileName
                    end
                end
                if ImageList[1] then
                    OpenImageFile(ImageList[1])
                    CurrentImageIndex = 1
                end
            end
        end

        if Result.Button ~= "" then
            OpenFile = false
        end
    end

    if CurrentlySaving and SaveMessageIsDisplayed > 5 and not DoneSaving then
        SaveAllImages()
        DoneSaving = true
    end
    
    if CurrentlySaving then
        local saveMessage = "Saving..."
        if DoneSaving == true then
            saveMessage = "Saving... Done!"
        end
        local Result = Slab.MessageBox("Saving", saveMessage)
    
        SaveMessageIsDisplayed = SaveMessageIsDisplayed + 1
        
        if Result ~= "" then
            CurrentlySaving = false
            DoneSaving = false
            SaveMessageIsDisplayed = 0
        end
    end

    Slab.BeginWindow('PreviewWindow', WindowOptions)

    local mousePosX, _ = Slab.GetMousePosition()
    PreviewWindowWidth, _ = Slab.GetWindowSize()
    if mousePosX < PreviewWindowWidth and Slab.IsMouseDragging(1) then 
        local deltaX, deltaY = Slab.GetMouseDelta()
        ImagePos.X = math.floor(ImagePos.X + deltaX)
        ImagePos.Y = math.floor(ImagePos.Y + deltaY)
    end
    if not PreviewImage then 
        Slab.BeginLayout('OpenFileLayout', {AlignX = 'center', AlignY = 'center'})
        if Slab.Button('Open Image(s)...') then
            OpenFile = true
        end
        Slab.Text('or')
        Slab.Text('Drag image or folder into window')
        Slab.EndLayout()
    end
    Slab.SetCursorPos(ImagePos.X, ImagePos.Y)
    if PreviewImage then Slab.Image('PreviewImage', {Image = PreviewImage, Scale = ImageScale}) end
    Slab.EndWindow()

    Slab.BeginWindow('Toolbar', ToolbarOptions)
    Slab.BeginLayout('ToolbarLayout1', {AlignX = 'center'})

    Slab.Separator({H = 20})
    if Slab.Button('Open Image(s)...', {W = ToolbarElementWidth, H = 50}) then
        OpenFile = true
    end

    Slab.Text("Image " .. CurrentImageIndex .. " of " .. #ImageList)
    if ImageList[CurrentImageIndex] then
        Slab.Text(CurrentFileName)
    end

    if PreviewImage then
        Slab.Text("Size: (" .. math.floor(ImageDataSize.Width * CurrentScale) .. "x" ..  math.floor(ImageDataSize.Height * CurrentScale) .. ")")
        if Slab.Input('CurrentScale', {W = ToolbarElementWidth, Text = CurrentScale, NumbersOnly = true, MinNumber = 0.01, MaxNumber = 1.0, Precision = 2, UseSlider = true}) then 
            CurrentScale = Slab.GetInputNumber()
            ParameterChanged = true
        end
    end

    Slab.Separator({H = 20})

    if Slab.CheckBox(SplitChannelEnabled, "Split Channels") then
        SplitChannelEnabled = not SplitChannelEnabled
        if SplitChannelEnabled and PreviewImage then
            SplitChannel()
        elseif PreviewImage then
            DitherImage()
        end
    end

    if SplitChannelEnabled then
        if Slab.Input('RedChannel', {W = ToolbarElementWidth, Text = ColorChannels.Red, NumbersOnly = true, MinNumber = 0.0, MaxNumber = 1.0, Precision = 2, UseSlider = true, BgColor = {1.0, 0.0, 0.0}}) then 
            ColorChannels.Red = Slab.GetInputNumber()
            ChannelChanged = true
        end
        if Slab.Input('GreenChannel', {W = ToolbarElementWidth, Text = ColorChannels.Green, NumbersOnly = true, MinNumber = 0.0, MaxNumber = 1.0, Precision = 2, UseSlider = true, BgColor = {0.0, 1.0, 0.0}}) then 
            ColorChannels.Green = Slab.GetInputNumber()
            ChannelChanged = true
        end
        if Slab.Input('BlueChannel', {W = ToolbarElementWidth, Text = ColorChannels.Blue, NumbersOnly = true, MinNumber = 0.0, MaxNumber = 1.0, Precision = 2, UseSlider = true, BgColor = {0.0, 0.0, 1.0}}) then 
            ColorChannels.Blue = Slab.GetInputNumber()
            ChannelChanged = true
        end
        if Slab.Button('Reset') then
            ColorChannels.Red = 0.30
            ColorChannels.Green = 0.59
            ColorChannels.Blue = 0.11
            SplitChannel()
        end
    end

    Slab.Separator({H = 20})

    if Slab.Button('Strength') then
        DitherParameters.Strength = 1.0
        DitherImage()
    end
    if Slab.Input('Strength', {W = ToolbarElementWidth, Text = DitherParameters.Strength, NumbersOnly = true, MinNumber = -1.0, MaxNumber = 1.0, Precision = 2, UseSlider = true}) then 
        DitherParameters.Strength = Slab.GetInputNumber()
        ParameterChanged = true
    end

    if Slab.Button('Brightness') then
        DitherParameters.Brightness = 0.0
        DitherImage()
    end
    if Slab.Input('Brightness', {W = ToolbarElementWidth, Text = DitherParameters.Brightness, NumbersOnly = true, MinNumber = -1.0, MaxNumber = 1.0, Precision = 2, UseSlider = true}) then 
        DitherParameters.Brightness = Slab.GetInputNumber()
        ParameterChanged = true
    end

    if Slab.Button('Contrast') then
        DitherParameters.Contrast = 0.0
        DitherImage()
    end
    if Slab.Input('Contrast', {W = ToolbarElementWidth, Text = DitherParameters.Contrast, NumbersOnly = true, MinNumber = -1.0, MaxNumber = 1.0, Precision = 2, UseSlider = true}) then 
        DitherParameters.Contrast = Slab.GetInputNumber()
        ParameterChanged = true
    end

    Slab.Separator({H = 20})

    Slab.Text('Dither Type')
    if Slab.BeginComboBox('DitherTypeComboBox', {Selected = SelectedDitherType, W = ToolbarElementWidth}) then
        for I, V in ipairs(DitherTypes) do
            if Slab.TextSelectable(V) then
                SelectedDitherType = V
                DitherImage()
            end
        end
        Slab.EndComboBox()
    end

    Slab.Separator({H = 20})

    if SelectedDitherType == 'Bayer Matrix' then
        Slab.Text('Bayer Dimensions')

        if Slab.CheckBox(UseCustomBayerType, "Custom Bayer Size") then
            UseCustomBayerType = not UseCustomBayerType
            DitherImage()
        end

        Slab.Separator({H = 20})
        
        if UseCustomBayerType then
            Slab.BeginLayout('BayerComboLayout', {AlignX = 'center', Columns = 5})
            Slab.SetLayoutColumn(1)
            Slab.Text(' ')
            Slab.SetLayoutColumn(2)
            if Slab.BeginComboBox('BayerType1ComboBox', {Selected = SelectedBayerType1}) then
                for I, V in ipairs(CustomBayerTypes) do
                    if Slab.TextSelectable(V) then
                        SelectedBayerType1 = V
                        DitherImage()
                    end
                end
                Slab.EndComboBox()
            end
            Slab.SetLayoutColumn(3)
            Slab.Text('x')
            Slab.SetLayoutColumn(4)
            if Slab.BeginComboBox('BayerType2ComboBox', {Selected = SelectedBayerType2}) then
                for I, V in ipairs(CustomBayerTypes) do
                    if Slab.TextSelectable(V) then
                        SelectedBayerType2 = V
                        DitherImage()
                    end
                end
                Slab.EndComboBox()
            end
            Slab.EndLayout()
        else
            if Slab.BeginComboBox('BayerTypeComboBox', {Selected = SelectedBayerType}) then
                for I, V in ipairs(BayerTypes) do
                    if Slab.TextSelectable(V) then
                        SelectedBayerType = V
                        DitherImage()
                    end
                end
                Slab.EndComboBox()
            end
        end
    end

    if SelectedDitherType == 'Random' then
        if Slab.Button('Random Noise Range') then
            RandomMin = -0.5
            RandomMax = 0.5
            DitherImage()
        end
        if Slab.Input('Random Min', {W = ToolbarElementWidth, Text = RandomMin, NumbersOnly = true, MinNumber = -2.0, MaxNumber = 2.0, Precision = 2, UseSlider = true}) then 
            RandomMin = Slab.GetInputNumber()
            if RandomMin > RandomMax then RandomMin = RandomMax end
            ParameterChanged = true
        end

        if Slab.Input('Random Max', {W = ToolbarElementWidth, Text = RandomMax, NumbersOnly = true, MinNumber = -2.0, MaxNumber = 2.0, Precision = 2, UseSlider = true}) then 
            RandomMax = Slab.GetInputNumber()
            if RandomMax < RandomMin then RandomMax = RandomMin end
            ParameterChanged = true
        end
    end

    if SelectedDitherType == 'Ordered Dithering Matrix' then
        Slab.Text('Ordered Dithering Matrix')
        if Slab.BeginComboBox('OrderedTypeComboBox', {Selected = SelectedOrderedType, W = ToolbarElementWidth}) then
            for I, V in ipairs(OrderedTypes) do
                if Slab.TextSelectable(V) then
                    SelectedOrderedType = V
                    DitherImage()
                end
            end
            Slab.EndComboBox()
        end
    end

    if SelectedDitherType == 'Error Diffusion Matrix' then
        Slab.Text('Error Diffusion Matrix')

        if Slab.CheckBox(Serpentine, "Use Serpentine") then
            Serpentine = not Serpentine
            DitherImage()
        end

        Slab.Separator({H = 20})

        if Slab.BeginComboBox('ErrorTypeComboBox', {Selected = SelectedErrorType, W = ToolbarElementWidth}) then
            for I, V in ipairs(ErrorTypes) do
                if Slab.TextSelectable(V) then
                    SelectedErrorType = V
                    DitherImage()
                end
            end
            Slab.EndComboBox()
        end
    end

    Slab.EndLayout()

    Slab.Separator({H = 20})

    Slab.BeginLayout('ToolbarLayout3', {AlignX = 'center', AlignY = 'bottom'})

    if Slab.CheckBox(ShowOriginal, "Show Original") then
        ShowOriginal = not ShowOriginal
        if PreviewImage then ReloadImage() end
    end

    Slab.Separator({H = 20})

    if Slab.Button('Save All To Output Folder', {W = ToolbarElementWidth, H = 50}) and PreviewImage then
        CurrentlySaving = true
    end
    Slab.Separator({H = 20})
    Slab.EndLayout()
    Slab.EndWindow()
end

--__________________________END UPDATE_____________________________

-- Draw the current image to the window
function love.draw()
    local quad = love.graphics.newQuad(0, 0, love.graphics.getWidth(), love.graphics.getHeight(), 64 * ImageScale, 64 * ImageScale)
    love.graphics.draw(Grid, quad)
    Slab.Draw()
end

-- If the window is resized, recalculate toolbars
function love.resize()
    ResizeWindows()
end

-- Switches current image when left and right arrow keys are pressed
function love.keypressed(key, scancode, isrepeat)
    if isrepeat then return end
    if #ImageList == 0 or #ImageList == 1 then return end
    if key == "right" then
        CurrentImageIndex = CurrentImageIndex + 1
        if CurrentImageIndex > #ImageList then CurrentImageIndex = 1 end
        OpenImageFile(ImageList[CurrentImageIndex])
    end
    if key == "left" then
        CurrentImageIndex = CurrentImageIndex - 1
        if CurrentImageIndex < 1 then CurrentImageIndex = #ImageList end
        OpenImageFile(ImageList[CurrentImageIndex])
    end
 end

 -- Handle zooming image when mouse wheel scrolls
function love.wheelmoved(x, y)
    if OpenFile then return end
    local mousePosX, _ = Slab.GetMousePosition()
    if mousePosX > PreviewWindowWidth then return end
    if not PreviewImage then return end

    local prevImageScale = ImageScale
    ImageScale = math.floor(ImageScale + x + y)
    if ImageScale < 1 then ImageScale = 1 end
    if prevImageScale == ImageScale then return end
    ImagePos = {X = math.floor((WindowOptions.W / 2.0) - ((PreviewImage:getWidth() * ImageScale) / 2.0)), Y = math.floor((WindowOptions.H / 2.0) - ((PreviewImage:getHeight() * ImageScale) / 2.0))}
end

-- This is used to prevent bug with didder not using the current slider values when releasing the mouse
function love.mousereleased(x, y, button)
    if button == 1 and PreviewImage and ParameterChanged and SliderUpdateTimer == 0.0 then
        SliderUpdateTimer = love.timer.getTime()
    end
    if button == 1 and PreviewImage and ChannelChanged and ChannelUpdateTimer == 0.0 then
        ChannelUpdateTimer = love.timer.getTime()
    end
 end

-- Calls the copy command from the operating system, this is platform dependant
function CopyFile(source, destination)
    local copyString = [[copy "]] .. source .. [[" "]] .. destination
    copyString = string.gsub(copyString, [[/]], [[\]]) -- Converts paths to backslash for Windows. I think Mac and Linux use forward slash.
    print("\n" .. copyString .. "\n")
    io.popen(copyString):close()
end

-- Called if user drags file into window, loads a single image
function love.filedropped(file)
    local fileName = file:getFilename()
    if file and (string.lower(string.sub(fileName, #fileName - 3, #fileName)) == '.png' or string.lower(string.sub(fileName, #fileName - 3, #fileName)) == '.jpg' or string.lower(string.sub(fileName, #fileName - 4, #fileName)) == '.jpeg') then
        CurrentImageIndex = 1
        ImageList = {}
        ImageList[1] = fileName
        print('Loaded ' .. fileName)
        OpenImageFile(fileName)
        print(fileName)
    else
        print('Unsupported file type. Only .png, .jpg, and .jpeg are supported.')
    end
end

-- Called if user drags directory into window, this uses a library called nativefs. Loads all supported images from the directory
function love.directorydropped(path)
    local files = nativefs.getDirectoryItemsInfo(path)
    if #files ~= 0 then
        ImageList = {}
        for i = 1 , #files do
            if files[i].type == "file" then
                local imagePath = path .. '\\' .. files[i].name
                if imagePath and (string.lower(string.sub(imagePath, #imagePath - 3, #imagePath)) == '.png' or string.lower(string.sub(imagePath, #imagePath - 3, #imagePath)) == '.jpg' or string.lower(string.sub(imagePath, #imagePath - 4, #imagePath)) == '.jpeg') then
                    print('Loaded ' .. imagePath)
                    ImageList[#ImageList + 1] = imagePath
                end
            end
        end
        if ImageList[1] then
            OpenImageFile(ImageList[1])
            CurrentImageIndex = 1
        end
    end
end

-- Copy an image and load it into the window
function OpenImageFile(path)
    CurrentFileName = GetFileName(path)
    CopyFile(path, love.filesystem.getSource() .. [[/cache/input.bin"]])
    LoadImage()
end

-- Get the name of the file without the folder structure or file extension
function GetFileName(path)
    local startpoint = 1
    for i = 1, #path do
        local ch = path:sub(i, i)
        if ch == '/' or ch == '\\' then
            startpoint = i + 1
        end
    end
    for i = #path, 1, -1 do
        if path:sub(i, i) == '.' then
            path = path:sub(startpoint, i-1)
            break
        end
    end
    return path
end

-- Resize the toolbars when the window is resized 
function ResizeWindows()
    ToolbarOptions = {X = love.graphics.getWidth() - (love.graphics.getWidth() / 4.0), Y = 0, W = love.graphics.getWidth() / 4.0, H = love.graphics.getHeight(), AutoSizeWindow = false, AllowResize = false, AllowFocus = false}
    ToolbarElementWidth = ToolbarOptions.W - 50

    local BackgroundColor = {0,0,0,0}
    if not PreviewImage then BackgroundColor = {0,0,0,1} end
    WindowOptions = {X = 0, Y = 0, W =  love.graphics.getWidth() - (love.graphics.getWidth() / 4.0), H = love.graphics.getHeight(), AutoSizeWindow = false, AllowResize = false, BgColor = BackgroundColor, AllowFocus = false}
end

-- Loads the image from input.bin to display on the screen
function LoadImage()
    Slab.ResetImageCache()
    local resetScaleAndPos = false
    if PreviewImage then
        PreviewImage = nil
    else
        resetScaleAndPos = true
    end
    if ImageData then
        ImageData:release()
        ImageData = nil
    end
    ImageData = love.image.newImageData('cache/input.bin')
    ImageDataSize.Width = ImageData:getWidth()
    ImageDataSize.Height = ImageData:getHeight()
    PreviewImage = love.graphics.newImage(ImageData)
    PreviewImage:setFilter('nearest', 'nearest')

    if resetScaleAndPos then
        ImageScale = 1
        ImagePos = {X = math.floor((WindowOptions.W / 2.0) - (PreviewImage:getWidth() / 2.0)), Y = math.floor((WindowOptions.H / 2.0) - (PreviewImage:getHeight() / 2.0))}
    end

    ResizeWindows()
    if SplitChannelEnabled then
        SplitChannel()
    else
        DitherImage()
    end
end

-- Iterate through all images in the list, dither each one, and save it to the output folder
function SaveAllImages()
    for i = 1, #ImageList do
        OpenImageFile(ImageList[i])
        SaveImage()
    end
    OpenImageFile(ImageList[CurrentImageIndex])
end

-- Copy the dithered image to the output folder, using the current file name for the png
function SaveImage()
    CopyFile(love.filesystem.getSource() .. [[/cache/temp.png]], love.filesystem.getSource() .. [[/output/]] .. CurrentFileName .. [[.png"]])
end

-- Reload the image when switching between dithered and original image
function ReloadImage()
    if ShowOriginal then
        Slab.ResetImageCache()
        ImageData:release()
        ImageData = nil
        ImageData = love.image.newImageData('cache/input.bin')
        PreviewImage = nil
        PreviewImage = love.graphics.newImage(ImageData)
        PreviewImage:setFilter('nearest', 'nearest')
        --PreviewImage:replacePixels(ImageData)
    else
        Slab.ResetImageCache()
        ImageData:release()
        ImageData = nil
        ImageData = love.image.newImageData('cache/temp.png')
        PreviewImage = nil
        PreviewImage = love.graphics.newImage(ImageData)
        PreviewImage:setFilter('nearest', 'nearest')
        --PreviewImage:replacePixels(ImageData)
    end
end

function SplitChannel()
    local channelString = [["]] .. ColorChannels.Red .. [[*r+]] .. ColorChannels.Green .. [[*g+]] .. ColorChannels.Blue .. [[*b"]]

    --magick convert input.png -fx "0.3*r+0.6*g+0.1*b" output.png
    local cmdString = [[""]] .. love.filesystem.getSource() ..
    [[/magick" "]] ..
    love.filesystem.getSource() .. [[/cache/input.bin" -channel rgb -fx ]] ..
    channelString .. [[ "]] ..
    love.filesystem.getSource() .. [[/cache/grayscale.png""]]
    
    cmdString = string.gsub(cmdString, [[/]], [[\]])

    print("\n" .. cmdString .. "\n")
    io.popen(cmdString):close()
    
    DitherImage()
end

-- Call the command line didder application with all of the parameters
function DitherImage()
    if not PreviewImage then return end
    
    local ditherString = ""

    if SelectedDitherType == 'Bayer Matrix' then
        if UseCustomBayerType then
            ditherString = [[ bayer ]] .. SelectedBayerType1 .. [[x]] .. SelectedBayerType2
         else
            ditherString = [[ bayer ]] .. SelectedBayerType
         end
    elseif SelectedDitherType == 'Ordered Dithering Matrix' then
        ditherString = [[ odm ]] .. SelectedOrderedType
    elseif SelectedDitherType == 'Error Diffusion Matrix' then
        if Serpentine then 
            ditherString = [[ edm --serpentine ]] .. SelectedErrorType
        else
            ditherString = [[ edm ]] .. SelectedErrorType
        end
    elseif SelectedDitherType == 'Random' then
        ditherString = [[ random ]] .. RandomMin .. [[ ]] .. RandomMax
    end

    local inputString = [["]] .. love.filesystem.getSource() .. [[/cache/input.bin"]]

    if SplitChannelEnabled then
        inputString = [["]] .. love.filesystem.getSource() .. [[/cache/grayscale.png"]]
    end

    local scaleString = ""
    if CurrentScale < 1.0 then
        scaleString = "-x " .. math.floor(ImageDataSize.Width * CurrentScale)
    end

    local cmdString = [[""]] .. love.filesystem.getSource() ..
    [[/didder_win64" ]] .. scaleString ..
    [[ --palette "black white" -i ]] ..
    inputString .. [[ -o "]] ..
    love.filesystem.getSource() .. [[/cache/temp.png"]] ..
    [[ --strength ]] .. DitherParameters.Strength ..
    [[ --brightness ]] .. DitherParameters.Brightness ..
    [[ --contrast ]] .. DitherParameters.Contrast ..
    ditherString .. [[""]]
    
    cmdString = string.gsub(cmdString, [[/]], [[\]])

    print("\n" .. cmdString .. "\n")
    io.popen(cmdString):close()
    ImageData:release()
    ImageData = nil
    ImageData = love.image.newImageData('cache/temp.png')
    ReloadImage()
end