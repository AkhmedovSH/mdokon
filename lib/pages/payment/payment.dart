import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:kassa/helpers/globals.dart';

class Payment extends StatefulWidget {
  const Payment({Key? key, this.setPayload, this.data, this.setData}) : super(key: key);
  final Function? setPayload;
  final Function? setData;
  final dynamic data;

  @override
  _PaymentState createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  int currentIndex = 0;
  final _formKey = GlobalKey<FormState>();
  final cashController = TextEditingController();
  final terminalController = TextEditingController();
  dynamic products = Get.arguments;
  dynamic sendData = {};
  dynamic data = {};

  calculateChange() {
    widget.setData!(cashController.text, terminalController.text);
    dynamic change = 0;
    dynamic paid = 0;
    if (cashController.text.isNotEmpty) {
      paid += double.parse(cashController.text);
    }
    if (terminalController.text.isNotEmpty) {
      paid += double.parse(terminalController.text);
    }
    change = (paid - double.parse(data['totalPrice'].toString()));

    setState(() {
      data['change'] = change;
      data['paid'] = paid;
    });
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      data = widget.data;
      cashController.text = double.parse(data['text']).toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 20),
            child: Text('К ОПЛАТЕ', style: TextStyle(color: darkGrey, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Container(
              margin: EdgeInsets.only(bottom: 10),
              child: Text('${formatMoney(data['totalPrice'])} сум', style: TextStyle(color: darkGrey, fontSize: 16, fontWeight: FontWeight.bold))),
          Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(margin: EdgeInsets.only(bottom: 5), child: Text('Наличные', style: TextStyle(fontWeight: FontWeight.bold, color: grey))),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: TextFormField(
                      controller: cashController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Обязательное поле';
                        }
                      },
                      onChanged: (value) {
                        calculateChange();
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
                        suffixIcon: Icon(
                          Icons.payments_outlined,
                          size: 30,
                          color: Color(0xFF7b8190),
                        ),
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
                        hintText: '0.00 сум',
                        hintStyle: TextStyle(color: a2),
                      ),
                    ),
                  ),
                  Container(margin: EdgeInsets.only(bottom: 5), child: Text('Терминал', style: TextStyle(fontWeight: FontWeight.bold, color: grey))),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: TextFormField(
                      controller: terminalController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Обязательное поле';
                        }
                      },
                      onChanged: (value) {
                        calculateChange();
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
                        suffixIcon: Icon(
                          Icons.payment_outlined,
                          size: 30,
                          color: Color(0xFF7b8190),
                        ),
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
                        hintText: '0.00 сум',
                        hintStyle: TextStyle(color: a2),
                      ),
                    ),
                  ),
                ],
              )),
          Text('СДАЧА:', style: TextStyle(color: darkGrey, fontSize: 16, fontWeight: FontWeight.bold)),
          Container(
              margin: EdgeInsets.only(bottom: 10, top: 5),
              child: Text('${formatMoney(data['change'])} Сум', style: TextStyle(color: darkGrey, fontSize: 16, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
