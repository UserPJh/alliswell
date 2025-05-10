from flask import Flask, request, jsonify
from gtts import gTTS
import uuid
import os

app = Flask(__name__)
AUDIO_FOLDER = "audio"
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
    app.run(host='0.0.0.0', port=5000, debug=True)
