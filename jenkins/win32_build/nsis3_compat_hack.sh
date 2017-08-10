#! /bin/sh
# 

sed -i -e 's@Plugins\InstallOptions.dll@Plugins\x86-unicode\InstallOptions.dll@' cmake/modules/NSIS.template.in

pushd admin/win/nsi/l10n
iconv -t UTF8 -f CP1252 -o German.nsh German.nsh
iconv -t UTF8 -f CP1252 -o Basque.nsh Basque.nsh
iconv -t UTF8 -f CP1252 -o English.nsh English.nsh
iconv -t UTF8 -f CP1252 -o Galician.nsh Galician.nsh
iconv -t UTF8 -f CP1253 -o Greek.nsh Greek.nsh
iconv -t UTF8 -f CP1250 -o Slovenian.nsh Slovenian.nsh
iconv -t UTF8 -f CP1257 -o Estonian.nsh Estonian.nsh
iconv -t UTF8 -f CP1252 -o Italian.nsh Italian.nsh
iconv -t UTF8 -f CP1252 -o PortugueseBR.nsh PortugueseBR.nsh
iconv -t UTF8 -f CP1252 -o Spanish.nsh Spanish.nsh
iconv -t UTF8 -f CP1252 -o Dutch.nsh Dutch.nsh
iconv -t UTF8 -f CP1252 -o Finnish.nsh Finnish.nsh
iconv -t UTF8 -f CP932 -o Japanese.nsh Japanese.nsh
iconv -t UTF8 -f CP1250 -o Slovak.nsh Slovak.nsh
iconv -t UTF8 -f CP1254 -o Turkish.nsh Turkish.nsh
iconv -t UTF8 -f CP1252 -o Norwegian.nsh Norwegian.nsh
iconv -t UTF8 -f CP1250 -o Polish.nsh Polish.nsh
iconv -t UTF8 -f CP852  -o Czech.nsh Czech.nsh
popd

cp /usr/share/nsis/Plugins/UAC.dll /usr/share/nsis/Plugins/x86-ansi/
cp /usr/share/nsis/Plugins/UAC.dll /usr/share/nsis/Plugins/x86-unicode/
cp /usr/share/nsis/Plugins/nsProcess.dll /usr/share/nsis/Plugins/x86-ansi/
cp /usr/share/nsis/Plugins/nsProcess.dll /usr/share/nsis/Plugins/x86-unicode/

