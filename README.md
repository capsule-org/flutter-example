# Capsule Flutter Example

This Repo has an example app demonstrating usage of the capsule_flutter plugin.

Before getting started, you'll need a Capsule API Key. Get one [here](https://usecapsule.com/beta)

## Setup

1. Clone this repo locally `git clone git@github.com:capsule-org/flutter-example.git`
2. In the root directory, run `flutter pub get`
3. In lib/main.dart (line 44) enter your API key for the desired environment (probably beta). On line 50, modify the desired environment (if not beta)

**Note:** If you haven't done so already, please reach out to the capsule team for a beta api key to start testing!

## Running the Example

### Via XCode

1. open `ios/Runner.xcworkspace` in XCode
2. select `Runner` under TARGETS
3. select `Signing & Capabilities`
4. set the team to your team and give the example app a unique bundle identifier

**Note:** you will need an organization level account, personal development accounts do not allow for associated domains
**Note:** please submit the appID to the capsule team. This will be in the following format: TEAM_ID.bundleIdentifier

start an iOS simulator
If using VSCode, go to the run and debug tab
click play button, which will allow you to debug if desiredi

### Via Command Link
Alternatively, you can use `flutter run`

## Questions and Troubleshooting

Need any additional help? Get in touch via the beta form or support@usecapsule.com

