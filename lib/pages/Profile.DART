import 'package:flutter/material.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  final String name = "Deepanshu Singh";
  final String number = "+91 9721885405";
  final String mail = "ceo@mail.com";
  final String position = "CEO";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
    appBar: AppBar(
      centerTitle: true,
      title: Text("Profile"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Padding(
                  padding: EdgeInsets.all(16.0),
                      child: Column(
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundImage: AssetImage('assets/image/CEO.JPG'),
                      backgroundColor: Colors.yellowAccent[100],
                    ),
                    SizedBox(height: 10,),
                    Text("$name",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text("$position",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    SizedBox(height: 10,),
                    Divider(),
                    ProfileItem(icon: Icons.email, label: 'Email', value: '$mail'),
                    ProfileItem(icon: Icons.phone, label: 'Phone', value: '$number'),

                  ],
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  ProfileItem({required this.icon, required this.label, this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(label),
      subtitle: value != null ? Text(value!) : null,
      trailing: onTap != null ? Icon(Icons.arrow_forward_ios, size: 16) : null,
      onTap: onTap,
    );
  }
}