# Aturan R8/ProGuard tambahan untuk build rilis.
#
# Aturan untuk Flutter dan plugin-nya sudah disertakan otomatis. Tambahkan aturan
# `-keep` di sini hanya bila build rilis crash atau R8 melaporkan
# "Missing class ..." untuk pustaka yang memakai refleksi.

# google_mlkit_text_recognition (fitur pindai struk OVO): AAR ML Kit biasanya
# sudah membawa aturan consumer-nya sendiri, tapi ini jaga-jaga karena belum
# diuji langsung pada build rilis di perangkat.
-keep class com.google.mlkit.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
-dontwarn com.google.mlkit.**
