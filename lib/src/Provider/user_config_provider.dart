import 'dart:convert';
import 'dart:developer';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:dartx/dartx.dart';

import 'package:crypto/crypto.dart';
// import 'package:archive/archive.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../Data/Model/adc_info_model.dart';
import '../Data/Model/ch_acc_model.dart';
import '../Data/Model/data_access_param.dart';
import '../Data/Model/group_shomiti_model.dart';
import '../Data/Model/jwt_token_model.dart';
import '../Data/Model/member_info_model.dart';
import '../Data/Model/response_model.dart';
import '../Data/Model/staff_information_model.dart';
import '../Data/Model/sub_branch_details.dart';
import '../Data/Model/user_info_model.dart';
import '../Data/Repository/auth_repo.dart';
import '../Data/datasource/apiservices/apiservices/responseApi/api_response.dart';
import '../util/code_util.dart';
import '../util/show_custom_snakbar.dart';

class UserConfigProvider with ChangeNotifier {
  final AuthRepo? authRepo;

  UserConfigProvider(this.authRepo);

  DataAccessParam? _dataAccessParam;
  DataAccessParam? get dataAccessParam => _dataAccessParam;

  JwtTokenInfo? _jwtTokenInfo;
  JwtTokenInfo? get jwtTokenInfo => _jwtTokenInfo;

  UserInfoModel? _userInfoModel;
  UserInfoModel? get userInfoModel => _userInfoModel;

  Future<ResponseModel> login(
    BuildContext context,
  ) async {
    _jwtTokenInfo = null;

    ApiResponse apiResponse = await authRepo!.login();
    ResponseModel responseModel;
    if (apiResponse.response != null && (apiResponse.response!.statusCode == 200 || apiResponse.response!.statusCode == 201)) {
      _jwtTokenInfo = JwtTokenInfo.fromJson(apiResponse.response!.data);

      authRepo!.saveUserToken(_jwtTokenInfo!.tokenstr);
      responseModel = ResponseModel(true, '${apiResponse.response}');
      debugPrint('success');
      //showCustomSnackBar('Success', context, isError: false);
    } else {
      responseModel = ResponseModel(false, '${apiResponse.error}');
      debugPrint('failed');
      //showCustomSnackBar('Success', context, isError: true);
    }
    notifyListeners();
    return responseModel;
  }

  String? _userstring;
  String? get userString => _userstring;

  bool _isLoginSuccess = false;
  bool get isLoginSuccess => _isLoginSuccess;

  bool _isLoginLoad = false;
  bool get isLoginLoad => _isLoginLoad;

