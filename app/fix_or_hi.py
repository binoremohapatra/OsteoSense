import json

# Odia translations
or_translations = {
    "past_medical_history": "ଅତୀତର ଚିକିତ୍ସା ଇତିହାସ",
    "previous_diagnosis_of_arthritis": "ପୂର୍ବରୁ ଆର୍ଥ୍ରାଇଟିସ୍ ଚିହ୍ନଟ ହୋଇଛି",
    "previous_joint_pain_episodes": "ପୂର୍ବରୁ ଗଣ୍ଠି ବିନ୍ଧା ହୋଇଛି",
    "chronic_joint_problems": "ଦୀର୍ଘକାଳୀନ ଗଣ୍ଠି ସମସ୍ୟା",
    "previous_joint_inflammation_swelling": "ପୂର୍ବରୁ ଗଣ୍ଠି ଫୁଲିବା ବା ପ୍ରଦାହ ହୋଇଛି",
    "history_of_injury_to_this_joint": "ଏହି ଗଣ୍ଠିରେ ଆଘାତର ଇତିହାସ",
    "for_side_joint": "{side} {joint} ପାଇଁ",
    "past_surgeries": "ଅତୀତର ଅସ୍ତ୍ରୋପଚାର",
    "have_you_had_surgery_on_this_joint": "ଆପଣ ଏହି ଗଣ୍ଠିରେ ଅସ୍ତ୍ରୋପଚାର କରିଛନ୍ତି କି?",
    "surgery_details": "ଅସ୍ତ୍ରୋପଚାର ବିବରଣୀ",
    "type_of_surgery": "ଅସ୍ତ୍ରୋପଚାରର ପ୍ରକାର",
    "are_there_implants_hardware": "କୌଣସି ଇମ୍ପ୍ଲାଣ୍ଟ/ହାର୍ଡୱେର୍ ଅଛି କି?",
    "question_4_mri": "ପ୍ରଶ୍ନ ୪: ଏମ୍.ଆର୍.ଆଇ ରିପୋର୍ଟ",
    "mri_scan_medical_report": "ଏମ୍.ଆର୍.ଆଇ ସ୍କାନ୍ / ମେଡିକାଲ୍ ରିପୋର୍ଟ",
    "mri_hint": "ଯଦି ରୋଗୀଙ୍କର ଏମ୍.ଆର୍.ଆଇ ରିପୋର୍ଟ ଅଛି, ତେବେ ଗ୍ରେଡ୍ (KL Grade) ବାଛନ୍ତୁ। ଏହା ମେସିନ୍ ଲର୍ଣ୍ଣିଂ ମଡେଲ୍ ପାଇଁ ବ୍ୟବହାର ହେବ।",
    "mri_normal_none": "ସାଧାରଣ / ନାହିଁ",
    "mri_normal_desc": "କୌଣସି ଏମ୍.ଆର୍.ଆଇ ନାହିଁ କିମ୍ବା ସୁସ୍ଥ ଗଣ୍ଠି",
    "mri_grade1_doubtful": "ଗ୍ରେଡ୍ ୧: ସନ୍ଦେହଜନକ",
    "mri_grade1_desc": "ଗଣ୍ଠି ସ୍ଥାନ ସାମାନ୍ୟ ସଂକୀର୍ଣ୍ଣ ଥିବାର ସନ୍ଦେହ",
    "mri_grade2_mild": "ଗ୍ରେଡ୍ ୨: ସାମାନ୍ୟ",
    "mri_grade2_desc": "ନିଶ୍ଚିତ ଓଷ୍ଟିଓଫାଇଟ୍ସ, ସମ୍ଭାବ୍ୟ ସଂକୀର୍ଣ୍ଣତା",
    "mri_grade3_moderate": "ଗ୍ରେଡ୍ ୩: ମଧ୍ୟମ",
    "mri_grade3_desc": "ଏକାଧିକ ଓଷ୍ଟିଓଫାଇଟ୍ସ, ନିଶ୍ଚିତ ସଂକୀର୍ଣ୍ଣତା",
    "mri_grade4_severe": "ଗ୍ରେଡ୍ ୪: ଗୁରୁତର",
    "mri_grade4_desc": "ବଡ଼ ଓଷ୍ଟିଓଫାଇଟ୍ସ, ଗୁରୁତର ସଂକୀର୍ଣ୍ଣତା",
    "question_5_symptoms": "ପ୍ରଶ୍ନ ୫: ଲକ୍ଷଣ",
    "expanded_symptoms": "ବିସ୍ତୃତ ଲକ୍ଷଣ",
    "expanded_symptoms_hint": "ଆପଣ ଅନୁଭବ କରୁଥିବା ଅନ୍ୟ କୌଣସି ଲକ୍ଷଣ ବାଛନ୍ତୁ।",
    "pain_characteristics": "ଯନ୍ତ୍ରଣାର ପ୍ରକାର",
    "pain_sharp": "ତୀବ୍ର ଯନ୍ତ୍ରଣା",
    "pain_dull": "ମୃଦୁ ଯନ୍ତ୍ରଣା",
    "pain_burning": "ଜଳାପୋଡ଼ା ଯନ୍ତ୍ରଣା",
    "pain_aching": "କ୍ରମାଗତ ବିନ୍ଧା",
    "pain_stabbing": "ଛୁରୀ ଭୁସିଲା ପରି ଯନ୍ତ୍ରଣା",
    "pain_throbbing": "ଦପ୍ ଦପ୍ ଯନ୍ତ୍ରଣା",
    "stiffness_triggers": "କଠିନତା ବଢ଼ାଉଥିବା କାରଣ",
    "stiff_morning": "ସକାଳେ",
    "stiff_after_sitting": "ବସିବା ପରେ",
    "stiff_after_inactivity": "ନିଷ୍କ୍ରିୟତା ପରେ",
    "stiff_after_exercise": "ବ୍ୟାୟାମ ପରେ",
    "other_observations": "ଅନ୍ୟାନ୍ୟ ଲକ୍ଷଣ",
    "sym_warmth": "ଗରମ ଲାଗିବା",
    "sym_redness": "ନାଲି ପଡ଼ିବା",
    "sym_tenderness": "ଛୁଇଁଲେ ବିନ୍ଧିବା",
    "sym_clicking": "କଟ୍ କଟ୍ ଶବ୍ଦ ହେବା",
    "sym_grinding": "ଘସି ହେବା ଶବ୍ଦ ହେବା",
    "sym_locking": "ଗଣ୍ଠି ଲାଗିଯିବା",
    "sym_giving_way": "ଗଣ୍ଠି ଖସିଯିବା ପରି ଲାଗିବା",
    "sym_instability": "ଅସ୍ଥିରତା",
    "sym_reduced_mobility": "ଗତିଶୀଳତା କମିଯିବା"
}

