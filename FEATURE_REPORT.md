# 🔍 Quick Trace Pro — Feature Adviser Raporu
> Tarih: 2026-02-12 | Analiz: Tüm proje dosyaları tarandı (Flutter + Python + C++)

---

## 📊 Mevcut Durum Özeti

| Bileşen | Durum |
|---------|-------|
| Bubble Mode (Fare ile çeviri) | ✅ Çalışıyor |
| Input Mode (Klavye ile çeviri) | ✅ Çalışıyor |
| CS2 Chat Mode | ⚠️ Scan code fix yapıldı, test bekliyor |
| System Tray | ✅ Çalışıyor |
| Çift yönlü çeviri | ✅ Çalışıyor |
| 23 dil desteği | ✅ Çalışıyor |
| TR/EN arayüz | ✅ Çalışıyor |
| Native C++ hooks | ✅ Çalışıyor |
| Noktalama düzeltme | ✅ Çalışıyor |
| Ayar kalıcılığı | ✅ Çalışıyor |

---

## 🔥 Tier 1 — Hemen Yapılmalı (Yüksek Etki, Düşük Efor)

### 1. 🧠 Çeviri Önbelleği (Translation Cache)
**Ne:** Aynı metni tekrar tekrar API'ye göndermek yerine bellekte tut.
**Neden:** Aynı cümleleri sık sık yazarsın (özellikle oyunda). Her seferinde 200-500ms API bekleme yerine anında çeviri.
**Efor:** 2-3 saat
**Risk:** Düşük

### 2. 📖 Oyun Sözlüğü (Gaming Dictionary)
**Ne:** CS2'deki callout'lar (A site, B site, Long, Short, AWP, AK) çevrilMEMELİ. Kullanıcının "çevirme" listesi.
**Neden:** "Rush B" yazınca "B'ye koş" çevirmesi saçma. Oyun terimleri korunmalı.
**Efor:** 3-4 saat
**Risk:** Düşük

### 3. ❌ Kullanıcıya Hata Geri Bildirimi
**Ne:** Şu anda tüm `catch` blokları boş. Çeviri başarısız olduğunda kullanıcı fark etmiyor.
**Neden:** Hata olunca kullanıcı "bozuldu" sanıyor. Küçük bir toast/snackbar gösterilmeli.
**Efor:** 2-3 saat
**Risk:** Düşük

### 4. ⌨️ Kısayol Tuşu Özelleştirme (Hotkey Config)
**Ne:** CS2 chat tuşları (Y, U, Enter) ve tetikleyici karakterler (., !, ?) değiştirilebilir olmalı.
**Neden:** Bazı oyunlarda chat tuşu T veya farklı bir tuş. Şu anda hardcoded.
**Efor:** 4-5 saat
**Risk:** Düşük

---

## ⭐ Tier 2 — Rekabet Avantajı (Orta Efor)

### 5. 📜 Çeviri Geçmişi Paneli
**Ne:** Son 50 çeviriyi listeleyen, kopyalama butonu olan bir panel.
**Neden:** "Az önce ne çevirmişti?" sorusuna yanıt. Ayrıca sık kullanılan çevirileri görmek faydalı.
**Efor:** 4-5 saat
**Risk:** Düşük

### 6. 🔄 DeepL / LibreTranslate Fallback
**Ne:** Google Translate API başarısız olursa (rate-limit, kesinti) otomatik DeepL veya LibreTranslate'e geç.
**Neden:** Google free API her an engellenebilir. Tek API'ye bağımlılık tehlikeli.
**Efor:** 6-8 saat
**Risk:** Orta (DeepL API anahtarı gerekebilir)

### 7. 🪟 Küçük Yüzen Widget (Floating Mini Bar)
**Ne:** Ekranın köşesinde 50x20px tiny bar: mod göstergesi, çeviri durumu, drag ile taşınabilir.
**Neden:** Ana pencereyi tray'e atınca hiçbir görsel feedback kalmıyor. Kullanıcı uygulamanın çalışıp çalışmadığını bilemiyor.
**Efor:** 6-8 saat
**Risk:** Orta (always-on-top + game overlay uyumu)

### 8. 🎮 Çoklu Oyun Desteği
**Ne:** CS2 dışında Valorant, Dota 2, LoL chat algılama.
**Neden:** Pazar büyütmek. Her oyunun chat açma tuşu ve formatı farklı.
**Efor:** 8-10 saat
**Risk:** Orta (her oyun için ayrı test gerekir)

---

## 🚀 Tier 3 — Vizyoner Özellikler (Yüksek Efor)

### 9. 📴 Çevrimdışı Çeviri (Offline ML)
**Ne:** İnternetsiz çeviri için yerel ML modeli (NLLB-200, MarianMT).
**Neden:** İnternet kesildiğinde veya çok yüksek gecikme olduğunda yedek.
**Efor:** 16-20 saat
**Risk:** Yüksek (model boyutu, performans)

### 10. 🎙️ Sesli Çeviri (Voice → Text → Translate)
**Ne:** Mikrofon dinle → konuşmayı metne çevir → çevir → yapıştır.
**Neden:** Oyun içinde yazmak zor, konuşmak daha hızlı.
**Efor:** 12-16 saat
**Risk:** Yüksek (gürültü, doğruluk)

### 11. 🌐 Chrome Extension
**Ne:** Discord, web tabanlı oyunlar ve sosyal medya için tarayıcı eklentisi.
**Neden:** Masaüstü dışında da çalışma. Büyük kullanıcı kitlesi.
**Efor:** 20-30 saat
**Risk:** Yüksek

### 12. 👁️ OCR Ekran Çevirisi
**Ne:** Ekrandaki herhangi bir metni (oyun içi HUD, menüler) OCR ile oku ve çevir.
**Neden:** Kapalı metinleri (chat olmayan) de çevirebilme.
**Efor:** 15-20 saat
**Risk:** Yüksek (performans, doğruluk)

---

## ⚠️ Riskler ve Uyarılar

| Risk | Seviye | Açıklama |
|------|--------|----------|
| Google Translate API | 🔴 Yüksek | Ücretsiz endpoint her an engellenebilir |
| VAC/EAC Anti-Cheat | 🟡 Orta | SendInput + global hook = algılama riski |
| Admin yetkisi | 🟡 Orta | Kullanıcılar admin çalıştırmaya güvenmeyebilir |
| Python/Flutter çatallanma | 🟡 Orta | İki versiyon bakımı zor, birini deprecate et |
| Boş catch blokları | 🟡 Orta | Hatalar sessizce yutulıyor, debug imkansız |

---

## 🔧 Kod Kalitesi İyileştirmeleri

1. **Boş `catch` blokları** — Tüm `catch (e) {}` bloklarına en azından test modu için log ekle
2. **TranslationProvider monoliti** — 530+ satır, Chat/Bubble/Input mantıkları ayrı mixin'lere taşınmalı
3. **Hardcoded tuş kodları** — `vkCode == 89` yerine `AppConstants.chatOpenKeys` gibi sabitler
4. **Unit test yokluğu** — PunctuationService, TranslationService için test yazılmalı
5. **Python backend deprecation** — Flutter versiyonu artık ana sürüm, Python'u arşivle

---

## 📋 Önerilen Yol Haritası

```
Hafta 1: Çeviri Cache + Gaming Dictionary + Error Feedback
Hafta 2: Hotkey Config + Çeviri Geçmişi
Hafta 3: DeepL Fallback + Floating Widget
Hafta 4: Multi-game Support + Polish
```

---

*Bu rapor Feature Adviser skill'i ile otomatik oluşturulmuştur.*
