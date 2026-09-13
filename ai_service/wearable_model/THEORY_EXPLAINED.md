# The Complete Theory Behind the OA Risk Classifier

This document explains **everything** — the reasoning behind every design choice, the physics behind every feature, and the ML theory behind every modeling decision — for SIH26004.

---

## 1. The Problem, Framed Properly

Osteoarthritis (OA) is usually diagnosed *after* cartilage damage has already progressed enough to show up on an X-ray. By then, treatment is largely about managing damage that's already done. The idea behind this project is to catch **pre-clinical biomechanical signatures** — subtle changes in how a joint moves, sounds, and is muscularly controlled — before a person would ever think to see a doctor.

This is fundamentally a **pattern recognition problem**: healthy joints move, sound, and are muscularly controlled a certain way; joints under early mechanical stress differ in all three, even if the person doesn't feel it yet. The entire pipeline exists to detect that difference automatically from wearable sensor data.

---

## 2. The Three Sensors — What They Physically Measure

### Gyroscope (motion)
A gyroscope measures **angular velocity** — how fast something is rotating, in degrees or radians per second, along three axes. Strapped near the knee, it captures how the joint rotates through a gait cycle: flexion/extension (bending/straightening), and smaller ab/adduction and internal/external rotation movements.

**Why this matters for OA:** joints under early degeneration don't move as smoothly. The muscles and cartilage that normally produce fluid, controlled rotation start compensating — producing motion that's less consistent stride-to-stride and less smooth moment-to-moment. Gyroscope data captures both of these directly as raw angular velocity over time.

### EMG module (muscle activation)
Surface EMG (electromyography) measures the tiny electrical signals generated when muscle fibers contract. A single-channel EMG module placed over a muscle near the joint (e.g. quadriceps) captures a broadband, noise-like waveform whose *amplitude* rises and falls with how hard and how long that muscle fires.

**Why this matters for OA:** joints under early mechanical stress are frequently protected by **compensatory muscle guarding** — the body unconsciously increases and prolongs muscle activation around a joint to stabilize or offload it, often before any pain is consciously noticed. This shows up in EMG as larger-amplitude, longer-duration, less consistent activation bursts compared to the crisp, efficient burst-then-relax pattern of a healthy joint during gait. This is a genuinely independent signal — it reflects the *muscular* response to joint stress, not the joint's motion (gyro) or sound (piezo) directly, which is exactly why adding it is valuable rather than redundant.

### Piezo disc (joint sound / vibration)
A piezo disc is a transducer that converts mechanical vibration into an electrical voltage. Pressed against the joint, it picks up the actual physical vibrations transmitted through the skin and tissue as the joint moves — essentially a contact microphone for the body.

**Why this matters for OA:** healthy joints move with smooth cartilage-on-cartilage contact and produce mostly low-frequency, tonal sound (soft tissue movement). As cartilage wears, surfaces become rougher, and movement starts producing **crepitus** — the clicking, popping, or grinding sensation/sound many people associate with "bad knees." This shows up in a piezo signal as **broadband, high-frequency, burst-like vibration** rather than smooth low-frequency sound. This is a well-established phenomenon studied under the field of **vibroarthrography (VAG)** — the clinical/research term for exactly this kind of joint-sound analysis.

---

## 3. Why Synthetic Data First (and Its Real Limitation)

There was no labeled real data available at project start, and getting clinically-labeled OA data in a hackathon timeframe isn't realistic. So the pipeline was built entirely on **fabricated data** — signals generated in code with rules based on published OA gait/VAG/EMG literature (more jerk, more variability, more crepitus bursts, more prolonged muscle guarding for the "OA-risk" class).

**The critical thing to understand:** this validates *pipeline plumbing*, not *model accuracy*. Because the rules that separate the two classes were written by hand, the classifier trained on this data gets a perfect 1.000 AUC — that's not the model being "good," it's the classes being artificially, perfectly separable by construction. Real biological signals overlap, are noisy, and vary hugely between people. A real published VAG study (using an 89-signal benchmark dataset across five joint-condition classes) reports around 87-88% accuracy with real subjects — that's the realistic ceiling to expect once real data comes in, not 100%.

---

## 4. Feature Engineering — The Core Translation Layer

