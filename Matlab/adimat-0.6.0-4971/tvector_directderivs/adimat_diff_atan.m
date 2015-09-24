function varargout = adimat_diff_atan(varargin)

        varargout{2} = atan(varargin{2});
        dai = i .* varargin{1};
        ai = i .* varargin{2};
        r1 = 1 - ai;
        r2 = 1 + ai;
        darg = adimat_opdiff_ediv(-dai, r1, dai, r2);
        varargout{1} = 0.5 .* i .* adimat_diff_log(darg, r1 ./ r2 );
      
end
% automatically generated from $Id: derivatives-tvdd.xml 4017 2014-04-10 08:55:21Z willkomm $
