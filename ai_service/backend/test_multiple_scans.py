import requests
import json
import numpy as np
import cv2

# Create Synthetic Images
# 1. X-Ray: highly bimodal (dark background, very bright bones)
xray = np.zeros((200, 200), dtype=np.uint8)
xray[50:150, 80:120] = 220 # Bright bone
xray[100:105, 80:120] = 40 # Joint space narrowing
cv2.imwrite("mock_xray.png", xray)

# 2. MRI: High entropy, mid-tones, complex structures
mri = np.random.randint(50, 180, (200, 200), dtype=np.uint8)
# Add some dark and bright spots for cartilage/tendons
mri[20:40, 20:40] = 240
mri[160:180, 160:180] = 10
cv2.imwrite("mock_mri.png", mri)

# 3. Ultrasound (USG): Grainy/noisy, mostly mid-dark tones with anechoic (very dark) fluid pockets
usg = np.random.normal(70, 25, (200, 200)).astype(np.uint8)
# Add very dark "effusion/fluid" pocket (anechoic)
usg[100:150, 100:150] = 10
cv2.imwrite("mock_usg.png", usg)


def test_endpoint(image_path, local_bio):
    url = "http://localhost:8000/analyze-scan"
    
    files = {'image': (image_path, open(image_path, 'rb'), 'image/png')}
    
    # We leave modality empty so the server auto-detects it
    data = {
        'modality': '', 
        'joint_type': 'knee',
        'local_biomarkers': json.dumps(local_bio)
    }

    try:
        response = requests.post(url, files=files, data=data)
        result = response.json()
        print(f"\n--- Testing {image_path} ---")
        print(f"Detected Modality: {result.get('modality')}")
        print(f"Risk Score: {result.get('image_risk_score')}")
        print(f"KL Grade: {result.get('estimated_kl_grade')}")
        print("Findings:")
        for f in result.get('findings', []):
            print(f"  - {f}")
    except Exception as e:
        print(f"Error testing {image_path}: {e}")


if __name__ == "__main__":
    # Test 1: X-Ray with local finding of KL Grade 3
    test_endpoint("mock_xray.png", {"estimated_kl_grade": 3, "joint_space_proxy": 0.2})
    
    # Test 2: MRI with local finding of reduced cartilage
    test_endpoint("mock_mri.png", {"cartilage_integrity": 0.3})
    
    # Test 3: Ultrasound with local finding of high effusion (inflammation)
    test_endpoint("mock_usg.png", {"effusion_score": 0.85})
