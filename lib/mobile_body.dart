import 'package:flutter/material.dart';

class MobileBody extends StatelessWidget {
  const MobileBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[200],
      appBar: AppBar(
        title: const Text('Mobile'),
      ),
      body: Column(
        children: [
          // youtube videos
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AspectRatio( //AspectRatio keep width and height with a ratio of configured value.
              aspectRatio: 16/9,
              child: Container(
                height: 250,
                color: Colors.deepPurple[400],
              ),
            ),
          ),
          // Comments sessions and recomment videos
          Expanded(
            child: ListView.builder(
                itemBuilder: ((context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: 120,
                      color: Colors.deepPurple[300],
                    ),
                  );
                }),
                itemCount: 10),
          ),
        ],
      ),
    );
  }
}
