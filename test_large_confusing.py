import numpy as np
import tensorflow as tf

print("--- TESTING 100+ CONFUSING & CONFLICTING CASES ---")

# Base anchors
arr1_raw = [0.0,0.0,0.0,0.2436118504267428,0.0054886246000250384,0.015,0.004933657365484558,0.26984082410146687,0.03401962668813401,0.048,0.008043753787877896,0.6191256600356448,0.024493672652340235,0.043,0.00902591269623189,0.0298564120281214,0.0,5.56969590527102e-7,0.7461056095359965,0.12172551649125167,0.09155631391513436,0.02256677502970325,2.011200828788857,0.0,0.06,2.0,0.04942331293502207,4.833554301045503e-7,9.05597118478709e-8,3.7253228918331445e-8,2.139558773910165e-8,1.3740853027596274e-8,1.014521572711593e-8,0.1824425868162036,0.15248369288119062,0.14379157938090975,3.5230771873540183,0.055,0.0,7.738840495797697,0.03926335305831578,0.013042010531879436,0.36,0.11270412280913306,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]
arr2_raw = [0.0,0.0,0.0,0.7373386886014749,0.016973361482040015,0.065,0.016947589061574512,0.40955914526150755,0.03464563464565198,0.057,0.007473359351723966,2.3466537707122437,0.047828077527745136,0.199,0.04367012680311336,0.02782359184035901,0.0,6.894835343417695e-7,0.7460671412560981,0.04207439627746655,0.15930303735768514,0.03804833202801707,1.9945079783470157,62.5,0.045,0.0,0.0,5.434104653045507e-7,4.479919113025384e-8,4.0908450234324885e-8,8.828043683867089e-8,6.89283677471739e-8,1.008111877779426e-8,0.12505477586806663,0.10334087844322981,0.10661877049562966,2.8885091469477313,0.065,0.0,9.673317147317706,0.0469784188238213,0.02027720437411266,0.37,0.12377123737660296,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]

healthy_gait = np.array(arr1_raw + [0.0] * (203 - len(arr1_raw)), dtype=np.float32)
severe_gait = np.array(arr2_raw + [0.0] * (203 - len(arr2_raw)), dtype=np.float32)
borderline_gait = (healthy_gait + severe_gait) / 2.0

# Load TFLite Model
tflite_path = r"D:\OsteoSense\app\assets\models\oa_risk_model.tflite"
interpreter = tf.lite.Interpreter(model_path=tflite_path)
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

def predict_batch(vectors):
    preds = []
    for vec in vectors:
        vec_f32 = np.array(vec, dtype=np.float32)
        interpreter.set_tensor(input_details[0]['index'], [vec_f32])
        interpreter.invoke()
        output_data = interpreter.get_tensor(output_details[0]['index'])[0]
        preds.append(np.argmax(output_data))
    return preds

np.random.seed(101)

# Group 1: 50 cases -> KL=4 (Severe), Pain=0, Gait=Healthy
# Expectation: Gait dominates -> Should predict Healthy (Class 0)
group1 = []
for _ in range(50):
    vec = np.copy(healthy_gait) + np.random.normal(0, 0.02, 203)
    vec[185] = 4.0 # KL 4
    vec[180] = 0.0 # Pain 0
    group1.append(vec)

# Group 2: 50 cases -> KL=0 (Normal), Pain=9, Gait=Severe
# Expectation: Gait dominates -> Should predict High Risk (Class 2)
group2 = []
for _ in range(50):
    vec = np.copy(severe_gait) + np.random.normal(0, 0.08, 203)
    vec[185] = 0.0 # KL 0
    vec[180] = 9.0 # Pain 9
    group2.append(vec)

# Group 3: 50 cases -> Borderline Gait (Midpoint), KL=4, Pain=9
# Expectation: Gait is 50/50, but Clinical is VERY BAD. Does the clinical push it to High Risk (Class 2)?
group3 = []
for _ in range(50):
    vec = np.copy(borderline_gait) + np.random.normal(0, 0.05, 203)
    vec[185] = 4.0 # KL 4
    vec[180] = 9.0 # Pain 9
    group3.append(vec)

# Group 4: 50 cases -> Borderline Gait (Midpoint), KL=0, Pain=0
# Expectation: Gait is 50/50, but Clinical is PERFECT. Does the clinical push it to Healthy (Class 0)?
group4 = []
for _ in range(50):
    vec = np.copy(borderline_gait) + np.random.normal(0, 0.05, 203)
    vec[185] = 0.0 # KL 0
    vec[180] = 0.0 # Pain 0
    group4.append(vec)

print("Testing Group 1 (KL 4, No Pain, Healthy Gait)...")
preds1 = predict_batch(group1)
g1_healthy = preds1.count(0)
g1_low = preds1.count(1)
g1_high = preds1.count(2)
print(f"  Results (out of 50): {g1_healthy} Healthy, {g1_low} Low Risk, {g1_high} High Risk")

print("\nTesting Group 2 (KL 0, Severe Pain, Severe Gait)...")
preds2 = predict_batch(group2)
g2_healthy = preds2.count(0)
g2_low = preds2.count(1)
g2_high = preds2.count(2)
print(f"  Results (out of 50): {g2_healthy} Healthy, {g2_low} Low Risk, {g2_high} High Risk")

print("\nTesting Group 3 (KL 4, Severe Pain, BORDERLINE Gait)...")
preds3 = predict_batch(group3)
g3_healthy = preds3.count(0)
g3_low = preds3.count(1)
g3_high = preds3.count(2)
print(f"  Results (out of 50): {g3_healthy} Healthy, {g3_low} Low Risk, {g3_high} High Risk")

print("\nTesting Group 4 (KL 0, No Pain, BORDERLINE Gait)...")
preds4 = predict_batch(group4)
g4_healthy = preds4.count(0)
g4_low = preds4.count(1)
g4_high = preds4.count(2)
print(f"  Results (out of 50): {g4_healthy} Healthy, {g4_low} Low Risk, {g4_high} High Risk")

print("\n--- ANALYSIS ---")
if g3_high > g3_low and g4_healthy > g4_low:
    print("SUCCESS: Clinical factors correctly steer the model when Gait is borderline!")
else:
    print("INSIGHT: The model is somewhat rigid and gait-heavy even in borderline scenarios.")
