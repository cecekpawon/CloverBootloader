@echo off
rem # windows batch script for building clover
rem # 2012-09-06 apianti
rem # 2016,2019 cecekpawon

rem # please do not direct call this script unless you know what you are doing,
rem # use provided builmc as a wrapper instead

set "CURRENT_DIR=%~dp0"
cd /D "%CURRENT_DIR%"
if %CURRENT_DIR:~-1%==\ set CURRENT_DIR=%CURRENT_DIR:~0,-1%

::
:: INTERNAL
::

set BUILD_OPTIONS=-D NO_GRUB_DRIVERS
set CLEANING=
set DEV_STAGE=
set EDBA_MAX=417792
set EDK_BUILD_INFOS=
set EDK_SETUP_ARGS=
set EDK_SHELL_BIN_FIXED_PATH=
set F_TMP_TXT=tmp.txt
set F_VER_H=Version.h
set F_VER_TXT=vers.txt
set FILE_SIZE=
set MSG=
set REVISION=0
set SHOW_USAGE=0

::
:: SCRIPT
::

set DEFAULT_EDK_SHELL_BIN_MODE=
set DEFAULT_GEN_PAGE=0
set DEFAULT_NO_BOOTLOADERS=0
set DEFAULT_NO_BOOTSECTORS=0
set DEFAULT_NO_COPY_BIN=0
set DEFAULT_REVISION=0000

::
:: PATH
::

set "DEFAULT_CYGWIN_HOME=c:\cygwin"
set "DEFAULT_IASL_PREFIX=c:\ASL\"
set "DEFAULT_NASM_PREFIX=%DEFAULT_CYGWIN_HOME%\bin\"
set "DEFAULT_PACKAGES_PATH="
set "DEFAULT_PYTHONHOME=c:\Python3"
rem set "DEFAULT_PYTHON_FREEZER_PATH=%DEFAULT_PYTHONHOME%\Scripts"

::
:: EDK SETUP
::

rem set PYTHON3_ENABLE="TRUE"

set DEFAULT_BUILD_IA32=
set DEFAULT_BUILD_TARGET=RELEASE
set DEFAULT_BUILD_X64=
set DEFAULT_DSC_FILE=
set DEFAULT_THREAD_NUMBER=%NUMBER_OF_PROCESSORS%
set DEFAULT_TOOLCHAIN=VS2015x86

::
:: MACROS
::

set DEFAULT_AMD_SUPPORT=1
set DEFAULT_ANDX86=1
set DEFAULT_DEBUG_ON_SERIAL_PORT=0
set DEFAULT_DISABLE_LTO=0
set DEFAULT_DISABLE_UDMA_SUPPORT=0
set DEFAULT_DISABLE_USB_CONTROLLERS=0
set DEFAULT_DISABLE_USB_SUPPORT=0
set DEFAULT_ENABLE_PS2MOUSE_LEGACYBOOT=0
set DEFAULT_ENABLE_SECURE_BOOT=0
set DEFAULT_ENABLE_VBIOS_PATCH_CLOVEREFI=0
set DEFAULT_EXIT_USBKB=0
set DEFAULT_HAVE_LEGACY_EMURUNTIMEDXE=0
set DEFAULT_INCLUDE_DP=0
set DEFAULT_INCLUDE_TFTP_COMMAND=0
set DEFAULT_LODEPNG=1
set DEFAULT_NO_CLOVER_SHELL=0
set DEFAULT_NO_SHELL_PROFILES=0
set DEFAULT_ONLY_SATA_0=0
set DEFAULT_OPENSSL_VERSION=
set DEFAULT_REAL_NVRAM=1
set DEFAULT_SKIP_FLASH=0
set DEFAULT_USE_BIOS_BLOCKIO=0
set DEFAULT_USE_LOW_EBDA=0

::
:: START
::

call :FN_PARSE_ARGUMENTS %*
if errorlevel 1 (
  set MSG=Unknown error
  goto :LBL_FAIL
)

goto :LB_INIT

:FN_CREATE_DIR

  if not exist "%~1" mkdir "%~1"
  goto :EOF

rem # FN_COPY_BIN
:FN_COPY_BIN

  if not exist "%~1" goto :EOF
  call :FN_CREATE_DIR "%~2"
  echo -^> "%~3"
  copy /B /Y "%~1" "%~2\%~3">nul
  goto :EOF

rem # get filezize, sometimes broken
:FN_GET_FILE_SIZE

  set FILE_SIZE=%~z1
  goto :EOF

rem # set edk path
:FN_SET_EDK_PATH

  set "EDK_PATH=%~1"
  goto :EOF

rem # search edk path
:FN_SEARCH_EDK_PATH

  if exist edksetup.bat (
    echo Found EDK
    call :FN_SET_EDK_PATH "%~dp0"
    goto :EOF
  )

  rem # reach the root dir and still not found?

  if ["%CD%"] == ["%~d0%\"] (
    echo EDK not found
    goto :EOF
  )
  cd ..
  goto :FN_SEARCH_EDK_PATH

