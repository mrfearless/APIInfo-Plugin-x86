;=====================================================================================
; x64dbg plugin SDK for Masm - fearless 2016 - www.LetTheLight.in
;
; APIInfo.asm
; 
; v1.0.0.2 - Last updated: 01/03/2016 
;
; - Added function APIInfoLoadMenuIcon to load png resource image as raw bytes 
; - Added menu icon for plugin (uses _plugin_menuseticon)
; - Added menu entry icons for options and gen api (uses _plugin_menuentryseticon) 
;
;-------------------------------------------------------------------------------------

.686
.MMX
.XMM
.model flat,stdcall
option casemap:none

;DEBUG32 EQU 1

IFDEF DEBUG32
    PRESERVEXMMREGS equ 1
    includelib M:\Masm32\lib\Debug32.lib
    DBG32LIB equ 1
    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
    include M:\Masm32\include\debug32.inc
ENDIF

;**************************************************************************
; MOD Macro
;**************************************************************************
_mod MACRO val1:REQ, val2:REQ
    push ecx
    mov  eax,val1
    mov  ecx,val2
    xor  edx,edx
    div  ecx  
    pop ecx
    exitm <edx>
endm


Include x64dbgpluginsdk.inc               ; Main x64dbg Plugin SDK for your program, and prototypes for the main exports 

Include APIInfo.inc                       ; plugin's include file

pluginit	        PROTO C :DWORD        ; Required prototype and export for x64dbg plugin SDK
plugstop            PROTO C               ; Required prototype and export for x64dbg plugin SDK
plugsetup           PROTO C :DWORD        ; Required prototype and export for x64dbg plugin SDK
;=====================================================================================


.CONST
PLUGIN_VERSION      EQU 1

.DATA
PLUGIN_NAME         DB "APIInfo",0

.DATA?
;-------------------------------------------------------------------------------------
; GLOBAL Plugin SDK variables
;-------------------------------------------------------------------------------------
PUBLIC              pluginHandle
PUBLIC              hwndDlg
PUBLIC              hMenu
PUBLIC              hMenuDisasm
PUBLIC              hMenuDump
PUBLIC              hMenuStack

pluginHandle        DD ?
hwndDlg             DD ?
hMenu               DD ?
hMenuDisasm         DD ?
hMenuDump           DD ?
hMenuStack          DD ?
;-------------------------------------------------------------------------------------


.CODE

;=====================================================================================
; Main entry function for a DLL file  - required.
;-------------------------------------------------------------------------------------
DllEntry PROC hInst:HINSTANCE, reason:DWORD, reserved:DWORD
    .IF reason == DLL_PROCESS_ATTACH
        mov eax, hInst
        mov hInstance, eax
    .ENDIF
    mov eax,TRUE
    ret
DllEntry Endp


;=====================================================================================
; pluginit - Called by debugger when plugin.dp32 is loaded - needs to be EXPORTED
; 
; Arguments: initStruct - a pointer to a PLUG_INITSTRUCT structure
;
; Notes:     you must fill in the pluginVersion, sdkVersion and pluginName members. 
;            The pluginHandle is obtained from the same structure - it may be needed in
;            other function calls.
;
;            you can call your own setup routine from within this function to setup 
;            menus and commands, and pass the initStruct parameter to this function.
;
;-------------------------------------------------------------------------------------
pluginit PROC C PUBLIC USES EBX initStruct:DWORD
    mov ebx, initStruct

    ; Fill in required information of initStruct, which is a pointer to a PLUG_INITSTRUCT structure
    mov eax, PLUGIN_VERSION
    mov [ebx].PLUG_INITSTRUCT.pluginVersion, eax
    mov eax, PLUG_SDKVERSION
    mov [ebx].PLUG_INITSTRUCT.sdkVersion, eax
    Invoke lstrcpy, Addr [ebx].PLUG_INITSTRUCT.pluginName, Addr PLUGIN_NAME
    
    mov ebx, initStruct
    mov eax, [ebx].PLUG_INITSTRUCT.pluginHandle
    mov pluginHandle, eax
    
    ; Do any other initialization here
    ; Construct plugin's .ini file from module filename
    Invoke GetModuleFileName, hInstance, Addr APIInfoIni, SIZEOF APIInfoIni
    Invoke lstrlen, Addr APIInfoIni
    lea ebx, APIInfoIni
    add ebx, eax
    sub ebx, 4 ; move back past 'dp32' extention
    mov byte ptr [ebx], 0 ; null so we can use lstrcat
    Invoke lstrcat, ebx, Addr szIni ; add 'ini' to end of string instead

    Invoke GetCurrentDirectory, MAX_PATH, Addr szCurrentDirectory
    Invoke lstrcat, Addr szCurrentDirectory, Addr szBackslash
    
    Invoke lstrcpy, Addr szFindApiFiles, Addr szCurrentDirectory
    Invoke lstrcat, Addr szFindApiFiles, Addr szStarApi

    Invoke LoadIcon, hInstance, ICO_APIINFO
    mov hIcoAPIInfo, eax

	mov eax, TRUE
	ret
pluginit endp


;=====================================================================================
; plugstop - Called by debugger when the plugin.dp32 is unloaded - needs to be EXPORTED
;
; Arguments: none
; 
; Notes:     perform cleanup operations here, clearing menus and other housekeeping
;
;-------------------------------------------------------------------------------------
plugstop PROC C PUBLIC 
    
    ; remove any menus, unregister any callbacks etc
    Invoke _plugin_menuclear, hMenu
    Invoke GuiAddLogMessage, Addr szPluginUnloaded
    
    mov eax, TRUE
    ret
plugstop endp


;=====================================================================================
; plugsetup - Called by debugger to initialize your plugins setup - needs to be EXPORTED
;
; Arguments: setupStruct - a pointer to a PLUG_SETUPSTRUCT structure
; 
; Notes:     setupStruct contains useful handles for use within x64_dbg, mainly Qt 
;            menu handles (which are not supported with win32 api) and the main window
;            handle with this information you can add your own menus and menu items 
;            to an existing menu, or one of the predefined supported right click 
;            context menus: hMenuDisam, hMenuDump & hMenuStack
;            
;            plugsetup is called after pluginit. 
;-------------------------------------------------------------------------------------
plugsetup PROC C PUBLIC USES EBX setupStruct:DWORD
    LOCAL hIconData:ICONDATA
    
    mov ebx, setupStruct

    ; Extract handles from setupStruct which is a pointer to a PLUG_SETUPSTRUCT structure  
    mov eax, [ebx].PLUG_SETUPSTRUCT.hwndDlg
    mov hwndDlg, eax
    mov eax, [ebx].PLUG_SETUPSTRUCT.hMenu
    mov hMenu, eax
    ;PrintText 'APIInfo'
    ;PrintDec hMenu
    mov eax, [ebx].PLUG_SETUPSTRUCT.hMenuDisasm
    mov hMenuDisasm, eax
    mov eax, [ebx].PLUG_SETUPSTRUCT.hMenuDump
    mov hMenuDump, eax
    mov eax, [ebx].PLUG_SETUPSTRUCT.hMenuStack
    mov hMenuStack, eax
    
    ; Do any setup here: add menus, menu items, callback and commands etc
    
    Invoke _plugin_menuaddentry, hMenu, MENU_APIINFOGENAPI1, Addr szMenuAPIInfo
    Invoke _plugin_menuaddentry, hMenu, MENU_APIINFOOPTIONS1, Addr szMenuAPIOptions
    Invoke _plugin_menuaddentry, hMenuDisasm, MENU_APIINFOGENAPI2, Addr szMenuAPIInfo
    Invoke _plugin_menuaddentry, hMenuDisasm, MENU_APIINFOOPTIONS2, Addr szMenuAPIOptions
    
    
    Invoke APIInfoLoadMenuIcon, IMG_APIINFO, Addr hIconData
    .IF eax == TRUE
        Invoke _plugin_menuseticon, hMenu, Addr hIconData
        Invoke _plugin_menuseticon, hMenuDisasm, Addr hIconData
    .ENDIF    

    Invoke APIInfoLoadMenuIcon, IMG_APIINFOOPTIONS, Addr hIconData
    .IF eax == TRUE
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_APIINFOOPTIONS1, Addr hIconData
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_APIINFOOPTIONS2, Addr hIconData
    .ENDIF
    
    Invoke APIInfoLoadMenuIcon, IMG_APIINFOGENAPI, Addr hIconData
    .IF eax == TRUE
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_APIINFOGENAPI1, Addr hIconData
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_APIINFOGENAPI2, Addr hIconData
    .ENDIF    

    
    Invoke GuiAddLogMessage, Addr szAPIInfoInfo

    Invoke GuiGetWindowHandle
    mov hwndDlg, eax    
    
    Invoke APIInfoLoadIniSettings
    
    mov eax, TRUE
    ret
