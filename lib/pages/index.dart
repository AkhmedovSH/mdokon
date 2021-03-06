import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/globals.dart';

import '../components/drawer_app_bar.dart';

class Index extends StatefulWidget {
  const Index({Key? key}) : super(key: key);

  @override
  _IndexState createState() => _IndexState();
}

// class ProductWithParamsUnit {
//   final String packaging;
//   final String piece;
//   final double quantity;
//   final double totalPrice;
//   const ProductWithParamsUnit(this.packaging, this.piece, this.quantity, this.totalPrice);
// }

class _IndexState extends State<Index> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  dynamic shortcutController = TextEditingController();
  dynamic shortcutFocusNode = FocusNode();
  dynamic textController = TextEditingController();
  dynamic textController2 = TextEditingController();
  dynamic packagingController = TextEditingController();
  dynamic pieceController = TextEditingController();

  dynamic data = {
    "cashboxVersion": "",
    "login": "",
    "loyaltyBonus": 0,
    "loyaltyClientAmount": 0,
    "loyaltyClientName": "",
    "cashboxId": "",
    "change": 0,
    "chequeDate": 0,
    "chequeNumber": "",
    "clientAmount": 0,
    "clientComment": "",
    "clientId": 0,
    "currencyId": "",
    "currencyRate": 0,
    "discount": 0,
    "note": "",
    "offline": false,
    "outType": false,
    "paid": 0,
    "posId": "",
    "saleCurrencyId": "",
    "shiftId": '',
    "totalPriceBeforeDiscount": 0, // this is only for showing when sale
    "totalPrice": 0,
    "transactionId": "",
    "itemsList": [],
    "transactionsList": []
  };

  dynamic productWithParams = {
    "selectedUnit": {"name": "", "quantity": ""},
    "modificationList": [],
    'unitList': [],
  };

  dynamic productWithParamsUnit = {
    "packaging": "",
    "piece": "",
    "quantity": "0",
    "totalPrice": "0",
  };

  dynamic cashbox = {};
  dynamic clients = [];
  dynamic expenseOut = {
    "cashboxId": '',
    "posId": '',
    "shiftId": '',
    'note': '',
    'amountOut': '',
    'paymentPurposeId': '1',
  };
  dynamic debtIn = {
    "amountIn": 0,
    "cash": "",
    "terminal": "",
    "amountOut": 0,
    "cashboxId": '',
    "clientId": 0,
    "currencyId": 0,
    "posId": '',
    "shiftId": '',
    "transactionsList": []
  };
  dynamic itemList = [
    {
      'label': '????????????????',
      'icon': Icons.payments,
      'fieldName': 'cash',
    },
    {
      'label': '????????????????',
      'icon': Icons.payment,
      'fieldName': 'terminal',
    },
    {
      'label': '????????????????????',
      'fieldName': 'note',
    },
  ];
  dynamic shortCutList = ["+", "-", "*", "/", "%", "%-"];

  getClients() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final cashbox = jsonDecode(prefs.getString('cashbox')!);
    final response = await get('/services/desktop/api/client-debt-list/${cashbox['posId']}');
    //print(response);
    for (var i = 0; i < response.length; i++) {
      response[i]['selected'] = false;
    }
    setState(() {
      clients = response;
      debtIn['cashboxId'] = cashbox['cashboxId'];
      debtIn['posId'] = cashbox['posId'];
      if (prefs.getString('shift') != null) {
        debtIn['shiftId'] = jsonDecode(prefs.getString('shift')!)['id'];
      } else {
        debtIn['shiftId'] = cashbox['id'];
      }
    });
  }

  createDebtorOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final cashbox = jsonDecode(prefs.getString('cashbox')!);
    setState(() {
      expenseOut['cashboxId'] = cashbox['cashboxId'].toString();
      expenseOut['posId'] = cashbox['posId'].toString();
      expenseOut['currencyId'] = cashbox['defaultCurrency'].toString();
      if (prefs.getString('shift') != null) {
        expenseOut['shiftId'] = jsonDecode(prefs.getString('shift')!)['id'];
      } else {
        expenseOut['shiftId'] = cashbox['id'].toString();
      }
    });
    final response = await post('/services/desktop/api/expense-out', expenseOut);
    if (response['success']) {
      Navigator.pop(context);
    }
  }

  createClientDebt() async {
    dynamic debtInCopy = Map.from(debtIn);

    final list = [];
    if (debtInCopy['cash'].length > 0) {
      list.add({"amountIn": double.parse(debtInCopy['cash']), "amountOut": "", "paymentTypeId": 1, "paymentPurposeId": 5});
      debtInCopy['amountIn'] += double.parse(debtInCopy['cash']);
    }
    if (debtInCopy['terminal'].length > 0) {
      list.add({"amountIn": double.parse(debtInCopy['terminal']), "amountOut": "", "paymentTypeId": 2, "paymentPurposeId": 5});
      debtInCopy['amountIn'] += double.parse(debtInCopy['terminal']);
    }
    debtInCopy['transactionsList'] = list;

    await post('/services/desktop/api/client-debt-in', debtInCopy);
    setState(() {
      debtIn = {
        "cash": "",
        "terminal": "",
        "amountIn": 0,
        "amountOut": 0,
        "cashboxId": '',
        "clientId": 0,
        "currencyId": 0,
        "posId": '',
        "shiftId": '',
        "transactionsList": []
      };
    });
    Navigator.pop(context);
  }

  redirectToCalculator(i) async {
    final product = await Get.toNamed('/calculator', arguments: data["itemsList"][i]);
    //print('product${product}');
    if (product != null) {
      var arr = data["itemsList"];
      double totalPrice = 0;

      for (var i = 0; i < arr.length; i++) {
        if (arr[i]['productId'] == product['productId']) {
          arr[i]['totalPrice'] = double.parse(arr[i]['quantity'].toString()) * double.parse(arr[i]['salePrice'].toString());
          arr[i] = product;
        }
        totalPrice += double.parse(arr[i]['quantity'].toString()) * double.parse(arr[i]['salePrice'].toString());
      }

      setState(() {
        data["itemsList"] = arr;
        data["totalPrice"] = totalPrice;
      });
    }
  }

  redirectToSearch() async {
    if (data['discount'] > 0) {
      showDangerToast('???????? ?????????????????? ????????????');
      return;
    }
    final product = await Get.toNamed('/search');
    if (product != null) {
      product['discount'] = 0;
      product['wholesale'] = false;
      product['outType'] = false;

      if (product['unitList'].length > 0) {
        setState(() {
          productWithParams = product;
          productWithParams['quantity'] = "";
          productWithParams['totalPrice'] = "";
          productWithParams['selectedUnit'] = product['unitList'][0];
        });
        showProductsWithParams();
        return;
      }
      var existSameProduct = false;
      dynamic productsCopy = data["itemsList"];
      for (var i = 0; i < productsCopy.length; i++) {
        if (productsCopy[i]['productId'] == product['productId']) {
          existSameProduct = true;

          if (productsCopy[i]['quantity'] >= productsCopy[i]['balance'] && !cashbox['saleMinus']) {
            showDangerToast('???????????????? ??????????');
            return;
          }
          addToList(productsCopy[i]);
        }
      }

      if (!existSameProduct) {
        addToList(product);
      }
    }
  }

  addToList(response, {weight = 0, unit = false}) {
    dynamic dataCopy = data;
    dataCopy['totalPrice'] = 0;
    dynamic index = dataCopy['itemsList'].indexWhere((e) => e['balanceId'] == response['balanceId']);
    if (index == -1) {
      if (!response.containsKey('quantity')) {
        response['quantity'] = 1;
        if (weight != 0) {
          response['quantity'] = weight;
        }
      }
      response['selected'] = false;
      response['totalPrice'] = 0;
      dataCopy['itemsList'].add(response);

      for (var i = 0; i < dataCopy['itemsList'].length; i++) {
        dataCopy['itemsList'][i]['selected'] = false;
      }
      dataCopy['itemsList'][dataCopy['itemsList'].length - 1]['selected'] = true;

      for (var i = 0; i < dataCopy['itemsList'].length; i++) {
        if (dataCopy['itemsList'][i]['wholesale'] == true) {
          //
        } else {
          dataCopy['totalPrice'] +=
              double.parse(dataCopy['itemsList'][i]['salePrice'].toString()) * double.parse(dataCopy['itemsList'][i]['quantity'].toString());
          dataCopy['itemsList'][i]['totalPrice'] =
              double.parse(dataCopy['itemsList'][i]['salePrice'].toString()) * double.parse(dataCopy['itemsList'][i]['quantity'].toString());
        }
      }
    } else {
      if (response['quantity'] != "") {
        // if scaleProduct
        if (weight > 0) {
          dataCopy['itemsList'][index]['quantity'] =
              double.parse(dataCopy['itemsList'][index]['quantity'].toString()) + double.parse(weight.toString());
        } else if (unit) {
          // not needed
          // dataCopy['itemsList'][index]['quantity'] = response['quantity']
        } else {
          dataCopy['itemsList'][index]['quantity'] = double.parse(dataCopy['itemsList'][index]['quantity'].toString()) + 1;
        }
      } else {
        dataCopy['itemsList'][index]['quantity'] = response['quantity'];
      }

      for (var i = 0; i < dataCopy['itemsList'].length; i++) {
        if (dataCopy['itemsList'][i]['wholesale'] == true) {
          dataCopy['itemsList'][i]['wholesale'] = true;
          dataCopy['itemsList'][i]['salePrice'] = double.parse(dataCopy['itemsList'][i]['wholesalePrice'].toString());
          dataCopy['totalPrice'] +=
              double.parse(dataCopy['itemsList'][i]['wholesalePrice'].toString()) * double.parse(dataCopy['itemsList'][i]['quantity'].toString());
          dataCopy['itemsList'][i]['totalPrice'] =
              double.parse(dataCopy['itemsList'][i]['wholesalePrice'].toString()) * double.parse(dataCopy['itemsList'][i]['quantity'].toString());
        } else {
          dataCopy['itemsList'][i]['wholesale'] = false;
          dataCopy['totalPrice'] +=
              double.parse(dataCopy['itemsList'][i]['salePrice'].toString()) * double.parse(dataCopy['itemsList'][i]['quantity'].toString());
          dataCopy['itemsList'][i]['totalPrice'] =
              double.parse(dataCopy['itemsList'][i]['salePrice'].toString()) * double.parse(dataCopy['itemsList'][i]['quantity'].toString());
        }
      }
    }

    setState(() {
      data = dataCopy;
    });
    if (unit) {
      Navigator.pop(context);
    }
  }

  addToListUnit() {
    setState(() {
      productWithParams['quantity'] = productWithParamsUnit['quantity'];
    });
    addToList(productWithParams, unit: true);
  }

  deleteProduct(i) {
    if (data["itemsList"].length == 1) {
      deleteAllProducts();
      return;
    }
    double totalPrice = 0;
    dynamic productsCopy = data["itemsList"];
    productsCopy.removeAt(i);

    for (var i = 0; i < productsCopy.length; i++) {
      productsCopy[i]['totalPrice'] = productsCopy[i]['quantity'] * productsCopy[i]['salePrice'];
      totalPrice += productsCopy[i]['totalPrice'];
    }

    setState(() {
      data["itemsList"] = productsCopy;
      data['totalPrice'] = totalPrice;
    });
  }

  deleteAllProducts({type = false}) {
    setState(() {
      data = {
        "cashboxVersion": "",
        "login": "",
        "loyaltyBonus": 0,
        "loyaltyClientAmount": 0,
        "loyaltyClientName": "",
        "cashboxId": "",
        "change": 0,
        "chequeDate": 0,
        "chequeNumber": "",
        "clientAmount": 0,
        "clientComment": "",
        "clientId": 0,
        "currencyId": "",
        "currencyRate": 0,
        "discount": 0,
        "note": "",
        "offline": false,
        "outType": false,
        "paid": 0,
        "posId": "",
        "saleCurrencyId": "",
        "shiftId": '',
        "totalPriceBeforeDiscount": 0, // this is only for showing when sale
        "totalPrice": 0,
        "transactionId": "",
        "itemsList": [],
        "transactionsList": []
      };
    });
    if (type) {
      Navigator.pop(context);
    }
  }

  handleShortCut(type) {
    if (shortcutController.text.length == 0 && type != "/") return;
    dynamic productsCopy = data["itemsList"];
    var inputData = shortcutController.text;
    var isFloat = '.'.allMatches(inputData).isEmpty ? false : true;

    if (type == "+") {
      for (var i = 0; i < productsCopy.length; i++) {
        if (productsCopy[i]['selected']) {
          // ?????????????? ???????????? ???????????? ?????????????? ?????????????? ????????????
          if (isFloat && productsCopy[i]['uomId'] == 1) {
            showDangerToast('???????????????? ????????????????????');
            shortcutController.text = "";
            FocusManager.instance.primaryFocus?.unfocus();
            return;
          } else {
            if (!cashbox['saleMinus'] && (double.parse(inputData) > productsCopy[i]['balance'])) {
              showDangerToast('???????????????? ??????????');
              productsCopy[i]['quantity'] = productsCopy[i]['balance'];
              calculateTotalPrice(productsCopy);
              shortcutController.text = "";
              FocusManager.instance.primaryFocus?.unfocus();
            } else {
              shortcutController.text = "";
              FocusManager.instance.primaryFocus?.unfocus();
              productsCopy[i]['quantity'] = inputData;
              calculateTotalPrice(productsCopy);
            }
            break;
          }
        }
      }
    } else {
      shortcutController.text = "";
      FocusManager.instance.primaryFocus?.unfocus();
    }

    if (type == "*") {
      for (var i = 0; i < productsCopy.length; i++) {
        if (productsCopy[i]['selected']) {
          if (double.parse(inputData) < productsCopy[i]['price']) {
            showDangerToast('???????? ?????????????? ???? ?????????? ???????? ???????? ?????? ???????? ??????????????????????');
            shortcutController.text = "";
            FocusManager.instance.primaryFocus?.unfocus();
            break;
          } else {
            productsCopy[i]['salePrice'] = double.parse(inputData);
          }
          calculateTotalPrice(productsCopy);
          shortcutController.text = "";
          FocusManager.instance.primaryFocus?.unfocus();
          break;
        }
      }
    }

    if (type == "-") {
      for (var i = 0; i < productsCopy.length; i++) {
        if (productsCopy[i]['selected']) {
          if (productsCopy[i]['uomId'] == 1) {
            showDangerToast('???????????????? ????????????????????');
            shortcutController.text = "";
          } else {
            if (!cashbox['saleMinus'] && (double.parse(inputData) / productsCopy[i]['salePrice'] > productsCopy[i]['balance'])) {
              showDangerToast('???????????????? ??????????');
            } else if (!cashbox['saleMinus'] && (productsCopy[i]['balance'] > (double.parse(inputData) / productsCopy[i]['salePrice']))) {
              productsCopy[i]['quantity'] = double.parse(inputData) / productsCopy[i]['salePrice'];
            } else {
              productsCopy[i]['quantity'] = double.parse(inputData) / productsCopy[i]['salePrice'];
            }
          }
          calculateTotalPrice(productsCopy);
          shortcutController.text = "";
          FocusManager.instance.primaryFocus?.unfocus();
          break;
        }
      }
    }

    if (type == "/") {
      shortcutController.text = "";
      for (var i = 0; i < productsCopy.length; i++) {
        if (productsCopy[i]['selected'] && productsCopy[i]['unitList'].length > 0) {
          setState(() {
            productWithParams = productsCopy[i];
            productWithParams['quantity'] = "";
            productWithParams['totalPrice'] = "";
            productWithParams['selectedUnit'] = productsCopy[i]['unitList'][0];
          });
          showProductsWithParams();
          return;
        }
      }
    }

    if (type == "%") {
      calculateDiscount("%", inputData);
      shortcutController.text = "";
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }

    if (type == "%-") {
      calculateDiscount("%-", inputData);
      shortcutController.text = "";
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }

    setState(() {
      data["itemsList"] = productsCopy;
    });
  }

  calculateTotalPrice(productsCopy) {
    dynamic totalPrice = 0;
    for (var i = 0; i < productsCopy.length; i++) {
      productsCopy[i]['totalPrice'] = double.parse(productsCopy[i]['quantity'].toString()) * double.parse(productsCopy[i]['salePrice'].toString());
      totalPrice += productsCopy[i]['totalPrice'];
    }
    setState(() {
      data['totalPrice'] = totalPrice;
      data["itemsList"] = productsCopy;
    });
  }

  calculateDiscount(key, value) {
    value = double.parse(value);
    dynamic dataCopy = data;
    if (dataCopy['discount'] > 0) {
      dataCopy['discount'] = 0;
      dataCopy['totalPrice'] = double.parse(dataCopy['totalPriceBeforeDiscount'].toString());
      dataCopy['totalPriceBeforeDiscount'] = 0;
      for (var i = 0; i < dataCopy["itemsList"].length; i++) {
        dataCopy["itemsList"][i]['discount'] = 0;
        dataCopy["itemsList"][i]['totalPrice'] =
            double.parse(dataCopy["itemsList"][i]['salePrice'].toString()) * double.parse(dataCopy["itemsList"][i]['quantity'].toString());
      }
    }

    if (key == "%") {
      dataCopy['discount'] = value;
      dataCopy['totalPrice'] = 0;
      for (var i = 0; i < dataCopy['itemsList'].length; i++) {
        dataCopy['totalPrice'] +=
            double.parse(dataCopy['itemsList'][i]['salePrice'].toString()) * double.parse(dataCopy['itemsList'][i]['quantity'].toString());
        dataCopy['itemsList'][i]['discount'] = value;
        dataCopy['itemsList'][i]['totalPrice'] = dataCopy['itemsList'][i]['totalPrice'] - (dataCopy['itemsList'][i]['totalPrice'] * value) / 100;
      }
      dataCopy['totalPriceBeforeDiscount'] = dataCopy['totalPrice'];
      dataCopy['totalPrice'] = dataCopy['totalPrice'] - (dataCopy['totalPrice'] * value) / 100;
    }

    if (key == "%-") {
      dynamic percent = 100 / (dataCopy['totalPrice'] / value);
      dataCopy['discount'] = percent;
      dataCopy['totalPriceBeforeDiscount'] = dataCopy['totalPrice'];
      dataCopy['totalPrice'] = dataCopy['totalPriceBeforeDiscount'] - (dataCopy['totalPrice'] * percent) / 100;

      for (var i = 0; i < dataCopy['itemsList'].length; i++) {
        dataCopy['itemsList'][i]['discount'] = percent;
        dataCopy['itemsList'][i]['totalPrice'] = dataCopy['itemsList'][i]['totalPrice'] - ((dataCopy['itemsList'][i]['totalPrice'] * percent) / 100);
      }
    }
    print(dataCopy['itemsList']);
    setState(() {
      data = dataCopy;
    });
  }

  calculateProductWithParamsUnit(Function setDialogState) {
    //debugger();
    dynamic quantity = 0;
    dynamic totalPrice = 0;

    dynamic packaging = packagingController.text.length == 0 ? 0 : double.parse(packagingController.text);
    dynamic piece = pieceController.text.length == 0 ? 0 : double.parse(pieceController.text);

    dynamic salePrice = double.parse(productWithParams['salePrice'].toString());
    dynamic selectedUnitQuantity = double.parse(productWithParams['selectedUnit']['quantity'].toString());

    if (packaging == 0 && piece == 0) {
      setDialogState(() {
        productWithParamsUnit['packaging'] = "";
        productWithParamsUnit['piece'] = "";
        productWithParamsUnit['quantity'] = "0";
        productWithParamsUnit['totalPrice'] = "0";
      });
      return;
    }

    if (packaging > 0 && piece == 0) {
      quantity = packaging;
      totalPrice = salePrice * packaging;
      setDialogState(() {
        productWithParamsUnit['quantity'] = quantity.toString();
        productWithParamsUnit['totalPrice'] = totalPrice.toString();
      });
      return;
    }

    if (piece != 0 && piece > selectedUnitQuantity) {
      setDialogState(() {
        productWithParamsUnit['piece'] = "";
      });
      return;
    }

    if (packaging > 0 && piece > 0) {
      if (piece == selectedUnitQuantity) {
        quantity = packaging + 1;
        totalPrice = salePrice * packaging + 1;
        setDialogState(() {
          productWithParamsUnit['quantity'] = quantity.toString();
          productWithParamsUnit['totalPrice'] = totalPrice.toString();
        });
      } else {
        quantity = packaging + piece / selectedUnitQuantity;
        totalPrice = salePrice * quantity;
        setDialogState(() {
          productWithParamsUnit['quantity'] = quantity.toString();
          productWithParamsUnit['totalPrice'] = totalPrice.toString();
        });
      }
      return;
    }

    if (packaging == 0 && piece > 0) {
      quantity = piece / selectedUnitQuantity;
      totalPrice = salePrice * quantity;
      setDialogState(() {
        productWithParamsUnit['quantity'] = quantity.toString();
        productWithParamsUnit['totalPrice'] = totalPrice.toString();
      });
      return;
    }
  }

  selectProduct(index) {
    dynamic productsCopy = data["itemsList"];
    for (var i = 0; i < productsCopy.length; i++) {
      productsCopy[i]['selected'] = false;
    }
    productsCopy[index]['selected'] = true;
    setState(() {
      data["itemsList"] = productsCopy;
    });
  }

  getCashbox() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      cashbox = jsonDecode(prefs.getString('cashbox')!);
    });
  }

  selectDebtorClient(Function setDebtorState, index) {
    dynamic clientsCopy = clients;
    for (var i = 0; i < clientsCopy.length; i++) {
      clientsCopy[i]['selected'] = false;
    }
    clientsCopy[index]['selected'] = true;
    setDebtorState(() {
      clients = clientsCopy;
      debtIn['clientId'] = clientsCopy[index]['clientId'];
      debtIn['currencyId'] = clientsCopy[index]['currencyId'];
    });
  }

  @override
  void initState() {
    super.initState();
    getCashbox();
  }

  buildTextField(label, icon, item, index, setDialogState, {scrollPadding, enabled}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: b8),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          width: MediaQuery.of(context).size.width,
          child: TextFormField(
            keyboardType: index != 2 ? TextInputType.number : TextInputType.text,
            onChanged: (value) {
              setDialogState(() {
                debtIn[item['fieldName']] = value;
              });
            },
            scrollPadding: EdgeInsets.only(bottom: 100),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: blue,
                  width: 1,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: blue,
                  width: 1,
                ),
              ),
              suffixIcon: Icon(icon),
              filled: true,
              fillColor: borderColor,
              focusColor: blue,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light,
          statusBarColor: blue, // Status bar
        ),
        bottomOpacity: 0.0,
        title: Text(
          '??????????????',
          style: TextStyle(color: white),
        ),
        backgroundColor: blue,
        elevation: 0,
        // centerTitle: true,
        leading: IconButton(
          onPressed: () {
            _scaffoldKey.currentState!.openDrawer();
          },
          icon: Icon(Icons.menu, color: white),
        ),
        actions: [
          SizedBox(
            child: IconButton(
              onPressed: () {
                showModalDebtor();
              },
              icon: Icon(Icons.payment),
            ),
          ),
          SizedBox(
            child: IconButton(
              onPressed: () {
                showModalExpense();
              },
              icon: Icon(Icons.paid_outlined),
            ),
          ),
          SizedBox(
            child: IconButton(
              onPressed: () {
                if (data["itemsList"].length > 0) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('???? ???????????????'),
                      // content: const Text('AlertDialog description'),
                      actions: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.33,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(primary: red, padding: EdgeInsets.symmetric(vertical: 10)),
                                child: const Text('????????????'),
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.33,
                              child: ElevatedButton(
                                onPressed: () {
                                  deleteAllProducts(type: true);
                                },
                                style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 10)),
                                child: const Text('????????????????????'),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  );
                }
              },
              icon: Icon(Icons.delete),
            ),
          ),
        ],
      ),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.70,
        child: const DrawerAppBar(),
      ),
      body: data["itemsList"].length == 0
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'images/barcode-scanner.png',
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    '???????????????????????? ???????????????? ?? ???????????????? ???????????? \n?????? ?????????????? ?????? ??????????????.',
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (var i = 0; i < shortCutList.length; i++)
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              handleShortCut(shortCutList[i]);
                            },
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 3),
                              color: blue,
                              padding: EdgeInsets.all(5),
                              child: Text(
                                shortCutList[i],
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontSize: 20),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: TextField(
                            controller: shortcutController,
                            focusNode: shortcutFocusNode,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.all(10),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: borderColor),
                                borderRadius: const BorderRadius.all(Radius.circular(24)),
                              ),
                              hintText: '?????????????? ????????????????',
                              hintStyle: TextStyle(
                                color: lightGrey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('??????????', style: TextStyle(fontSize: 16)),
                      data['discount'] == 0
                          ? Text(formatMoney(data['totalPrice']) + ' ??????', style: TextStyle(fontSize: 16))
                          : Text(formatMoney(data['totalPriceBeforeDiscount']) + ' ??????', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('????????????', style: TextStyle(fontSize: 16)),
                      Wrap(
                        children: [
                          data['discount'] == 0
                              ? Text('(0%)', style: TextStyle(fontSize: 16))
                              : Text('(' + formatMoney(data['discount']) + '%)', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 10),
                          data['discount'] == 0
                              ? Text('0,00 ??????', style: TextStyle(fontSize: 16))
                              : Text(
                                  formatMoney(
                                          double.parse(data['totalPriceBeforeDiscount'].toString()) - double.parse(data['totalPrice'].toString())) +
                                      '??????',
                                  style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(height: 10),
                          Text('?? ????????????', style: TextStyle(fontSize: 16)),
                          Text(formatMoney(data['totalPrice']) + ' ??????', style: TextStyle(fontSize: 16)),
                        ],
                      )
                    ],
                  ),
                  for (var i = data["itemsList"].length - 1; i >= 0; i--)
                    Dismissible(
                      key: ValueKey(data["itemsList"][i]['productName']),
                      onDismissed: (DismissDirection direction) {
                        deleteProduct(i);
                      },
                      background: Container(
                        color: white,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(Icons.delete, color: red),
                      ),
                      direction: DismissDirection.endToStart,
                      child: GestureDetector(
                        onTap: () {
                          selectProduct(i);
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.only(bottom: 5),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: data["itemsList"][i]['selected'] ? Color(0xFF5b73e8) : Color(0xFFF5F3F5), width: 1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(i + 1).toString() + '. ' + data["itemsList"][i]['productName']}',
                                style: const TextStyle(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                softWrap: false,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 5),
                                      Text(
                                        '${formatMoney(data["itemsList"][i]['salePrice'])}x ${formatMoney(data["itemsList"][i]['quantity'])}',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${formatMoney(data["itemsList"][i]['totalPrice'])}So\'m',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: blue, fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                ],
              ),
            ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            margin: EdgeInsets.only(left: 32),
            child: ElevatedButton(
              onPressed: () {
                if (data["itemsList"].length > 0) {
                  Get.toNamed('/payment', arguments: data);
                }
              },
              style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32), primary: data["itemsList"].length > 0 ? blue : lightGrey),
              child: Text('??????????????'),
            ),
          ),
          FloatingActionButton(
            backgroundColor: data['discount'] == 0 ? blue : lightGrey,
            onPressed: () {
              redirectToSearch();
            },
            child: const Icon(Icons.add, size: 28),
          )
        ],
      ),
    );
  }

  showModalExpense() async {
    await showDialog(
        context: context,
        useSafeArea: true,
        builder: (BuildContext context) {
          List filter = [
            {"id": 1, "name": "??????????????"},
            {"id": 3, "name": "?????????????? ??????????????"},
            {"id": 4, "name": "????????"},
            {"id": 5, "name": "?????????????????? ?????????????????????????? "},
            {"id": 6, "name": "?????? ?????????????????????? ????????"},
            {"id": 7, "name": "?????? ???????? ???????????????? ??????????"},
            {"id": 8, "name": "????????????"},
          ];
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: Text(''),
              titlePadding: EdgeInsets.all(0),
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
              insetPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              actionsPadding: EdgeInsets.all(0),
              buttonPadding: EdgeInsets.all(0),
              scrollable: true,
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 15),
                      width: double.infinity,
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(width: 1.0, style: BorderStyle.solid, color: Color(0xFFECECEC)),
                          borderRadius: BorderRadius.all(Radius.circular(5.0)),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: ButtonTheme(
                          alignedDropdown: true,
                          child: DropdownButton(
                            value: expenseOut['paymentPurposeId'],
                            isExpanded: true,
                            hint: Text('${filter[0]['name']}'),
                            icon: const Icon(Icons.expand_more_outlined),
                            iconSize: 24,
                            iconEnabledColor: blue,
                            elevation: 16,
                            style: const TextStyle(color: Color(0xFF313131)),
                            underline: Container(
                              height: 2,
                              color: blue,
                            ),
                            onChanged: (newValue) {
                              setState(() {
                                expenseOut['paymentPurposeId'] = newValue;
                              });
                            },
                            items: filter.map((item) {
                              return DropdownMenuItem<String>(
                                value: '${item['id']}',
                                child: Text(item['name']),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '???????????????? (??????)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: b8),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      width: MediaQuery.of(context).size.width,
                      child: TextFormField(
                        onChanged: (value) {
                          setState(() {
                            expenseOut['amountOut'] = value;
                          });
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: blue,
                              width: 2,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: blue,
                              width: 2,
                            ),
                          ),
                          suffixIcon: Icon(Icons.payment),
                          filled: true,
                          fillColor: borderColor,
                          focusColor: blue,
                          hintText: '0 ??????',
                          hintStyle: TextStyle(color: a2),
                        ),
                      ),
                    ),
                    Text(
                      '????????????????????',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: b8),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      width: MediaQuery.of(context).size.width,
                      child: TextFormField(
                        onChanged: (value) {
                          setState(() {
                            expenseOut['note'] = value;
                          });
                        },
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: blue,
                              width: 2,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: blue,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: borderColor,
                          focusColor: blue,
                          hintText: '????????????????????',
                          hintStyle: TextStyle(color: a2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  margin: EdgeInsets.fromLTRB(10, 0, 10, 5),
                  child: ElevatedButton(
                    onPressed: () {
                      if (expenseOut['amountOut'].length != 0) {
                        createDebtorOut();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      primary: expenseOut['amountOut'].length == 0 ? lightGrey : blue,
                    ),
                    child: Text('??????????????'),
                  ),
                )
              ],
            );
          });
        });
  }

  showModalDebtor() async {
    await getClients();
    var closed = await showDialog(
        context: context,
        useSafeArea: true,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: Text(''),
              titlePadding: EdgeInsets.all(0),
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
              insetPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              actionsPadding: EdgeInsets.all(0),
              buttonPadding: EdgeInsets.all(0),
              scrollable: true,
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: [
                    // Container(
                    //   margin: const EdgeInsets.only(bottom: 10),
                    //   width: MediaQuery.of(context).size.width,
                    //   child: TextFormField(
                    //     onChanged: (value) {},
                    //     decoration: InputDecoration(
                    //       contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
                    //       enabledBorder: UnderlineInputBorder(
                    //         borderSide: BorderSide(
                    //           color: blue,
                    //           width: 2,
                    //         ),
                    //       ),
                    //       focusedBorder: UnderlineInputBorder(
                    //         borderSide: BorderSide(
                    //           color: blue,
                    //           width: 2,
                    //         ),
                    //       ),
                    //       filled: true,
                    //       fillColor: borderColor,
                    //       focusColor: blue,
                    //       hintText: '?????????? ???? ??????????????????',
                    //       hintStyle: TextStyle(color: a2),
                    //     ),
                    //   ),
                    // ),
                    // SizedBox(height: 5),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.2,
                        child: SingleChildScrollView(
                          child: Table(
                              border: TableBorder(horizontalInside: BorderSide(width: 1, color: Color(0xFFDADADa), style: BorderStyle.solid)),
                              children: [
                                TableRow(children: const [
                                  Text(
                                    '??????????????',
                                  ),
                                  Text(
                                    '????????????',
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    '?????????? ??????????',
                                    textAlign: TextAlign.end,
                                  ),
                                ]),
                                for (var i = 0; i < clients.length; i++)
                                  TableRow(children: [
                                    GestureDetector(
                                      onTap: () {
                                        selectDebtorClient(setState, i);
                                      },
                                      child: Container(
                                        padding: EdgeInsets.fromLTRB(5, 8, 0, 8),
                                        color: clients[i]['selected'] ? Color(0xFF91a0e7) : Colors.transparent,
                                        child: Text(
                                          '${clients[i]['clientName']}',
                                          style: TextStyle(
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        selectDebtorClient(setState, i);
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(vertical: 8),
                                        color: clients[i]['selected'] ? Color(0xFF91a0e7) : Colors.transparent,
                                        child: Text(
                                          clients[i]['currencyName'],
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        selectDebtorClient(setState, i);
                                      },
                                      child: Container(
                                        padding: EdgeInsets.fromLTRB(0, 8, 5, 8),
                                        color: clients[i]['selected'] ? Color(0xFF91a0e7) : Colors.transparent,
                                        child: Text(
                                          '${formatMoney(clients[i]['balance'])}',
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                    ),
                                  ]),
                              ]),
                        )),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: blue, width: 4))),
                      child: Text(
                        '????????????',
                        style: TextStyle(fontSize: 20, color: blue),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    for (var i = 0; i < itemList.length; i++)
                      buildTextField(
                        itemList[i]['label'],
                        itemList[i]['icon'],
                        itemList[i],
                        i,
                        setState,
                      ),
                  ],
                ),
              ),
              actions: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  margin: EdgeInsets.fromLTRB(10, 0, 10, 5),
                  child: ElevatedButton(
                    onPressed: () {
                      if (debtIn['cash'].length > 0 || debtIn['terminal'].length > 0) {
                        createClientDebt();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      primary: (debtIn['cash'].length > 0 || debtIn['terminal'].length > 0) ? blue : lightGrey,
                    ),
                    child: Text('??????????????'),
                  ),
                )
              ],
            );
          });
        });
    if (closed == null) {
      setState(() {
        debtIn = {
          "cash": "",
          "terminal": "",
          "amountIn": 0,
          "amountOut": 0,
          "cashboxId": '',
          "clientId": 0,
          "currencyId": 0,
          "posId": '',
          "shiftId": '',
          "transactionsList": []
        };
      });
    }
  }

  showProductsWithParams() async {
    var closed = await showDialog(
      context: context,
      useSafeArea: true,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(''),
            titlePadding: EdgeInsets.all(0),
            contentPadding: EdgeInsets.symmetric(horizontal: 10),
            insetPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            actionsPadding: EdgeInsets.all(0),
            buttonPadding: EdgeInsets.all(0),
            scrollable: true,
            content: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '?????? ????',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: b8),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    width: MediaQuery.of(context).size.width,
                    child: TextFormField(
                      controller: packagingController,
                      onChanged: (value) {
                        calculateProductWithParamsUnit(setState);
                      },
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: blue,
                            width: 2,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: blue,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: borderColor,
                        focusColor: blue,
                        hintText: '0',
                        hintStyle: TextStyle(color: a2),
                      ),
                    ),
                  ),
                  Text(
                    '???? ????????????????',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: b8),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    width: MediaQuery.of(context).size.width,
                    child: TextFormField(
                      controller: pieceController,
                      onChanged: (value) {
                        calculateProductWithParamsUnit(setState);
                      },
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: blue,
                            width: 2,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: blue,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: borderColor,
                        focusColor: blue,
                        hintText: '0',
                        hintStyle: TextStyle(color: a2),
                      ),
                    ),
                  ),
                  Text('????????????????????????: ${productWithParams['productName']}'),
                  Text('?? ????????????????: ${formatMoney(productWithParams['selectedUnit']['quantity'])}'),
                  Text('????????: ${formatMoney(productWithParams['salePrice'])}'),
                  Text('??????-????: ${formatMoney(productWithParamsUnit['quantity'])}'),
                  Text('?? ????????????: ${formatMoney(productWithParamsUnit['totalPrice'])}'),
                  SizedBox(height: 10),
                ],
              ),
            ),
            actions: [
              Container(
                width: MediaQuery.of(context).size.width,
                margin: EdgeInsets.fromLTRB(10, 0, 10, 5),
                child: ElevatedButton(
                  onPressed: () {
                    if (packagingController.text != "" || pieceController.text != "") {
                      addToListUnit();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    primary: (packagingController.text != "" || pieceController.text != "") ? blue : lightGrey,
                  ),
                  child: Text('??????????????'),
                ),
              )
            ],
          );
        });
      },
    );
    if (closed == null) {
      packagingController.text = "";
      pieceController.text = "";
      setState(() {
        productWithParamsUnit = {
          "quantity": "",
          "totalPrice": "",
        };
      });
    }
  }
}
