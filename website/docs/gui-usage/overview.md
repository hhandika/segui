---
sidebar_position: 0
---

# Overview

We are bringing SEGUL as a GUI application running on major desktop and mobile operating system. We welcome everyone to try the beta version of the app and report any bugs you encounter.

## Specific Guideline for Smartphone Users

SEGUI is engineered to function seamlessly on both Android and iOS devices. We’ve conducted tests on both platforms, but due to limited resources, we couldn’t test the app on all devices. If you come across any bugs, we encourage you to report them to us. Here are a few considerations for using the app:

Phylogenomic datasets typically consist of over a thousand files. The file input interface may not support loading all of them simultaneously. We suggest dividing the files into smaller batches for optimal performance. Our tests show that the app can handle up to 1,500 files at once on a [Xiaomi Redmi Note 12](https://www.gsmarena.com/xiaomi_redmi_note_12-12063.php) with 8 Gb of RAM.

For Android users, SEGUI leverages the dynamic Material You theme. This means the app’s colors will adapt based on your wallpaper. Any changes to your wallpaper will consequently alter the app’s color scheme.

## Specific Guideline for macOS Users

Our app prioritizes security by utilizing [App Sandbox](https://developer.apple.com/documentation/security/app_sandbox), which inherently limits its access to your file system to protect your data. During our testing phase on macOS Sonoma, we found that the app encountered issues when processing thousands of files stored in the document folder. However, it functioned as expected when the data was located in the download folder or an external drive.

We are actively investigating this issue. If you experience permission issues while running the app with a large number of files, we recommend moving the files to the download folder or an external drive as a workaround.

Looking ahead, we plan to enhance our app's functionality by supporting input of compressed files (e.g., zip, tar.gz). This feature will enable users to process large datasets more efficiently by reducing the number of files.
