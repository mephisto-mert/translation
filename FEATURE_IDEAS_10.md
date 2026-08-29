# 🚀 Quick Trace Pro — 10 Yeni Özellik Önerisi
> Tarih: 2026-02-12 | Kaynak: Rakip analizi + Feature Adviser + Pazar araştırması
> Rakipler: Gaminik, Translumo, OCR Game Translator, RSTGameTranslation, Live Translate

---

## Mevcut Rekabet Avantajımız 🏆
**Input Mode (yaz-çevir-yapıştır)** — Hiçbir rakipte yok! Rakipler sadece OCR overlay veya clipboard çevirisi yapıyor. Biz doğrudan chat'te yazdığını çeviriyoruz.

---

## 1. 👁️ OCR Ekran Çevirisi
**Ne:** Ekrandaki herhangi bir metni kamera gibi okuyup çevir.
**Kullanım:** Yabancı dilde oyun menüleri, quest açıklamaları, item bilgileri — hepsini seç ve çevir.
**Nasıl:** Windows 10/11 yerleşik OCR API'si (`Windows.Media.Ocr`) — ek kurulum yok.
**Rakip karşılaştırma:** Gaminik, Translumo, OCR Game Translator hepsi bunu yapıyor. Bizde yok!

| Metrik | Değer |
|--------|-------|
| Etki | ⭐⭐⭐⭐⭐ |
| Efor | 12-16 saat |
| Risk | Orta |
| Öncelik | 🔴 Kritik |

---

## 2. 🤖 Gemini AI Çeviri Motoru
**Ne:** Google Gemini Flash'ı 4. çeviri motoru olarak ekle.
**Neden:** Normal Google Translate basit kelime-kelime çeviri yapıyor. Gemini bağlam anlıyor, oyun terminolojisini biliyor, slang'i doğru çeviriyor.
**Nasıl:** Gemini API (ücretsiz tier: 15 RPM, 1M token/gün). REST API çağrısı.
**Örnek:** "gg wp" → Google: "gg wp" (çevirmez) → Gemini: "iyi oyundu, güzel oynadınız" 🎯

| Metrik | Değer |
|--------|-------|
| Etki | ⭐⭐⭐⭐⭐ |
| Efor | 4-6 saat |
| Risk | Düşük |
| Öncelik | 🔴 Kritik |

---

## 3. ⚡ Hızlı Çeviri Paneli (Quick Phrases)
**Ne:** Önceden tanımlı oyun cümlelerini tek tuşla çevir ve yapıştır.
**Örnek panel:**
```
F1 → "Rush B, don't stop" → "B'ye koşun, durmayın"
F2 → "Eco round" → "Eko raund"
F3 → "Need backup" → "Destek lazım"
F4 → "Enemy spotted" → "Düşman görüldü"
```
**Neden:** Oyunda hızlı iletişim hayat kurtarır. Yazmaya gerek yok, tek tuş.
**Ek:** Kullanıcı kendi phrase'lerini ekleyebilir.

| Metrik | Değer |
|--------|-------|
| Etki | ⭐⭐⭐⭐ |
| Efor | 6-8 saat |
| Risk | Düşük |
| Öncelik | 🟡 Yüksek |

---

## 4. 🎙️ Sesli Çeviri (Voice-to-Chat)
**Ne:** Mikrofona konuş → metin yap → çevir → chat'e yapıştır.
**Kullanım:** CS2 chat'ine yazmak yerine konuş. "Merhaba arkadaşlar bomba A'da" → "Hello friends bomb is at A"
**Nasıl:** Windows Speech Recognition API (yerleşik) veya Whisper API (daha doğru).
**Rakip karşılaştırma:** RSTGameTranslation ve Live Translate bunu yapıyor. Biz de yapmalıyız.

| Metrik | Değer |
|--------|-------|
| Etki | ⭐⭐⭐⭐⭐ |
| Efor | 16-20 saat |
| Risk | Yüksek (gürültü, doğruluk) |
| Öncelik | 🟡 Yüksek |

