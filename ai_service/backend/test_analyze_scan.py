import requests
import numpy as np
import cv2
import json

# Create a fake X-ray image (bimodal histogram)
# Dark background + bright bones
img = np.zeros((200, 200), dtype=np.uint8)
img[50:150, 80:120] = 200  # Bright bone

cv2.imwrite("test_xray.png", img)

# Test the endpoint
url = "http://localhost:8000/analyze-scan"
files = {'image': ('test_xray.png', open('test_xray.png', 'rb'), 'image/png')}
data = {
    'modality': '', # let it auto-detect
    'joint_type': 'knee'
}

print(f"Sending POST request to {url}...")
try:
    response = requests.post(url, files=files, data=data)
    print(f"Status Code: {response.status_code}")
    print(json.dumps(response.json(), indent=2))
except Exception as e:
    print(f"Error: {e}")