plugsetup endp


;=====================================================================================
; CBMENUENTRY - Called by debugger when a menu item is clicked - needs to be EXPORTED
;
; Arguments: cbType
;            cbInfo - a pointer to a PLUG_CB_MENUENTRY structure. The hEntry contains 
;            the resource id of menu item identifiers
;  
; Notes:     hEntry can be used to determine if the user has clicked on your plugins
;            menu item(s) and to do something in response to it.
;            Needs to be PROC C type procedure call to be compatible with debugger
;-------------------------------------------------------------------------------------
CBMENUENTRY PROC C PUBLIC USES EBX cbType:DWORD, cbInfo:DWORD
    mov ebx, cbInfo
    mov eax, [ebx].PLUG_CB_MENUENTRY.hEntry
    
    .IF eax == MENU_APIINFOGENAPI1 || eax == MENU_APIINFOGENAPI2
        Invoke DbgIsDebugging
        .IF eax == FALSE
            Invoke GuiAddStatusBarMessage, Addr szDebuggingRequired
            Invoke GuiAddLogMessage, Addr szDebuggingRequired
        .ELSE
            Invoke GenAPIInfo
        .ENDIF
    .ELSEIF eax == MENU_APIINFOOPTIONS1 || eax == MENU_APIINFOOPTIONS2
        Invoke DialogBoxParam, hInstance, IDD_APIInfoOptionsDlg, hwndDlg, OFFSET APIInfoOptionsDlgProc, NULL
    .ENDIF
    mov eax, TRUE
    ret

CBMENUENTRY endp