  Future<ResponseModel> loginAccess(
    BuildContext context, {
    required String loginName,
    required String password,
  }) async {
    _dataAccessParam = null;
    _userInfoModel = null;
    String jsonDs1 = "";

    _dataAccessParam = DataAccessParam(
      comCod: "2501",
      procName: "dbo.SP_MICR_REPORT_CODEBOOK_01",
      procID: "USERLOGINACT01",
      parmJson1: null,
      parmJson2: null,
      parmBin01: null,
      parm01: "",
      parm02: loginName,
    );
    _isLoginLoad = true;
    var encryptedData = CodeUtil.convertToBase64(_dataAccessParam!);
    ApiResponse apiResponse = await authRepo!.apiProcess(data1: encryptedData);
    _isLoginLoad = false;
    ResponseModel responseModel;
    if (apiResponse.response != null && (apiResponse.response!.statusCode == 200 || apiResponse.response!.statusCode == 201)) {
      _userInfoModel = UserInfoModel();
      log(apiResponse.response!.data.toString());

      String decompressedJson = CodeUtil.decompress(apiResponse.response!.data.toString());

      var jsonResponse = jsonDecode(decompressedJson.toString());
      log(jsonResponse.toString());

      // var jsonResponse = jsonDecode(apiResponse.response!.data);
      for (var element in jsonResponse['Table']) {
        _userInfoModel = UserInfoModel.fromJson(element);
      }
      if (userInfoModel!.stafid != null) {
        var encodedAuthData = CodeUtil.encodedPassword(userInfoModel!.stafid! + loginName + password);
        var dashString = encodedAuthData.replaceAll('-', '');
        var finalDash = CodeUtil.addDashes(dashString);
        if (userInfoModel!.paswrd != finalDash.toUpperCase()) {
          _isLoginSuccess = false;
        } else {
          _isLoginSuccess = true;
        }
      } else {
        _isLoginSuccess = false;
      }

      responseModel = ResponseModel(true, '${apiResponse.response}');
    } else {
      responseModel = ResponseModel(false, '${apiResponse.error}');
      // showCustomSnackBar('Operation Failed', context, isError: true);
    }

    notifyListeners();
    return responseModel;
  }

//   "ComCod": "2501",
//   "ProcName": "dbo.SP_MICR_REPORT_CODEBOOK_01",
//   "ProcID": "VERSIONCHK01",
  String _versionNumber = '';
  String get versionNumber => _versionNumber;
  Future<ResponseModel> versionChk() async {
    _dataAccessParam = null;
    _dataAccessParam = DataAccessParam(
      comCod: "2501",
      procName: "dbo.SP_MICR_REPORT_CODEBOOK_01",
      procID: "VERSIONCHK01",
    );
    var encryptedverschk = CodeUtil.convertToBase64(_dataAccessParam!);
    ApiResponse apiResponse = await authRepo!.apiProcess(data1: encryptedverschk);
    ResponseModel responseModel;
    if (apiResponse.response != null && (apiResponse.response!.statusCode == 200 || apiResponse.response!.statusCode == 201)) {
      String decompressedJson = CodeUtil.decompress(apiResponse.response!.data.toString());

      var jsonverschk = jsonDecode(decompressedJson.toString());
      for (var element in jsonverschk['Table']) {
        _versionNumber = element["app_version"];
      }
      versionNumber.isNotEmpty
          ? responseModel = ResponseModel(true, '${apiResponse.response}')
          : responseModel = ResponseModel(false, '${apiResponse.response}');
    } else {
      responseModel = ResponseModel(false, '${apiResponse.error}');
      // showCustomSnackBar('Version Checking Failed', context, isError: true);
    }
    notifyListeners();
    return responseModel;
  }

