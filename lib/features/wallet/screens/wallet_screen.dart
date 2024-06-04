import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/wallet/controllers/wallet_controller.dart';
import 'package:ride_sharing_user_app/features/wallet/screens/loyality_point_screen.dart';
import 'package:ride_sharing_user_app/features/wallet/widget/wallet_money_screen.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/common_widgets/app_bar_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/body_widget.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}
class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin{
  late TabController tabController;

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: 2, vsync: this);
    Get.find<WalletController>().getTransactionList(1);
    Get.find<WalletController>().getLoyaltyPointList(1);
    Get.find<ProfileController>().getProfileInfo();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        Get.find<ProfileController>().getProfileInfo();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: BodyWidget(
          appBar: AppBarWidget(title: 'wallet'.tr, centerTitle: true),
          body: GetBuilder<WalletController>(builder: (walletController) {
            return Column(children: [

              Padding(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                child: TabBar(

                  controller: tabController,
                  unselectedLabelColor: Colors.grey,
                  labelColor: Get.isDarkMode ? Colors.white : Theme.of(context).primaryColor,
                  labelStyle: textMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
                  isScrollable: true,
                  indicatorColor: Theme.of(context).primaryColor.withOpacity(0),
                  padding: const EdgeInsets.all(0),
                  tabs:  [
                    SizedBox(height: 30, child: Tab(text: 'wallet_money'.tr)),
                    SizedBox(height: 30, child: Tab(text: 'loyalty_point'.tr)),
                  ],
                ),
              ),

              Expanded(child: TabBarView(
                controller: tabController,
                children:  const [
                  WalletMoneyScreen(),
                  LoyaltyPointScreen(),
                ],
              )),

            ]);
          }),
        ),
      ),
    );
  }
}