rem # call edk setup
:FN_CALL_EDK_SETUP

  call "%EDK_PATH%"\edksetup.bat %~1
  goto :EOF

rem # add build option
:FN_ADD_BUILD_OPTION

  set "%~1=1"
  set "BUILD_OPTIONS=%BUILD_OPTIONS% %~1"
  goto :EOF

rem # add safe check build option
:FN_SAFE_ADD_BUILD_OPTION

  set OPTION_STR=%~1
  call set DEFAULT_OPTION=%%DEFAULT_%OPTION_STR%%%
  call set OPTION=%%%OPTION_STR%%%
  if ["%OPTION%"] == [""] set "OPTION=%DEFAULT_OPTION%"
  if not ["%~2"] == [""] set "OPTION_STR=%OPTION_STR%=%~2"
  if not ["%OPTION%"] == [""] (
    if not ["%OPTION%"] == ["0"] call :FN_ADD_BUILD_OPTION "-D %OPTION_STR%"
  )
  goto :EOF

rem # initialize
:LB_INIT

  rem # git, "G" prefixed

  :LBL_GET_GIT_REVISION
    if not exist ".git\" goto :LBL_GET_SVN_REVISION
    git rev-list --count HEAD>%F_VER_TXT%
    set "DEV_STAGE=%DEV_STAGE%G"
    goto :LBL_GET_EXT_REVISION

  rem # svn, "S" prefixed

  :LBL_GET_SVN_REVISION
    if not exist ".svn\" goto :LBL_GET_EXT_REVISION
    set "DEV_STAGE=%DEV_STAGE%S"
    svnversion -n>%F_VER_TXT%

  rem # dev, "DEV_STAGE", eg: "B" for beta prefixed

  :LBL_GET_EXT_REVISION
    if not exist %F_VER_TXT% echo %DEFAULT_REVISION%>%F_VER_TXT%
    set /P REVISION=<%F_VER_TXT%

  if ["%REVISION%"] == [""] (
    set MSG=Invalid ^(local^) source
    goto :LBL_FAIL
  ) else (
    set REVISION=%REVISION%%DEV_STAGE%
  )

  rem # pass 1-call :param, and exit
  if ["%SHOW_USAGE%"] == ["1"] goto :LBL_USAGE

  rem # set any required path for edksetup

  if ["%CYGWIN_HOME%"]          == [""] set CYGWIN_HOME=%DEFAULT_CYGWIN_HOME%
  if ["%PYTHONHOME%"]           == [""] set PYTHONHOME=%DEFAULT_PYTHONHOME%
  if ["%PYTHON_HOME%"]          == [""] set PYTHON_HOME=%PYTHONHOME%
  if ["%PYTHON_PATH%"]          == [""] set PYTHON_PATH=%PYTHON_HOME%
  rem if ["%PYTHON_FREEZER_PATH%"]  == [""] set PYTHON_FREEZER_PATH=%DEFAULT_PYTHON_FREEZER_PATH%
  if ["%NASM_PREFIX%"]          == [""] set NASM_PREFIX=%DEFAULT_NASM_PREFIX%
  if ["%PACKAGES_PATH%"]        == [""] set PACKAGES_PATH=%DEFAULT_PACKAGES_PATH%

rem # setup build
:LBL_PREBUILD

  set EDK_SETUP_ARGS=

  rem # set edk path

  pushd .
  if ["%EDK_PATH%"] == [""] (
    echo Searching for EDK ...
    call :FN_SEARCH_EDK_PATH
  )
  popd

  if %EDK_PATH:~-1%==\ set EDK_PATH=%EDK_PATH:~0,-1%
  if not exist "%EDK_PATH%" goto :LBL_FAIL

  rem # set workspace as edk path if undefined

  if ["%WORKSPACE%"] == [""] set "WORKSPACE=%EDK_PATH%"
  if %WORKSPACE:~-1%==\ set WORKSPACE=%WORKSPACE:~0,-1%
  if not exist "%EDK_PATH%" goto :LBL_FAIL

  rem # check win32 basetools

  if ["%EDK_TOOLS_PATH%"] == [""] set "EDK_TOOLS_PATH=%EDK_PATH%\BaseTools"
  if %EDK_TOOLS_PATH:~-1%==\ set EDK_TOOLS_PATH=%EDK_TOOLS_PATH:~0,-1%
  if not exist "%EDK_TOOLS_PATH%" goto :LBL_FAIL

  set "BASETOOLS_DIR=%EDK_TOOLS_PATH%\Bin\Win32"
  if not ["%EDK_TOOLS_BIN%"] == [""] set "BASETOOLS_DIR=%EDK_TOOLS_BIN%"
  if %BASETOOLS_DIR:~-1%==\ set BASETOOLS_DIR=%BASETOOLS_DIR:~0,-1%

  rem # check conf path

  if exist "%CUSTOM_CONF_PATH%" set "CONF_PATH=%CUSTOM_CONF_PATH%"
  if ["%CONF_PATH%"] == [""] set "CONF_PATH=%WORKSPACE%\Conf"
  if %CONF_PATH:~-1%==\ set CONF_PATH=%CONF_PATH:~0,-1%

  rem # call edksetup to rebuild tools / reconfig

  if not exist "%CONF_PATH%"\target.txt     set EDK_SETUP_ARGS=Reconfig
  if not exist "%BASETOOLS_DIR%"\GenFw.exe  set "EDK_SETUP_ARGS=%EDK_SETUP_ARGS% ForceRebuild"

  if not ["%EDK_SETUP_ARGS%"] == [""] (
    call :FN_CALL_EDK_SETUP "%EDK_SETUP_ARGS%"
  )

  rem # pass 1-call :param, call edksetup and exit

  if not ["%EDK_BUILD_INFOS%"] == [""] (
    call :FN_CALL_EDK_SETUP
    goto :LBL_GET_EDK_BUILD_INFOS
  )

