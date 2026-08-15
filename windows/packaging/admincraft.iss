; Inno Setup script for the Windows installer.
;
; Driven by the release workflow, which passes the version and the folder that
; `flutter build windows` produced:
;
;   iscc /DAppVersion=2.0.0 /DSourceDir=..\..\build\windows\x64\runner\Release ^
;        /DOutputDir=..\..\dist windows\packaging\admincraft.iss

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\dist"
#endif

#define AppName "Admincraft"
#define AppPublisher "Joan Roig"
#define AppURL "https://github.com/joanroig/admincraft"
#define AppExeName "admincraft.exe"

[Setup]
AppId={{8F1C6A2E-7B44-4E1D-9C3A-5D2F0B7E4A91}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}/issues
; Shown on the installer's welcome page and in Apps & features, so someone who
; installs without reading anything else still sees it.
AppComments=NOT AN OFFICIAL MINECRAFT PRODUCT. NOT APPROVED BY OR ASSOCIATED WITH MOJANG OR MICROSOFT. Minecraft is a trademark of Mojang Synergies AB.
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
UninstallDisplayIcon={app}\{#AppExeName}
; Per-user install so no elevation prompt is needed.
PrivilegesRequired=lowest
OutputDir={#OutputDir}
OutputBaseFilename=admincraft-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
; Refuse to install the 64-bit build on a 32-bit system.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Files]
; The whole Release folder: the exe alone will not run without the Flutter
; runtime DLLs and the data directory beside it.
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent
