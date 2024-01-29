---
sidebar_position: 0
---

# General Guideline

## File Input

The GUI version offer two input options for the desktop application and one input option for the mobile applications.

### Input from selected files (mobile and desktop)

This option allows users to select files from their local storage. You can use the `Select All` button on mobile devices to select all files. On desktop platforms, you can use the `Ctrl/Cmd` or `Shift` key to select multiple files or use `Ctrl/Cmd + A` to select all files.

### Input from a directory (desktop only)

This option allows users to select a directory. The app will look for files that match the supported file extensions in the directory. Recursive search is not yet supported.

## Output

On desktop platforms, the application saves the output in the user's chosen directory. However, due to the restrictive nature of mobile platforms, the application defaults to saving the output in its designated directory. To copy the output or share it with other applications or devices, simply utilize the 'Share' button. The quick share button will compress output files and share it as a single file, whereas the 'Share' button the `Output` window allows you to share the output individually.

## Specific Guideline for Smartphone Users

SEGUI is engineered to function seamlessly on both Android and iOS devices. We’ve conducted tests on both platforms, but due to limited resources, we couldn’t test the app on all devices. If you come across any bugs, we encourage you to report them to us. Here are a few considerations for using the app:

Phylogenomic datasets typically consist of over a thousand files. The file input interface may not support loading all of them simultaneously. We suggest dividing the files into smaller batches for optimal performance. Our tests show that the app can handle up to 1,500 files at once on a [Xiaomi Redmi Note 12](https://www.gsmarena.com/xiaomi_redmi_note_12-12063.php) with 8 Gb of RAM.

## Specific Guideline for macOS Users

Our app prioritizes security by utilizing [App Sandbox](https://developer.apple.com/documentation/security/app_sandbox), which inherently limits its access to your file system to protect your data. During our testing phase on macOS Sonoma, we found that the app encountered issues when processing thousands of files stored in the document folder. However, it functioned as expected when the data was located in the download folder or an external drive. Recent update on macOS Sonoma/Xcode seems to have resolved this issue. Nonetheless, if you experience permission issues while running the app with a large number of files, we recommend moving the files to the download folder or an external drive as a workaround.

Looking ahead, we plan to enhance our app's functionality by supporting input of compressed files (e.g., zip, tar.gz). This feature will enable users to process large datasets more efficiently by reducing the number of files.
