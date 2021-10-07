// pub.dev
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:string_validator/string_validator.dart';

// custom
import 'package:isave/widgets/intro.dart';
import 'package:isave/widgets/loading.dart';
import 'package:isave/utils/toast.dart';
import 'package:isave/utils/download.dart';
import 'package:isave/utils/instagram_parser.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  TextEditingController inputController = TextEditingController();
  bool show = false;
  Map _data = {};
  bool _loading = false;
  late FocusNode _input;

  @override
  void initState() {
    super.initState();

    _input = FocusNode();

    inputController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    inputController.dispose();
    _input.dispose();
    inputController.removeListener(() {});
    super.dispose();
  }

  Future<void> clipboard() async {
    FocusScope.of(context).requestFocus(_input);
    Map result =
        await SystemChannels.platform.invokeMethod('Clipboard.getData');

    // ignore: unnecessary_null_comparison
    if (result == null) return;
    inputController.text = result['text'];
  }

  Future<void> fetchApi(String value) async {
    if (value.isEmpty) return;

    if (isURL(value)) value = InstagramParser.profileUrl(value);

    setState(() {
      _loading = true;
    });
    try {
      const String url = ''; // api url
      final send = {"username": value};

      var res = await Dio().post(
        url,
        data: send,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Connection": "keep-alive",
          },
        ),
      );
      if (res.statusCode != 200) {
        toastMessage("Something went wrong!");
        setState(() {
          _loading = false;
        });
        return;
      }

      final data = res.data;

      setState(() {
        _data = data;
        show = true;
      });
    } catch (err) {
      debugPrint('something went wrong! #Fetch Profile');
      toastMessage("Something went wrong!");
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedOpacity(
            opacity: _loading ? 1 : 0,
            duration: const Duration(milliseconds: 650),
            child: Loading(width: screenWidth),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: TextField(
              keyboardType: TextInputType.text,
              controller: inputController,
              focusNode: _input,
              decoration: InputDecoration(
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2.0),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
                hintText: "Enter profile username",
                prefixIcon: Icon(
                  Icons.link_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                suffixIcon: inputController.text.isEmpty
                    ? IconButton(
                        onPressed: clipboard,
                        icon: Icon(
                          Icons.content_paste_rounded,
                          size: 22.0,
                          color: Theme.of(context).primaryColor,
                        ),
                      )
                    : IconButton(
                        onPressed: () {
                          inputController.clear();
                        },
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
              ),
              cursorColor: Colors.black,
              onSubmitted: fetchApi,
              maxLines: 1,
            ),
          ),
          Expanded(
            child: show
                ? Container(
                    padding: const EdgeInsets.only(
                      top: 10.0,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '@${_data['username']}',
                              style: Theme.of(context).textTheme.bodyText1,
                            ),
                            const Divider(
                              height: 20.0,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Hero(
                                  tag: _data['profile_image'],
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/image_view',
                                        arguments: {
                                          "image_url": _data['profile_image']
                                        },
                                      );
                                    },
                                    child: CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(_data['profile_image']),
                                      backgroundColor: Colors.black,
                                      radius: 50,
                                    ),
                                  ),
                                ),
                                Column(
                                  children: <Widget>[
                                    Text(
                                      '${_data['post']}',
                                      style:
                                          Theme.of(context).textTheme.headline2,
                                    ),
                                    const Text(
                                      'Posts',
                                    )
                                  ],
                                ),
                                Column(
                                  children: <Widget>[
                                    Text(
                                      '${_data['followers']}',
                                      style:
                                          Theme.of(context).textTheme.headline2,
                                    ),
                                    const Text(
                                      'Followers',
                                    )
                                  ],
                                ),
                                Column(
                                  children: <Widget>[
                                    Text(
                                      '${_data['following']}',
                                      style:
                                          Theme.of(context).textTheme.headline2,
                                    ),
                                    const Text(
                                      'Following',
                                    )
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 20.0,
                            ),
                            // name
                            Text(
                              _data['name'],
                              style: Theme.of(context).textTheme.bodyText1,
                            ),
                            const SizedBox(height: 5.0),

                            // bio
                            SelectableText(_data['bio']),
                            const Divider(),

                            TextButton.icon(
                              icon: Icon(Icons.download,
                                  color: Theme.of(context).primaryColor),
                              onPressed: () {
                                final String fileName =
                                    "isave-${_data['username']}.jpg";
                                download(_data['profile_image'], fileName);
                              },
                              label: Text(
                                "Download Profile Picture",
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              style: ButtonStyle(
                                overlayColor: MaterialStateProperty.all<Color>(
                                  Colors.black.withOpacity(0.1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const Intro(name: 'profile'),
          ),
        ],
      ),
    );
  }
}