rem # Read target.txt. Dont look TARGET_ARCH, we build multi ARCH if undefined
:LBL_READ_TEMPLATE

  set EDK_CONF_TARGET_TXT="%CONF_PATH%"\target.txt
  findstr /v /r /c:"^#" /c:"^$" "%EDK_CONF_TARGET_TXT%">%F_TMP_TXT%
  for /f "tokens=1*" %%i in ('type %F_TMP_TXT% ^| findstr /i "TOOL_CHAIN_TAG"') do set SCAN_TOOLCHAIN%%j
  for /f "tokens=1*" %%i in ('type %F_TMP_TXT% ^| findstr /i "TARGET_ARCH"') do set SCAN_TARGET_ARCH%%j
  for /f "tokens=1*" %%i in ('type %F_TMP_TXT% ^| findstr /v /r /c:"TARGET_ARCH"  ^| findstr /i "TARGET"') do set SCAN_BUILD_TARGET%%j
  del %F_TMP_TXT%

  if not ["%SCAN_TOOLCHAIN%"] == [""] (
    set SCAN_TOOLCHAIN=%SCAN_TOOLCHAIN: =%
    if not ["%SCAN_TOOLCHAIN: =%"] == [""] set DEFAULT_TOOLCHAIN=%SCAN_TOOLCHAIN: =%
  )

  if not ["%BUILD_X64%"] == ["1"] (
    if not ["%BUILD_IA32%"] == ["1"] (
      if ["%SCAN_TARGET_ARCH%"] == [""] set "SCAN_TARGET_ARCH=%DEFAULT_TARGET_ARCH%"
      for %%i in (%SCAN_TARGET_ARCH%) do (
        if ["%%i"] == ["X64"] (
          set BUILD_X64=1
        ) else (
          if ["%%i"] == ["IA32"] (
            set BUILD_IA32=1
          )
        )
      )
    )
  )

  if not ["%SCAN_BUILD_TARGET%"] == [""] (
    set SCAN_BUILD_TARGET=%SCAN_BUILD_TARGET: =%
    if not ["%SCAN_BUILD_TARGET: =%"] == [""] set DEFAULT_BUILD_TARGET=%SCAN_BUILD_TARGET: =%
  )

  rem # set edksetup args

  if ["%TOOLCHAIN%"]     == [""]  set TOOLCHAIN=%DEFAULT_TOOLCHAIN%
  if ["%BUILD_TARGET%"]  == [""]  set BUILD_TARGET=%DEFAULT_BUILD_TARGET%
  if ["%THREAD_NUMBER%"] == [""]  set THREAD_NUMBER=%DEFAULT_THREAD_NUMBER%

  set EDK_SETUP_ARGS=

  if not ["%TOOLCHAIN:VS=%"] == ["%TOOLCHAIN%"] (
    rem remove x86 suffix
    set EDK_SETUP_ARGS=%TOOLCHAIN%
    if %TOOLCHAIN:~-2%==86 set EDK_SETUP_ARGS=%TOOLCHAIN:~0,-3%
  )

  rem # call edksetup for build

  call :FN_CALL_EDK_SETUP "%EDK_SETUP_ARGS%"

  ::LBL_LONG_FOLD_MACROS_FIX

  rem # list of current supported build macros, please keep em all up-to-date

  for %%i in (
    AMD_SUPPORT
    ANDX86
    DEBUG_ON_SERIAL_PORT
    DISABLE_LTO
    DISABLE_UDMA_SUPPORT
    DISABLE_USB_CONTROLLERS
    DISABLE_USB_SUPPORT
    ENABLE_PS2MOUSE_LEGACYBOOT
    ENABLE_SECURE_BOOT
    ENABLE_VBIOS_PATCH_CLOVEREFI
    EXIT_USBKB
    HAVE_LEGACY_EMURUNTIMEDXE
    INCLUDE_DP
    INCLUDE_TFTP_COMMAND
    LODEPNG
    NO_CLOVER_SHELL
    NO_SHELL_PROFILES
    ONLY_SATA_0
    REAL_NVRAM
    SKIP_FLASH
    USE_BIOS_BLOCKIO
    USE_LOW_EBDA
  ) do (
    call :FN_SAFE_ADD_BUILD_OPTION "%%i"
  )

  rem # sample calling FN_SAFE_ADD_BUILD_OPTION with add value as arg
  rem call :FN_SAFE_ADD_BUILD_OPTION "OPENSSL_VERSION" "0000"

  rem # check active platform, clover as default

  if ["%DSC_FILE%"] == [""] set DSC_FILE="%CURRENT_DIR%\Clover.dsc"
  if not exist "%DSC_FILE%" (
    set MSG=No Platform
    goto :LBL_USAGE
  )

  rem # check for add build sets, mainly to speedup dev proc

  if ["%GEN_PAGE%"]       == [""] set GEN_PAGE=%DEFAULT_GEN_PAGE%
  if ["%NO_BOOTLOADERS%"] == [""] set NO_BOOTLOADERS=%DEFAULT_NO_BOOTLOADERS%
  if ["%NO_BOOTSECTORS%"] == [""] set NO_BOOTSECTORS=%DEFAULT_NO_BOOTSECTORS%
  if ["%NO_COPY_BIN%"]    == [""] set NO_COPY_BIN=%DEFAULT_NO_COPY_BIN%

  rem # check at least we have 1 valid target arch to build
  rem # give X64 1st priority, IA32 as a fallback

  if not ["%BUILD_X64%"] == ["1"] (
    if ["%BUILD_IA32%"] == ["1"] (
      goto :LBL_BUILD_IA32
    ) else (
      set MSG=No build architecture
      goto :LBL_USAGE
    )
  )

  set TARGET_ARCH=X64
  set UEFI_DRV_LIST=(FSInject OsxFatBinaryDrv VBoxHfs)
  set UEFI_OFF_DRV_LIST=(CsmVideoDxe DataHubDxe EmuVariableUefi OsxAptioFixDrv OsxAptioFix2Drv OsxLowMemFixDrv PartitionDxe)
  set DRV_LIST=(NvmExpressDxe Ps2MouseDxe UsbMouseDxe VBoxIso9600 VBoxExt2 VBoxExt4 XhciDxe)
  goto :LBL_START_BUILD

