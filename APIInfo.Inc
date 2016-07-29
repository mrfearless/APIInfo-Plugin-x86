;=====================================================================================
; x64dbg plugin SDK for Masm - fearless 2016 - www.LetTheLight.in
;
; APIInfo.inc
;
;-------------------------------------------------------------------------------------
include windows.inc
include user32.inc
include kernel32.inc
includelib user32.lib
includelib kernel32.lib

APIInfoOptionsDlgProc           PROTO :DWORD, :DWORD, :DWORD, :DWORD
DbgGetEntryExitPoints           PROTO :DWORD, :DWORD
Strip_x64dbg_calls              PROTO :DWORD, :DWORD
GenAPIInfo                      PROTO 
SearchApiFileForDefinition      PROTO :DWORD, :DWORD, :DWORD
APIInfoLoadIniSettings          PROTO
APIInfoSaveIniSettings          PROTO
InitLVApiFiles                  PROTO :DWORD
LoadLVApiFiles                  PROTO :DWORD
InternalTest                    PROTO :DWORD, :DWORD
InternalTestCallback            PROTO :DWORD, :DWORD, :DWORD
SetAutoCommentIfCommentIsEmpty  PROTO :DWORD, :DWORD
GetFunctionParamCount           PROTO :DWORD, :DWORD
GetFunctionParam                PROTO :DWORD, :DWORD, :DWORD, :DWORD
APIInfoLoadMenuIcon             PROTO :DWORD, :DWORD

INSTRUCTIONSTACK                STRUCT
    Address                     DD ?
INSTRUCTIONSTACK                ENDS

INSTRUCTIONSTACK_MAXSIZE        EQU 24

.CONST
CRLF                            TEXTEQU <13,10,0,0> ; carriage return and linefeed for strings that require them (GuiAddLogMessage for example) 

ICO_APIINFO                     EQU 100
IMG_APIINFO                     EQU 101
IMG_APIINFOOPTIONS              EQU 102 ; PNG image for plugin menu icon
IMG_APIINFOGENAPI               EQU 103 ; PNG image for plugin menu icon



MENU_APIINFOGENAPI1             EQU 5
MENU_APIINFOGENAPI2             EQU 6
MENU_APIINFOOPTIONS1            EQU 7
MENU_APIINFOOPTIONS2            EQU 8


;APIInfo.dlg
IDD_APIInfoOptionsDlg			equ 1000
IDC_GrpAPIFilesToInclude		equ 1001
IDC_LV_APIFILES					equ 1002
IDC_GrpAPIDisplayOptions		equ 1003
IDC_RbDisplayNothing			equ 1004
IDC_RbDisplayModuleOnly			equ 1005
IDC_RbDisplayFunctionOnly		equ 1006
IDC_RbDisplayModuleAndFunction	equ 1007
IDC_RbDisplayFunctionDef		equ 1008
IDC_RbDisplayFunctionDefParams	equ 1009
IDC_GRP1						equ 1010
IDC_ChkAutoLoad					equ 1011
IDC_ChkPreserveExistingComments	equ 1012
IDC_BtnAPIInfoOptionsCancel	equ 1013
IDC_BtnAPIInfoOptionsOk		equ 1014

.DATA
APIInfo                         DB "APIInfo",0
APIInfoIni                      DB MAX_PATH DUP (0)
szCurrentDirectory              DB MAX_PATH DUP (0)
szApiFile                       DB MAX_PATH DUP (0)
szFindApiFiles                  DB MAX_PATH DUP (0)
szSymbolName                    DB MAX_PATH DUP (0)
szMenuPlugin1                   DB "APIInfo",0
szPluginLoaded                  DB "APIInfo loaded.",CRLF
szPluginUnloaded                DB "APIInfo unloaded.",CRLF
szMenuAPIInfo                   DB "Generate API Information",0
szMenuAPIOptions                DB "APIInfo Options...",0
szComment                       DB MAX_COMMENT_SIZE DUP (0)

szAPIInfoInfo                   DB 13,10         
                                DB "APIInfo x32dbg plugin by fearless 2016 - www.LetTheLight.in",13,10
                                DB 13,10
                                DB "APIInfo Features & Usage:",13,10
                                DB " - Add windows api function definition information to the comments",13,10  
                                DB 13,10,0

szAPIFunction                   DB MAX_PATH DUP (0)
szAPIModuleName                 DB MAX_PATH DUP (0)
szAPIComment                    DB MAX_COMMENT_SIZE DUP (0)
szAPIDefinition                 DB MAX_COMMENT_SIZE DUP (0)
szAPIFunctionParameter          DB MAX_COMMENT_SIZE DUP (0)
szDisasmText                    DB GUI_MAX_DISASSEMBLY_SIZE DUP (0)

szStartAddAPIInfo               DB "APIInfo: adding API information, please wait...",CRLF
szFinishAddAPIInfo              DB "APIInfo: finshed adding API information, ready to continue.",CRLF
szDebuggingRequired             DB "APIInfo: you need to be debugging to use this option.",CRLF
szSetToDisplayNothing           DB "APIInfo: currently set to display nothing. If you wish to see api information change this setting in the options dialog.",CRLF


szLVApiFilesColumnText          DB "API Files",0
szStarApi                       DB "*.api",0
szIni                           DB "ini",0
szApi                           DB ".api",0
szColon                         DB ":",0
szQuote                         DB 22h,0
szZero                          DB "0",0
szOne                           DB "1",0
szTwo                           DB "2",0
szThree                         DB "3",0
szFour                          DB "4",0
szFive                          DB "5",0
szSix                           DB "6",0
szSeven                         DB "7",0
szEight                         DB "8",0
szNine                          DB "9",0
szTen                           DB "10",0
szEleven                        DB "11",0
szTwelve                        DB "12",0
szThirteen                      DB "13",0
szFourteen                      DB "14",0
szFifthteen                     DB "15",0
szSixteen                       DB "16",0
szSeventeen                     DB "17",0
szEighteen                      DB "18",0
szNineteen                      DB "19",0
szTwenty                        DB "20",0
szTwentyOne                     DB "21",0
szTwentyTwo                     DB "22",0
szTwentyThree                   DB "23",0
szTwentyFour                    DB "24",0


szQ                             DB "?",0
szSpace                         DB " ",0
szBackslash                     DB "\",0
szAt                            DB "@",0
szDashSpace                     DB "- ",0
szCRLF                          DB 13,10,0
szNull                          DB 0,0,0,0

szIniDisplayOptions             DB "DisplayOptions",0
szIniAutoLoadAtEntry            DB "AutoLoadAtEntry",0
szAPIFilesToExclude             DB "APIFilesToExclude",0 ;section has entry for each file = 1 (true) or 0 (false), no entry = 1 (true) 
szIniPreserveExistingComments   DB "PreserveExistingComments",0
szIniParamCount                 DB "ParamCount",0

gIniDisplayOptions              DD 4
gNewIniDisplayOptions           DD 0
gIniAutoLoadAtEntry             DD 0
gNewIniAutoLoadAtEntry          DD 0
gIniPreserveExistingComments    DD 1
gNewIniPreserveExistingComments DD 0
gOptionsChanged                 DD 0
InitDlg                         DD 0

pIS                             DD 0
IS                              INSTRUCTIONSTACK INSTRUCTIONSTACK_MAXSIZE DUP (<>)

ISCOUNT                         DD 0

.DATA?
hInstance                       DD ?
IFDEF DEBUG32
DbgVar                          DD ?
ENDIF
hLVApiFiles                     DD ?
hIcoAPIInfo                     DD ?
