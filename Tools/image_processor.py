from PIL import Image
import os
import sys

def process_card_image(input_path, output_path):
    try:
        if not os.path.exists(input_path):
            print(f"Error: File not found at {input_path}")
            return

        with Image.open(input_path) as img:
            img = img.convert("RGBA")
            width, height = img.size
            print(f"Original Size: {width}x{height}")
            
            # 1. CROP to Aspect Ratio 2:3 (140:210)
            target_ratio = 2 / 3
            current_ratio = width / height
            
            if current_ratio > target_ratio:
                # Too wide: Trim sides
                new_width = int(height * target_ratio)
                left = (width - new_width) // 2
                right = left + new_width
                box = (left, 0, right, height)
            else:
                # Too tall: Trim top/bottom
                new_height = int(width / target_ratio)
                top = (height - new_height) // 2
                bottom = top + new_height
                box = (0, top, width, bottom)
            
            print(f"Cropping to box: {box}")
            img_cropped = img.crop(box)
            
            # 2. RESIZE to 140x210
            target_size = (140, 210)
            print(f"Resizing to: {target_size}")
            # Use LANCZOS for better downscaling quality, or NEAREST for pixel art crispness
            # Since user likes pixel art, NEAREST might be safer, but LANCZOS is better for general art.
            # Given previous "pixel art" prompt, lets stick to NEAREST to keep it sharp.
            img_final = img_cropped.resize(target_size, Image.Resampling.NEAREST)
            
            # 3. BACKGROUND REMOVAL (Flood Fill)
            from PIL import ImageDraw
            
            # Flood fill from all 4 corners with transparency
            # Threshold helps with compression artifacts or slight gradients
            threshold = 40 
            
            # Top-Left
            ImageDraw.floodfill(img_final, (0, 0), (0, 0, 0, 0), thresh=threshold)
            # Top-Right
            ImageDraw.floodfill(img_final, (img_final.width - 1, 0), (0, 0, 0, 0), thresh=threshold)
            # Bottom-Left
            ImageDraw.floodfill(img_final, (0, img_final.height - 1), (0, 0, 0, 0), thresh=threshold)
            # Bottom-Right
            ImageDraw.floodfill(img_final, (img_final.width - 1, img_final.height - 1), (0, 0, 0, 0), thresh=threshold)
            
            # No manual loop needed anymore
            
            # Save
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            img_final.save(output_path)
            print(f"Successfully processed image to: {output_path}")

    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input", required=True)
    parser.add_argument("-o", "--output", required=True)
    args = parser.parse_args()
    
    process_card_image(args.input, args.output)
