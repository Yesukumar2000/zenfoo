import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';

Future productBulkOperationApi({
  required Map<String, File> filesMap,
  required BuildContext context,
  required bool isUpload,
}) async {
  try {
    var response = await sendApiMultiPartRequest(
        apiName: isUpload == true
            ? ApiAndParams.apiProductBulkUpload
            : ApiAndParams.apiProductBulkUpdate,
        params: {},
        filesMap: filesMap);

    return response;
  } catch (e) {
    rethrow;
  }
}

/// Download bulk upload template (GET API with headers)
Future productDownloadBulkUploadTemplateApi() async {
  var response = await sendApiRequest(
    apiName: ApiAndParams.apiBulkUploadTemplate,
    params: {},
    isPost: false,
    isRequestedForInvoice: true,
  );

  return await response;
}

Future productDownloadProductDataExcelApi({required String from}) async {
  var response = await sendApiRequest(
      apiName: from == "upload"
          ? ApiAndParams.apiDownloadSampleProductFile
          : ApiAndParams.apiDownloadProductDataExcel,
      params: {},
      isPost: false,
      isRequestedForInvoice: true);

  return await response;
}

/// Get bulk upload instructions (GET API)
Future getBulkUploadInstructionsApi() async {
  var response = await sendApiRequest(
    apiName: ApiAndParams.apiBulkUploadInstructions,
    params: {},
    isPost: false,
  );

  return response;
}
