# MediaPipe's Android framework references optional proto classes that are not
# packaged by flutter_gemma 0.12.6. R8 only needs to ignore these unresolved
# profiler/template references during release shrinking.
-dontwarn com.google.mediapipe.proto.CalculatorProfileProto$CalculatorProfile
-dontwarn com.google.mediapipe.proto.GraphTemplateProto$CalculatorGraphTemplate
