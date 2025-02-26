import 'dart:convert';
import 'dart:typed_data';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'info.dart';
import 'package:universal_html/html.dart' as html;

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  String? selectedPaymentMethod;
  TextEditingController cardNumberController = TextEditingController();
  TextEditingController expiryDateController = TextEditingController();
  TextEditingController cvvController = TextEditingController();

  Future<String> sendMessage(
      String date, String gender, String description, String type) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
          'Bearer sk-2ruHUfuexrGGvI3JkS6GBXpPQacBoG7CjgINSwuUZVT3BlbkFJBl8zXKJcR-TTVQg72cf3UNDg_E_YwZLgqefgJfr1UA',
        },
        body: json.encode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content':
              'Hello, you are an assistant for a charity marathon NIS 2025. I will provide you with information about a participant. Can you give them some advice in plain text with a numbered order? Date of birth: $date, Gender: $gender, Description: $description, and they participate in $type marathon. You can also say that participant should not praticipate.Write in brackets "Weather in daytime is -7". Also do not use extra signs and emojis and bold text'
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to get response');
      }
    } catch (error) {
      return 'Error fetching advice';
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
                  Text(
                    'Payment Method(5000₸)',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildPaymentButton(
                          'Halyk', Icons.account_balance_wallet, setStateSheet, Colors.green),
                      _buildPaymentButton(
                          'Kaspi', Icons.credit_card, setStateSheet, Colors.red),
                      _buildPaymentButton(
                          'ApplePay', Icons.apple, setStateSheet, Colors.black),
                      _buildPaymentButton(
                          'GooglePay', Icons.android, setStateSheet, Colors.green),
                      _buildPaymentButton(
                          'SberBank', Icons.account_balance, setStateSheet, Colors.green),
                      _buildPaymentButton(
                          'Jusan', Icons.payment, setStateSheet, Colors.orange),
                      _buildPaymentButton(
                          'PayPal', Icons.paypal, setStateSheet, Colors.black),
                      _buildPaymentButton(
                          'Visa/MasterCard', Icons.credit_card, setStateSheet, Colors.red),
                    ],
                  ),
                  SizedBox(height: 10),
                  if (selectedPaymentMethod == 'Visa/MasterCard')
                    _buildCardPaymentFields(),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Validate Amount
                      String amountStr = "5000";
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
                      padding:
                      EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'Donate Now',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentButton(
      String label, IconData icon, StateSetter setStateSheet, Color clr) {
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
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(
        label,
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
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
            labelStyle: TextStyle(fontSize: 18),
            prefixIcon: Icon(Icons.credit_card, size: 18),
            border: OutlineInputBorder(),
          ),
          style: TextStyle(fontSize: 18),
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
                  labelStyle: TextStyle(fontSize: 18),
                  prefixIcon: Icon(Icons.date_range, size: 18),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(fontSize: 18),
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
                  labelStyle: TextStyle(fontSize: 18),
                  prefixIcon: Icon(Icons.lock, size: 18),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(fontSize: 18),
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
      desc:
      'Thank you for your contribution of \$${amount.toStringAsFixed(2)}! Your donation via $selectedPaymentMethod has been received.',
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      descTextStyle: TextStyle(fontSize: 18),
      btnOkOnPress: () async {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.error,
            title: 'User not logged in',
            desc: 'Please log in first.',
            btnOkOnPress: () {},
            titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            descTextStyle: TextStyle(fontSize: 18),
          ).show();
          return;
        }

        String userId = currentUser.uid;

        // Update points and total money
        DatabaseReference refe = FirebaseDatabase.instance.ref();
        DatabaseReference userRef = FirebaseDatabase.instance.ref('users/$userId');
        DatabaseReference moneyref = FirebaseDatabase.instance.ref('money');

        // Update total money
        DataSnapshot monSnapshot = await moneyref.get();
        if (monSnapshot.exists) {
          int moneyData = monSnapshot.value as int;
          int currentPoints = moneyData;
          double update = currentPoints + amount;
          await refe.update({"money": update});
        }

        // Update user points
        DataSnapshot snapshot = await userRef.get();
        if (snapshot.exists && snapshot.value is Map) {
          Map<dynamic, dynamic> userData = snapshot.value as Map<dynamic, dynamic>;
          double currentPoints = userData['points'] ?? 0;
          double updatedPoints = currentPoints + amount;
          await userRef.update({'points': updatedPoints});
        } else {
          await userRef.set({'points': amount});
        }

        // Save participant data to 'participants' node
        DatabaseReference participantsRef =
        FirebaseDatabase.instance.ref('participants/$userId');
        await participantsRef.set({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'dateOfBirth': _dateController.text,
          'gender': _selectedGender,
          'description': _descriptionController.text,
          'paymentMethod': selectedPaymentMethod,
          'amount': amount,
          'timestamp': ServerValue.timestamp,
        });
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CharityRunsPage()),
        );
      },
    ).show();
    _generateAndDownloadReceipt(5000);
  }

  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedType;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _generateAndDownloadReceipt(double amount) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('Donation Receipt',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text('Date: ${now.toLocal()}',
                    style: pw.TextStyle(fontSize: 18)),
                pw.Text('Amount Donated: \₸${amount.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 18)),
                pw.Text('Payment Method: $selectedPaymentMethod',
                    style: pw.TextStyle(fontSize: 18)),
                pw.SizedBox(height: 20),
                pw.Text('Thank you for your generous contribution!',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 18)),
              ],
            ),
          );
        },
      ),
    );

    try {
      final Uint8List pdfBytes = await pdf.save();

      // Create a downloadable file in the browser
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "receipt.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);

      print("Receipt downloaded successfully!");
    } catch (e) {
      print("Failed to generate receipt: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Registration for NIS 2025 Marathon",
          style: TextStyle(fontSize: 18),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Name *',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(fontSize: 18),
                        validator: (value) =>
                        value?.isEmpty ?? true ? 'Required field' : null,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Mobile Phone *',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFamily: "Helvetica",
                            fontSize: 18),
                      ),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(fontSize: 18),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) =>
                        value?.isEmpty ?? true ? 'Required field' : null,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Marathon Type *',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFamily: "Helvetica",
                            fontSize: 18),
                      ),
                      Row(
                        children: [
                          Radio<String>(
                            value: '5k',
                            groupValue: _selectedGender,
                            onChanged: (value) =>
                                setState(() => _selectedGender = value),
                          ),
                          const Text(
                            '5K Marathon',
                            style: TextStyle(
                                fontFamily: "Helvetica", fontSize: 18),
                          ),
                          const SizedBox(width: 20),
                          Radio<String>(
                            value: '10K',
                            groupValue: _selectedType,
                            onChanged: (value) =>
                                setState(() => _selectedType = value),
                          ),
                          const Text(
                            '10K Marathon',
                            style: TextStyle(
                                fontFamily: "Helvetica", fontSize: 18),
                          ),
                          const SizedBox(width: 20),
                          Radio<String>(
                            value: 'Half',
                            groupValue: _selectedType,
                            onChanged: (value) =>
                                setState(() => _selectedType = value),
                          ),
                          const Text(
                            'Half Marathon',
                            style: TextStyle(
                                fontFamily: "Helvetica", fontSize: 18),
                          ),
                          const SizedBox(width: 20),
                          Radio<String>(
                            value: 'Full',
                            groupValue: _selectedType,
                            onChanged: (value) =>
                                setState(() => _selectedType = value),
                          ),
                          const Text(
                            'Full Marathon',
                            style: TextStyle(
                                fontFamily: "Helvetica", fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Date of Birth *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: IgnorePointer(
                          child: TextFormField(
                            controller: _dateController,
                            decoration:
                            const InputDecoration(hintText: 'dd/mm/yyyy'),
                            style: TextStyle(fontSize: 18),
                            validator: (value) =>
                            value?.isEmpty ?? true ? 'Required field' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Gender *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'Male',
                            groupValue: _selectedGender,
                            onChanged: (value) =>
                                setState(() => _selectedGender = value),
                          ),
                          const Text(
                            'Male',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 20),
                          Radio<String>(
                            value: 'Female',
                            groupValue: _selectedGender,
                            onChanged: (value) =>
                                setState(() => _selectedGender = value),
                          ),
                          const Text(
                            'Female',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Description *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      TextFormField(
                        controller: _descriptionController,
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            final advice = await sendMessage(
                              _dateController.text,
                              _selectedGender ?? 'Not specified',
                              _descriptionController.text,
                              _selectedType ?? "full",
                            );
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text(
                                  'Advices',
                                  style: TextStyle(fontSize: 18),
                                ),
                                content: Text(
                                  advice,
                                  style: TextStyle(fontSize: 18),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      'OK',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Get Advice',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 600,
              child: _buildSummarySection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Card(
      color: Colors.blue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 40,
            ),
            const Text(
              "1 February",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              "NIS MARATHON CUP 2025",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            const SizedBox(
              height: 12,
            ),
            const Divider(color: Colors.white),
            const SizedBox(
              height: 12,
            ),
            const Text(
              "Стартовый взнос: 5000₸",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              "Скидка по промокоду: 5000₸",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              "Благотворительный взнос: 5000₸",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(
              height: 12,
            ),
            const Divider(color: Colors.white),
            const SizedBox(
              height: 12,
            ),
            const Text(
              "Общая сумма: 5000₸",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            const SizedBox(
              height: 22,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                bool isFormValid = _formKey.currentState?.validate() ?? false;
                bool isGenderSelected = _selectedGender != null;
                if (isFormValid && isGenderSelected) {
                  _showPaymentSheet();
                } else {
                  String errorMessage = '';
                  if (!isFormValid)
                    errorMessage += 'Please fill in all required fields.\n';
                  if (!isGenderSelected)
                    errorMessage += 'Please select your gender.\n';
                  AwesomeDialog(
                    context: context,
                    dialogType: DialogType.error,
                    title: 'Form Incomplete',
                    desc: errorMessage,
                    btnOkOnPress: () {},
                    titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    descTextStyle: TextStyle(fontSize: 18),
                  ).show();
                }
              },
              child: const Center(
                child: Text(
                  "Перейти к оплате",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