  String stripMargin(String s) {
    return s.splitMapJoin(
      RegExp(r'^', multiLine: true),
      onMatch: (_) => '\n',
      onNonMatch: (n) => n.trim(),
    );
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<GroupShomitiModel> _shomitiList = [];
  List<GroupShomitiModel> get shomitiList => _shomitiList;
  List<GroupShomitiModel> _kormiwiseshomitiList = [];
  List<GroupShomitiModel> get kormiwiseshomitiList => _kormiwiseshomitiList;
  List<GroupShomitiModel> _pdfShomitiList = [];
  List<GroupShomitiModel> get pdfshomitiList => _pdfShomitiList;
  List<MemberInfoModel> _memberInfoList = [];
  List<MemberInfoModel> get memberInfoList => _memberInfoList;
  List<GroupShomitiModel> _tempShomitiList = [];
  List<MemberInfoModel> _tempmemberInfoList = [];

  //for group shomiti
  Future groupWiseKormiProvider(BuildContext context, String branchID) async {
    _shomitiList = [];
    _tempShomitiList = [];
    _pdfShomitiList = [];
    _dataAccessParam = null;
    _isLoading = true;
    _dataAccessParam = DataAccessParam(
      comCod: "2501",
      procName: "dbo.SP_MICR_REPORT_CODEBOOK_01",
      procID: "GROUPINFOLIST01",
      parm01: branchID,
    );
    var encryptedgroupData = CodeUtil.convertToBase64(_dataAccessParam!);
    ApiResponse apiResponse = await authRepo!.apiProcess(data1: encryptedgroupData);
    _isLoading = false;
    if (apiResponse.response != null && (apiResponse.response!.statusCode == 200 || apiResponse.response!.statusCode == 201)) {
      _shomitiList = [];
      _tempShomitiList = [];
      _pdfShomitiList = [];
      String decompressedJson = CodeUtil.decompress(apiResponse.response!.data.toString());

      var jsonGroup = jsonDecode(decompressedJson.toString());

      for (var element in jsonGroup['Table']) {
        _shomitiList.add(GroupShomitiModel.fromJson(element));
      }
      //_shomitiList.chunkWhile((p0, p1) => p0.kormi == p1.kormi);
      _tempShomitiList = shomitiList;
    } else {
      if (!context.mounted) return;

      showCustomSnackBar('Failed to Load Data', context, isError: true);
    }
    notifyListeners();
  }

  findShomitiofKormi(String kormi) {
    _kormiwiseshomitiList = [];
    _kormiwiseshomitiList = shomitiList.where((element) => element.kormi == kormi).toList();
    notifyListeners();
  }

  List<SubBranchDetails> _kormiFromBrnch = [];
  List<SubBranchDetails> get kormiFromBrnch => _kormiFromBrnch;

  List<SubBranchDetails> _tempkormiFromBrnch = [];
  List<SubBranchDetails> get tempkormiFromBrnch => _tempkormiFromBrnch;

  List<GroupShomitiModel> _kormiwiseShomiti = [];
  List<GroupShomitiModel> get kormiWiseShomiti => _kormiwiseShomiti;

  List<GroupShomitiModel> _tempkormiwiseShomiti = [];
  List<GroupShomitiModel> get tempkormiWiseShomiti => _tempkormiwiseShomiti;

  //bool isadcSearch = false;

  findkormiFromBranchList(String adcid) {
    _kormiFromBrnch = subBrnchListInfoList.where((element) => element.adcid!.contains(adcid)).toList();
    _tempkormiFromBrnch = kormiFromBrnch;
  }

  searchkormiFromBrnchData(String query) {
    if (query.isEmpty) {
      _kormiFromBrnch.clear();
      _kormiFromBrnch = tempkormiFromBrnch;

      isadcSearch = false;
      notifyListeners();
    } else {
      _kormiFromBrnch = [];
      isadcSearch = true;
      tempkormiFromBrnch.forEach((item) async {
        if ((item.lName!.toLowerCase().contains(query.toLowerCase())) ||
            (item.stafid.toString().toLowerCase().contains(query.toLowerCase()))) {
          _kormiFromBrnch.add(item);
        }
      });
      notifyListeners();
    }
  }

  kormiWiseGroupDetails(String kormiID) {
    _kormiwiseShomiti = shomitiList.where((element) => element.kormi!.contains(kormiID)).toList();
    _tempkormiwiseShomiti = kormiWiseShomiti;
  }

  searchkormiwiseShomitiData(String query) {
    if (query.isEmpty) {
      _kormiwiseShomiti.clear();
      _kormiwiseShomiti = tempkormiWiseShomiti;

      isadcSearch = false;
      notifyListeners();
    } else {
      _kormiwiseShomiti = [];
      isadcSearch = true;
      tempkormiWiseShomiti.forEach((item) async {
        if ((item.lName!.toLowerCase().contains(query.toLowerCase())) || (item.sgName!.contains(query))) {
          _kormiwiseShomiti.add(item);
        }
      });
      notifyListeners();
    }
  }

  searchShomitiData(String query) {
    if (query.isEmpty) {
      _shomitiList.clear();
      _shomitiList = _tempShomitiList;

      isadcSearch = false;
      notifyListeners();
    } else {
      _shomitiList = [];
      isadcSearch = true;
      _tempShomitiList.forEach((item) async {
        if ((item.lName!.toLowerCase().contains(query.toLowerCase())) ||
            (item.kormi!.contains(query)) ||
            (item.sgName!.contains(query)) ||
            (item.sgGroup.toString().toLowerCase().contains(query.toLowerCase()))) {
          _shomitiList.add(item);
        }
      });
      notifyListeners();
    }
  }

  Future groupMemberProvider(BuildContext context, String branchID, String groupID) async {
    _dataAccessParam = null;
    _memberInfoList = [];
    _tempmemberInfoList = [];
    _isLoading = true;
    _dataAccessParam = DataAccessParam(
      comCod: "2501",
      procName: "dbo.SP_MICR_REPORT_CODEBOOK_01",
      procID: "MEMBERINFOLIST01",
      parm01: branchID,
      parm02: groupID,
    );
    var encryptedgroupMemberData = CodeUtil.convertToBase64(_dataAccessParam!);
    ApiResponse apiResponse = await authRepo!.apiProcess(data1: encryptedgroupMemberData);
    _isLoading = false;
    if (apiResponse.response != null && (apiResponse.response!.statusCode == 200 || apiResponse.response!.statusCode == 201)) {
      _memberInfoList = [];
      _tempmemberInfoList = [];
      String decompressedJson = CodeUtil.decompress(apiResponse.response!.data.toString());

      var jsonGroup = jsonDecode(decompressedJson.toString());
      //var jsonGroup = jsonDecode(apiResponse.response!.data);
      for (var element in jsonGroup['Table']) {
        _memberInfoList.add(MemberInfoModel.fromJson(element));
      }
      _tempmemberInfoList = memberInfoList;
    } else {
      showCustomSnackBar('Failed to Load Data', context, isError: true);
    }
  }

  searchMembershomiti(String query) {
    if (query.isEmpty) {
      _memberInfoList.clear();
      _memberInfoList = _tempmemberInfoList;

      isadcSearch = false;
      notifyListeners();
    } else {
      _memberInfoList = [];
      isadcSearch = true;
      _tempmemberInfoList.forEach((item) async {
        if ((item.smNameE.toString().toLowerCase().contains(query.toLowerCase())) || (item.smName!.contains(query))) {
          _memberInfoList.add(item);
        }
      });
      notifyListeners();
    }
  }

  clearInfo() {
    _kormiFromBrnch.clear();
    _shomitiList.clear();
    _selectAdcforGwkL = '';
    _selectAdcIdforBrnch = '';
    _getbrnchName = '';
    adcValuegrm = '';
  }

  bool _isHideContainer = false;
  bool get isHideContainer => _isHideContainer;
  hideContainer() {
    _isHideContainer = !_isHideContainer;
    notifyListeners();
  }

  nohideContainer() {
    _isHideContainer = false;
    notifyListeners();
  }

  String _selectAdcforGwkL = '';
  String get selectAdcforGwkL => _selectAdcforGwkL;
  setAdcForGwkl(String selval) {
    _selectAdcforGwkL = selval;
    notifyListeners();
  }
  // String setautoAdcValue(){

  // }

  String _selectAdcIdforBrnch = '';
  String get selectAdcIdforBrnch => _selectAdcIdforBrnch;
  getAdcforBrnch(String selval) {
    _selectAdcIdforBrnch = selval;
    notifyListeners();
  }

  String _getbrnchName = '';
  String get getbrnchName => _getbrnchName;
  clearName() {
    _getbrnchName = '';
    notifyListeners();
  }

  String _getbrnchID = '';
  String get getbrnchID => _getbrnchID;
  getbrnchIdfogGrpMemList({
    String? selval,
  }) {
    _getbrnchName = selval ?? '';

    notifyListeners();
  }

  String? adcValuegrm;

  getbrnchIDforMember({
    String? gID,
  }) {
    _getbrnchID = gID ?? '';

    notifyListeners();
  }

  devAreaVal(String id) {
    for (var element in adcList) {
      if (element.adcid!.substring(0, 6) == id.substring(0, 6)) {
        adcValuegrm = element.aName!;
        print('val$adcValuegrm');
      }
    }
    notifyListeners();
  }

  String? _getKormiName;
  String? get kormiName => _getKormiName;

  clearKormiName() {
    _getKormiName = '';
    notifyListeners();
  }

  getdrpKormiName(String? val) {
    _getKormiName = val;
    notifyListeners();
  }

  // List<ThanaModel> _thanaList = [];
  // List<ThanaModel> get thanaList => _thanaList;
  // List<ThanaModel> _tempthanaList = [];
  // List<ThanaModel> get tempthanaList => _tempthanaList;

  // List<ThanaModel> _divThList = [];
  // List<ThanaModel> get divThList => _divThList;

  // List<ThanaModel> _distList = [];
  // List<ThanaModel> get districtList => _distList;

  // Future areaInformationProvider(BuildContext context) async {
  //   _dataAccessParam = null;
  //   _divThList = [];

  //   _thanaList = [];
  //   _isLoading = true;
  //   //notifyListeners();
  //   _dataAccessParam = DataAccessParam(
  //     comCod: "2501",
  //     procName: "dbo.SP_MICR_REPORT_CODEBOOK_01",
  //     procID: "AREAINFOLIST01",
  //   );
  //   var encryptedADCData = CodeUtil.convertToBase64(_dataAccessParam!);
  //   ApiResponse apiResponse = await authRepo!.apiProcess(data1: encryptedADCData);
  //   _isLoading = false;

  //   if (apiResponse.response != null && (apiResponse.response!.statusCode == 200 || apiResponse.response!.statusCode == 201)) {
  //     _thanaList = [];
  //     _divThList = [];
  //     String decompressedJson = CodeUtil.decompress(apiResponse.response!.data.toString());

  //     var jsonAdc = jsonDecode(decompressedJson.toString());

  //     for (var element in jsonAdc['Table']) {
  //       _thanaList.add(ThanaModel.fromJson(element));
  //     }
  //     _tempthanaList = thanaList;
  //     _divThList = thanaList.distinctBy((element) => element.aDivid).toList();
  //     _distList = thanaList.distinctBy((element) => element.aDistrict).toList();
  //     // log(json);
  //   } else {
  //     if (!context.mounted) return;
  //     showCustomSnackBar('Failed to Load Data', context, isError: true);
  //   }
  //   notifyListeners();
  // }

  // List<ThanaModel> distListGen(String id) {
  //   var distList = [];
  //   distList = thanaList.where((element) => element.aDivid == id).toList();

  //   return [...distList];
  // }

  String _selectedDiv = '';
  String get selectedDiv => _selectedDiv;
  setdiv(String divid) {
    _selectedDiv = divid;
    notifyListeners();
  }

  clearText() {
    _selectedDiv = '';
    //notifyListeners();
  }

  // filterDivision(String query) {
  //   if (query.isEmpty) {
  //     _thanaList.clear();
  //     _thanaList = _tempthanaList;

  //     isadcSearch = false;
  //     notifyListeners();
  //   } else {
  //     _thanaList = [];
  //     isadcSearch = true;
  //     _tempthanaList.forEach((item) async {
  //       if (item.aDivid!.substring(0, 2) == query) {
  //         _thanaList.add(item);
  //       }
  //     });
  //     notifyListeners();
  //   }
  // }

  // filterDistrict(String query) {
  //   if (query.isEmpty) {
  //     _thanaList.clear();
  //     _thanaList = tempthanaList;

  //     isadcSearch = false;
  //     notifyListeners();
  //   } else {
  //     _thanaList = [];
  //     isadcSearch = true;
  //     tempthanaList.forEach((item) async {
  //       if (item.aDivid!.substring(0, 2) == query) {
  //         _thanaList.add(item);
  //       }
  //     });
  //     notifyListeners();
  //   }
  // }

  // List<UnionModel> _unionList = [];
  // List<UnionModel> get unionList => _unionList;

  // List<UnionModel> _onlyunionList = [];
  // List<UnionModel> get onlyunionList => _onlyunionList;

  // List<UnionModel> _tempOnlyUnion = [];
  // List<UnionModel> get temponlyUnion => _tempOnlyUnion;

  bool isUnionTile = false;
  bool isSubBranch = false;
  // bool get isUnionTile => _isUnionTile;

  int ourIndex = -1;
  int brIndex = -1;

  selectUnionExpand({required int index}) {
    ourIndex = index;
    if (ourIndex == index) {
      isUnionTile = !isUnionTile;
      notifyListeners();
    }
  }

  selectsubBranchBank({required int index}) {
    brIndex = index;
    if (brIndex == index) {
      isSubBranch = !isSubBranch;
      notifyListeners();
    }
  }

  // Future unionVillageInfoProvider({required String thanaID}) async {
  //   _dataAccessParam = null;
  //   _unionList = [];
  //   _onlyunionList = [];
  //   _tempOnlyUnion = [];
  //   _isLoading = true;
  //   //notifyListeners();
  //   _dataAccessParam = DataAccessParam(
  //     comCod: "2501",
  //     procName: "dbo.SP_MICR_REPORT_CODEBOOK_01",
  //     procID: "UNIONVILLINFLIST01",
  //     parm01: thanaID,
  //   );
  //   var encryptedADCData = CodeUtil.convertToBase64(_dataAccessParam!);
  //   ApiResponse apiResponse = await authRepo!.apiProcess(data1: encryptedADCData);
  //   _isLoading = false;

  //   if (apiResponse.response != null && (apiResponse.response!.statusCode == 200 || apiResponse.response!.statusCode == 201)) {
  //     _unionList = [];
  //     _onlyunionList = [];
  //     _tempOnlyUnion = [];
  //     String decompressedJson = CodeUtil.decompress(apiResponse.response!.data.toString());

  //     var jsonAdc = jsonDecode(decompressedJson.toString());

  //     for (var element in jsonAdc['Table']) {
  //       _unionList.add(UnionModel.fromJson(element));
  //     }
  //     _onlyunionList = unionList.where((element) => element.uvcode!.endsWith("00")).toList();
  //     _tempOnlyUnion = onlyunionList;
  //     //_tempthanaList = thanaList;
  //     // log(json);
  //   }
  //   notifyListeners();
  // }

  // List<UnionModel> villageInfoList(String unionId) {
  //   var unionsList = unionList
  //       .where((element) => element.uvcode!.substring(0, 2) == unionId.substring(0, 2) && !element.uvcode!.endsWith('000'))
  //       .toList();
  //   return [...unionsList];
  // }

  // searchunion(String query) {
  //   if (query.isEmpty) {
  //     _onlyunionList.clear();
  //     _onlyunionList = temponlyUnion;

  //     isadcSearch = false;
  //     notifyListeners();
  //   } else {
  //     _onlyunionList = [];
  //     isadcSearch = true;
  //     temponlyUnion.forEach((item) async {
  //       if ((item.uvname!.toLowerCase().contains(query.toLowerCase())) ||
  //           (item.uvnamb!.contains(query)) ||
  //           (item.uvcode!.toLowerCase().contains(query.toLowerCase()))) {
  //         _onlyunionList.add(item);
  //       }
  //     });
  //     notifyListeners();
  //   }
  // }

  // List<UnionModel> pdfVillageInfoList(String unionId) {
  //   var unionsList = unionList.where((element) => element.uvcode!.substring(0, 2) == unionId.substring(0, 2)).toList();
  //   return [...unionsList];
  // }

  List<AdcModel> _adcList = [];
  List<AdcModel> get adcList => _adcList;

  List<AdcModel> _adcBranchList = [];
  List<AdcModel> get adcBranchList => _adcBranchList;

  List<SubBranchDetails> _subBrnchListInfoList = [];
  List<SubBranchDetails> get subBrnchListInfoList => _subBrnchListInfoList;

  List<AdcModel> _tempAdcList = [];
  List<AdcModel> get tempAdcList => _tempAdcList;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future adcInformationProvider(BuildContext context, String dbVersionNumber) async {
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
      parm02: dbVersionNumber,
      //parm02: "230116.1",
      //parm02: "230130.1",
    );
    var encryptedADCData = CodeUtil.convertToBase64(_dataAccessParam!);
    ApiResponse apiResponse = await authRepo!.apiProcess(data1: encryptedADCData);
    _isLoading = false;

    if (apiResponse.response != null && (apiResponse.response!.statusCode == 200 || apiResponse.response!.statusCode == 201)) {
      _adcList = [];
      _adcBranchList = [];
      _subBrnchListInfoList = [];
      String decompressedJson = CodeUtil.decompress(apiResponse.response!.data.toString());

      Map<String, dynamic> jsonAdc = jsonDecode(decompressedJson.toString());
      if (jsonAdc.containsKey("ErrorTable")) {
        for (var element in jsonAdc["ErrorTable"]) {
          _errorMessage = element["errormessage"];
          // if (!context.mounted) return;

          showCustomSnackBar(errorMessage!, context);
        }
      } else {
        for (var element in jsonAdc['Table']) {
          _adcList.add(AdcModel.fromJson(element));
        }
        for (var element in jsonAdc['Table1']) {
          _adcBranchList.add(AdcModel.fromJson(element));
        }
        for (var element in jsonAdc['Table2']) {
          _subBrnchListInfoList.add(SubBranchDetails.fromJson(element));
        }
        _tempAdcList = adcList;
      }

      //var tmpBranch = _adcBranchList.where((item) => ).toList();

      // log(json);
    } else {
      if (!context.mounted) return;

      showCustomSnackBar('Failed to load data', context, isError: true);
    }
    notifyListeners();
  }