# Hindi translations
hi_translations = {
    "past_medical_history": "पिछला चिकित्सा इतिहास",
    "previous_diagnosis_of_arthritis": "गठिया का पूर्व निदान",
    "previous_joint_pain_episodes": "पिछले जोड़ों के दर्द के एपिसोड",
    "chronic_joint_problems": "क्रोनिक जोड़ों की समस्याएं",
    "previous_joint_inflammation_swelling": "जोड़ों में सूजन/प्रदाह",
    "history_of_injury_to_this_joint": "इस जोड़ में चोट का इतिहास",
    "for_side_joint": "{side} {joint} के लिए",
    "past_surgeries": "पिछली सर्जरी",
    "have_you_had_surgery_on_this_joint": "क्या आपकी इस जोड़ पर सर्जरी हुई है?",
    "surgery_details": "सर्जरी का विवरण",
    "type_of_surgery": "सर्जरी का प्रकार",
    "are_there_implants_hardware": "क्या कोई इम्प्लांट/हार्डवेयर मौजूद है?",
    "question_4_mri": "प्रश्न 4: एमआरआई रिपोर्ट",
    "mri_scan_medical_report": "एमआरआई स्कैन / मेडिकल रिपोर्ट",
    "mri_hint": "यदि मरीज की एमआरआई रिपोर्ट है, तो ग्रेड (KL Grade) चुनें। यह डेटा हमारे ML मॉडल द्वारा उपयोग किया जाएगा।",
    "mri_normal_none": "सामान्य / कोई नहीं",
    "mri_normal_desc": "कोई एमआरआई नहीं या स्वस्थ जोड़",
    "mri_grade1_doubtful": "ग्रेड 1: संदिग्ध",
    "mri_grade1_desc": "संदिग्ध जोड़ स्थान का संकुचन",
    "mri_grade2_mild": "ग्रेड 2: हल्का",
    "mri_grade2_desc": "निश्चित ओस्टियोफाइट्स, संभावित संकुचन",
    "mri_grade3_moderate": "ग्रेड 3: मध्यम",
    "mri_grade3_desc": "कई ओस्टियोफाइट्स, निश्चित संकुचन",
    "mri_grade4_severe": "ग्रेड 4: गंभीर",
    "mri_grade4_desc": "बड़े ओस्टियोफाइट्स, गंभीर संकुचन",
    "question_5_symptoms": "प्रश्न 5: लक्षण",
    "expanded_symptoms": "विस्तृत लक्षण",
    "expanded_symptoms_hint": "यदि आप कोई अन्य लक्षण अनुभव कर रहे हैं तो उन्हें चुनें।",
    "pain_characteristics": "दर्द की विशेषताएं",
    "pain_sharp": "तेज़ दर्द",
    "pain_dull": "हल्का दर्द",
    "pain_burning": "जलन",
    "pain_aching": "लगातार दर्द",
    "pain_stabbing": "चुभने वाला दर्द",
    "pain_throbbing": "टीस मारना",
    "stiffness_triggers": "अकड़न बढ़ने के कारण",
    "stiff_morning": "सुबह",
    "stiff_after_sitting": "बैठने के बाद",
    "stiff_after_inactivity": "निष्क्रियता के बाद",
    "stiff_after_exercise": "व्यायाम के बाद",
    "other_observations": "अन्य लक्षण",
    "sym_warmth": "गर्म लगना",
    "sym_redness": "लाल होना",
    "sym_tenderness": "छूने पर दर्द (टेंडरनेस)",
    "sym_clicking": "क्लिकिंग की आवाज़",
    "sym_grinding": "घिसने की आवाज़",
    "sym_locking": "जोड़ का लॉक होना",
    "sym_giving_way": "जोड़ खिसकना",
    "sym_instability": "अस्थिरता",
    "sym_reduced_mobility": "गतिशीलता में कमी"
}

def update_lang(lang_code, translations_dict):
    path = f"d:/OsteoSense/app/assets/translations/{lang_code}.json"
    with open(path, 'r', encoding='utf-8-sig') as f:
        data = json.load(f)
    
    updated = 0
    for k, v in translations_dict.items():
        data[k] = v
        updated += 1
        
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"Updated {updated} keys in {lang_code}.json")

update_lang('or', or_translations)
update_lang('hi', hi_translations)
