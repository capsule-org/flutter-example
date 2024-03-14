# Capsule Flutter Example

![flutter_demo](https://github.com/capsule-org/flutter-example/assets/2686353/216c204a-5b0f-4b85-a416-0b529741802f)

This Repo has an example app demonstrating usage of the capsule flutter plugin.

Before getting started, you'll need a Capsule API Key. Get one [here](https://usecapsule.com/beta)

## Setup

1. Clone this repo locally `git clone git@github.com:capsule-org/flutter-example.git`
2. In the root directory, run `flutter pub get`
3. Create a `.env` file in the root directory. You can copy the `.env.example` and modify, it includes all of the requried environment variables to run the app.

**Note** Valid environments are `dev`, `sandbox`, `beta`, and `prod`

**Note:** If you haven't done so already, please reach out to the capsule team for a beta api key to start testing!

## Running the Example

### Via XCode

1. open `ios/Runner.xcworkspace` in XCode
2. select `Runner` under TARGETS
3. select `Signing & Capabilities`
4. set the team to your team and give the example app a unique bundle identifier

**Note:** you will need an organization level account, personal development accounts do not allow for associated domains

**Note:** please submit the appID to the capsule team. This will be in the following format: TEAM_ID.bundleIdentifier

5. Start an iOS simulator. If using VSCode, go to the run and debug tab
6. Click play button, which will allow you to debug if desired

### Via Command Link

Alternatively, you can use `flutter run`

## Questions and Troubleshooting

Need any additional help? Get in touch via the beta form or support@usecapsule.com