---

## 5. 📜 Çeviri Geçmişi & İstatistikler
**Ne:** Tüm çevirileri logla. Son 100 çeviriyi göster. İstatistik paneli.
**Gösterilecekler:**
- Zaman damgası
- Kaynak metin → Çevrilmiş metin
- Hangi motor kullanıldı (Google/MyMemory/DeepL)
- En çok çevrilen dil çiftleri
- Toplam çeviri sayısı
**Neden:** "Az önce ne çevirmişti?" sorusuna yanıt + kullanıcı davranış analizi.

| Metrik | Değer |
|--------|-------|
| Etki | ⭐⭐⭐ |
| Efor | 4-6 saat |
| Risk | Düşük |
| Öncelik | 🟢 Orta |

---

## 6. ⌨️ Kısayol Tuşu Özelleştirme
**Ne:** Tüm tetikleyici tuşları ayarlardan değiştir.
**Yapılandırılabilir tuşlar:**
- Chat açma tuşları (şu an Y/U/Enter — hardcoded)
- Çeviri tetikleme karakterleri (şu an . ! ?)
- OCR kısayolu (örn: Ctrl+Shift+T)
- Quick Phrases tuşları (F1-F12)
- Mod değiştirme (Ctrl+Alt+B = Bubble toggle)
**Neden:** Her oyunun farklı tuş düzeni var. Valorant'ta chat tuşu Enter, CS2'de Y.

| Metrik | Değer |
|--------|-------|
| Etki | ⭐⭐⭐⭐ |
| Efor | 5-7 saat |
| Risk | Düşük |
| Öncelik | 🟡 Yüksek |

---

## 7. 📐 OCR Bölge Seçimi (Region Capture)
**Ne:** Ekranda dikdörtgen çiz → o bölgeyi sürekli OCR'la → çevirileri overlay göster.
**Kullanım:** Yabancı oyun chat bölgesine sabitleyip sürekli otomatik çeviri.
**Nasıl:** Transparent overlay penceresi + periodic screen capture + OCR pipeline.
**Rakip karşılaştırma:** Gaminik ve OCR Game Translator'ın en çok beğenilen özelliği.

| Metrik | Değer |
|--------|-------|
| Etki | ⭐⭐⭐⭐⭐ |
| Efor | 8-12 saat |
| Risk | Orta |
| Öncelik | 🟡 Yüksek |

---

## 8. 🤬 Küfür Filtresi
**Ne:** Çevirilen metindeki küfürleri otomatik sansürle veya temizle.
**Modlar:**
- `Kapalı` — filtreleme yok
- `Yıldız` — "f**k" gibi yıldızla
- `Temiz` — tamamen kaldır
- `Emoji` — küfür yerine 🤬 koy
**Neden:** Yayıncılar (streamers) için kritik. Twitch/YouTube'da küfür ban sebebi.

| Metrik | Değer |
|--------|-------|
| Etki | ⭐⭐⭐ |
| Efor | 3-4 saat |
| Risk | Düşük |
| Öncelik | 🟢 Orta |

---

## 9. 🎮 Çoklu Oyun Profilleri
**Ne:** Her oyun için farklı ayar seti kaydet ve hızlıca değiştir.
**Profil içeriği:**
```
📁 CS2 Profili
├── Chat tuşları: Y, U
├── Kaynak dil: auto
├── Hedef dil: en
├── Modlar: Input ✅, Bubble ❌
└── Çevirme listesi: "gg", "wp", "ez", "clutch"

📁 Valorant Profili
├── Chat tuşları: Enter, /all
├── Kaynak dil: auto
├── Hedef dil: tr
├── Modlar: Input ✅, Bubble ✅
└── Çevirme listesi: "ace", "sage", "jett"

📁 Masaüstü Profili
├── Chat tuşları: yok
├── Kaynak dil: auto
├── Hedef dil: tr
├── Modlar: Input ❌, Bubble ✅, Clipboard ✅
└── Çevirme listesi: yok
```
**Neden:** Her oyuna girdiğinde ayar değiştirmek zahmetli. Profille tek tık.

