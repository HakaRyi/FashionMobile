class AIAnalysisResult {
  final String processedUrl;
  final Map<String, List<LabelConfidence>> data;

  AIAnalysisResult({required this.processedUrl, required this.data});

  factory AIAnalysisResult.fromJson(Map<String, dynamic> json) {
    Map<String, List<LabelConfidence>> mappedData = {};
    json['data'].forEach((key, value) {
      mappedData[key] = (value as List)
          .map((item) => LabelConfidence.fromJson(item))
          .toList();
    });
    return AIAnalysisResult(
      processedUrl: json['processed_url'],
      data: mappedData,
    );
  }
}

class LabelConfidence {
  final String label;
  final double confidence;
  LabelConfidence({required this.label, required this.confidence});

  factory LabelConfidence.fromJson(Map<String, dynamic> json) {
    return LabelConfidence(
      label: json['label'],
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}