:LBL_BUILD_IA32

  set TARGET_ARCH=IA32
  set UEFI_DRV_LIST=(FSInject OsxFatBinaryDrv VBoxHfs)
  set UEFI_OFF_DRV_LIST=(CsmVideoDxe)
  set DRV_LIST=(Ps2KeyboardDxe Ps2MouseAbsolutePointerDxe Ps2MouseDxe UsbMouseDxe VBoxExt2 VBoxExt4 XhciDxe)

:LBL_START_BUILD

  rem # set dest bin path

  set SIGNTOOL_BUILD_DIR=%CURRENT_DIR%\SignTool
  set SIGNTOOL_BUILD=BuildSignTool.bat
  set SIGNTOOL=%CURRENT_DIR%\SignTool\SignTool
  set BUILD_DIR=%WORKSPACE%\Build\Clover\%BUILD_TARGET%_%TOOLCHAIN%
  set DEST_DIR=%CURRENT_DIR%\CloverPackage\CloverV2
  set BOOTSECTOR_BIN_DIR=%CURRENT_DIR%\CloverEFI\BootSector\bin
  set BUILD_DIR_ARCH=%BUILD_DIR%\%TARGET_ARCH%

  set TARGET_ARCH_INT=%TARGET_ARCH:ia=%
  set TARGET_ARCH_INT=%TARGET_ARCH_INT:x=%

  set "DEST_BOOTSECTORS=%DEST_DIR%\BootSectors"
  set "DEST_BOOTLOADERS=%DEST_DIR%\Bootloaders"
  set "DEST_EFI=%DEST_DIR%\EFI"
  set "DEST_BOOT=%DEST_EFI%\BOOT"
  set "DEST_CLOVER=%DEST_EFI%\CLOVER"
  set "DEST_TOOLS=%DEST_CLOVER%\tools"
  set "DEST_DRIVER=%DEST_CLOVER%\drivers%TARGET_ARCH_INT%"
  set "DEST_OFF=%DEST_DIR%\drivers-Off\drivers%TARGET_ARCH_INT%"

  rem # shell bin copy path

  set "EDK_SHELL_PATH=%WORKSPACE%\EdkShellBinPkg\%EDK_SHELL_BIN_MODE%\%TARGET_ARCH%"
  set "EDK_SHELL_BIN_MIN_PATH=%EDK_SHELL_PATH%\Shell.efi"
  set "EDK_SHELL_BIN_FULL_PATH=%EDK_SHELL_PATH%\Shell_Full.efi"

  if exist "%EDK_SHELL_BIN_MIN_PATH%" (
    set EDK_SHELL_BIN_FIXED_PATH=%EDK_SHELL_BIN_MIN_PATH%
  ) else (
    if exist "%EDK_SHELL_BIN_FULL_PATH%" (
      set EDK_SHELL_BIN_FIXED_PATH=%EDK_SHELL_BIN_FULL_PATH%
    )
  )

  rem # set build args

  set LOG_FILE="%CURRENT_DIR%\CloverLog_%TARGET_ARCH%.txt"
  set "CMD_BUILD=build -a %TARGET_ARCH% -t %TOOLCHAIN% -b %BUILD_TARGET% -n %THREAD_NUMBER% -p %DSC_FILE% %BUILD_OPTIONS% -j %LOG_FILE%"

  for /f "tokens=2 delims=[]" %%x in ('ver') do set WINVER=%%x
  set WINVER=%WINVER:Version =%

  set CLOVER_BUILD_INFO=%CMD_BUILD%
  set CLOVER_BUILD_INFO=%CLOVER_BUILD_INFO:\=\\%
  set CLOVER_BUILD_INFO=%CLOVER_BUILD_INFO:"=\"%
  for /f "tokens=* delims= " %%A in ('echo %CLOVER_BUILD_INFO% ') do set CLOVER_BUILD_INFO=%%A
  set CLOVER_BUILD_INFO=%CLOVER_BUILD_INFO:~0,-1%
  set CLOVER_BUILD_INFO="Args: %~nx0 %* | Command: %CLOVER_BUILD_INFO% | OS: Win %WINVER%"

  rem # generate build date and time
  set BUILD_DATE=%date:~10,4%-%date:~4,2%-%date:~7,2% %time:~0,-3%

  rem # generate version.h
  echo // Autogenerated %F_VER_H%>%F_VER_H%
  echo #define FIRMWARE_VERSION "2.31">>%F_VER_H%
  echo #define FIRMWARE_BUILDDATE "%BUILD_DATE%">>%F_VER_H%
  echo #define FIRMWARE_REVISION L"%REVISION%">>%F_VER_H%
  echo #define REVISION_STR "Clover revision: %REVISION%">>%F_VER_H%
  echo #define BUILDINFOS_STR %CLOVER_BUILD_INFO%>>%F_VER_H%

 rem # launch clean build
