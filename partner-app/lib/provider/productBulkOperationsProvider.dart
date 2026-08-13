import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/bulk_upload_instructions_model.dart';
import 'package:project/repositories/productBulkOperationsApi.dart';

enum ProductBulkOperationsState {
  initial,
  loading,
  loaded,
  error,
}

enum ProductSampleFileState {
  initial,
  loading,
  loaded,
  error,
}

enum BulkUploadInstructionsState {
  initial,
  loading,
  loaded,
  error,
}

/// Model for bulk upload error details
class BulkUploadError {
  final int row;
  final String product;
  final String message;

  BulkUploadError({
    required this.row,
    required this.product,
    required this.message,
  });

  factory BulkUploadError.fromJson(Map<String, dynamic> json) {
    return BulkUploadError(
      row: json['row'] ?? 0,
      product: json['product']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }
}

/// Result class for bulk upload operation
class BulkUploadResult {
  final bool success;
  final String message;
  final List<BulkUploadError> errors;

  BulkUploadResult({
    required this.success,
    required this.message,
    this.errors = const [],
  });
}

class ProductBulkOperationsProvider extends ChangeNotifier {
  ProductBulkOperationsState productBulkOperationsState =
      ProductBulkOperationsState.initial;

  ProductSampleFileState productSampleFileState =
      ProductSampleFileState.initial;

  BulkUploadInstructionsState instructionsState =
      BulkUploadInstructionsState.initial;

  String message = '';
  late Uint8List sampleFileData;
  BulkUploadInstructionsData? instructionsData;

  /// Fetch bulk upload instructions from API
  Future<void> fetchBulkUploadInstructions() async {
    instructionsState = BulkUploadInstructionsState.loading;
    notifyListeners();

    try {
      var response = await getBulkUploadInstructionsApi();

      if (response == null) {
        instructionsState = BulkUploadInstructionsState.error;
        notifyListeners();
        return;
      }

      // Parse response
      Map<String, dynamic> responseData;
      if (response is String) {
        responseData = json.decode(response);
      } else if (response is Map) {
        responseData = Map<String, dynamic>.from(response);
      } else {
        instructionsState = BulkUploadInstructionsState.error;
        notifyListeners();
        return;
      }

      final model = BulkUploadInstructionsModel.fromJson(responseData);
      if (model.status == 1 && model.data != null) {
        instructionsData = model.data;
        instructionsState = BulkUploadInstructionsState.loaded;
      } else {
        instructionsState = BulkUploadInstructionsState.error;
      }
      notifyListeners();
    } catch (e) {
      message = e.toString();
      instructionsState = BulkUploadInstructionsState.error;
      notifyListeners();
    }
  }

  /// Download bulk upload template file
  Future<Uint8List?> downloadBulkUploadTemplate({
    required BuildContext context,
  }) async {
    productSampleFileState = ProductSampleFileState.loading;
    notifyListeners();

    try {
      sampleFileData = await productDownloadBulkUploadTemplateApi();

      productSampleFileState = ProductSampleFileState.loaded;
      notifyListeners();

      return sampleFileData;
    } catch (e) {
      message = e.toString();
      productSampleFileState = ProductSampleFileState.error;
      showMessage(
        context,
        message,
        MessageType.warning,
      );
      notifyListeners();
      return null;
    }
  }

  Future<Uint8List?> getProductDownloadExcel({
    required BuildContext context,
    required String from,
  }) async {
    productSampleFileState = ProductSampleFileState.loading;
    notifyListeners();

    try {
      // Use new template API for upload, existing API for update
      if (from == "upload") {
        sampleFileData = await productDownloadBulkUploadTemplateApi();
      } else {
        sampleFileData = await productDownloadProductDataExcelApi(from: from);
      }

      productSampleFileState = ProductSampleFileState.loaded;
      notifyListeners();

      return sampleFileData;
    } catch (e) {
      message = e.toString();
      productSampleFileState = ProductSampleFileState.error;
      showMessage(
        context,
        message,
        MessageType.warning,
      );
      notifyListeners();
      return null;
    }
  }

  Future<BulkUploadResult> productBulkOperation({
    required BuildContext context,
    required String fileParamsFilesPath,
    required bool isUpload,
  }) async {
    try {
      productBulkOperationsState = ProductBulkOperationsState.loading;
      notifyListeners();

      dynamic response = await productBulkOperationApi(
        context: context,
        isUpload: isUpload,
        filesMap: {
          ApiAndParams.file: File(fileParamsFilesPath),
        },
      );

      // Debug print
      print('╔════════════════════════════════════════════════════════════════════');
      print('║ BULK UPLOAD PROVIDER DEBUG');
      print('║ Response: $response');
      print('║ Response Type: ${response.runtimeType}');
      print('╚════════════════════════════════════════════════════════════════════');

      // Handle null response
      if (response == null) {
        productBulkOperationsState = ProductBulkOperationsState.error;
        notifyListeners();
        return BulkUploadResult(
          success: false,
          message: 'No response from server',
        );
      }

      // Parse response - handle both String and Map
      Map<String, dynamic> bulkUploadData;
      if (response is String) {
        bulkUploadData = json.decode(response);
      } else if (response is Map) {
        bulkUploadData = Map<String, dynamic>.from(response);
      } else {
        productBulkOperationsState = ProductBulkOperationsState.error;
        notifyListeners();
        return BulkUploadResult(
          success: false,
          message: 'Invalid response format: ${response.runtimeType}',
        );
      }

      // Check status (1 = success, 0 = error)
      if (bulkUploadData[ApiAndParams.status].toString() == "1") {
        productBulkOperationsState = ProductBulkOperationsState.loaded;
        notifyListeners();
        return BulkUploadResult(
          success: true,
          message: bulkUploadData[ApiAndParams.message]?.toString() ??
              'Upload successful',
        );
      } else {
        // Handle error response with errors array
        productBulkOperationsState = ProductBulkOperationsState.error;

        String errorMessage = bulkUploadData[ApiAndParams.message]?.toString() ??
            'Upload failed';
        List<BulkUploadError> errors = [];

        // Parse errors array if present
        if (bulkUploadData['errors'] != null &&
            bulkUploadData['errors'] is List) {
          errors = (bulkUploadData['errors'] as List)
              .map((e) => BulkUploadError.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }

        notifyListeners();
        return BulkUploadResult(
          success: false,
          message: errorMessage,
          errors: errors,
        );
      }
    } catch (e) {
      message = e.toString();
      productBulkOperationsState = ProductBulkOperationsState.error;
      notifyListeners();
      return BulkUploadResult(
        success: false,
        message: message,
      );
    }
  }
}
