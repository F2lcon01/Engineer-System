# دليل التثبيت السريع

## الفكرة

ضع مجلد النظام مرة واحدة على سطح المكتب، ثم ثبّته في أي مشروع بأمر واحد.

---

## الإعداد لمرة واحدة

```powershell
# 1. انسخ مجلد النظام لسطح المكتب
# اجعل المسار: C:\Users\<اسمك>\Desktop\Engineer System
#
# هيكل المجلد:
# Engineer System/
# ├── CLAUDE.md
# ├── .claude/
# │   ├── agents/
# │   ├── commands/
# │   ├── hooks/
# │   └── settings.json
# ├── memory/
# │   └── PROJECT_MAP.md
# └── installer/
#     ├── Install-EngineerSystem.ps1
#     ├── install.sh
#     └── INSTALL-PROMPT.md
```

---

## الاستخدام

### الطريقة 1: PowerShell (Windows — موصى به)

```powershell
# انتقل لمشروعك
cd C:\projects\my-project

# شغّل المثبّت
& "$env:USERPROFILE\Desktop\Engineer System\installer\Install-EngineerSystem.ps1"
```

**اختصار أفضل — أضفه لـ PowerShell profile:**

```powershell
# افتح profile
notepad $PROFILE

# أضف هذا السطر
function install-eng {
    & "$env:USERPROFILE\Desktop\Engineer System\installer\Install-EngineerSystem.ps1" @args
}

# احفظ ثم أعد فتح PowerShell
# الآن استخدمه في أي مشروع:
cd C:\projects\polar-os
install-eng
```

### الطريقة 2: Bash (Linux/macOS/WSL)

```bash
# انتقل لمشروعك
cd ~/projects/my-project

# شغّل المثبّت
bash ~/Desktop/Engineer\ System/installer/install.sh

# اختصار — أضفه لـ ~/.bashrc أو ~/.zshrc
alias install-eng='bash ~/Desktop/Engineer\ System/installer/install.sh'
```

### الطريقة 3: Claude نفسه (بدون terminal)

افتح Claude Code في أي مشروع واكتب:

```
ثبّت Engineer System من ~/Desktop/Engineer System في هذا المشروع.
احفظ بياناتي الموجودة. اعرض الخطة قبل التنفيذ.
```

Claude سيقرأ الملفات، يفحص الـ conflicts، ويثبّت بذكاء.

---

## الأوضاع المتاحة

### Install (افتراضي) — تثبيت جديد

```powershell
install-eng
```

يفشل إذا النظام مثبّت سابقاً (حماية من الكتابة فوق التخصيصات).

### Upgrade — ترقية مع الحفاظ على البيانات

```powershell
install-eng -Mode Upgrade
```

يحدّث agents/commands/hooks، **يحمي** CLAUDE.md و PROJECT_MAP.md الموجودين.

### DryRun — معاينة بدون تنفيذ

```powershell
install-eng -Mode DryRun
```

يعرض ما سيحدث بدون كتابة أي ملف. مفيد للفحص قبل التنفيذ.

### Force — استبدال كامل (خطر)

```powershell
install-eng -Force
```

يكتب فوق كل شيء. **يفقد التخصيصات والبيانات.** استخدمه فقط إذا تعرف ماذا تفعل.

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
# ✓ Hooks مُفعّلة
# ✓ .gitignore محدّث
# اكتمل التثبيت بنجاح
```

### بعد شهر: ترقية النظام

```powershell
# عدّلت staff-engineer.md في النسخة الأصلية
# تريد توزيع التحديث على كل مشاريعك

cd C:\projects\polar-os
install-eng -Mode Upgrade
# CLAUDE.md (محتوي تخصيصاتك): محمي
# PROJECT_MAP.md (محتوي 30 جلسة): محمي
# agents/staff-engineer.md: مُحدّث

cd C:\projects\everything-claude-code
install-eng -Mode Upgrade
# نفس الشيء

cd C:\projects\new-tool
install-eng -Mode Upgrade
# نفس الشيء
```

ثلاث مشاريع، ثلاث ثوانٍ.

---

## استكشاف الأخطاء

### "مجلد المصدر غير موجود"

تأكد من المسار:
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

### Hooks لا تعمل على Windows

PowerShell ينفذ chmod عبر WSL/Git Bash. تأكد من تثبيت أحدهما، أو شغّل يدوياً في WSL:
```bash
cd /mnt/c/projects/my-project
chmod +x .claude/hooks/*.sh
```

### "Claude Code CLI غير مثبّت"

```bash
npm install -g @anthropic-ai/claude-code
```

---

## ملاحظات

- النظام **لا يحذف** ملفات المشروع — يضيف فقط ملفاته الخاصة
- في Upgrade: CLAUDE.md و PROJECT_MAP.md المحتويين بياناتك محميان دائماً
- DryRun هو صديقك — استخدمه قبل أي عملية مشكوك فيها
- النظام آمن للـ git — يضيف للـ .gitignore تلقائياً