:LBL_START_BUILD_CLEAN

  if ["%CLEANING%"] == [""] goto LBL_START_BUILD_CALL

  echo Start ^(%TARGET_ARCH%^) %CLEANING% ...
  rem # clean arg is currently broken on edk2-stable201908 tag
  rem call %CMD_BUILD% %CLEANING%
  rmdir "%BUILD_DIR_ARCH%" /S /Q 2>nul
  echo End ^(%TARGET_ARCH%^) %CLEANING% ...

rem # launch build
:LBL_START_BUILD_CALL

  echo Start ^(%TARGET_ARCH%^) build ...
  call %CMD_BUILD%
  echo End ^(%TARGET_ARCH%^) build ...

  if errorlevel 1 (
    set MSG=Error while building
    goto :LBL_FAIL
  )

:LBL_POST_BUILD

  rem # clean bin

  if ["%CLEANING%"] == [""] goto :LBL_FINALIZE_BUILD

  for /R "%DEST_BOOTSECTORS%" %%i in (boot0* boot1*) do del "%%i"
  for /R "%DEST_BOOTLOADERS%\%TARGET_ARCH%" %%i in (boot*) do del "%%i"
  for /R "%DEST_TOOLS%" %%i in (Shell*.efi) do ren "%%i" "%%~nxi.ctmp"
  for /R "%DEST_DIR%" %%i in (*%TARGET_ARCH%.efi *-%TARGET_ARCH_INT%.efi) do del /F /Q "%%i"
  for /R "%DEST_TOOLS%" %%i in (*.ctmp) do ren "%%i" "%%~ni"

