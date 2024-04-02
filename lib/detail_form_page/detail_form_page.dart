// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:attheblocks/detail_form_page/detail_submission_controller.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_base_helper.dart';
import 'detail_form_controller.dart';
import 'form_detail_submit_controller.dart';
import 'model/detail_form_model.dart';
import 'model/detail_submission_model.dart';
import 'model/offline_submission_model.dart';

class Detail_form_page extends StatefulWidget {
  final String itemId;
  Detail_form_page({Key? key, required this.itemId});

  @override
  State<Detail_form_page> createState() => _Detail_form_pageState();
}

class _Detail_form_pageState extends State<Detail_form_page> {
  GlobalKey<AutoCompleteTextFieldState> autokey =
      GlobalKey<AutoCompleteTextFieldState>();
  double _menuHeight = 0.0;
  bool _menuOpened = false;
  String firstLetter = '';
  Color backGroundColor = Color.fromARGB(255, 231, 233, 200);
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final DetailFormData _formDataController = Get.find<DetailFormData>();
  final PostFormData _postFormData = Get.find<PostFormData>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  List<FormDetailModel> formDetailList = [];
  List<SubmissionModel> submissions = [];
  Map<String, List<dynamic>> selectedValuesFromCheckbox = {};
  Map<String, dynamic> selectedValuesFromRadioBtn = {};
  Map<String, dynamic> selectedValuesFromTags = {};
  Map<String, dynamic> selectedValuesFromDropDown = {};
  Map<String, dynamic> selectedValuesFromDateTime = {};
  Map<String, dynamic> selectedValuesFromLocation = {};
  Map<String, dynamic> autoCompleteTextFieldKeys = {};
  Map<String, dynamic> selectedValuesFromDropDownText = {};
  Map<String, dynamic> selectedValuesFromUniqueId = {};
  Map<String, dynamic> selectedValuesFromImage = {};
  final TextEditingController _selectdateController = TextEditingController();
  Map<String, TextEditingController> autoCompleteTextFieldController = {};
  List<DateTime> _selectedDates = [];
  bool _locationIsLoading = false;
  File? _image;
  List<String> imagePaths = [];
  final picker = ImagePicker();
  TextEditingController _imagePathController = TextEditingController();
  bool _isConnected = false;
  bool isLoading = true;
  bool submitDataLoading = false;
  final List<String> itemList = [
    'Add new submission',
  ];
  final Map<String, String> formData = {
    'Item 1': 'Data for Item 1',
    'Item 2': 'Data for Item 2',
    'Item 3': 'Data for Item 3',
  };

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    _selectedDate = now;
    _dateController.text =
        DateFormat('yyyy-MM-dd').format(_selectedDate).toString();
    String formattedTime = DateFormat('HH:mm').format(now);
    _timeController.text = formattedTime;
    // uploadFormDetails();