  bool isadcSearch = false;
  //Search ADC Data
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

  // List<BankInformation> _allBankList = [];
  // List<BankInformation> get bankList => _allBankList;

  // List<BankInformation> _mainHeadbankList = [];
  // List<BankInformation> get mainHeadBankList => _mainHeadbankList;

  // List<BankInformation> _subHeadBankList = [];
  // List<BankInformation> get bankBranchList => _subHeadBankList;

  // List<BankInformation> _tempBank = [];

  // Future bankListInfoProvider(BuildContext context) async {
  //   _dataAccessParam = null;
  //   _allBankList = [];
  //   _mainHeadbankList = [];
  //   _tempBank = [];

  //   _isLoading = true;
  //   //notifyListeners();
  //   _dataAccessParam = DataAccessParam(
  //     comCod: "2501",
  //     procName: "dbo.SP_MICR_REPORT_ACCOUNTS_01",
  //     procID: "BANKNAMELIST01",
  //   );
  //   var encryptedADCData = CodeUtil.convertToBase64(_dataAccessParam!);
  //   ApiResponse apiResponse = await authRepo!.apiProcess(data1: encryptedADCData);
  //   _isLoading = false;

  //   if (apiResponse.response != null && (apiResponse.response!.statusCode == 200 || apiResponse.response!.statusCode == 201)) {
  //     _allBankList = [];
  //     _mainHeadbankList = [];
  //     _tempBank = [];
  //     String decompressedJson = CodeUtil.decompress(apiResponse.response!.data.toString());

