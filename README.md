# 📦 WebBox

Ek Progressive Web App (PWA) jo HTML files aur website links ko save, publish aur share karta hai. Har recipient apne mobile number + 4-digit PIN se login karta hai, aur uski entries sirf usi ko dikhti hain.

---

## ✨ Features

### Main App
- HTML files (.html, .htm) import karein
- Website links add karein (auto favicon)
- Emoji ya custom image icons
- Trash with 30-day auto-delete
- Search, rename, delete
- Local JSON backup / restore
- Portable HTML export (poora app + data ek file me)
- Cloud sync (auto + manual backup / restore)
- Publish & Share — public link generate karein

### Public Viewer
- Mobile + 4-digit PIN se Sign Up / Login
- Per-user entries (har user ka data isolated)
- Auto-sync cloud me
- Backup / Restore / Logout menu

### Admin Panel
- Sab published apps ki list
- Har app ke users ki entries dekhna
- Entry JSON browse karna

---

## 🛠️ Setup

### 1. Supabase Project
1. [supabase.com](https://supabase.com) par account banayein
2. Naya project create karein
3. `webbox-schema.sql` ko SQL Editor me paste karke **Run** karein
4. Project URL aur anon key note karein

### 2. Configure `index.html`
`index.html` me ye 2 constants apne Supabase values se replace karein:

```js
const SUPABASE_URL      = 'https://YOUR-PROJECT.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY';
```

### 3. Generate Icons
- `icon-generator.html` browser me kholein
- `icon-192.png` aur `icon-512.png` download karein
- Project root me rakhein

### 4. Deploy
Kisi bhi static host par upload karein:

**Options:** GitHub Pages, Netlify, Vercel, Cloudflare Pages

**HTTPS zaroori hai** — PWA install aur clipboard APIs ke liye.

---

## 📁 File Structure

```
/
├── index.html
├── sw.js
├── manifest.json
├── icon-192.png
├── icon-512.png
├── webbox-schema.sql
├── icon-generator.html
└── README.md
```

---

## 🌐 URL Routes

| URL | Description |
|-----|-------------|
| `/` | Main app |
| `/#/p/{slug}` | Public viewer (mobile + PIN login) |

---

## 🗄️ Database Schema

| Table | Purpose |
|-------|---------|
| `published_apps` | Published HTML apps (slug-based links) |
| `app_users` | End-users (mobile + hashed PIN) |
| `app_entries` | Per-user state for each published app |
| `webbox_sync` | Owner's cloud backup |

### RPC Functions
- `app_signup(p_mobile, p_pin)` — naya user register
- `app_login(p_mobile, p_pin)` — login

PINs `bcrypt` se hashed hote hain (`crypt()` + `gen_salt('bf')`).

---

## 📱 User Flows

### Owner
1. Email + password se sign up / login
2. HTML file add karein
3. Card par ⋮ → **Publish & Share**
4. Link copy karke share karein

### Recipient
1. Share link kholein
2. Mobile number + 4-digit PIN se **Sign Up**
3. App use karein — entries auto cloud pe save hongi
4. Menu se Backup / Restore / Auto-sync toggle / Logout

### Admin
1. Main app me ⋮ Menu → **👑 Admin Panel**
2. Credentials daalein (deployment owner ke paas)
3. Apps list → App select → Users list → Entries view

---

## 🎨 Customization

### Theme colors
`index.html` me `:root` variables:

```css
:root {
  --bg: #080b12;
  --txt: #eef2ff;
  --muted: #8b97b5;
}
```

Primary gradient: `#4f7dff → #7c5cff`

### Admin credentials
Admin ka mobile + PIN SQL me `app_users` table me insert hota hai. Deployment ke waqt SQL me apne values daalein.

---

## 🔐 Security Notes

- PINs bcrypt hashed
- RLS enabled on all tables
- Owner auth Supabase Auth (email/password)
- RPC functions `SECURITY DEFINER`

⚠️ **Production recommendation**: RLS policies abhi `using (true)` hain kyunki client-side app anon key use karta hai. Strict multi-tenant privacy ke liye server-side edge functions ya `auth.uid()` based RLS recommend karte hain.

---

## 🧪 Testing Checklist

- [ ] SQL run ho gaya, tables dikh rahe hain
- [ ] Main app me login ho raha hai
- [ ] HTML file add ho rahi hai
- [ ] Cloud backup / restore kaam kar raha hai
- [ ] Publish karne par link mila
- [ ] Link khulne par mobile + PIN screen aaya
- [ ] Sign Up / Login chal raha hai
- [ ] Entries cloud me save ho rahi hain
- [ ] Alag users alag entries dekh rahe hain
- [ ] Admin Panel se entries dikh rahi hain

---

## 🐛 Troubleshooting

**"Supabase load nahi hua"**
- Internet check karein
- CDN block ho sakta hai — `supabase-js` self-host karein

**"Service Worker registered nahi hua"**
- HTTPS zaroori (localhost bhi chalega)
- `sw.js` root folder me hona chahiye

**Public link kaam nahi kar raha**
- Static host par `index.html` serve ho raha ho
- `#/p/{slug}` hash-based routing hai

**Icons nahi dikh rahe**
- File names exact: `icon-192.png`, `icon-512.png`
- Same folder me rakhein

---

## 📜 License

MIT — free to use, modify, and distribute.

---

## 🙏 Credits

- Backend: [Supabase](https://supabase.com)
- Framework: Vanilla JS (no build step)
- Icons: Emoji + built-in generator