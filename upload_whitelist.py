import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd

# 1. Initialize Firebase Admin SDK
cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

# 2. Read Excel File
excel_file = 'students.xlsx' 
df = pd.read_excel(excel_file)

# Clean column headers
df.columns = df.columns.str.strip()

# 3. Upload each student row to 'students' collection in Firestore
collection_name = 'students'

for index, row in df.iterrows():
    prn = str(row['prn']).strip()
    
    student_data = {
        'prn': prn,
        'rollNum': int(row['rollNum']) if pd.notna(row['rollNum']) else None,
        'isRegistered': bool(row['isRegistered']) if pd.notna(row['isRegistered']) else False
    }
    
    # Use .document() instead of .doc()
    db.collection(collection_name).document(prn).set(student_data)
    print(f"Uploaded PRN: {prn}")

print("\nUpload complete!")