  //     var jsonAdc = jsonDecode(decompressedJson.toString());

  //     for (var element in jsonAdc['Table']) {
  //       _allBankList.add(BankInformation.fromJson(element));
  //     }
  //     _mainHeadbankList = _allBankList.where((element) => element.bankid!.endsWith('000')).toList();
  //     // _subHeadBankList =
  //     _tempBank = mainHeadBankList;
  //     // log(json);
  //   } else {
  //     if (!context.mounted) return;
  //     showCustomSnackBar('Failed to load data', context, isError: true);
  //   }
  //   notifyListeners();
  // }

  // List<ChofAccTypeModel> _chartOfAaccTypeList = [];
  // List<ChofAccTypeModel> get chartOfAccTypeList => _chartOfAaccTypeList;

  // List<ChofAccModel> _chartOfAaccList = [];
  // List<ChofAccModel> get chartOfAccList => _chartOfAaccList;

  // List<ChofAccModel> _tempchartOfAaccList = [];
  // List<ChofAccModel> get tempchartOfAaccList => _tempchartOfAaccList;

  // Future chartsOfAccountsProvider(BuildContext context) async {
  //   _dataAccessParam = null;
  //   _chartOfAaccTypeList = [];
  //   _chartOfAaccList = [];
  //   _isLoading = true;
  //   //notifyListeners();
  //   _dataAccessParam = DataAccessParam(
  //     comCod: "2501",
  //     procName: "dbo.SP_MICR_REPORT_CODEBOOK_01",
  //     procID: "CHARTOFACCLIST01",
  //   );
  //   var encryptedADCData = CodeUtil.convertToBase64(_dataAccessParam!);
  //   ApiResponse apiResponse = await authRepo!.apiProcess(data1: encryptedADCData);
  //   _isLoading = false;

