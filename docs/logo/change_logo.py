import os
from PIL import Image, ImageOps

def read_logo_name():
    """
    Reads the logo name from a file named 'choose_logo.txt'.
    
    :return: The logo name as a string.
    :rtype: str
    """
    with open('choose_logo.txt', 'r') as file:
        return file.readline().strip()

def validate_and_open_logo(logo_location):
    """
    Validates and opens the logo image file from the specified path.
    
    :param logo_location: Path of the logo image file.
    :type logo_location: str
    
    :return: PIL.Image instance of the logo image.
    :rtype: PIL.Image.Image
    
    :raises FileNotFoundError: If the logo image file does not exist.
    :raises ValueError: If the image is not a 16x16 PNG file.
    """
    logo_path = os.path.join(os.getcwd(), logo_location)

    if not os.path.isfile(logo_path):
        raise FileNotFoundError(f"File {logo_path} does not exist.")
    
    img = Image.open(logo_path)
    if img.size != (16, 16) or img.format != 'PNG':
        img.close()
        raise ValueError("Image must be a 16x16 PNG file.")
    return img

def convert_to_6_colors(image):
    """
    Converts an image to a 6-color palette using adaptive color quantization.

    This method first ensures the image is in RGBA mode and then reduces the 
    color palette to 6 colors using adaptive dithering. This process can 
    be useful for tasks such as creating a stylized image with a limited 
    color scheme.

    :param image: A PIL.Image instance of the source image.
    :type image: PIL.Image.Image
    
    :return: A PIL.Image instance of the image converted to a 6-color palette.
    :rtype: PIL.Image.Image
    """
    # Convert image to RGBA if not already in that mode
    if image.mode != 'RGBA':
        image = image.convert('RGBA')
    
    # Reduce the image to a palette of 6 colors using adaptive dithering
    image = image.convert('P', palette=Image.ADAPTIVE, colors=6)
    return image

def save_resized_image(image, output_path, size):
    """
    Resizes the given image to the specified size and saves it to the output path.
    
    :param image: PIL.Image instance of the source image.
    :type image: PIL.Image.Image
    
    :param output_path: Path where the resized image will be saved.
    :type output_path: str
    
    :param size: Desired width and height for the resized image.
    :type size: int
    """
    # Convert image to 6-colors palette before resizing
    image = convert_to_6_colors(image)
    resized_image = image.resize((size, size), Image.Resampling.NEAREST)
    resized_image.save(output_path)

def save_resized_image_with_frame(image, output_path, target_size):
    """
    Resizes the input pixel art image to fit within the target size, adds a transparent border,
    and saves it to the specified output path.
    
    :param image: PIL.Image instance of the source pixel art image.
    :type image: PIL.Image.Image
    
    :param output_path: Path where the output image with frame will be saved.
    :type output_path: str
    
    :param target_size: Maximum size (width and height) for the resized image.
    :type target_size: int
    """
    # Convert image to 6-colors palette before resizing and framing
    image = convert_to_6_colors(image)
    
    # Ensure the image is in RGBA mode to handle transparency for framing
    if image.mode != 'RGBA':
        image = image.convert('RGBA')
    
    # Resize the image to fit within the target size, maintaining aspect ratio
    aspect_ratio = image.width / image.height
    if image.width > image.height:
        new_width = target_size
        new_height = int(target_size / aspect_ratio)
    else:
        new_height = target_size
        new_width = int(target_size * aspect_ratio)
    
    resized_image = image.resize((new_width, new_height), Image.Resampling.NEAREST)
    
    # Create a frame with a transparent border
    border_size = max(int(target_size * 0.1), 1)  # Ensure border is at least 1 pixel
    framed_image = ImageOps.expand(resized_image, border=border_size, fill=(0, 0, 0, 0))
    
    # Ensure the final image fits within the target size
    if framed_image.size[0] > target_size or framed_image.size[1] > target_size:
        framed_image = framed_image.resize((target_size, target_size), Image.Resampling.NEAREST)
    
    framed_image.save(output_path)

