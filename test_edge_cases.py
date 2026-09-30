import numpy as np
import tensorflow as tf

print("--- TESTING COMPLEX / CONFUSING EDGE CASES ---")

# Base anchors
arr1_raw = [0.0,0.0,0.0,0.2436118504267428,0.0054886246000250384,0.015,0.004933657365484558,0.26984082410146687,0.03401962668813401,0.048,0.008043753787877896,0.6191256600356448,0.024493672652340235,0.043,0.00902591269623189,0.0298564120281214,0.0,5.56969590527102e-7,0.7461056095359965,0.12172551649125167,0.09155631391513436,0.02256677502970325,2.011200828788857,0.0,0.06,2.0,0.04942331293502207,4.833554301045503e-7,9.05597118478709e-8,3.7253228918331445e-8,2.139558773910165e-8,1.3740853027596274e-8,1.014521572711593e-8,0.1824425868162036,0.15248369288119062,0.14379157938090975,3.5230771873540183,0.055,0.0,7.738840495797697,0.03926335305831578,0.013042010531879436,0.36,0.11270412280913306,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]
arr2_raw = [0.0,0.0,0.0,0.7373386886014749,0.016973361482040015,0.065,0.016947589061574512,0.40955914526150755,0.03464563464565198,0.057,0.007473359351723966,2.3466537707122437,0.047828077527745136,0.199,0.04367012680311336,0.02782359184035901,0.0,6.894835343417695e-7,0.7460671412560981,0.04207439627746655,0.15930303735768514,0.03804833202801707,1.9945079783470157,62.5,0.045,0.0,0.0,5.434104653045507e-7,4.479919113025384e-8,4.0908450234324885e-8,8.828043683867089e-8,6.89283677471739e-8,1.008111877779426e-8,0.12505477586806663,0.10334087844322981,0.10661877049562966,2.8885091469477313,0.065,0.0,9.673317147317706,0.0469784188238213,0.02027720437411266,0.37,0.12377123737660296,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]

healthy_gait = np.array(arr1_raw + [0.0] * (203 - len(arr1_raw)), dtype=np.float32)
severe_gait = np.array(arr2_raw + [0.0] * (203 - len(arr2_raw)), dtype=np.float32)

tflite_path = r"D:\OsteoSense\app\assets\models\oa_risk_model.tflite"
interpreter = tf.lite.Interpreter(model_path=tflite_path)
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

def predict(patient_vector):
    interpreter.set_tensor(input_details[0]['index'], [patient_vector])
    interpreter.invoke()
    return interpreter.get_tensor(output_details[0]['index'])[0]

patients = []

# Case 1: Silent Degeneration (Terrible X-Ray, but zero pain and perfect gait)
p1 = np.copy(healthy_gait)
p1[185] = 4.0 # Severe KL Grade
p1[180] = 0.0 # 0 Pain
patients.append(("Silent Degeneration (KL 4, 0 Pain, Healthy Gait)", p1))

# Case 2: Ghost Pain (Perfect X-Ray, Perfect Gait, but extreme pain)
p2 = np.copy(healthy_gait)
p2[185] = 0.0 # KL Grade 0
p2[180] = 9.0 # Extreme Pain
patients.append(("Ghost Pain (KL 0, Pain 9, Healthy Gait)", p2))

# Case 3: Severe Limp, No Arthritis (KL Grade 1, but gait is highly erratic - maybe ankle sprain?)
p3 = np.copy(severe_gait)
p3[185] = 1.0 # Mild OA
p3[180] = 3.0 # Mild Pain
patients.append(("Severe Limp but Mild OA (KL 1, Pain 3, SEVERE Gait)", p3))

# Case 4: Post-Surgery Success (Had surgery, X-ray is KL 4 from past, but gait and pain are perfectly healthy now)
p4 = np.copy(healthy_gait)
p4[185] = 4.0 # KL 4
p4[184] = 1.0 # Past Surgery = True
p4[180] = 0.0 # Pain = 0
patients.append(("Post-Op Success (KL 4, Past Surgery, 0 Pain, Healthy Gait)", p4))

for name, vector in patients:
    probs = predict(vector)
    cls = np.argmax(probs)
    labels = ["Healthy (Class 0)", "Low Risk (Class 1)", "High Risk (Class 2)"]
    print(f"\n{name}")
    print(f"  Prediction: {labels[cls]}")
    print(f"  Confidence: {probs[cls]*100:.2f}%")
    print(f"  Full Breakdown: Healthy={probs[0]:.3f}, Low={probs[1]:.3f}, High={probs[2]:.3f}")
