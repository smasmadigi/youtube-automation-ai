import os
import json
import google.generativeai as genai

# Configurez l'API Gemini
genai.configure(api_key=os.environ.get("GEMINI_API_KEY"))

# CORRECTION : Utilisation du modèle stable 'gemini-pro'
model = genai.GenerativeModel('gemini-pro')

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
