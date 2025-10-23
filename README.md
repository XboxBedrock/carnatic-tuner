<p align="center">
<kbd> 
<img src="./assets/icon/icon.png" alt="CarnaticTuner Logo" style="width:150px; height:150px; border-radius:10%;">
</kbd>
</p>

# CarnaticTuner
[![Play Store](https://img.shields.io/endpoint?color=green&logo=google-play&logoColor=green&url=https%3A%2F%2Fplay.cuzi.workers.dev%2Fplay%3Fi%3Dai.viri.newtuner%26gl%3DUS%26hl%3Den%26l%3DAndroid%26m%3D%24installs%2520Downloads)](https://play.google.com/store/apps/details?id=ai.viri.newtuner)
[![App Store](https://img.shields.io/badge/App_Store-0D96F6?logo=app-store&logoColor=white)](https://apps.apple.com/us/app/carnatictuner/id6448685976)

CarnaticTuner is the only free and open source tuner app for Carnatic instruments. Whether you play the Carnatic violin, veena, flute, sitar, or do Carnatic vocals, this app is for you!

## Features
- Accurate Carnatic tuning with specific Carnatic pitch intervals
- Select the base pitch easily
- Upper bar to indicate accuracy

## How To Use
Just download the app and start playing! Select the pitch you want to tune your instrument to! For example, most violin players tune to D# or E.

<img src="./screenshots/IosImage.webp" alt="Ios" style="height:500px;"> <img src="./screenshots/AndroidPhone.webp" alt="Android" style="height:500px;"> <img src="./screenshots/Screenshot_20230403_111454.png" alt="Tablet" align="top" style="height:250px;">



## Technical Brief

This app was built with Flutter for cross-platform support. The FFT algorithm is used for converting the audio samples into freqency domain, to allow for precise pitch determination.

The source code can be found in [`./lib`](./lib)
