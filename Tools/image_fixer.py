from PIL import Image
import os

def fix_image(image_path):
    try:
        if not os.path.exists(image_path):
            print(f"Error: File not found at {image_path}")
            return

        with Image.open(image_path) as img:
            img = img.convert("RGBA")
            print(f"Original Size: {img.size}")
            
            # 1. Get Background Color (Top-Left Pixel)
            bg_color = img.getpixel((0, 0))
            print(f"Detected Background Color: {bg_color}")
            
            # 2. Resize (High Quality)
            # Force 140x210 for card size
            new_width = 140
            new_height = 210
            
            print(f"Resizing to: {new_width}x{new_height}")
            img_resized = img.resize((new_width, new_height), Image.Resampling.NEAREST)
            
            # 3. Remove Background
            datas = img_resized.getdata()
            new_data = []
            
            # Use strict match for the detected bg_color
            bg_r, bg_g, bg_b, _ = bg_color
            
            for item in datas:
                # Check RGB, ignore original Alpha
                if item[0:3] == (bg_r, bg_g, bg_b):
                    new_data.append((0, 0, 0, 0))
                else:
                    new_data.append(item)
            
            img_resized.putdata(new_data)
            
            # Save
            img_resized.save(image_path)
            print(f"Successfully fixed image: {image_path}")

    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    fix_image("Image/Cards/Neon/Front.png")
