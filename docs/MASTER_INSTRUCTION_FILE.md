# MASTER INSTRUCTION FILE — B2B GST Tax Invoice System
## Maa Sharda Enterprises (Logistics Intermediary) — Courier & Logistics Service Invoicing

> **Purpose:** Paste this entire file into a fresh AI chat to give it 100% context.
> It contains the complete business model, legal constraints, approved UI layout
> (pixel-level), technical architecture, known bugs (already fixed — do not
> repeat), and the verification protocol for the Python/ReportLab invoice generator.

---

## SECTION 1: BUSINESS CONTEXT

### 1.1 The Firm
- **Firm Name:** Maa Sharda Enterprises
- **Role:** Logistics intermediary (freight forwarder/reseller of shipping services)
- **Routing Partner:** Delhivery (third-party courier used for physical delivery)
- **Supplier GSTIN:** `23BCPPD5853C1ZT` (State code 23 = Madhya Pradesh)
- **Registered Address (as per GST certificate — DO NOT change):**
  - Line 1: `Near Rest House, Panna Satna Road`
  - Line 2: `Nagod, Distt. Satna, Madhya Pradesh - 485446`
  - (Field-for-field from the certificate: Building=Near Rest House,
    Road=Panna Satna Road, Landmark/City=Nagod, District=Satna,
    State=Madhya Pradesh, PIN=485446)

### 1.2 The "Pass-Through" COD Model (critical to understand)
1. A **Business Client** (the B2B customer, e.g. an e-commerce seller) sells
   physical products to end-customers (often COD — Cash On Delivery).
2. The client hands shipments to Maa Sharda Enterprises, which books them on
   **Delhivery**. Delhivery's own invoice/PDF shows the **product value**
   (e.g. CLOTHS × 1 @ INR 2000) and end-customer details.
3. **Maa Sharda Enterprises bills ONLY the Client — and ONLY for the shipping
   service (freight) + GST.** The product's value and the COD amount belong to
   the Client's transaction with its end-customer — they are **pass-through**
   and must NEVER appear on our invoice.

### 1.3 Core Objective of the System
Generate a **legally compliant B2B "TAX INVOICE"** (PDF + HTML) from:
- Client details (name, address, GSTIN)
- Base shipping charge (taxable value, ₹)
- Shipment metadata (AWB, consignee name, client order ID, pincodes, weight)

The system computes GST automatically, formats the number to words, and emits
a pixel-perfect US Letter PDF.

### 1.4 Ecosystem Note (receipt tool REMOVED)
An older "Customer Receipt Tool" (receipt_tool.py, invoice_engine.py,
generate_invoice.py, tests, run.bat, build_exe.py, GitHub workflow, old spec
docs) coexisted with this system but was **deleted on user request** after the
GST-only workflow was confirmed. Only its *generated business records* remain
in `generated/` (receipt_*.pdf/html). Shared modules it used — `pdf_parser.py`
and `embedded_assets.py` — are still live dependencies of the GST system.
Do not recreate the receipt tool unless the user asks.

---

## SECTION 2: STRICT GST COMPLIANCE RULES (ZERO EXCEPTIONS)

### RULE G1 — ABSOLUTE EXCLUSION LIST (never print these anywhere)
- ❌ Product Name / Item Description (e.g. "CLOTHS")
- ❌ Product Value / Declared Value (e.g. INR 2000)
- ❌ COD Amount (total cash collected from end-customer)
- ❌ Quantity / Qty column

*Reason:* The invoice bills a **service** (freight), not goods. Product/COD data
belongs to the Client↔End-Customer relationship. Mentioning goods on a service
invoice misrepresents the supply and breaks GST compliance.

### RULE G2 — SERVICE IDENTIFICATION (mandatory on every invoice)
- Service Description (static): **"Courier & Logistics Services"**
- **SAC Code (static): `9968`** — must be permanently visible, right-aligned on
  the same horizontal row as Service Description (see Section 3.3).

### RULE G3 — GST CALCULATION LOGIC (18% on base freight)
Let `base` = Base Shipping Charge (Taxable Value), rounded 2dp half-up.
Determine client state code from the **first 2 digits of the client's GSTIN**
(fallback: client_state name lookup):