    getFormDetails();
    getOfflineList();
  }

  getOfflineList() async {
    submissions = await DatabaseHelper.instance.retrieveSubmissions();
  }

  uploadFormDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('itemId') == null || prefs.getString('itemId') == '') {
    } else {
      String itemidString = prefs.getString('itemId') ?? '';
      String selectedDateString = prefs.getString(
            'selectedDate',
          ) ??
          '';
      List<FormData> formDataList = await getFormDataList();
      DateTime selectedDateOff = DateTime.parse(selectedDateString);

      await _postFormData.submitFormData(
          formDataList, itemidString, selectedDateOff);

      clearData();
      await prefs.setStringList('form_data', []);
      await prefs.setString('itemId', '');
    }
  }

  Future<void> _syncData() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check internet connection'),
        ),
      );
    } else {
      List<SubmissionModel> submissions =
          await DatabaseHelper.instance.retrieveSubmissions();
      for (SubmissionModel submission in submissions) {
        await _postFormData.submitFormData(
            submission.formDataList, submission.itemId, submission.date);
        DatabaseHelper.instance.deleteSubmission(submission.itemId);
        setState(() {
          getFormDetails();
          getOfflineList();
        });
      }
      DatabaseHelper.instance.deleteAllSubmissions();
    }
  }

  Future<List<FormData>> getFormDataList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? jsonList = prefs.getStringList('form_data');
    if (jsonList != null) {
      try {
        return jsonList
            .map((jsonString) => FormData.fromJson(json.decode(jsonString)))
            .toList();
      } catch (e) {
        // Handle parsing errors here
        print('Error parsing JSON: $e');
      }
    }
    return [];
  }

  List<FormData> convertStringToFormDataList(String? jsonString) {
    List<dynamic> jsonList = json.decode(jsonString!);
    List<FormData> formDataList = jsonList.map((jsonData) {
      Map<String, dynamic> formDataMap = Map<String, dynamic>.from(jsonData);
      return FormData.fromJson(formDataMap);
    }).toList();
    return formDataList;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imagePaths.add(pickedFile.path);
      });
    }
  }

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.camera);

    if (pickedImage != null) {
      setState(() {
        imagePaths.add(pickedImage.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      imagePaths.removeAt(index);
    });
  }

  // Future<void> _pickImage(String id) async {
  //   final picker = ImagePicker();
  //   final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  //   if (pickedFile != null) {
  //     formDatavalues.add(FormData(
  //         custom_disclosure_id: id, type: 'gallery', value: pickedFile.path));
  //     setState(() {
  //       final field = formDatavalues.firstWhere(
  //           (formDatavalues) => formDatavalues.custom_disclosure_id == id);
  //       field.value.add(pickedFile.path);
  //     });
  //   }
  // }

  // void _removeImage(String Id, int index) {
  //   setState(() {
  //     final field = formDatavalues.firstWhere(
  //         (formDatavalues) => formDatavalues.custom_disclosure_id == Id);
  //     field.value.removeAt(index);
  //   });
  // }

  List<FormData> formDatavalues = [];
  Future<void> _selectDate(BuildContext context,
      {String? from, DateTime? initialDate, var disclosurId}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: from == 'Date_Submission'
          ? DateTime.now()
          : DateTime(DateTime.now().year + 5),
    );
    if (picked != null) {
      if (from == 'Date_Submission' && picked != _selectedDate) {
        setState(() {
          _selectedDate = picked.add(Duration(
              hours: _selectedTime.hour, minutes: _selectedTime.minute));
          _dateController.text =
              DateFormat('yyyy-MM-dd').format(_selectedDate).toString();
          isLoading = true;
          getFormDetails(date: _selectedDate);
        });
      } else if (from == 'Custom_Disclosure') {
        selectedValuesFromDateTime[disclosurId] = picked;
      }
    }
  }

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _imagePathController.text = _image!.path;
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = _getCurrentTime();
      });
    }
  }

  Future<void> selectDatefromComponent(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDates.add(picked);
        _updateDateController();
      });
    }
  }

  void _updateDateController() {
    if (_selectedDates.isNotEmpty) {
      _selectdateController.text = _selectedDates
          .map((date) => date.toString().split(' ')[0])
          .join(', ');
    } else {
      _selectdateController.text = '';
    }
  }

  String _getCurrentTime() {
    String formattedTime = '${_selectedTime.hour}:${_selectedTime.minute}';
    return formattedTime;
  }

  void _getCurrentLocation({var disclosurId}) async {
    PermissionStatus permissionStatus = await Permission.location.request();

    if (permissionStatus == PermissionStatus.granted) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _locationController.text =
            '${position.latitude}, ${position.longitude}';
        selectedValuesFromLocation[disclosurId] = [
          position.latitude,
          position.longitude
        ];
        _locationIsLoading = false;
      });
    } else {
      // Handle if permission is not granted
      print('Location permission not granted');
    }
  }

  void _toggleMenu() {
    setState(() {
      _menuOpened = !_menuOpened;
      _menuHeight = _menuOpened ? 100.0 : 0.0;
    });
  }

  getFormDetails({DateTime? date}) async {
    // setState(() {
    formDetailList.clear();

    //_formDataController.data.value.tagList.clear();
    // });
    formDetailList =
        await _formDataController.getFormDetail(widget.itemId, date: date);
    firstLetter = formDetailList[0].name != ''
        ? formDetailList[0].name.substring(0, 1)
        : '';
    backGroundColor = generateRandomColor();
    formDetailList[0].customDisclosures.forEach((element) {
      if (element.type == 'unique_id') {
        autoCompleteTextFieldKeys[element.id] =
            GlobalKey<AutoCompleteTextFieldState>();
      }
    });

    if (mounted) {
      setState(() {
        isLoading = false;
        submitDataLoading = false;
      });
    }
  }

  Color generateRandomColor() {
    Random random = Random();
    int red = 200 + random.nextInt(55); // Red component between 200 and 255
    int green = 200 + random.nextInt(55); // Green component between 200 and 255
    int blue = 200 + random.nextInt(55); // Blue component between 200 and 255
    return Color.fromRGBO(red, green, blue, 1.0);
  }

  Future<void> _clearUserSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Clear relevant data from SharedPreferences
    await prefs.clear();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi;
    });
  }

  Future<void> _storeFormData(List<FormData> formData) async {
    // Store form data in local cache
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> formDataJsonList =
        formData.map((data) => jsonEncode(data.toJson())).toList();
    await prefs.setStringList('form_data', formDataJsonList);
    await prefs.setString('itemId', widget.itemId);
    await prefs.setString('selectedDate', _selectedDate.toString());
  }

  Future<void> _clearCache() async {
    // Clear form data from local cache
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('form_data');
  }

  // Future<void> _uploadCachedData() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   List<String>? formDataJsonList = prefs.getStringList('form_data');
  //   String? itemId = prefs.getString('itemId');
  //   List<String>? _selectedDate = prefs.getStringList('selectedDate');
  //   if (formDataJsonList != null && formDataJsonList.isNotEmpty) {
  //     List<FormData> formData = formDataJsonList
  //         .map((jsonString) => FormData.fromJson(jsonDecode(jsonString)))
  //         .toList();
  //     await _submitForm(formData);
  //     DateTime date = DateTime.parse(_selectedDate as String);
  //     await _postFormData.submitFormData(
  //         formData, itemId!, date);
  //     clearData();
  //   }
  // }

  void _submitFormData(List<FormData> formData) {
    if (_isConnected) {
      // _submitForm(formData);
    } else {
      _storeFormData(formData);
    }
  }

  clearData() {
    setState(() {
      _menuHeight = 0.0;
      _menuOpened = false;
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _dateController.clear();
      _timeController.clear();
      _locationController.clear();
      // formDetailList = [];
      selectedValuesFromCheckbox = {};
      selectedValuesFromRadioBtn = {};
      selectedValuesFromTags = {};
      selectedValuesFromDropDown = {};
      selectedValuesFromDateTime = {};
      selectedValuesFromDropDownText = {};
      selectedValuesFromUniqueId = {};
      _selectdateController.clear();
      _selectedDates = [];
      _locationIsLoading = false;
      _image = null;
      _imagePathController.clear();
      autoCompleteTextFieldKeys.clear();
      imagePaths = [];

      formDatavalues = [];
      _dateController.text =
          DateFormat('yyyy-MM-dd').format(_selectedDate).toString();
      String formattedTime = DateFormat('HH:mm').format(DateTime.now());
      _timeController.text = formattedTime;
    });

    getFormDetails();
  }

  clearOfflineData() {
    setState(() {
      _menuHeight = 0.0;
      _menuOpened = false;
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _dateController.clear();
      _timeController.clear();
      _locationController.clear();
      // formDetailList = [];
      selectedValuesFromCheckbox = {};
      selectedValuesFromRadioBtn = {};
      selectedValuesFromTags = {};
      selectedValuesFromDropDown = {};
      selectedValuesFromDateTime = {};
      selectedValuesFromDropDownText = {};
      selectedValuesFromUniqueId = {};
      _selectdateController.clear();
      _selectedDates = [];
      _locationIsLoading = false;
      _image = null;
      _imagePathController.clear();
      autoCompleteTextFieldKeys.clear();
      imagePaths = [];

      formDatavalues = [];
      _dateController.text =
          DateFormat('yyyy-MM-dd').format(_selectedDate).toString();
      String formattedTime = DateFormat('HH:mm').format(DateTime.now());
      _timeController.text = formattedTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
          title: Container(
            child: Image.asset(
              "assets/images/atbi_logo.png",
              height: 30,
            ),
          ),
          actions: [
            IconButton(
                onPressed: () {
                  _syncData();
                },
                icon: const Icon(
                  Icons.sync,
                  color: Colors.white,
                )),
            IconButton(
                onPressed: () {
                  _toggleMenu();
                },
                icon: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                )),
          ]),
      body: Stack(
        children: [
          isLoading || formDetailList.isEmpty
              ? Container(
                  width: screenWidth,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 50,
                      ),
                      CircularProgressIndicator(
                        color: Colors.black,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text('Loading item ...')
                    ],
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: [
                      Container(
                          width: screenWidth,
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                              onPressed: () {
                                Get.back();
                              },
                              icon: const Icon(Icons.arrow_back))),
                      CircleAvatar(
                        radius: 85,
                        backgroundColor: backGroundColor,
                        child: Text(
                          firstLetter,
                          style: const TextStyle(fontSize: 50),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                padding: const EdgeInsets.only(top: 10),
                                child: const Icon(Icons.category_rounded)),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Text(
                                formDetailList[0].name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 34),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            const Icon(Icons.location_city_sharp),
                            const SizedBox(
                              width: 10,
                            ),
                            Text(
                              formDetailList[0].property.name,
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 10,
                          ),
                          Image.asset('assets/images/tag_img.png'),
                          const SizedBox(
                            width: 10,
                          ),
                          SizedBox(
                            height: 30,
                            width: screenWidth * 0.8,
                            // Adjust height as needed
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              //shrinkWrap: true,
                              itemCount: formDetailList[0].tagList.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  padding: const EdgeInsets.all(
                                      2), // Adjust width as needed
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                      color: index % 2 == 0
                                          ? Colors.grey
                                          : const Color.fromARGB(
                                              255, 240, 232, 218),
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: const [
                                        BoxShadow(
                                          blurRadius: 1,
                                          color: Colors.grey,
                                        )
                                      ]),

                                  alignment: Alignment.center,
                                  child: Text(
                                    formDetailList[0].tagList[index],
                                    style: TextStyle(
                                      color: index % 2 == 0
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      ListView.builder(
                        itemCount: itemList.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          String item = itemList[index];
                          return ExpandableListItem(
                            title: item,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Date and Time of Submission',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    TextFormField(
                                      readOnly: true,
                                      onTap: () => _selectDate(context,
                                          from: 'Date_Submission'),
                                      decoration: InputDecoration(
                                        labelText: 'Date',
                                        suffixIcon: IconButton(
                                          icon:
                                              const Icon(Icons.calendar_today),
                                          onPressed: () => _selectDate(context,
                                              from: 'Date_Submission'),
                                        ),
                                      ),
                                      controller: _dateController,
                                    ),
                                    TextFormField(
                                      readOnly: true,
                                      onTap: () => _selectTime(context),
                                      decoration: InputDecoration(
                                        labelText: 'Time',
                                        suffixIcon: IconButton(
                                          icon: const Icon(
                                            Icons.access_time,
                                          ),
                                          onPressed: () => _selectTime(context),
                                        ),
                                      ),
                                      controller: _timeController,
                                    ),
                                    const SizedBox(
                                      height: 40,
                                    ),
                                    ListView.builder(
                                      itemCount: formDetailList[0]
                                          .customDisclosures
                                          .length,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        List<CustomDisclosure>
                                            customDisclosure =
                                            formDetailList[0].customDisclosures;

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        customDisclosure[index]
                                                            .disclosureName,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Color.fromARGB(
                                                          255, 167, 160, 64),
                                                    ),
                                                  ),
                                                  const TextSpan(
                                                    text: ' : ',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Color.fromARGB(
                                                          255, 167, 160, 64),
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        customDisclosure[index]
                                                            .disclosure,
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black),
                                                  ),
                                                  customDisclosure[index]
                                                              .timer ==
                                                          'unlimited'
                                                      ? const TextSpan(
                                                          text:
                                                              ' [Unlimited submissions]',
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors.black),
                                                        )
                                                      : customDisclosure[index]
                                                                  .timer ==
                                                              'computed'
                                                          ? const TextSpan(
                                                              text:
                                                                  ' [computed]',
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .black),
                                                            )
                                                          : const TextSpan(
                                                              text: '[]',
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .black),
                                                            )
                                                ],
                                              ),
                                            ),
                                            buildFormField(
                                                customDisclosure, index),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    Container(
                                      width: screenWidth,
                                      alignment: Alignment.center,
                                      child: InkWell(
                                          onTap: () async {
                                            // Navigator.push(
                                            //   context,
                                            //   MaterialPageRoute(
                                            //     builder: (context) => NextPage(
                                            //         formDatavalues:
                                            //             formDatavalues),
                                            //   ),
                                            // );

                                            if (formDatavalues.isEmpty) {
                                              setState(() {
                                                submitDataLoading = false;
                                              });
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Please Fill In At List One Disclosure'),
                                                ),
                                              );
                                            } else {
                                              await _checkConnectivity();
                                              if (_isConnected == true) {
                                                setState(() {
                                                  submitDataLoading = true;
                                                });
                                                await _postFormData
                                                    .submitFormData(
                                                        formDatavalues,
                                                        widget.itemId,
                                                        _selectedDate);
                                                clearData();
                                              } else {
                                                // SharedPreferences prefs =
                                                //     await SharedPreferences
                                                //         .getInstance();

                                                // List<String> jsonList =
                                                //     formDatavalues
                                                //         .map((formData) =>
                                                //             json.encode(formData
                                                //                 .toJson()))
                                                //         .toList();
                                                // await prefs.setStringList(
                                                //     'form_data', jsonList);

                                                // await prefs.setString(
                                                //     'itemId', widget.itemId);
                                                // await prefs.setString(
                                                //     'selectedDate',
                                                //     _selectedDate.toString());

                                                SubmissionModel
                                                    submitDataOffline =
                                                    SubmissionModel(
                                                        date: _selectedDate,
                                                        itemId: widget.itemId,
                                                        formDataList:
                                                            formDatavalues);
                                                await DatabaseHelper.instance
                                                    .insertSubmission(
                                                        submitDataOffline);
                                                setState(() {
                                                  getOfflineList();
                                                });

                                                // clearData();
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'No internet data submitted offline'),
                                                  ),
                                                );
                                                // setState(() {
                                                //   submitDataLoading = false;
                                                // });
                                              }
                                            }
                                          },
                                          child: Container(
                                              color: Colors.black,
                                              alignment: Alignment.center,
                                              width: 80,
                                              padding: EdgeInsets.all(8),
                                              child: submitDataLoading
                                                  ? Container(
                                                      height: 20,
                                                      width: 20,
                                                      child:
                                                          const CircularProgressIndicator(
                                                              color:
                                                                  Colors.white),
                                                    )
                                                  : const Text(
                                                      'Submit',
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ))),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          );
                        },
                      ),
                      ListView.builder(
                        itemCount: submissions.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final data = submissions[index];

                          String formattedDate =
                              DateFormat('MMMM d, yyyy - HH:mm')
                                  .format(data.date);
                          return Container(
                            height: 50,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 2),
                            decoration: const BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                      blurRadius: 1,
                                      spreadRadius: 1,
                                      color: Colors.grey)
                                ]),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formattedDate,
                                  style: TextStyle(fontSize: 18),
                                ),
                                const Text(
                                  'Pending',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.orange),
                                ),
                                // ExpandableListOfflineSubmission(
                                //   title: formattedDate,
                                // )
                              ],
                            ),
                          );
                        },
                      ),
                      ListView.builder(
                          itemCount: submissions.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final data = submissions[index];

                            String formattedDate =
                                DateFormat('MMMM d, yyyy - HH:mm')
                                    .format(data.date);
                            return ExpandableListSubmission(
                                title: formattedDate,
                                itemId: widget.itemId,
                                id: formDetailList[0].submissions[index].id);
                          }),
                      ListView.builder(
                          itemCount: formDetailList[0].submissions.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            DateTime dateTime = DateTime.parse(formDetailList[0]
                                .submissions[index]
                                .submissionAt);

                            String formattedDate =
                                DateFormat('MMMM d, yyyy - HH:mm')
                                    .format(dateTime);
                            return ExpandableListSubmission(
                                title: formattedDate,
                                itemId: widget.itemId,
                                id: formDetailList[0].submissions[index].id);
                          })
                    ],
                  ),
                ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _menuHeight,
            color: Colors.black,
            child: ListView(
              children: [
                InkWell(
                  onTap: () {
                    Get.back();
                  },
                  child: Container(
                    padding: EdgeInsets.all(7),
                    width: screenWidth,
                    alignment: Alignment.center,
                    child: const Text('Items',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                InkWell(
                  onTap: () {
                    FirebaseAuth.instance.signOut();
                    Get.offAllNamed('/logingScreen');
                    _clearUserSession();
                  },
                  child: Container(
                    padding: EdgeInsets.all(7),
                    width: screenWidth,
                    alignment: Alignment.center,
                    child: const Text('Logout',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                // InkWell(
                //   onTap: () {},
                //   child: Container(
                //     padding: const EdgeInsets.all(7),
                //     width: screenWidth,
                //     alignment: Alignment.center,
                //     child: const Text('Settings',
                //         style: TextStyle(color: Colors.white)),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFormField(List<CustomDisclosure> disclosure, index) {
    final String type = disclosure[index].type;
    final String id = disclosure[index].id;

    switch (type) {
      case 'string':
        return TextFormField(
          decoration: const InputDecoration(hintText: 'Enter a text input'),
          onChanged: (value) {
            // Find the index of the FormData object with the matching disclosureName
            int index = formDatavalues
                .indexWhere((formData) => formData.custom_disclosure_id == id);
            if (index != -1) {
              // If FormData object with matching disclosureName is found, update its value
              formDatavalues[index] =
                  FormData(custom_disclosure_id: id, type: type, value: value);
            } else {
              // If FormData object with matching disclosureName is not found, add a new FormData object
              formDatavalues.add(
                  FormData(custom_disclosure_id: id, type: type, value: value));
            }
          },
        );
      case 'number':
        return TextFormField(
          decoration: const InputDecoration(hintText: 'Enter a number'),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            int index = formDatavalues
                .indexWhere((formData) => formData.custom_disclosure_id == id);
            if (index != -1) {
              // If FormData object with matching disclosureName is found, update its value
              formDatavalues[index] = FormData(
                  custom_disclosure_id: id,
                  type: type,
                  value: double.tryParse(value) ?? 0);
            } else {
              // If FormData object with matching disclosureName is not found, add a new FormData object
              formDatavalues.add(FormData(
                  custom_disclosure_id: id,
                  type: type,
                  value: double.tryParse(value) ?? 0));
            }
          },
        );

      case 'tags':
        final List<dynamic> valueList =
            List<dynamic>.from(disclosure[index].valueList);
        List<String> selectedTags = selectedValuesFromTags[id] ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              hint: const Text('Select Tags'),
              // value: selectedTags.isNotEmpty ? selectedTags.join(', ') : null,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  if (!(selectedValuesFromTags[id] ?? []).contains(newValue)) {
                    selectedValuesFromTags[id] != null
                        ? selectedValuesFromTags[id].add(newValue)
                        : selectedValuesFromTags[id] = [newValue];
                    int index = formDatavalues.indexWhere(
                        (formData) => formData.custom_disclosure_id == id);
                    if (index != -1) {
                      // If FormData object with matching disclosureName is found, update its value
                      formDatavalues[index] = FormData(
                          custom_disclosure_id: id,
                          type: type,
                          value: selectedValuesFromTags[id]);
                    } else {
                      // If FormData object with matching disclosureName is not found, add a new FormData object
                      formDatavalues.add(FormData(
                          custom_disclosure_id: id,
                          type: type,
                          value: selectedValuesFromTags[id]));
                    }
                  }
                }

                if (mounted) {
                  setState(() {});
                }
              },
              items: valueList.map<DropdownMenuItem<String>>((value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 2,
              children: selectedTags.map((tag) {
                return Container(
                  height: 35,
                  child: Chip(
                    backgroundColor: Colors.grey,
                    label: Text(
                      tag,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    onDeleted: () {
                      setState(() {
                        selectedValuesFromTags[id].remove(tag);
                        int index = formDatavalues.indexWhere(
                            (formData) => formData.custom_disclosure_id == id);
                        if (index != -1) {
                          formDatavalues[index] = FormData(
                              custom_disclosure_id: id,
                              type: type,
                              value: selectedValuesFromTags[id]);
                        }
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        );
      // return Column(
      //   crossAxisAlignment: CrossAxisAlignment.start,
      //   children: [
      //     DropdownButtonFormField<String>(
      //       hint: Text('Select Tags'),
      //       value: selectedTags.isNotEmpty ? selectedTags.join(', ') : null,
      //       onChanged: (String? newValue) {
      //         setState(() {
      //           if (newValue != null) {
      //             if (!selectedTags.contains(newValue)) {
      //               selectedTags.add(
      //                   newValue); // Add the value if it's not already in the list
      //             }
      //           } else {
      //             selectedTags
      //                 .clear(); // Clear the list if no value is selected
      //           }
      //         });
      //       },
      //       items: valueList.map<DropdownMenuItem<String>>((dynamic value) {
      //         return DropdownMenuItem<String>(
      //           value: value,
      //           child: Row(
      //             children: [
      //               Text(value),
      //             ],
      //           ),
      //         );
      //       }).toList(),
      //     ),
      //     const SizedBox(height: 20),
      //     Wrap(
      //       spacing: 8,
      //       children: selectedTags.map((tag) {
      //         return Chip(
      //           label: Text(tag),
      //           onDeleted: () {
      //             setState(() {
      //               selectedTags.remove(tag);
      //             });
      //           },
      //         );
      //       }).toList(),
      //     ),
      //   ],
      // );
      case 'radio':
        final List<dynamic> valueList =
            List<dynamic>.from(disclosure[index].valueList);
        return Container(
          child: GridView.builder(
            itemCount: valueList.length,
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 4, crossAxisSpacing: 1),
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                title: Text(
                  valueList[index],
                  style: TextStyle(fontSize: 12),
                ),
                leading: Radio<String>(
                  activeColor: Color.fromARGB(255, 167, 160, 64),
                  value: valueList[index],
                  groupValue: selectedValuesFromRadioBtn[id],
                  onChanged: (dynamic newValue) {
                    setState(() {
                      selectedValuesFromRadioBtn[id] = newValue;
                      int index = formDatavalues.indexWhere(
                          (formData) => formData.custom_disclosure_id == id);
                      if (index != -1) {
                        // If FormData object with matching disclosureName is found, update its value
                        formDatavalues[index] = formDatavalues[index] =
                            FormData(
                                custom_disclosure_id: id,
                                type: type,
                                value: selectedValuesFromRadioBtn[id]);
                      } else {
                        // If FormData object with matching disclosureName is not found, add a new FormData object
                        formDatavalues.add(FormData(
                            custom_disclosure_id: id,
                            type: type,
                            value: selectedValuesFromRadioBtn[id]));
                      }
                    });
                  },
                ),
              );
            },
          ),
        );
      // return Column(
      //   children: valueList.map((value) {
      //     return RadioListTile<dynamic>(
      //       title: Text(value.toString()),
      //       value: value,
      //       groupValue: selectedValuesFromRadioBtn[id],
      //       activeColor: Color.fromARGB(255, 202, 170, 75),
      //       onChanged: (dynamic newValue) {
      //         setState(() {
      //           selectedValuesFromRadioBtn[id] = newValue;
      //           int index = formDatavalues.indexWhere(
      //               (formData) => formData.custom_disclosure_id == id);
      //           if (index != -1) {
      //             // If FormData object with matching disclosureName is found, update its value
      //             formDatavalues[index] = formDatavalues[index] = FormData(
      //                 custom_disclosure_id: id,
      //                 type: type,
      //                 value: selectedValuesFromRadioBtn[id]);
      //           } else {
      //             // If FormData object with matching disclosureName is not found, add a new FormData object
      //             formDatavalues.add(FormData(
      //                 custom_disclosure_id: id,
      //                 type: type,
      //                 value: selectedValuesFromRadioBtn[id]));
      //           }
      //         });
      //       },
      //     );
      //   }).toList(),
      // );
      case 'checkbox':
        final List<dynamic> valueList =
            List<dynamic>.from(disclosure[index].valueList);
        return GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: valueList.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 3, crossAxisSpacing: 0.2),
          itemBuilder: (BuildContext context, int index) {
            String selectvalue = valueList[index];
            return Container(
              child: CheckboxListTile(
                title: Text(
                  valueList[index],
                  style: TextStyle(fontSize: 14),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color.fromARGB(255, 167, 160, 64),
                value: (selectedValuesFromCheckbox[id] ?? [])
                    .contains(selectvalue),
                onChanged: (bool? newValue) {
                  setState(() {
                    // selectedValuesFromCheckbox[id] ??= [];
                    if (newValue!) {
                      selectedValuesFromCheckbox[id] != null
                          ? selectedValuesFromCheckbox[id]?.add(selectvalue)
                          : selectedValuesFromCheckbox[id] = [selectvalue];
                    } else {
                      selectedValuesFromCheckbox[id]?.remove(selectvalue);
                    }
                    int index = formDatavalues.indexWhere(
                        (formData) => formData.custom_disclosure_id == id);
                    if (index != -1) {
                      // If FormData object with matching disclosureName is found, update its value
                      formDatavalues[index] = formDatavalues[index] = FormData(
                          custom_disclosure_id: id,
                          type: type,
                          value: selectedValuesFromCheckbox[id]);
                    } else {
                      // If FormData object with matching disclosureName is not found, add a new FormData object
                      formDatavalues.add(FormData(
                          custom_disclosure_id: id,
                          type: type,
                          value: selectedValuesFromCheckbox[id]));
                    }
                  });
                },
              ),
            );
          },
        );
      // return Column(
      //   children: valueList.map((value) {
      //     return CheckboxListTile(
      //       title: Text(value.toString()),
      //       activeColor: Color.fromARGB(255, 202, 170, 75),
      //       value: (selectedValuesFromCheckbox[id] ?? []).contains(value),
      //       onChanged: (bool? newValue) {
      //         setState(() {
      //           // selectedValuesFromCheckbox[id] ??= [];
      //           if (newValue!) {
      //             selectedValuesFromCheckbox[id] != null
      //                 ? selectedValuesFromCheckbox[id]?.add(value.toString())
      //                 : selectedValuesFromCheckbox[id] = [value.toString()];
      //           } else {
      //             selectedValuesFromCheckbox[id]?.remove(value.toString());
      //           }
      //           int index = formDatavalues.indexWhere(
      //               (formData) => formData.custom_disclosure_id == id);
      //           if (index != -1) {
      //             // If FormData object with matching disclosureName is found, update its value
      //             formDatavalues[index] = formDatavalues[index] = FormData(
      //                 custom_disclosure_id: id,
      //                 type: type,
      //                 value: selectedValuesFromCheckbox[id]);
      //           } else {
      //             // If FormData object with matching disclosureName is not found, add a new FormData object
      //             formDatavalues.add(FormData(
      //                 custom_disclosure_id: id,
      //                 type: type,
      //                 value: selectedValuesFromCheckbox[id]));
      //           }
      //         });
      //       },
      //     );
      //   }).toList(),
      // );
      case 'dropdown':
        final List<dynamic> valueList =
            List<dynamic>.from(disclosure[index].valueList);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              child: DropdownButton<dynamic>(
                value: selectedValuesFromDropDown[id],
                hint: Text('select options'),
                items: valueList.map((value) {
                  return DropdownMenuItem<dynamic>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (dynamic selectedValue) {
                  setState(() {
                    selectedValuesFromDropDown[id] = selectedValue;
                    int index = formDatavalues.indexWhere(
                        (formData) => formData.custom_disclosure_id == id);
                    if (index != -1) {
                      // If FormData object with matching disclosureName is found, update its value
                      formDatavalues[index] = formDatavalues[index] = FormData(
                          custom_disclosure_id: id,
                          type: type,
                          value: selectedValuesFromDropDown[id]);
                    } else {
                      // If FormData object with matching disclosureName is not found, add a new FormData object
                      formDatavalues.add(FormData(
                          custom_disclosure_id: id,
                          type: type,
                          value: selectedValuesFromDropDown[id]));
                    }
                  });
                },
              ),
            ),
          ],
        );
      case 'date':
        String dateText = 'Select Date';
        if (selectedValuesFromDateTime[id] != null) {
          dateText = DateFormat('yyyy-MM-dd')
              .format(selectedValuesFromDateTime[id])
              .toString();
        } else {
          dateText = 'Select Date';
        }
        return TextFormField(
          readOnly: true,
          onTap: () async {
            await _selectDate(context,
                from: 'Custom_Disclosure',
                initialDate: selectedValuesFromDateTime[id],
                disclosurId: id);

            setState(() {
              if (selectedValuesFromDateTime[id] != null) {
                dateText = DateFormat('yyyy-MM-dd')
                    .format(selectedValuesFromDateTime[id])
                    .toString();
                setState(() {});
              } else {
                dateText = 'Select Date';
              }
              int index = formDatavalues.indexWhere(
                  (formData) => formData.custom_disclosure_id == id);
              if (index != -1) {
                // If FormData object with matching disclosureName is found, update its value
                formDatavalues[index] = formDatavalues[index] = FormData(
                    custom_disclosure_id: id,
                    type: type,
                    value: selectedValuesFromDateTime[id]);
              } else {
                // If FormData object with matching disclosureName is not found, add a new FormData object
                formDatavalues.add(FormData(
                    custom_disclosure_id: id,
                    type: type,
                    value: selectedValuesFromDateTime[id]));
              }
            });
          },
          decoration: InputDecoration(
            labelText: '$dateText',
            suffixIcon: IconButton(
              onPressed: () async {
                await _selectDate(context,
                    from: 'Custom_Disclosure',
                    initialDate: selectedValuesFromDateTime[id],
                    disclosurId: id);

                setState(() {
                  if (selectedValuesFromDateTime[id] != null) {
                    dateText = DateFormat('yyyy-MM-dd')
                        .format(selectedValuesFromDateTime[id])
                        .toString();
                  } else {
                    dateText = 'Select Date';
                  }
                });
              },
              icon: const Icon(Icons.calendar_today),
            ),
          ),
        );
      case 'location':
        String locationText = 'Current Location';
        if (selectedValuesFromLocation[id] != null) {
          locationText =
              '${selectedValuesFromLocation[id][0]}, ${selectedValuesFromLocation[id][1]}';
        } else {
          locationText = 'Current Location';
        }
        return TextField(
          controller: _locationController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Current Location',
            suffixIcon: IconButton(
              icon: _locationIsLoading
                  ? Container(
                      height: 10,
                      width: 10,
                      child: const CircularProgressIndicator(
                        strokeAlign: 0.2,
                        strokeWidth: 2,
                      ),
                    )
                  : const CircleAvatar(
                      backgroundColor: Colors.black,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.white,
                      )),
              onPressed: () {
                _getCurrentLocation();
                _getCurrentLocation(disclosurId: id);
                setState(() {
                  setState(() {
                    int index = formDatavalues.indexWhere(
                        (formData) => formData.custom_disclosure_id == id);
                    if (index != -1) {
                      // If FormData object with matching disclosureName is found, update its value
                      formDatavalues[index] = formDatavalues[index] = FormData(
                          custom_disclosure_id: id,
                          type: type,
                          value: selectedValuesFromLocation[id]);
                    } else {
                      // If FormData object with matching disclosureName is not found, add a new FormData object
                      formDatavalues.add(FormData(
                          custom_disclosure_id: id,
                          type: type,
                          value: selectedValuesFromLocation[id]));
                    }
                    _locationIsLoading = true;
                    _locationIsLoading = true;
                  });
                });
              },
            ),
          ),
        );
      case 'dropdown+text':
        final List<dynamic> valueList =
            List<dynamic>.from(disclosure[index].valueList);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              child: DropdownButton<dynamic>(
                value: selectedValuesFromDropDownText[id] != null
                    ? selectedValuesFromDropDownText[id]['value_dropdown']
                    : null,
                hint: const Text('select options'),
                items: valueList.map((value) {
                  return DropdownMenuItem<dynamic>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (dynamic selectedValue) {
                  setState(() {
                    selectedValuesFromDropDownText[id] = {
                      'value_string': selectedValuesFromDropDownText[id] != null
                          ? selectedValuesFromDropDownText[id]['value_string']
                          : '',
                      'value_dropdown': selectedValue,
                    };

                    int index = formDatavalues.indexWhere(
                        (formData) => formData.custom_disclosure_id == id);
                    if (index != -1) {
                      // If FormData object with matching disclosureName is found, update its value
                      formDatavalues[index] = formDatavalues[index] = FormData(
                          custom_disclosure_id: id,
                          type: type,
                          value: selectedValuesFromDropDownText[id]);
                    } else {
                      // If FormData object with matching disclosureName is not found, add a new FormData object
                      formDatavalues.add(FormData(
                          custom_disclosure_id: id,
                          type: type,
                          value: selectedValuesFromDropDownText[id]));
                    }
                  });
                },
              ),
            ),
            TextFormField(
              decoration: const InputDecoration(hintText: 'Enter a text input'),
              onChanged: (value) {
                selectedValuesFromDropDownText[id] = {
                  'value_string': value,
                  'value_dropdown': selectedValuesFromDropDownText[id] != null
                      ? selectedValuesFromDropDownText[id]['value_dropdown']
                      : '',
                };

                // Find the index of the FormData object with the matching disclosureName
                int index = formDatavalues.indexWhere(
                    (formData) => formData.custom_disclosure_id == id);
                if (index != -1) {
                  // If FormData object with matching disclosureName is found, update its value
                  formDatavalues[index] = FormData(
                      custom_disclosure_id: id,
                      type: type,
                      value: selectedValuesFromDropDownText[id]);
                } else {
                  // If FormData object with matching disclosureName is not found, add a new FormData object
                  formDatavalues.add(FormData(
                      custom_disclosure_id: id,
                      type: type,
                      value: selectedValuesFromDropDownText[id]));
                }
              },
            )
          ],
        );
      case 'gallery':
        // bool isAvailable = false;
        // int imageindex = 0;
        // for (var field in formDatavalues) {
        //   if (field.custom_disclosure_id == id) {
        //     isAvailable = true;
        //   }
        // }
        // int ii = 0;
        // for (ii = 0; ii < formDatavalues.length; ii++) {
        //   if (formDatavalues[ii].custom_disclosure_id == id) {
        //     isAvailable = true;
        //     imageindex = ii;
        //   }
        // }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await _pickImage();
                      // if (_image != null) {
                      selectedValuesFromImage[id] = imagePaths;
                      int index = formDatavalues.indexWhere(
                          (formData) => formData.custom_disclosure_id == id);
                      if (index != -1) {
                        // If FormData object with matching disclosureName is found, update its value
                        formDatavalues[index] = formDatavalues[index] =
                            FormData(
                                custom_disclosure_id: id,
                                type: type,
                                value: selectedValuesFromImage[id]);
                      } else {
                        // If FormData object with matching disclosureName is not found, add a new FormData object
                        formDatavalues.add(FormData(
                            custom_disclosure_id: id,
                            type: type,
                            value: selectedValuesFromImage[id]));
                      }
                      // }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.attach_file),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _imagePathController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: 'Image Path',
                        // prefix: IconButton(
                        //     icon: Icon(Icons.attach_file),
                        //     onPressed: () {
                        //       setState(() async {
                        //         await getImage();
                        //         if (_image != null) {
                        //           selectedValuesFromImage[id] = [_image?.path];
                        //           int index = formDatavalues.indexWhere(
                        //               (formData) =>
                        //                   formData.custom_disclosure_id == id);
                        //           if (index != -1) {
                        //             // If FormData object with matching disclosureName is found, update its value
                        //             formDatavalues[index] =
                        //                 formDatavalues[index] = FormData(
                        //                     custom_disclosure_id: id,
                        //                     type: type,
                        //                     value: selectedValuesFromImage[id]);
                        //           } else {
                        //             // If FormData object with matching disclosureName is not found, add a new FormData object
                        //             formDatavalues.add(FormData(
                        //                 custom_disclosure_id: id,
                        //                 type: type,
                        //                 value: selectedValuesFromImage[id]));
                        //           }
                        //         }
                        //       });
                        //     }),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _image = null;
                              _imagePathController.clear();
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const Text('or'),
                  const SizedBox(
                    width: 4,
                  ),
                  InkWell(
                    onTap: () {
                      _takePicture();
                      selectedValuesFromImage[id] = imagePaths;
                      int index = formDatavalues.indexWhere(
                          (formData) => formData.custom_disclosure_id == id);
                      if (index != -1) {
                        // If FormData object with matching disclosureName is found, update its value
                        formDatavalues[index] = formDatavalues[index] =
                            FormData(
                                custom_disclosure_id: id,
                                type: type,
                                value: selectedValuesFromImage[id]);
                      } else {
                        // If FormData object with matching disclosureName is not found, add a new FormData object
                        formDatavalues.add(FormData(
                            custom_disclosure_id: id,
                            type: type,
                            value: selectedValuesFromImage[id]));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      color: Colors.black,
                      child: const Text(
                        'USE CAMERA',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  )
                ],
              ),
            ),
            // if (formDatavalues[index].value != null &&
            //     formDatavalues[index].value)
            GridView.builder(
              itemCount:
                  imagePaths.length, //formDatavalues[index].value?.length,
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemBuilder: (context, index1) {
                return Stack(
                  children: <Widget>[
                    Image.file(
                      File(imagePaths[index1]),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: IconButton(
                        icon: Icon(Icons.delete_forever_sharp),
                        color: Colors.black,
                        onPressed: () {
                          _removeImage(index1);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: 20),
          ],
        );
      case 'unique_id':
        return Column(
          children: [
            TypeAheadField(
              controller: autoCompleteTextFieldController[id],
              builder: (context, controller, focusNode) => CupertinoTextField(
                controller: controller,
                focusNode: focusNode,
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.white)),
                // autofocus: true,
                padding: const EdgeInsets.all(12),
                placeholder: 'Enter a new value or select an existing value',
              ),
              itemBuilder: (context, suggestion) {
                return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(suggestion['title']),
                    ));
              },
              onSelected: (item) {
                setState(() {
                  autoCompleteTextFieldController[id] =
                      TextEditingController(text: item['title']);
                  selectedValuesFromUniqueId[id] = item;
                  int index = formDatavalues.indexWhere(
                      (formData) => formData.custom_disclosure_id == id);
                  if (index != -1) {
                    // If FormData object with matching disclosureName is found, update its value
                    formDatavalues[index] = formDatavalues[index] = FormData(
                        custom_disclosure_id: id,
                        type: type,
                        value: selectedValuesFromUniqueId[id]);
                  } else {
                    // If FormData object with matching disclosureName is not found, add a new FormData object
                    formDatavalues.add(FormData(
                        custom_disclosure_id: id,
                        type: type,
                        value: selectedValuesFromUniqueId[id]));
                  }
                });
              },
              suggestionsCallback: (search) {
                return Future<List>.delayed(
                  const Duration(milliseconds: 300),
                  () => disclosure[index].valueList.where((suggestion) {
                    return suggestion['title']
                        .toString()
                        .toLowerCase()
                        .contains(search.toLowerCase());
                  }).toList(),
                );
              },
            ),
            const Divider(
              color: Colors.black,
            )
          ],
        );
      // return AutoCompleteTextField(
      //   decoration: const InputDecoration(
      //       hintText: "Enter a new value or select an existing value"),
      //   clearOnSubmit: false,
      //   textChanged: (item) {
      //     setState(() {
      //       selectedValuesFromUniqueId[id] = {
      //         'value': item,
      //       };
      //       int index = formDatavalues.indexWhere(
      //           (formData) => formData.custom_disclosure_id == id);
      //       if (index != -1) {
      //         // If FormData object with matching disclosureName is found, update its value
      //         formDatavalues[index] = formDatavalues[index] = FormData(
      //             custom_disclosure_id: id,
      //             type: type,
      //             value: selectedValuesFromUniqueId[id]);
      //       } else {
      //         // If FormData object with matching disclosureName is not found, add a new FormData object
      //         formDatavalues.add(FormData(
      //             custom_disclosure_id: id,
      //             type: type,
      //             value: selectedValuesFromUniqueId[id]));
      //       }
      //     });
      //   },
      //   itemSubmitted: (item) {
      //     setState(() {
      //       selectedValuesFromUniqueId[id] = {
      //         'value': item,
      //       };
      //       int index = formDatavalues.indexWhere(
      //           (formData) => formData.custom_disclosure_id == id);
      //       if (index != -1) {
      //         // If FormData object with matching disclosureName is found, update its value
      //         formDatavalues[index] = formDatavalues[index] = FormData(
      //             custom_disclosure_id: id,
      //             type: type,
      //             value: selectedValuesFromUniqueId[id]);
      //       } else {
      //         // If FormData object with matching disclosureName is not found, add a new FormData object
      //         formDatavalues.add(FormData(
      //             custom_disclosure_id: id,
      //             type: type,
      //             value: selectedValuesFromUniqueId[id]));
      //       }
      //     });
      //   },
      //   key: autoCompleteTextFieldKeys[id],
      //   suggestions: disclosure[index].valueList,
      //   itemBuilder: (context, suggestion) => Padding(
      //       padding: const EdgeInsets.all(8.0),
      //       child: ListTile(
      //         title: Text(suggestion['title']),
      //       )),
      //   itemSorter: (a, b) => a['title']
      //       .toString()
      //       .toLowerCase()
      //       .compareTo(b['title'].toString().toLowerCase()),
      //   itemFilter: (suggestion, input) => suggestion['title']
      //       .toString()
      //       .toLowerCase()
      //       .contains(input.toLowerCase()),
      // );

      // final List valueList = List.from(disclosure[index].valueList);

      // return AutoCompleteTextField(
      //   decoration: const InputDecoration(
      //       hintText: "Enter a new value or select an existing value"),
      //   textChanged: (item) {
      //     setState(() {
      //       selectedValuesFromUniqueId[id] = {
      //         'value': item,
      //       };
      //       int index = formDatavalues.indexWhere(
      //           (formData) => formData.custom_disclosure_id == id);
      //       if (index != -1) {
      //         // If FormData object with matching disclosureName is found, update its value
      //         formDatavalues[index] = formDatavalues[index] = FormData(
      //             custom_disclosure_id: id,
      //             type: type,
      //             value: selectedValuesFromUniqueId[id]);
      //       } else {
      //         // If FormData object with matching disclosureName is not found, add a new FormData object
      //         formDatavalues.add(FormData(
      //             custom_disclosure_id: id,
      //             type: type,
      //             value: selectedValuesFromUniqueId[id]));
      //       }
      //     });
      //   },
      //   itemSubmitted: (item) {
      //     setState(() {
      //       selectedValuesFromUniqueId[id] = {
      //         'value': item,
      //       };
      //       int index = formDatavalues.indexWhere(
      //           (formData) => formData.custom_disclosure_id == id);
      //       if (index != -1) {
      //         // If FormData object with matching disclosureName is found, update its value
      //         formDatavalues[index] = formDatavalues[index] = FormData(
      //             custom_disclosure_id: id,
      //             type: type,
      //             value: selectedValuesFromUniqueId[id]);
      //       } else {
      //         // If FormData object with matching disclosureName is not found, add a new FormData object
      //         formDatavalues.add(FormData(
      //             custom_disclosure_id: id,
      //             type: type,
      //             value: selectedValuesFromUniqueId[id]));
      //       }
      //     });
      //   },
      //   key: autokey,
      //   suggestions: valueList,
      //   itemBuilder: (context, suggestion) => Padding(
      //       padding: const EdgeInsets.all(8.0),
      //       child: ListTile(
      //           title: Text(suggestion), trailing: Text(suggestion))),
      //   itemSorter: (a, b) =>
      //       a.toString().toLowerCase().compareTo(b.toString().toLowerCase()),
      //   itemFilter: (suggestion, input) => suggestion
      //       .toString()
      //       .toLowerCase()
      //       .startsWith(input.toLowerCase()),
      // );
      case 'computed':
        List<ComputedDisclosureModel> formula =
            disclosure[index].computedDisclosureFormula ?? [];
        var answer = 0.0;
        answer = formComputedDisclosure(formula, id, type);

        return answer != 0.0
            ? Text(
                '$answer',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
              )
            : ListView.builder(
                itemCount: formula.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Center(child: buildFormulaItem(formula[index]));
                });

      default:
        return Container(
          height: 20,
        ); // Default case, return an empty container
    }
  }

  double formComputedDisclosure(
      List<ComputedDisclosureModel> formula, String id, String type) {
    var answer = 0.0;
    String? currentOperator;

    for (var value in formula) {
      var selectedData = formDatavalues.firstWhereOrNull(
          (element) => element.custom_disclosure_id == value.disclosureId);

      if (selectedData != null) {
        double selectedDataValue =
            (double.tryParse(selectedData.value.toString()) ?? 0);
        if (answer == 0) {
          answer += selectedDataValue;
        }
        if ((currentOperator ?? '').isNotEmpty) {
          answer = calculateComputedDisclosure(
              currentOperator, answer, selectedDataValue);
          currentOperator = null;
        }
        if (selectedDataValue == 0.0) {
          answer = 0.0;
          break;
        }
      } else if (value.operator != null && (value.operator ?? '').isNotEmpty) {
        currentOperator = value.operator;
      } else if (value.type == 'constant' && (value.value ?? '').isNotEmpty) {
        answer = calculateComputedDisclosure(currentOperator, answer,
            (double.tryParse(value.value.toString()) ?? 0));
        currentOperator = null;
      }
    }
    int index = formDatavalues
        .indexWhere((formData) => formData.custom_disclosure_id == id);
    if (answer != 0.0) {
      if (index != -1) {
        // If FormData object with matching disclosureName is found, update its value
        formDatavalues[index] = formDatavalues[index] =
            FormData(custom_disclosure_id: id, type: type, value: answer);
      } else {
        // If FormData object with matching disclosureName is not found, add a new FormData object
        formDatavalues
            .add(FormData(custom_disclosure_id: id, type: type, value: answer));
      }
    } else {
      if (index != -1) {
        formDatavalues.removeAt(index);
      }
    }

    return answer;
  }

  double calculateComputedDisclosure(
      String? currentOperator, double answer, double selectedDataValue) {
    switch (currentOperator) {
      case 'add':
        answer += selectedDataValue;
        break;
      case 'division':
        answer = answer / selectedDataValue;
        break;
      case 'multiply':
        answer = answer * selectedDataValue;
        break;
      case 'subtract':
        answer = answer - selectedDataValue;
        break;
      default:
        answer += selectedDataValue;
        break;
    }
    return answer;
  }

  Widget buildFormulaItem(ComputedDisclosureModel computedDisclosure) {
    switch (computedDisclosure.type) {
      case 'custom':
        CustomDisclosure? selectedDisclosure = formDetailList[0]
            .customDisclosures
            .firstWhereOrNull(
                (element) => element.id == computedDisclosure.disclosureId);
        return Text(
          selectedDisclosure?.disclosureName ?? '',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black,
          ),
        );
      case 'constant':
        return Text(
          'Constant ${computedDisclosure.value ?? ''}',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black,
          ),
        );
      default:
        if (computedDisclosure.operator != null &&
            (computedDisclosure.operator ?? '').isNotEmpty) {
          return buildOperatorItem(computedDisclosure.operator);
        }
        return Container();
    }
  }

  Widget buildOperatorItem(String? operator) {
    switch (operator) {
      case 'add':
        return const Icon(Icons.add_circle);
      case 'division':
        return const Divider();
      case 'multiply':
        return const Icon(Icons.close);
      case 'subtract':
        return const Icon(Icons.minimize);
      default:
        return Container();
    }
  }

  Widget _buildCircularDropdownButton({
    required ValueChanged<String?> onChanged,
    required Array,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 3),
      child: DropdownButtonFormField<String>(
        items: ["option"]
            .map((option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ))
            .toList(),
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: 'select an option',
          //contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
          //border: InputBorder.none,
        ),
      ),
    );
  }
}