;=====================================================================================
; Plugin Dialog Procedure
;-------------------------------------------------------------------------------------
APIInfoOptionsDlgProc PROC USES EBX ECX hWin:HWND,iMsg:DWORD,wParam:WPARAM, lParam:LPARAM
    LOCAL nItem:DWORD
    
    mov eax, iMsg
    .IF eax == WM_INITDIALOG
        ; Any initialization here
        
        Invoke SendMessage, hWin, WM_SETICON, ICON_SMALL, hIcoAPIInfo
        
        mov InitDlg, 0
        mov gOptionsChanged, FALSE
        
        Invoke GetDlgItem, hWin, IDC_LV_APIFILES
        mov hLVApiFiles, eax
        Invoke InitLVApiFiles, hLVApiFiles
        Invoke LoadLVApiFiles, hLVApiFiles
        Invoke APIInfoLoadIniSettings
        
        .IF gIniDisplayOptions == 0
            Invoke SendDlgItemMessage, hWin, IDC_RbDisplayNothing, BM_SETCHECK, BST_CHECKED, 0
        .ELSEIF gIniDisplayOptions == 1
            Invoke SendDlgItemMessage, hWin, IDC_RbDisplayModuleOnly, BM_SETCHECK, BST_CHECKED, 0
        .ELSEIF gIniDisplayOptions == 2
            Invoke SendDlgItemMessage, hWin, IDC_RbDisplayFunctionOnly, BM_SETCHECK, BST_CHECKED, 0
        .ELSEIF gIniDisplayOptions == 3
            Invoke SendDlgItemMessage, hWin, IDC_RbDisplayModuleAndFunction, BM_SETCHECK, BST_CHECKED, 0
        .ELSEIF gIniDisplayOptions == 4
            Invoke SendDlgItemMessage, hWin, IDC_RbDisplayFunctionDef, BM_SETCHECK, BST_CHECKED, 0
        .ELSEIF gIniDisplayOptions == 5
            Invoke SendDlgItemMessage, hWin, IDC_RbDisplayFunctionDefParams, BM_SETCHECK, BST_CHECKED, 0
        .ENDIF
        
        .IF gIniAutoLoadAtEntry == 0
            Invoke SendDlgItemMessage, hWin, IDC_ChkAutoLoad, BM_SETCHECK, BST_UNCHECKED, 0
        .ELSE
            Invoke SendDlgItemMessage, hWin, IDC_ChkAutoLoad, BM_SETCHECK, BST_CHECKED, 0
        .ENDIF
        
        .IF gIniPreserveExistingComments == 0
            Invoke SendDlgItemMessage, hWin, IDC_ChkPreserveExistingComments, BM_SETCHECK, BST_UNCHECKED, 0
        .ELSE
            Invoke SendDlgItemMessage, hWin, IDC_ChkPreserveExistingComments, BM_SETCHECK, BST_CHECKED, 0
        .ENDIF
        
        mov InitDlg, 1
        
        
	.ELSEIF eax == WM_CLOSE
        Invoke EndDialog, hWin, NULL
        
	.ELSEIF eax == WM_COMMAND
        mov eax, wParam
        and eax, 0FFFFh
        .IF eax == IDC_BtnAPIInfoOptionsOk
            .IF gOptionsChanged == TRUE
    
                Invoke SendDlgItemMessage, hWin, IDC_ChkAutoLoad, BM_GETCHECK, 0, 0
                .IF eax == BST_CHECKED
                    mov gNewIniAutoLoadAtEntry, 1
                .ELSE
                    mov gNewIniAutoLoadAtEntry, 0
                .ENDIF    
                mov eax, gNewIniAutoLoadAtEntry
                mov gIniAutoLoadAtEntry, eax
                
                Invoke SendDlgItemMessage, hWin, IDC_ChkPreserveExistingComments, BM_GETCHECK, 0, 0
                .IF eax == BST_CHECKED
                    mov gNewIniPreserveExistingComments, 1  
                .ELSE
                    mov gNewIniPreserveExistingComments, 0
                .ENDIF
                mov eax, gNewIniPreserveExistingComments
                mov gIniPreserveExistingComments, eax
                
                Invoke SendDlgItemMessage, hWin, IDC_RbDisplayNothing, BM_GETCHECK, 0, 0
                .IF eax == BST_CHECKED
                    mov gNewIniDisplayOptions, 0
                .ENDIF
                Invoke SendDlgItemMessage, hWin, IDC_RbDisplayModuleOnly, BM_GETCHECK, 0, 0
                .IF eax == BST_CHECKED
                    mov gNewIniDisplayOptions, 1
                .ENDIF
                Invoke SendDlgItemMessage, hWin, IDC_RbDisplayFunctionOnly, BM_GETCHECK, 0, 0
                .IF eax == BST_CHECKED
                    mov gNewIniDisplayOptions, 2
                .ENDIF
                Invoke SendDlgItemMessage, hWin, IDC_RbDisplayModuleAndFunction, BM_GETCHECK, 0, 0
                .IF eax == BST_CHECKED
                    mov gNewIniDisplayOptions, 3
                .ENDIF
                Invoke SendDlgItemMessage, hWin, IDC_RbDisplayFunctionDef, BM_GETCHECK, 0, 0
                .IF eax == BST_CHECKED
                    mov gNewIniDisplayOptions, 4
                .ENDIF
                Invoke SendDlgItemMessage, hWin, IDC_RbDisplayFunctionDefParams, BM_GETCHECK, 0, 0
                .IF eax == BST_CHECKED
                    mov gNewIniDisplayOptions, 5
                .ENDIF
                mov eax, gNewIniDisplayOptions
                mov gIniDisplayOptions, eax
                                
                ;PrintDec gNewIniDisplayOptions
                ;PrintDec gNewIniAutoLoadAtEntry
                ;PrintDec gIniDisplayOptions
                ;PrintDec gIniAutoLoadAtEntry
                ;PrintDec gIniPreserveExistingComments
                
                Invoke APIInfoSaveIniSettings
            .ENDIF
            Invoke SendMessage, hWin, WM_CLOSE, NULL, NULL
        
        .ELSEIF eax == IDC_BtnAPIInfoOptionsCancel
            Invoke SendMessage, hWin, WM_CLOSE, NULL, NULL
       
        .ELSEIF eax == IDC_RbDisplayNothing
            mov gOptionsChanged, TRUE
            ;mov gNewIniDisplayOptions, 0

        .ELSEIF eax == IDC_RbDisplayModuleOnly
            mov gOptionsChanged, TRUE
            ;mov gNewIniDisplayOptions, 1

        .ELSEIF eax == IDC_RbDisplayFunctionOnly
            mov gOptionsChanged, TRUE
            ;mov gNewIniDisplayOptions, 2

        .ELSEIF eax == IDC_RbDisplayModuleAndFunction
            mov gOptionsChanged, TRUE
            ;mov gNewIniDisplayOptions, 3

        .ELSEIF eax == IDC_RbDisplayFunctionDef
            mov gOptionsChanged, TRUE
            ;mov gNewIniDisplayOptions, 4

        .ELSEIF eax == IDC_RbDisplayFunctionDefParams
            mov gOptionsChanged, TRUE
            ;mov gNewIniDisplayOptions, 5

        .ELSEIF eax == IDC_ChkAutoLoad
            mov gOptionsChanged, TRUE
            ;Invoke SendDlgItemMessage, hWin, IDC_ChkAutoLoad, BM_GETCHECK, 0, 0
            ;.IF eax == BST_CHECKED
            ;    mov gNewIniAutoLoadAtEntry, 1
            ;.ELSE
            ;    mov gNewIniAutoLoadAtEntry, 0
            ;.ENDIF
            
        .ELSEIF eax == IDC_ChkPreserveExistingComments
            mov gOptionsChanged, TRUE
            ;Invoke SendDlgItemMessage, hWin, IDC_ChkPreserveExistingComments, BM_GETCHECK, 0, 0
            ;.IF eax == BST_CHECKED
            ;    mov gNewIniPreserveExistingComments, 1
            ;.ELSE
            ;    mov gNewIniPreserveExistingComments, 0
            ;.ENDIF

        .ENDIF
        
	.ELSEIF eax==WM_NOTIFY
		mov ecx, lParam
		mov eax, ( [ecx].NMHDR.code)
		mov ebx, ( [ecx].NMHDR.hwndFrom)
        .IF ebx == hLVApiFiles
    		.IF eax == NM_DBLCLK        
                mov gOptionsChanged, TRUE
        
            .ELSEIF eax == NM_CLICK
                mov gOptionsChanged, TRUE

            .ELSEIF eax == NM_CUSTOMDRAW
                mov ecx, lParam
                mov eax, (NMLVCUSTOMDRAW ptr[ecx]).nmcd.dwDrawStage
                .IF eax == CDDS_PREPAINT
                    mov eax, CDRF_NOTIFYITEMDRAW
                    invoke SetWindowLong,hWin,DWL_MSGRESULT,eax
                    mov eax, TRUE
                    ret
                     
                .ELSEIF eax == CDDS_ITEMPREPAINT
                    mov eax, CDRF_NOTIFYSUBITEMDRAW
                    invoke SetWindowLong,hWin,DWL_MSGRESULT,eax
                    mov eax, TRUE
                    ret
                    
                .ELSEIF eax == CDDS_ITEMPREPAINT or CDDS_SUBITEM
                    mov ecx, lParam
                    ;mov eax, (NMLVCUSTOMDRAW ptr[ecx]).iSubItem
                    ;mov nSubItem, eax
                    mov eax, (NMLVCUSTOMDRAW ptr[ecx]).nmcd.dwItemSpec      ; item
                    mov nItem, eax
                    
                	.IF  _mod(nItem,2) == 1                                 ; Calc mod of item to see if the background should be applied
                		mov (NMLVCUSTOMDRAW ptr[ecx]).clrTextBk, 00FFF3F2h        ;00F9F9F9h; 00F9F9F9h ; Light Grey | 00FFF3F2h Light Blue | 00FFF0E6h; 00FFE4D0h ; 00A6F7F0h ;Background text = light yellow
                		mov (NMLVCUSTOMDRAW ptr[ecx]).clrText,00000000h     ; text color = red
                	.ELSE
                		mov (NMLVCUSTOMDRAW ptr[ecx]).clrTextBk,0FFFFFFh    ;Background text = white
                		mov (NMLVCUSTOMDRAW ptr[ecx]).clrText,00h           ; text color = black
                		
                	.ENDIF    	            
                    mov eax, CDRF_NOTIFYSUBITEMDRAW ;CDRF_DODEFAULT
                    invoke SetWindowLong,hWin,DWL_MSGRESULT,eax
                    mov eax, TRUE	            
                    ret
                    
                .ELSE
                    mov eax, CDRF_DODEFAULT
                    invoke SetWindowLong,hWin,DWL_MSGRESULT,eax
                    mov eax, TRUE
                    ret
                .ENDIF


                
		    .ELSEIF eax == LVN_ITEMCHANGED ; maybe create a ListViewCompareStates
                .IF InitDlg == 1
                    mov ecx, lParam
                    mov eax, (NM_LISTVIEW Ptr [ecx]).uChanged
                    .IF eax == LVIF_STATE
                        mov eax, (NM_LISTVIEW Ptr [ecx]).uNewState
                        mov ebx, (NM_LISTVIEW Ptr [ecx]).uOldState
                        .IF (eax == 8192d && ebx == 4096d) || (eax == 4096d && ebx == 8192d) 
                            ;PrintText 'Changes'
                            mov gOptionsChanged, TRUE
                        .ENDIF
                    .ENDIF
                .ENDIF  
            .ENDIF
        .ENDIF
            
    .ELSE
        mov eax, FALSE
        ret
	.ENDIF
    mov eax, TRUE
    ret
