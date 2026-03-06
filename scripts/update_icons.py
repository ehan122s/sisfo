import os
import subprocess
import shutil

sizes = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192
}

base_path = "/Users/suhendararyadi/Documents/Belajar Coding/E-PKL/android/app/src/main/res"
src_img = "/Users/suhendararyadi/.gemini/antigravity/brain/60fa6d81-4a6e-41aa-a4c4-7e68ddded736/app_icon_1769348018117.png"

print(f"Source Image: {src_img}")

for folder, size in sizes.items():
    dest_folder = os.path.join(base_path, folder)
    if not os.path.exists(dest_folder):
        print(f"Creating directory: {dest_folder}")
        os.makedirs(dest_folder)
    
    dest_path = os.path.join(dest_folder, "ic_launcher.png")
    round_path = os.path.join(dest_folder, "ic_launcher_round.png")
    
    print(f"Processing {folder} ({size}x{size})...")
    
    # Resize using sips
    try:
        cmd = ["sips", "-z", str(size), str(size), "-s", "format", "png", src_img, "--out", dest_path]
        subprocess.run(cmd, check=True, capture_output=True)
        
        # Copy to round (we use the square one as round for now, or just overwrite it)
        shutil.copy(dest_path, round_path)
        print(f"  -> Updated {dest_path}")
        print(f"  -> Updated {round_path}")
    except subprocess.CalledProcessError as e:
        print(f"Error processing {folder}: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")

print("Icon update process completed.")
