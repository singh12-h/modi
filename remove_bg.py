from PIL import Image

# Load the logo
img = Image.open('e:/modi/assets/broader_ai_logo.png')
img = img.convert('RGBA')

# Get pixel data
data = img.getdata()

# Create new data with transparent white
new_data = []
for item in data:
    # If pixel is white or near white, make it transparent
    if item[0] > 240 and item[1] > 240 and item[2] > 240:
        new_data.append((255, 255, 255, 0))  # Transparent
    else:
        new_data.append(item)

# Update image data
img.putdata(new_data)

# Save with transparency
img.save('e:/modi/assets/broader_ai_logo_transparent.png', 'PNG')
print('Transparent logo created!')