APIInfoOptionsDlgProc endp


;=====================================================================================
; Init Listivew
;-------------------------------------------------------------------------------------
InitLVApiFiles PROC hListview:DWORD
    LOCAL LVC:LV_COLUMN
    
    mov eax, LVS_EX_CHECKBOXES + LVS_EX_FULLROWSELECT + LVS_EX_GRIDLINES + LVS_EX_DOUBLEBUFFER
    Invoke SendMessage, hListview, LVM_SETEXTENDEDLISTVIEWSTYLE, eax, eax
    
	mov LVC.imask, LVCF_FMT or LVCF_TEXT ;or LVCF_WIDTH  ;or LVCFMT_COL_HAS_IMAGES
    mov LVC.fmt, LVCFMT_LEFT ; defaults to LVCFMT_LEFT
    lea ebx, szLVApiFilesColumnText	
	mov LVC.pszText, ebx
	;mov LVC.lx, 150d
	Invoke SendMessage, hListview, LVM_INSERTCOLUMN, 0, Addr LVC
    Invoke SendMessage, hListview, LVM_SETCOLUMNWIDTH, 0, LVSCW_AUTOSIZE_USEHEADER
    ret

InitLVApiFiles endp


;=====================================================================================
; Load listview with api files
;-------------------------------------------------------------------------------------
LoadLVApiFiles PROC USES EBX hListview:DWORD
	LOCAL LVItem:LV_ITEM
	LOCAL nItemIndex:DWORD
	LOCAL wfd:WIN32_FIND_DATA
	LOCAL hFind:DWORD
    LOCAL dwCheckedState:DWORD
    
	mov nItemIndex, 0
	
    mov LVItem.imask, LVIF_TEXT + LVIF_STATE
	;mov LVItem.iItem, eax	
	mov LVItem.iSubItem, 0
	mov LVItem.stateMask, LVIS_STATEIMAGEMASK

    ;PrintString szFindApiFiles
    Invoke FindFirstFile, Addr szFindApiFiles, Addr wfd
    .IF eax == INVALID_HANDLE_VALUE
        ;PrintText 'FindFirstFile Fail'
        mov eax, FALSE
        ret
    .ENDIF
    mov hFind, eax
    ;PrintDec hFind
    mov eax, TRUE
    .WHILE eax == TRUE
        Invoke FindNextFile, hFind, Addr wfd
        .IF eax != 0
            mov eax, nItemIndex
	        mov LVItem.iItem, eax	        
            lea ebx, wfd.cFileName
            ;mov DbgVar, ebx
            ;PrintStringByAddr DbgVar
            lea ebx, wfd.cFileName
            mov LVItem.pszText, ebx

            Invoke GetPrivateProfileInt, Addr szAPIFilesToExclude, ebx, 1, Addr APIInfoIni
            mov dwCheckedState, eax



            invoke SendMessage, hListview, LVM_INSERTITEM, 0, Addr LVItem
            .IF eax == -1
                ;PrintText 'Failed to add'
            .endif
            
        	xor eax, eax
        	.IF dwCheckedState == 1
        	    mov eax, 2      ; set check
        	.ELSE               ; 0 
        	    mov eax, 1      ; set uncheck
        	.ENDIF        
        	shl eax,12	
        	mov LVItem.state, eax            
            
	        mov LVItem.state, eax
	        Invoke SendMessage, hListview, LVM_SETITEMSTATE, nItemIndex, addr LVItem            
            
            inc nItemIndex
            ;PrintDec nItemIndex
            mov eax, TRUE
        .ELSE
            mov eax, FALSE
        .ENDIF
    .ENDW

    ret

LoadLVApiFiles endp