:LBL_FINALIZE_BUILD

  echo Performing post build operations ...

  rem # Be sure that all needed directories exists
  call :FN_CREATE_DIR %DEST_BOOTSECTORS%
  call :FN_CREATE_DIR %DEST_BOOT%
  call :FN_CREATE_DIR %DEST_TOOLS%
  call :FN_CREATE_DIR %DEST_DRIVER%
  call :FN_CREATE_DIR %DEST_DRIVER%UEFI
  call :FN_CREATE_DIR %DEST_OFF%
  call :FN_CREATE_DIR %DEST_OFF%UEFI

  rem # fixme: openssl compilation error
  if ["%ENABLE_SECURE_BOOT%"] == ["1"] (
    rem echo Building signing tool ...
    rem pushd .
    rem cd "%SIGNTOOL_BUILD_DIR%"
    rem call :"%SIGNTOOL_BUILD%"
    rem popd
    rem if errorlevel 1 (
    rem   set MSG=Error while signing
    rem   goto :LBL_FAIL
    rem )
    echo.
    echo "ENABLE_SECURE_BOOT" doesnt work ATM ...
    echo.
  )

  rem # build bootloaders

  if ["%NO_BOOTLOADERS%"] == ["1"] goto LBL_COPY_BIN

  call :FN_CREATE_DIR %DEST_BOOTLOADERS%\%TARGET_ARCH%

  echo Compressing DUETEFIMainFv.FV ^(%TARGET_ARCH%^) ...
  LzmaCompress -e -q -o "%BUILD_DIR%\FV\DUETEFIMAINFV%TARGET_ARCH%.z" "%BUILD_DIR%\FV\DUETEFIMAINFV%TARGET_ARCH%.Fv"

  echo Compressing DxeMain.efi ^(%TARGET_ARCH%^) ...
  LzmaCompress -e -q -o "%BUILD_DIR%\FV\DxeMain%TARGET_ARCH%.z" "%BUILD_DIR%\%TARGET_ARCH%\DxeCore.efi"

  echo Compressing DxeIpl.efi ^(%TARGET_ARCH%^) ...
  LzmaCompress -e -q -o "%BUILD_DIR%\FV\DxeIpl%TARGET_ARCH%.z" "%BUILD_DIR%\%TARGET_ARCH%\DxeIpl.efi"

  echo Generating Loader Image ^(%TARGET_ARCH%^) ...
  EfiLdrImage -o "%BUILD_DIR%\FV\Efildr%TARGET_ARCH_INT%" "%BUILD_DIR%\%TARGET_ARCH%\EfiLoader.efi" "%BUILD_DIR%\FV\DxeIpl%TARGET_ARCH%.z" "%BUILD_DIR%\FV\DxeMain%TARGET_ARCH%.z" "%BUILD_DIR%\FV\DUETEFIMAINFV%TARGET_ARCH%.z"

  call :FN_GET_FILE_SIZE "%BUILD_DIR%\FV\Efildr%TARGET_ARCH_INT%"

  if ["%GEN_PAGE%"] == ["0"] (
    if not ["%USE_LOW_EBDA%"] == ["0"] (
      if not ["%FILE_SIZE%"] == [""]  (
        if %FILE_SIZE% gtr %EDBA_MAX% (
          echo warning: boot file bigger than low-ebda permits, switching to --std-ebda
          set USE_LOW_EBDA=0
        )
      )
    )
  )

  if ["%TARGET_ARCH%"] == ["X64"] (
    Setlocal EnableDelayedExpansion
      rem # first key index 0/1?
      rem set COM_NAMES=(H H2 H3 H4 H5 H6 H5 H6)
      set COM_NAMES[0]=H
      set COM_NAMES[1]=H2
      set COM_NAMES[2]=H3
      set COM_NAMES[3]=H4
      set COM_NAMES[4]=H5
      set COM_NAMES[5]=H6
      set /A "BLOCK=%GEN_PAGE% << 2 | %USE_LOW_EBDA% << 1 | %USE_BIOS_BLOCKIO%"
      set "BLOCK=COM_NAMES[%BLOCK%]"
      set STARTBLOCK=Start%TARGET_ARCH_INT%!%BLOCK%!.com
    Endlocal
  ) else if ["%USE_BIOS_BLOCKIO%"] == ["1"] (
    set STARTBLOCK=Start%TARGET_ARCH_INT%H.com2
  ) else (
    set STARTBLOCK=Start%TARGET_ARCH_INT%.com
  )
  set GENLDR=Efildr%TARGET_ARCH_INT%Pure
  if not ["%GEN_PAGE%"] == ["0"] set GENLDR=boot%TARGET_ARCH_INT%
  set GENLDR=%BUILD_DIR%\FV\%GENLDR%
  copy /B /Y "%BOOTSECTOR_BIN_DIR%\%STARTBLOCK%"+"%BOOTSECTOR_BIN_DIR%\efi%TARGET_ARCH_INT%.com3"+"%BUILD_DIR%\FV\Efildr%TARGET_ARCH_INT%" "%GENLDR%">nul
  set GENINT=-o "%BUILD_DIR%\FV\Efildr%TARGET_ARCH_INT%"
  if not ["%USE_LOW_EBDA%"] == ["0"] set GENINT= -b 0x88000 -f 0x68000 %GENINT%
  GenPage "%GENLDR%" %GENINT%
  Split -f "%BUILD_DIR%\FV\Efildr%TARGET_ARCH_INT%" -p %BUILD_DIR%\FV\ -o Efildr%TARGET_ARCH_INT%.1 -t boot%TARGET_ARCH_INT% -s 512
  del "%BUILD_DIR%\FV\Efildr%TARGET_ARCH_INT%.1"

  set /A "CLOVER_EFI_FILE=(%TARGET_ARCH_INT:~0,1% + %USE_BIOS_BLOCKIO%)"
  set CLOVER_EFI_FILE=boot%CLOVER_EFI_FILE%

