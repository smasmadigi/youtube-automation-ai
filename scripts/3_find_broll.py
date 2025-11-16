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