;=====================================================================================
; GenAPIInfo Procedure
;-------------------------------------------------------------------------------------
GenAPIInfo PROC USES EBX ECX
    LOCAL CurrentAddress:DWORD
    LOCAL CallDestination:DWORD
    LOCAL JmpDestination:DWORD
    LOCAL bii:BASIC_INSTRUCTION_INFO ; basic 
    LOCAL cbii:BASIC_INSTRUCTION_INFO ; call destination
    LOCAL dwEntry:DWORD
    LOCAL dwExit:DWORD    
    LOCAL iscounter:DWORD
    LOCAL ParamCount:DWORD
    LOCAL CurrentParam:DWORD
    LOCAL CurrentISIndex:DWORD
    LOCAL ParamAddress:DWORD
    
    Invoke DbgIsDebugging
    .IF eax == FALSE
        Invoke GuiAddLogMessage, Addr szDebuggingRequired
        ret
    .ENDIF

    .IF gIniDisplayOptions == 0
        Invoke GuiAddStatusBarMessage, Addr szSetToDisplayNothing
        mov eax, FALSE
        ret
    .ENDIF

    Invoke GuiAddStatusBarMessage, Addr szStartAddAPIInfo

    Invoke DbgGetEntryExitPoints, Addr dwEntry, Addr dwExit
    
    Invoke DbgClearAutoCommentRange, dwEntry, dwExit
    ;Invoke DbgClearCommentRange, dwEntry, dwExit
    Invoke GuiUpdateDisassemblyView
    mov eax, dwEntry
    mov CurrentAddress, eax
    
    mov ISCOUNT, 0
    mov iscounter, 0
    
    
    .WHILE eax < dwExit ;ExitPoint
        Invoke DbgDisasmFastAt, CurrentAddress, Addr bii
        movzx eax, byte ptr bii.call_
        movzx ebx, byte ptr bii.branch
        .IF eax == 1 && ebx == 1 ; we have call statement
            Invoke GuiGetDisassembly, CurrentAddress, Addr szDisasmText
            Invoke Strip_x64dbg_calls, Addr szDisasmText, Addr szAPIFunction ; Addr szDisasmText
            .IF eax == TRUE
                
                .IF gIniDisplayOptions == 2 ; just function name
                    ;Invoke DbgSetAutoCommentAt, CurrentAddress, Addr szAPIFunction
                    Invoke SetAutoCommentIfCommentIsEmpty, CurrentAddress, Addr szAPIFunction
                .ELSE
                    mov eax, bii.address
                    mov CallDestination, eax
                    Invoke DbgDisasmFastAt, CallDestination, Addr cbii
                    
                    movzx eax, byte ptr cbii.branch
                    .IF eax == 1 ; jmp
                        Invoke DbgGetBranchDestination, CallDestination
                        mov JmpDestination, eax
                        .IF gIniDisplayOptions == 1
                            _DbgFunctions ModNameFromAddr, JmpDestination, ADDR szAPIModuleName, TRUE ; show .dll
                        .ELSE
                            _DbgFunctions ModNameFromAddr, JmpDestination, ADDR szAPIModuleName, FALSE; for other options we just need the module name without the .dll ext
                        .ENDIF
                        
                        ;PrintString szAPIModuleName
                        ;PrintString szAPIFunction
                        .IF gIniDisplayOptions == 1 ; just module name
                            ;Invoke DbgSetAutoCommentAt, CurrentAddress, Addr szAPIModuleName
                            Invoke SetAutoCommentIfCommentIsEmpty, CurrentAddress, Addr szAPIModuleName
                        .ELSEIF gIniDisplayOptions == 3 ; module:function
                            Invoke lstrcpy, Addr szAPIComment, Addr szAPIModuleName
                            invoke lstrcat, Addr szAPIComment, Addr szColon
                            invoke lstrcat, Addr szAPIComment, Addr szAPIFunction
                            ;Invoke DbgSetAutoCommentAt, CurrentAddress, Addr szAPIComment
                            Invoke SetAutoCommentIfCommentIsEmpty, CurrentAddress, Addr szAPIComment
                        .ELSE
                            Invoke SearchApiFileForDefinition, Addr szAPIModuleName, Addr szAPIFunction, Addr szAPIDefinition
                            .IF eax == FALSE
                                Invoke lstrcpy, Addr szAPIComment, Addr szAPIModuleName
                                invoke lstrcat, Addr szAPIComment, Addr szColon
                                invoke lstrcat, Addr szAPIComment, Addr szAPIFunction
                                ;Invoke DbgSetAutoCommentAt, CurrentAddress, Addr szAPIComment
                                Invoke SetAutoCommentIfCommentIsEmpty, CurrentAddress, Addr szAPIComment
                            .ELSE
                                ;Invoke DbgSetAutoCommentAt, CurrentAddress, Addr szAPIDefinition
                                Invoke SetAutoCommentIfCommentIsEmpty, CurrentAddress, Addr szAPIDefinition
                            .ENDIF
                            
                            .IF gIniDisplayOptions == 5 ; do parameters as well as definition
                                Invoke GetFunctionParamCount, Addr szAPIModuleName, Addr szAPIFunction
                                mov ParamCount, eax
                                .IF eax != -1 && eax != 0 ; make sure we are only checked for functions that are succesfully found in api file and have 1 or more parameters
                                    .IF eax <= ISCOUNT ; make sure we have enough in our stack to check for parameters
                                        ;PrintString szAPIFunction
                                        ;PrintDec ParamCount
                                        ;PrintDec CurrentAddress
                                        ;PrintDec ISCOUNT
                                        
                                        mov eax, ISCOUNT
                                        mov CurrentISIndex, eax
                                        mov CurrentParam, 1
                                        .WHILE eax != 0
                                            ;PrintDec CurrentParam
                                            mov ecx, CurrentISIndex
                                            dec ecx ; for 0 based index
                                            lea ebx, IS
                                            mov eax, [ebx+ecx*4] ; eax contains address of last param to get
                                            mov ParamAddress, eax
                                            
                                            Invoke GetFunctionParam, Addr szAPIModuleName, Addr szAPIFunction, CurrentParam, Addr szAPIFunctionParameter
                                            .IF eax == TRUE
                                                Invoke SetAutoCommentIfCommentIsEmpty, ParamAddress, Addr szAPIFunctionParameter
                                            .ENDIF
                                            inc CurrentParam
                                            dec CurrentISIndex
                                            mov eax, CurrentISIndex
                                        .ENDW 
                                        
                                    .ENDIF
                                .ENDIF
                                mov ISCOUNT, 0 ; reset instruction stack
                            .ENDIF
                            
                            
                        .ENDIF
                    .ELSE ; internal function call
                        Invoke lstrcpy, Addr szAPIComment, Addr szDashSpace
                        Invoke DbgGetLabelAt, CurrentAddress, SEG_DEFAULT, Addr szAPIFunction
                        Invoke lstrcat, Addr szAPIComment, Addr szAPIFunction
                        ;Invoke DbgSetAutoCommentAt, CurrentAddress, Addr szAPIComment
                        Invoke SetAutoCommentIfCommentIsEmpty, CurrentAddress, Addr szAPIComment
                        mov ISCOUNT, 0 ; reset instruction stack
                        ;PrintText '-----------------------------------'
                        ;PrintString szAPIFunction
                        ;Invoke InternalTest, CurrentAddress, Addr szAPIFunction
                    .ENDIF
                .ENDIF
            .ENDIF
        .ELSE
            .IF gIniDisplayOptions == 5 
                movzx eax, byte ptr bii.branch
                .IF eax != 1 ; jmp instruction
                
                    lea ebx, bii.instruction
                    mov eax, [ebx]
                    mov ecx, [ebx+4]
                    mov ebx, [ebx+1]
                     
                    .IF eax == "hsup" && ebx == " hsu" && ecx != "pbe " ; save to our instruction stack - only push instruction
                        mov eax, ISCOUNT
                        .IF eax < INSTRUCTIONSTACK_MAXSIZE
                            lea ebx, IS
                            mov eax, CurrentAddress
                            mov ecx, ISCOUNT
                            mov [ebx+ecx*4] , eax
                            inc ISCOUNT
                            ;PrintDec CurrentAddress
                            ;lea ebx, bii.instruction
                            ;mov DbgVar, ebx
                            ;PrintStringByAddr DbgVar
                        .ELSE
                            IFDEF DEBUG32
                            PrintText 'Stack too full!'
                            PrintDec ISCOUNT
                            PrintDec CurrentAddress
                            ENDIF
                        .ENDIF
                    .ELSEIF eax == " ter" ;|| eax == " ter"
                        mov ISCOUNT, 0 ; reset stack
                    .ENDIF
                .ENDIF
            .ENDIF
            ;Invoke SetAutoCommentIfCommentIsEmpty, CurrentAddress, Addr szSpace ;DbgClearAutoCommentRange, CurrentAddress, CurrentAddress ; SetAutoCommentIfCommentIsEmpty, CurrentAddress, Addr szNull
        .ENDIF
        mov eax, bii.size_ 
        add CurrentAddress, eax        
        mov eax, CurrentAddress
    .ENDW
    
    Invoke GuiAddStatusBarMessage, Addr szFinishAddAPIInfo
    Invoke GuiUpdateDisassemblyView
    
    ret

GenAPIInfo endp


;=====================================================================================
; Set Auto Comment only if a comment isnt already set 
; 
;-------------------------------------------------------------------------------------
SetAutoCommentIfCommentIsEmpty PROC CommentAddress:DWORD, CommentString:DWORD
    ;PrintDec gIniPreserveExistingComments
    .IF gIniPreserveExistingComments == 1
        Invoke RtlZeroMemory, Addr szComment, SIZEOF szComment
        Invoke DbgGetCommentAt, CommentAddress, Addr szComment
        .IF eax == TRUE
            Invoke lstrlen, Addr szComment
            .IF eax != 0
                mov eax, FALSE
                ret
            .ENDIF
        .ENDIF
    .ENDIF
    ;Invoke DbgSetAutoCommentAt, CommentAddress, CommentString
    Invoke DbgSetCommentAt, CommentAddress, CommentString
    mov eax, TRUE
    ret

SetAutoCommentIfCommentIsEmpty endp


