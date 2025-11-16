#!/bin/bash
# setup_project.sh

# Nom du dépôt (doit correspondre à votre config n8n)
REPO_NAME="smasmadigi/youtube-automation-ai"
REPO_URL="https://github.com/smasmadigi/youtube-automation-ai.git"

# 1. Créer la structure locale
echo "--- Création de la structure du projet ---"
mkdir -p .github/workflows
mkdir -p scripts
touch .gitignore

# 2. Créer les fichiers
echo "--- Création des fichiers de script ---"
# (Ici, collez le contenu de .github/workflows/video_factory.yml)
cat << 'EOF' > .github/workflows/video_factory.yml
name: Video Factory
name: Video Factory

# Déclenché par n8n (via workflow_dispatch)
on:
  workflow_dispatch:
    inputs:
      prompt:
        description: 'Le prompt IA pour générer le script'
        required: true
        default: 'Les 5 faits les plus surprenants sur l'IA'
      titre:
        description: 'Le titre de travail'
        required: true
        default: 'Vidéo IA'

jobs:
  # Étape 1: Générer le scénario complet
  generate_script:
    runs-on: ubuntu-latest
    outputs:
      script_json_path: ${{ steps.upload_script.outputs.artifact_path }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r scripts/requirements.txt

      - name: Run script generation
        env:
          GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
          USER_PROMPT: ${{ github.event.inputs.prompt }}
        run: python scripts/1_generate_script.py

      - name: Upload script artifact
        id: upload_script
        uses: actions/upload-artifact@v3
        with:
          name: script-json
          path: video_script.json

  # Étape 2: Générer l'audio (TTS)
  generate_audio:
    runs-on: ubuntu-latest
    needs: generate_script
    steps:
      - name: Download script
        uses: actions/download-artifact@v3
        with:
          name: script-json

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r scripts/requirements.txt
      
      - name: Run TTS generation
        env:
          ELEVENLABS_API_KEY: ${{ secrets.ELEVENLABS_API_KEY }}
        run: python scripts/2_generate_audio.py
      
      - name: Upload audio files
        uses: actions/upload-artifact@v3
        with:
          name: audio-files
          path: audio/

  # Étape 3: Trouver les vidéos B-Roll
  generate_broll:
    runs-on: ubuntu-latest
    needs: generate_script
    steps:
      - name: Download script
        uses: actions/download-artifact@v3
        with:
          name: script-json

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r scripts/requirements.txt
      
      - name: Run B-roll finder
        env:
          PEXELS_API_KEY: ${{ secrets.PEXELS_API_KEY }}
        run: python scripts/3_find_broll.py
      
      - name: Upload video files
        uses: actions/upload-artifact@v3
        with:
          name: video-files
          path: videos/

  # Étape 4: Compiler la vidéo finale
  compile_video:
    runs-on: ubuntu-latest
    needs: [generate_audio, generate_broll]
    steps:
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r scripts/requirements.txt
      
      - name: Install FFmpeg ( requis par moviepy )
        uses: FedericoCarboni/setup-ffmpeg@v2
        with:
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Download all artifacts
        uses: actions/download-artifact@v3
        with:
          path: artifacts/
      
      - name: Re-organize artifacts
        run: |
          mkdir -p audio/ videos/
          mv artifacts/audio-files/* audio/
          mv artifacts/video-files/* videos/
          mv artifacts/script-json/video_script.json .

      - name: Run video compilation
        run: python scripts/4_compile_video.py

      - name: Upload final video
        uses: actions/upload-artifact@v3
        with:
          name: final_video # Doit correspondre au nœud n8n "Download Artifact"
          path: final_video.mp4
EOF

# (Collez le contenu de requirements.txt)
cat << 'EOF' > scripts/requirements.txt
google-generativeai
requests
elevenlabs
moviepy
Pillow
EOF

# (Collez 1_generate_script.py)
cat << 'EOF' > scripts/1_generate_script.py
import os
import os
import json
import google.generativeai as genai

# Configurez l'API Gemini
genai.configure(api_key=os.environ.get("GEMINI_API_KEY"))
model = genai.GenerativeModel('gemini-1.5-flash')

# Récupérez le prompt de n8n
user_prompt = os.environ.get("USER_PROMPT")

# Un prompt "méta" pour forcer Gemini à retourner du JSON
system_prompt = f"""
Vous êtes un scénariste pour des vidéos YouTube virales.
Générez un script pour une vidéo basée sur le prompt suivant : "{user_prompt}"

Le script doit être divisé en scènes. Pour chaque scène, fournissez :
1.  `scene` (numéro de scène, ex: 1)
2.  `text` (le texte exact que le narrateur dira)
3.  `keywords` (3 mots-clés visuels pour trouver une vidéo B-roll, ex: "technologie, cerveau, néon")

Retournez UNIQUEMENT le script au format JSON valide, sous une clé "scenes".
Exemple de format :
{{
  "scenes": [
    {{ "scene": 1, "text": "Bonjour et bienvenue...", "keywords": "accueil, néon, bonjour" }},
    {{ "scene": 2, "text": "Aujourd'hui, nous explorons...", "keywords": "carte du monde, exploration, aventure" }}
  ]
}}
"""

response = model.generate_content(system_prompt)
script_text = response.text.strip().replace("```json", "").replace("```", "")

print("Script généré par l'IA :")
print(script_text)

# Sauvegarder le script
with open("video_script.json", "w", encoding="utf-8") as f:
    f.write(script_text)
EOF

# (Collez 2_generate_audio.py)
cat << 'EOF' > scripts/2_generate_audio.py
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
EOF

# (Collez 3_find_broll.py)
cat << 'EOF' > scripts/3_find_broll.py
import os
import os
import json
import requests

PEXELS_API_KEY = os.environ.get("PEXELS_API_KEY")
PEXELS_URL = "https://api.pexels.com/videos/search"

# Charger le script
with open("video_script.json", "r", encoding="utf-8") as f:
    script_data = json.load(f)

os.makedirs("videos", exist_ok=True)
headers = {"Authorization": PEXELS_API_KEY}

for scene in script_data["scenes"]:
    scene_number = scene["scene"]
    keywords = scene["keywords"]
    
    print(f"Recherche B-Roll pour Scène {scene_number} (keywords: {keywords})...")
    
    params = {
        "query": keywords,
        "per_page": 1,
        "orientation": "portrait" # ou landscape
    }
    
    response = requests.get(PEXELS_URL, headers=headers, params=params)
    
    if response.status_code == 200:
        data = response.json()
        if data["videos"]:
            video_link = data["videos"][0]["video_files"][0]["link"]
            video_data = requests.get(video_link).content
            
            file_path = f"videos/scene_{scene_number}.mp4"
            with open(file_path, "wb") as f:
                f.write(video_data)
            print(f"Vidéo {file_path} téléchargée.")
        else:
            print(f"Aucune vidéo trouvée pour : {keywords}")
    else:
        print(f"Erreur API Pexels: {response.status_code}")
EOF

# (Collez 4_compile_video.py)
cat << 'EOF' > scripts/4_compile_video.py
import json
import json
from moviepy.editor import *

print("Démarrage de la compilation vidéo...")

# Charger le script
with open("video_script.json", "r", encoding="utf-8") as f:
    script_data = json.load(f)

final_clips = []

for scene in script_data["scenes"]:
    scene_number = scene["scene"]
    print(f"Montage de la Scène {scene_number}...")
    
    audio_path = f"audio/scene_{scene_number}.mp3"
    video_path = f"videos/scene_{scene_number}.mp4"

    # Vérifier que les fichiers existent
    if not os.path.exists(audio_path) or not os.path.exists(video_path):
        print(f"Erreur: Fichiers manquants pour la scène {scene_number}. Ignorée.")
        continue

    # Charger les clips
    audio_clip = AudioFileClip(audio_path)
    video_clip = VideoFileClip(video_path)
    
    # Ajuster la durée de la vidéo à celle de l'audio
    video_clip = video_clip.set_duration(audio_clip.duration)
    
    # Redimensionner (ex: format 1080x1920 pour Shorts)
    video_clip = video_clip.resize(height=1920)
    video_clip = video_clip.crop(x_center=video_clip.w/2, width=1080, height=1920)
    
    # Ajouter l'audio à la vidéo
    video_clip = video_clip.set_audio(audio_clip)
    
    final_clips.append(video_clip)

# Concaténer toutes les scènes
if final_clips:
    final_video = concatenate_videoclips(final_clips, method="compose")
    final_video.write_videofile(
        "final_video.mp4",
        codec="libx264",
        audio_codec="aac",
        temp_audiofile="temp-audio.m4a",
        remove_temp=True,
        fps=24
    )
    print("Compilation vidéo terminée : final_video.mp4")
else:
    print("Aucun clip n'a été généré.")
EOF

# (Ajouter un .gitignore)
cat << 'EOF' > .gitignore
*.mp4
*.mp3
*.json
audio/
videos/
artifacts/
__pycache__/
*.pyc
EOF

echo "--- Initialisation de Git et premier commit ---"
git init
git add .
git commit -m "Initial commit: ajout de la factory vidéo"
git branch -M main
git remote add origin https://github.com/smasmadigi/youtube-automation-ai.git
git push -u origin main

echo "--- Terminé! N'oubliez pas de configurer vos Secrets GitHub! ---"
