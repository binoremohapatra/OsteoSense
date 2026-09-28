import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/medical_image_service.dart';

void main() {
  test('Single Patient: Questionnaire + Image Test', () async {
    final svc = MedicalImageService();

    // -- SINGLE PATIENT DATA --
    const patientName    = 'Ravi Kumar';
    const painLevel      = 7;
    const stiffness      = '>60';
    const swelling       = true;
    const pastInjury     = 'knee_sprain';
    const mriKlGrade     = 3;
    const symLocking     = true;
    const symClicking    = true;
    const symGrinding    = true;
    const symInstability = false;
    const gaitVariance   = 3.2;
    const imagePath      = 'D:/OsteoSense/test_scans/xray/images (6).jpg';

    print('');
    print('OSTEOSENSE FULL SCREENING - SINGLE PATIENT TEST');
    print('Patient: ' + patientName);
    print('');

    // STEP 1 - Clinical
    print('[STEP 1] Clinical Questionnaire:');
    print('  Pain Level:    ' + painLevel.toString() + '/10');
    print('  Stiffness:     ' + stiffness + ' min');
    print('  Swelling:      ' + swelling.toString());
    print('  Past Injury:   ' + pastInjury);
    print('  MRI KL Grade:  ' + mriKlGrade.toString() + '/4');
    print('  Locking=' + symLocking.toString() + ' Clicking=' + symClicking.toString() + ' Grinding=' + symGrinding.toString() + ' Instability=' + symInstability.toString());

    // STEP 2 - Gait
    const gv = gaitVariance;
    final gs = (gv / 4.0).clamp(0.0, 1.0) * 0.15;
    print('');
    print('[STEP 2] Gait Analysis:');
    print('  Variance: ' + gv.toString() + '  Score: ' + (gs * 100).toStringAsFixed(1) + '%');

    // STEP 3 - Clinical score calculation
    double cs = 0.0;
    final fs = <String>[];
    cs += painLevel / 10.0 * 0.30;
    if (painLevel >= 7) fs.add('Severe pain level');
    else if (painLevel >= 4) fs.add('Moderate pain level');
    if (stiffness == '>60') { cs += 0.25; fs.add('Prolonged stiffness >60 min'); }
    else if (stiffness == '30-60') { cs += 0.20; fs.add('Stiffness 30-60 min'); }
    else if (stiffness == '<30') { cs += 0.10; fs.add('Mild stiffness <30 min'); }
    if (swelling) { cs += 0.15; fs.add('Joint swelling present'); }
    cs += 0.15; fs.add('History: ' + pastInjury);
    if (mriKlGrade == 4) { cs += 0.50; fs.add('Severe degeneration Grade 4'); }
    else if (mriKlGrade == 3) { cs += 0.35; fs.add('Moderate degeneration Grade 3'); }
    else if (mriKlGrade == 2) { cs += 0.20; fs.add('Mild degeneration Grade 2'); }
    if (symLocking || symGrinding || symClicking) { cs += 0.15; fs.add('Mechanical symptoms (locking/clicking/grinding)'); }
    if (symInstability) { cs += 0.10; fs.add('Joint instability'); }
    cs += gs;
    if (gs > 0.08) fs.add('Abnormal gait pattern detected');
    cs = cs.clamp(0.0, 1.0);
    final cr = cs >= 0.6 ? 'HIGH' : cs >= 0.25 ? 'MEDIUM' : 'LOW';
    print('');
    print('[STEP 3] Clinical Risk Score:');
    print('  Score: ' + (cs * 100).toStringAsFixed(1) + '%  =>  ' + cr + ' RISK');
    print('  Contributing Factors:');
    for (final f in fs) { print('    - ' + f); }

    // STEP 4 - Image analysis
    print('');
    print('[STEP 4] Medical Image Analysis:');
    print('  File: ' + imagePath.split('/').last);
    final r = await svc.analyzeImage(imagePath: imagePath);
    print('  Modality:    ' + r.modalityLabel + ' (' + (r.modalityConfidence * 100).toStringAsFixed(0) + '% confidence)');
    print('  KL Grade:    ' + r.suggestedKLGrade.toString() + '/4');
    print('  Image Risk:  ' + (r.imageRiskScore * 100).toStringAsFixed(1) + '%');
    print('  Biomarkers:');
    print('    Joint Space: ' + r.biomarkers.jointSpaceProxy.toStringAsFixed(3));
    print('    Osteophyte:  ' + r.biomarkers.osteophyteScore.toStringAsFixed(3));
    print('    Sclerosis:   ' + r.biomarkers.sclerosisScore.toStringAsFixed(3));
    print('    Effusion:    ' + r.biomarkers.effusionScore.toStringAsFixed(3));
    print('  Findings:');
    for (final f in r.findings) { print('    > ' + f); }

    // STEP 5 - Combined final
    final combined = (cs * 0.60 + r.imageRiskScore * 0.40).clamp(0.0, 1.0);
    final tag = combined >= 0.60 ? 'HIGH RISK' : combined >= 0.30 ? 'MEDIUM RISK' : 'LOW RISK';
    print('');
    print('=============================================');
    print('FINAL COMBINED RESULT');
    print('=============================================');
    print('  Clinical Score  (60%): ' + (cs * 100).toStringAsFixed(1) + '%');
    print('  Image Score     (40%): ' + (r.imageRiskScore * 100).toStringAsFixed(1) + '%');
    print('  -------------------------------------------');
    print('  FINAL SCORE:  ' + (combined * 100).toStringAsFixed(1) + '%');
    print('  FINAL RISK:   ' + tag);
    print('=============================================');
  });
}