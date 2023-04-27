import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../Data/Model/bank_info_model.dart';
import '../Data/Model/ch_acc_model.dart';
import '../Data/Model/ch_actype_model.dart';
import '../Data/Model/data_access_param.dart';
import '../Data/Repository/auth_repo.dart';
import '../Data/datasource/apiservices/apiservices/responseApi/api_response.dart';
import '../util/code_util.dart';
import '../util/show_custom_snakbar.dart';

class ChBankAccountProvider with ChangeNotifier {
  final AuthRepo? authRepo;

  ChBankAccountProvider(this.authRepo);

  DataAccessParam? _dataAccessParam;
  DataAccessParam? get dataAccessParam => _dataAccessParam;

  List<BankInformation> _allBankList = [];
  List<BankInformation> get bankList => _allBankList;

  List<BankInformation> _mainHeadbankList = [];
  List<BankInformation> get mainHeadBankList => _mainHeadbankList;

  List<BankInformation> _subHeadBankList = [];
  List<BankInformation> get bankBranchList => _subHeadBankList;

  List<BankInformation> _tempBank = [];
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future bankListInfoProvider(BuildContext context) async {
    _dataAccessParam = null;
    _allBankList = [];
    _mainHeadbankList = [];
    _tempBank = [];

    _isLoading = true;
    //notifyListeners();
    _dataAccessParam = DataAccessParam(
      comCod: "2501",
      procName: "dbo.SP_MICR_REPORT_ACCOUNTS_01",
      procID: "BANKNAMELIST01",
    );
    var encryptedADCData = CodeUtil.convertToBase64(_dataAccessParam!);
    ApiResponse apiResponse = await authRepo!.apiProcess(data1: encryptedADCData);
    _isLoading = false;

    if (apiResponse.response != null && (apiResponse.response!.statusCode == 200 || apiResponse.response!.statusCode == 201)) {
      _allBankList = [];
      _mainHeadbankList = [];
      _tempBank = [];
      String decompressedJson = CodeUtil.decompress(apiResponse.response!.data.toString());

      var jsonAdc = jsonDecode(decompressedJson.toString());

      for (var element in jsonAdc['Table']) {
        _allBankList.add(BankInformation.fromJson(element));
      }
      _mainHeadbankList = _allBankList.where((element) => element.bankid!.endsWith('000')).toList();
      // _subHeadBankList =
      _tempBank = mainHeadBankList;
      // log(json);
    } else {
      if (!context.mounted) return;
      showCustomSnackBar('Failed to load data', context, isError: true);
    }
    notifyListeners();
  }

  List<ChofAccTypeModel> _chartOfAaccTypeList = [];
  List<ChofAccTypeModel> get chartOfAccTypeList => _chartOfAaccTypeList;

  List<ChofAccModel> _chartOfAaccList = [];
  List<ChofAccModel> get chartOfAccList => _chartOfAaccList;

  List<ChofAccModel> _tempchartOfAaccList = [];
  List<ChofAccModel> get tempchartOfAaccList => _tempchartOfAaccList;

  Future chartsOfAccountsProvider(BuildContext context) async {
    _dataAccessParam = null;
    _chartOfAaccTypeList = [];
    _chartOfAaccList = [];
    _isLoading = true;
    //notifyListeners();
    _dataAccessParam = DataAccessParam(
      comCod: "2501",
      procName: "dbo.SP_MICR_REPORT_CODEBOOK_01",
      procID: "CHARTOFACCLIST01",
    );
    var encryptedADCData = CodeUtil.convertToBase64(_dataAccessParam!);
    ApiResponse apiResponse = await authRepo!.apiProcess(data1: encryptedADCData);
    _isLoading = false;

    if (apiResponse.response != null && (apiResponse.response!.statusCode == 200 || apiResponse.response!.statusCode == 201)) {
      _chartOfAaccTypeList = [];
      _chartOfAaccList = [];
      String decompressedJson = CodeUtil.decompress(apiResponse.response!.data.toString());

      var jsonAdc = jsonDecode(decompressedJson.toString());

      for (var element in jsonAdc['Table']) {
        _chartOfAaccTypeList.add(ChofAccTypeModel.fromJson(element));
      }
      for (var element in jsonAdc['Table1']) {
        _chartOfAaccList.add(ChofAccModel.fromJson(element));
      }
      _tempchartOfAaccList = chartOfAccList;

      // log(json);
    } else {
      if (!context.mounted) return;
      showCustomSnackBar('Failed to load data', context, isError: true);
    }
    notifyListeners();
  }

  //chart of accounts search
  bool isSearchofAccnt = false;
  searchChartofAccount(String query) {
    if (query.isEmpty) {
      _chartOfAaccList.clear();
      _chartOfAaccList = tempchartOfAaccList;
      isSearchofAccnt = false;

      notifyListeners();
    } else {
      _chartOfAaccList = [];
      isSearchofAccnt = true;
      for (var element in tempchartOfAaccList) {
        if (element.acctitle!.toLowerCase().contains(query.toLowerCase()) ||
            element.acctype!.toLowerCase().contains(query.toLowerCase())) {
          _chartOfAaccList.add(element);
        }
      }
    }
    notifyListeners();
  }

  searchBank(String query) {
    if (query.isEmpty) {
      _mainHeadbankList.clear();
      _mainHeadbankList = _tempBank;

      isSearchofAccnt = false;
      notifyListeners();
    } else {
      _mainHeadbankList = [];
      isSearchofAccnt = true;
      _tempBank.forEach(
        (element) async {
          if ((element.bankname!.toLowerCase().contains(query.toLowerCase())) ||
              (element.bankname!.toLowerCase().contains(query.toLowerCase()))) {
            _mainHeadbankList.add(element);
          }
        },
      );
      notifyListeners();
    }
  }

  int chIndex = -1;
  bool isMainchOAc = false;

  selectChOfAccnt({required int index}) {
    chIndex = index;
    if (chIndex == index) {
      isMainchOAc = !isMainchOAc;
      notifyListeners();
    }
  }

  List<BankInformation> banksubBranchList(String id) {
    var bankList = [];
    bankList = _allBankList
        .where((element) =>
            element.bankid!.substring(0, 3) == id.substring(0, 3) &&
            element.bankid!.endsWith('00') &&
            !element.bankid!.endsWith('000'))
        .toList();
    return [...bankList];
  }

  List<BankInformation> banksubBranchAccountsList(String id) {
    var bankList = [];
    bankList = _allBankList
        .where((element) => element.bankid!.substring(0, 6) == id.substring(0, 6) && !element.bankid!.endsWith('00'))
        .toList();
    return [...bankList];
  }

  List<ChofAccModel> chartOfaccList(
    String accType,
  ) {
    var bankList = [];

    bankList = chartOfAccList.where((element) => element.acctype!.trim() == accType.trim()).toList();

    return [...bankList];
  }

  List<ChofAccModel> cdetOfaccList(
    String id,
  ) {
    var bankList = [];

    bankList = chartOfAccList
        .where((element) =>
            element.accid!.substring(0, 3) == id && element.accid!.endsWith('000') && !element.accid!.endsWith('000000'))
        .toList();

    return [...bankList];
  }

  List<ChofAccModel> subchoAcList(
    String accID,
  ) {
    var bankList = [];

    bankList = chartOfAccList
        .where(
            (element) => element.accid!.substring(0, 5).trim() == accID.substring(0, 5).trim() && !element.accid!.endsWith('000'))
        .toList();

    return [...bankList];
  }
}