  //   if (apiResponse.response != null && (apiResponse.response!.statusCode == 200 || apiResponse.response!.statusCode == 201)) {
  //     _chartOfAaccTypeList = [];
  //     _chartOfAaccList = [];
  //     String decompressedJson = CodeUtil.decompress(apiResponse.response!.data.toString());

  //     var jsonAdc = jsonDecode(decompressedJson.toString());

  //     for (var element in jsonAdc['Table']) {
  //       _chartOfAaccTypeList.add(ChofAccTypeModel.fromJson(element));
  //     }
  //     for (var element in jsonAdc['Table1']) {
  //       _chartOfAaccList.add(ChofAccModel.fromJson(element));
  //     }
  //     _tempchartOfAaccList = chartOfAccList;

  //     // log(json);
  //   } else {
  //     if (!context.mounted) return;
  //     showCustomSnackBar('Failed to load data', context, isError: true);
  //   }
  //   notifyListeners();
  // }

  // //chart of accounts search
  // searchChartofAccount(String query) {
  //   if (query.isEmpty) {
  //     _chartOfAaccList.clear();
  //     _chartOfAaccList = tempchartOfAaccList;
  //     isadcSearch = false;

  //     notifyListeners();
  //   } else {
  //     _chartOfAaccList = [];
  //     isadcSearch = true;
  //     for (var element in tempchartOfAaccList) {
  //       if (element.acctitle!.toLowerCase().contains(query.toLowerCase()) ||
  //           element.acctype!.toLowerCase().contains(query.toLowerCase())) {
  //         _chartOfAaccList.add(element);
  //       }
  //     }
  //   }
  //   notifyListeners();
  // }

