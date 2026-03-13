# LensAI 👁️

> Point. Shoot. Understand China.

A cultural visual guide for foreigners in China — not a translator. Snap a photo of any Chinese text, menu, sign, medicine, or form and get an instant, context-aware cultural explanation powered by AI.

---

## The Problem

Foreigners in China face a unique challenge: **Google's entire ecosystem doesn't work** — no Google Maps, no Google Search, no Google Translate camera. The entire digital world runs on Chinese-only apps (WeChat, Alipay, 高德地图, 大众点评). Even with translation tools, you get word-for-word output with zero cultural context.

**"麻辣香锅" → "Spicy Fragrant Pot"** — then what?

You don't know how spicy it is, whether it has peanuts, how to order it, or that you're supposed to pick raw ingredients at a counter.

LensAI goes further — it explains **what something means for you as a foreigner**, not just what the characters say.

---

## What It Does

| You point at | LensAI tells you |
|---|---|
| 🍜 A restaurant menu | Dish name, taste profile, cultural context, how to order |
| 🚇 A subway sign | What it means and what action to take |
| 💊 A medicine box | Usage, dosage, and warnings in plain English |
| 📄 A form or document | What each field means and how to fill it |
| 🚧 A warning sign | Whether it's serious and what to do |

---

## Core Innovation: Ask the Chef 🧑‍🍳

AI can tell you **general** information about a dish, but **every restaurant is different** — the same dish at two shops may use completely different ingredients. AI cannot know if this specific restaurant puts peanuts in their 麻辣香锅.

**Ask the Chef** solves this honestly:

