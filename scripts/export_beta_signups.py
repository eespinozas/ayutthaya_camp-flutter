"""Exporta los correos inscritos en la beta (coleccion beta_signups).

Imprime los correos separados por coma, listos para pegar en la lista de
testers de Play Console (Testing > Closed testing > Testers).

Uso:
    python scripts/export_beta_signups.py
"""

import os
import sys

import firebase_admin
from firebase_admin import credentials, firestore

SERVICE_ACCOUNT_PATHS = [
    os.environ.get("FIREBASE_SERVICE_ACCOUNT", ""),
    os.path.join(os.path.dirname(__file__), "firebase-service-account.json"),
    os.path.join(os.path.dirname(__file__), "..", "serviceAccountKey.json"),
]


def main() -> None:
    cred_path = next((p for p in SERVICE_ACCOUNT_PATHS if p and os.path.exists(p)), None)
    if not cred_path:
        print("ERROR: no se encontro el service account de Firebase.")
        sys.exit(1)

    firebase_admin.initialize_app(credentials.Certificate(cred_path))
    db = firestore.client()

    docs = list(db.collection("beta_signups").order_by("createdAt").stream())
    emails = [d.get("email") for d in docs if d.get("email")]

    print(f"\n{len(emails)} inscritos en la beta:\n")
    for doc in docs:
        data = doc.to_dict()
        created = data.get("createdAt")
        created_str = created.strftime("%Y-%m-%d %H:%M") if created else "?"
        print(f"  {data.get('email'):<45} {created_str}")

    print("\nListos para pegar en Play Console (separados por coma):\n")
    print(", ".join(emails))


if __name__ == "__main__":
    main()
