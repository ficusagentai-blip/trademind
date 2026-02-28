# 🐺 TradeMind — Wolf Discipline System

> **Indian Traders साठी बनवलेला AI-powered Trading Journal**  
> Track trades · Master psychology · Evolve from Cub to Legendary Wolf

![Version](https://img.shields.io/badge/version-1.0-green) ![License](https://img.shields.io/badge/license-MIT-blue) ![Made for](https://img.shields.io/badge/Made%20for-Indian%20Traders%20🇮🇳-orange)

---

## 📋 Table of Contents

- [About](#about)
- [Features](#features)
- [Wolf Evolution System](#wolf-evolution-system)
- [Tech Stack](#tech-stack)
- [File Structure](#file-structure)
- [Setup Guide](#setup-guide)
- [Supabase Setup](#supabase-setup)
- [Razorpay Setup](#razorpay-setup)
- [Admin Panel](#admin-panel)
- [Deployment](#deployment)
- [Pricing](#pricing)
- [FAQ](#faq)

---

## 🎯 About

TradeMind एक full-stack web application आहे जो Indian traders ला त्यांच्या trades track करायला, trading psychology समजायला, आणि discipline build करायला मदत करतो.

**Key Differentiator:** Wolf Evolution System — तुमचा discipline score तुमची wolf rank ठरवतो. जितकं consistent trading, तितकं higher rank.

---

## ✨ Features

| Feature | Description |
|---|---|
| 📊 **Smart Trade Logger** | 11-point execution checklist + psychology sliders. Mandatory fields ensure data quality. |
| 🤖 **AI Performance Report** | Claude AI तुमच्या patterns आणि psychological weaknesses analyze करतो. Hinglish मध्ये personalised action plan. |
| 🐺 **Wolf Evolution System** | 70% Execution + 30% Focus = Discipline Score. 4 stages: Cub → Wolf → Alpha → Legendary. |
| 📈 **Advanced Analytics** | Equity curve, P&L heatmap, setup performance, emotion vs P&L, discipline trends. |
| 📓 **Trading Journal** | Daily journal with mood tracking. Emotions link to outcomes. |
| 📌 **Rule Manager** | Personal trading rules create करा. Violations track करा. Discipline build करा. |
| 🔐 **Admin Panel** | Full user management, subscription approvals, revenue tracking. |

---

## 🐺 Wolf Evolution System

Discipline score दोन pillars वर calculate होतो:

```
Discipline Score = (Execution × 70%) + (Focus × 30%)

Execution = (Checklist items completed / 11) × 100
Focus     = (Confidence + Focus + Patience + Calm) / 40 × 100
```

### Stages

| Stage | Range | Emoji | Description |
|---|---|---|---|
| Cub | 0 – 40% | 🐾 | Every legend starts here |
| Wolf | 40 – 65% | 🐺 | You've found your path |
| Alpha | 65 – 85% | ⚡ | Leading the pack |
| Legendary | 85 – 100% | 🏆 | Apex trader. Elite only. |

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Pure HTML, CSS, Vanilla JavaScript |
| **Database** | Supabase (PostgreSQL) |
| **Auth** | Supabase Auth |
| **Payments** | Razorpay + Manual UPI/WhatsApp |
| **AI** | Anthropic Claude API (claude-sonnet-4-20250514) |
| **Hosting** | GitHub Pages |
| **CI/CD** | GitHub Actions |

---

## 📁 File Structure

```
trademind/
│
├── index.html              # Main app (landing + auth + dashboard)
├── admin.html              # Admin control panel
├── config.js               # Config (Supabase URL, anon key, Razorpay key)
├── README.md               # हे file
│
├── .gitignore              # Git ignore rules
│
└── .github/
    └── workflows/
        └── deploy-pages.yml   # GitHub Pages auto-deploy
```

> **Note:** `schema.sql` हे Supabase SQL Editor मध्ये एकदाच run करायचं असतं. Repo मध्ये ठेवणं optional आहे.

---

## 🚀 Setup Guide

### Step 1 — Supabase Project बनवा

1. [supabase.com](https://supabase.com) → New Project
2. Project name: `trademind`
3. Database password: strong password ठेवा (save करा!)
4. Region: **Mumbai (ap-south-1)** — fastest for India

### Step 2 — Database Schema Run करा

1. Supabase Dashboard → **SQL Editor**
2. `schema.sql` चा content paste करा
3. **Run** click करा
4. ✅ Tables created: `profiles`, `trades`, `journals`, `rules`, `admin_settings`

### Step 3 — Config Update करा

`config.js` उघडा:

```javascript
const TF_CONFIG = {
  SUPABASE_URL:  'https://YOUR-PROJECT.supabase.co',  // ← आपला URL
  SUPABASE_ANON: 'YOUR_ANON_KEY',                      // ← आपला anon key
  RAZORPAY_KEY:  'rzp_test_YOUR_KEY',                  // ← Razorpay key (optional)
};
```

**Supabase URL आणि Key कुठे मिळेल?**  
Supabase Dashboard → Settings → API → Project URL + anon/public key

### Step 4 — Admin User बनवा

1. Supabase Dashboard → **Authentication** → Users → **Add User**
2. Admin email आणि password टाका
3. User created झाल्यावर **SQL Editor** मध्ये run करा:

```sql
UPDATE public.profiles
SET role = 'admin'
WHERE email = 'your-admin@email.com';
```

### Step 5 — GitHub वर Deploy करा

```bash
git init
git add .
git commit -m "🐺 TradeMind launch"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/trademind.git
git push -u origin main
```

GitHub → Settings → Pages → Source: **GitHub Actions** → Save

**Done!** काही minutes मध्ये `https://YOUR_USERNAME.github.io/trademind/` live होईल.

---

## 🗄 Supabase Setup

### RLS (Row Level Security)

Schema मध्ये automatically सेट होतं. पण verify करा:

- Supabase → Table Editor → प्रत्येक table वर 🔒 icon असावं
- `admin_settings` → RLS enabled असावं (Lint warnings fix)

### Email Confirmation (Optional)

By default Supabase email confirmation पाठवतो. Development साठी:

Supabase → Authentication → Providers → Email → **Confirm email: OFF**

Production साठी ON ठेवा आणि email template customize करा.

---

## 💳 Razorpay Setup

1. [dashboard.razorpay.com](https://dashboard.razorpay.com) → Sign Up
2. Test Mode मध्ये: Settings → API Keys → Generate Test Key
3. `config.js` मध्ये `RAZORPAY_KEY` update करा
4. Live करायला: KYC complete करा → Live key use करा

> **Note:** Razorpay नसेल तरी UPI + WhatsApp payment options काम करतात.

### UPI Payment Flow

1. User → Payment screen → UPI select → `9987961609@paytm` वर ₹99 pay करतो
2. "I've Paid" button click करतो → Status `pending` होतो
3. Admin Panel → Subscriptions → Pending → ✅ Approve

---

## 🔧 Admin Panel

`admin.html` वर जा (same URL + `/admin.html`)

### Features

- **Overview** — Total users, MRR, ARR, platform stats
- **Users** — सर्व users पाहा, search करा, pro grant/revoke करा
- **Subscriptions** — Pending approvals, active subscribers
- **All Trades** — Platform-wide trade data
- **Wolf Rankings** — Leaderboard, stage distribution
- **Revenue** — MRR, ARR, conversion rates
- **Settings** — Password change, export data

### First Login

Admin email आणि Supabase password वापरा (Step 4 मध्ये बनवलेला user).

---

## 🌐 Deployment

### GitHub Pages (Recommended — Free)

`.github/workflows/deploy-pages.yml` आधीच configured आहे. `main` branch वर push केल्यावर automatically deploy होतं.

### Custom Domain (Optional)

1. GitHub → Settings → Pages → Custom domain टाका
2. Domain DNS मध्ये CNAME record add करा:
   ```
   CNAME → YOUR_USERNAME.github.io
   ```

---

## 💰 Pricing

| Plan | Amount | Features |
|---|---|---|
| **First Month** | ₹99 | सर्व features included — 67% OFF |
| **Monthly** | ₹299/month | Full access, cancel anytime |
| **Free** | ₹0 | Account create, no app access |

### Payment Methods Supported

- 💬 WhatsApp Pay (Business: +91 9987961609)
- 📱 UPI — Paytm / GPay / PhonePe / BHIM
- 💳 Debit/Credit Card (Razorpay)

---

## ❓ FAQ

**Q: config.js GitHub वर safe आहे का?**  
A: हो. `SUPABASE_ANON` हा publishable key आहे — public करणं safe आहे. Supabase RLS (Row Level Security) database protect करतो.

**Q: Supabase free plan enough आहे का?**  
A: होय! Free plan: 500MB database, 2GB bandwidth, 50,000 monthly active users. सुरुवातीला more than enough.

**Q: AI Reports काम करत नाहीत?**  
A: `generateAIReport()` Anthropic API directly call करतो. Browser CORS restrictions मुळे कदाचित work न होऊ शकतं. Production साठी Supabase Edge Function वापरणं recommend केलं जातं.

**Q: Admin password कसं reset करायचं?**  
A: Supabase → Authentication → Users → Admin user → Reset password.

**Q: Mobile वर काम करतं का?**  
A: Desktop optimized आहे. Mobile layout basic काम करतं. Full mobile support future version मध्ये येईल.

---

## 🔒 Security Notes

- `config.js` मध्ये फक्त **publishable/anon** keys ठेवा
- Secret keys कधीच frontend code मध्ये टाकू नका
- Supabase RLS सर्व tables वर enabled आहे
- Admin panel Supabase Auth + role check वापरतो

---

## 📞 Support

- 💬 WhatsApp: +91 9987961609
- 📧 Email: support@trademind.in

---

## 📄 License

MIT License · © 2026 TradeMind · Made with ❤️ for Indian Traders 🇮🇳

---

> *"Every legendary wolf was once a cub who refused to give up."* 🐺
