set srcfile=%1
set bindir=%2
set awfuldir=%3
set dval=%4
set kval=%5

mex -I%awfuldir% -outdir %bindir% %srcfile%