Raw sensor data (a stream of numbers over time) isn't directly usable by classical ML models in a meaningful way — you need to translate it into **descriptive numbers (features)** that capture the underlying phenomenon. This is where most of the domain knowledge in the project lives. There are three feature groups now, one per sensor, combined into a single 45-feature vector.

### 4a. Gait Features (from gyroscope)

**Stride/peak detection.** The dominant gyro axis (flexion/extension) rises and falls once per gait cycle (per step). Using peak-detection (`scipy.signal.find_peaks`, with a minimum 0.5-second spacing constraint so noise isn't mistaken for a stride), each peak marks one gait cycle. From the *timing* of these peaks:
- **Cadence** — steps per second
- **Stride time mean** — average time per gait cycle
- **Stride time coefficient of variation (CV)** — how *consistent* stride timing is. This is one of the most clinically meaningful features: healthy walking is metronomic; early joint problems often manifest as inconsistency in timing before they manifest as slowness.

**Jerk (movement smoothness).** Jerk is literally the mathematical derivative of angular velocity — the rate of change of motion. It's computed as `np.diff(signal) * sample_rate`, then reduced to a single number via RMS (root mean square, a way of summarizing the "typical magnitude" of a signal that fluctuates around zero). High jerk means rough, uncontrolled, jerky motion; low jerk means smooth, well-controlled motion. This is a widely used movement-quality metric in biomechanics and rehabilitation research generally, not something specific to this project — an established concept applied to this specific signal.

**Frequency-domain smoothness.** Using Welch's method (`scipy.signal.welch`) — a standard way to estimate the power spectral density (how much signal energy exists at each frequency) — the pipeline computes what fraction of the total motion energy sits above a quarter of the sampling rate. Smooth, controlled movement concentrates energy at low frequencies (the actual gait rhythm); rough, tremor-like movement pushes more energy into higher frequencies. This ratio is a compact way of capturing "how rough is this motion overall," complementary to jerk.

**Stride amplitude variability.** How much the *size* (not just timing) of each stride's peak varies. This acts as an asymmetry/consistency proxy — someone favoring one side or compensating for discomfort tends to produce less uniform stride amplitudes.

### 4b. Piezo / VAG Features (from the piezo disc)

This entire feature group borrows techniques from **audio signal processing**, because "detect a grinding/clicking sound pattern in a vibration signal" is mathematically the same problem as audio event detection.

**Power spectrum + band energy ratios.** Again via Welch's method, the pipeline computes the full frequency spectrum of the piezo signal, then measures what fraction of total energy falls into specific bands:
- 0–100 Hz: normal soft-tissue movement sound
- 100–200 Hz: transition zone
- **200–800 Hz: the crepitus band** — where grinding/clicking sounds are reported to concentrate in VAG literature
- 800–2000 Hz: higher-frequency content

This band-splitting is a standard audio/vibration analysis technique — essentially asking "where does this signal's energy live?" and using that distribution as a fingerprint.

**Spectral entropy.** Entropy, borrowed from information theory, measures how "spread out" or unpredictable a distribution is. Applied to a normalized power spectrum, low entropy means energy is concentrated at a few frequencies (a smooth, tonal sound); high entropy means energy is spread broadly across many frequencies (a noisy, broadband sound — exactly what crepitus sounds like). This is computed with `scipy.stats.entropy`.

**Transient burst detection.** This is the most literally "listen for clicks" feature in the pipeline. The signal's **envelope** is computed using a Hilbert transform — a mathematical technique that extracts the amplitude of a signal over time regardless of its underlying frequency content (this is the same math used in AM radio demodulation). Once the envelope is available, any point where it spikes more than 3 standard deviations above its mean gets flagged — those spikes correspond to sudden, sharp events: exactly what a discrete click or pop looks like in vibration data. These events are counted (`n_transient_bursts`) and their share of total signal energy is measured (`burst_energy_ratio`). Crepitus is fundamentally a series of discrete micro-events, not continuous noise, so this feature targets that structure directly.

**Mel-scale band energies (MFCC substitute).** MFCCs (Mel-Frequency Cepstral Coefficients) are the standard feature representation in speech/audio ML — but computing true MFCCs needs an extra library (`librosa`), avoided here to keep dependencies minimal. Instead, a simplified version is computed: frequency is converted to the **mel scale** (a perceptually-motivated frequency scale that weights lower frequencies more heavily, originally designed to match human hearing perception, but useful here too since it emphasizes the range where meaningful joint-sound differences occur), and log-energy is computed in 6 mel-spaced bands. This gives a compact, complementary summary of spectral shape.

### 4c. EMG Features (from the EMG module)

These borrow standard **time-domain and frequency-domain EMG analysis** techniques used broadly in biomechanics and rehabilitation research, plus custom activation-burst features targeting the muscle-guarding pattern described above.

**Time-domain amplitude features.** RMS (root mean square) and MAV (mean absolute value) are the two most standard ways of summarizing overall EMG activation magnitude — both capture "how strongly is this muscle firing, on average, over this window." **Waveform length** (the cumulative sum of absolute differences between consecutive samples) is a standard EMG complexity/activity metric — a more active, less controlled muscle produces a longer, more jagged waveform.

**Frequency-domain features.** **Median frequency** (the frequency that splits the signal's total power exactly in half) and **mean frequency** are classic EMG quality/fatigue indicators — shifts in these values are associated with changes in which muscle fibers are being recruited to do the work, which can differ under compensatory guarding versus normal firing patterns.

**Activation-burst features — the core "muscle guarding" detector.** Using the same Hilbert-transform envelope technique applied to the piezo signal, the pipeline extracts the EMG's activation envelope and thresholds it to identify when the muscle is "active" versus "resting." From this:
- **Duty cycle** — what fraction of the whole window the muscle spends activated. A healthy muscle fires in short, efficient bursts timed to the gait cycle; compensatory guarding shows up as *prolonged* activation, raising this fraction.
- **Activation amplitude variability** — how consistent activation strength is across bursts. Guarding tends to produce less consistent, more variable activation than the crisp, repeatable pattern of normal gait.

### 4d. Why hand-crafted features instead of raw signal → deep learning?

Three concrete reasons:
1. **Dataset size.** Deep learning models need lots of data to avoid overfitting; a hackathon-scale dataset (dozens to low hundreds of subjects, realistically) is far too small for that. Classical ML with well-chosen features generalizes much better on small datasets.
2. **Explainability.** Every feature above maps to a one-sentence physical explanation ("this measures how jagged the motion is," "this counts clicking sounds," "this measures how long the muscle stays tense"). That matters enormously when explaining the system to judges or, eventually, clinicians — a black-box neural net offers no such story.
3. **Deployability.** These features and the resulting classical models run instantly on a phone or lightweight backend. No GPU, no edge-inference framework needed.

---

## 5. Model Training — The ML Theory

### Why train and compare four different models?

No single algorithm is universally best — it depends on the data's underlying structure, which you don't know in advance. So the pipeline trains **four different classifiers** with fundamentally different approaches and lets cross-validation pick the winner objectively rather than guessing:

- **Logistic Regression** — the simplest approach: finds a straight-line (technically, a linear combination of features passed through a sigmoid function) boundary between classes. Fast, highly interpretable (each feature gets a weight showing its influence), and surprisingly strong when classes are close to linearly separable.
- **Random Forest** — builds many decision trees, each trained on a random subset of data and features, then averages their votes. Naturally captures non-linear relationships and feature interactions, and is fairly resistant to overfitting on small-to-medium datasets. Also gives feature importance scores "for free."
- **SVM (Support Vector Machine, RBF kernel)** — finds the boundary between classes that maximizes the margin (distance) to the nearest points of each class. The RBF kernel lets it find non-linear boundaries by implicitly mapping data into a higher-dimensional space. Tends to do well on smaller, cleanly-separated datasets.
- **XGBoost** — an advanced form of gradient boosting: builds trees sequentially, where each new tree specifically tries to correct the errors of the previous ones. Often the strongest performer on structured/tabular feature data (exactly the kind of data this pipeline produces), which is why it's a common choice in real-world ML competitions on tabular data.

### Cross-validation — why not just one train/test split?

A single train/test split can be lucky or unlucky depending on which subjects happen to land in which set — especially with a small dataset. **5-fold cross-validation** solves this: the training data is split into 5 chunks, and the model is trained 5 times, each time holding out a different chunk as validation. The average performance across all 5 folds gives a far more reliable estimate than any single split, and the *spread* across folds tells you how stable the model is (a model with very different scores across folds is unstable/unreliable).

### ROC-AUC — why this metric specifically?

AUC (Area Under the ROC Curve) measures how well a model ranks positive cases above negative cases across *every possible decision threshold*, not just the default 0.5 cutoff. A perfect model scores 1.0; random guessing scores 0.5. It's a better metric than plain accuracy for medical-style screening problems because it doesn't depend on picking one specific threshold — useful since in a real deployment you might want to tune sensitivity vs. specificity based on context (e.g. a screening tool might deliberately favor catching more true positives at the cost of more false alarms).

### Feature scaling

Before training, every feature is standardized (`StandardScaler`) — transformed to have mean 0 and standard deviation 1. This matters because features are wildly different in raw scale (e.g. `stride_time_cv` might be ~0.1 while `piezo_total_power` might be in the thousands, while `emg_median_freq` is in the hundreds). Without scaling, models like Logistic Regression and SVM would be unfairly dominated by whichever feature happens to have larger raw numbers, regardless of actual predictive value.

---

## 6. Evaluation — What the Numbers Actually Mean

- **Precision** — of everything the model labeled "OA-risk," what fraction actually were? Matters when false alarms are costly.
- **Recall** — of everything that actually was "OA-risk," what fraction did the model catch? Matters when missing a real case is costly (usually the more important one for a health-screening context).
- **Confusion matrix** — a 2×2 table showing exactly how many healthy/OA-risk cases were correctly vs. incorrectly classified. More informative than a single accuracy number because it shows *which kind* of mistake the model makes, if any.
- **Feature importance** (Random Forest/XGBoost only) — ranks which features most influenced the model's decisions. Useful both for explainability and for sanity-checking that the model is picking up on physiologically sensible signals rather than some data artifact.

---

## 7. The Backend/API — Architecture Reasoning

- **FastAPI** was chosen because it's fast to build with, auto-generates interactive documentation (the Swagger UI), and validates incoming data automatically against a defined schema — catching malformed sensor data before it ever reaches the model.
- **Flat JSON arrays** for sensor data (`gyro: [x,y,z,x,y,z,...]` rather than nested objects) specifically because this is far simpler to generate from embedded C on the ESP32 side — no nested JSON array construction needed in firmware, just a flat buffer of numbers. Same applies to `piezo` and `emg`, both flat single-channel waveforms.
- **SQLite** for storage — a single-file, zero-setup database, appropriate for a hackathon demo. It stores every session (timestamp, risk score, full feature vector) tied to a device ID, which is what makes trend tracking possible.
- **Trend tracking, not just single-session scoring** — a single reading is inherently noisy (bad sensor placement on one particular day, a slightly different walking pattern, etc.). The `/trend` endpoint computes a rolling average and fits a simple linear trend (slope) across recent sessions to detect whether risk is genuinely *worsening*, *improving*, or *stable* over time — which is a far more clinically meaningful signal than any single reading, and mirrors how real longitudinal health monitoring actually works.
- **Explicit error handling (422 responses)** for malformed sensor windows — a health-adjacent app should visibly reject bad data rather than silently producing a meaningless prediction from garbage input.

---

## 8. What This Pipeline Honestly Proves vs. Doesn't

**Proven:**
- The full data flow works end-to-end: raw sensor data (gyro + piezo + EMG) → feature extraction → trained model → risk score → stored session → trend computation → API response.
- The feature engineering is grounded in real, cited biomechanical, VAG, and EMG research concepts, not arbitrary made-up numbers.
- The model comparison and evaluation methodology (cross-validation, multiple algorithms, proper metrics) is methodologically sound.

**Not proven (and shouldn't be claimed):**
- Real-world clinical accuracy — the 1.000 AUC reflects synthetic data separability, not real diagnostic performance.
- Generalization to real human variability — real gait, joint-sound, and EMG signals will overlap between classes far more than the synthetic data does.
- Clinical validity of the "labels" — synthetic labels were authored by rule, not by any clinical diagnosis.

---

## 9. The Honest One-Paragraph Summary (for judges)

*"We built a complete, tested, end-to-end pipeline — from simulated wearable sensor data (motion, joint sound, and muscle activation) through feature extraction grounded in published gait, vibroarthrography, and EMG research, through a multi-model comparison with proper cross-validation, to a working API with session storage and trend tracking. This proves our system architecture and methodology are sound. What it does not yet prove is real-world diagnostic accuracy — that requires real labeled data from real subjects, which is the natural next phase beyond this hackathon, once hardware and a labeling protocol (self-report, clinician screening, or diagnosed volunteers) are in place."*