;-------------------------------------------------------------------------------------
; TEST FUNCTION - NOT IN USE
;-------------------------------------------------------------------------------------
InternalTest PROC USES EDI functionAddress:DWORD, functionName:DWORD
    LOCAL entry:DWORD
    LOCAL base:DWORD
    LOCAL modname[MAX_MODULE_SIZE]:BYTE
    LOCAL hProcess:DWORD
    LOCAL isf:IMAGEHLP_STACK_FRAME
    LOCAL qfuncaddr[2]:DWORD
    
    ;PrintText 'InternalTest'

    Invoke GetContextData, UE_CIP
    mov entry, eax
   
    Invoke DbgGetModuleAt, entry, Addr modname
    Invoke DbgModBaseFromName, Addr modname
    mov base, eax

    
    Invoke TitanGetProcessInformation 
    mov eax, [eax].PROCESS_INFORMATION.hProcess
    mov hProcess, eax     

    ;lea edi, dword ptr isf.InstructionOffset
    mov eax, functionAddress
    add dword ptr isf.InstructionOffset, eax
    adc dword ptr isf.InstructionOffset+4, 0

    ;mov eax, functionAddress
    ;mov dword ptr isf.InstructionOffset, eax ; InstructionOffset = functionAddress
    
    Invoke SymSetContext, hProcess, Addr isf, NULL

     
    Invoke SymEnumSymbols, hProcess, base, 0, functionName, Offset InternalTestCallback, NULL
    ;Invoke SymEnumTypesByName, hProcess, base, 0, Addr modname, Offset InternalTestCallback, NULL
    ;Invoke SymEnumSymbolsForAddr, hProcess, functionAddress, 0, Offset InternalTestCallback, NULL
    ;.IF eax == FALSE
    ;    Invoke GetLastError
    ;    PrintDec eax
    ;.endif
    ret

InternalTest endp


;-------------------------------------------------------------------------------------
; TEST FUNCTION - NOT IN USE
;-------------------------------------------------------------------------------------
InternalTestCallback PROC USES EBX EDX pSymInfo:DWORD, SymbolSize:ULONG, UserContext:PVOID
    LOCAL nNameLen:DWORD
    LOCAL nMaxNameLen:DWORD
    LOCAL nFlags:DWORD
    LOCAL nValue:DWORD
    LOCAL nTag:DWORD
    LOCAL nAddress:DWORD
    ;PrintText 'InternalTestCallback'

    mov ebx, pSymInfo
    ;lea eax, [ebx].SYMBOL_INFO.Name_
    mov eax, [ebx].SYMBOL_INFO.NameLen
    mov nNameLen, eax
    mov eax, [ebx].SYMBOL_INFO.MaxNameLen
    mov nMaxNameLen, eax
    mov eax, [ebx].SYMBOL_INFO.Flags
    mov nFlags, eax
    mov eax, [ebx].SYMBOL_INFO.Tag
    mov nTag, eax    
    mov eax, dword ptr [ebx].SYMBOL_INFO.Address
    mov nAddress, eax
    ;mov edx, dword ptr [ebx+4].SYMBOL_INFO.Address
    
    ;PrintDec eax
    ;PrintDec edx
    
    ;PrintDec nNameLen
    ;PrintDec nMaxNameLen
    ;PrintDec nFlags
    ;PrintDec nTag
    
    mov ebx, pSymInfo
    lea eax, [ebx].SYMBOL_INFO.Name_
    Invoke lstrcpyn, Addr szSymbolName, eax, nMaxNameLen
    IFDEF DEBUG32
    PrintString szSymbolName
    PrintDec nAddress
    ENDIF
    ;add ebx, 88d
    ;DbgDump ebx, 10
    ;mov eax, DbgVar
    ;PrintStringByAddr DbgVar
    ;DbgDump [ebx].SYMBOL_INFO.Name_, [ebx].SYMBOL_INFO.NameLen
    
    ;DbgDump ebx, 90d
    ;PrintDec [ebx].SYMBOL_INFO.NameLen
    ;PrintDec [ebx].SYMBOL_INFO.TypeIndex
    ;PrintDec [ebx].SYMBOL_INFO.MaxNameLen
    ;mov eax, [ebx].SYMBOL_INFO.Name_
    ;PrintDec eax
    ;mov DbgVar, eax
    ;PrintStringByAddr DbgVar
    ;mov eax, [ebx].SYMBOL_INFO.Name_
    ;mov eax, [eax]
    ;mov DbgVar, eax
    ;PrintStringByAddr DbgVar
    
    ret
InternalTestCallback ENDP


;=====================================================================================
; Search the .api file (.ini) - based on the module name, for the section that
; describes the api function, and return the definition value
; eg. Module = kernel32, api filename will be 'kernel32.api'
;-------------------------------------------------------------------------------------
SearchApiFileForDefinition PROC lpszApiModule:DWORD, lpszApiFunction:DWORD, lpszApiDefinition:DWORD
    .IF lpszApiModule == NULL && lpszApiFunction == NULL
        mov ebx, lpszApiDefinition
        mov byte ptr [ebx], 0    
        mov eax, FALSE
        ret
    .ENDIF
    
    Invoke lstrcpy, Addr szApiFile, Addr szCurrentDirectory
    Invoke lstrcat, Addr szApiFile, lpszApiModule
    Invoke lstrcat, Addr szApiFile, Addr szApi
    
    ;PrintString szApiFile
    ;PrintString szAPIFunction
    
    Invoke GetPrivateProfileString, lpszApiFunction, Addr szAt, Addr szColon, lpszApiDefinition, MAX_COMMENT_SIZE, Addr szApiFile
    ;PrintDec eax
    .IF eax == 0 || eax == 1 ; just got nothing or the colon and nothing else
        mov ebx, lpszApiDefinition
        mov byte ptr [ebx], 0
        mov eax, FALSE
    .ELSE
        ;PrintString szAPIDefinition
        mov eax, TRUE
    .ENDIF
    ret

SearchApiFileForDefinition endp


;=====================================================================================
; Returns parameters for function in .api file, or -1 if not found
;-------------------------------------------------------------------------------------
GetFunctionParamCount PROC lpszApiModule:DWORD, lpszApiFunction:DWORD
    .IF lpszApiModule == NULL && lpszApiFunction == NULL
        mov eax, -1
        ret
    .ENDIF
    
    Invoke lstrcpy, Addr szApiFile, Addr szCurrentDirectory
    Invoke lstrcat, Addr szApiFile, lpszApiModule
    Invoke lstrcat, Addr szApiFile, Addr szApi
    
    Invoke GetPrivateProfileInt, lpszApiFunction, Addr szIniParamCount, 0, Addr szApiFile

    ret

GetFunctionParamCount endp