| Metrik | Değer |
|--------|-------|
| Etki | ⭐⭐⭐⭐ |
| Efor | 6-8 saat |
| Risk | Düşük |
| Öncelik | 🟡 Yüksek |

---

## 10. 📋 Clipboard Monitör Modu
**Ne:** Clipboard'a kopyalanan her metni otomatik çevir ve baloncuk göster.
**Kullanım:** Discord mesajı kopyala → anında çeviri baloncuğu. Web sitesinden metin kopyala → çeviri.
**Nasıl:** Clipboard listener (C++ `AddClipboardFormatListener`) + mevcut çeviri pipeline.
**Ek:** Minimum karakter limiti (2+), aynı metin tekrar çevrilmez (cache).

| Metrik | Değer |
|--------|-------|
| Etki | ⭐⭐⭐ |
| Efor | 3-4 saat |
| Risk | Düşük |
| Öncelik | 🟢 Orta |

---

## 📊 Özet Tablo

| # | Özellik | Etki | Efor | Risk | Rakiplerde Var? |
|---|---------|------|------|------|-----------------|
| 1 | OCR Ekran Çevirisi | ⭐⭐⭐⭐⭐ | 12-16h | Orta | ✅ Hepsinde |
| 2 | Gemini AI Motoru | ⭐⭐⭐⭐⭐ | 4-6h | Düşük | ⚠️ Bazılarında |
| 3 | Quick Phrases | ⭐⭐⭐⭐ | 6-8h | Düşük | ❌ Hiçbirinde |
| 4 | Sesli Çeviri | ⭐⭐⭐⭐⭐ | 16-20h | Yüksek | ⚠️ Bazılarında |
| 5 | Çeviri Geçmişi | ⭐⭐⭐ | 4-6h | Düşük | ❌ Hiçbirinde |
| 6 | Hotkey Ayarları | ⭐⭐⭐⭐ | 5-7h | Düşük | ⚠️ Bazılarında |
| 7 | OCR Bölge Seçimi | ⭐⭐⭐⭐⭐ | 8-12h | Orta | ✅ Hepsinde |
| 8 | Küfür Filtresi | ⭐⭐⭐ | 3-4h | Düşük | ❌ Hiçbirinde |
| 9 | Oyun Profilleri | ⭐⭐⭐⭐ | 6-8h | Düşük | ❌ Hiçbirinde |
| 10 | Clipboard Monitör | ⭐⭐⭐ | 3-4h | Düşük | ⚠️ Bazılarında |

---

## 🎯 Önerilen Yol Haritası

```
🔴 Sprint 1 (Bu Hafta): Gemini AI + Hotkey Config + Clipboard Monitor
   → 12-17 saat | Hızlı kazanımlar

🟡 Sprint 2 (Gelecek Hafta): Quick Phrases + Oyun Profilleri + Çeviri Geçmişi + Küfür Filtresi
   → 19-26 saat | UX zenginleştirme

🟢 Sprint 3 (2 Hafta Sonra): OCR Ekran + OCR Bölge Seçimi
   → 20-28 saat | Büyük rekabet özelliği

🔵 Sprint 4 (3 Hafta Sonra): Sesli Çeviri
   → 16-20 saat | Killer feature
```

---

## 🏆 Benzersiz Avantajlarımız (Rakiplerde YOK)
1. ✅ **Input Mode** — Yazıyı anında çevir-değiştir
2. ✅ **CS2 Chat Mode** — Oyun chat'ini otomatik algıla
3. 🔜 **Quick Phrases** — Tek tuşla hazır çeviri
4. 🔜 **Oyun Profilleri** — Oyuna özel ayar seti
5. 🔜 **Küfür Filtresi** — Yayıncılar için temiz çeviri

*Bu rapor Feature Adviser skill + Sequential Thinking MCP + Web Research ile oluşturuldu.*
