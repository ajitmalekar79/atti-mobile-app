import 'package:attheblocks/common/connectivity_controller.dart';
import 'package:get/get.dart';
import '../auth_controller.dart';
import '../dashboard/controller/dashboard_provider.dart';
import '../dashboard/search_controller/search controller.dart';
import '../detail_form_page/detail_form_controller.dart';
import '../detail_form_page/detail_submission_controller.dart';
import '../detail_form_page/form_detail_submit_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<ConnectivityController>(ConnectivityController(), permanent: true);
    Get.put<HomeDataListController>(HomeDataListController(), permanent: true);
    Get.put<PostAuthTocken>(PostAuthTocken(), permanent: true);
    Get.put<DetailFormData>(DetailFormData(), permanent: true);
    Get.put<DetailSubmitedFormData>(DetailSubmitedFormData(), permanent: true);
    Get.put<PostFormData>(PostFormData(), permanent: true);
    Get.put<GetListOnSearchController>(GetListOnSearchController(),
        permanent: true);
  }
}