class CustomDashedDivider extends StatelessWidget {
  final double height;
  final double dashWidth;
  final double dashSpace;
  final Color color;

  const CustomDashedDivider({
    this.height = 1.0,
    this.dashWidth = 5.0,
    this.dashSpace = 5.0,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: dashSpace),
        Expanded(
          child: Container(
            height: height,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: height,
                  color: color,
                  style: BorderStyle.solid,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: dashSpace),
      ],
    );
  }
}

class ExpandableListItem extends StatefulWidget {
  final String title;
  final List<Widget> children;

  ExpandableListItem({required this.title, required this.children});

  @override
  _ExpandableListItemState createState() => _ExpandableListItemState();
}

class _ExpandableListItemState extends State<ExpandableListItem> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(blurRadius: 2, color: Colors.grey, spreadRadius: 1)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.center,
            height: 70,
            color:
                _isExpanded ? Color.fromARGB(255, 236, 235, 235) : Colors.white,
            child: ListTile(
              title: Text(
                widget.title,
                style: TextStyle(color: Colors.black, fontSize: 18),
              ),
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              trailing: Container(
                height: 30,
                width: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color.fromARGB(255, 216, 209, 188)),
                child: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
              ),
            ),
          ),
          if (_isExpanded) ...widget.children,
        ],
      ),
    );
  }
}

