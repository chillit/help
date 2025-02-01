import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:help/ranking.dart';

import 'login.dart';

class MarathonPrizePage extends StatefulWidget {
  @override
  _MarathonPrizePageState createState() => _MarathonPrizePageState();
}

class _MarathonPrizePageState extends State<MarathonPrizePage> {
  String? selectedPaymentMethod;
  User? user = FirebaseAuth.instance.currentUser;
  TextEditingController cardNumberController = TextEditingController();
  TextEditingController expiryDateController = TextEditingController();
  TextEditingController cvvController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  int prizeFund = 0;  // Store the prize fund value here

  @override
  void initState() {
    super.initState();
    _getPrizeFund();  // Fetch the prize fund on initial load
  }

  // Method to fetch the prize fund from the database
  Future<void> _getPrizeFund() async {
    DatabaseReference prizeFundRef = FirebaseDatabase.instance.ref('money');
    DataSnapshot snapshot = await prizeFundRef.get();

    if (snapshot.exists && snapshot.value is double) {
      setState(() {
        prizeFund = snapshot.value as int;  // Update the prize fund value
      });
    } else {
      print("No prize fund found or invalid data");
    }
  }
  void _showPaymentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateSheet) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildPaymentButton('Halyk', Icons.account_balance_wallet, setStateSheet, Colors.green),
                      _buildPaymentButton('Kaspi', Icons.credit_card, setStateSheet, Colors.red),
                      _buildPaymentButton('ApplePay', Icons.apple, setStateSheet, Colors.black),
                      _buildPaymentButton('GooglePay', Icons.android, setStateSheet, Colors.green),
                      _buildPaymentButton('SberBank', Icons.account_balance, setStateSheet, Colors.green),
                      _buildPaymentButton('Jusan', Icons.payment, setStateSheet, Colors.orange),
                      _buildPaymentButton('PayPal', Icons.paypal, setStateSheet, Colors.black),
                      _buildPaymentButton('Visa/MasterCard', Icons.credit_card, setStateSheet, Colors.red),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Donation Amount (\$)',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  if (selectedPaymentMethod == 'Visa/MasterCard') _buildCardPaymentFields(),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Validate Amount
                      String amountStr = amountController.text.trim();
                      if (amountStr.isEmpty) {
                        AwesomeDialog(
                          context: context,
                          dialogType: DialogType.error,
                          title: 'Amount Required',
                          desc: 'Please enter the donation amount.',
                          btnOkOnPress: () {},
                        ).show();
                        return;
                      }
                      double? amount = double.tryParse(amountStr);
                      if (amount == null || amount <= 0) {
                        AwesomeDialog(
                          context: context,
                          dialogType: DialogType.error,
                          title: 'Invalid Amount',
                          desc: 'Please enter a valid donation amount.',
                          btnOkOnPress: () {},
                        ).show();
                        return;
                      }

                      // Validate Payment Method
                      if (selectedPaymentMethod == null) {
                        AwesomeDialog(
                          context: context,
                          dialogType: DialogType.error,
                          title: 'Payment Method Required',
                          desc: 'Please select a payment method.',
                          btnOkOnPress: () {},
                        ).show();
                        return;
                      }

                      // Validate Card Details if Visa/MasterCard
                      if (selectedPaymentMethod == 'Visa/MasterCard') {
                        String cardNumber = cardNumberController.text.trim();
                        String expiry = expiryDateController.text.trim();
                        String cvv = cvvController.text.trim();
                        if (cardNumber.isEmpty || expiry.isEmpty || cvv.isEmpty) {
                          AwesomeDialog(
                            context: context,
                            dialogType: DialogType.error,
                            title: 'Card Details Required',
                            desc: 'Please fill in all card details.',
                            btnOkOnPress: () {},
                          ).show();
                          return;
                        }
                      }

                      Navigator.pop(context);
                      _showConfirmationDialog(amount);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Donate Now', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentButton(String label, IconData icon, StateSetter setStateSheet, Color clr) {
    return ElevatedButton.icon(
      onPressed: () {
        setStateSheet(() {
          selectedPaymentMethod = label;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: selectedPaymentMethod == label ? Colors.blue : clr,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildCardPaymentFields() {
    return Column(
      children: [
        TextField(
          controller: cardNumberController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Card Number',
            prefixIcon: Icon(Icons.credit_card),
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: expiryDateController,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  labelText: 'Expiry Date (MM/YY)',
                  prefixIcon: Icon(Icons.date_range),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: cvvController,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showConfirmationDialog(double amount) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.topSlide,
      title: 'Donation Successful 🎉',
      desc: 'Thank you for your contribution of \$${amount.toStringAsFixed(2)}! Your donation via $selectedPaymentMethod has been received.',
      btnOkOnPress: () async {
        // Get the current authenticated user's UID
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          // Handle case when the user is not logged in
          AwesomeDialog(
            context: context,
            dialogType: DialogType.error,
            title: 'User not logged in',
            desc: 'Please log in first.',
            btnOkOnPress: () {},
          ).show();
          return;
        }

        String userId = currentUser.uid;  // Get the UID of the current user

        // Update points in the Firebase Realtime Database
        DatabaseReference refe = FirebaseDatabase.instance.ref();
        DatabaseReference userRef = FirebaseDatabase.instance.ref('users/$userId');
        DatabaseReference moneyref = FirebaseDatabase.instance.ref('money');
        DataSnapshot monSnapshot = await moneyref.get();
        if(monSnapshot.exists){
          int moneyData = monSnapshot.value as int;
          int currentPoints = moneyData as int ?? 0;
          double update = currentPoints + amount;
          await refe.update({"money": update});
        }

        // Read the current points of the user
        DataSnapshot snapshot = await userRef.get();
        print(userId);

        if (snapshot.exists && snapshot.value is Map) {
          // Safely cast snapshot.value to a Map
          Map<dynamic, dynamic> userData = snapshot.value as Map<dynamic, dynamic>;

          // Get the current points value, defaulting to 0 if not present
          double currentPoints = userData['points'] ?? 0;
          double updatedPoints = currentPoints + amount;

          // Update the points in the database
          await userRef.update({'points': updatedPoints});

          // Optionally, you could show a confirmation message here if needed
          print("User's points updated to $updatedPoints");
        } else {
          // If user data does not exist or is not a Map, create the user with initial points
          await userRef.set({'points': amount});
          print("User data was created with points: $amount");
        }
      },
    ).show();
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Charity Run', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF072c2d),
        actions: [
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MarathonPrizePage())),
                child: Text('CHARITY', style: TextStyle(color: Colors.white)),
              ),
              SizedBox(width: 10),
              TextButton(
                onPressed: () {},
                child: Text('SIGN IN', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Total Prize Fund 💰',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              TweenAnimationBuilder(
                tween: IntTween(begin: 0, end: prizeFund),
                duration: Duration(seconds: 5),
                builder: (context, int value, child) {
                  return Text(
                    '\$${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              Image.asset("assets/prize.png", scale: 1.2),
              SizedBox(height: 16),
              Text(
                'Marathon is not only about running! 🏅',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed:(){
                  if (user == null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyHomePage()),
                    );
                  } else {
                    _showPaymentSheet();
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(40, 70),
                  backgroundColor: Colors.deepPurple,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Donate', style: TextStyle(fontSize: 36, color: Colors.white)),
              ),
              SizedBox(height: 8,),
              ElevatedButton(
                onPressed:(){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Ranking()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Ranking', style: TextStyle(fontSize: 22, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}