;=====================================================================================
; Returns parameter type and name for a specified parameter of a function in a api file 
;-------------------------------------------------------------------------------------
GetFunctionParam PROC lpszApiModule:DWORD, lpszApiFunction:DWORD, dwParamNo:DWORD, lpszApiFunctionParameter:DWORD
    .IF lpszApiModule == NULL && lpszApiFunction == NULL
        mov ebx, lpszApiFunctionParameter
        mov byte ptr [ebx], 0    
        mov eax, FALSE
        ret
    .ENDIF
    
    Invoke lstrcpy, Addr szApiFile, Addr szCurrentDirectory
    Invoke lstrcat, Addr szApiFile, lpszApiModule
    Invoke lstrcat, Addr szApiFile, Addr szApi
    
    mov eax, dwParamNo
    .IF eax == 1
        lea ebx, szOne
    
    .ELSEIF eax == 2
        lea ebx, szTwo
    
    .ELSEIF eax == 3
        lea ebx, szThree
    
    .ELSEIF eax == 4
        lea ebx, szFour
    
    .ELSEIF eax == 5
        lea ebx, szFive
    
    .ELSEIF eax == 6
        lea ebx, szSix
    
    .ELSEIF eax == 7
        lea ebx, szSeven
    
    .ELSEIF eax == 8
        lea ebx, szEight
    
    .ELSEIF eax == 9
        lea ebx, szNine
    
    .ELSEIF eax == 10
        lea ebx, szTen
    
    .ELSEIF eax == 11
        lea ebx, szEleven
    
    .ELSEIF eax == 12
        lea ebx, szTwelve
    
    .ELSEIF eax == 13
        lea ebx, szThirteen
    
    .ELSEIF eax == 14
        lea ebx, szFourteen
    
    .ELSEIF eax == 15
        lea ebx, szFifthteen
    
    .ELSEIF eax == 16
        lea ebx, szSixteen
    
    .ELSEIF eax == 17
        lea ebx, szSeventeen
    
    .ELSEIF eax == 18
        lea ebx, szEighteen
    
    .ELSEIF eax == 19
        lea ebx, szNineteen
    
    .ELSEIF eax == 20
        lea ebx, szTwenty
    
    .ELSEIF eax == 21
        lea ebx, szTwentyOne
    
    .ELSEIF eax == 22
        lea ebx, szTwentyTwo
    
    .ELSEIF eax == 23
        lea ebx, szTwentyThree
    
    .ELSEIF eax == 24
        lea ebx, szTwentyFour
    
    .ELSE ; something > 24 params - gone wrong somewhere then
        mov ebx, lpszApiFunctionParameter
        mov byte ptr [ebx], 0    
        mov eax, FALSE
        ret
    .ENDIF
    
    Invoke GetPrivateProfileString, lpszApiFunction, ebx, Addr szColon, lpszApiFunctionParameter, MAX_COMMENT_SIZE, Addr szApiFile
    .IF eax == 0 || eax == 1 ; just got nothing or the colon and nothing else
        mov ebx, lpszApiFunctionParameter
        mov byte ptr [ebx], 0
        mov eax, FALSE
    .ELSE
        ;PrintString szAPIDefinition
        mov eax, TRUE
    .ENDIF
    ret
    
    ret
GetFunctionParam ENDP


;=====================================================================================
; Strips out the brackets, underscores, full stops and @ symbols from calls: call <winbif._GetModuleHandleA@4> and returns just the api call: GetModuleHandle
; Returns true if succesful and lpszAPIFunction will contain the stripped api function name, otherwise false and lpszAPIFunction will be a null string
;-------------------------------------------------------------------------------------
Strip_x64dbg_calls PROC USES EBX EDI ESI lpszCallText:DWORD, lpszAPIFunction:DWORD

    mov esi, lpszCallText
    mov edi, lpszAPIFunction
    
    movzx eax, byte ptr [esi]
    .WHILE al != '.' && al != '&' ; 64bit have & in the api calls, so to check for that as well
        .IF al == 0h
            mov edi, lpszAPIFunction
            mov byte ptr [edi], 0h ; null out string
            mov eax, FALSE
            ret
        .ENDIF
        inc esi
        movzx eax, byte ptr [esi]
    .ENDW

    inc esi ; jump over the . and the first _ if its there
    movzx eax, byte ptr [esi]
    .IF al == '_'
        inc esi
    .ENDIF

    movzx eax, byte ptr [esi]
    .WHILE al != '@' && al != '>'
        .IF al == 0h
            mov edi, lpszAPIFunction
            mov byte ptr [edi], 0h ; null out string
            mov eax, FALSE
            ret
        .ENDIF
        mov byte ptr [edi], al
        inc edi
        inc esi
        movzx eax, byte ptr [esi]
    .ENDW
    mov byte ptr [edi], 0h ; null out string
    
    ; check if 2nd last byte was lowercase, if so if the last byte is 'A' or 'W' we strip that off - ansi/unicode part
;    dec edi
;    dec edi
;    movzx eax, byte ptr [edi]
;    .IF al >= 'a' && al <= 'z'
;        inc edi
;        movzx eax, byte ptr [edi]
;        .IF al == 'A' || al == 'W'
;            mov byte ptr [edi], 0h ; null out string
;        .ENDIF
;    .ENDIF 
    mov eax, TRUE
    ret

Strip_x64dbg_calls endp


;=====================================================================================
; Gets entry point and exit point
;-------------------------------------------------------------------------------------
DbgGetEntryExitPoints PROC USES EBX lpdwEntry:DWORD, lpdwExit:DWORD
    LOCAL entry:DWORD
    LOCAL base:DWORD
    LOCAL modname[MAX_MODULE_SIZE]:BYTE
    LOCAL modbasename[MAX_MODULE_SIZE]:BYTE
    LOCAL dwModSize:DWORD
    LOCAL hProcess:DWORD
    LOCAL hModule:DWORD
    LOCAL modinfo:MODULEINFO
    LOCAL ExitPoint:DWORD
    LOCAL baseaddress:DWORD
    
    Invoke GetContextData, UE_CIP
    mov entry, eax
   
    Invoke DbgGetModuleAt, entry, Addr modname
    Invoke DbgModBaseFromName, Addr modname
    mov base, eax

    Invoke TitanGetProcessInformation 
    mov eax, [eax].PROCESS_INFORMATION.hProcess
    mov hProcess, eax    
    Invoke GetModuleBaseNameA, hProcess, base, Addr modbasename, MAX_MODULE_SIZE
    Invoke GetModuleHandle, Addr modbasename
    mov hModule, eax
    
    Invoke GetModuleInformation, hProcess, hModule, Addr modinfo, SIZEOF MODULEINFO
    Invoke DbgMemFindBaseAddr, modinfo.EntryPoint , Addr dwModSize
    mov baseaddress, eax
    
    mov eax, dwModSize
    mov ebx, baseaddress
    add eax, ebx
    sub eax, 2d
    mov ExitPoint, eax
    
    mov ebx, lpdwEntry
    mov eax, modinfo.EntryPoint
    mov [ebx], eax
    
    mov ebx, lpdwExit
    mov eax, ExitPoint
    mov [ebx], eax
    
    xor eax, eax
    ret

DbgGetEntryExitPoints endp


;=====================================================================================
; Loads setting from ini file for options dialog
;-------------------------------------------------------------------------------------
APIInfoLoadIniSettings PROC USES EBX
    
    Invoke GetPrivateProfileInt, Addr APIInfo, Addr szIniDisplayOptions, 4, Addr APIInfoIni
    mov gIniDisplayOptions, eax
    
    Invoke GetPrivateProfileInt, Addr APIInfo, Addr szIniAutoLoadAtEntry, 0, Addr APIInfoIni
    mov gIniAutoLoadAtEntry, eax
    
    Invoke GetPrivateProfileInt, Addr APIInfo, Addr szIniPreserveExistingComments, 1, Addr APIInfoIni
    mov gIniPreserveExistingComments, eax
    ret

APIInfoLoadIniSettings endp


