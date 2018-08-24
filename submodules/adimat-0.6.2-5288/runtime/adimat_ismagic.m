function r = adimat_ismagic(varargin)
  s = varargin{1};
  tinfo = whos('s');
  r = strcmp(tinfo.class, 'magic-colon') || (ischar(s) && (s==':'));
