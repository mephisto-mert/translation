import requests
import os

# Map language code to flag country code (ISO 3166-1 alpha-2)
# Some languages map to specific countries for flags
flags = {
    "auto": "https://flagcdn.com/w80/un.png",
    "tr": "https://flagcdn.com/w80/tr.png",
    "en": "https://flagcdn.com/w80/us.png",
    "de": "https://flagcdn.com/w80/de.png",
    "fr": "https://flagcdn.com/w80/fr.png",
    "es": "https://flagcdn.com/w80/es.png",
    "it": "https://flagcdn.com/w80/it.png",
    "ru": "https://flagcdn.com/w80/ru.png",
    "ja": "https://flagcdn.com/w80/jp.png",
    "zh-CN": "https://flagcdn.com/w80/cn.png",
    "ar": "https://flagcdn.com/w80/sa.png",
    # New Languages
    "pt": "https://flagcdn.com/w80/pt.png",      # Portuguese (Portugal)
    "ko": "https://flagcdn.com/w80/kr.png",      # Korean (South Korea)
    "nl": "https://flagcdn.com/w80/nl.png",      # Dutch (Netherlands)
    "pl": "https://flagcdn.com/w80/pl.png",      # Polish (Poland)
    "hi": "https://flagcdn.com/w80/in.png",      # Hindi (India)
    "id": "https://flagcdn.com/w80/id.png",      # Indonesian (Indonesia)
    "uk": "https://flagcdn.com/w80/ua.png",      # Ukrainian (Ukraine)
    "el": "https://flagcdn.com/w80/gr.png",      # Greek (Greece)
    "cs": "https://flagcdn.com/w80/cz.png",      # Czech (Czech Republic)
    "sv": "https://flagcdn.com/w80/se.png",      # Swedish (Sweden)
    "vi": "https://flagcdn.com/w80/vn.png",      # Vietnamese (Vietnam)
    "th": "https://flagcdn.com/w80/th.png",      # Thai (Thailand)
}

os.makedirs("assets/flags", exist_ok=True)

for code, url in flags.items():
    try:
        response = requests.get(url)
        if response.status_code == 200:
            with open(f"assets/flags/{code}.png", "wb") as f:
                f.write(response.content)
            print(f"Downloaded {code}.png")
        else:
            print(f"Failed to download {code}: {response.status_code}")
    except Exception as e:
        print(f"Error downloading {code}: {e}")
