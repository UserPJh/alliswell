import os
from flask import Flask, request, jsonify
from gtts import gTTS
import uuid

app = Flask(__name__)

# 환경 변수에서 설정값 읽기
AUDIO_FOLDER = os.getenv("AUDIO_FOLDER", "audio")
SERVER_HOST = os.getenv("SERVER_HOST", "0.0.0.0")
SERVER_PORT = int(os.getenv("SERVER_PORT", 5000))

os.makedirs(AUDIO_FOLDER, exist_ok=True)

@app.route("/speak", methods=["POST"])
def speak():
    text = request.json.get("text")
    if not text:
        return jsonify({"error": "No text provided"}), 400

    filename = f"tts_{uuid.uuid4()}.mp3"
    filepath = os.path.join(AUDIO_FOLDER, filename)

    tts = gTTS(text=text, lang="ko")
    tts.save(filepath)

    return jsonify({"url": f"http://localhost/audio/{filename}"}), 200

@app.route("/audio/<filename>", methods=["GET"])
def get_audio(filename):
    filepath = os.path.join(AUDIO_FOLDER, filename)
    if os.path.exists(filepath):
        return send_file(filepath, mimetype="audio/mpeg")
    else:
        return jsonify({"error": "File not found"}), 404

if __name__ == "__main__":
    app.run(host=SERVER_HOST, port=SERVER_PORT, debug=True)
