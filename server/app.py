import os
from datetime import datetime, timedelta
from flask import Flask, request, render_template, redirect, url_for, flash, jsonify
from flask_cors import CORS
from werkzeug.utils import secure_filename

import firebase_admin
from firebase_admin import credentials, storage, firestore
from google.cloud import storage as gcs

# ---------------------------
# KONFIGURASI
# ---------------------------
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
SERVICE_ACCOUNT_JSON = os.path.join(BASE_DIR, "serviceAccountKey.json")

# ⚠️ GANTI sesuai dengan bucket kamu di Firebase Storage
FIREBASE_BUCKET = "tugas-akhir-15.appspot.com"

SIGNED_URL_EXPIRES_SECONDS = 60 * 60 * 24  # 24 jam

# ---------------------------
# INISIALISASI FIREBASE
# ---------------------------
if not firebase_admin._apps:
    cred = credentials.Certificate(SERVICE_ACCOUNT_JSON)
    firebase_admin.initialize_app(cred, {"storageBucket": FIREBASE_BUCKET})

db = firestore.client()
bucket = storage.bucket()

# client GCS untuk signed URL
gcs_client = gcs.Client.from_service_account_json(SERVICE_ACCOUNT_JSON)
gcs_bucket = gcs_client.bucket(FIREBASE_BUCKET)

# ---------------------------
# FLASK APP
# ---------------------------
app = Flask(__name__)
CORS(app)
app.secret_key = os.environ.get("FLASK_SECRET", "supersecretkey")

ALLOWED_EXT = {"png", "jpg", "jpeg", "gif", "mp4", "mov", "webm", "avi", "mkv"}


def allowed_file(filename: str) -> bool:
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXT


def id_weekday_to_indonesian(weekday_name: str) -> str:
    mapping = {
        "Monday": "Senin",
        "Tuesday": "Selasa",
        "Wednesday": "Rabu",
        "Thursday": "Kamis",
        "Friday": "Jumat",
        "Saturday": "Sabtu",
        "Sunday": "Minggu",
    }
    return mapping.get(weekday_name, weekday_name)


def day_folder_for(dt: datetime) -> str:
    date_str = dt.strftime("%Y-%m-%d")
    weekday_en = dt.strftime("%A")
    weekday_id = id_weekday_to_indonesian(weekday_en)
    return f"{date_str}_{weekday_id}"


def generate_signed_url(storage_path: str, expire_seconds: int = SIGNED_URL_EXPIRES_SECONDS):
    blob = gcs_bucket.blob(storage_path)
    url = blob.generate_signed_url(expiration=timedelta(seconds=expire_seconds))
    return url


# ---------------------------
# ROUTES
# ---------------------------

@app.route("/")
def index():
    return redirect(url_for("dashboard"))


@app.route("/upload", methods=["POST"])
def upload_endpoint():
    """Endpoint upload dari aplikasi Flutter"""
    if "file" not in request.files:
        return jsonify({"ok": False, "message": "No file part"}), 400

    file = request.files["file"]
    if file.filename == "":
        return jsonify({"ok": False, "message": "No selected file"}), 400

    if not allowed_file(file.filename):
        return jsonify({"ok": False, "message": "File type not allowed"}), 400

    file_type_raw = request.form.get("type", "gambar").lower()
    main_type = "Video" if "vid" in file_type_raw or "video" in file_type_raw else "Gambar"

    filename_clean = secure_filename(file.filename)
    now = datetime.utcnow()
    folder_name = day_folder_for(now)
    storage_path = f"{main_type}/{folder_name}/{filename_clean}"

    blob = bucket.blob(storage_path)
    content_type = file.content_type or None

    try:
        blob.upload_from_file(file.stream, content_type=content_type)
    except Exception as e:
        app.logger.exception("Upload to storage failed")
        return jsonify({"ok": False, "message": f"Upload failed: {e}"}), 500

    local_dt = datetime.now()
    weekday = id_weekday_to_indonesian(local_dt.strftime("%A"))
    readable_date = f"{weekday}, {local_dt.strftime('%Y-%m-%d')} • {local_dt.strftime('%H:%M')}"

    doc = {
        "name": filename_clean,
        "storage_path": storage_path,
        "main": main_type,
        "folder": folder_name,
        "readable_date": readable_date,
        "uploaded_at": firestore.SERVER_TIMESTAMP,
    }

    try:
        db.collection("files").add(doc)
    except Exception as e:
        app.logger.exception("Saving metadata failed")

    return jsonify({"ok": True, "message": "uploaded", "path": storage_path}), 200


@app.route("/dashboard")
def dashboard():
    """Dashboard web"""
    docs = db.collection("files").order_by("uploaded_at", direction=firestore.Query.DESCENDING).stream()
    files = []
    for d in docs:
        data = d.to_dict()
        data["id"] = d.id
        storage_path = data.get("storage_path")
        try:
            url = generate_signed_url(storage_path)
        except Exception as e:
            url = None
        data["url"] = url
        files.append(data)

    grouped = {}
    for f in files:
        main = f.get("main", "Gambar")
        folder = f.get("folder", "unknown")
        grouped.setdefault(main, {})
        grouped[main].setdefault(folder, [])
        grouped[main][folder].append(f)

    return render_template("dashboard.html", grouped=grouped)


@app.route("/delete/<doc_id>", methods=["POST"])
def delete_file(doc_id):
    """Hapus file dari Storage dan Firestore"""
    doc_ref = db.collection("files").document(doc_id)
    doc = doc_ref.get()
    if not doc.exists:
        flash("Dokumen tidak ditemukan", "danger")
        return redirect(url_for("dashboard"))

    data = doc.to_dict()
    storage_path = data.get("storage_path")
    blob = bucket.blob(storage_path)
    try:
        blob.delete()
    except Exception as e:
        app.logger.warning("Gagal hapus di Storage: %s", e)

    doc_ref.delete()
    flash("File dihapus", "success")
    return redirect(url_for("dashboard"))


@app.route("/download/<path:storage_path>")
def download_file(storage_path):
    """Redirect ke signed URL (download/view file)"""
    try:
        url = generate_signed_url(storage_path, expire_seconds=60 * 60)
        return redirect(url)
    except Exception:
        return "File not available", 404


@app.route("/send_all_dummy", methods=["POST"])
def send_all_dummy():
    """Simulasi tombol 'Kirim semua' di dashboard"""
    flash("Semua file berhasil dikirim (simulasi).", "info")
    return redirect(url_for("dashboard"))


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
