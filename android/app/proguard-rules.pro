# Keep TensorFlow Lite classes, including GPU delegates
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Keep tflite_flutter native bindings
-keep class com.google.flatbuffers.** { *; }
-dontwarn com.google.flatbuffers.**

# Keep JNI bindings
-keepclassmembers class * {
    native <methods>;
}

# Prevent removal of classes used via reflection (just in case)
-keepclassmembers class * {
    public *;
}
