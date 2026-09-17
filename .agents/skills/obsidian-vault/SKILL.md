---
name: obsidian-vault
description: Interaksi dengan Obsidian Vault melalui Obsidian MCP server. Gunakan untuk mencari konteks proyek, membaca preferensi pengguna, melihat arsitektur & guideline, atau mencatat keputusan baru ke vault.
---

# Obsidian Vault MCP Skill

Gunakan skill ini untuk menyelaraskan pekerjaan dengan pengetahuan dan preferensi pengguna yang tersimpan di Obsidian Vault.

## Alur Kerja (Workflow)

1. **Pemeriksaan Konteks di Awal (Pre-Task Check)**:
   - Sebelum mengeksekusi tugas besar atau perancangan arsitektur, panggil alat pencarian MCP Obsidian (misal: search, read_note, list_files).
   - Kueri kata kunci relevan seperti: nama proyek (`LumaApp`), arsitektur (`flutter`, `clean architecture`, `riverpod`), preferensi coding, atau guidelines.

2. **Penerapan Konvensi**:
   - Terapkan aturan dan gaya kode yang ditemukan pada implementasi kode.

3. **Sinkronisasi (Knowledge Retention)**:
   - Jika ada keputusan baru yang penting dibuat bersama pengguna, tawarkan untuk mencatatnya kembali ke file/folder yang sesuai di Obsidian Vault.
