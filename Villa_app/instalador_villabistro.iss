#define MyAppName "Villa Bistro Mobile"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Sua Empresa"
#define MyAppURL "https://seusite.com"
#define MyAppExeName "villabistromobile.exe"
#define WebView2URL "https://go.microsoft.com/fwlink/p/?LinkId=2124703"

[Setup]
AppId={{AUTO}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=.\instalador_output
OutputBaseFilename=setup_villabistro
SetupIconFile=C:\caminho\para\seu\icone.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTA: O caminho acima deve apontar para a pasta de build do seu projeto Flutter.

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
const
  WebView2RegKey = 'SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}';
  WebView2RegValue = 'pv';

function IsWebView2Installed: Boolean;
begin
  Result := RegQueryStringValue(HKLM, WebView2RegKey, WebView2RegValue, '');
end;

function InitializeSetup(): Boolean;
var
  ErrorCode: Integer;
  WebView2Path: string;
begin
  Result := True;
  if not IsWebView2Installed then
  begin
    if MsgBox('O WebView2 Runtime da Microsoft é necessário para rodar este aplicativo. Deseja baixá-lo e instalá-lo agora?', mbConfirmation, MB_YESNO) = IDYES then
    begin
      WebView2Path := ExpandConstant('{tmp}\MicrosoftEdgeWebView2RuntimeInstallerX64.exe');
      if not DownloadPage(ExpandConstant('{#WebView2URL}'), WebView2Path) then
      begin
        MsgBox('Falha ao baixar o instalador do WebView2. Verifique sua conexão com a internet e tente novamente.', mbError, MB_OK);
        Result := False;
      end
      else
      begin
        if not Exec(WebView2Path, '/silent /install', '', SW_SHOW, ewWaitUntilTerminated, ErrorCode) then
        begin
          MsgBox('Ocorreu um erro durante a instalação do WebView2. Código de erro: ' + IntToStr(ErrorCode), mbError, MB_OK);
          Result := False;
        end;
      end;
    end
    else
    begin
      MsgBox('A instalação foi cancelada porque o WebView2 Runtime é um componente obrigatório.', mbInformation, MB_OK);
      Result := False;
    end;
  end;
end;