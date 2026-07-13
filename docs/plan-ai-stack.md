# Plan: AI Vibecoding Stack untuk arinanoX (proot, ARM64, Termux)

**Status: ✅ Tervalidasi** — semua tool terinstal dan berfungsi di proot ARM64.

---

## Ringkasan Instalasi

```bash
# 0. Start arinanoX (udah include PROOT_NO_SECCOMP=1)
bash ~/.shortcuts/1-start-arinanox.sh

# 1. Pi (di dalam proot)
npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# 2. lean-ctx binary (musl ARM64)
curl -fsSL https://github.com/yvgude/lean-ctx/releases/download/v3.9.8/lean-ctx-aarch64-unknown-linux-musl.tar.gz -o /tmp/lean-ctx.tar.gz
tar xzf /tmp/lean-ctx.tar.gz -C /tmp
cp /tmp/lean-ctx /usr/local/bin/
lean-ctx init --global
lean-ctx init --agent pi

# 3. DeepSeek models.json
mkdir -p ~/.pi/agent
# (isi models.json — lihat config di bawah)

# 4. ddg_search (install dari Termux, target rootfs proot)
npm install --prefix /data/data/.../rootfs/usr -g @oevortex/ddg_search

# 5. Firefox user.js
cp user.js ~/.mozilla/firefox/*.default-esr/
```

---

## 1. Peta Fungsi → Tool

| # | Fungsi | Tool | Status |
|---|---|---|---|
| 0 | Base OS/desktop | **arinanoX** (Debian 13) | ✅ |
| 1 | Agent orchestration | **Pi** (`@earendil-works/pi-coding-agent`) | ✅ v0.80.6 |
| 2 | Kompresi konteks | **lean-ctx** | ✅ v3.9.8 binary musl |
| 3 | Permission/safety gate | **pi-permission-system** (extension TS) | ⏳ Belum dipasang |
| 4 | Model provider | **DeepSeek API** | ✅ models.json siap |
| 5 | Web search | **`@oevortex/ddg_search`** via CLI/MCP | ✅ Mode AI (IAsk) jalan |
| 6 | Gateway Telegram | **`@gamalan/pi-gateway`** | ⏳ Clone timeout, perlu test ulang |

---

## 2. Catatan Validasi Proot ARM64

### PROOT_NO_SECCOMP=1 (WAJIB)
Semua tool Node.js (Pi, ddg_search, pi-gateway) butuh `export PROOT_NO_SECCOMP=1` sebelum `proot-distro login` untuk fix tiga bug:

| Bug | Tanpa Fix | Dengan Fix |
|---|---|---|
| `uv__io_poll: Assertion 'errno == EINTR'` | Crash di event loop Node | ✅ Normal |
| `fork: Function not implemented` | Gagal spawn process | ✅ Normal |
| `futex` error | Gagal thread sync V8/libuv | ✅ Normal |

Sudah ditambahkan ke `~/.shortcuts/1-start-arinanox.sh`.

### Side Effect PROOT_NO_SECCOMP=1
- ❌ `su - admin` gagal (setuid diblok) → Ganti dengan `proot-distro login -u admin`
- ❌ Shebang `#!/usr/bin/env node` gagal → Semua tool Node dipanggil via `node /path/to/cli.js`
- ✅ lean-ctx binary Rust (musl statis) tidak terpengaruh

### Invocation Pattern untuk Tool Node
```bash
# Jangan panggil langsung (shebang broken):
pi --help              # ❌
ddg "query"            # ❌

# Panggil via node:
node /usr/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js --help  # ✅
node /usr/lib/node_modules/@oevortex/ddg_search/bin/cli.js "query"            # ✅
```

### MCP Config (`~/.pi/agent/mcp.json`)
```json
{
  "mcpServers": {
    "ddg-search": {
      "command": "node",
      "args": [
        "/usr/lib/node_modules/@oevortex/ddg_search/bin/cli.js",
        "--server"
      ],
      "env": {
        "NODE_TLS_REJECT_UNAUTHORIZED": "0"
      }
    }
  }
}
```

### DeepSeek Models (`~/.pi/agent/models.json`)
```json
{
  "providers": {
    "deepseek": {
      "baseUrl": "https://api.deepseek.com",
      "api": "openai-completions",
      "apiKey": "$DEEPSEEK_API_KEY",
      "models": [
        {
          "id": "deepseek-chat",
          "name": "DeepSeek V4 Chat",
          "contextWindow": 1000000,
          "maxTokens": 384000,
          "input": ["text"],
          "reasoning": false,
          "compat": {
            "requiresReasoningContentOnAssistantMessages": false,
            "thinkingFormat": "deepseek"
          }
        }
      ]
    }
  }
}
```

