# OneBitDitherTool
A 1-bit dithering tool written in [Love2D](https://love2d.org/). This tool relies on the command line dithering tool [didder](https://github.com/makeworld-the-better-one/didder), as well as the Lua libraries [Slab](https://github.com/flamendless/Slab) and [nativeFS](https://github.com/EngineerSmith/nativefs). It currently only runs on Windows, although adding Mac and Linux support should be relatively straightforward (see the section on [Mac and Linux support](https://github.com/timheigames/onebitdithertool#mac-and-linux-support) if you want to help).

![UI_example_image](https://user-images.githubusercontent.com/102014001/165626507-634bcc2a-2d00-4f4f-925f-5c749f3a3a26.png)


## Features
- Supports all dithering algorithms provided by didder:
  - Bayer dithering
    - 2x2, 3x3, 3x5, 5x3, 4x4, 8x8, 16x16, 32x32, 64x64, custom size
  - Ordered dithering
    - Vertical5x3, Horizontal3x5, ClusteredDotVerticalLine, ClusteredDotHorizontalLine, ClusteredDot4x4, ClusteredDotSpiral5x5, ClusteredDot6x6, ClusteredDotDiagonal6x6, ClusteredDot8x8, ClusteredDotDiagonal8x8, ClusteredDotDiagonal16x16
  - Error diffusion dithering
    - Simple2D, FloydSteinberg, FalseFloydSteinberg, JarvisJudiceNinke, Atkinson, Stucki, Burkes, Sierra, TwoRowSierra, SierraLite, StevenPigeon
  - Random noise dithering
- Fine control over dither strength, image brightness, and image contrast with real-time updates in the preview window.
- Multiple ways to open files. You can drag a single image into the window, drag a folder into the window to load multiple images, or use a file browser to open one or more images (select multiple with ctrl or shift click).
- Dither many images at the same time, with the same settings.
- A toggle button to show the original image for making comparisons.

## How to use
- Download OneBitDitherTool by [clicking this link](https://github.com/timheigames/onebitdithertool/archive/main.zip), or at the top of the page with Code -> Download ZIP.
- Run the app by using "Run_OneBitDitherTool_Windows.bat".
- You can drag a single image into the window, drag a folder into the window, or use the file browser. (.png, .jpg, .jpeg are supported)
  - Dragging a folder will scan through the folder and find all .png, .jpg, and .jpeg files. Any other files will be ignored.
  - While using the file browser, you can select multiple files using CTRL+Click or SHIFT+Click. You must click "OK" to load the files, double clicking does not work.
- If you have loaded multiple images, you can change the preview image with Left Arrow and Right Arrow.
- You can use left mouse to click and drag the image around. Mouse wheel will zoom the image at integer scales.
- Adjust Strength, Brightness, and Contrast sliders with the mouse. Clicking the name of the slider will reset to the default value.
- Select a Dither Type in the drop down menu. Each dither type will have different settings available.
- When you are happy with the results, click "Save All To Output Folder". This will iterate through all of the loaded images, apply the same dithering to each one, and then copy the images to the "output" folder in the OneBitDitherTool directory. Output images are always .png files.

## Mac and Linux support
I only have access to a Windows PC, and I am not familiar with Linux. If anyone can get OneBitDitherTool working on another OS, please submit a pull request. Here is a list of things you will most likely need to change:

1. You will need the proper Love2D binary for your system. You can get it [here](https://love2d.org/). You will have to create an alternative method of running the app, such as a shell script. The `Run_OneBitDitherTool_Windows.bat` just runs the included love executable on the current directory (`%CD%/love-11.4-win64/love %CD%`)

2. Due to the limitations of Love2D when it comes to accessing the filesystem outside of the game folder, I have had to utilize Lua's `io.popen` function to run cmd commands. I use these commands to copy the image files to the game folder (as input.bin), and copy the dithered image to the output folder. For supporting Mac and Linux, these calls would need to be replaced by the respective OS alternatives.

3. I also use `io.popen` to run the didder command line app. [Didder](https://github.com/makeworld-the-better-one/didder/releases) has release executables for every kind of system, so it should be relatively simple to download yours and fix the "io.popen" call.

4. The `io.popen` calls might also need to be adjusted for your OS's directory structure (forward/backward slash), and for your OS's argument formatting.

5. You should be able to wrap OS specific code with [love.system.getOS()](https://love2d.org/wiki/love.system.getOS).

6. I also use nativeFS specifically for allowing the "drag folder to window" feature. I'm not sure if nativeFS works with Mac and Linux. If it doesn't you could just wrap the `love.directorydropped(path)` function with `if love.system.getOS() == "Windows" then`.
