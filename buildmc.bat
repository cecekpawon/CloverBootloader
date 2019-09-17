@echo off
rem # 2019 cecekpawon

set "CURRENT_DIR=%~dp0"
cd /D "%CURRENT_DIR%"

set BUILD_IA32=
set BUILD_X64=
set BUILDTARGET=
set BUILDTARGET=RELEASE
set "CYGWIN_HOME=c:\cygwin"
set DSCFILE=
set "IASL_PREFIX=c:\ASL\"
set "NASM_PREFIX=%CYGWIN_HOME%\bin\"
rem set "PYTHON_FREEZER_PATH=%PYTHONHOME%\Scripts"
rem set "PYTHONHOME=d:\Program File\Python37"
set "PYTHONHOME=c:\Python3"
set REVISION=0000
set THREADNUMBER=%NUMBER_OF_PROCESSORS%
set TOOLCHAIN=VS2015x86
set TOOLCHAIN=VS2017

set GENPAGE=0
set NOBOOTFILES=1
set EDK2SHELL=

set AMD_SUPPORT=1
set ANDX86=1
set DEBUG_ON_SERIAL_PORT=0
set DISABLE_LTO=0
set DISABLE_UDMA_SUPPORT=0
set DISABLE_USB_CONTROLLERS=0
set DISABLE_USB_SUPPORT=0
set ENABLE_PS2MOUSE_LEGACYBOOT=0
set ENABLE_SECURE_BOOT=0
set ENABLE_VBIOS_PATCH_CLOVEREFI=0
set EXIT_USBKB=0
set HAVE_LEGACY_EMURUNTIMEDXE=0
set INCLUDE_DP=0
set INCLUDE_TFTP_COMMAND=0
set NO_SHELL_PROFILES=0
set ONLY_SATA_0=0
set REAL_NVRAM=1
set SKIP_FLASH=1
set USE_BIOS_BLOCKIO=0
set USE_LOW_EBDA=0

rem -D AMD_SUPPORT -D ANDX86 -D DEBUG_ON_SERIAL_PORT -D DISABLE_LTO -D DISABLE_UDMA_SUPPORT
rem -D DISABLE_USB_CONTROLLERS -D DISABLE_USB_SUPPORT -D ENABLE_PS2MOUSE_LEGACYBOOT -D ENABLE_SECURE_BOOT
rem -D ENABLE_VBIOS_PATCH_CLOVEREFI -D EXIT_USBKB -D HAVE_LEGACY_EMURUNTIMEDXE -D INCLUDE_DP -D INCLUDE_TFTP_COMMAND
rem -D NO_SHELL_PROFILES -D ONLY_SATA_0 -D REAL_NVRAM -D SKIP_FLASH -D USE_BIOS_BLOCKIO -D USE_LOW_EBDA

call cbuild.bat -a X64 -a IA32 cleanall