| Condition | Rows printed | Math |
|---|---|---|
| Client state code == `23` (MP, same as supplier) → **intra-state** | `Add: CGST @ 9%` AND `Add: SGST @ 9%` (two separate rows) | cgst = sgst = round(base × 0.09) |
| Client state code != `23` (or unknown/other state) → **inter-state** | `Add: IGST @ 18%` (one row) | igst = round(base × 0.18) |

- **Total Invoice Amount = base + cgst + sgst + igst** (never anything else)
- **Amount in Words** (Indian numbering: Crore/Lakh/Thousand) must follow the
  total, e.g. "One Thousand One Hundred Eighty Rupees Only".

### RULE G4 — PARTY DETAILS
- **Supplier block = HARDCODED** (name/address/GSTIN from Section 1.1). Never
  extract supplier details from any PDF.
- **Billed To block = the Business Client** (dynamic: name, address, GSTIN, state).
- **The Consignee (end-customer name) must NEVER appear in the BILLED TO block.**
  It appears only inside the Service & Shipment Details box as reconciliation data.

### RULE G5 — DOCUMENT IDENTIFICATION
- Title: **"TAX INVOICE"**
- Invoice Number: **sequential, FY-aware** — format `MSE/<FY>/####` e.g.
  `MSE/2026-27/0001`. Indian fiscal year runs **April→March** (a date in
  Feb 2027 belongs to FY 2026-27). Counter persisted in a text file
  (`generated/gst_invoice_counter.txt`, lines `FY: count`).
- Invoice Date: `YYYY-MM-DD` only — **time is NEVER printed** (existing
  `clean_date_string()` helper strips it).

### RULE G6 — GSTIN VALIDATION (warn, don't block)
- Regex: `^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$`
- CLI prints ⚠️ warnings for missing/invalid client GSTIN or placeholder
  supplier GSTIN. B2B invoices should carry the client's GSTIN (needed for ITC).

---

## SECTION 3: UI & LAYOUT BLUEPRINT (approved, pixel-level)

### 3.0 Page & Style Constants
- Page: **US Letter (612×792pt)**, margins **36pt** all sides → content width **540pt**
- Font: Helvetica / Helvetica-Bold
- Palette (exact):
  - Header/title `#0f172a` · body `#1e293b` · muted `#64748b` · semi-muted `#475569`
  - Border `#cbd5e1` · light border `#e2e8f0` · light bg `#f8fafc` · red `#d9534f`
- Styles: firm name 20pt bold; "TAX INVOICE" 15pt bold; section headers 10.5pt
  bold; body 10pt; small 9pt; financial labels 10.5pt (total row 11.5pt);
  words italic 9.5pt; declaration 8.5pt; footer 8pt centered.

### 3.1 Header (top of page)
```
┌────────────────────────────────────────────────────────┐
│ Maa Sharda Enterprises (20pt bold, LEFT)   TAX INVOICE (15pt bold, RIGHT) │
│ Near Rest House, Panna Satna Road, Nagod    Invoice No: MSE/2026-27/0001  │
│ Distt. Satna, Madhya Pradesh - 485446       Date: 2026-09-01             │
│ GSTIN: 23BCPPD5853C1ZT | State: MP (23)                                  │
└────────────────────────────────────────────────────────┘
→ then 1.5pt horizontal rule #cbd5e1
```
- **BRANDING RULE:** Only "Maa Sharda Enterprises" branding here.
- **The Delhivery logo is STRICTLY FORBIDDEN in the header.** It appears exactly
  once in the whole document: small icon in the Service & Shipment box (3.3).
- Table: `colWidths=[360, 180]`, VALIGN TOP, all paddings 0.

### 3.2 Billed To (single block — no FROM block)
```
BILLED TO (CLIENT)
<client_name> (bold)
<client_address1>
<client_address2>
GSTIN: <client_gstin or —>
State: <resolved from GSTIN> (code)
```
- Supplier details live ONLY in the header (3.1) — a separate "FROM
  (SUPPLIER)" block was removed on user request. `colWidths=[540]`.