  // int chIndex = -1;
  // bool isMainchOAc = false;

  // selectChOfAccnt({required int index}) {
  //   chIndex = index;
  //   if (chIndex == index) {
  //     isMainchOAc = !isMainchOAc;
  //     notifyListeners();
  //   }
  // }

  // List<BankInformation> banksubBranchList(String id) {
  //   var bankList = [];
  //   bankList = _allBankList
  //       .where((element) =>
  //           element.bankid!.substring(0, 3) == id.substring(0, 3) &&
  //           element.bankid!.endsWith('00') &&
  //           !element.bankid!.endsWith('000'))
  //       .toList();
  //   return [...bankList];
  // }

  // List<BankInformation> banksubBranchAccountsList(String id) {
  //   var bankList = [];
  //   bankList = _allBankList
  //       .where((element) => element.bankid!.substring(0, 6) == id.substring(0, 6) && !element.bankid!.endsWith('00'))
  //       .toList();
  //   return [...bankList];
  // }

  // List<ChofAccModel> chartOfaccList(
  //   String accType,
  // ) {
  //   var bankList = [];

  //   bankList = chartOfAccList.where((element) => element.acctype!.trim() == accType.trim()).toList();

  //   return [...bankList];
  // }

  // List<ChofAccModel> cdetOfaccList(
  //   String id,
  // ) {
  //   var bankList = [];

