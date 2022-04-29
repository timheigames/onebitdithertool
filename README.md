# OneBitDitherTool
A 1-bit dithering tool written in [Love2D](https://love2d.org/). It currently supports Windows, Linux and macOS. This tool relies on the command line dithering tool [didder](https://github.com/makeworld-the-better-one/didder), command line image editor [ImageMagick](https://imagemagick.org/index.php), as well as the Lua libraries [Slab](https://github.com/flamendless/Slab) and [nativeFS](https://github.com/EngineerSmith/nativefs).

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
- Modify RGB channel multipliers before image is converted to grayscale.
- Multiple ways to open files. You can drag a single image into the window, drag a folder into the window to load multiple images, or use a file browser to open one or more images (select multiple with ctrl or shift click).
- Dither many images at the same time, with the same settings.
- Resize the image before dithering is applied.
- A toggle button to show the original image for making comparisons.

## macOS prerequisites
The app requires `lua`, the love2d framework and the `didder` app. Those are easily installed via [homebrew][https://brew.sh].

- Open a terminal window and install homebrew by typing `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`.
- Install `lua` by typing `brew install lua`.
- Install the love2d framework by typing `brew install love`.
- Add a cask for the developer of `didder` by typing `brew tap makeworld-the-better-one/tap`.
- Install the `didder` command line tool by typing `brew install didder`.

If you wish to use split RGB channel tweaking, you will also need `imageMagick`:

- Install the imageMagick command line tool by typing `brew install imagemagick`.

Unfortunately the love2d framework is not code-signed correctly so if you have the standard security settings, you will need to tell macOS to ignore that when using it.

- Go to `Applications`, right click on `Love` then select Open.
- You will get a notification that the app is from an unidentified developer, click Ok and close the `Love` app.
- In the finder menu open click on Go->Open Folder and type `/opt/homebrew/bin/`
- Right click on `love` then select Open.
- You will get a notification that the app is from an unidentified developer, click Ok.

## How to use
- Download and extract OneBitDitherTool from the [Releases](https://github.com/timheigames/onebitdithertool/releases) section.
- Run the app by using "Run_OneBitDitherTool_Windows.bat" on Windows, "Run_OneBitDitherTool_Linux.sh" on Linux or `love .` in a terminal window on macOS.
- You can drag a single image into the window, drag a folder into the window, or use the file browser. (.png, .jpg, .jpeg are supported)
  - Dragging a folder will scan through the folder and find all .png, .jpg, and .jpeg files. Any other files will be ignored.
  - While using the file browser, you can select multiple files using CTRL+Click or SHIFT+Click. You must click "OK" to load the files, double clicking does not work.
- If you have loaded multiple images, you can change the preview image with Left Arrow and Right Arrow.
- You can use left mouse to click and drag the image around. Mouse wheel will zoom the image at integer scales.
- You can resize the image before dithering is applied with the scale slider.
- By enabling "Split Channels", you can modify the RGB multipliers for the grayscale image. Note: This option will slow down performance in some cases.
- Adjust Strength, Brightness, and Contrast sliders with the mouse. Clicking the name of the slider will reset to the default value.
- Select a Dither Type in the drop down menu. Each dither type will have different settings available.
- When you are happy with the results, click "Save All To Output Folder". This will iterate through all of the loaded images, apply the same dithering to each one, and then copy the images to the "output" folder in the OneBitDitherTool directory. Output images are always .png files.