- Supplier data is generated from constants — never from parsed data.

### 3.3 SERVICE & SHIPMENT DETAILS box  ← most iteration-sensitive area
Outer box: full width 540, **bg #f8fafc, border 0.5pt #e2e8f0, padding 15 L/R, 12 T/B**
→ inner usable width = **540 − 30 = 510pt**. Inner table **colWidths=[310, 200] (sum 510!)**

Row order (exact):
```
Row 0: SERVICE & SHIPMENT DETAILS (section header, SPAN both columns)
Row 1: AWB No / Tracking ID: <b><awb></b>            [Delhivery icon 52×9 + "Routing Partner: Delhivery"] (RIGHT)
Row 2: Consignee / Delivered To: <b><name></b>        Client Order ID: <b><id></b>
       (When generating from a Delhivery PDF, Client Order ID AUTO-FILLS
        from the PDF's "Sales Number" field — flag/manual input overrides)
Row 3: Service Description: Courier & Logistics Services    SAC Code: 9968 (RIGHT-ALIGNED, SAME ROW)
Row 4: [Origin Pincode | Destination Pincode | Weight]  (3-col specs sub-table, SPAN both columns)
```
- Row 3 mandatory appearance: label left-flush at box inner-left edge (x≈51),
  `SAC Code: 9968` right-flush at box inner-right edge (x1≈561) — same baseline.
- Specs sub-table: 3 equal columns (~166pt), header labels bold + bold values,
  thin top rule #e2e8f0.
- Empty optional values render as "—" (em dash), never blank or "None".

### 3.4 Financial Table (Base + GST = Total)
```
┌──────────────────────────────────────────────────────────┐
│ Base Shipping Charge (Taxable Value)          INR 1,000.00 │
│ Add: IGST @ 18%  (OR  Add: CGST @ 9% + Add: SGST @ 9%)      │
│──────────────────────────────────────────────────────────│
│ Total Invoice Amount (bold, bg #f8fafc,      INR 1,180.00 │ │
│ 1pt top border #0f172a)                                    │
│ Amount in Words: One Thousand One Hundred Eighty Rupees Only│
└──────────────────────────────────────────────────────────┘
```
- `colWidths=[360, 180]`; value column right-aligned; cell padding 12 L/R, 8 T/B.
- Amount-in-words row spans both columns, italic.
- Amounts formatted `INR 1,234.56` (comma thousands, 2 decimals).

### 3.5 Footer Area
- Declaration (left, 8.5pt muted): "We declare that this invoice shows the
  actual price of the service described… computer-generated… no physical signature."
- Signature block (right): "For Maa Sharda Enterprises" (bold) + gap +
  "Authorised Signatory"
- Thin 0.5pt rule + centered footer: "This is a computer-generated tax invoice
  for courier & logistics services. | Routing Partner: Delhivery"

### 3.6 HTML Twin
Every PDF change must be mirrored in `generate_gst_html()` (standalone HTML,
inline CSS, base64 Delhivery icon, print button + `@media print` rules).
Structure maps 1:1 to the PDF sections above.

---

## SECTION 4: TECHNICAL WORKFLOW (Python / ReportLab)

### 4.1 File Map (project: `Receipt_tool/`)
```
src/gst_invoice_engine.py    ← engine: constants, styles, calc_gst (+reverse),
                               words, numbering, normalize_gst_data,
                               build_gst_story, generate_gst_pdf /
                               generate_gst_html / generate_gst_invoice
src/generate_gst_invoice.py  ← CLI: flags + client profile + --doc extraction,
                               auto invoice no., prints GST breakdown
src/doc_extractor.py         ← OCR/document extraction (image/PDF → AWB,
                               consignee, destination pincode; label-aware
                               regexes + preprocessing)
src/pdf_parser.py            ← Delhivery invoice parser (shared: also provides
                               clean_date_string + deduplicate_line)
src/embedded_assets.py       ← Delhivery logo as base64 (get_logo_stream())
clients/default.json         ← FIXED client profile (auto Billed-To)
clients/example.json         ← profile format sample
generated/                   ← outputs: GST_invoice_<AWB>.pdf/.html +
                               gst_invoice_counter.txt (sequence state)
```

