# Phase 4 — Admin panel / ops checklist

These are the home-screen issues that live in **catalogue data and assets**, not
in the app code. Nothing here can be fixed in the Flutter repo without
hardcoding a correction for one specific record, which hides the problem the
next time it recurs.

Every item below was observed on the live app (Zenfoo customer, home + Categories
tab) during the Phase 1–3 design pass.

---

## 0. Fix first — these are not cosmetic

**a. Test/junk stores are live on the Super mart tab, and their storefront
images are developer screenshots — one of which exposes personal data.**

The "Nearby Super Markets" list currently shows stores named `viiiii`, `Store`,
`Ggg`, and `Stote`, each carrying a 4.4–4.9 star rating. Their storefront
images are not photographs of shops. They are screen captures, including:

- **An internal wallet/transactions admin dashboard showing a real person's
  full name and email address, plus transaction amounts and balances.** This is
  personal data rendered to every customer who opens the Super mart tab. Treat
  as a privacy incident, not a content bug: unpublish the store or clear the
  image immediately, then work out how it got uploaded.
- A screenshot of an OTP entry screen
- A screenshot of a LinkedIn marketing post
- A Play Store "early access / What's new" screenshot
- One store with a blank grey image

*(The affected name and email are deliberately not reproduced in this file. They
are visible in the app on the Super mart tab.)*

Actions: unpublish the test stores, purge the screenshot images, and check
whether the seeded 4.4–4.9 ratings on them are fabricated — fake ratings on
live storefronts carry their own exposure.

**b. Unlicensed stock photo in the live catalogue.**
The `Dairy, Bread & Eggs` category image is a **Shutterstock watermarked
comp** — the watermark bar is visible in the app. This is a licensing exposure,
not a design nit. Replace with a licensed or own-shot image.

**c. A product priced at ₹0 with an Add button.**
Product `Oil Bottle` shows `₹0`, `QTY: -`, and an active **ADD** button. A
customer can put it in a basket. Its image is also a **Toor Dal packet**, not an
oil bottle. Either fix the price/variant/image or unpublish it.

**d. Wrong product image.**
`Fortune Sunflower Oil` uses a **photograph of a floor / ground**. Visible in the
home screen's Buy it again rail.

---

## 1. Copy fixes — category and product names

Exact current string → exact corrected string. Edit in the admin panel's
category / category-group / product records.

| Current | Should be | Where seen |
|---|---|---|
| `Oils,Ghee & Massala` | `Oils, Ghee & Masala` | Home → Shop by Category; Categories tab |
| `Groceries  & Kitchen` | `Groceries & Kitchen` | Categories tab heading (double space) |
| `Customer favouite products` | `Customer Favourite Products` | Home section heading — **misspelling** |
| `Cadburry 5 Star ...` | `Cadbury 5 Star ...` | Product — **misspelling** (the neighbouring `Cadbury Dairy Milk` is spelled correctly) |
| `Beauty & Personal care` | `Beauty & Personal Care` | Categories rail |
| `Bottles & cups` | `Bottles & Cups` | Home → Shop by Category |
| `Sabarmati-Atta` | `Sabarmati Atta` | Product — hyphen for space |
| `prawns` | `Prawns` | Home → Special Items |
| `biryani` | `Biryani` | Product, appears in Buy it again |
| `Products` | *(rename or remove)* | Home section heading — says nothing |
| `Atta rice & Dal` | `Atta, Rice & Dal` | Home → Shop by Category |

**Rule going forward:** Title Case for every customer-facing category, section
and product name; a space after every comma; no double spaces. Worth adding as
validation on the admin form so it can't regress.

---

## 2. Taxonomy — duplicate and overlapping categories

These need a decision before any edit, because they change what customers can
find. **Four category names currently appear twice on the same home screen**,
under different parent groups, with different images:

| Name | Appears under | Note |
|---|---|---|
| `Instant Food` | Groceries & Kitchen **and** Snacks & Drinks | Different images (noodles vs a fried snack) |
| `Tea, Coffee & Milk Drinks` | Groceries & Kitchen **and** Snacks & Drinks | Different images |
| `Atta rice & Dal` / `Atta, Rice` | Groceries & Kitchen / Snacks & Drinks | Same chakki-atta packshot on both |
| `Bakery & Biscuits` / `Chocolates & Biscuits` | Groceries & Kitchen / Snacks & Drinks | Biscuits sit in both |

A customer scrolling one screen sees the same category twice and cannot tell
which to tap. For each: decide the single owner, then remove or re-point the
duplicate.

Also:

- **`Mutton`** vs **`Raw Mutton`** in Special Items — near-identical photos, no
  visible difference to a customer. Merge, or rename so the distinction is
  obvious (e.g. `Mutton — Curry Cut` vs `Mutton — Whole`).
- **Single-item sections.** `Products` and `Customer favouite products` each
  render one product, leaving most of the row empty. Either populate them or
  hide sections below a minimum item count.

---

## 3. "Special Items" needs a definition

Right now Special Items contains `Chicken & Eggs`, `Fish & Seafood`, `Mutton`,
`Prawns`, `Raw Mutton`, `Camel Meat` — which is the same ground the **Chicken &
Meat** store tab already covers. A customer sees the same products presented
twice with no explanation of the difference.

Decide what the section is for — seasonal? discounted? high-margin? new
arrivals? — then rename the section to say so, and curate the contents to
match. If the answer is "it's just meat", the section should be removed and the
tab left to do the job.

---

## 4. Image art direction

The catalogue currently mixes at least four photographic styles inside a single
grid:

- Plated/styled food (Fish & Seafood, Prawns)
- Raw product on white (Raw Mutton)
- Live animal (Camel Meat — a photo of a camel, not of meat)
- Retail packshot (Dry Fruits & Cereals, Chocos)
- **Watermarked stock comp**: `Dairy, Bread & Eggs` — see section 0a
- **Wrong image entirely**: `Fortune Sunflower Oil` (a floor), `Oil Bottle`
  (a toor dal packet) — see section 0b/0c

**Standard to adopt for every catalogue image:**

1. 1:1 square (the admin cropper already enforces this — keep it)
2. Product centred, filling ~80% of the frame
3. Plain white or single-tone background, consistent across a section
4. One style per section — either all styled/plated or all packshot, not mixed
5. No live animals for meat categories

Re-shooting or re-cropping is an ops task; the app renders whatever is uploaded.

---

## 5. Deferred by request

- **Banner safe zones** — the hero art crops awkwardly at some screen sizes
  (subject cut at the ankles on the original screenshots).
- **Peach banner background vs the green brand** — the peach block is ~40% of
  the first screen in a colour used nowhere else.

Both were explicitly left for a later background change.

---

## What was fixed in the app instead (Phases 1–3)

For reference, so this list isn't confused with the code work already done:
grid dead space, duplicate tile captions, heading typography and alignment,
section spacing scale, the pinned ETA + address strip, the full-screen reload
loader, section skeletons and error states, the "Back to top" label, the search
placeholder cursor, plus the new Buy it again rail and rewards progress strip.