;=====================================================================================
; Saves setting from options dialog to ini file 
;-------------------------------------------------------------------------------------
APIInfoSaveIniSettings PROC USES EBX
    LOCAL LVItem:LV_ITEM
    LOCAL nItemIndex:DWORD
    LOCAL nTotalItemCount:DWORD
    LOCAL szItemText[MAX_PATH]:BYTE
    
    .IF gIniAutoLoadAtEntry == 0
        Invoke WritePrivateProfileString, Addr APIInfo, Addr szIniAutoLoadAtEntry, Addr szZero, Addr APIInfoIni
    .ELSE
        Invoke WritePrivateProfileString, Addr APIInfo, Addr szIniAutoLoadAtEntry, Addr szOne, Addr APIInfoIni
    .ENDIF
    
    .IF gIniPreserveExistingComments == 0
        Invoke WritePrivateProfileString, Addr APIInfo, Addr szIniPreserveExistingComments, Addr szZero, Addr APIInfoIni
    .ELSE
        Invoke WritePrivateProfileString, Addr APIInfo, Addr szIniPreserveExistingComments, Addr szOne, Addr APIInfoIni
    .ENDIF
    
    
    .IF gIniDisplayOptions == 0 ; display nothing
        Invoke WritePrivateProfileString, Addr APIInfo, Addr szIniDisplayOptions, Addr szZero, Addr APIInfoIni
       
    .ELSEIF gIniDisplayOptions == 1 ; Display Module Only
        Invoke WritePrivateProfileString, Addr APIInfo, Addr szIniDisplayOptions, Addr szOne, Addr APIInfoIni
        
    .ELSEIF gIniDisplayOptions == 2 ; Display Function Name Only
        Invoke WritePrivateProfileString, Addr APIInfo, Addr szIniDisplayOptions, Addr szTwo, Addr APIInfoIni
        
    .ELSEIF gIniDisplayOptions == 3 ; Display Module & Function Name
        Invoke WritePrivateProfileString, Addr APIInfo, Addr szIniDisplayOptions, Addr szThree, Addr APIInfoIni
    
    .ELSEIF gIniDisplayOptions == 4 ; Display Definition from .api file @=
        Invoke WritePrivateProfileString, Addr APIInfo, Addr szIniDisplayOptions, Addr szFour, Addr APIInfoIni
    
    .ELSEIF gIniDisplayOptions == 5 ; Display Definition and params
        Invoke WritePrivateProfileString, Addr APIInfo, Addr szIniDisplayOptions, Addr szFive, Addr APIInfoIni
    
    ;.ELSEIF gIniDisplayOptions == 6
    
    ;.ELSEIF gIniDisplayOptions == 7
    
    .ENDIF
    
    ; loop through listview, getting checked boxes to see if any are to be excluded
    mov LVItem.imask, LVIF_TEXT
	mov LVItem.iSubItem, 0
	lea ebx, szItemText
    mov LVItem.pszText, ebx
    mov eax, MAX_PATH
    mov LVItem.cchTextMax, eax
    
    Invoke SendMessage, hLVApiFiles, LVM_GETITEMCOUNT, 0, 0
    mov nTotalItemCount, eax
    mov nItemIndex, 0
    mov eax, 0
    .WHILE eax < nTotalItemCount ; loop through all till total count is reached
        mov eax, nItemIndex
	    mov LVItem.iItem, eax	        
        Invoke SendMessage, hLVApiFiles, LVM_GETITEMTEXT, nItemIndex, Addr LVItem
        Invoke SendMessage, hLVApiFiles, LVM_GETITEMSTATE, nItemIndex, LVIS_STATEIMAGEMASK
        and eax, (3 SHL 12)
        .IF (eax == (2 SHL 12)) ; unchecked
            Invoke WritePrivateProfileString, Addr szAPIFilesToExclude, Addr szItemText, 0, Addr APIInfoIni
        .ELSE
            Invoke WritePrivateProfileString, Addr szAPIFilesToExclude, Addr szItemText, Addr szZero, Addr APIInfoIni
        .ENDIF
        inc nItemIndex
        mov eax, nItemIndex
    .ENDW
    ret

APIInfoSaveIniSettings endp


;=====================================================================================
; APIInfoLoadMenuIcon - Loads RT_RCDATA png resource and assigns it to ICONDATA
; Returns TRUE in eax if succesful or FALSE otherwise.
;-------------------------------------------------------------------------------------
APIInfoLoadMenuIcon PROC USES EBX dwImageResourceID:DWORD, lpIconData:DWORD
    LOCAL hRes:DWORD
    
    ; Load image for our menu item
    Invoke FindResource, hInstance, dwImageResourceID, RT_RCDATA ; load png image as raw data
    .IF eax != NULL
        mov hRes, eax
        Invoke SizeofResource, hInstance, hRes
        .IF eax != 0
            mov ebx, lpIconData
            mov [ebx].ICONDATA.size_, eax
            Invoke LoadResource, hInstance, hRes
            .IF eax != NULL
                Invoke LockResource, eax
                .IF eax != NULL
                    mov ebx, lpIconData
                    mov [ebx].ICONDATA.data, eax
                    mov eax, TRUE
                .ELSE
                    ;PrintText 'Failed to lock resource'
                    mov eax, FALSE
                .ENDIF
            .ELSE
                ;PrintText 'Failed to load resource'
                mov eax, FALSE
            .ENDIF
        .ELSE
            ;PrintText 'Failed to get resource size'
            mov eax, FALSE
        .ENDIF
    .ELSE
        ;PrintText 'Failed to find resource'
        mov eax, FALSE
    .ENDIF    
    ret

APIInfoLoadMenuIcon ENDP


;=====================================================================================
; CBINITDEBUG - Called by debugger when a program is debugged - needs to be EXPORTED
;
; Arguments: cbType
;            cbInfo - a pointer to a PLUG_CB_INITDEBUG structure. 
;            The szFileName item contains name of file being debugged. 
;  
; Notes:     
;            
;            Needs to be PROC C type procedure call to be compatible with debugger
;-------------------------------------------------------------------------------------
CBINITDEBUG PROC C PUBLIC USES EBX cbType:DWORD, cbInfo:DWORD
    ;PrintText 'CBINITDEBUG'
    Invoke DbgClearAutoCommentRange, 0, 0FFFFFFFEh
    ;Invoke DbgClearCommentRange, 0, 0FFFFFFFEh
    mov eax, TRUE
    ret
CBINITDEBUG endp


;=====================================================================================
; CBSTOPDEBUG - Called by debugger when debugging stopped - needs to be EXPORTED
;
; Arguments: cbType
;            cbInfo - reserved 
;            
;  
; Notes:     
;            
;            Needs to be PROC C type procedure call to be compatible with debugger
;-------------------------------------------------------------------------------------
CBSTOPDEBUG PROC C PUBLIC USES EBX cbType:DWORD, cbInfo:DWORD
    ;PrintText 'CBSTOPDEBUG'
    Invoke DbgClearAutoCommentRange, 0, 0FFFFFFFEh
    ;Invoke DbgClearCommentRange, 0, 0FFFFFFFEh
    mov eax, TRUE
    ret
CBSTOPDEBUG endp 


;=====================================================================================
; CBSYSTEMBREAKPOINT - Called by debugger at system breakpoint - needs to be EXPORTED
;
; Arguments: cbType
;            cbInfo - reserved 
;            
;  
; Notes:     
;            
;            Needs to be PROC C type procedure call to be compatible with debugger
;-------------------------------------------------------------------------------------
CBSYSTEMBREAKPOINT PROC C PUBLIC cbType:DWORD, cbInfo:DWORD
    ;PrintText 'CBSYSTEMBREAKPOINT'
    Invoke DbgClearAutoCommentRange, 0, 0FFFFFFFEh   
    ;Invoke DbgClearCommentRange, 0, 0FFFFFFFEh 
    mov eax, TRUE
    ret
CBSYSTEMBREAKPOINT ENDP

END DllEntry
















