import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/globals.dart';
import 'package:kassa/helpers/controller.dart';
import 'package:kassa/components/loading_layout.dart';

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final Controller controller = Get.put(Controller());
  Timer? _debounce;
  dynamic products = [];
  dynamic cashbox = {};

  @override
  void initState() {
    super.initState();
    //getProducts();
    getCashbox();
  }

  searchProducts(value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final response =
          await get('/services/desktop/api/get-balance-product-list-mobile/${cashbox['posId']}/${cashbox['defaultCurrency']}?search=$value');
      if (response != null && response.length > 0) {
        setState(() {
          products = response;
        });
      }
    });
  }

  getProducts() async {
    controller.showLoading();
    setState(() {});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final cashbox = jsonDecode(prefs.getString('cashbox')!);
    final response = await get('/services/desktop/api/get-balance-product-list/${cashbox['posId']}/${cashbox['defaultCurrency']}');
    controller.hideLoading();
    if (response != null && response.length > 0) {
      setState(() {
        products = response;
      });
    }
  }

  getCashbox() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      cashbox = jsonDecode(prefs.getString('cashbox')!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LoadingLayout(
      body: Scaffold(
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.dark,
            statusBarColor: white,
          ),
          title: Text(
            '?????????????? ??????????????',
            style: TextStyle(color: black),
          ),
          backgroundColor: white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
              onPressed: () {
                Get.back();
              },
              icon: Icon(Icons.arrow_back_ios, color: black)),
        ),
        body: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 6,
                          child: SizedBox(
                            height: 35,
                            child: TextField(
                              onChanged: (value) {
                                searchProducts(value);
                              },
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.all(2),
                                isDense: true,
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: grey,
                                  size: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: borderColor),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(24),
                                  ),
                                ),
                                hintText: '?????????? ???? ????????????????, QR code ...',
                                hintStyle: TextStyle(
                                  color: lightGrey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: 35,
                          width: 35,
                          margin: EdgeInsets.only(left: 15),
                          decoration: BoxDecoration(border: Border.all(width: 1, color: blue), borderRadius: BorderRadius.all(Radius.circular(50))),
                          child: Icon(
                            Icons.qr_code_2_outlined,
                            color: blue,
                            size: 18,
                          ),
                        )
                      ],
                    ),
                  ),
                  for (var i = 0; i < products.length; i++)
                    GestureDetector(
                      onTap: () {
                        products[i]['selected'] = false;
                        Get.back(result: products[i]);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: white,
                          border: Border.all(color: borderColor),
                          borderRadius: const BorderRadius.all(Radius.circular(5)),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black,
                              spreadRadius: -6,
                              blurRadius: 5,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${products[i]['productName']}',
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      'Ostatok: ${formatMoney(products[i]['balance']) ?? 0}',
                                      style: TextStyle(color: lightGrey),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  child: Text(
                                    '${formatMoney(products[i]['salePrice']) ?? 0} So\'m',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: blue, fontSize: 16),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                ],
              ),
            )),
      ),
    );
  }
}
