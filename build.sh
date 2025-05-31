#!/bin/bash

# حمل Cecil
curl -sSOL https://cecil.app/cecil.phar
chmod +x cecil.phar

# شغّل البناء
php cecil.phar build

# لو الملفات اتبنتت في مجلد غير _site، انقلها (اختياري)
mv output _site || true