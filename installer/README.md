# دليل التثبيت السريع (Windows + Claude Code for VS Code)

## الفكرة

ضع مجلد النظام مرة واحدة على سطح المكتب، ثم ثبّته في أي مشروع بأمر PowerShell واحد. النظام يعمل تلقائياً داخل **Claude Code for VS Code** (الـ extension يقرأ نفس `.claude/settings.json`).

---

## الإعداد لمرة واحدة

```powershell
# 1. ضع مجلد النظام في:
#    C:\Users\<اسمك>\Desktop\Engineer System
#
# هيكل المجلد:
# Engineer System\
# ├── CLAUDE.md
# ├── .claude\
# │   ├── agents\          (7 ملفات .md)
# │   ├── commands\        (3 ملفات .md)
# │   ├── hooks\           (4 ملفات .mjs — Node)
# │   ├── skills\          (2 ملفات .md)
# │   └── settings.json
# ├── memory\
# │   └── PROJECT_MAP.md
# └── installer\
#     ├── Install-EngineerSystem.ps1
#     └── INSTALL-PROMPT.md
```

### المتطلبات

- **Windows 10/11**
- **PowerShell 5.1+** (موجود افتراضياً)
- **Node.js 18+** — إلزامي للـ hooks (`node --version` للفحص)
- **Claude Code for VS Code** extension

---

## الاستخدام

### الطريقة 1: PowerShell (موصى بها)

```powershell
# انتقل لمشروعك
cd C:\projects\my-project

# شغّل المثبّت مباشرة
& "$env:USERPROFILE\Desktop\Engineer System\installer\Install-EngineerSystem.ps1"
```

**اختصار `install-eng` — أضفه لـ PowerShell profile مرة واحدة:**

```powershell
# 1. افتح الـ profile
notepad $PROFILE

# 2. ألصق هذا السطر:
function install-eng {
    & "$env:USERPROFILE\Desktop\Engineer System\installer\Install-EngineerSystem.ps1" @args
}

# 3. احفظ، ثم أعد تحميل:
. $PROFILE

# 4. الآن من أي مشروع:
cd C:\projects\polar-os
install-eng
```

### الطريقة 2: Claude نفسه (من داخل VS Code، بدون terminal)

افتح VS Code → فعّل Claude Code → اكتب:

```
ثبّت Engineer System من ~/Desktop/Engineer System في هذا المشروع.
احفظ بياناتي الموجودة. اعرض الخطة قبل التنفيذ.
```

Claude يقرأ، يفحص الـ conflicts، ينسخ، ويُخصِّص.

---

## الأوضاع المتاحة

| الوضع | الأمر | الغرض |
|-------|------|-------|
| **Install** | `install-eng` | تثبيت جديد (يفشل لو موجود) |
| **Upgrade** | `install-eng -Mode Upgrade` | يحدّث agents/hooks، يحمي CLAUDE.md و PROJECT_MAP |
| **DryRun** | `install-eng -Mode DryRun` | معاينة بدون كتابة |
| **Force** | `install-eng -Force` | استبدال كامل (خطر — يفقد التخصيصات) |

---

## مثال سيناريو كامل

### اليوم الأول: مشروع جديد

```powershell
mkdir C:\projects\new-tool
cd C:\projects\new-tool
git init
install-eng

# الناتج:
# ✓ ملفات جديدة: 14
# ✓ كل الـ hooks (.mjs) موجودة — لا تحتاج chmod (Node executor)
# ✓ .gitignore محدّث
# ✓ اكتمل التثبيت بنجاح
```

### بعد شهر: ترقية النظام لعدة مشاريع

```powershell
# عدّلت staff-engineer.md في النسخة الأصلية
# تريد توزيع التحديث على كل مشاريعك

cd C:\projects\polar-os
install-eng -Mode Upgrade
# CLAUDE.md (محتوي تخصيصاتك): محمي
# PROJECT_MAP.md (محتوي 30 جلسة): محمي
# agents\staff-engineer.md: مُحدّث

cd C:\projects\everything-claude-code
install-eng -Mode Upgrade

cd C:\projects\new-tool
install-eng -Mode Upgrade
```

ثلاث مشاريع، ثلاث ثوانٍ.

---

## استكشاف الأخطاء

### "مجلد المصدر غير موجود"

```powershell
# المسار الافتراضي:
"$env:USERPROFILE\Desktop\Engineer System"

# إذا حفظته في مكان آخر:
install-eng -SourcePath "D:\Tools\Engineer System"
```

### "النظام مثبّت سابقاً"

استخدم Upgrade بدل Install:

```powershell
install-eng -Mode Upgrade
```

### Hooks لا تعمل

```powershell
# تحقق من Node:
node --version
# يجب أن يكون v18+

# لو ناقص: ثبّت من https://nodejs.org/ (LTS)
```

### "Claude Code CLI غير مثبّت"

```powershell
npm install -g @anthropic-ai/claude-code
```

### اختبار الـ hooks بعد التثبيت

```powershell
# لو مجلد المصدر يحوي smoke test:
node "$env:USERPROFILE\Desktop\Engineer System\.claude\hooks\__smoke-test.mjs"
# المتوقع: 10 passed, 0 failed
```

---

## ملاحظات

- النظام **لا يحذف** ملفات المشروع — يضيف فقط ملفاته الخاصة
- في Upgrade: `CLAUDE.md` و `PROJECT_MAP.md` المحتويين بياناتك **محميان دائماً**
- `DryRun` هو صديقك — استخدمه قبل أي عملية مشكوك فيها
- النظام آمن للـ git — يضيف للـ `.gitignore` تلقائياً
- الـ hooks مكتوبة بـ Node.js (لا bash، لا WSL، لا chmod)
