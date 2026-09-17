# Obsidian Vault Integration & Project Context Rules

## 1. Context & Preference Retrieval via Obsidian MCP

- **Proactive Context Checking**: Sebelum merancang arsitektur, memulai fitur baru, refactoring, atau membuat keputusan teknis penting, selalu periksa/kueri catatan yang relevan di **Obsidian Vault** via MCP Server `obsidian`.
- **Fokus Pencarian**:
  - Catatan preferensi pengguna (*user preferences* & *coding conventions*).
  - Standar arsitektur proyek (misal: Flutter Clean Architecture, State Management dengan Riverpod/Provider, Design Systems).
  - Catatan proyek di folder `LumaApp/` (`00 - Index.md`, `01 - Project Overview & Tech Stack.md`, `02 - Architecture & Directory Structure.md`, dll).
  - Best practices di folder `Fullstack_Cheatsheets/Flutter/`.
  - Aturan kerja, roadmap, atau task requirements yang tersimpan di Vault.

## 2. Knowledge Synchronization & Memory

- Jika pengguna menetapkan keputusan arsitektur, aturan baru, atau preferensi spesifik selama percakapan:
  - Gunakan pemahaman tersebut secara konsisten.
  - Tawarkan atau bantu perbarui catatan di Obsidian Vault bila diperlukan agar pengetahuan tersimpan permanen.

## 3. Graceful Fallback

- Jika server MCP Obsidian tidak terhubung (misal aplikasi Obsidian sedang tertutup atau REST API plugin nonaktif), gunakan aturan lokal di proyek dan konfirmasi preferensi pengguna secara langsung tanpa memblokir pekerjaan.
