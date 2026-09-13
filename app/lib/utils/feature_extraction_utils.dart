import 'dart:math' as math;
import 'dsp_utils.dart';

class FeatureExtractionUtils {
  static const int GYRO_FS = 100;
  static const int PIEZO_FS = 4000;
  static const int EMG_FS = 1000;

  static List<double> extractAllFeatures(List<double> gyroX, List<double> gyroY, List<double> gyroZ, List<double> piezo, List<double> emg) {
    var gaitFeats = _extractGaitFeatures(gyroX, gyroY, gyroZ, GYRO_FS);
    var piezoFeats = _extractPiezoFeatures(piezo, PIEZO_FS);
    var emgFeats = _extractEmgFeatures(emg, EMG_FS);

    // Matches feature_columns.json order exactly
    return [
      gaitFeats['cadence_hz'] ?? 0.0,
      gaitFeats['stride_time_mean'] ?? 0.0,
      gaitFeats['stride_time_cv'] ?? 0.0,
      gaitFeats['jerk_rms_flex'] ?? 0.0,
      gaitFeats['gyro_rms_flex'] ?? 0.0,
      gaitFeats['gyro_peak_flex'] ?? 0.0,
      gaitFeats['gyro_std_flex'] ?? 0.0,
      gaitFeats['jerk_rms_abad'] ?? 0.0,
      gaitFeats['gyro_rms_abad'] ?? 0.0,
      gaitFeats['gyro_peak_abad'] ?? 0.0,
      gaitFeats['gyro_std_abad'] ?? 0.0,
      gaitFeats['jerk_rms_rot'] ?? 0.0,
      gaitFeats['gyro_rms_rot'] ?? 0.0,
      gaitFeats['gyro_peak_rot'] ?? 0.0,
      gaitFeats['gyro_std_rot'] ?? 0.0,
      gaitFeats['gait_high_freq_ratio'] ?? 0.0,
      gaitFeats['stride_amplitude_cv'] ?? 0.0,
      piezoFeats['piezo_total_power'] ?? 0.0,
      piezoFeats['band_low_0_100'] ?? 0.0,
      piezoFeats['band_mid_100_200'] ?? 0.0,
      piezoFeats['band_crepitus_200_800'] ?? 0.0,
      piezoFeats['band_high_800_2000'] ?? 0.0,
      piezoFeats['spectral_entropy'] ?? 0.0,
      piezoFeats['dominant_freq'] ?? 0.0,
      piezoFeats['zero_crossing_rate'] ?? 0.0,
      piezoFeats['n_transient_bursts'] ?? 0.0,
      piezoFeats['burst_energy_ratio'] ?? 0.0,
      piezoFeats['melband_0'] ?? 0.0,
      piezoFeats['melband_1'] ?? 0.0,
      piezoFeats['melband_2'] ?? 0.0,
      piezoFeats['melband_3'] ?? 0.0,
      piezoFeats['melband_4'] ?? 0.0,
      piezoFeats['melband_5'] ?? 0.0,
      emgFeats['emg_rms'] ?? 0.0,
      emgFeats['emg_mav'] ?? 0.0,
      emgFeats['emg_std'] ?? 0.0,
      emgFeats['emg_waveform_length'] ?? 0.0,
      emgFeats['emg_zero_crossing_rate'] ?? 0.0,
      emgFeats['emg_median_freq'] ?? 0.0,
      emgFeats['emg_mean_freq'] ?? 0.0,
      emgFeats['emg_low_band_ratio'] ?? 0.0,
      emgFeats['emg_high_band_ratio'] ?? 0.0,
      emgFeats['emg_duty_cycle'] ?? 0.0,
      emgFeats['emg_activation_amplitude_cv'] ?? 0.0,
    ];
  }

