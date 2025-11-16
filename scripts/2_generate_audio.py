import os
import os
import json
from elevenlabs.client import ElevenLabs

# Configurez l'API
client = ElevenLabs(
  api_key=os.environ.get("ELEVENLABS_API_KEY")
)

# Charger le script
with open("video_script.json", "r", encoding="utf-8") as f:
    script_data = json.load(f)

# Créer le dossier audio
os.makedirs("audio", exist_ok=True)

# Générer l'audio pour chaque scène
for scene in script_data["scenes"]:
    scene_number = scene["scene"]
    text_to_speak = scene["text"]
    
    print(f"Génération audio pour Scène {scene_number}...")
    
    audio = client.generate(
        text=text_to_speak,
        voice="Adam", # (Vous pouvez changer la voix)
        model="eleven_multilingual_v2"
    )
    
    file_path = f"audio/scene_{scene_number}.mp3"
    
    with open(file_path, "wb") as f:
        f.write(audio)

print("Génération audio terminée.")
