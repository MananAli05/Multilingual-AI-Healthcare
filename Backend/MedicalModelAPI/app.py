from fastapi import FastAPI, File, UploadFile, HTTPException
from pydantic import BaseModel
import joblib
import pandas as pd
import numpy as np
from fastapi.middleware.cors import CORSMiddleware
import easyocr
import re
import io
import tensorflow as tf
from PIL import Image
from lab_metadata import LAB_METADATA

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"]
)
# SYMPTOM PREDICTION
symptom_model = joblib.load("Symtom_Diseases_Model.joblib")
symptoms_list = [
    'high_fever','mild_fever','chills','shivering','sweating','cough',
    'breathlessness','phlegm','chest_pain','headache','fatigue','nausea',
    'vomiting','loss_of_appetite','abdominal_pain','diarrhoea','joint_pain',
    'muscle_pain','back_pain','yellowish_skin','yellowing_of_eyes',
    'dark_urine','skin_rash','itching','weight_loss','dizziness',
    'stiff_neck','excessive_hunger','polyuria','blurred_and_distorted_vision',
    'continuous_sneezing','acidity','burning_micturition','runny_nose'
]
class InputData(BaseModel):
    input_vector: list
@app.post("/predict")
def predict(data: InputData):
    if len(data.input_vector) != len(symptoms_list):
        raise HTTPException(status_code=400, detail="Invalid input vector length")
    input_df = pd.DataFrame([data.input_vector], columns=symptoms_list)
    probs = symptom_model.predict_proba(input_df)[0]
    classes = symptom_model.classes_
    top_indices = np.argsort(probs)[-5:][::-1]
    results = [
        {"disease": classes[i].strip(), "confidence": float(probs[i] * 100)}
        for i in top_indices
    ]
    return {"results": results}
#X-RAY MODEL
xray_model = tf.keras.models.load_model("pneumonia_model.h5")
@app.post("/predict-xray")
async def predict_xray(file: UploadFile = File(...)):
    contents = await file.read()
    image = Image.open(io.BytesIO(contents)).convert('RGB')
    image = image.resize((150, 150))
    img_array = np.array(image) / 255.0
    img_array = np.expand_dims(img_array, axis=0)
    prediction = xray_model.predict(img_array)
    prob = float(prediction[0][0])
    result = "PNEUMONIA" if prob > 0.5 else "NORMAL"
    confidence = prob if result == "PNEUMONIA" else (1 - prob)
    return {
        "result": result,
        "confidence": round(confidence * 100, 2)
    }
# LAB REPORT OCR
reader = easyocr.Reader(['en'])
def preprocess_image(image_bytes):
    img = Image.open(io.BytesIO(image_bytes)).convert("L")  
    img = img.resize((img.width * 2, img.height * 2))       
    return np.array(img)
def extract_all_tests(tokens):
    findings = []
    matched_keys = set()  
    for i, token in enumerate(tokens):
        for key, data in LAB_METADATA.items():
            if key in matched_keys:
                continue
            for alias in data["aliases"]:
                if alias in token:
                    for j in range(i + 1, min(i + 15, len(tokens))):
                        is_another_test = any(
                            a in tokens[j]
                            for k2, d2 in LAB_METADATA.items()
                            if k2 != key
                            for a in d2["aliases"]
                        )
                        if is_another_test:
                            break 
                        match = re.search(r"\d+\.?\d*", tokens[j])
                        if match:
                            val = float(match.group())
                            if val == 0 or (val > 5000 and key not in ["wbc", "platelets"]):
                                continue
                            findings.append({"test_key": key, "value": val})
                            matched_keys.add(key)
                            break
                    break  
    return findings
def interpret_results(findings):
    results = []

    for f in findings:
        data = LAB_METADATA[f["test_key"]]
        val = f["value"]

        status = "Normal"
        color = "green"
        advice = data["advice_normal"]

        if val < data["min"]:
            status = "Low"
            color = "red"
            advice = data["advice_low"]
        elif val > data["max"]:
            status = "High"
            color = "red"
            advice = data["advice_high"]

        results.append({
            "test_en": data["name_en"],
            "test_ur": data["name_ur"],
            "value": val,
            "unit": data["unit"],
            "status": status,
            "advice": advice,
            "color": color
        })
    return results
@app.post("/interpret-report")
async def interpret_report(file: UploadFile = File(...)):
    contents = await file.read()
    processed = preprocess_image(contents)
    ocr_results = reader.readtext(processed, detail=1)
    tokens = [text.lower() for (_, text, conf) in ocr_results if conf > 0.3]
    print(f"[OCR] Detected {len(tokens)} tokens: {tokens[:20]}")  
    findings = extract_all_tests(tokens)
    print(f"[OCR] Matched {len(findings)} tests: {[f['test_key'] for f in findings]}")
    results = interpret_results(findings)
    return {
        "total_tests": len(results),
        "results": results  #
    }

