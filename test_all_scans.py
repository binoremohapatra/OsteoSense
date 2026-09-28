import os
import requests
import glob
import time

def generate_report():
    base_dir = r"D:\OsteoSense\test_scans"
    url = "http://localhost:8000/analyze-scan"
    
    report_lines = ["# 📊 OsteoSense Medical Scan Analysis Report\n"]
    report_lines.append("Testing the Cloud API (which mirrors the local App's pixel heuristics) across all uploaded X-Ray, MRI, and CT scan images.\n")
    
    scan_folders = ["xray", "mri", "ctscan"]
    
    for folder in scan_folders:
        folder_path = os.path.join(base_dir, folder)
        images = glob.glob(os.path.join(folder_path, "*.*"))
        
        report_lines.append(f"## 📁 {folder.upper()} Scans\n")
        if not images:
            report_lines.append("_No images found in this folder._\n")
            continue
            
        for img_path in images:
            img_name = os.path.basename(img_path)
            report_lines.append(f"### 🖼️ Image: `{img_name}`")
            
            try:
                with open(img_path, 'rb') as f:
                    files = {'image': (img_name, f, 'image/jpeg')}
                    data = {'modality': '', 'joint_type': 'knee'}
                    
                    response = requests.post(url, files=files, data=data)
                    
                    if response.status_code == 200:
                        res = response.json()
                        modality = res.get('modality', 'Unknown')
                        kl = res.get('estimated_kl_grade', 'N/A')
                        risk = res.get('image_risk_score', 0)
                        findings = res.get('findings', [])
                        
                        report_lines.append(f"- **Detected Modality:** {modality}")
                        report_lines.append(f"- **Predicted KL Grade:** {kl}/4")
                        report_lines.append(f"- **Risk Score:** {round(risk*100, 1)}%")
                        report_lines.append("- **Key Findings:**")
                        for finding in findings:
                            report_lines.append(f"  - {finding}")
                        
                        # Biomarkers
                        report_lines.append(f"- **Extracted Factors:**")
                        report_lines.append(f"  - Joint Space Proxy: {res.get('joint_space_proxy')}")
                        report_lines.append(f"  - Osteophyte Score: {res.get('osteophyte_score')}")
                        report_lines.append(f"  - Sclerosis Score: {res.get('sclerosis_score')}")
                        if 'effusion_score' in res:
                            report_lines.append(f"  - Effusion Score: {res.get('effusion_score')}")
                            
                    else:
                        report_lines.append(f"- ❌ Error: Status {response.status_code} - {response.text}")
            except Exception as e:
                report_lines.append(f"- ❌ Error: {str(e)}")
            
            report_lines.append("\n---\n")
            # slight delay to not choke the server
            time.sleep(0.5)

    with open("test_results.md", "w", encoding="utf-8") as f:
        f.write("\n".join(report_lines))
    print("Report generated successfully: test_results.md")

if __name__ == "__main__":
    generate_report()
