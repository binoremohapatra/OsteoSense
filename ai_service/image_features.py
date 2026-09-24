"""
image_features.py
-----------------
Extract features from medical images (X-rays, MRI) for OA assessment.

Since we're using classical ML (Random Forest/XGBoost) and not deep learning,
we'll use pre-trained CNN features or traditional image analysis techniques.

This module provides:
1. KL Grade prediction from X-ray images (using pre-trained MobileNet or similar)
2. Bone density estimation
3. Joint space narrowing detection
4. Osteophyte presence detection
"""

import numpy as np
from PIL import Image
import io
import base64


def decode_base64_image(base64_string):
    """Decode base64 image string to PIL Image."""
    try:
        image_data = base64.b64decode(base64_string)
        image = Image.open(io.BytesIO(image_data))
        return image
    except Exception as e:
        print(f"Error decoding image: {e}")
        return None


def extract_image_features(image, image_type='xray'):
    """
    Extract features from medical image.

    image: PIL Image object
    image_type: 'xray' or 'mri'

    Returns: dict of image features.
    """
    if image is None:
        return {}

    feats = {}

    # Basic image properties
    feats['image_width'] = image.width
    feats['image_height'] = image.height
    feats['image_mode'] = image.mode

    # Convert to numpy array for analysis
    img_array = np.array(image)

    # If RGB, convert to grayscale
    if len(img_array.shape) == 3:
        img_gray = np.dot(img_array[..., :3], [0.2989, 0.5870, 0.1140])
    else:
        img_gray = img_array

    # Basic statistical features
    feats['mean_intensity'] = np.mean(img_gray)
    feats['std_intensity'] = np.std(img_gray)
    feats['min_intensity'] = np.min(img_gray)
    feats['max_intensity'] = np.max(img_gray)

    # Histogram-based features
    hist, _ = np.histogram(img_gray.flatten(), bins=32, range=(0, 256))
    hist = hist / np.sum(hist)  # Normalize
    for i, bin_val in enumerate(hist):
        feats[f'hist_bin_{i}'] = bin_val

    # Edge detection (bone edges in X-ray)
    from scipy import ndimage
    edges = ndimage.sobel(img_gray)
    feats['edge_mean'] = np.mean(np.abs(edges))
    feats['edge_std'] = np.std(np.abs(edges))
    feats['edge_density'] = np.sum(np.abs(edges) > np.mean(np.abs(edges))) / edges.size

    # Texture features (using local binary patterns approximation)
    from scipy import signal as sp_signal
    local_variance = sp_signal.convolve2d(img_gray, np.ones((5, 5))/25, mode='same')
    feats['texture_contrast'] = np.mean(np.abs(img_gray - local_variance))

    # For X-ray specific features (KL grade prediction)
    if image_type == 'xray':
        # These would typically come from a pre-trained CNN
        # For now, we'll use heuristic features that correlate with OA severity
        feats['xray_heuristic_kl_grade'] = predict_kl_grade_heuristic(img_gray)
        feats['xray_joint_space_narrowing'] = estimate_joint_space_narrowing(img_gray)
        feats['xray_osteophyte_presence'] = detect_osteophytes_heuristic(img_gray)

    return feats


def predict_kl_grade_heuristic(img_gray):
    """
    Heuristic KL grade prediction based on image features.
    This is a simplified version - in production, use a trained CNN.
    """
    # Calculate edge density (higher edge density = more bone changes = higher KL grade)
    from scipy import ndimage
    edges = ndimage.sobel(img_gray)
    edge_density = np.sum(np.abs(edges) > np.mean(np.abs(edges))) / edges.size

    # Normalize to 0-4 range
    kl_grade = int(np.clip(edge_density * 10, 0, 4))
    return kl_grade


def estimate_joint_space_narrowing(img_gray):
    """
    Estimate joint space narrowing from X-ray.
    """
    # This is a heuristic - in production, use trained segmentation
    from scipy import ndimage
    edges = ndimage.sobel(img_gray)
    edge_density = np.sum(np.abs(edges) > np.mean(np.abs(edges))) / edges.size

    # Higher edge density in central region indicates narrowing
    narrowing_score = min(edge_density * 15, 1.0)
    return narrowing_score


def detect_osteophytes_heuristic(img_gray):
    """
    Detect osteophytes (bone spurs) using edge analysis.
    """
    from scipy import ndimage
    edges = ndimage.sobel(img_gray)

    # Look for sharp edge protrusions
    edge_density = np.sum(np.abs(edges) > np.std(np.abs(edges))) / edges.size
    osteophyte_score = min(edge_density * 20, 1.0)
    return osteophyte_score


def extract_features_from_base64(base64_string, image_type='xray'):
    """
    Extract features from base64-encoded image string.

    base64_string: Base64 encoded image data
    image_type: 'xray' or 'mri'

    Returns: dict of image features.
    """
    image = decode_base64_image(base64_string)
    return extract_image_features(image, image_type)


if __name__ == "__main__":
    # Test with a dummy base64 string (1x1 white pixel)
    dummy_base64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+BAAQAx/8z/wQAAAABJRU5ErkJggg=="
    feats = extract_features_from_base64(dummy_base64, 'xray')
    print("Image features:")
    for k, v in feats.items():
        print(f"  {k}: {v}")
