import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/providers/llm/local/local_models.dart';

void main() {
  test('registry exposes at least the default model', () {
    expect(localModels.any((m) => m.id == kDefaultLocalModelId), isTrue);
  });

  test('localModelById returns the model or null', () {
    expect(localModelById(kDefaultLocalModelId)?.id, kDefaultLocalModelId);
    expect(localModelById('nope'), isNull);
  });

  test('resolveState reports downloaded when file present and full size', () {
    final m = localModelById(kDefaultLocalModelId)!;
    final s = resolveState(m, exists: true, sizeOnDisk: m.sizeBytes);
    expect(s, LocalModelState.downloaded);
  });

  test('resolveState reports notDownloaded when file absent', () {
    final m = localModelById(kDefaultLocalModelId)!;
    expect(resolveState(m, exists: false, sizeOnDisk: 0),
        LocalModelState.notDownloaded);
  });

  test('resolveState reports partial when file smaller than expected', () {
    final m = localModelById(kDefaultLocalModelId)!;
    expect(resolveState(m, exists: true, sizeOnDisk: m.sizeBytes - 1),
        LocalModelState.partial);
  });
}
