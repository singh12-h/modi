import re

with open('lib/doctor_dashboard.dart', 'r') as f:
    content = f.read()

# Replace .withOpacity(value) with .withValues(alpha: value)
content = re.sub(r'\.withOpacity\(([^)]+)\)', r'.withValues(alpha: \1)', content)

# Replace ..scale(value) with ..scaleByDouble(value)
content = re.sub(r'\.\.scale\(([^)]+)\)', r'..scaleByDouble(\1)', content)

with open('lib/doctor_dashboard.dart', 'w') as f:
    f.write(content)

print("Replaced all withOpacity and scale")
