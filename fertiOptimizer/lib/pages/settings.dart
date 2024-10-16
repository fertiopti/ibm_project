import 'package:agri_connect/constants/image_strings.dart';
import 'package:agri_connect/utils/appbar.dart';
import 'package:agri_connect/utils/settingContainer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool emailAlertValue = false; // Track the switch state

  @override
  void initState() {
    super.initState();
    // Uncomment if you want to customize system UI styles
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    //   systemNavigationBarColor: Colors.transparent.withOpacity(0.15),
    //   systemNavigationBarIconBrightness: Brightness.light,
    // ));
  }

  @override
  void dispose() {
    // Uncomment if you want to reset system UI styles
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    //   systemNavigationBarColor: Colors.grey,
    //   systemNavigationBarIconBrightness: Brightness.dark,
    // ));
    super.dispose();
  }

  void _onEmailAlertChanged(bool newValue) {
    setState(() {
      emailAlertValue = newValue;
    });
    // Save the new value to SharedPreferences if needed
    // SharedPreferences.getInstance().then((prefs) {
    //   prefs.setBool('emailAlert', newValue);
    // });
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Scaffold(
        backgroundColor: Colors.green,
        appBar: const EAppBar(
          title: Text(
            "Settings",
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  // color: Color(0xFF70BE92),
                  color: Colors.transparent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  // boxShadow: [
                  //   BoxShadow(
                  //     color: Colors.white.withOpacity(0.15),
                  //     spreadRadius: 2,
                  //     blurRadius: 5,
                  //     offset: const Offset(0, 3),
                  //   ),
                  // ],
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 15, right: 5),
                      child: CircleAvatar(
                        radius: 40,
                        child: Image.asset(EImages.darkAppLogo),
                      ),
                    ),
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "JIJIN",
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          "jijinjebanesh@gmail.com",
                          style: TextStyle(color: Colors.white54),
                        )
                      ],
                    ),
                    const Spacer(),
                    const Padding(
                      padding: EdgeInsets.only(right: 15),
                      child: Icon(Iconsax.edit),
                    ),
                  ],
                ),
              ),
              SC(
                name: 'Saved Credit / Debit Cards',
                value: emailAlertValue,
                onChanged: _onEmailAlertChanged,
                icon: Iconsax.card_edit,
              ),
              SC(
                name: 'Become a Seller',
                value: emailAlertValue,
                onChanged: _onEmailAlertChanged,
                onPressed: (){context.push('/ProductAddScreen');},
                icon: Iconsax.coin,
              ),
              SC(
                name: 'Saved location',
                value: emailAlertValue,
                onChanged: _onEmailAlertChanged,
                icon: Iconsax.location,
              ),
              SC(
                name: 'Notification Settings',
                value: emailAlertValue,
                onChanged: _onEmailAlertChanged,
                icon: Iconsax.notification,
              ),
              SC(
                name: 'Sell on FO',
                value: emailAlertValue,
                onChanged: _onEmailAlertChanged,
                icon: Iconsax.shop,
              ),
              SC(
                name: 'Terms, Policies and Licenses',
                value: emailAlertValue,
                onChanged: _onEmailAlertChanged,
                icon: Iconsax.document_copy,
              ),
              SC(
                name: 'Browse FAQs',
                value: emailAlertValue,
                onChanged: _onEmailAlertChanged,
                icon: Iconsax.message_question,
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear(); // This will clear all the stored preferences
                    print('SharedPreferences cleared');
                    context.go('/');
                  },
                  child: const Text(
                    "Logout",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