### 4.2 Input Data Contract (dict passed to `generate_gst_invoice`)
```python
{
  "invoice_num": "",              # empty → auto MSE/FY/NNNN
  "invoice_date": "2026-09-01",   # YYYY-MM-DD, time stripped
  "client_name": "Sharma Trading Co.",
  "client_address1": "42, Civil Lines",
  "client_address2": "Gurugram, Haryana - 122001",
  "client_gstin": "06ABCDE1234F1Z5",   # first 2 digits decide CGST/SGST vs IGST
  "client_state": "",              # optional fallback for state detection
  "base_charge": 1000.0,           # taxable value
  "awb": "34084710004266",
  "consignee_name": "Kajal Singh Chandel",   # end-customer (recon only!)
  "client_order_id": "ORD-88123",
  "origin_pincode": "485446",
  "destination_pincode": "122001",
  "weight": "0.5 kg",
}
```

### 4.3 Key Implementation Notes (ReportLab specifics)
- `SimpleDocTemplate(path, pagesize=letter, margins=36)`, platypus story build.
- Right alignment: `ParagraphStyle(..., alignment=2)` and/or TableStyle
  `("ALIGN", (col,row), (col,row), "RIGHT")`.
- **⚠ SPAN TRAP (caused a real bug):** `("SPAN", (0,r),(1,r))` indexes are
  ROW-POSITIONAL. Adding a row shifts every later row — every SPAN/ALIGN/
  padding directive must be re-indexed. Approved final indexes for the svc
  table: SPAN rows 0 and 4; ALIGN RIGHT at (1,1) and (1,3).
- **⚠ WIDTH TRAP (caused a real bug):** a nested table inside a padded box must
  use `box_width − horizontal_padding` (540−30=510). Oversized inner tables
  silently overflow the box border (~15pt past it).
- Money rounding: `Decimal.quantize(0.01, ROUND_HALF_UP)` — never float math.
- Sequential numbering writes back to the counter file — reset
  `generated/gst_invoice_counter.txt` to restart a FY sequence (e.g. after tests).

### 4.4 CLI Usage
```bash
python src/generate_gst_invoice.py \
  --client_name "Sharma Trading Co." \
  --client_address1 "42, Civil Lines" \
  --client_address2 "Gurugram, Haryana - 122001" \
  --client_gstin "06ABCDE1234F1Z5" \
  --base_charge 1000 \
  --awb "34084710004266" \
  --consignee "Kajal Singh Chandel" \
  --client_order_id "ORD-88123" \
  --origin_pincode 485446 --destination_pincode 122001 --weight "0.5 kg" \
  --out generated/GST_invoice.pdf
```

### 4.5 Mandatory Verification Protocol (run after ANY layout change)
Using `pdfplumber` on the output PDF:
1. **Forbidden-word scan (G1):** none of `Item Description, Qty, Quantity, COD,
   CLOTH, Product` may appear in extracted text.
2. **SAC row geometry:** "Service" and "SAC" words share the same `top` (±2pt);
   "9968" ends at x1≈561 (box inner-right); Service label starts x≈51.
3. **Overflow scan:** no word on the page may have `x1 > 577` (right margin).
4. **Order of rows:** AWB < Consignee/OrderID < Service/SAC < Pincodes.
5. **BILLED TO isolation:** consignee name must NOT appear between the
   "BILLED TO" and "SERVICE &" text anchors.
6. **Tax math:** same-state → CGST & SGST rows present, IGST absent (and vice
   versa); Total = base + taxes; words string present.
7. Single page, size 612×792, exactly ONE image (the small Delhivery icon).

### 4.6 Known Bugs Already Fixed — Never Reintroduce
| Bug | Root cause | Fix |
|---|---|---|
| SAC Code invisible | New Consignee row shifted rows; stale `SPAN (0,3)` swallowed the Service/SAC row | Re-index SPAN to row 4; keep SAC in row 3 |
| Content crossing box border | Inner table 540pt inside 510pt space | Inner `colWidths=[310,200]` |
| SAC not right-aligned | style used left-aligned `s_body` | `s_right` (alignment=2) + cell ALIGN |
| Time leaking into dates | raw Delhivery dates | `clean_date_string()` everywhere |

