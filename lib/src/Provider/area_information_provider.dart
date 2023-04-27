import 'dart:convert';

import 'package:dartx/dartx.dart';
import 'package:flutter/cupertino.dart';

import '../Data/Model/area_info_model.dart';
import '../Data/Model/data_access_param.dart';
import '../Data/Model/union_model.dart';
import '../Data/Repository/auth_repo.dart';
import '../Data/datasource/apiservices/apiservices/responseApi/api_response.dart';
import '../util/code_util.dart';
import '../util/show_custom_snakbar.dart';

class AreaInformationProvider with ChangeNotifier {
  final AuthRepo? authRepo;

  AreaInformationProvider(this.authRepo);

  DataAccessParam? _dataAccessParam;
  DataAccessParam? get dataAccessParam => _dataAccessParam;

  List<ThanaModel> _thanaList = [];
  List<ThanaModel> get thanaList => _thanaList;
  List<ThanaModel> _tempthanaList = [];
  List<ThanaModel> get tempthanaList => _tempthanaList;

  List<ThanaModel> _divThList = [];
  List<ThanaModel> get divThList => _divThList;

  List<ThanaModel> _distList = [];
  List<ThanaModel> get districtList => _distList;

  List<UnionModel> _unionList = [];
  List<UnionModel> get unionList => _unionList;

  List<UnionModel> _onlyunionList = [];
  List<UnionModel> get onlyunionList => _onlyunionList;

  List<UnionModel> _tempOnlyUnion = [];
  List<UnionModel> get temponlyUnion => _tempOnlyUnion;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future areaInformationProvider(BuildContext context) async {
    _dataAccessParam = null;
    _divThList = [];

    _thanaList = [];
    _isLoading = true;
    //notifyListeners();
    _dataAccessParam = DataAccessParam(
      comCod: "2501",
      procName: "dbo.SP_MICR_REPORT_CODEBOOK_01",
      procID: "AREAINFOLIST01",
    );
    var encryptedADCData = CodeUtil.convertToBase64(_dataAccessParam!);
    ApiResponse apiResponse = await authRepo!.apiProcess(data1: encryptedADCData);
    _isLoading = false;

    if (apiResponse.response != null && (apiResponse.response!.statusCode == 200 || apiResponse.response!.statusCode == 201)) {
      _thanaList = [];
      _divThList = [];
      String decompressedJson = CodeUtil.decompress(apiResponse.response!.data.toString());

      var jsonAdc = jsonDecode(decompressedJson.toString());
      if (jsonAdc.containsKey("ErrorTable")) {
        for (var element in jsonAdc["ErrorTable"]) {
          showCustomSnackBar(element["errormessage"], context);
        }
      } else {
        for (var element in jsonAdc['Table']) {
          _thanaList.add(ThanaModel.fromJson(element));
        }
      }

      _tempthanaList = thanaList;
      _divThList = thanaList.distinctBy((element) => element.aDivid).toList();
      _distList = thanaList.distinctBy((element) => element.aDistrict).toList();
      // log(json);
    } else {
      if (!context.mounted) return;
      showCustomSnackBar('Failed to Load Data', context, isError: true);
    }
    notifyListeners();
  }

