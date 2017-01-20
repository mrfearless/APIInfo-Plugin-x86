# APIInfo Plugin (x86) - A Plugin For x64dbg

![](https://github.com/mrfearless/APIInfo-Plugin-x86/blob/master/images/APIInfo.png) [Current version: 1.0.0.3 - Last updated: 26/06/2016](https://github.com/mrfearless/APIInfo-Plugin-x86/releases/latest) There is no x64 version of this plugin currently.

## Overview

A plugin to populate the comments with windows api calls

**Note:** APIInfo plugin has been superseded by ThunderCls's xAnalyzer plugin.

xAnalyzer supports both x86 and x64 versions of x64dbg.

For more information, please visit: https://github.com/ThunderCls/xAnalyzer


## Features

* Add windows api function definition information to the comments

## How to install

* If x32dbg (x64dbg 32bit) is currently running, stop and exit.
* Copy the `APIInfo.dp32` to your `x64dbg\x32\plugins` folder.
* Extract `APIInfo-API-Definitions.zip` which contains the `.api` definition files to the `x64dbg\x32\plugins` folder.
* Start x32dbg

## How to use

* Set the required detail level in the APIInfo options dialog (from the plugins menu, APIInfo Options)
* Select Generate API Information from the plugins menu (or from the right click context menu in the CPU View)
* Wait till the information has been generated - hopefully you should see some API definitions show up in the comments now

## Notes

The API defintion files are created with a utility called ApiCreator (currently unreleased) which takes a selected windows sdk header file and parses it, outputting the function definitions into a file which uses a standard .ini format

Each function name is the stored as a section name, the key values for parameters, parameter count and full definition (key '@') are stored under this section name for easy retrieval with standard win32 api calls: [GetPrivateProfileString](https://msdn.microsoft.com/en-us/library/windows/desktop/ms724353(v=vs.85).aspx) & [GetPrivateProfileInt](https://msdn.microsoft.com/en-us/library/windows/desktop/ms724345(v=vs.85).aspx)
Some of the definition files have to be manually fixed up afterwards, so there may be errors or omissions. If you require a specific api file generated, feel free to contact me.

The comments where APIInfo thinks there is a parameter may be incorrect in some cases.

There isnt an x64 version of the plugin at this time due to the differences in calling conventions for 64bit, and would require considerable more time than i can spare to look into ways of maybe generating this info.

## Information

* Written by [fearless](https://github.com/mrfearless)  - [www.LetTheLight.in](http://www.LetTheLight.in)
* Created with the [x64dbg Plugin SDK For x86 Assembler](https://github.com/mrfearless/x64dbg-Plugin-SDK-For-x86-Assembler)
* A RadASM project (.rap) is used to manage and compile the plugin. The RadASM IDE can be downloaded [here](http://www.softpedia.com/get/Programming/File-Editors/RadASM.shtml)
* Some plugins make use of the MASM32 SDK found [here](http://www.masm32.com/masmdl.htm)

## x64dbg
* [x64dbg website](http://x64dbg.com)
* [x64dbg github](https://github.com/x64dbg/x64dbg)
* [x64dbg gitter](https://gitter.im/x64dbg/x64dbg)