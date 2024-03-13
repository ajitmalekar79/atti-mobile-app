import 'dart:math';

import 'package:attheblocks/detail_form_page/detail_form_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:number_paginator/number_paginator.dart';
import 'package:pagination_flutter/pagination.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/dashboard_provider.dart';
import '../models/dashboard_data_model.dart';
import '../search_controller/search controller.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<MyItem> homedata_list = [];
  final HomeDataListController _homedataListController =
      Get.find<HomeDataListController>();
  final GetListOnSearchController _getListOnSearchController =
      Get.find<GetListOnSearchController>();
  ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<MyItem> _filteredDataList = [];
  List<String> items = List.generate(100, (index) => 'Item ${index + 1}');
  List<String> _data = [];
  bool isLoading = true;
  int currentPage = 1;
  int itemsPerPage = 10;
  int pagesCount = 1;
  int selectedPage = 1;
  double _menuHeight = 0.0;
  bool _menuOpened = false;
  String selectedFilter = 'Item';
  bool clearVislibility = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    getList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  setSelectedPage(int index) {
    setState(() {
      selectedPage = index;
    });
  }

  void _toggleMenu() {
    setState(() {
      _menuOpened = !_menuOpened;
      _menuHeight = _menuOpened ? 100.0 : 0.0;
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {}
  }

  getList() async {
    _filteredDataList.clear();
    homedata_list =
        await _homedataListController.getList(selectedPage.toString());
    _filteredDataList.addAll(homedata_list);

    if (mounted) {
      setState(() {
        int pageCount = _homedataListController.pageCount;
        int pageSize = _homedataListController.pageSize;
        pagesCount = (pageCount / pageSize).ceil();
        // (_homedataListController.pageCount / _filteredDataList[0].pageSize)
        //     .ceil();
        isLoading = false;
      });
    }
  }

  getSearchList() async {
    isLoading = true;
    clearVislibility = true;
    _filteredDataList.clear();
    homedata_list.clear();
    homedata_list = await _getListOnSearchController.getListOnSearch(
        selectedFilter, _searchController.text, selectedPage);
    _filteredDataList.addAll(homedata_list);

    if (mounted) {
      setState(() {
        int pageCount = _getListOnSearchController.pageCount;
        int pageSize = _getListOnSearchController.pageSize;
        if (pageCount == 0) {
          pagesCount = 1;
          isLoading = false;
        } else {
          pagesCount = (pageCount / pageSize).ceil();
          isLoading = false;
        }
      });
    }
  }

  void _filterUsers(String query) {
    setState(() {
      homedata_list
          .where(
              (user) => user.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _clearUserSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Clear relevant data from SharedPreferences
    await prefs.clear();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
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
                    _toggleMenu();
                  },
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                  )),
            ]),
        body: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _menuHeight,
              color: Colors.black,
              child: ListView(
                children: [
                  InkWell(
                    onTap: () {
                      _toggleMenu();
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
            // Display paginated items
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _filteredDataList.isEmpty
                      ? Text('No data found')
                      : ListView.builder(
                          itemCount: _filteredDataList.length,
                          itemBuilder: (context, index) {
                            String firstLetter =
                                _filteredDataList[index].name.substring(0, 1);
                            Color generateRandomColor() {
                              Random random = Random();
                              int red = 200 +
                                  random.nextInt(
                                      55); // Red component between 200 and 255
                              int green = 200 +
                                  random.nextInt(
                                      55); // Green component between 200 and 255
                              int blue = 200 +
                                  random.nextInt(
                                      55); // Blue component between 200 and 255
                              return Color.fromRGBO(red, green, blue, 1.0);
                            }

                            return InkWell(
                              onTap: () {
                                Get.to(Detail_form_page(
                                  itemId: _filteredDataList[index].itemId,
                                ));
                              },
                              child: Container(
                                height: 150,
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    color: Color.fromARGB(255, 247, 244, 244)),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor:
                                              generateRandomColor(),
                                          child: Text(firstLetter),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.7,
                                          child: Text(
                                            _filteredDataList[index].name,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        )
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Text(
                                          'PROPERTY',
                                          style: TextStyle(fontSize: 10),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          _filteredDataList[index]
                                              .property
                                              .name
                                              .toString(),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black,
                                          ),
                                        )
                                      ],
                                    ),
                                    // ListView.builder(
                                    //     itemCount: tagList.length,
                                    //     scrollDirection: Axis.horizontal,
                                    //     itemBuilder: (context, index) {
                                    //       return Container(
                                    //         padding: const EdgeInsets.all(2),
                                    //         decoration: BoxDecoration(
                                    //             color: const Color.fromARGB(
                                    //                 255, 197, 191, 191),
                                    //             borderRadius:
                                    //                 BorderRadius.circular(5),
                                    //             boxShadow: const [
                                    //               BoxShadow(
                                    //                 blurRadius: 1,
                                    //                 color: Colors.grey,
                                    //               )
                                    //             ]),
                                    //         child: Text(
                                    //           tagList[index],
                                    //           style: const TextStyle(
                                    //               fontSize: 16,
                                    //               color: Colors.black,
                                    //               fontWeight: FontWeight.bold),
                                    //         ),
                                    //       );
                                    //     }),
                                    const SizedBox(
                                      height: 5,
                                    ),

                                    Container(
                                      height: 30, // Adjust height as needed
                                      alignment: Alignment.centerLeft,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        shrinkWrap: true,
                                        itemCount:
                                            _filteredDataList[0].tagList.length,
                                        itemBuilder: (context, index) {
                                          return Container(
                                            padding: const EdgeInsets.all(
                                                2), // Adjust width as needed
                                            margin: EdgeInsets.symmetric(
                                                horizontal: 7),
                                            decoration: BoxDecoration(
                                              color: index % 2 == 0
                                                  ? Colors.grey
                                                  : const Color.fromARGB(
                                                      255, 240, 232, 218),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),

                                            alignment: Alignment.center,
                                            child: Text(
                                              _filteredDataList[0]
                                                  .tagList[index],
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

                                    const SizedBox(
                                      height: 8,
                                    ),
                                    Stack(
                                      children: [
                                        Container(
                                          height: 12,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.85, // Set desired width for the progress bar
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: LinearProgressIndicator(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            backgroundColor:
                                                const Color.fromARGB(
                                                    255, 235, 236, 214),
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                        Color>(
                                                    Color.fromARGB(
                                                        255, 233, 233, 213)),
                                            value: _filteredDataList[index]
                                                    .percentCompleted /
                                                100, // Set progress value (0.0 - 1.0)
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${_filteredDataList[index].percentCompleted.toString()}% completed   ',
                                              style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

            // Paginator widget
            // NumberPaginator(
            //   // by default, the paginator shows numbers as center content
            //   numberPages: items.length,

            //   onPageChange: (int index) {
            //     setState(() {
            //       // _currentPage = index;
            //     });
            //   },
            // )
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          height: 120,
          color: Color.fromARGB(255, 248, 245, 245),
          shadowColor: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Visibility(
                    visible: clearVislibility,
                    child: Container(
                        width: MediaQuery.of(context).size.width * 0.14,
                        height: 44,
                        alignment: Alignment.center,
                        child: TextButton(
                            onPressed: () {
                              getList();
                              setState(() {
                                clearVislibility = false;
                                _searchController.clear();
                                selectedFilter = 'Item';
                              });
                            },
                            child: const Text(
                              "Clear",
                              maxLines: 1,
                              style:
                                  TextStyle(fontSize: 10, color: Colors.black),
                            ))),
                  ),
                  Container(
                    height: 35,
                    width: MediaQuery.of(context).size.width * 0.77,
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    margin: const EdgeInsets.only(top: 1, bottom: 1),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.white,
                        border: Border.all(
                            color: const Color.fromARGB(255, 199, 191, 191),
                            strokeAlign: 0.5,
                            width: 0.5)),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 30,
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search ',
                              hintStyle: TextStyle(fontSize: 14),

                              //  suffixIcon: Icon(Icons.search),
                              // suffix: IconButton(onPressed: () {}, icon: Icon(Icons.clear),style: ButtonStyle()),
                              border: InputBorder
                                  .none, // Remove the input decoration
                            ),
                          ),
                        ),
                        Container(
                            width: 80,
                            child: DropdownButton<String>(
                              value: selectedFilter,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedFilter = newValue!;
                                });
                              },
                              items: <String>[
                                'Item',
                                'Tag',
                                'Property'
                              ] // List of data items (tags)
                                  .map<DropdownMenuItem<String>>(
                                      (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(fontSize: 12),
                                  ), // Display text for each item
                                );
                              }).toList(),
                            )),
                        Expanded(
                            flex: 10,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _searchController.text != ''
                                      ? getSearchList()
                                      : null;
                                });
                              },
                              child: Container(
                                height: 35,
                                alignment: Alignment.center,
                                child: Icon(Icons.search, size: 18),
                                color: Color.fromARGB(255, 250, 247, 232),
                              ),
                            ))
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 2,
              ),

              NumberPaginator(
                // by default, the paginator shows numbers as center content
                numberPages: pagesCount,
                onPageChange: (int index) {
                  setState(() {
                    isLoading = true;
                    selectedPage = index + 1;
                    getList();
                    // _currentPage is a variable within State of StatefulWidget
                  });
                },
                // initially selected index
                initialPage: 0,
                config: const NumberPaginatorUIConfig(
                  // default height is 48
                  height: 45,

                  buttonShape: BeveledRectangleBorder(
                      // borderRadius: BorderRadius.circular(8),
                      ),
                  buttonSelectedForegroundColor: Colors.white,
                  buttonUnselectedForegroundColor: Colors.black,
                  buttonUnselectedBackgroundColor: Colors.white,
                  buttonSelectedBackgroundColor: Colors.black,
                ),
              )
              // Pagination(
              //   numOfPages: 24,
              //   selectedPage: selectedPage,
              //   pagesVisible: 3,
              //   onPageChanged: (page) {
              //     setState(() {
              //       setState(() {
              //         isLoading = true;
              //         selectedPage = page;
              //         getList();
              //       });
              //     });
              //   },
              //   nextIcon: const Icon(
              //     Icons.arrow_forward_ios,
              //     color: Colors.black,
              //     size: 14,
              //   ),
              //   previousIcon: const Icon(
              //     Icons.arrow_back_ios,
              //     color: Colors.black,
              //     size: 14,
              //   ),
              //   activeTextStyle: const TextStyle(
              //     color: Colors.white,
              //     fontSize: 12,
              //     fontWeight: FontWeight.w700,
              //   ),
              //   spacing: 1,
              //   activeBtnStyle: ButtonStyle(
              //     backgroundColor: MaterialStateProperty.all(Colors.black),
              //     shape: MaterialStateProperty.all(
              //       RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(5),
              //       ),
              //     ),
              //   ),
              //   inactiveBtnStyle: ButtonStyle(
              //     shape: MaterialStateProperty.all(RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(5),
              //     )),
              //   ),
              //   inactiveTextStyle: const TextStyle(
              //     fontSize: 12,
              //     color: Colors.black,
              //     fontWeight: FontWeight.w700,
              //   ),
              // ),
            ],
          ),
        ));
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6, // Set initial height of the sheet
          minChildSize: 0.3, // Set minimum height of the sheet
          maxChildSize: 0.9, // Set maximum height of the sheet
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: CustomScrollView(
                controller: scrollController,
                slivers: <Widget>[
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        ListTile(
                          title: Text('Option 1'),
                          onTap: () {
                            // Handle option 1 selection
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: Text('Option 2'),
                          onTap: () {
                            // Handle option 2 selection
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: Text('Option 3'),
                          onTap: () {
                            // Handle option 3 selection
                            Navigator.pop(context);
                          },
                        ),
                      ],
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
}
