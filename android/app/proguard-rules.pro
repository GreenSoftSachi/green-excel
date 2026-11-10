# Flutter Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Printing & PDF Packages
-keep class net.legaion.printing.** { *; }
-dontwarn net.legaion.printing.**
-dontwarn com.itextpdf.**