class ExpandableListSubmission extends StatefulWidget {
  final String title;
  final String id;
  final String itemId;

  ExpandableListSubmission(
      {required this.title, required this.id, required this.itemId});

  @override
  _ExpandableListSubmissionState createState() =>
      _ExpandableListSubmissionState();
}

class _ExpandableListSubmissionState extends State<ExpandableListSubmission> {
  bool _isExpanded = false;
  bool isLoading = false;
  final DetailSubmitedFormData _detailFormSubmitted =
      Get.find<DetailSubmitedFormData>();
  List<ItemSubmission> formDetailList = [];

  getFormDetails(id, itemId) async {
    setState(() {
      formDetailList.clear();
      isLoading = true;
      //_formDataController.data.value.tagList.clear();
    });
    formDetailList =
        await _detailFormSubmitted.getsubmitedFormDetail(id, itemId);
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildFormField(List<CustomDisclosureSubmission> disclosure, index) {
    final String type = disclosure[index].type ?? '';

    switch (type) {
      case 'string':
        return TextFormField(
          autofocus: false,
          decoration: const InputDecoration(
            hintText: 'Enter a text input',
            labelStyle:
                TextStyle(color: Colors.grey), // Grey text color for label
            hintStyle:
                TextStyle(color: Colors.grey), // Grey text color for hint
            // Remove bottom line color on selection
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide.none),
            // Style for disabled text color (grey)
            disabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
          initialValue: disclosure[index].value,
          readOnly: true,
          enabled: false,
        );
      case 'number':
        return TextFormField(
          decoration: const InputDecoration(
              hintText: 'Enter a number',
              labelStyle:
                  TextStyle(color: Colors.grey), // Grey text color for label
              hintStyle:
                  TextStyle(color: Colors.grey), // Grey text color for hint
              // Remove bottom line color on selection
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide.none),
              // Style for disabled text color (grey)
              disabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusColor: Colors.grey),
          keyboardType: TextInputType.number,
          initialValue: "${disclosure[index].value ?? ''}",
          autofocus: false,
          enabled: false,
          readOnly: true,
        );

      case 'tags':
        List selectedTags = disclosure[index].value ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: selectedTags.map((tag) {
                return Chip(
                  backgroundColor: Colors.grey,
                  label: Text(
                    tag,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  onDeleted: () {},
                );
              }).toList(),
            ),
          ],
        );
      case 'radio':
        final List<dynamic> valueList =
            List<dynamic>.from(disclosure[index].valueList ?? []);
        return Column(
          children: valueList.map((value) {
            return RadioListTile<dynamic>(
              title: Text(value.toString()),
              value: value,
              activeColor: Colors.grey,
              groupValue: disclosure[index].value,
              onChanged: (dynamic newValue) {},
            );
          }).toList(),
        );