  static Map<String, double> _extractGaitFeatures(List<double> flex, List<double> abad, List<double> rot, int fs) {
    if (flex.isEmpty) return {};
    
    Map<String, double> feats = {};
    
    var peaks = DspUtils.findStridePeaks(flex, fs);
    if (peaks.length >= 3) {
      List<double> strideIntervals = [];
      for (int i = 1; i < peaks.length; i++) {
        strideIntervals.add((peaks[i] - peaks[i-1]) / fs);
      }
      double meanStride = _mean(strideIntervals);
      feats["cadence_hz"] = 1.0 / meanStride;
      feats["stride_time_mean"] = meanStride;
      feats["stride_time_cv"] = _std(strideIntervals, meanStride) / (meanStride + 1e-8);
      
      List<double> peakVals = peaks.map((p) => flex[p]).toList();
      double meanPeak = _mean(peakVals);
      feats["stride_amplitude_cv"] = _std(peakVals, meanPeak) / (meanPeak.abs() + 1e-8);
    } else {
      feats["cadence_hz"] = 0.0;
      feats["stride_time_mean"] = 0.0;
      feats["stride_time_cv"] = 0.0;
      feats["stride_amplitude_cv"] = 0.0;
    }

    _processAxis(feats, flex, "flex", fs);
    _processAxis(feats, abad, "abad", fs);
    _processAxis(feats, rot, "rot", fs);

    var psdRes = DspUtils.welchPSD(flex, fs, 256);
    List<double> freqs = psdRes['freqs'];
    List<double> psd = psdRes['psd'];
    
    double totalPower = psd.fold(0.0, (a, b) => a + b) + 1e-8;
    double highFreqPower = 0.0;
    for (int i = 0; i < freqs.length; i++) {
      if (freqs[i] > fs / 4.0) {
        highFreqPower += psd[i];
      }
    }
    feats["gait_high_freq_ratio"] = highFreqPower / totalPower;

    return feats;
  }

  static void _processAxis(Map<String, double> feats, List<double> axis, String name, int fs) {
    List<double> jerk = [];
    for (int i = 1; i < axis.length; i++) {
      jerk.add((axis[i] - axis[i-1]) * fs);
    }
    feats["jerk_rms_$name"] = _rms(jerk);
    feats["gyro_rms_$name"] = _rms(axis);
    double peak = 0.0;
    for (var v in axis) { if (v.abs() > peak) peak = v.abs(); }
    feats["gyro_peak_$name"] = peak;
    feats["gyro_std_$name"] = _std(axis, _mean(axis));
  }

  static Map<String, double> _extractPiezoFeatures(List<double> piezo, int fs) {
    if (piezo.isEmpty) return {};
    Map<String, double> feats = {};
    
    var psdRes = DspUtils.welchPSD(piezo, fs, 1024);
    List<double> freqs = psdRes['freqs'];
    List<double> psd = psdRes['psd'];
    
    double totalPower = psd.fold(0.0, (a, b) => a + b) + 1e-8;
    feats["piezo_total_power"] = totalPower;
    
    feats["band_low_0_100"] = _bandEnergy(freqs, psd, 0, 100) / totalPower;
    feats["band_mid_100_200"] = _bandEnergy(freqs, psd, 100, 200) / totalPower;
    feats["band_crepitus_200_800"] = _bandEnergy(freqs, psd, 200, 800) / totalPower;
    feats["band_high_800_2000"] = _bandEnergy(freqs, psd, 800, math.min(2000.0, fs / 2)) / totalPower;
    
    feats["spectral_entropy"] = DspUtils.spectralEntropy(psd);
    
    double maxPsd = -1;
    double domFreq = 0;
    for (int i = 0; i < psd.length; i++) {
      if (psd[i] > maxPsd) { maxPsd = psd[i]; domFreq = freqs[i]; }
    }
    feats["dominant_freq"] = domFreq;
    
    int zc = 0;
    for (int i = 1; i < piezo.length; i++) {
      if (piezo[i].sign != piezo[i-1].sign && piezo[i-1] != 0) zc++;
    }
    feats["zero_crossing_rate"] = zc / piezo.length;
    
    var envelope = DspUtils.hilbertEnvelope(piezo);
    if (envelope.isNotEmpty) {
      double meanEnv = _mean(envelope);
      double stdEnv = _std(envelope, meanEnv);
      double threshold = meanEnv + 3 * stdEnv;
      
      int nBursts = 0;
      double burstEnergy = 0.0;
      double totalEnvEnergy = 0.0;
      bool inBurst = false;
      
      for (double e in envelope) {
        totalEnvEnergy += e * e;
        if (e > threshold) {
          burstEnergy += e * e;
          if (!inBurst) { nBursts++; inBurst = true; }
        } else {
          inBurst = false;
        }
      }
      feats["n_transient_bursts"] = nBursts.toDouble();
      feats["burst_energy_ratio"] = burstEnergy / (totalEnvEnergy + 1e-8);
    } else {
      feats["n_transient_bursts"] = 0;
      feats["burst_energy_ratio"] = 0;
    }
    
    // Mel bands
    double hzToMel(double f) => 2595 * math.log(1 + f / 700) / math.ln10;
    double melToHz(double m) => 700 * (math.pow(10, m / 2595) - 1);
    
    int nBands = 6;
    double fmax = 1000.0;
    List<double> melEdges = [];
    double m0 = hzToMel(0);
    double m1 = hzToMel(fmax);
    double step = (m1 - m0) / (nBands + 1);
    for (int i = 0; i < nBands + 2; i++) {
      melEdges.add(melToHz(m0 + i * step));
    }
    
    for (int i = 0; i < nBands; i++) {
      double lo = melEdges[i];
      double hi = melEdges[i+2];
      double e = _bandEnergy(freqs, psd, lo, hi);
      feats["melband_$i"] = math.log(1 + e); // log1p
    }
    
    return feats;
  }