### 4.7 Change Request Checklist (for future edits)
1. Update `normalize_gst_data()` (new keys) → `build_gst_story()` → HTML twin.
2. Re-check every SPAN/ALIGN index against the new row order.
3. Regenerate BOTH test cases (inter-state IGST + intra-state CGST/SGST).
4. Run the full Section 4.5 verification protocol.
5. Never touch: supplier constants, GST math, exclusion list (G1), financial
   layout — unless the user explicitly requests a compliance change.

---

## APPENDIX A: Approved End-to-End Samples
- Inter-state (IGST): client "Sharma Trading Co." (06/Haryana), base ₹1000 →
  IGST ₹180 → **Total ₹1180** — "One Thousand One Hundred Eighty Rupees Only"
- Intra-state (CGST+SGST): client "Bhopal Retail Pvt Ltd" (23/MP), base ₹500 →
  CGST ₹45 + SGST ₹45 → **Total ₹590** — "Five Hundred Ninety Rupees Only"

## APPENDIX B: Quick FAQ for the new AI
- **Q: Where do I put the Delhivery logo?** A: Nowhere except the small
  52×9pt icon beside "Routing Partner: Delhivery" in the Service box.
- **Q: Client GSTIN missing?** A: Generate anyway but warn (Rule G6); state
  detection then falls back to client_state string.
- **Q: Can total ever include product value or COD?** A: NEVER. Total is
  always base freight + GST only.
- **Q: User sends a Delhivery PDF?** A: `pdf_parser.parse_delhivery_pdf()` can
  pre-fill consignee/AWB/pincodes — but client (billed-to) details and base
  charge come from the user, and NOTHING from the PDF's product table is used.

*— End of Master Instruction File —*


### Archival Policy (user instruction, standing)
Every generated invoice PDF is AUTO-MOVED to `<client name>/<YYYY-MM MonthName>/`
(e.g. `Shree Mahadev/2026-09 September/`) via `archive_invoice()`. The HTML copy
is deleted; `generated/` stays empty (counter file only). The archive folder is
git-ignored (private business records). Invoice filenames include the consignee
name: `GST_invoice_<CUSTOMER>_<AWB>.pdf`.
---

## ADDENDUM — v3.1 (supersedes older layout notes above where conflicting)
- Service & Shipment specs row ab **4 columns**: Origin | Destination | Weight |
  **Payment Method (Prepaid/COD)** — sirf method, COD **amount kabhi nahi**.
- Payment method Delhivery PDF / OCR se auto-scan (`doc_extractor`).
- Desktop app: **dashboard UI** (navy sidebar + indigo) — pages: Invoice, Bulk,
  History, Templates, Settings, Backup, Help. Bug fixed: nayi file select par
  fields hamesha fresh data se overwrite.
- **Bulk mode**: multi-page PDF (har page 1 invoice) → editable table
  (Weight/Amount manual) → Generate ALL → sequential numbering + archive.
- `archive_invoice()`: client-name folder HAMESHA banta hai (title-case,
  e.g. "Shree Mahadev"), archive_root base location hai; month subfolder
  `<YYYY-MM MonthName>`; HTML delete, sirf PDF store.


### Invoice Numbering — v3.2 (FINAL, supersedes MSE/<FY>/0001)
New GST-compliant format (max 16 chars, only A-Z 0-9 - /):
`MSE/<yymmdd><HH>-<seq>` e.g. **MSE/26090814-101**
- seq is GLOBAL: starts **101**, NEVER resets or repeats (persisted in
  `generated/gst_invoice_counter.txt` as `seq: N`)
- timestamp = generation time (adds uniqueness)
- seq > 999 → hour segment dropped (`MSE/<yymmdd>-<seq>`) to stay within
  the 16-character GST limit
- Old FY-format counter lines are safely ignored (migration-safe)