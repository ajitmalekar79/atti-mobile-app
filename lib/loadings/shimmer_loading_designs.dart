import 'package:flutter/material.dart';

class ShimmerDesign extends StatelessWidget {
  const ShimmerDesign({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(),
    );
  }

  horizontalcontainer(double height, double width) {
    return Container(
      height: height,
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10), color: Colors.grey),
    );
  }

  box_and_lines(double height, double width) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: [
          Container(
            height: 130,
            width: width * 0.35,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10), color: Colors.grey),
          ),
          SizedBox(
            height: 130,
            width: width * 0.55,
            child: Column(children: [
              Container(
                height: 15,
                width: width * 0.50,
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey),
              ),
              Container(
                height: 15,
                width: width * 0.50,
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey),
              ),
              Container(
                height: 15,
                width: width * 0.50,
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey),
              ),
              Container(
                height: 15,
                width: width * 0.50,
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey),
              ),
              Container(
                height: 15,
                width: width * 0.50,
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey),
              ),
            ]),
          )
        ],
      ),
    );
  }

  circularcontainer(double height, double width) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CircleAvatar(
          radius: width * 0.10,
          backgroundColor: Colors.grey,
        ),
        CircleAvatar(
          radius: width * 0.10,
          backgroundColor: Colors.grey,
        ),
        CircleAvatar(
          radius: width * 0.10,
          backgroundColor: Colors.grey,
        ),
        CircleAvatar(
          radius: width * 0.10,
          backgroundColor: Colors.grey,
        )
      ],
    );
  }
}
