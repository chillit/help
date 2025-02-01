import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:help/prize.dart';
class Ranking extends StatefulWidget {
  @override
  _RankingState createState() => _RankingState();
}

class _RankingState extends State<Ranking> {
  DatabaseReference _userRef = FirebaseDatabase.instance.ref().child('users');
  List<Map<dynamic, dynamic>> _users = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  String currentUserUID = "";
  String currentUsername = "";
  late DatabaseReference _databaseReference ;
  int rankNumber = -1;

  bool _isLoading = true;
  late User user;




  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchUsers();
    _getUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      currentUserUID = user.uid;
      final nameRef = _database.ref().child('users/$currentUserUID/Username');
      DatabaseEvent nameSnapshot = await nameRef.once();

      setState(() {
        currentUsername = nameSnapshot.snapshot.value?.toString() ?? '';
      });
    }
  }



  void _fetchUsers() {
    _userRef.orderByChild('points').once().then((DatabaseEvent snapshot) {
      if (snapshot.snapshot.value != null && snapshot.snapshot.value is Map) {
        Map<dynamic, dynamic> values = snapshot.snapshot.value as Map<dynamic, dynamic>;

        List<Map<dynamic, dynamic>> tempUsers = []; // Temporary list to store users
        values.forEach((key, value) {
          if (value != null && value['name'] != null && value['points'] != null) {
            tempUsers.add(value);
          }
        });

        tempUsers.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));

        setState(() {
          _users = tempUsers;
          _isLoading = false; // Stop loading indicator
        });
      } else {
        setState(() {
          _isLoading = false; // Stop loading even if no users found
        });
      }
    }).catchError((error) {
      print("Error fetching users: $error");
    });
  }

  Color my = Colors.brown, CheckMyColor = Colors.white;


  int userPoints = 0;


  Future<void> _getUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        _databaseReference = FirebaseDatabase.instance.ref().child('users/${user.uid}');
        final dataSnapshot = await _databaseReference.once();
        final Map<dynamic, dynamic> data = dataSnapshot.snapshot.value as Map<dynamic, dynamic>;
        print(data);

        setState(() {
          userPoints = data['points'];
        });
      }
    } catch (error) {
      print('Error: $error');
    }
  }


  _titleText(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
    );
  }

  String getOrdinalSuffix(int number) {
    if (number % 100 >= 11 && number % 100 <= 13) {
      return '$number' + 'th';
    } else {
      switch (number % 10) {
        case 1:
          return '$number' + 'st';
        case 2:
          return '$number' + 'nd';
        case 3:
          return '$number' + 'rd';
        default:
          return '$number' + 'th';
      }
    }
  }



  @override

  Widget build(BuildContext context) {

    String pointsProfile = userPoints != null ? getOrdinalSuffix(userPoints) : '';
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
      body: _isLoading?
      Center(child: CircularProgressIndicator(),):
      Stack(
        children: <Widget>[
          Scaffold(
              body: Container(
                margin: EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Leaderboard",style: TextStyle(fontFamily: 'Feather',fontSize: 17),),

                      ],
                    ),
                    Container(
                      margin: EdgeInsets.only( top: 10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[

                              Expanded(
                                child: Text("$pointsProfile",style: TextStyle(fontFamily: 'Feather', fontSize: 25),
                                  textAlign: TextAlign.center,),
                              ),

                              Center(
                                child: ClipOval(
                                  child: Image.asset(
                                    userPoints>=1000000?"assets/images/ranks/r.png":userPoints>=500000?"assets/images/ranks/i.png":userPoints>=100000?"assets/images/ranks/a.png":userPoints>=50000?"assets/images/ranks/d.png":userPoints>=10000?"assets/images/ranks/p.png":userPoints>=5000?"assets/images/ranks/g.png":userPoints>=2000?"assets/images/ranks/s.png":userPoints>=500?"assets/images/ranks/b.png":"assets/images/ranks/ir.png",
                                    height: 120,
                                  ),
                                ),
                              ),

                              Expanded(
                                child: Text(
                                  "$userPoints pts",
                                  style: TextStyle(fontFamily: 'Feather', fontSize: 20),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            ],
                          ),
                          Divider(color: Colors.grey.shade500),
                        ],
                      ),
                    ),
                    SizedBox(height: 15,),
                    Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8, // 80% width of screen
                        height: 400, // Fixed height
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300, // Gray background
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                itemCount: _users.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final userName = _users[index]['name'] ?? 'Unknown';
                                  final userPoints = _users[index]['points'] ?? 0;
                                  final rankNumber = index + 1;
                                  final isCurrentUser = userName == currentUsername;

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isCurrentUser ? Colors.green.withOpacity(0.2) : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    margin: EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blueGrey,
                                        child: Image.asset(
                                          userPoints>=1000000?"assets/images/ranks/r.png":userPoints>=500000?"assets/images/ranks/i.png":userPoints>=100000?"assets/images/ranks/a.png":userPoints>=50000?"assets/images/ranks/d.png":userPoints>=10000?"assets/images/ranks/p.png":userPoints>=5000?"assets/images/ranks/g.png":userPoints>=2000?"assets/images/ranks/s.png":userPoints>=500?"assets/images/ranks/b.png":"assets/images/ranks/ir.png",
                                        ),
                                      ),
                                      title: Text(
                                        userName,
                                        style: TextStyle(
                                          color: isCurrentUser ? Colors.green : Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      trailing: Text(
                                        '$userPoints pts',
                                        style: TextStyle(fontSize: 14, color: Colors.black54),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}