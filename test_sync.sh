#!/bin/bash
# اختبر مزامنة البيانات بين Flutter و Native

echo "=========================================="
echo "🔍 فحص مزامنة البيانات Flutter → Native"
echo "=========================================="
echo ""
echo "الخطوة 1: افتح Logcat في Terminal منفصل:"
echo "  adb logcat | grep -E \"ADD|SYNC|CHANNEL|Received|saved|CACHE|loaded\""
echo ""
echo "الخطوة 2: اضغط Enter لبدء التطبيق..."
read
echo ""
echo "فتح التطبيق..."
cd e:\block_app
flutter run