rem # drop compiled files to dest EFI folder
:LBL_COPY_BIN

  if ["%NO_COPY_BIN%"] == ["1"] goto LBL_SKIP_COPY_BIN

  echo Start copying:

  echo Mandatory ^(UEFI^) drivers:

  set CP_DEST=%DEST_DRIVER%UEFI
  for %%i in %UEFI_DRV_LIST% do (
    call :FN_COPY_BIN "%BUILD_DIR_ARCH%\%%i.efi" "%CP_DEST%" "%%i-%TARGET_ARCH_INT%.efi"
  )

  echo Optional ^(UEFI^) drivers:

  set CP_DEST=%DEST_OFF%UEFI
  for %%i in %UEFI_OFF_DRV_LIST% do (
    call :FN_COPY_BIN "%BUILD_DIR_ARCH%\%%i.efi" "%CP_DEST%" "%%i-%TARGET_ARCH_INT%.efi"
  )

  echo Optional drivers:

  set CP_DEST=%DEST_OFF%
  for %%i in %DRV_LIST% do (
    call :FN_COPY_BIN "%BUILD_DIR_ARCH%\%%i.efi" "%CP_DEST%" "%%i-%TARGET_ARCH_INT%.efi"
  )

  echo CloverEFI + Applications:

  call :FN_COPY_BIN "%BUILD_DIR%\FV\boot%TARGET_ARCH_INT%" "%DEST_BOOTLOADERS%\%TARGET_ARCH%" "%CLOVER_EFI_FILE%"
  call :FN_COPY_BIN "%BUILD_DIR_ARCH%\bdmesg.efi" "%DEST_TOOLS%" "bdmesg-%TARGET_ARCH_INT%.efi"
  call :FN_COPY_BIN "%BUILD_DIR_ARCH%\CLOVER.efi" "%DEST_CLOVER%" "CLOVER%TARGET_ARCH%.efi"
  call :FN_COPY_BIN "%BUILD_DIR_ARCH%\CLOVER.efi" "%DEST_BOOT%" "BOOT%TARGET_ARCH%.efi"

  if ["%EDK_SHELL_BIN_FIXED_PATH%"] == [""] goto :LBL_DONE_BUILD

  echo EDK Shell ^(%EDK_SHELL%^):

  set CLOVER_SHELL_LIST=(Shell%TARGET_ARCH_INT%U Shell%TARGET_ARCH_INT%)
  for %%i in %CLOVER_SHELL_LIST% do (
    if not exist "%DEST_TOOLS%\%%i.efi.bak" (
      if exist "%DEST_TOOLS%\%%i.efi" (
        ren "%DEST_TOOLS%\%%i.efi" "%%i.efi.bak"
      )
    )
  )
  call :FN_COPY_BIN "%EDK_SHELL_BIN_FIXED_PATH%" "%DEST_TOOLS%" "Shell%TARGET_ARCH_INT%.efi"

:LBL_DONE_BUILD

  echo End copying ...

:LBL_SKIP_COPY_BIN

  if ["%BUILD_IA32%"] == ["1"] (
    if not ["%TARGET_ARCH%"] == ["IA32"] goto :LBL_BUILD_IA32
  )

  if ["%NO_BOOTSECTORS%"] == ["1"] goto LBL_DONE

  rem # build bootsectors

  echo Generating BootSectors ...

  pushd BootHFS
  set DESTDIR=%DEST_BOOTSECTORS%
  nmake /nologo /c /a /f Makefile.win
  popd

:LBL_DONE

  echo ### Build dir: "%BUILD_DIR%"
  echo ### EFI dir: "%DEST_DIR%\EFI"
  echo Done!
  exit /b 0

rem # print build infos
:LBL_GET_EDK_BUILD_INFOS

  if not exist %BASETOOLS_DIR% (
    set MSG=No basetools. Run edksetup
    goto :LBL_FAIL
  ) else (
    build %EDK_BUILD_INFOS%
    if errorlevel 1 (
      set MSG=Failed to retrieve infos
      goto :LBL_FAIL
    )
  )
  exit /b 0

rem # exit failed with add message
:LBL_FAIL

  if ["%MSG%"] == [""] (
    set MSG=Build failed
  )
  echo.
  echo !!! %MSG% !!!
  exit /b 0

rem # print the usage
:LBL_USAGE

  if not ["%MSG%"] == [""] (
    echo.
    echo !!! Error: %MSG% !!!
    echo.
  )
  rem echo.
  rem printf "Usage: %s [OPTIONS] [all|fds|genc|genmake|clean|cleanpkg|cleanall|cleanlib|modules|libraries]\n" "$SELF"
  echo Infos:
  echo --usage : print this message and exit
  echo --version : print build version and exit
  echo -h, --help : print build help and exit
  echo.
  echo Configurations:
  echo -n, --threadnumber ^<THREAD_NUMBER^> : build with multi-threaded [default CPUs + 1]
  echo -t, --tagname ^<TOOLCHAIN^> : force to use a specific toolchain
  echo -a, --arch ^<TARGET_ARCH^> : overrides target.txt's TARGET_ARCH definition
  echo -p, --platform ^<PLATFORMFILE^> : build the platform specified by the DSC argument
  echo -m, --module ^<MODULEFILE^> : build only the module specified by the INF argument
  echo -d, --define=^<MACRO^>, ex: -D ENABLE_SECURE_BOOT
  echo -b, --buildtarget ^<BUILD_TARGET^> : using the BUILD_TARGET to build the platform, or:
  echo                         --debug : set DEBUG buildtarget
  echo                       --release : set RELEASE buildtarget
  echo.
  echo Options:
  echo --vbios-patch-cloverefi : activate vbios patch in CloverEFI
  echo --only-sata0 : activate only SATA0 patch
  echo --std-ebda : ebda offset dont shift to 0x88000
  echo --genpage : dynamically generate page table under ebda
  echo --no-usb : disable USB support
  echo --mc : build in 64-bit [boot7] using BiosBlockIO ^(compatible with MCP chipset^)
  echo --edk2shell ^<MinimumShell^|FullShell^> : copy edk2 Shell to EFI tools dir
  echo.
  echo Extras:
  echo --cygwin : set CYGWIN dir ^(def: %DEFAULT_CYGWIN_HOME%^)
  echo --nasmprefix : set NASM bin dir ^(def: %DEFAULT_NASM_PREFIX%^)
  echo --pythonhome : set PYTHON dir ^(def: %DEFAULT_PYTHONHOME%^)
  echo --pythonfreezer : set PYTHON Freeze dir ^(def: %DEFAULT_PYTHON_FREEZER_PATH%^)
  rem echo.
  rem echo Report bugs to https://sourceforge.net/p/cloverefiboot/discussion/1726372/
  exit /b 0