def generate_android_icons(image):
    """
    Generates Android icons in various resolutions from the provided image.
    
    :param image: PIL.Image instance of the source image.
    :type image: PIL.Image.Image
    """
    sizes = {'mipmap-hdpi': 72, 'mipmap-mdpi': 48, 'mipmap-xhdpi': 96, 'mipmap-xxhdpi': 144, 'mipmap-xxxhdpi': 192}
    for folder, size in sizes.items():
        output_path = os.path.join('..', '..', 'android', 'app', 'src', 'main', 'res', folder, 'ic_launcher.png')
        save_resized_image(image, output_path, size)

def generate_ios_icons(image):
    """
    Generates iOS icons in various resolutions from the provided image.
    
    :param image: PIL.Image instance of the source image.
    :type image: PIL.Image.Image
    """
    sizes = [16, 20, 29, 32, 40, 48, 50, 55, 57, 58, 60, 64, 66, 72, 76, 80, 87, 88, 92, 100, 102, 114, 120, 128, 144, 152, 167, 172, 180, 196, 216, 256, 512, 1024]
    for size in sizes:
        output_path = os.path.join('..', '..', 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset', f'{size}.png')
        save_resized_image(image, output_path, size)

def generate_macos_icons(image):
    """
    Generates macOS icons with a frame in various resolutions from the provided image.
    
    :param image: PIL.Image instance of the source image.
    :type image: PIL.Image.Image
    """
    sizes = [16, 32, 64, 128, 256, 512, 1024]
    for size in sizes:
        output_path = os.path.join('..', '..', 'macos', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset', f'app_icon_{size}.png')
        save_resized_image_with_frame(image, output_path, size)

def generate_web_icons(image):
    """
    Generates web icons in various resolutions from the provided image.
    
    :param image: PIL.Image instance of the source image.
    :type image: PIL.Image.Image
    """
    sizes = [192, 512]
    for size in sizes:
        output_path = os.path.join('..', '..', 'web', 'icons', f'Icon-{size}.png')
        save_resized_image(image, output_path, size)
    
    favicon_path = os.path.join('..', '..', 'web', 'favicon.png')
    save_resized_image(image, favicon_path, 16)

def generate_web_maskable_icons(image):
    """
    Generates maskable web icons in various resolutions from the provided image.
    
    :param image: PIL.Image instance of the source image.
    :type image: PIL.Image.Image
    """
    sizes = [192, 512]
    for size in sizes:
        output_path = os.path.join('..', '..', 'web', 'icons', f'Icon-maskable-{size}.png')
        save_resized_image(image, output_path, size)

def generate_windows_icon(image):
    """
    Generates a Windows icon with multiple resolutions from the provided image and saves it as an ICO file.
    Upscales the image to 512px before generating the icon.
    
    :param image: PIL.Image instance of the source image.
    :type image: PIL.Image.Image
    """
    # Convert image to 6-colors palette before resizing
    image = convert_to_6_colors(image)
    # Upscale the image to 512px before generating the ICO file
    upscaled_image = image.resize((512, 512), Image.Resampling.NEAREST)
    
    # Define icon sizes (excluding 24px as it's not a multiple of 16)
    icon_sizes = [(16, 16), (32, 32), (48, 48), (256, 256), (512, 512)]
    output_path = os.path.join('..', '..', 'windows', 'runner', 'resources', 'app_icon.ico')
    upscaled_image.save(output_path, format='ICO', sizes=icon_sizes)


def main():
    """
    Main function to read the logo name, validate and open the logo image, and generate icons for different platforms.
    Specially designed to resize pixel art.
    """
    logo_location = read_logo_name()
    logo_image = validate_and_open_logo(logo_location)

    generate_android_icons(logo_image)
    generate_ios_icons(logo_image)
    generate_macos_icons(logo_image)
    generate_web_icons(logo_image)
    generate_web_maskable_icons(logo_image)
    generate_windows_icon(logo_image)

    # Close the image after all operations
    logo_image.close()

if __name__ == '__main__':
    main()
