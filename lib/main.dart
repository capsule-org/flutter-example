import 'dart:async';

import 'package:capsule/capsule.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  runApp(
    MaterialApp(
      home: const MyApp(),
      theme: ThemeData.light(useMaterial3: true),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

enum _MyAppStateStatus { loggedOut, testing, success }

class MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  late Capsule _capsule;
  _MyAppStateStatus _status = _MyAppStateStatus.loggedOut;
  String _statusMessage = 'Initializing...';
  late TabController _tabController;
  int _progress = 0;
  String? _walletAddress;
  List<String> _signatures = [];
  static const progressMax = 8;

  static const _chainId = 4;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    _capsule = Capsule(
      environment: EnvironmentExtension.fromString(dotenv.env['CAPSULE_ENV']!),
      apiKey: dotenv.env['CAPSULE_API_KEY']!,
      relyingPartyId: dotenv.env['CAPSULE_RELYING_PARTY_ID'],
    )..init();
    super.initState();
  }

  @override
  void dispose() {
    _capsule.dispose();
    super.dispose();
  }

  Widget _tabBarViewWeb3Dart() {
    return const Center(
      child: Text('Coming soon'),
    );
  }

  Future<void> _testSignUpNativePasskey() async {
    setState(() {
      _progress = 0;
      _statusMessage = 'Creating user...';
    });

    final email = await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Enter email'),
          content: TextField(
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofocus: true,
            onSubmitted: (value) {
              Navigator.of(context).pop(value);
            },
          ),
        );
      },
    );
    if (email == null) {
      setState(() {
        _status = _MyAppStateStatus.loggedOut;
      });
      return;
    }

    final userExists = await _capsule.checkIfUserExists(email);

    if (userExists) {
      _testSignInNativePasskey();
      return;
    }

    await _capsule.createUser(email);

    // This step is so fast, add some delay
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      _progress++;
      _statusMessage = 'Verifying email...';
    });
    if (!mounted) return;
    final verificationCode = await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Enter verification code'),
          content: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              if (value.length == 6) Navigator.of(context).pop(value);
            },
          ),
        );
      },
    );

    final biometricsId = await _capsule.verifyEmail(verificationCode);
    // This step is so fast, add some delay
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      _progress++;
      _statusMessage = 'Waiting for biometric auth...';
    });

    try {
      await _capsule.generatePasskey(email, biometricsId);
    } catch (e) {
      print(e);
      setState(() {
        _status = _MyAppStateStatus.loggedOut;
        _progress = 0;
        _statusMessage = "Initializing";
      });
      return;
    }

    setState(() {
      _progress++;
      _statusMessage = 'Biometric auth complete...';
    });

    // This step is so fast, add some delay
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      _progress++;
      _statusMessage = 'Creating wallet...';
    });
    final result = await _capsule.createWallet(
      skipDistribute: false,
    );
    final wallet = result.wallet;
    setState(() => _walletAddress = wallet.address);
    for (int i = 0; i < 3; i++) {
      setState(() {
        _progress++;
        _statusMessage = 'Signing message ${i + 1}...';
      });
      final signer = CapsuleSigner(_capsule);
      const msgParams = {
        'domain': {
          // This defines the network, in this case, Sepolia.
          'chainId': '$_chainId',
          // Give a user-friendly name to the specific contract you're signing for.
          'name': 'Ether Mail',
          // Add a verifying contract to make sure you're establishing contracts with the proper entity.
          'verifyingContract': '0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC',
          // This identifies the latest version.
          'version': '1',
        },

        // This defines the message you're proposing the user to sign, is dapp-specific, and contains
        // anything you want. There are no required fields. Be as explicit as possible when building out
        // the message schema.
        'message': {
          'contents': 'Hello, Bob!',
          'attachedMoneyInEth': 4.2,
          'from': {
            'name': 'Cow',
            'wallets': [
              '0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826',
              '0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF',
            ],
          },
          'to': [
            {
              'name': 'Bob',
              'wallets': [
                '0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB',
                '0xB0BdaBea57B0BDABeA57b0bdABEA57b0BDabEa57',
                '0xB0B0b0b0b0b0B000000000000000000000000000',
              ],
            },
          ],
        },
        // This refers to the keys of the following types object.
        'primaryType': 'Mail',
        'types': {
          // This refers to the domain the contract is hosted on.
          'EIP712Domain': [
            {'name': 'name', 'type': 'string'},
            {'name': 'version', 'type': 'string'},
            {'name': 'chainId', 'type': 'uint256'},
            {'name': 'verifyingContract', 'type': 'address'},
          ],
          // Not an EIP712Domain definition.
          'Group': [
            {'name': 'name', 'type': 'string'},
            {'name': 'members', 'type': 'Person[]'},
          ],
          // Refer to primaryType.
          'Mail': [
            {'name': 'from', 'type': 'Person'},
            {'name': 'to', 'type': 'Person[]'},
            {'name': 'contents', 'type': 'string'},
          ],
          // Not an EIP712Domain definition.
          'Person': [
            {'name': 'name', 'type': 'string'},
            {'name': 'wallets', 'type': 'address[]'},
          ],
        },
      };

      final result = await signer.signTypedData(
        from: wallet.address!,
        data: msgParams,
        version: SignTypedDataVersion.v4,
      );
      if (result is SuccessfulSignatureResult) {
        // Verify the signature.
        final address = await signer.recoverTypedSignature(
          data: msgParams,
          signature: result.signature,
          version: SignTypedDataVersion.v4,
        );
        assert(address == wallet.address);
        _signatures.add(result.signature);
      }
    }
    setState(() {
      _progress++;
      assert(_progress == progressMax);
      _status = _MyAppStateStatus.success;
      _statusMessage = 'Signing complete.';
    });
  }

  Future<void> _testSignInNativePasskey() async {
    var wallet;
    try {
      wallet = await _capsule.login();
    } on CapsuleBridgeException catch (error) {
      print(error.message);
      return;
    }

    setState(() => _walletAddress = wallet['address']);

    for (int i = 0; i < 3; i++) {
      setState(() {
        _progress++;
        _statusMessage = 'Signing message ${i + 1}...';
      });
      final signer = CapsuleSigner(_capsule);
      const msgParams = {
        'domain': {
          // This defines the network, in this case, Sepolia.
          'chainId': '$_chainId',
          // Give a user-friendly name to the specific contract you're signing for.
          'name': 'Ether Mail',
          // Add a verifying contract to make sure you're establishing contracts with the proper entity.
          'verifyingContract': '0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC',
          // This identifies the latest version.
          'version': '1',
        },

        // This defines the message you're proposing the user to sign, is dapp-specific, and contains
        // anything you want. There are no required fields. Be as explicit as possible when building out
        // the message schema.
        'message': {
          'contents': 'Hello, Bob!',
          'attachedMoneyInEth': 4.2,
          'from': {
            'name': 'Cow',
            'wallets': [
              '0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826',
              '0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF',
            ],
          },
          'to': [
            {
              'name': 'Bob',
              'wallets': [
                '0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB',
                '0xB0BdaBea57B0BDABeA57b0bdABEA57b0BDabEa57',
                '0xB0B0b0b0b0b0B000000000000000000000000000',
              ],
            },
          ],
        },
        // This refers to the keys of the following types object.
        'primaryType': 'Mail',
        'types': {
          // This refers to the domain the contract is hosted on.
          'EIP712Domain': [
            {'name': 'name', 'type': 'string'},
            {'name': 'version', 'type': 'string'},
            {'name': 'chainId', 'type': 'uint256'},
            {'name': 'verifyingContract', 'type': 'address'},
          ],
          // Not an EIP712Domain definition.
          'Group': [
            {'name': 'name', 'type': 'string'},
            {'name': 'members', 'type': 'Person[]'},
          ],
          // Refer to primaryType.
          'Mail': [
            {'name': 'from', 'type': 'Person'},
            {'name': 'to', 'type': 'Person[]'},
            {'name': 'contents', 'type': 'string'},
          ],
          // Not an EIP712Domain definition.
          'Person': [
            {'name': 'name', 'type': 'string'},
            {'name': 'wallets', 'type': 'address[]'},
          ],
        },
      };

      final result = await signer.signTypedData(
        from: wallet['address'],
        data: msgParams,
        version: SignTypedDataVersion.v4,
      );
      if (result is SuccessfulSignatureResult) {
        // Verify the signature.
        final address = await signer.recoverTypedSignature(
          data: msgParams,
          signature: result.signature,
          version: SignTypedDataVersion.v4,
        );
        assert(address == wallet['address']);
        _signatures.add(result.signature);
      }
    }
    setState(() {
      _progress++;
      _status = _MyAppStateStatus.success;
      _statusMessage = 'Signing complete.';
    });

    return;
  }

  Widget _progressIndicator() {
    return StepProgressIndicator(
      totalSteps: progressMax,
      currentStep: _progress,
      size: 36,
      selectedColor: Colors.black,
      unselectedColor: Colors.grey[200]!,
      customStep: (index, color, _) {
        final check = Container(
          color: color,
          child: const Icon(
            Icons.check,
            color: Colors.white,
          ),
        );
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              color: color,
              child: const Icon(
                Icons.remove,
              ),
            ),
            if (color == Colors.black)
              index == _progress ? check : check.animate().scale().fade()
          ],
        );
      },
    );
  }

  Widget _tabBarViewCapsule() {
    late Widget result;
    switch (_status) {
      case _MyAppStateStatus.loggedOut:
        result = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Sign Up - Native Passkey'),
              onPressed: () async {
                setState(() {
                  _status = _MyAppStateStatus.testing;
                });
                await _testSignUpNativePasskey();
                setState(() {
                  _status = _MyAppStateStatus.success;
                });
              },
            ),
            ElevatedButton(
              child: const Text('Sign In - Native Passkey'),
              onPressed: () async {
                setState(() {
                  _status = _MyAppStateStatus.testing;
                });
                await _testSignInNativePasskey();
                setState(() {
                  _status = _MyAppStateStatus.success;
                });
              },
            ),
          ],
        );
        break;
      case _MyAppStateStatus.testing:
        result = Column(
          children: [_progressIndicator(), Text(_statusMessage)],
        );
        break;
      case _MyAppStateStatus.success:
        result = Column(
          children: [
            _progressIndicator(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Text(
                    'Address: $_walletAddress',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: _walletAddress!),
                    );
                  },
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
            for (String signature in _signatures)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Text(
                      'Signature: $signature',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: signature),
                      );
                    },
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _capsule.logout();
                setState(() {
                  _walletAddress = null;
                  _signatures = [];
                  _status = _MyAppStateStatus.loggedOut;
                });
              },
              child: const Text('Log out'),
            ),
          ],
        );
        break;
    }
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: result,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Capsule Example",
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Capsule'),
            Tab(text: 'Web3Dart'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: <Widget>[
            _tabBarViewCapsule(),
            _tabBarViewWeb3Dart(),
          ],
        ),
      ),
    );
  }
}
