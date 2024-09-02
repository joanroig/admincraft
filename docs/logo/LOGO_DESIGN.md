## ![Admincraft logo](variants/dirt.png) Logo Design

The [variants](variants) folder the Admincraft logo and its alternative versions. The official logo can be found at the [variants/dirt.png](variants/dirt.png).

### Specification

- **Logo Format**: PNG
- **Logo Size**: 16x16px
- **Color Count**: Maximum of 6 colors

### How to Create and Apply Logo Icons

1. **Obtain or Create a Base Sprite**:

   - Download or draw a sprite with a resolution of 16x16px.
   - Use [Inktica](https://play.google.com/store/apps/details?id=com.arcuilo.inktica) or any pixel-editing software to customize the logo. Ensure the resolution remains 16x16px and the color count does not exceed 6 colors.

2. **Reduce Color Palette**:

   - If necessary, reduce the color palette to a maximum of 6 colors using [Online PNG Tools](https://onlinepngtools.com/decrease-png-color-count).

3. **Add the Logo to the Project**:

   - Create a new folder in [/docs/logo](/docs/logo) with the desired icon name. Inside this folder, place the logo file with the name **logo.png**.

4. **Apply Your Logo**:

   - Ensure [Python](https://www.python.org/downloads/) is installed.
   - Update the text in `choose_logo.txt` to point to your newly created file.
   - Run the script [change_logo.py](change_logo.py) using the following commands:

     ```
     pip install -r requirements.txt
     python change_logo.py
     ```

   - App icons for all platforms will be updated and applied the next time the app is built.

### Technical Details

- The Python scripts upscale the logo to ensure suitability for various sizes and formats across platforms, while maintaining the crispness of pixel art.
- The logo's color palette is always compressed to exactly 6 colors. If a logo with more colors is provided, it will be adjusted to meet this requirement.
