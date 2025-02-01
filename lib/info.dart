import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:help/participantReg.dart';
import 'package:help/path.dart';
import 'package:help/prize.dart';

import 'login.dart';

class CharityRunsPage extends StatelessWidget {
  final DatabaseReference _databaseRef =
  FirebaseDatabase.instance.ref().child('participants');
  void _showParticipantsDialog(BuildContext context) async {
    List<Map<String, String>> participants = [];

    // Fetch participants data
    DataSnapshot snapshot = await _databaseRef.get();
    if (snapshot.exists && snapshot.value is Map) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        participants.add({
          'name': value['name'] ?? 'Unknown',
          'gender': value['gender'] ?? 'Not specified',
        });
      });
    }

    // Show Dialog with Participants
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Participants'),
          content: participants.isEmpty
              ? Text('No participants found.')
              : SizedBox(
            width: 450,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: participants.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(participants[index]['name']!),
                  subtitle: Text('Gender: ${participants[index]['gender']}'),
                  leading: Icon(
                    participants[index]['gender'] == 'Male'
                        ? Icons.male
                        : Icons.female,
                    color: participants[index]['gender'] == 'Male'
                        ? Colors.blue
                        : Colors.pink,
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  User? user = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Charity Run', style: TextStyle(color: Colors.white),),
        backgroundColor: Color(0xFF072c2d),
        actions: [
          Row(
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MarathonPrizePage()),
                  );
                },
                child: Text('CHARITY', style: TextStyle(color: Colors.white)),
              ),
              SizedBox(width: 10,),
              TextButton(
                onPressed: () async{
                  if (user == null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyHomePage()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyHomePage()),
                    );
                    await FirebaseAuth.instance.signOut();
                  }
                },
                child: Text(user == null?"SIGN IN":'EXIT', style: TextStyle(color: Colors.white)),
              ),
            ],
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.asset(
                  'assets/marathon.png', // Ensure you have this image in your assets
                  width: double.infinity,
                  height: 400,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  left: 100,
                  bottom: 50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        color: Colors.white,
                        child: Text('RUN FOR CHARITY',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[900])),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'NIS 10-Year Charity Marathon',
                        style: TextStyle(
                          fontSize: 48, // Adjusted for better fit
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Celebrating 10 years of NIS in Petropavlovsk, Kazakhstan - 2025',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(95, 16, 95, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF072c2d),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHARITY RUNS IN PETROPAVLOVSK',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Join us in celebrating 10 years of NIS! Run for charity and support education in Petropavlovsk, Kazakhstan.',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'EVENT CATEGORIES',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Wrap(
                          spacing: 10,
                          children: [
                            _buildCategoryChip('5K FUN RUN'),
                            _buildCategoryChip('10K CHARITY RUN'),
                            _buildCategoryChip('HALF MARATHON'),
                            _buildCategoryChip('FULL MARATHON'),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text(
                          'EVENT LOCATIONS',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildLocationChip('PETROPAVLOVSK CITY CENTER'),
                            _buildLocationChip('NIS SCHOOL GROUNDS'),
                            _buildLocationChip('ISHYM RIVER PARK'),
                            _buildLocationChip('NORTH KAZAKHSTAN REGION'),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => MapScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                              child: Text('MAP VIEW', style: TextStyle(color: Colors.white),),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                User? user = FirebaseAuth.instance.currentUser;
                                if (user == null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => MyHomePage()),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => RegistrationPage()),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                              child: Text('REGISTER NOW',style: TextStyle(color: Colors.white),),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                _showParticipantsDialog(context);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                              child: Text('PARTICIPANTS',style: TextStyle(color: Colors.white),),
                            ),
                            SizedBox(width: 10),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    return Chip(
      label: Text(label, style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.blue,
    );
  }

  Widget _buildLocationChip(String label) {
    return Chip(
      label: Text(label, style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.green,
    );
  }
}