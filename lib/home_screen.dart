import 'package:flutter/material.dart';
import 'package:infinity_invest_admin/all_user_screen.dart';
import 'package:infinity_invest_admin/contact_us.dart';
import 'package:infinity_invest_admin/deposit_details.dart';
import 'package:infinity_invest_admin/deposit_request.dart';
import 'package:infinity_invest_admin/mining_on_off.dart';
import 'package:infinity_invest_admin/notice_screen.dart';
import 'package:infinity_invest_admin/packages_screen.dart';
import 'package:infinity_invest_admin/refer_benefit.dart';
import 'package:infinity_invest_admin/slider_image.dart';
import 'package:infinity_invest_admin/total_transaction.dart';
import 'package:infinity_invest_admin/withdraw_request.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<GridItem> gridItems = [
    GridItem("All Users", Icons.person, AllUserScreen()),
    GridItem("Packages", Icons.local_shipping, PackagesScreen()),
    GridItem("Notice", Icons.campaign, NoticeScreen()),
    GridItem("Deposits", Icons.monetization_on, DepositRequest()),
    GridItem("Withdraws", Icons.money_off, WithdrawRequestScreen()),
    GridItem("Contact", Icons.support_agent, ContactUs()),
    GridItem("Deposit info", Icons.settings_system_daydream, DepositDetails()),
    GridItem("Refer Bonus", Icons.people, ReferBenefit()),
    GridItem("Slider Images", Icons.image_outlined, SliderScreen()),
    GridItem("Total Deposit", Icons.today_outlined, TotalDeposit()),
    GridItem("Mining On-Off", Icons.ac_unit_rounded, MiningOnOrOff()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Control Panel"),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemCount: gridItems.length,
        itemBuilder: (BuildContext context, int index) {
          return GridItemCard(
            screenName: gridItems[index].screen,
            title: gridItems[index].title,
            icon: gridItems[index].icon,
          );
        },
      ),
    );
  }
}

class GridItem {
  final String title;
  final IconData icon;
  final Widget screen;

  GridItem(this.title, this.icon, this.screen);
}

class GridItemCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget screenName;

  GridItemCard(
      {required this.title, required this.icon, required this.screenName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screenName),
        );
      },
      child: Card(
        elevation: 5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 40,
              color: Colors.blue,
            ),
            Text(
              title,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
