LAB_METADATA = {

    # ================= CBC =================
    "hemoglobin": {
        "aliases": ["hb", "hemoglobin", "haemoglobin"],
        "min": 12.0, "max": 17.5, "unit": "g/dL",
        "name_en": "Hemoglobin",
        "name_ur": "ہیموگلوبن (خون کی مقدار)",
        "advice_low": "خون کی کمی (انیمیا) ہو سکتی ہے۔ آئرن والی غذا استعمال کریں۔",
        "advice_high": "خون زیادہ ہے، ڈاکٹر سے رجوع کریں۔",
        "advice_normal": "ہیموگلوبن نارمل ہے۔"
    },

    "wbc": {
        "aliases": ["wbc", "tlc", "white blood cells", "wbc count", "wbc / tlc", "wbc/tlc", "total wbc"],
        "min": 4000, "max": 11000, "unit": "/uL",
        "name_en": "White Blood Cells (WBC)",
        "name_ur": "سفید خون کے خلیے (WBC)",
        "advice_low": "مدافعتی نظام کمزور ہو سکتا ہے۔",
        "advice_high": "انفیکشن یا سوزش ہو سکتی ہے۔",
        "advice_normal": "WBC نارمل ہے۔"
    },

    "platelets": {
        "aliases": ["platelet", "plt", "platelet count", "thrombocytes"],
        "min": 150000, "max": 450000, "unit": "/uL",
        "name_en": "Platelets",
        "name_ur": "پلیٹلیٹس",
        "advice_low": "پلیٹلیٹس کم ہیں، ڈینگی یا انفیکشن ہو سکتا ہے۔",
        "advice_high": "پلیٹلیٹس زیادہ ہیں، ڈاکٹر سے مشورہ کریں۔",
        "advice_normal": "پلیٹلیٹس نارمل ہیں۔"
    },

    "rbc": {
        "aliases": ["rbc", "red blood cells", "total rbc", "erythrocytes"],
        "min": 4.0, "max": 6.0, "unit": "million/uL",
        "name_en": "Red Blood Cells (RBC)",
        "name_ur": "سرخ خون کے خلیے (RBC)",
        "advice_low": "خون کی کمی ہو سکتی ہے۔",
        "advice_high": "ڈی ہائیڈریشن یا دیگر مسئلہ ہو سکتا ہے۔",
        "advice_normal": "RBC نارمل ہے۔"
    },

    # ── NEW: CBC sub-tests ──────────────────────────────────────
    "hematocrit": {
        "aliases": ["hct", "hematocrit", "haematocrit", "pcv", "packed cell volume"],
        "min": 36.0, "max": 46.0, "unit": "%",
        "name_en": "Hematocrit (HCT)",
        "name_ur": "ہیماٹوکریٹ",
        "advice_low": "خون کی کمی کی علامت ہو سکتی ہے۔",
        "advice_high": "ڈی ہائیڈریشن ہو سکتی ہے۔",
        "advice_normal": "نارمل ہے۔"
    },

    "mcv": {
        "aliases": ["mcv", "mean corpuscular volume", "mean cell volume"],
        "min": 80.0, "max": 100.0, "unit": "fL",
        "name_en": "MCV (Mean Corpuscular Volume)",
        "name_ur": "MCV",
        "advice_low": "آئرن کی کمی کی انیمیا ہو سکتی ہے۔",
        "advice_high": "وٹامن بی 12 یا فولک ایسڈ کی کمی ہو سکتی ہے۔",
        "advice_normal": "نارمل ہے۔"
    },

    "mch": {
        "aliases": ["mch", "mean corpuscular hemoglobin", "mean cell hemoglobin"],
        "min": 27.0, "max": 33.0, "unit": "pg",
        "name_en": "MCH (Mean Corpuscular Hemoglobin)",
        "name_ur": "MCH",
        "advice_low": "آئرن کی کمی ہو سکتی ہے۔",
        "advice_high": "وٹامن بی 12 کمی ہو سکتی ہے۔",
        "advice_normal": "نارمل ہے۔"
    },

    "mchc": {
        "aliases": ["mchc", "mean corpuscular hemoglobin concentration"],
        "min": 32.0, "max": 36.0, "unit": "g/dL",
        "name_en": "MCHC",
        "name_ur": "MCHC",
        "advice_low": "آئرن کی کمی انیمیا کی علامت ہو سکتی ہے۔",
        "advice_high": "ہیمولیسس یا سفیروسائٹوسس ہو سکتی ہے۔",
        "advice_normal": "نارمل ہے۔"
    },

    "esr": {
        "aliases": ["esr", "erythrocyte sedimentation", "sed rate", "westergren"],
        "min": 0, "max": 20, "unit": "mm/hr",
        "name_en": "ESR (Erythrocyte Sedimentation Rate)",
        "name_ur": "ESR",
        "advice_low": "نارمل ہے۔",
        "advice_high": "سوزش یا انفیکشن کی علامت ہو سکتی ہے۔",
        "advice_normal": "نارمل ہے۔"
    },

    # ================= DIABETES =================
    "glucose_fasting": {
        "aliases": ["fasting glucose", "fbs", "fasting sugar", "glucose fasting", "glucose — fasting", "glucose fasting (fbs)"],
        "min": 70, "max": 100, "unit": "mg/dL",
        "name_en": "Fasting Glucose (FBS)",
        "name_ur": "فاسٹنگ شوگر",
        "advice_low": "شوگر کم ہے، فوری میٹھا لیں۔",
        "advice_high": "شوگر زیادہ ہے، ذیابیطس کا خطرہ ہو سکتا ہے۔",
        "advice_normal": "فاسٹنگ شوگر نارمل ہے۔"
    },

    "glucose_random": {
        "aliases": ["random glucose", "rbs", "random sugar"],
        "min": 70, "max": 140, "unit": "mg/dL",
        "name_en": "Random Glucose",
        "name_ur": "رینڈم شوگر",
        "advice_low": "شوگر کم ہے۔",
        "advice_high": "شوگر زیادہ ہے۔ ڈاکٹر سے مشورہ کریں۔",
        "advice_normal": "شوگر نارمل ہے۔"
    },

    "hba1c": {
        "aliases": ["hba1c", "glycated hemoglobin", "glycosylated hemoglobin"],
        "min": 4.0, "max": 5.6, "unit": "%",
        "name_en": "HbA1c",
        "name_ur": "HbA1c (شوگر اوسط)",
        "advice_low": "نارمل ہے۔",
        "advice_high": "ذیابیطس کنٹرول میں نہیں ہے۔",
        "advice_normal": "HbA1c نارمل ہے۔"
    },

    # ================= LIVER =================
    "alt": {
        "aliases": ["alt", "sgpt", "alanine aminotransferase", "alanine transaminase"],
        "min": 0, "max": 45, "unit": "U/L",
        "name_en": "ALT (SGPT)",
        "name_ur": "ALT (جگر)",
        "advice_low": "نارمل ہے۔",
        "advice_high": "جگر میں سوزش یا ہیپاٹائٹس ہو سکتا ہے۔",
        "advice_normal": "جگر نارمل ہے۔"
    },

    "ast": {
        "aliases": ["ast", "sgot", "aspartate aminotransferase"],
        "min": 0, "max": 40, "unit": "U/L",
        "name_en": "AST (SGOT)",
        "name_ur": "AST (جگر)",
        "advice_low": "نارمل ہے۔",
        "advice_high": "جگر یا دل کا مسئلہ ہو سکتا ہے۔",
        "advice_normal": "نارمل ہے۔"
    },

    "bilirubin": {
        "aliases": ["bilirubin", "total bilirubin", "bilirubin — total", "bilirubin-total", "s. bilirubin"],
        "min": 0.3, "max": 1.2, "unit": "mg/dL",
        "name_en": "Bilirubin (Total)",
        "name_ur": "بلیروبن",
        "advice_low": "نارمل ہے۔",
        "advice_high": "یرقان (Jaundice) کا امکان ہے۔",
        "advice_normal": "بلیروبن نارمل ہے۔"
    },

    # ── NEW: Albumin ──────────────────────────────────────────
    "albumin": {
        "aliases": ["albumin", "serum albumin", "s. albumin"],
        "min": 3.5, "max": 5.2, "unit": "g/dL",
        "name_en": "Albumin",
        "name_ur": "البیومن (پروٹین)",
        "advice_low": "پروٹین کی کمی یا جگر کا مسئلہ ہو سکتا ہے۔",
        "advice_high": "ڈی ہائیڈریشن ہو سکتی ہے۔",
        "advice_normal": "البیومن نارمل ہے۔"
    },

    # ================= KIDNEY =================
    "creatinine": {
        "aliases": ["creatinine", "creat", "serum creatinine", "s. creatinine"],
        "min": 0.6, "max": 1.3, "unit": "mg/dL",
        "name_en": "Serum Creatinine",
        "name_ur": "کریٹینائن (گردے)",
        "advice_low": "نارمل ہے۔",
        "advice_high": "گردوں کی کارکردگی متاثر ہو سکتی ہے۔",
        "advice_normal": "گردے نارمل ہیں۔"
    },

    "urea": {
        "aliases": ["urea", "blood urea", "serum urea", "s. urea", "bun"],
        "min": 15, "max": 40, "unit": "mg/dL",
        "name_en": "Serum Urea",
        "name_ur": "یوریا",
        "advice_low": "نارمل ہے۔",
        "advice_high": "گردے کا مسئلہ یا پانی کی کمی ہو سکتی ہے۔",
        "advice_normal": "یوریا نارمل ہے۔"
    },

    # ================= HEART / LIPID =================
    "cholesterol": {
        "aliases": ["cholesterol", "total cholesterol", "chol"],
        "min": 0, "max": 200, "unit": "mg/dL",
        "name_en": "Total Cholesterol",
        "name_ur": "کولیسٹرول",
        "advice_low": "نارمل ہے۔",
        "advice_high": "دل کی بیماری کا خطرہ ہو سکتا ہے۔",
        "advice_normal": "کولیسٹرول نارمل ہے۔"
    },

    "ldl": {
        "aliases": ["ldl", "bad cholesterol", "ldl cholesterol", "ldl-c"],
        "min": 0, "max": 100, "unit": "mg/dL",
        "name_en": "LDL Cholesterol",
        "name_ur": "LDL (خراب کولیسٹرول)",
        "advice_low": "نارمل ہے۔",
        "advice_high": "دل کے لیے خطرناک ہو سکتا ہے۔",
        "advice_normal": "LDL نارمل ہے۔"
    },

    "hdl": {
        "aliases": ["hdl", "good cholesterol", "hdl cholesterol", "hdl-c"],
        "min": 40, "max": 60, "unit": "mg/dL",
        "name_en": "HDL Cholesterol",
        "name_ur": "HDL (اچھا کولیسٹرول)",
        "advice_low": "کم ہے، دل کے لیے خطرہ ہو سکتا ہے۔",
        "advice_high": "اچھا ہے، دل محفوظ ہے۔",
        "advice_normal": "HDL نارمل ہے۔"
    },

    "triglycerides": {
        "aliases": ["triglycerides", "tg", "triglyceride", "trigs"],
        "min": 0, "max": 150, "unit": "mg/dL",
        "name_en": "Triglycerides",
        "name_ur": "ٹرائی گلیسرائیڈز",
        "advice_low": "نارمل ہے۔",
        "advice_high": "دل کی بیماری کا خطرہ ہو سکتا ہے۔",
        "advice_normal": "نارمل ہے۔"
    },

    # ================= VITAMINS =================
    "vitamin_d": {
        "aliases": ["vitamin d", "vit d", "25-oh vitamin d", "25 oh vitamin d"],
        "min": 20, "max": 50, "unit": "ng/mL",
        "name_en": "Vitamin D",
        "name_ur": "وٹامن ڈی",
        "advice_low": "وٹامن ڈی کی کمی ہے، دھوپ اور سپلیمنٹ لیں۔",
        "advice_high": "زیادہ ہے، ڈاکٹر سے مشورہ کریں۔",
        "advice_normal": "نارمل ہے۔"
    },

    "vitamin_b12": {
        "aliases": ["vitamin b12", "b12", "vit b12", "cobalamin"],
        "min": 200, "max": 900, "unit": "pg/mL",
        "name_en": "Vitamin B12",
        "name_ur": "وٹامن بی 12",
        "advice_low": "کمزوری اور تھکن ہو سکتی ہے۔",
        "advice_high": "زیادہ ہے، ڈاکٹر سے رجوع کریں۔",
        "advice_normal": "نارمل ہے۔"
    },

}
