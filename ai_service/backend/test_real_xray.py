import requests
import json
import os

url_img = "https://upload.wikimedia.org/wikipedia/commons/b/b5/Radiograph_of_osteoarthritis_of_the_knee.jpg"
print("Downloading real X-Ray image...")
headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
img_data = requests.get(url_img, headers=headers).content

with open("real_xray.jpg", "wb") as f:
    f.write(img_data)

print(f"Downloaded {os.path.getsize('real_xray.jpg')} bytes.")

url = "http://localhost:8000/analyze-scan"
files = {'image': ('real_xray.jpg', open('real_xray.jpg', 'rb'), 'image/jpeg')}
data = {
    'modality': '', 
    'joint_type': 'knee'
}

print(f"Sending POST request to {url}...")
try:
    response = requests.post(url, files=files, data=data)
    print(f"Status Code: {response.status_code}")
    print(json.dumps(response.json(), indent=2))
except Exception as e:
    print(f"Error: {e}")
