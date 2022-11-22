@echo off

CALL deps\build-luajit.cmd
CALL deps\build-llhttp.cmd
CALL deps\build-openssl.cmd
CALL deps\build-luaopenssl.cmd
CALL deps\build-luv.cmd
CALL deps\build-zlib.cmd
CALL deps\build-pcre2.cmd
