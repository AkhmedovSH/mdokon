import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kassa/components/drawer_app_bar.dart';
import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/globals.dart';

class XReport extends StatefulWidget {
  const XReport({Key? key}) : super(key: key);

  @override
  _XReportState createState() => _XReportState();
}

class _XReportState extends State<XReport> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  dynamic report = {};
  dynamic reportList = [];

  getReport() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final cashbox = jsonDecode(prefs.getString('cashbox')!);
    int cashboxId = 0;
    if (cashbox['id'] != null) {
      cashboxId = cashbox['id'];
    } else {
      final shift = jsonDecode(prefs.getString('shift')!);
      cashboxId = shift['id'];
    }
    dynamic response =
        await get('/services/desktop/api/shift-xreport/$cashboxId');

    print(response);

    setState(() {
      report = response;
      reportList = report['xReportList'];
      report['shiftNumber'] = formatUnixTime(report['shiftNumber']);
    });
  }

  @override
  void initState() {
    super.initState();
    getReport();
  }

  buildRow(text, text2, {fz = 16.0}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style:
              TextStyle(fontWeight: FontWeight.w600, color: b8, fontSize: fz),
        ),
        Text(
          '$text2',
          style: TextStyle(color: b8, fontSize: fz),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.dark,
          statusBarColor: white, // Status bar
        ),
        bottomOpacity: 0.0,
        backgroundColor: white,
        elevation: 0,
        // centerTitle: true,
        leading: IconButton(
          onPressed: () {
            _scaffoldKey.currentState!.openDrawer();
          },
          icon: Icon(Icons.menu, color: black,),
        ),
      ),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.70,
        child: const DrawerAppBar(),
      ),
        body: SafeArea(
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Center(
                  child: Image.asset(
                'images/logo.jpg',
                height: 64,
                width: 200,
              )),
              Container(
                alignment: Alignment.center,
                margin: EdgeInsets.only(bottom: 10),
                child: Text(
                  'ДУБЛИКАТ',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: b8, fontSize: 18),
                ),
              ),
              Container(
                alignment: Alignment.center,
                margin: EdgeInsets.only(bottom: 10),
                child: Text(
                  '${report['posName']}',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: b8, fontSize: 16),
                ),
              ),
              Container(
                alignment: Alignment.center,
                margin: EdgeInsets.only(bottom: 10),
                child: Text(
                  'Телефон: 998977655885',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: b8, fontSize: 16),
                ),
              ),
              Container(
                alignment: Alignment.center,
                margin: EdgeInsets.only(bottom: 10),
                child: Text(
                  'Адресс: Glinka',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: b8, fontSize: 16),
                ),
              ),
              buildRow('Кассир', report['cashierName']),
              buildRow('Касса №', report['shiftNumber']),
              buildRow('ИНН', report['tin']),
              buildRow('Дата', report['shiftOpenDate']),
              Container(
                margin: EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  '*****************************************************************************************',
                  style: TextStyle(color: b8),
                  overflow: TextOverflow.clip,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
              Table(columnWidths: const {
                0: FlexColumnWidth(5),
                1: FlexColumnWidth(3),
                2: FlexColumnWidth(3),
              }, children: [
                TableRow(children: [
                  Container(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('№ Товар',
                        style:
                            TextStyle(fontWeight: FontWeight.bold, color: b8)),
                  ),
                  Container(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Кол-во',
                        style:
                            TextStyle(fontWeight: FontWeight.bold, color: b8)),
                  ),
                  Container(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Цена',
                        textAlign: TextAlign.end,
                        style:
                            TextStyle(fontWeight: FontWeight.bold, color: b8)),
                  ),
                ]),
                for (var i = 0; i < reportList.length; i++)
                  TableRow(children: [
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${i + 1} ${reportList[i]['productName']}',
                        style: TextStyle(color: b8),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${reportList[i]['quantity']} * ${reportList[i]['salePrice']}',
                        style: TextStyle(color: b8),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${reportList[i]['totalPrice']}',
                        textAlign: TextAlign.end,
                        style: TextStyle(color: b8),
                      ),
                    ),
                  ])
              ]),
              Container(
                margin: EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  '*****************************************************************************************',
                  style: TextStyle(color: b8),
                  overflow: TextOverflow.clip,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
              buildRow('Продано в долг', report['debt']),
              buildRow('Сумма скидки', report['discountAmount']),
              Container(
                margin: EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  '*****************************************************************************************',
                  style: TextStyle(color: b8),
                  overflow: TextOverflow.clip,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
              buildRow('Остаток в кассе', report['cashboxTotalAmount']),
              Container(
                margin: EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  '*****************************************************************************************',
                  style: TextStyle(color: b8),
                  overflow: TextOverflow.clip,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
              buildRow('КОЛИЧЕСТВО Х ОТЧЕТОВ', report['countRequest']),
            ],
          ),
        ),
      ),
    ));
  }
}