      case 'checkbox':
        final List<dynamic> valueList =
            List<dynamic>.from(disclosure[index].valueList ?? []);
        return Column(
          children: valueList.map((value) {
            return CheckboxListTile(
              title: Text(value.toString()),
              activeColor: Colors.grey,
              value: (disclosure[index].value ?? []).contains(value),
              onChanged: (bool? newValue) {},
            );
          }).toList(),
        );
      case 'dropdown':
        final List<dynamic> valueList =
            List<dynamic>.from(disclosure[index].valueList ?? []);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<dynamic>(
              value: disclosure[index].value,
              dropdownColor:
                  Colors.grey[200], // Set dropdown color to light grey
              iconEnabledColor: Colors.grey,
              hint: Text('select options'),
              items: valueList.map((value) {
                return DropdownMenuItem<dynamic>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }).toList(),
              onChanged: (dynamic selectedValue) {},
            ),
          ],
        );
      case 'date':
        return TextFormField(
          initialValue: "${disclosure[index].value ?? ''}",
          readOnly: true,
          enabled: false,
          decoration: const InputDecoration(
            labelText: 'Select Dates',
            suffixIcon: Icon(Icons.calendar_today),
          ),
        );
      case 'location':
        return TextFormField(
          initialValue: "${disclosure[index].value ?? ''}",
          readOnly: true,
          enabled: false,
          decoration: const InputDecoration(
            hintText: 'Current Location',
            suffixIcon: CircleAvatar(
                backgroundColor: Colors.black,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                )),
          ),
        );
      case 'dropdown+text':
        final List<dynamic> valueList =
            List<dynamic>.from(disclosure[index].valueList ?? []);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<dynamic>(
              value: disclosure[index].value != null
                  ? disclosure[index].value['value_dropdown']
                  : null,
              hint: const Text('select options'),
              dropdownColor:
                  Colors.grey[200], // Set dropdown color to light grey
              iconEnabledColor: Colors.grey,
              items: valueList.map((value) {
                return DropdownMenuItem<dynamic>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }).toList(),
              onChanged: (dynamic selectedValue) {},
              enableFeedback: false,
            ),
            TextFormField(
              initialValue:
                  "${disclosure[index].value != null ? disclosure[index].value['value_string'] ?? '' : ''}",
              readOnly: true,
              enabled: false,
              decoration: const InputDecoration(hintText: 'Enter a text input'),
            )
          ],
        );
      // // case 'gallery':
      // //   return Column(
      // //     mainAxisAlignment: MainAxisAlignment.center,
      // //     children: <Widget>[
      // //       _image == null
      // //           ? Text('No image selected.')
      // //           : Container(
      // //               height: 150,
      // //               width: 200,
      // //               child: Image.file(
      // //                 _image!,
      // //                 fit: BoxFit.fill,
      // //               )),
      // //       const SizedBox(height: 20),
      // //       GestureDetector(
      // //         onTap: getImage,
      // //         child: const Row(
      // //           mainAxisAlignment: MainAxisAlignment.center,
      // //           children: [
      // //             Icon(Icons.attach_file),
      // //             SizedBox(width: 10),
      // //             Text('Attach Image'),
      // //           ],
      // //         ),
      // //       ),
      // //       SizedBox(height: 20),
      // //       Padding(
      // //         padding: EdgeInsets.symmetric(horizontal: 20),
      // //         child: TextField(
      // //           controller: _imagePathController,
      // //           readOnly: true,
      // //           decoration: InputDecoration(
      // //             hintText: 'Image Path',
      // //             suffixIcon: IconButton(
      // //               icon: Icon(Icons.clear),
      // //               onPressed: () {
      // //                 setState(() {
      // //                   _image = null;
      // //                   _imagePathController.clear();
      // //                 });
      // //               },
      // //             ),
      // //           ),
      // //         ),
      // //       ),
      // //     ],
      // //   );
      case 'unique_id':
        // final List valueList = List.from(disclosure[index].valueList);
        String uniqueId = '';
        if (disclosure[index].value != null) {
          uniqueId =
              '${disclosure[index].value['id'].toString() ?? ''} - ${disclosure[index].value['value'] ?? ''}';
        }

        return TextFormField(
          initialValue: uniqueId,
          readOnly: true,
          enabled: false,
          decoration: const InputDecoration(
              hintText: "Enter a new value or select an existing value"),
        );
      case 'computed':
        return TextFormField(
          initialValue: "${disclosure[index].value ?? ''}",
          readOnly: true,
          enabled: false,
        );
      case 'gallery':
        return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              disclosure[index].value == null
                  ? const Text('No image found.')
                  : GridView.builder(
                      itemCount: disclosure[index]
                          .value
                          .length, //formDatavalues[index].value?.length,
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 4.0,
                      ),
                      itemBuilder: (context, index1) {
                        return Stack(
                          children: <Widget>[
                            Image.network(
                              disclosure[index].value[index1] ?? '',
                              fit: BoxFit.fill,
                              // width: double.infinity,
                              // height: double.infinity,
                              // loadingBuilder:
                              //     (context, child, loadingProgress) => Center(
                              //         child: Container(
                              //             height: 50,
                              //             width: 50,
                              //             padding: const EdgeInsets.all(10),
                              //             child:
                              //                 const CircularProgressIndicator(
                              //               color: Colors.black,
                              //             ))),
                            ),
                          ],
                        );
                      },
                    ),

              // Container(
              //     height: 120,
              //     width: 150,
              //     child: Image.network(
              //       disclosure[index].value[0].toString()!,
              //       fit: BoxFit.fill,
              //     )),
            ]);

      default:
        return Container(
          height: 20,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
                blurRadius: 2,
                color: Color.fromARGB(255, 168, 160, 160),
                spreadRadius: 1)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.center,
            height: 70,
            color: _isExpanded
                ? const Color.fromARGB(255, 236, 235, 235)
                : Colors.white,
            child: ListTile(
              title: Text(
                widget.title,
                style: TextStyle(color: Colors.black, fontSize: 18),
              ),
              onTap: () async {
                var connectivityResult =
                    await Connectivity().checkConnectivity();
                if (connectivityResult == ConnectivityResult.none) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please check internet connection'),
                    ),
                  );
                } else {
                  setState(() {
                    _isExpanded = !_isExpanded;
                    _isExpanded
                        ? getFormDetails(widget.id, widget.itemId)
                        : null;
                  });
                }
              },
              trailing: Container(
                height: 30,
                width: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color.fromARGB(255, 216, 209, 188)),
                child: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
              ),
            ),
          ),
          _isExpanded == true
              ? Container(
                  child: isLoading
                      ? Center(
                          child: Container(
                              height: 50,
                              width: 50,
                              padding: EdgeInsets.all(10),
                              child: const CircularProgressIndicator(
                                color: Colors.black,
                              )))
                      : formDetailList.length == 0
                          ? Container(
                              padding: EdgeInsets.all(5),
                              alignment: Alignment.center,
                              child: const Text('No data'))
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: formDetailList[0]
                                  .customDisclosureSubmissions
                                  .length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                List<CustomDisclosureSubmission>
                                    customDisclosure = formDetailList[0]
                                        .customDisclosureSubmissions;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: customDisclosure[index]
                                                .disclosureName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color.fromARGB(
                                                  255, 167, 160, 64),
                                            ),
                                          ),
                                          const TextSpan(
                                            text: ' : ',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color.fromARGB(
                                                  255, 167, 160, 64),
                                            ),
                                          ),
                                          TextSpan(
                                            text: customDisclosure[index]
                                                .disclosure,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black),
                                          ),
                                          customDisclosure[index].timer ==
                                                  'unlimited'
                                              ? const TextSpan(
                                                  text:
                                                      ' [Unlimited Submissions]',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black),
                                                )
                                              : customDisclosure[index].timer ==
                                                      'computed'
                                                  ? const TextSpan(
                                                      text: ' [computed]',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.black),
                                                    )
                                                  : const TextSpan(
                                                      text: '[]',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.black),
                                                    )
                                        ],
                                      ),
                                    ),
                                    buildFormField(customDisclosure, index),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ],
                                );
                              },
                            ))
              : Container()
        ],
      ),
    );
  }
}

