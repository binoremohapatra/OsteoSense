"""
clinical_factors.py
------------------
Clinical questionnaire factors for OA risk assessment.

These factors are collected from the app's symptom questionnaire:
- Pain level (0-5 scale)
- Stiffness duration (none, <30min, 30min-1h, 1h-2h, >2h)
- Swelling (yes/no)
- Past injury (yes/no + details)
- MRI KL Grade (0-4)
- Pain characteristics (sharp, dull, burning, aching, stabbing, throbbing)
- Stiffness triggers (morning, after sitting, after inactivity, after exercise)
- Other symptoms (warmth, redness, tenderness, clicking, grinding, locking, giving way, instability, reduced mobility)
"""

import numpy as np


def encode_pain_level(pain_level):
    """Encode pain level (0-5) into features."""
    # One-hot encoding
    return {
        f"pain_level_{i}": 1.0 if pain_level == i else 0.0
        for i in range(6)
    }


def encode_stiffness_duration(stiffness_duration):
    """Encode stiffness duration into features."""
    mapping = {
        'none': 0,
        '<30min': 1,
        '30min-1h': 2,
        '1h-2h': 3,
        '>2h': 4
    }
    value = mapping.get(stiffness_duration, 0)
    return {
        f"stiffness_{i}": 1.0 if value == i else 0.0
        for i in range(5)
    }


def encode_swelling(swelling):
    """Encode swelling (yes/no)."""
    return {
        'swelling_yes': 1.0 if swelling else 0.0,
        'swelling_no': 1.0 if not swelling else 0.0
    }


def encode_past_injury(past_injury):
    """Encode past injury (yes/no)."""
    return {
        'past_injury_yes': 1.0 if past_injury else 0.0,
        'past_injury_no': 1.0 if not past_injury else 0.0
    }


def encode_mri_kl_grade(kl_grade):
    """Encode MRI KL Grade (0-4) into features."""
    return {
        f"kl_grade_{i}": 1.0 if kl_grade == i else 0.0
        for i in range(5)
    }


def encode_pain_characteristics(pain_chars):
    """Encode pain characteristics (multi-select)."""
    chars = ['Sharp', 'Dull', 'Burning', 'Aching', 'Stabbing', 'Throbbing']
    return {
        f"pain_{char.lower()}": 1.0 if pain_chars.get(char, False) else 0.0
        for char in chars
    }


def encode_stiffness_triggers(triggers):
    """Encode stiffness triggers (multi-select)."""
    trigger_list = ['Morning', 'After sitting', 'After inactivity', 'After exercise']
    return {
        f"stiffness_{trigger.lower().replace(' ', '_')}": 1.0 if triggers.get(trigger, False) else 0.0
        for trigger in trigger_list
    }


def encode_other_symptoms(symptoms):
    """Encode other symptoms (multi-select)."""
    symptom_list = ['Warmth', 'Redness', 'Tenderness', 'Clicking', 'Grinding',
                    'Locking', 'Giving way', 'Instability', 'Reduced mobility']
    return {
        f"symptom_{symptom.lower()}": 1.0 if symptoms.get(symptom, False) else 0.0
        for symptom in symptom_list
    }


def extract_clinical_factors(questionnaire_data):
    """
    Extract all clinical factors from questionnaire data.

    questionnaire_data: dict with keys:
        - pain_level (int)
        - stiffness_duration (str)
        - swelling (bool)
        - past_injury (bool)
        - mri_kl_grade (int)
        - pain_chars (dict)
        - stiffness_triggers (dict)
        - other_symptoms (dict)

    Returns: dict of all clinical features.
    """
    factors = {}

    # Basic factors
    factors.update(encode_pain_level(questionnaire_data.get('pain_level', 0)))
    factors.update(encode_stiffness_duration(questionnaire_data.get('stiffness_duration', 'none')))
    factors.update(encode_swelling(questionnaire_data.get('swelling', False)))
    factors.update(encode_past_injury(questionnaire_data.get('past_injury', False)))
    factors.update(encode_mri_kl_grade(questionnaire_data.get('mri_kl_grade', 0)))

    # Multi-select factors
    factors.update(encode_pain_characteristics(questionnaire_data.get('pain_chars', {})))
    factors.update(encode_stiffness_triggers(questionnaire_data.get('stiffness_triggers', {})))
    factors.update(encode_other_symptoms(questionnaire_data.get('other_symptoms', {})))

    return factors


if __name__ == "__main__":
    # Test with sample data
    sample_data = {
        'pain_level': 3,
        'stiffness_duration': '30min-1h',
        'swelling': True,
        'past_injury': False,
        'mri_kl_grade': 2,
        'pain_chars': {'Sharp': True, 'Aching': True},
        'stiffness_triggers': {'Morning': True, 'After sitting': True},
        'other_symptoms': {'Clicking': True, 'Grinding': True}
    }

    factors = extract_clinical_factors(sample_data)
    print("Clinical factors:")
    for k, v in factors.items():
        print(f"  {k}: {v}")
    print(f"Total features: {len(factors)}")