  Future unionVillageInfoProvider(
    BuildContext context, {
    required String thanaID,
  }) async {
    _dataAccessParam = null;
    _unionList = [];
    _onlyunionList = [];
    _tempOnlyUnion = [];
    _isLoading = true;
    //notifyListeners();
    _dataAccessParam = DataAccessParam(
      comCod: "2501",
      procName: "dbo.SP_MICR_REPORT_CODEBOOK_01",
      procID: "UNIONVILLINFLIST01",
      parm01: thanaID,
    );
    var encryptedADCData = CodeUtil.convertToBase64(_dataAccessParam!);
    ApiResponse apiResponse = await authRepo!.apiProcess(data1: encryptedADCData);
    _isLoading = false;

    if (apiResponse.response != null && (apiResponse.response!.statusCode == 200 || apiResponse.response!.statusCode == 201)) {
      _unionList = [];
      _onlyunionList = [];
      _tempOnlyUnion = [];
      String decompressedJson = CodeUtil.decompress(apiResponse.response!.data.toString());

      var jsonAdc = jsonDecode(decompressedJson.toString());
      if (jsonAdc.containsKey("ErrorTable")) {
        for (var element in jsonAdc["ErrorTable"]) {
          showCustomSnackBar(element["errormessage"], context);
        }
      } else {
        for (var element in jsonAdc['Table']) {
          _unionList.add(UnionModel.fromJson(element));
        }
      }

      _onlyunionList = unionList.where((element) => element.uvcode!.endsWith("00")).toList();
      _tempOnlyUnion = onlyunionList;
      //_tempthanaList = thanaList;
      // log(json);
    }
    notifyListeners();
  }

  List<ThanaModel> distListGen(String id) {
    var distList = [];
    distList = thanaList.where((element) => element.aDivid == id).toList();

    return [...distList];
  }

  bool isAreaSearch = false;

  searchThAreaData(String query) {
    if (query.isEmpty) {
      _thanaList.clear();
      _thanaList = _tempthanaList;

      isAreaSearch = false;
      notifyListeners();
    } else {
      _thanaList = [];
      isAreaSearch = true;
      _tempthanaList.forEach((item) async {
        if ((item.thname!.toLowerCase().contains(query.toLowerCase())) ||
            (item.divname!.toLowerCase().contains(query.toLowerCase())) ||
            (item.distname!.toLowerCase().contains(query.toLowerCase())) ||
            (item.aDivid!.toLowerCase().contains(query.toLowerCase()))) {
          _thanaList.add(item);
        }
      });
      notifyListeners();
    }
  }

  List<UnionModel> villageInfoList(String unionId) {
    var unionsList = unionList
        .where((element) => element.uvcode!.substring(0, 2) == unionId.substring(0, 2) && !element.uvcode!.endsWith('000'))
        .toList();
    return [...unionsList];
  }

  searchunion(String query) {
    if (query.isEmpty) {
      _onlyunionList.clear();
      _onlyunionList = temponlyUnion;

      isAreaSearch = false;
      notifyListeners();
    } else {
      _onlyunionList = [];
      isAreaSearch = true;
      temponlyUnion.forEach((item) async {
        if ((item.uvname!.toLowerCase().contains(query.toLowerCase())) ||
            (item.uvnamb!.contains(query)) ||
            (item.uvcode!.toLowerCase().contains(query.toLowerCase()))) {
          _onlyunionList.add(item);
        }
      });
      notifyListeners();
    }
  }

  filterDivision(String query) {
    if (query.isEmpty) {
      _thanaList.clear();
      _thanaList = _tempthanaList;

      isAreaSearch = false;
      notifyListeners();
    } else {
      _thanaList = [];
      isAreaSearch = true;
      _tempthanaList.forEach((item) async {
        if (item.aDivid!.substring(0, 2) == query) {
          _thanaList.add(item);
        }
      });
      notifyListeners();
    }
  }

  filterDistrict(String query) {
    if (query.isEmpty) {
      _thanaList.clear();
      _thanaList = tempthanaList;

      isAreaSearch = false;
      notifyListeners();
    } else {
      _thanaList = [];
      isAreaSearch = true;
      tempthanaList.forEach((item) async {
        if (item.aDivid!.substring(0, 2) == query) {
          _thanaList.add(item);
        }
      });
      notifyListeners();
    }
  }

  bool isUnionTile = false;
  int ourIndex = -1;
  selectUnionExpand({required int index}) {
    ourIndex = index;
    if (ourIndex == index) {
      isUnionTile = !isUnionTile;
      notifyListeners();
    }
  }
}
