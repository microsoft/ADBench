function varargout = adimat_diff_spdiags2(varargin)
   varargout{1} = calln(@($@TMP2, $@TMP3) spdiags($@TMP2, varargin{3}, $@TMP3), varargin{1}, varargin{4});
end
% automatically generated from $Id: derivatives-vdd.xml 4891 2015-02-16 11:03:40Z willkomm $
