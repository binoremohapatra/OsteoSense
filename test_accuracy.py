import numpy as np
import tensorflow as tf
from sklearn.metrics import classification_report, accuracy_score

print("--- RUNNING ACCURACY TEST ON 300 NEW UNSEEN PATIENTS ---")

# Base anchor arrays from hospital
arr1_raw = [0.0,0.0,0.0,0.2436118504267428,0.0054886246000250384,0.015,0.004933657365484558,0.26984082410146687,0.03401962668813401,0.048,0.008043753787877896,0.6191256600356448,0.024493672652340235,0.043,0.00902591269623189,0.0298564120281214,0.0,5.56969590527102e-7,0.7461056095359965,0.12172551649125167,0.09155631391513436,0.02256677502970325,2.011200828788857,0.0,0.06,2.0,0.04942331293502207,4.833554301045503e-7,9.05597118478709e-8,3.7253228918331445e-8,2.139558773910165e-8,1.3740853027596274e-8,1.014521572711593e-8,0.1824425868162036,0.15248369288119062,0.14379157938090975,3.5230771873540183,0.055,0.0,7.738840495797697,0.03926335305831578,0.013042010531879436,0.36,0.11270412280913306,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]
arr2_raw = [0.0,0.0,0.0,0.7373386886014749,0.016973361482040015,0.065,0.016947589061574512,0.40955914526150755,0.03464563464565198,0.057,0.007473359351723966,2.3466537707122437,0.047828077527745136,0.199,0.04367012680311336,0.02782359184035901,0.0,6.894835343417695e-7,0.7460671412560981,0.04207439627746655,0.15930303735768514,0.03804833202801707,1.9945079783470157,62.5,0.045,0.0,0.0,5.434104653045507e-7,4.479919113025384e-8,4.0908450234324885e-8,8.828043683867089e-8,6.89283677471739e-8,1.008111877779426e-8,0.12505477586806663,0.10334087844322981,0.10661877049562966,2.8885091469477313,0.065,0.0,9.673317147317706,0.0469784188238213,0.02027720437411266,0.37,0.12377123737660296,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]

arr1 = np.array(arr1_raw + [0.0] * (203 - len(arr1_raw)), dtype=np.float32)
arr2 = np.array(arr2_raw + [0.0] * (203 - len(arr2_raw)), dtype=np.float32)

X_test = []
y_test_true = []

# Generate 300 completely unseen records
np.random.seed(99) # Different seed for test data

print("Generating 100 Healthy Patients...")
for _ in range(100):
    noise = np.random.normal(0, 0.08, 203)
    sample = arr1 + noise
    sample[180] = np.random.choice([0.0, 1.0, 2.0, 3.0]) 
    sample[185] = np.random.choice([0.0, 1.0])
    X_test.append(sample)
    y_test_true.append(0)

print("Generating 100 Low-Risk Patients...")
for _ in range(100):
    midpoint = (arr1 + arr2) / 2.0
    noise = np.random.normal(0, 0.12, 203)
    sample = midpoint + noise
    sample[180] = np.random.choice([2.0, 3.0, 4.0, 5.0])
    sample[185] = np.random.choice([1.0, 2.0, 3.0])
    X_test.append(sample)
    y_test_true.append(1)

print("Generating 100 High-Risk Patients...")
for _ in range(100):
    noise = np.random.normal(0, 0.18, 203)
    sample = arr2 + noise
    sample[180] = np.random.choice([5.0, 6.0, 7.0, 8.0, 9.0])
    sample[185] = np.random.choice([2.0, 3.0, 4.0])
    sample[180:203] += np.random.choice([0.0, 1.0], size=23, p=[0.5, 0.5])
    X_test.append(sample)
    y_test_true.append(2)

X_test = np.array(X_test, dtype=np.float32)
y_test_true = np.array(y_test_true, dtype=np.int32)

# Load TFLite Model
tflite_path = r"D:\OsteoSense\app\assets\models\oa_risk_model.tflite"
interpreter = tf.lite.Interpreter(model_path=tflite_path)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

y_pred = []
for i in range(300):
    interpreter.set_tensor(input_details[0]['index'], [X_test[i]])
    interpreter.invoke()
    output_data = interpreter.get_tensor(output_details[0]['index'])[0]
    predicted_class = np.argmax(output_data)
    y_pred.append(predicted_class)

y_pred = np.array(y_pred)

print("\n--- RESULTS ---")
accuracy = accuracy_score(y_test_true, y_pred) * 100
print(f"OVERALL MODEL ACCURACY: {accuracy:.2f}%")

print("\nDetailed Breakdown (Precision/Recall):")
print(classification_report(y_test_true, y_pred, target_names=["Healthy (KL 0)", "Low Risk (KL 1-2)", "High Risk (KL 3-4)"]))
