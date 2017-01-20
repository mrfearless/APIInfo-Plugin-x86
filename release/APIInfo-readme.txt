;=====================================================================================
;
; APIInfo-readme.txt
;
; v1.0.0.3 - Last updated: 26/06/2016 
;
;-------------------------------------------------------------------------------------

NOTE
----

APIInfo plugin has been superseded by ThunderCls's xAnalyzer plugin.

xAnalyzer supports both x86 and x64 versions of x64dbg.

For more information, please visit: https://github.com/ThunderCls/xAnalyzer




About
-----

APIInfo Plugin (x86) For x64dbg (32bit plugin)
by fearless - www.LetTheLight.in

Created with the x64dbg Plugin SDK For x86 Assembler
https://github.com/mrfearless/x64dbg-Plugin-SDK-For-x86-Assembler


Overview
--------

A plugin to populate the comments with windows api calls


Features
--------

- Add windows api function definition information to the comments


Installation
------------

Copy APIInfo.dp32 to x32\plugins folder of x64dbg
Extract APIInfo-API-Definitions.zip which contains the api definition files to the same 
plugins folder


How to use
----------

 - Set the required detail level in the APIInfo options dialog (from the plugins menu, 
   APIInfo Options)
 - Select Generate API Information from the plugins menu (or from the right click context
   menu in the CPU View)
 - Wait till the information has been generated - hopefully you should see some API
   definitions show up in the comments now

 
Notes
-----

The API defintion files are created with a utility called ApiCreator (currently unreleased)
which takes a selected windows sdk header file and parses it, outputting the function
definitions into a file which uses a standard .ini format

Each function name is the stored as a section name, the key values for parameters, 
parameter count and full definition (key '@') are stored under this section name for easy 
retrieval with standard win32 api calls: GetPrivateProfileString & GetPrivateProfileInt
Some of the definition files have to be manually fixed up afterwards, so there may be 
errors or omissions. If you require a specific api file generated, feel free to contact me.

The comments where APIInfo thinks there is a parameter may be incorrect in some cases.

There isnt an x64 version of the plugin at this time due to the differences in calling 
conventions for 64bit, and would require considerable more time than i can spare to look
into ways of maybe generating this info.



- 26/06/2016 updated plugin to use ico, added definitions with plugin
- 01/03/2016 Updated x64dbg SDK for masm to version 1.0.0.2 and recompiled plugin.
- Added function APIInfoLoadMenuIcon to load png resource image as raw bytes 
- Added menu icon for plugin (uses _plugin_menuseticon)
- Added menu entry icons for options and gen api (uses _plugin_menuentryseticon)
