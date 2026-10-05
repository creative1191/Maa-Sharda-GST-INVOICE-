# 🧾 B2B GST Tax Invoice Generator — Maa Sharda Enterprises

Client ko **shipping service ka GST-compliant invoice** banane wala tool.
Input file (label image / Delhivery PDF) se AWB + Consignee **auto-extract**,
fixed client profile se billing details, **reverse GST** (final total → base),
sequential invoice numbering.

## 🚀 Sabse simple use (aapka daily workflow)

```bash
python src/generate_gst_invoice.py --base_charge 590 --total_inclusive --doc label.png
```

- Client details `clients/default.json` se (ek baar bharein)
- AWB / Consignee / Destination pincode `--doc` file se (OCR / parser)
- `--total_inclusive` → amount = **final total (GST samet)**; base = total/1.18
- Invoice No auto: `MSE/2026-27/0001, 0002…`
- Output: `generated/GST_invoice_<AWB>.pdf` + `.html`

## 📁 Files

| File | Kaam |
|---|---|
| `src/gst_invoice_engine.py` | Core engine — layout, GST math, words, numbering |
| `src/generate_gst_invoice.py` | CLI (flags + profile + doc extraction) |
| `src/doc_extractor.py` | Image OCR / PDF se AWB + consignee auto-fill |
| `src/pdf_parser.py` | Delhivery invoice PDF parser (shared helper) |
| `src/embedded_assets.py` | Delhivery logo base64 |
| `clients/default.json` | **Aapke fixed client ki details** (ek baar bharein) |
| `clients/example.json` | Format sample |
| `generated/` | Invoices + counter file |
| `docs/MASTER_INSTRUCTION_FILE.md/.txt` | ⭐ Poora system context (naye AI chat me paste karein) |
| `assets/` + `uploads/` | Reference PNGs / purani invoice copies |

## ⚙️ Key Rules (zero exceptions)

- Product / Item Description / Product Value / COD / Quantity — **kahin nahi**
- Service: "Courier & Logistics Services", **SAC 9968**
- Supplier (header): Maa Sharda Enterprises, Near Rest House, Panna Satna Road,
  Nagod, Distt. Satna, MP - 485446, **GSTIN 23BCPPD5853C1ZT**
- GST: client state 23 → CGST 9% + SGST 9%, warna IGST 18%
  (inclusive mode me reverse calc — sum hamesha exact input ke barabar)
- Consignee sirf "Service & Shipment Details" box me — **BILLED TO = client hi**
- Header me sirf Maa Sharda branding; Delhivery sirf chhota icon AWB ke paas
- Weight field nahi hai (removed); Origin/Destination pincode hai

## 🔧 Dependencies

```bash
pip install -r requirements.txt
# Image OCR ke liye Tesseract binary bhi:
#   Windows: https://github.com/UB-Mannheim/tesseract/wiki
#   Ubuntu:  sudo apt install tesseract-ocr
```

## 📄 Examples

```bash
# Inter-state (IGST), inclusive total:
python src/generate_gst_invoice.py --base_charge 1180 --total_inclusive \
  --client_profile clients/example.json \
  --awb 34084710004266 --consignee "Kajal Singh Chandel" \
  --client_order_id "ORD-88123" --destination_pincode 122001
# → Base 1000 + IGST 180 = 1180

# Intra-state MP client (CGST+SGST):
python src/generate_gst_invoice.py --base_charge 500 \
  --client_name "Bhopal Retail Pvt Ltd" --client_gstin "23AACCU9603R1ZM" \
  --client_address1 "Plot 7, Industrial Area" --client_address2 "Bhopal, MP - 462001"
# → Base 500 + CGST 45 + SGST 45 = 590
```

Generated samples: `generated/SAMPLE_1_Meena.pdf`, `SAMPLE_2_Rahul.pdf`
(Purane customer-receipt records bhi `generated/` me preserved hain.)

## 🌐 Streamlit Web UI (naya folder: `streamlit_app/`)

Browser me invoice banane wala interface — `app.py` 5 backend modules (`../src`) ko import karta hai:

```bash
pip install -r requirements.txt
streamlit run streamlit_app/app.py
```

**Features:** AWB + amount input, ⚡ Generate button, PDF ⬇️ download, GST breakdown (Base/CGST/SGST/IGST/Total/Words), fixed client sidebar (profile se auto + save option), label/PDF upload → OCR auto-fill, invoice number auto/manual, inclusive/exclusive amount toggle.

## 📁 Invoice Archive (automatic)

Har nayi invoice **automatically** client ke month-folder me save hoti hai (sirf PDF), `generated/` se hat jaati hai:

```
Shree Mahadev/
└── 2026-09 September/
    ├── GST_invoice_Ankita_Singh_34084710004620.pdf
    ├── GST_invoice_SHUBHKAMNA_SINGH_34084710004631.pdf
    └── GST_invoice_MANJU_SINGH_34084710004642.pdf
```

- Month folder invoice **date** se banta hai (naya month = naya folder)
- HTML copy delete hoti hai — sirf PDF store hota hai
- Ye folder `.gitignore` me hai (GitHub pe nahi jayega)

## 🖥️ Windows EXE (Desktop App)

`src/gst_desktop.py` — Tkinter GUI (wahi workflow: PDF select → auto-extract →
weight + amount → generate → archive). EXE banane ke 2 tarike:

**Tarika 1 — Apne PC par (1 double-click):**
1. Ye folder apne PC par rakho (Python installed hona chahiye)
2. `build_exe.bat` double-click karo
3. EXE milegi: `dist/GST_Invoice_Generator.exe` (~25 MB)

**Tarika 2 — GitHub se automatic (Python bhi nahi chahiye!):**
1. Ye repo GitHub par push karo (`.github/workflows/build.yml` included)
2. GitHub → **Actions** tab → "Build Windows EXE" khud chalega
3. Complete hone par **Artifacts** se `GST_Invoice_Generator.exe` download karo
   (90 din tak available; `v1.0` jaisa tag push karke version bana sakte ho)

**EXE ki baatein:**
- Data (clients/, Shree Mahadev/ archive, counter) **exe ke folder** me banta hai
- Double-click → GUI khulti hai, koi browser/Python nahi chahiye
- Delhivery PDF parsing built-in; sirf IMAGE OCR ke liye Tesseract install karna
  hoga (warna sab kaam PDF se hota hai)
- Windows SmartScreen pehli baar "More info → Run anyway" kar sakte ho
  (unsigned exe me normal hai)
