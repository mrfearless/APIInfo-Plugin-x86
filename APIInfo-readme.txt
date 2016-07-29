;=====================================================================================
;
; APIInfo-readme.txt
;
; v1.0.0.3 - Last updated: 26/06/2016 
;
;-------------------------------------------------------------------------------------

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
Extract APIInfo-API-Definitions.zip which contains the api definition files to the same plugins folder


Notes
-----

- 26/06/2016 updated plugin to use ico, added definitions with plugin
- 01/03/2016 Updated x64dbg SDK for masm to version 1.0.0.2 and recompiled plugin.
- Added function APIInfoLoadMenuIcon to load png resource image as raw bytes 
- Added menu icon for plugin (uses _plugin_menuseticon)
- Added menu entry icons for options and gen api (uses _plugin_menuentryseticon)