  static Map<String, double> _extractEmgFeatures(List<double> emg, int fs) {
    if (emg.isEmpty) return {};
    Map<String, double> feats = {};
    
    feats["emg_rms"] = _rms(emg);
    feats["emg_mav"] = _mean(emg.map((e) => e.abs()).toList());
    double meanEmg = _mean(emg);
    feats["emg_std"] = _std(emg, meanEmg);
    
    double wl = 0;
    for (int i = 1; i < emg.length; i++) wl += (emg[i] - emg[i-1]).abs();
    feats["emg_waveform_length"] = wl;
    
    int zc = 0;
    for (int i = 1; i < emg.length; i++) {
      if (emg[i].sign != emg[i-1].sign && emg[i-1] != 0) zc++;
    }
    feats["emg_zero_crossing_rate"] = zc / emg.length;
    
    var psdRes = DspUtils.welchPSD(emg, fs, 512);
    List<double> freqs = psdRes['freqs'];
    List<double> psd = psdRes['psd'];
    double totalPower = psd.fold(0.0, (a, b) => a + b) + 1e-8;
    
    double cumulativePower = 0;
    double medianFreq = freqs.last;
    for (int i = 0; i < psd.length; i++) {
      cumulativePower += psd[i];
      if (cumulativePower >= totalPower / 2.0) {
        medianFreq = freqs[i];
        break;
      }
    }
    feats["emg_median_freq"] = medianFreq;
    
    double meanFreqPower = 0;
    for (int i = 0; i < psd.length; i++) meanFreqPower += freqs[i] * psd[i];
    feats["emg_mean_freq"] = meanFreqPower / totalPower;
    
    feats["emg_low_band_ratio"] = _bandEnergy(freqs, psd, 20, 100) / totalPower;
    feats["emg_high_band_ratio"] = _bandEnergy(freqs, psd, 100, 450) / totalPower;
    
    var envelope = DspUtils.hilbertEnvelope(emg);
    if (envelope.isNotEmpty) {
      double meanEnv = _mean(envelope);
      double stdEnv = _std(envelope, meanEnv);
      double threshold = meanEnv + 0.5 * stdEnv;
      
      int activeCount = 0;
      List<double> activeVals = [];
      for (double e in envelope) {
        if (e > threshold) {
          activeCount++;
          activeVals.add(e);
        }
      }
      feats["emg_duty_cycle"] = activeCount / envelope.length;
      
      if (activeVals.isNotEmpty) {
        double mAct = _mean(activeVals);
        feats["emg_activation_amplitude_cv"] = _std(activeVals, mAct) / (mAct + 1e-8);
      } else {
        feats["emg_activation_amplitude_cv"] = 0.0;
      }
    } else {
      feats["emg_duty_cycle"] = 0.0;
      feats["emg_activation_amplitude_cv"] = 0.0;
    }
    
    return feats;
  }

  static double _bandEnergy(List<double> freqs, List<double> psd, double lo, double hi) {
    double sum = 0;
    for (int i = 0; i < freqs.length; i++) {
      if (freqs[i] >= lo && freqs[i] < hi) sum += psd[i];
    }
    return sum;
  }
  
  static double _mean(List<double> vals) {
    if (vals.isEmpty) return 0;
    return vals.fold(0.0, (a, b) => a + b) / vals.length;
  }
  
  static double _std(List<double> vals, double mean) {
    if (vals.isEmpty) return 0;
    double sumSq = vals.fold(0.0, (a, b) => a + (b - mean) * (b - mean));
    return math.sqrt(sumSq / vals.length);
  }
  
  static double _rms(List<double> vals) {
    if (vals.isEmpty) return 0;
    double sumSq = vals.fold(0.0, (a, b) => a + b * b);
    return math.sqrt(sumSq / vals.length);
  }
}
