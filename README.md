# iOS app - AR Diffusion Museum

An iOS app that generates images using Stable Diffusion and displays them in AR.

![AppIcon](images/appIcon180.png)

You can generate images specifying any prompt (text) and display them on the wall in AR.

- macOS 13.1 or newer, Xcode 14.1 or newer
- iPhone 12+ / iOS 16.2+, iPad Pro with M1/M2 / iPadOS 16.2+

You can run the app on above mobile devices.
And you can run the app on Mac, building as a Designed for iPad app.

This Xcode project uses the `Apple/ml-stable-diffusion` Swift Package.

This project does not contain the CoreML models of Stable Diffusion v2 (SD2).
You need to make them converting the PyTorch SD2 models using Apple converter tools.
You can find the instructions of converting models in Apple's repo on GitHub.

- Apple/ml-stable-diffusion repo: https://github.com/apple/ml-stable-diffusion

There is a Readme in another GitHub Repository that explains how to add Stable Diffusion CoreML models
to your Xcode project. Please refer to it.

- Image Generator with Stable Diffusion v2: https://github.com/ynagatomo/ImgGenSD2

## Features

1. image generation using Stable Diffusion v2 on device
1. showing generating images step by step
1. saving generated images in Photo Library
1. displaying generated images on the wall in AR
1. automatic switching of displayed images at regular intervals
1. automatic enlargement according to viewing distance (Large projection on outdoor walls)
1. built-in sample images

![Image](images/ss1_1280.jpg)

![Image](images/ss2_1280.jpg)

![Image](images/gif1_640.gif)

## References

- Apple Swift Package / ml-stable-diffusion: https://github.com/apple/ml-stable-diffusion
- Hugging Face Hub - stabilityai/stable-diffusion-2: https://huggingface.co/stabilityai/stable-diffusion-2

![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)