:FN_PARSE_ARGUMENTS
  if ["%~1"] == [""] exit /b 0
  if ["%~1"] == ["--cygwin"] (
    if not ["%~2"] == [""] (
      set CYGWIN_HOME="%~2"
    )
  )
  if ["%~1"] == ["--nasmprefix"] (
    if not ["%~2"] == [""] (
      set NASM_PREFIX="%~2"
    )
  )
  if ["%~1"] == ["--pythonhome"] (
    if not ["%~2"] == [""] (
      set PYTHONHOME="%~2"
    )
  )
  if ["%~1"] == ["--pythonfreezer"] (
    if not ["%~2"] == [""] (
      set PYTHON_FREEZER_PATH="%~2"
    )
  )
  if ["%~1"] == ["-d"] (
    if not ["%~2"] == [""] (
      call :FN_ADD_BUILD_OPTION "-D %~2"
    )
  )
  if ["%~1"] == ["--define"] (
    if not ["%~2"] == [""] (
      call :FN_ADD_BUILD_OPTION "-D %~2"
    )
  )
  if ["%~1"] == ["-m"] (
    if not ["%~2"] == [""] (
      call :FN_ADD_BUILD_OPTION "-m %~2"
    )
  )
  if ["%~1"] == ["-b"] (
    set BUILD_TARGET=%2
  )
  if ["%~1"] == ["--buildtarget"] (
    set BUILD_TARGET=%2
  )
  if ["%~1"] == ["--debug"] (
    set BUILD_TARGET=DEBUG
  )
  if ["%~1"] == ["--release"] (
    set BUILD_TARGET=RELEASE
  )
  if ["%~1"] == ["-n"] (
    set THREAD_NUMBER=%2
  )
  if ["%~1"] == ["--threadnumber"] (
    set THREAD_NUMBER=%2
  )
  if ["%~1"] == ["-t"] (
    set TOOLCHAIN=%2
  )
  if ["%~1"] == ["--tagname"] (
    set TOOLCHAIN=%2
  )
  if ["%~1"] == ["-a"] (
    if /i ["%~2"] == ["X64"] (
      set BUILD_X64=1
    ) else (
      if /i ["%~2"] == ["IA32"] set BUILD_IA32=1
    )
  )
  if ["%~1"] == ["--arch"] (
    if /i ["%~2"] == ["X64"] (
      set BUILD_X64=1
    ) else (
      if /i ["%~2"] == ["IA32"] set BUILD_IA32=1
    )
  )
  if ["%~1"] == ["-p"] (
    set DSC_FILE=%2
  )
  if ["%~1"] == ["--platform"] (
    set DSC_FILE=%2
  )
  if ["%~1"] == ["--vbios-patch-cloverefi"] (
    set ENABLE_VBIOS_PATCH_CLOVEREFI=1
  )
  if ["%~1"] == ["--only-sata0"] (
    set ONLY_SATA_0=1
  )
  if ["%~1"] == ["--std-ebda"] (
    set USE_LOW_EBDA=0
  )
  if ["%~1"] == ["--genpage"] (
    set GEN_PAGE=1
  )
  if ["%~1"] == ["--mc"] (
    set BUILD_X64=1
    set USE_BIOS_BLOCKIO=1
  )
  if ["%~1"] == ["--no-usb"] (
    set DISABLE_USB_SUPPORT=1
  )
  if ["%~1"] == ["--edk2shell"] (
    set EDK_SHELL_BIN_MODE=%2
  )
  if ["%~1"] == ["--beta"] (
    set DEV_STAGE=b
  )
  if ["%~1"] == ["-h"] (
    set EDK_BUILD_INFOS=%1
  )
  if ["%~1"] == ["--help"] (
    set EDK_BUILD_INFOS=%1
  )
  if ["%~1"] == ["--version"] (
    set EDK_BUILD_INFOS=%1
  )
  if ["%~1"] == ["--usage"] (
    set SHOW_USAGE=1
  )
  if /i ["%~1"] == ["clean"] (
    set CLEANING=clean
  )
  if /i ["%~1"] == ["cleanall"] (
    set CLEANING=cleanall
  )
  shift
  goto :FN_PARSE_ARGUMENTS
