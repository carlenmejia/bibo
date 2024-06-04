
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/coupon/controllers/coupon_controller.dart';
import 'package:ride_sharing_user_app/features/home/widgets/banner_view.dart';
import 'package:ride_sharing_user_app/features/home/widgets/best_offers_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/category_view.dart';
import 'package:ride_sharing_user_app/features/home/widgets/coupon_home_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/home_map_view.dart';
import 'package:ride_sharing_user_app/features/home/widgets/home_search_widget.dart';
import 'package:ride_sharing_user_app/features/my_offer/controller/offer_controller.dart';
import 'package:ride_sharing_user_app/features/parcel/controllers/parcel_controller.dart';
import 'package:ride_sharing_user_app/features/parcel/screens/ongoing_parcel_list_view.dart';
import 'package:ride_sharing_user_app/features/ride/widgets/rider_details_widget.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/pusher_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:ride_sharing_user_app/features/address/controllers/address_controller.dart';
import 'package:ride_sharing_user_app/features/home/controllers/banner_controller.dart';
import 'package:ride_sharing_user_app/features/home/controllers/category_controller.dart';
import 'package:ride_sharing_user_app/features/home/widgets/home_my_address.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/common_widgets/app_bar_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/body_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {


  String greetingMessage() {
    var timeNow = DateTime.now().hour;
    if (timeNow <= 12) {
      return 'good_morning'.tr;
    } else if ((timeNow > 12) && (timeNow <= 16)) {
      return 'good_afternoon'.tr;
    } else if ((timeNow > 16) && (timeNow < 20)) {
      return 'good_evening'.tr;
    } else {
      return 'good_night'.tr;
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  bool clickedMenu = false;
  Future<void> loadData() async{
    Get.find<ParcelController>().getUnpaidParcelList();
    Get.find<BannerController>().getBannerList();
    Get.find<CategoryController>().getCategoryList();
    Get.find<AddressController>().getAddressList(1);
    Get.find<CouponController>().getCouponList(1, isUpdate: false);
    Get.find<OfferController>().getOfferList(1);
    await Get.find<RideController>().getCurrentRide();
    if(Get.find<RideController>().currentTripDetails != null){
      PusherHelper().pusherDriverStatus(Get.find<RideController>().currentTripDetails!.id!);
      if(Get.find<RideController>().currentTripDetails!.currentStatus == 'accepted' || Get.find<RideController>().currentTripDetails!.currentStatus == 'ongoing'){
        Get.find<RideController>().startLocationRecord();
      }
    }
    await Get.find<ParcelController>().getOngoingParcelList();
    if(Get.find<ParcelController>().parcelListModel!.data!.isNotEmpty){
      for (var element in Get.find<ParcelController>().parcelListModel!.data!) {
              PusherHelper().pusherDriverStatus(element.id!);}
    }
    Get.find<RideController>().getNearestDriverList(Get.find<LocationController>().getUserAddress()!.latitude!.toString(), Get.find<LocationController>().getUserAddress()!.longitude!.toString());
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<RideController>(
        builder: (rideController) {
          return GetBuilder<ParcelController>(
            builder: (parcelController) {
              int parcelCount = parcelController.parcelListModel?.totalSize??0;
              int rideCount = (rideController.tripDetails != null && rideController.tripDetails!.type == 'ride_request' &&
                  (rideController.tripDetails!.currentStatus == 'pending' || rideController.tripDetails!.currentStatus == 'accepted'|| rideController.tripDetails!.currentStatus == 'ongoing'
                  || (rideController.tripDetails!.currentStatus == 'completed' && rideController.tripDetails!.paymentStatus! == 'unpaid') || (rideController.tripDetails!.currentStatus == 'cancelled' && rideController.tripDetails!.paymentStatus! == 'unpaid')))?1:0;
              return Stack(children: [
                  GetBuilder<ProfileController>(builder: (profileController) {
                    return GetBuilder<RideController>(
                      builder: (rideController) {
                        return GetBuilder<ParcelController>(
                          builder: (parcelController) {
                            return BodyWidget(
                              appBar:  AppBarWidget(title: '${greetingMessage()}, ${profileController.customerFirstName()}',
                                showBackButton: false, isHome: true, fontSize: Dimensions.fontSizeLarge),
                              body: RefreshIndicator(
                                onRefresh: () async {
                                  await loadData();
                                },
                                child: CustomScrollView(slivers: [
                                  SliverToBoxAdapter(child: Column(children: [
                                    Padding(padding: const EdgeInsets.only(top:Dimensions.paddingSize,left: Dimensions.paddingSize,right: Dimensions.paddingSize),
                                      child: Stack(
                                        children: [
                                           Column(children: [

                                             const BannerView(),

                                             const Padding(padding:  EdgeInsets.only(top:Dimensions.paddingSize),
                                               child: CategoryView()),

                                             rideController.tripDetails != null? const SizedBox():
                                             const HomeSearchWidget(),

                                             const HomeMyAddress(addressPage: AddressPage.home),

                                             const HomeMapView(title: 'rider_around_you'),

                                          ])])),

                                    const BestOfferWidget(),

                                    const HomeCouponWidget(),

                                    const SizedBox(height: 100,)
                                  ])),

                                ]),
                              ),
                            );
                          }
                        );
                      }
                    );
                  }),

                (rideCount + parcelCount) != 0 ?
                Positioned(child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                        onTap: (){
                         setState(() {
                           clickedMenu = true;
                         });
                        },
                        onHorizontalDragEnd: (DragEndDetails details){
                          _onHorizontalDrag(details);

                        },

                        child: Stack(children: [
                          SizedBox(width: 70,
                              child: Image.asset(Images.homeMapIcon, color: Theme.of(context).primaryColor)),
                          Positioned(top: 0, bottom: 15, left: 35, right: 0, child: SizedBox(height: 10,child: Image.asset(Images.ongoing, scale: 2.7,))),

                          Positioned( bottom: 85,  right: 5, child: Container(width: 20, height: 20,padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(50)),

                              child: Center(child: Text('${ rideCount + parcelCount}', style: textRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraSmall),))))

                        ],
                        )))) : const SizedBox(),
                if(clickedMenu)
                Positioned(child: Align(
                    alignment: Alignment.centerRight,
                    child: GetBuilder<RideController>(
                      builder: (rideController) {
                        return GetBuilder<ParcelController>(
                          builder: (parcelController) {
                            return Container(width: 220, height: 120,
                                decoration: BoxDecoration(
                                  boxShadow: [BoxShadow(color: Theme.of(context).hintColor.withOpacity(.5), blurRadius: 1, spreadRadius: 1, offset: const Offset(1,1))],
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                                  color: Theme.of(context).cardColor),
                                child: Row(children: [
                                    InkWell(
                                      onTap: (){
                                        setState(() {
                                          clickedMenu = false;
                                        });
                                      },
                                      child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                        child: Icon(Icons.arrow_forward_ios_rounded, color: Theme.of(context).hintColor,size: Dimensions.iconSizeMedium,),),
                                    ),
                                    Column(children: [
                                      Padding(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                                        child: InkWell(onTap: () async {
                                            await rideController.getCurrentRideStatus(fromRefresh: true);
                                            setState(() {
                                              clickedMenu = false;
                                            });
                                        },
                                          child: Container(width: 150,
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Theme.of(context).primaryColor.withOpacity(.5)),
                                                  borderRadius: BorderRadius.circular(10),
                                                  color: Theme.of(context).primaryColor.withOpacity(.125)),
                                              child: Padding(padding: const EdgeInsets.all(8.0),
                                                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                                    Text('ongoing_ride'.tr),
                                                  CircleAvatar(radius: 10,backgroundColor: Theme.of(context).colorScheme.error,
                                                    child: Text('$rideCount', style: textRegular.copyWith(color: Theme.of(context).cardColor, fontSize: Dimensions.fontSizeSmall),),)
                                                  ]))))),

                                      InkWell(onTap: (){
                                        if(parcelController.parcelListModel != null && parcelController.parcelListModel!.data != null && parcelController.parcelListModel!.data!.isNotEmpty){
                                          Get.to(()=>  OngoingParcelListView(title: 'ongoing_parcel_list', parcelListModel: parcelController.parcelListModel!));
                                        }else{
                                          showCustomSnackBar('no_parcel_available'.tr);
                                        }
                                      },
                                        child: Container(width: 150,
                                            decoration: BoxDecoration(
                                                border: Border.all(color: Theme.of(context).primaryColor.withOpacity(.5)),
                                                borderRadius: BorderRadius.circular(10),
                                                color: Theme.of(context).primaryColor.withOpacity(.125)
                                            ),
                                            child: Padding(padding: const EdgeInsets.all(8.0),
                                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                                Text('parcel_delivery'.tr),
                                                CircleAvatar(radius: 10,backgroundColor: Theme.of(context).colorScheme.error,
                                                  child: Text('${parcelController.parcelListModel?.totalSize??0}', style: textRegular.copyWith(color: Theme.of(context).cardColor, fontSize: Dimensions.fontSizeSmall),),)
                                              ],
                                              ))),
                                      ),
                                    ],),
                                  ],
                                ));
                          }
                        );
                      }
                    ))),

                if(rideController.biddingList.isNotEmpty && rideController.tripDetails?.currentStatus == 'pending' )
                  Positioned(bottom: 90, left: 15, right: 15,child: Align(
                    alignment: Alignment.bottomLeft,
                    child: GetBuilder<RideController>(
                        builder: (rideController) {
                          return SizedBox(height: 170,
                            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: ListView.builder(padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  scrollDirection: Axis.horizontal,
                                  itemCount: rideController.biddingList.length,
                                  addRepaintBoundaries: false,
                                  addAutomaticKeepAlives: false,
                                  itemBuilder: (context, index){
                                    return Container(width: Get.width-70,
                                        decoration: BoxDecoration(
                                          boxShadow: [BoxShadow(color: Theme.of(context).hintColor.withOpacity(.125), blurRadius: 1, spreadRadius: 1, offset: const Offset(0,0))]
                                        ),
                                        child: RiderDetailsWidget(bidding: rideController.biddingList[index], tripId: rideController.tripDetails!.id!,));
                                  }),
                            ),
                          );
                        }
                    )))
                ],
              );
            }
          );
        }
      ),
    );
  }
  void _onHorizontalDrag(DragEndDetails details) {
    if(details.primaryVelocity == 0) return;

    if (details.primaryVelocity!.compareTo(0) == -1) {
      debugPrint('dragged from left');
    } else {
      debugPrint('dragged from right');
    }
  }
}