  //   bankList = chartOfAccList
  //       .where((element) =>
  //           element.accid!.substring(0, 3) == id && element.accid!.endsWith('000') && !element.accid!.endsWith('000000'))
  //       .toList();

  //   return [...bankList];
  // }

  // List<ChofAccModel> subchoAcList(
  //   String accID,
  // ) {
  //   var bankList = [];

  //   bankList = chartOfAccList
  //       .where(
  //           (element) => element.accid!.substring(0, 5).trim() == accID.substring(0, 5).trim() && !element.accid!.endsWith('000'))
  //       .toList();

  //   return [...bankList];
  // }

//-------------------------------PDF GENERATOR METHODS--------------------------------------/
//   String? simpleMethod() {
//     String? sampleString;
//     var a = """<tr>
// <td>Hello</td><td>World</td>
// </tr>""";
//     for (var i = 0; i < thanaList.length; i++) {
//       log('simple $a');
//       sampleString = a;
//     }
//     return sampleString;
//   }

  bool _isPdf = false;
  bool get isPdf => _isPdf;
  pdfset(bool pdfcond) {
    _isPdf = pdfcond;
    notifyListeners();
  }

  List<AdcModel> findADCwiseBranch(String madcid) {
    List findBrnchList = adcBranchList.where((element) => element.madcid!.contains(madcid)).toList();
    return [...findBrnchList];
  }

  List<SubBranchDetails> findBrancwiseDetails(String adcid) {
    List findBrnchList = [];
    findBrnchList = subBrnchListInfoList.where((element) => element.adcid!.contains(adcid)).toList();
    return [...findBrnchList];
  }

  bool _isAdcSearchEnable = false;
  bool get isAdcSearch => _isAdcSearchEnable;
  setSearch() {
    _isAdcSearchEnable = !_isAdcSearchEnable;
    notifyListeners();
  }

  unsetSearch() {
    _isAdcSearchEnable = false;
    notifyListeners();
  }

  bool ismemberTable = false;
  showMemberTableView() {
    ismemberTable = !ismemberTable;
    notifyListeners();
  }

  bool _isActiveRememberMe = false;

  bool get isActiveRememberMe => _isActiveRememberMe;

  toggleRememberMe() {
    _isActiveRememberMe = !_isActiveRememberMe;
    notifyListeners();
  }

  void saveUserNumberAndPassword(String username, String password) {
    authRepo!.saveUserNumberAndPassword(username: username, password: password);
  }

  String getUserEmail() {
    return authRepo!.getUserName();
  }

  String getUserPassword() {
    return authRepo!.getUserPassword();
  }

  void clearToken() async {
    await authRepo!.cleanBarearToken();
  }

  Future<bool> clearUserEmailAndPassword() async {
    return authRepo!.clearUserNumberAndPassword();
  }

  final adcSearchController = TextEditingController();
  clearcontr() {
    adcSearchController.clear();
  }
}
