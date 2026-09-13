import 'dart:math' as math;
import 'dart:typed_data';
import 'package:fftea/fftea.dart';

class DspUtils {
  
  /// Find peaks in a signal with a minimum distance
  static List<int> findStridePeaks(List<double> signal, int fs) {
    int minDistance = (0.5 * fs).toInt();
    List<int> peaks = [];
    
    for (int i = 1; i < signal.length - 1; i++) {
      if (signal[i] > signal[i - 1] && signal[i] > signal[i + 1]) {
        // It's a peak, check distance
        if (peaks.isEmpty || (i - peaks.last) >= minDistance) {
          peaks.add(i);
        }
      }
    }
    return peaks;
  }

  /// Calculates a simplified Power Spectral Density (PSD) using a single FFT 
  /// (if signal is short) or averaged over segments (simplified Welch).
  static Map<String, dynamic> welchPSD(List<double> signal, int fs, int nperseg) {
    if (signal.isEmpty) return {'freqs': <double>[], 'psd': <double>[]};
    
    // Ensure nperseg is a power of 2 for FFT
    int segmentSize = 1;
    while (segmentSize * 2 <= nperseg) {
      segmentSize *= 2;
    }
    
    if (segmentSize > signal.length) {
      segmentSize = 1;
      while (segmentSize * 2 <= signal.length) {
        segmentSize *= 2;
      }
    }
    
    if (segmentSize < 2) return {'freqs': <double>[], 'psd': <double>[]};

    final fft = FFT(segmentSize);
    final window = Window.hanning(segmentSize);
    
    int step = segmentSize ~/ 2; // 50% overlap
    int numSegments = 0;
    
    List<double> avgPsd = List.filled(segmentSize ~/ 2 + 1, 0.0);
    
    for (int start = 0; start <= signal.length - segmentSize; start += step) {
      List<double> segment = signal.sublist(start, start + segmentSize);
      
      // Apply window
      for (int i = 0; i < segmentSize; i++) {
        segment[i] *= window[i];
      }
      
      final complexArray = fft.realFft(segment);
      final magnitudes = complexArray.discardConjugates().magnitudes();
      
      for (int i = 0; i < avgPsd.length; i++) {
        avgPsd[i] += (magnitudes[i] * magnitudes[i]); 
      }
      numSegments++;
    }
    
    if (numSegments == 0) return {'freqs': <double>[], 'psd': <double>[]};
    
    List<double> freqs = [];
    for (int i = 0; i < avgPsd.length; i++) {
      avgPsd[i] /= numSegments;
      avgPsd[i] /= (fs * segmentSize / 2.0); 
      freqs.add(i * fs / segmentSize);
    }
    
    return {'freqs': freqs, 'psd': avgPsd};
  }

  /// Calculate Shannon Entropy of a PSD
  static double spectralEntropy(List<double> psd) {
    double totalPower = psd.fold(0.0, (a, b) => a + b) + 1e-8;
    double entropy = 0;
    for (double p in psd) {
      double normP = p / totalPower;
      if (normP > 0) {
        entropy -= normP * math.log(normP);
      }
    }
    return entropy;
  }

  /// Calculate analytic envelope using Hilbert Transform
  static List<double> hilbertEnvelope(List<double> signal) {
    if (signal.isEmpty) return [];
    
    int n = 1;
    while (n < signal.length) n *= 2;
    
    List<double> padded = List.from(signal);
    while (padded.length < n) padded.add(0.0);
    
    final fft = FFT(n);
    final freqDomain = fft.realFft(padded);
    
    final complexData = freqDomain.toList(); 
    
    // Analytic signal
    for (int i = 1; i < n ~/ 2; i++) {
      complexData[i] = Float64x2(complexData[i].x * 2, complexData[i].y * 2);
    }
    for (int i = (n ~/ 2) + 1; i < n; i++) {
      complexData[i] = Float64x2(0, 0);
    }
    
    // For IFFT, we need to pass Float64x2List
    Float64x2List cpxList = Float64x2List(n);
    for (int i = 0; i < n; i++) {
      cpxList[i] = Float64x2(complexData[i].x, complexData[i].y);
    }
    
    // NOTE: fftea's realFft does not have an inverse that takes full complex spectra. 
    // We should use the standard complex FFT.
    final cfft = FFT(n); 
    // We need to convert our complexData back to the packed format used by cfft.inPlaceFFT, 
    // wait, fftea has `.inPlaceInverseFft(cpxList)`.
    cfft.inPlaceInverseFft(cpxList);
    
    List<double> envelope = [];
    for (int i = 0; i < signal.length; i++) {
       double real = cpxList[i].x; 
       double imag = cpxList[i].y; 
       envelope.add(math.sqrt(real * real + imag * imag));
    }
    return envelope;
  }
}