1. AI gives you general cultural context + common allergens
2. You tap "Ask the Chef" → hand your phone to the restaurant staff
3. Staff sees a **bilingual Chinese checklist** — no English needed
4. They tap through 4 simple forms:
   - **12 allergens** (3-state: contains ✓ / doesn't contain ✗ / skip)  
     Peanut, tree nuts, shellfish, fish, egg, dairy, soy, wheat/gluten, sesame, celery, mustard, sulfites
   - **5 spice levels** (不辣 / 微辣 / 中辣 / 辣 / 特辣)
   - **8 dietary items** (pork, beef, lard, alcohol, MSG, cilantro, Sichuan peppercorn, sugar)
   - **Custom questions** + free-form note
5. Staff taps "Done" → thank you screen → hands phone back
6. User sees confirmed results in English with color-coded allergen cards

**AI handles the knowledge layer. Humans handle the confirmation layer.**

---

## User Flow

```
Open camera (QR-style viewfinder)
       ↓
Point at anything Chinese — tap shutter or pick from library
       ↓
AI analyzes image (Gemini 2.0 Flash)
       ↓
Progress animation: Detecting → Identifying → Analyzing → Done ✓
       ↓
Result card: What It Is / Cultural Context / Tips / Allergen Warning
       ↓                                              ↓
  [Save to History]                           [Ask the Chef]
                                                      ↓
                                          Hand phone to staff
                                                      ↓
                                    Staff checks bilingual form (4 steps)
                                                      ↓
                                         Thank you → Hand back
                                                      ↓
                                      User sees confirmed English results
```

---

## Screens

### 1. Home
Warm greeting + single "Scan something" CTA + recent scan history + tips.

### 2. Scanner
QR-code style camera viewfinder — no mode selection, no categories. Point at anything, tap the shutter. Also supports photo library import. Scan line animation indicates the camera is active.

### 3. AI Scan Animation
Photo thumbnail with progress bar and real-time status messages:
- Detecting Chinese text...
- Identifying content...
- Analyzing meaning & context...
- Generating cultural explanation...
- Done ✓

### 4. Result
Structured AI analysis with sections:
- **What It Is** — 1-2 sentence identification
- **Cultural Context** — 2-3 sentences of background
- **Practical Tips** — what to do, what to say
- **Allergen Warning** — common allergens (with disclaimer: "General info — actual ingredients vary by restaurant")
- **Ask the Chef** button (food items only)
- **Save to History** button

### 5. Ask the Chef (4-step staff flow)
- Staff Home — dish name in large Chinese + 4 category buttons + back button
- Allergen Check — 12 items, 3-state toggle
- Spice Level — 5 options, single select
- Dietary / Ingredients — 8 items, multi-select
- Custom Questions — 3 yes/no + free-form note
- Done → Thank you → User result with color-coded confirmed allergens

### 6. History
Searchable, filterable local history. Category pills (All / Food / Sign / Product / Document). Relative timestamps.

---

## Design System

### Colors

| Token | Hex | Usage |
|-------|-----|-------|
| Ink | `#1A1A1A` | Primary text |
| Ink3 | `#555555` | Secondary text |
| Paper | `#F8F6F3` | Background |
| Accent | `#2D7A6F` | Interactive elements, scan line |
| Alert | `#C4564A` | Allergen warnings, danger |
| Food | `#C67B3C` | Food category |
| Sign | `#4A7FB5` | Sign category |
| Product | `#7B5EA7` | Product category |
| Document | `#B86B4A` | Document category |

### Typography
- **Display** — Serif (system serif) for titles, humanistic warmth
- **Body** — Sans-serif (system) for UI, geometric precision
- **Chinese** — Noto Serif SC for Chinese text rendering

### Design Principles
- Extreme minimalism — no unnecessary UI elements
- Paper-and-ink warmth — not cold tech, not generic AI
- Bilingual by design — Chinese for staff, English for user
- Honest AI — general knowledge clearly labeled, confirmation deferred to humans
- Unified scanner — one viewfinder for everything, no mode switching

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| Camera | AVFoundation |
| AI | Google Gemini 2.0 Flash (via REST API) |
| Local Storage | SwiftData |
| Networking | URLSession (async/await) |
| Minimum iOS | 17.0 |

---

## Project Structure

```
LensAI/
├── LensAIApp.swift         # App entry point + TabView navigation
├── Theme.swift              # Design tokens (colors, hex extension)
├── Models.swift             # ScanResult, HistoryItem, ChefConfirmation,
│                            # Allergen, SpiceLevel, DietaryItem, CustomQuestion
├── GeminiService.swift      # Google Gemini API integration
├── CameraHelpers.swift      # AVFoundation preview + image picker
├── HomeView.swift           # Landing screen
├── ScannerView.swift        # QR-style camera viewfinder
├── ResultView.swift         # AI result display + Ask the Chef CTA
├── HistoryView.swift        # Saved scans with search/filter
└── AskTheChefFlow.swift     # Complete staff confirmation flow (7 sub-views)
```

---

## Getting Started

### Prerequisites
- Mac with macOS 14+
- Xcode 15+
- Google AI Studio API key → [Get one here](https://aistudio.google.com/apikey)

### Setup

1. **Create new Xcode project**
   - File → New → Project → App
   - Product Name: `LensAI`, Interface: SwiftUI, Language: Swift

2. **Delete default files**
   - Remove `ContentView.swift` and auto-generated `LensAIApp.swift`

3. **Add source files**
   - Drag all 10 `.swift` files into the project
   - Check "Copy items if needed", Target: LensAI

4. **Set API key**
   - Open `GeminiService.swift`, replace the API key string

5. **Add camera permission** (optional for simulator)
   - Project → Info → add `Privacy - Camera Usage Description`

6. **Run** — Select iPhone simulator → ⌘R

---

## Target Market

**Primary:** International travelers visiting China (tourist visa, 144-hour transit)

**Secondary:** Expats, business travelers, exchange students

**Why now:** China expanded visa-free entry to 38+ countries in 2024-2025. Inbound tourism is surging, but the digital infrastructure gap (no Google, cashless society, Chinese-only apps) creates massive friction.

---

## Competitive Positioning

| | Google Translate | DeepL | LensAI |
|---|---|---|---|
| Word translation | ✅ | ✅ | ✅ |
| Cultural context | ❌ | ❌ | ✅ |
| Practical tips | ❌ | ❌ | ✅ |
| Allergen warnings | ❌ | ❌ | ✅ |
| Ask the Chef | ❌ | ❌ | ✅ |
| Works in China | ⚠️ VPN needed | ⚠️ Limited | ✅ Native |

**Positioning:** LensAI is not a translator. It's a cultural guide that happens to read Chinese.

---

## Roadmap

- [x] Core photo scan + AI analysis
- [x] Ask the Chef bilingual checklist
- [x] History with SwiftData
- [x] Category tagging + allergen system
- [ ] Real-time camera scan (live viewfinder OCR)
- [ ] Offline mode with cached common items
- [ ] Share result as image card
- [ ] Multi-language support (Japanese, Korean)
- [ ] iPad layout
- [ ] Voice output (speak Chinese phrases for the user)

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

*Made with ♥ for every foreigner who's ever stared at a Chinese menu and pointed at random.*