### Firefox user.js
- Lokasi: `~/.mozilla/firefox/*.default-esr/user.js`
- 126 lines — WebRender software, HW accel mati, disk cache mati, network hemat, privasi moderat
- Aman untuk proot + virgl

---

## 3. Keterbatasan & Workaround

| Keterbatasan | Workaround |
|---|---|
| DuckDuckGo diblokir dari Indonesia (DNS redirect ke ::1) | `ddg_search --mode ai --backend iask` (IAsk AI — berfungsi) |
| `#!/usr/bin/env node` broken di proot | Panggil via `node /path/to/cli.js` |
| `su - admin` broken dengan PROOT_NO_SECCOMP=1 | `proot-distro login -u admin` (sudah di start script) |
| npm install dari dalam proot kadang crash (libuv) | Install dari Termux host dengan `--prefix $ROOTFS/usr -g` |
| Git clone lambat (jaringan via bind-mount) | Download manual / package manager |
| `NODE_TLS_REJECT_UNAUTHORIZED` untuk IAsk | Sudah di env MCP config |

---

## 4. Jalur Upgrade

- **pi-permission-system**: Tambah extension setelah Pi berjalan stabil
- **pi-gateway**: Test ulang install (butuh git clone)
- **headroom**: Sebagai addon lean-ctx (`lean-ctx addon add headroom`) — kalau butuh cross-agent memory

---

## 5. Perintah Cepat

```bash
# Start desktop (otomatis PROOT_NO_SECCOMP=1)
bash ~/.shortcuts/1-start-arinanox.sh

# Di sesi proot:
lean-ctx doctor           # cek health
lean-ctx gain --deep      # lihat token savings

# Panggil Pi (via node langsung)
node /usr/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js

# Search (via node, mode AI karena DDG diblokir)
NODE_TLS_REJECT_UNAUTHORIZED=0 node \
  /usr/lib/node_modules/@oevortex/ddg_search/bin/cli.js \
  --mode ai --backend iask "query"

# Set DeepSeek key
export DEEPSEEK_API_KEY="sk-xxxxxxxx"
```

---

## 8. FAQ: Kenapa Binary Termux Bisa Terlihat dari Proot?

Proot menggunakan **bind-mount** untuk memberikan akses container ke filesystem Termux. Dari daftar argumen proot:

```
--bind=/data/data/com.termux/files/usr
```

Ini memetakan **seluruh direktori `/usr` Termux** ke dalam container di path yang sama (`/data/data/com.termux/files/usr`).

### Binary apa saja yang bisa diakses?
**Semua binary Termux** — karena bind-mount-nya di level direktori `/usr`, bukan file spesifik:

| Kategori | Contoh | Path di proot |
|---|---|---|
| Runtime | `node`, `python3` | `/data/data/.../files/usr/bin/node` |
| Tools | `curl`, `git`, `wget` | `/data/data/.../files/usr/bin/curl` |
| Libraries | `.so` files | `/data/data/.../files/usr/lib/...` |
| Config | `/etc` files | `/data/data/.../files/usr/etc/...` |

### Tapi bisakah binary Termux dijalankan dari proot?
**Tidak bisa** — walaupun terlihat, binary Termux tidak bisa di-execute dari dalam proot karena linker dan libc berbeda:

```bash
# Dari dalam proot — ini akan gagal:
/data/data/com.termux/files/usr/bin/node --version
# Error: No such file or directory (linker mismatch)
```

### Kenapa tidak conflict dengan binary proot?
Karena **PATH container tidak include** path Termux:
```bash
export PATH=/usr/local/bin:/usr/bin:/bin:...
```

Jadi `which node` → `/usr/bin/node` (milik proot/glibc), bukan `/data/data/.../usr/bin/node` (milik Termux/bionic).

### Bedanya binary proot vs Termux

| Aspek | Termux Binary | Proot Binary |
|---|---|---|
| **libc** | bionic (Android NDK) | glibc (Debian) |
| **linker** | `/system/bin/linker64` | `/lib/ld-linux-aarch64.so.1` |
| **ELF type** | `interpreter /system/bin/linker64` | `interpreter /lib/ld-linux-aarch64.so.1` |
| **Dependencies** | Android system libs | Debian glibc libs |
| **Can run in proot?** | ❌ (linker mismatch) | ✅ |
| **Can run in Termux?** | ✅ | ❌ (glibc not available) |

### Kesimpulan
Bind-mount `/usr` Termux adalah **fitur, bukan bug** — berguna untuk sharing data (TAPI utils, storage Android), tapi binary-nya tetap tidak bisa dijalankan silang karena perbedaan ABI. PATH container sudah benar指向 proot-native. Jangan pindahkan binary Termux ke PATH proot.
