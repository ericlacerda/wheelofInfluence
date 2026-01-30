import argparse
import os
from PIL import Image

def remove_background(image_path, output_path, key_color=(0, 0, 255), tolerance=50):
    """
    Removes a specific background color from an image using a chroma key approach.
    
    Args:
        image_path (str): Path to the input image.
        output_path (str): Path to save the output image.
        key_color (tuple): RGB tuple of the color to remove (default: Blue).
        tolerance (int): Distance tolerance for color matching.
    """
    try:
        img = Image.open(image_path)
        img = img.convert("RGBA")
        datas = img.getdata()

        new_data = []
        key_r, key_g, key_b = key_color

        for item in datas:
            r, g, b, a = item
            
            # Calculate Euclidean distance-like difference (simplified)
            diff = max(abs(r - key_r), abs(g - key_g), abs(b - key_b))
            
            # Alternative: Check if it's "mostly blue" vs other colors for better robustness
            # If Blue is dominant and Red/Green are low.
            # But let's stick to distance from key color for standard chroma key.
            
            if diff < tolerance:
                # Transparent
                new_data.append((0, 0, 0, 0))
            else:
                new_data.append(item)

        img.putdata(new_data)
        
        # Ensure output directory exists
        os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
        
        img.save(output_path, "PNG")
        print(f"Processed: {image_path} -> {output_path}")
        
    except Exception as e:
        print(f"Error processing {image_path}: {e}")

def main():
    parser = argparse.ArgumentParser(description="Remove background from images (Chroma Key).")
    parser.add_argument("--input", "-i", type=str, required=True, help="Input file or directory")
    # Default output to the Godot Image/Cards folder if relative
    default_output = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "Image", "Cards", "Neon"))
    parser.add_argument("--output", "-o", type=str, default=default_output, help=f"Output directory. Default: {default_output}")
    parser.add_argument("--tolerance", "-t", type=int, default=60, help="Color tolerance (0-255). Default 60.")
    
    args = parser.parse_args()
    
    input_path = args.input
    output_dir = args.output
    
    print(f"Processing images from {input_path} to {output_dir}")
    
    if os.path.isfile(input_path):
        # Single file
        filename = os.path.basename(input_path)
        output_path = os.path.join(output_dir, os.path.splitext(filename)[0] + ".png")
        remove_background(input_path, output_path, tolerance=args.tolerance)
        
    elif os.path.isdir(input_path):
        # Directory
        for filename in os.listdir(input_path):
            if filename.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp')):
                file_path = os.path.join(input_path, filename)
                output_path = os.path.join(output_dir, os.path.splitext(filename)[0] + ".png")
                remove_background(file_path, output_path, tolerance=args.tolerance)
    else:
        print("Invalid input path.")

if __name__ == "__main__":
    main()
