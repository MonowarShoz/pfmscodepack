import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../Data/Model/adc_info_model.dart';
import '../Data/Model/data_access_param.dart';
import '../Data/Model/sub_branch_details.dart';
import '../Data/Repository/auth_repo.dart';
import '../Data/datasource/apiservices/apiservices/responseApi/api_response.dart';
import '../util/code_util.dart';
import '../util/show_custom_snakbar.dart';

class AdcInformationProvider with ChangeNotifier {
  final AuthRepo? authRepo;

  AdcInformationProvider(
    this.authRepo,
  );

  List<AdcModel> _adcList = [];
  List<AdcModel> get adcList => _adcList;
  DataAccessParam? _dataAccessParam;
  DataAccessParam? get dataAccessParam => _dataAccessParam;

  List<AdcModel> _adcBranchList = [];
  List<AdcModel> get adcBranchList => _adcBranchList;

  List<SubBranchDetails> _subBrnchListInfoList = [];
  List<SubBranchDetails> get subBrnchListInfoList => _subBrnchListInfoList;

  List<AdcModel> _tempAdcList = [];
  List<AdcModel> get tempAdcList => _tempAdcList;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future adcInformationProvider(BuildContext context) async {
    _dataAccessParam = null;

    _adcList = [];
    _adcBranchList = [];
    _subBrnchListInfoList = [];
    _isLoading = true;
    //notifyListeners();
    _dataAccessParam = DataAccessParam(
      comCod: "2501",
      procName: "dbo.SP_MICR_REPORT_CODEBOOK_01",
      procID: "ADCINFOLIST01",
      parm01: "%",
    );
    var encryptedADCData = CodeUtil.convertToBase64(_dataAccessParam!);
    ApiResponse apiResponse = await authRepo!.apiProcess(data1: encryptedADCData);
    _isLoading = false;

    if (apiResponse.response != null && (apiResponse.response!.statusCode == 200 || apiResponse.response!.statusCode == 201)) {
      _adcList = [];
      _adcBranchList = [];
      _subBrnchListInfoList = [];
      String decompressedJson = CodeUtil.decompress(apiResponse.response!.data.toString());

      var jsonAdc = jsonDecode(decompressedJson.toString());

      for (var element in jsonAdc['Table']) {
        _adcList.add(AdcModel.fromJson(element));
      }
      for (var element in jsonAdc['Table1']) {
        _adcBranchList.add(AdcModel.fromJson(element));
      }
      for (var element in jsonAdc['Table2']) {
        _subBrnchListInfoList.add(SubBranchDetails.fromJson(element));
      }
      //var tmpBranch = _adcBranchList.where((item) => ).toList();
      _tempAdcList = adcList;
      // log(json);
    } else {
      if (!context.mounted) return;

      showCustomSnackBar('Failed to load data', context, isError: true);
    }
    notifyListeners();
  }
  //  findkormiFromBranchList(String adcid) {
  //   _kormiFromBrnch = subBrnchListInfoList.where((element) => element.adcid!.contains(adcid)).toList();
  //   _tempkormiFromBrnch = kormiFromBrnch;
  // }

  bool isadcSearch = false;
  // Search ADC Data
  searchAdcData(String query) {
    if (query.isEmpty) {
      _adcList.clear();
      _adcList = tempAdcList;

      isadcSearch = false;
      notifyListeners();
    } else {
      _adcList = [];
      isadcSearch = true;
      tempAdcList.forEach((item) async {
        if ((item.adcid!.toLowerCase().contains(query.toLowerCase())) ||
            (item.aName!.toLowerCase().contains(query.toLowerCase())) ||
            (item.aThana!.toLowerCase().contains(query.toLowerCase()))) {
          _adcList.add(item);
        }
      });
      notifyListeners();
    }
  }

  //  findkormiFromBranchList(String adcid) {
  //   _kormiFromBrnch = subBrnchListInfoList.where((element) => element.adcid!.contains(adcid)).toList();
  //   _tempkormiFromBrnch = kormiFromBrnch;
  // }
}
