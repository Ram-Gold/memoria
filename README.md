# Memoria (メモリ) — AI Language-Learning Polaroid Camera

> **"Learn a language one physical memory at a time."**  
> Memoria transforms everyday surroundings into authentic, pedagogically sound, and tactile Polaroid keepsakes. Snap a photo of anything in your world, shake your device to develop the analog emulsion, and receive authentic vocabulary, native script, pronunciation, and real-world example sentences.

---

## 📷 Product Philosophy & Sensory Rituals

Memoria bridges analog nostalgia and multimodal language learning:

1. **Sensory Latency Masking**: Instead of traditional loading spinners, inference latency (2–4s) is synchronized directly with the physical **"Shake to Develop"** ritual using mobile accelerometer agitation (>14 m/s²) and mechanical shutter soundscapes.
2. **Pedagogical Restraint**: Rather than overwhelming the learner with busy textbook worksheets, Memoria isolates the primary focal object onto an authentic Polaroid print with handwritten script, preserving secondary recognized objects in the latent photo for interactive tap discovery.
3. **Authentic Native Orthography**: Strictly enforces native writing systems:
   - **Japanese**: Kanji + Kana + Hepburn Romaji (JLPT N5–N1)
   - **Tagalog / Filipino**: Modern Tagalog + Classical Baybayin Unicode transliteration
   - **Spanish / French / German**: Proper grammatical gender articles and agreement
   - **Mandarin Chinese**: Simplified/Traditional Hanzi + Pinyin with tonal markers

---

## 🧠 Multi-Agent Architecture & Inference Pipeline

```
[ Mobile Camera Sensor ]
           │ (Raw Capture Frame)
           ▼
┌──────────────────────────────────────────────────────────────┐
│ 1. Perception & Framing Agent (Multimodal Vision Engine)     │
│    - Multi-object segmentation & bounding box extraction     │
│    - Scene context & primary subject saliency scoring        │
└──────────────────────────────┬───────────────────────────────┘
                               │ Structured Bounding Boxes + Scene Context
                               ▼
┌──────────────────────────────────────────────────────────────┐
│ 2. Pedagogical Lexicon Agent (Linguistics & Orthography)     │
│    - Target language vocabulary selection & level grading    │
│    - Authentic transliteration / pronunciation guide         │
│    - Part-of-speech classification & CEFR/JLPT tagging       │
└──────────────────────────────┬───────────────────────────────┘
                               │ Enriched Object Payload
                               ▼
┌──────────────────────────────────────────────────────────────┐
│ 3. Sentence & Corpus Pipeline (Tatoeba + Gemini AI + Fallback)│
│    - Tier 1: Tatoeba Open Corpus (real-world sentences)      │
│    - Tier 2: Gemini 2.0 Flash (context-aware AI generation)  │
│    - Tier 3: Deterministic offline grammar templates         │
└──────────────────────────────┬───────────────────────────────┘
                               │ Final Render Payload
                               ▼
┌──────────────────────────────────────────────────────────────┐
│ 4. Composition & Layout Engine                               │
│    - Tactile Polaroid chin formatting & handwritten script   │
│    - Washi tape, organic tilt (-2° to +2°), and rubber stamp │
└──────────────────────────────┬───────────────────────────────┘
                               ▼
              [ Developed Polaroid in Scrapbook ]
```

---

## 🛠️ Technology Stack & APIs

Memoria is built with Flutter and a decoupled multimodal backend:

### Client & Core Framework
- **Flutter 3.x / Dart 3**: Multiplatform mobile client with pattern matching and sound null safety.
- **State Management**: [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) for reactive state isolation and dependency injection.
- **Local Persistence**: 
  - `sqflite` (SQLite) for Polaroid metadata, recognized object boxes, and journal history.
  - `shared_preferences` for zero-latency persistent caching of sentences and user language preferences.
- **Physical Sensors & Audio**:
  - `sensors_plus`: Real-time accelerometer listening for device agitation during development.
  - `audioplayers`: Analog mechanical shutter clicks, roller agitation, and development chimes.
  - `flutter_tts`: Native platform text-to-speech engine for multi-lingual pronunciation.

### Vision & Multimodal AI Layer
- **Google Gemini 2.0 Flash (`gemini-2.0-flash`)**: High-throughput multimodal VLM utilized for:
  - 2D normalized object bounding boxes (`[ymin, xmin, ymax, xmax]`).
  - Vocabulary translation into authentic native orthography.
  - Strict JSON output enforcement via `responseSchema`.
- **Local On-Device Engine**: MediaPipe / Gemma 2B VLM integration ready for zero-network edge operation.

### Bilingual Sentence & Corpus Engine
- **Tatoeba Open Corpus API**: Directly queries the open multilingual sentence database (the underlying corpus behind Jisho and major bilingual tools) to source authentic native sentences with verified translations.
- **Baybayin Transliteration Engine**: Custom in-engine deterministic Tagalog-to-Baybayin Unicode transliterator (U+1700–U+171F).
- **External Exploration**: Deep integration with contextual language resources (Jisho, Reverso Context, Tagalog.com, MDBG Chinese, and Google exact-match search).

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>= 3.5.0)
- Android Studio / Xcode with physical device or simulator
- A Google Gemini API key (from [Google AI Studio](https://aistudio.google.com/))

### Environment Configuration
Create a `.env` file in the root of the project:

```env
# Google Gemini API Key for Multimodal Vision & Contextual Sentences
GEMINI_API_KEY=your_gemini_api_key_here
```

### Installation & Run

1. Clone repository and install dependencies:
   ```bash
   git clone https://github.com/your-username/memoria.git
   cd memoria
   flutter pub get
   ```

2. Run on a connected device:
   ```bash
   flutter run
   ```

---

## 🧪 Testing & Code Quality

Memoria maintains a complete test suite covering the Baybayin engine, confidence calibrators, image downscaling, lexicon translations, sentence services, and UI smoke tests.

```bash
# Run all unit and widget tests
flutter test

# Run static analysis
flutter analyze
```

---

## 📄 License
This project is open-source under the MIT License.
