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
