import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class TFLiteModelManager {
  static const String _modelsBaseUrl = 'https://storage.googleapis.com/mediapipe-models';

  /// Available pre-trained models for offline use
  static const Map<String, ModelInfo> availableModels = {
    'bert_qa': ModelInfo(
      name: 'BERT Question Answering',
      fileName: 'bert_qa_model.tflite',
      vocabFileName: 'bert_vocab.txt',
      size: '25 MB',
      description: 'Question answering model based on BERT',
      downloadUrl: 'https://tfhub.dev/tensorflow/lite-model/mobilebert/1/default/1?lite-format=tflite',
    ),
    'universal_sentence_encoder': ModelInfo(
      name: 'Universal Sentence Encoder',
      fileName: 'use_model.tflite',
      vocabFileName: 'use_vocab.txt',
      size: '15 MB',
      description: 'Text embeddings for semantic similarity',
      downloadUrl: 'https://tfhub.dev/google/lite-model/universal-sentence-encoder-qa-ondevice/1?lite-format=tflite',
    ),
    'text_classifier': ModelInfo(
      name: 'Text Classification',
      fileName: 'text_classifier.tflite',
      vocabFileName: 'classifier_vocab.txt',
      size: '12 MB',
      description: 'Text classification and sentiment analysis',
      downloadUrl: 'https://storage.googleapis.com/download.tensorflow.org/models/tflite/text_classification/text_classification_v2.tflite',
    ),
  };

  /// Download and install a TensorFlow Lite model
  static Future<bool> downloadModel(String modelKey, {Function(double)? onProgress}) async {
    try {
      final modelInfo = availableModels[modelKey];
      if (modelInfo == null) {
        print('❌ Model not found: $modelKey');
        return false;
      }

      final directory = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${directory.path}/models');
      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }

      final dio = Dio();
      final modelPath = '${modelsDir.path}/${modelInfo.fileName}';

      print('📥 Downloading ${modelInfo.name}...');

      await dio.download(
        modelInfo.downloadUrl,
        modelPath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            final progress = received / total;
            onProgress(progress);
            print('📊 Progress: ${(progress * 100).toStringAsFixed(1)}%');
          }
        },
      );

      // Copy to assets folder for app access
      await _copyToAssets(modelPath, modelInfo.fileName);

      print('✅ Model downloaded successfully: ${modelInfo.name}');
      return true;

    } catch (e) {
      print('❌ Error downloading model: $e');
      return false;
    }
  }

  /// Copy downloaded model to assets folder
  static Future<void> _copyToAssets(String sourcePath, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final assetsDir = Directory('${directory.path}/assets/models');
      if (!await assetsDir.exists()) {
        await assetsDir.create(recursive: true);
      }

      final sourceFile = File(sourcePath);
      final targetPath = '${assetsDir.path}/$fileName';
      await sourceFile.copy(targetPath);

      print('📁 Model copied to assets: $fileName');
    } catch (e) {
      print('⚠️ Error copying to assets: $e');
    }
  }

  /// Check if a model is already downloaded
  static Future<bool> isModelDownloaded(String modelKey) async {
    try {
      final modelInfo = availableModels[modelKey];
      if (modelInfo == null) return false;

      final directory = await getApplicationDocumentsDirectory();
      final modelPath = '${directory.path}/assets/models/${modelInfo.fileName}';
      return await File(modelPath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Get list of downloaded models
  static Future<List<String>> getDownloadedModels() async {
    final downloaded = <String>[];

    for (final modelKey in availableModels.keys) {
      if (await isModelDownloaded(modelKey)) {
        downloaded.add(modelKey);
      }
    }

    return downloaded;
  }

  /// Delete a downloaded model
  static Future<bool> deleteModel(String modelKey) async {
    try {
      final modelInfo = availableModels[modelKey];
      if (modelInfo == null) return false;

      final directory = await getApplicationDocumentsDirectory();
      final modelPath = '${directory.path}/assets/models/${modelInfo.fileName}';
      final modelFile = File(modelPath);

      if (await modelFile.exists()) {
        await modelFile.delete();
        print('🗑️ Model deleted: ${modelInfo.name}');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Error deleting model: $e');
      return false;
    }
  }

  /// Create sample vocabulary file for testing
  static Future<void> createSampleVocab() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final assetsDir = Directory('${directory.path}/assets/models');
      if (!await assetsDir.exists()) {
        await assetsDir.create(recursive: true);
      }

      const sampleVocab = '''[PAD]
[UNK]
[CLS]
[SEP]
the
be
to
of
and
a
in
that
have
i
it
for
not
on
with
he
as
you
do
at
this
but
his
by
from
they
we
say
her
she
or
an
will
my
one
all
would
there
their
what
so
up
out
if
about
who
get
which
go
me
when
make
can
like
time
no
just
him
know
take
people
into
year
your
good
some
could
them
see
other
than
then
now
look
only
come
its
over
think
also
back
after
use
two
how
our
work
first
well
way
even
new
want
because
any
these
give
day
most
us''';

      final vocabFile = File('${assetsDir.path}/vocab.txt');
      await vocabFile.writeAsString(sampleVocab);

      print('📝 Sample vocabulary created');
    } catch (e) {
      print('❌ Error creating vocabulary: $e');
    }
  }
}

/// Model information class
class ModelInfo {
  final String name;
  final String fileName;
  final String vocabFileName;
  final String size;
  final String description;
  final String downloadUrl;

  const ModelInfo({
    required this.name,
    required this.fileName,
    required this.vocabFileName,
    required this.size,
    required this.description,
    required this.downloadUrl,
  });
}
