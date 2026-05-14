class Translations {
  static const Map<String, Map<String, String>> ui = {
    // Authentication
    'Login': {'ur': 'لاگ ان', 'en': 'Login'},
    'Sign Up': {'ur': 'رجسٹر کریں', 'en': 'Sign Up'},
    'Phone Number': {'ur': 'فون نمبر', 'en': 'Phone Number'},
    'Full Name': {'ur': 'پورا نام', 'en': 'Full Name'},
    'Enter phone number': {'ur': 'فون نمبر درج کریں', 'en': 'Enter phone number'},
    'Welcome': {'ur': 'خوش آمدید', 'en': 'Welcome'},
    'Don\'t have an account?': {'ur': 'اکاؤنٹ نہیں ہے؟', 'en': "Don't have an account?"},
    'Already have an account?': {'ur': 'پہلے سے اکاؤنٹ ہے؟', 'en': 'Already have an account?'},
    'Create Account': {'ur': 'اکاؤنٹ بنائیں', 'en': 'Create Account'},
    'Start your health journey': {'ur': 'اپنے صحت کے سفر کا آغاز کریں', 'en': 'Start your health journey'},

    // Dashboard
    'Our Services': {'ur': 'ہماری خدمات', 'en': 'Our Services'},
    'Symptom Checker': {'ur': 'علامات کی جانچ', 'en': 'Symptom Checker'},
    'Symptom Analysis': {'ur': 'علامات کا تجزیہ', 'en': 'Symptom Analysis'},
    'X-Ray Analysis': {'ur': 'ایکس رے تجزیہ', 'en': 'X-Ray Analysis'},
    'Lab Report': {'ur': 'لیب رپورٹ', 'en': 'Lab Report'},
    'History': {'ur': 'تاریخچہ', 'en': 'History'},
    'Emergency': {'ur': 'ہنگامی', 'en': 'Emergency'},
    'Health Tips': {'ur': 'صحت کے مشورے', 'en': 'Health Tips'},
    'View All': {'ur': 'تمام دیکھیں', 'en': 'View All'},

    // Profile
    'profile': {'ur': 'پروفائل', 'en': 'Profile'},
    'phone': {'ur': 'فون نمبر', 'en': 'Phone Number'},
    'my_activity': {'ur': 'میری سرگرمیاں', 'en': 'My Activity'},
    'settings': {'ur': 'ترتیبات', 'en': 'Settings'},
    'logout': {'ur': 'لاگ آؤٹ', 'en': 'Logout'},

    // OTP
    'verify_otp': {'ur': 'تصدیق کریں', 'en': 'Verify OTP'},
    'otp_description': {'ur': 'اپنے فون پر بھیجا گیا کوڈ درج کریں', 'en': 'Enter the code sent to your phone'},
    'resend_otp': {'ur': 'دوبارہ بھیجیں', 'en': 'Resend OTP'},

    // Symptom Checker Specifics
    'Identify Yourself': {'ur': 'اپنی شناخت کریں', 'en': 'Identify Yourself'},
    'Select Symptoms': {'ur': 'علامات منتخب کریں', 'en': 'Select Symptoms'},
    'Get Diagnosis': {'ur': 'تشخیص حاصل کریں', 'en': 'Get Diagnosis'},
    'Analyzing...': {'ur': 'تجزیہ ہو رہا ہے...', 'en': 'Analyzing...'},
  };

  static const Map<String, Map<String, String>> symptoms = {
    'high_fever': {'ur': 'تیز بخار', 'en': 'High Fever'},
    'mild_fever': {'ur': 'ہلکا بخار', 'en': 'Mild Fever'},
    'chills': {'ur': 'سردی لگنا', 'en': 'Chills'},
    'shivering': {'ur': 'کپکپاہٹ', 'en': 'Shivering'},
    'sweating': {'ur': 'پسینہ آنا', 'en': 'Sweating'},
    'cough': {'ur': 'کھانسی', 'en': 'Cough'},
    'breathlessness': {'ur': 'سانس پھولنا', 'en': 'Breathlessness'},
    'phlegm': {'ur': 'بلغم', 'en': 'Phlegm'},
    'chest_pain': {'ur': 'سینے میں درد', 'en': 'Chest Pain'},
    'headache': {'ur': 'سر درد', 'en': 'Headache'},
    'fatigue': {'ur': 'تھکاوٹ', 'en': 'Fatigue'},
    'nausea': {'ur': 'متلی', 'en': 'Nausea'},
    'vomiting': {'ur': 'الٹی', 'en': 'Vomiting'},
    'loss_of_appetite': {'ur': 'بھوک نہ لگنا', 'en': 'Loss of Appetite'},
    'abdominal_pain': {'ur': 'پیٹ میں درد', 'en': 'Abdominal Pain'},
    'diarrhoea': {'ur': 'اسہال', 'en': 'Diarrhoea'},
    'joint_pain': {'ur': 'جوڑوں کا درد', 'en': 'Joint Pain'},
    'muscle_pain': {'ur': 'پٹھوں کا درد', 'en': 'Muscle Pain'},
    'back_pain': {'ur': 'کمر درد', 'en': 'Back Pain'},
    'yellowish_skin': {'ur': 'جلد کا پیلا پڑنا', 'en': 'Yellowish Skin'},
    'yellowing_of_eyes': {'ur': 'آنکھوں کا پیلا پڑنا', 'en': 'Yellowing of Eyes'},
    'dark_urine': {'ur': 'گہرا پیشاب', 'en': 'Dark Urine'},
    'skin_rash': {'ur': 'جلد پر دانے', 'en': 'Skin Rash'},
    'itching': {'ur': 'خارش', 'en': 'Itching'},
    'weight_loss': {'ur': 'وزن کم ہونا', 'en': 'Weight Loss'},
    'dizziness': {'ur': 'چکر آنا', 'en': 'Dizziness'},
    'stiff_neck': {'ur': 'گردن میں اکڑاہٹ', 'en': 'Stiff Neck'},
    'excessive_hunger': {'ur': 'بہت زیادہ بھوک', 'en': 'Excessive Hunger'},
    'polyuria': {'ur': 'بار بار پیشاب آنا', 'en': 'Polyuria'},
    'blurred_and_distorted_vision': {'ur': 'دھندلا نظر آنا', 'en': 'Blurred Vision'},
    'continuous_sneezing': {'ur': 'مسلسل چھینکیں', 'en': 'Continuous Sneezing'},
    'acidity': {'ur': 'تیزابیت', 'en': 'Acidity'},
    'burning_micturition': {'ur': 'پیشاب میں جلن', 'en': 'Burning Micturition'},
    'runny_nose': {'ur': 'ناک بہنا', 'en': 'Runny Nose'},
  };

  static const Map<String, Map<String, String>> mcq = {
    "Duration of Fever?": {"ur": "بخار کب سے ہے؟", "en": "Duration of Fever?", "ro": "Bukhar kab se hai?"},
    "Temperature level?": {"ur": "بخار کی شدت؟", "en": "Temperature level?", "ro": "Bukhar ki shiddat?"},
    "Type of Cough?": {"ur": "کھانسی کی قسم؟", "en": "Type of Cough?", "ro": "Khansi ki qisam?"},
    "With phlegm?": {"ur": "کیا بلغم بھی ہے؟", "en": "With phlegm?", "ro": "Kya balgham bhi hai?"},
    "Pain Description?": {"ur": "درد کی کیفیت؟", "en": "Pain Description?", "ro": "Dard ki kaifiyat?"},
    "No": {"ur": "نہیں", "en": "No", "ro": "Nahi"},
    "Yes": {"ur": "ہاں", "en": "Yes", "ro": "Haan"},
    "Mild": {"ur": "ہلکا", "en": "Mild", "ro": "Halka"},
    "Moderate": {"ur": "درمیانہ", "en": "Moderate", "ro": "Darmiyana"},
    "Severe": {"ur": "شدید", "en": "Severe", "ro": "Shadeed"},
    "1-2 days": {"ur": "1-2 دن", "en": "1-2 days", "ro": "1-2 din"},
    "3-5 days": {"ur": "3-5 دن", "en": "3-5 days", "ro": "3-5 din"},
    "5+ days": {"ur": "5 دن سے زیادہ", "en": "5+ days", "ro": "5 din se zyada"},
    "Dry": {"ur": "خشک", "en": "Dry", "ro": "Khushk"},
    "Wet": {"ur": "بلغم والی", "en": "Wet", "ro": "Balgham wali"},
    "Sharp": {"ur": "تیز", "en": "Sharp", "ro": "Taiz"},
    "Dull": {"ur": "ہلکا میٹھا", "en": "Dull", "ro": "Halka meetha"},
  };

  static String t(String text, String lang) => get(text, lang);

  static String get(String text, String lang) {
    if (lang == 'en') return text;
    if (ui.containsKey(text)) return ui[text]![lang] ?? text;
    if (mcq.containsKey(text)) return mcq[text]![lang] ?? text;
    if (symptoms.containsKey(text)) return symptoms[text]![lang] ?? text;
    String lower = text.toLowerCase();
    if (ui.containsKey(lower)) return ui[lower]![lang] ?? text;
    
    return text;
  }
}