class ExpandableListOfflineSubmission extends StatefulWidget {
  final String title;

  ExpandableListOfflineSubmission({
    required this.title,
  });

  @override
  _ExpandableListSubmissionState createState() =>
      _ExpandableListSubmissionState();
}

class _ExpandableListOfflineSubmissionState
    extends State<ExpandableListOfflineSubmission> {
  bool _isExpanded = false;
  bool isLoading = false;
  List<ItemSubmission> formDetailList = [];

  Widget buildFormField(List<CustomDisclosureSubmission> disclosure, index) {
    final String type = disclosure[index].type ?? '';

    switch (type) {
      case 'string':
        return TextFormField(
          autofocus: false,
          decoration: const InputDecoration(
            hintText: 'Enter a text input',
            labelStyle:
                TextStyle(color: Colors.grey), // Grey text color for label
            hintStyle:
                TextStyle(color: Colors.grey), // Grey text color for hint
            // Remove bottom line color on selection
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide.none),
            // Style for disabled text color (grey)
            disabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
          initialValue: disclosure[index].value,
          readOnly: true,
          enabled: false,
        );
      case 'number':
        return TextFormField(
          decoration: const InputDecoration(
              hintText: 'Enter a number',
              labelStyle:
                  TextStyle(color: Colors.grey), // Grey text color for label
              hintStyle:
                  TextStyle(color: Colors.grey), // Grey text color for hint
              // Remove bottom line color on selection
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide.none),
              // Style for disabled text color (grey)
              disabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusColor: Colors.grey),
          keyboardType: TextInputType.number,
          initialValue: "${disclosure[index].value ?? ''}",
          autofocus: false,
          enabled: false,
          readOnly: true,
        );

      case 'tags':
        List selectedTags = disclosure[index].value ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: selectedTags.map((tag) {
                return Chip(
                  backgroundColor: Colors.grey,
                  label: Text(
                    tag,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  onDeleted: () {},
                );
              }).toList(),
            ),
          ],
        );
      case 'radio':
        final List<dynamic> valueList =
            List<dynamic>.from(disclosure[index].valueList ?? []);
        return Column(
          children: valueList.map((value) {
            return RadioListTile<dynamic>(
              title: Text(value.toString()),
              value: value,
              activeColor: Colors.grey,
              groupValue: disclosure[index].value,
              onChanged: (dynamic newValue) {},
            );
          }).toList(),
        );

      case 'checkbox':
        final List<dynamic> valueList =
            List<dynamic>.from(disclosure[index].valueList ?? []);
        return Column(
          children: valueList.map((value) {
            return CheckboxListTile(
              title: Text(value.toString()),
              activeColor: Colors.grey,
              value: (disclosure[index].value ?? []).contains(value),
              onChanged: (bool? newValue) {},
            );
          }).toList(),
        );
      case 'dropdown':
        final List<dynamic> valueList =
            List<dynamic>.from(disclosure[index].valueList ?? []);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<dynamic>(
              value: disclosure[index].value,
              dropdownColor:
                  Colors.grey[200], // Set dropdown color to light grey
              iconEnabledColor: Colors.grey,
              hint: Text('select options'),
              items: valueList.map((value) {
                return DropdownMenuItem<dynamic>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }).toList(),
              onChanged: (dynamic selectedValue) {},
            ),
          ],
        );
      case 'date':
        return TextFormField(
          initialValue: "${disclosure[index].value ?? ''}",
          readOnly: true,
          enabled: false,
          decoration: const InputDecoration(
            labelText: 'Select Dates',
            suffixIcon: Icon(Icons.calendar_today),
          ),
        );
      case 'location':
        return TextFormField(
          initialValue: "${disclosure[index].value ?? ''}",
          readOnly: true,
          enabled: false,
          decoration: const InputDecoration(
            hintText: 'Current Location',
            suffixIcon: CircleAvatar(
                backgroundColor: Colors.black,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                )),
          ),
        );
      case 'dropdown+text':
        final List<dynamic> valueList =
            List<dynamic>.from(disclosure[index].valueList ?? []);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<dynamic>(
              value: disclosure[index].value != null
                  ? disclosure[index].value['value_dropdown']
                  : null,
              hint: const Text('select options'),
              dropdownColor:
                  Colors.grey[200], // Set dropdown color to light grey
              iconEnabledColor: Colors.grey,
              items: valueList.map((value) {
                return DropdownMenuItem<dynamic>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }).toList(),
              onChanged: (dynamic selectedValue) {},
              enableFeedback: false,
            ),
            TextFormField(
              initialValue:
                  "${disclosure[index].value != null ? disclosure[index].value['value_string'] ?? '' : ''}",
              readOnly: true,
              enabled: false,
              decoration: const InputDecoration(hintText: 'Enter a text input'),
            )
          ],
        );
      // // case 'gallery':
      // //   return Column(
      // //     mainAxisAlignment: MainAxisAlignment.center,
      // //     children: <Widget>[
      // //       _image == null
      // //           ? Text('No image selected.')
      // //           : Container(
      // //               height: 150,
      // //               width: 200,
      // //               child: Image.file(
      // //                 _image!,
      // //                 fit: BoxFit.fill,
      // //               )),
      // //       const SizedBox(height: 20),
      // //       GestureDetector(
      // //         onTap: getImage,
      // //         child: const Row(
      // //           mainAxisAlignment: MainAxisAlignment.center,
      // //           children: [
      // //             Icon(Icons.attach_file),
      // //             SizedBox(width: 10),
      // //             Text('Attach Image'),
      // //           ],
      // //         ),
      // //       ),
      // //       SizedBox(height: 20),
      // //       Padding(
      // //         padding: EdgeInsets.symmetric(horizontal: 20),
      // //         child: TextField(
      // //           controller: _imagePathController,
      // //           readOnly: true,
      // //           decoration: InputDecoration(
      // //             hintText: 'Image Path',
      // //             suffixIcon: IconButton(
      // //               icon: Icon(Icons.clear),
      // //               onPressed: () {
      // //                 setState(() {
      // //                   _image = null;
      // //                   _imagePathController.clear();
      // //                 });
      // //               },
      // //             ),
      // //           ),
      // //         ),
      // //       ),
      // //     ],
      // //   );
      case 'unique_id':
        // final List valueList = List.from(disclosure[index].valueList);
        String uniqueId = '';
        if (disclosure[index].value != null) {
          uniqueId =
              '${disclosure[index].value['id'].toString() ?? ''} - ${disclosure[index].value['value'] ?? ''}';
        }

        return TextFormField(
          initialValue: uniqueId,
          readOnly: true,
          enabled: false,
          decoration: const InputDecoration(
              hintText: "Enter a new value or select an existing value"),
        );
      case 'computed':
        return TextFormField(
          initialValue: "${disclosure[index].value ?? ''}",
          readOnly: true,
          enabled: false,
        );
      case 'gallery':
        return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              disclosure[index].value == null
                  ? const Text('No image found.')
                  : GridView.builder(
                      itemCount: disclosure[index]
                          .value
                          .length, //formDatavalues[index].value?.length,
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 4.0,
                      ),
                      itemBuilder: (context, index1) {
                        return Stack(
                          children: <Widget>[
                            Image.network(
                              disclosure[index].value[index1] ?? '',
                              fit: BoxFit.fill,
                              // width: double.infinity,
                              // height: double.infinity,
                              // loadingBuilder:
                              //     (context, child, loadingProgress) => Center(
                              //         child: Container(
                              //             height: 50,
                              //             width: 50,
                              //             padding: const EdgeInsets.all(10),
                              //             child:
                              //                 const CircularProgressIndicator(
                              //               color: Colors.black,
                              //             ))),
                            ),
                          ],
                        );
                      },
                    ),

              // Container(
              //     height: 120,
              //     width: 150,
              //     child: Image.network(
              //       disclosure[index].value[0].toString()!,
              //       fit: BoxFit.fill,
              //     )),
            ]);

      default:
        return Container(
          height: 20,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
                blurRadius: 2,
                color: Color.fromARGB(255, 168, 160, 160),
                spreadRadius: 1)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.center,
            height: 70,
            color: _isExpanded
                ? const Color.fromARGB(255, 236, 235, 235)
                : Colors.white,
            child: ListTile(
              title: Text(
                widget.title,
                style: TextStyle(color: Colors.black, fontSize: 18),
              ),
              onTap: () async {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              trailing: Container(
                height: 30,
                width: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color.fromARGB(255, 216, 209, 188)),
                child: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
              ),
            ),
          ),
          // _isExpanded == true
          //     ? Container(
          //         child: isLoading
          //             ? Center(
          //                 child: Container(
          //                     height: 50,
          //                     width: 50,
          //                     padding: EdgeInsets.all(10),
          //                     child: const CircularProgressIndicator(
          //                       color: Colors.black,
          //                     )))
          //             : formDetailList.length == 0
          //                 ? Container(
          //                     padding: EdgeInsets.all(5),
          //                     alignment: Alignment.center,
          //                     child: const Text('No data'))
          //                 : ListView.builder(
          //                     padding:
          //                         const EdgeInsets.symmetric(horizontal: 20),
          //                     itemCount: formDetailList[0]
          //                         .customDisclosureSubmissions
          //                         .length,
          //                     shrinkWrap: true,
          //                     physics: const NeverScrollableScrollPhysics(),
          //                     itemBuilder: (context, index) {
          //                       List<CustomDisclosureSubmission>
          //                           customDisclosure = formDetailList[0]
          //                               .customDisclosureSubmissions;

          //                       return Column(
          //                         crossAxisAlignment: CrossAxisAlignment.start,
          //                         children: [
          //                           RichText(
          //                             text: TextSpan(
          //                               children: [
          //                                 TextSpan(
          //                                   text: customDisclosure[index]
          //                                       .disclosureName,
          //                                   style: const TextStyle(
          //                                     fontSize: 14,
          //                                     color: Color.fromARGB(
          //                                         255, 167, 160, 64),
          //                                   ),
          //                                 ),
          //                                 const TextSpan(
          //                                   text: ' : ',
          //                                   style: TextStyle(
          //                                     fontSize: 14,
          //                                     color: Color.fromARGB(
          //                                         255, 167, 160, 64),
          //                                   ),
          //                                 ),
          //                                 TextSpan(
          //                                   text: customDisclosure[index]
          //                                       .disclosure,
          //                                   style: const TextStyle(
          //                                       fontSize: 14,
          //                                       color: Colors.black),
          //                                 ),
          //                                 customDisclosure[index].timer ==
          //                                         'unlimited'
          //                                     ? const TextSpan(
          //                                         text:
          //                                             ' [Unlimited Submissions]',
          //                                         style: TextStyle(
          //                                             fontSize: 12,
          //                                             color: Colors.black),
          //                                       )
          //                                     : customDisclosure[index].timer ==
          //                                             'computed'
          //                                         ? const TextSpan(
          //                                             text: ' [computed]',
          //                                             style: TextStyle(
          //                                                 fontSize: 12,
          //                                                 color: Colors.black),
          //                                           )
          //                                         : const TextSpan(
          //                                             text: '[]',
          //                                             style: TextStyle(
          //                                                 fontSize: 12,
          //                                                 color: Colors.black),
          //                                           )
          //                               ],
          //                             ),
          //                           ),
          //                           buildFormField(customDisclosure, index),
          //                           const SizedBox(
          //                             height: 10,
          //                           ),
          //                         ],
          //                       );
          //                     },
          //                   ))
          //     : Container()
        ],
      ),
    );
  }
}

class FormData {
  final String custom_disclosure_id;
  final dynamic value;
  final String type;

  FormData({
    required this.custom_disclosure_id,
    required this.value,
    required this.type,
  });

  factory FormData.fromJson(Map<String, dynamic> json) {
    return FormData(
      custom_disclosure_id: json['custom_disclosure_id'],
      value: json['value'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    String formattedDate = '';
    if (type == 'date') {
      //formattedDate = '${DateFormat('yyyy-MM-ddTHH:mm:ss.sss').format(value)}Z';
      DateTime formated_date = DateTime.parse(value);
      formattedDate =
          DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').format(formated_date);

      // Add 'Z' at the end to indicate UTC time
      formattedDate += 'Z';
    }
    return {
      'custom_disclosure_id': custom_disclosure_id,
      'type': type,
      'value': type == 'date' ? formattedDate : value,
    };
  }
}
