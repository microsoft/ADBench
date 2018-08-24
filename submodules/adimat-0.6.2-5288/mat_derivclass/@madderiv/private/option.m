function res= option(cmd, val)
% ADDERIV/PRIVATE/OPTION -- Set and get options.
%
% Copyright 2003, 2004 Andre Vehreschild, Inst. f. Scientific Computing
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

persistent options

if isempty(options)
   options= clearAll(options);
end

if nargin>1
   % Set data !!!
   switch cmd
   case {'ndd', 'NumberOfDirectionalDerivatives'}
%      if options.NumDirDeriv==0
         options.NumDirDeriv= val;
%      elseif options.NumDirDeriv~=val
%         error('All derivative object have to store the same number of directional derivatives.');
%      end        
   case 'ADiMatHome'
      options.ADiMatHome= val;
   case 'Version'
       error('The version of ADiMat can not be modified.');
   otherwise
      error('Unknown option!');
   end
else
   % Get data !!!
   switch cmd
   case {'ndd', 'NumberOfDirectionalDerivatives'}
      res= options.NumDirDeriv;
   case 'ADiMatHome'
      res= options.ADiMatHome;
   case 'Version'
      res= options.Version;
   case 'Revision'
      res = options.Revision;
   case 'VersionString'
      res = options.VersionString;
   case 'ClearAll'
      options.NumDirDeriv= 0;
      warning('ADiMat:clearOptionswarning', ...
              'All AD-options are set back to defaults.');
      res= [];
   case 'DerivativeClassName'
      res = 'madderiv';
   case 'DerivativeClassVersion'
      res = 0.2;
   case 'DerivativeClassKind'
      res = 'madderiv 0.2';
   otherwise
      error('Unknown option!');
   end
end

function options= clearAll(options)
   [va vb vc] = adimat_version;
   adimathome = adimat_home;
   
   options=struct('ADiMatHome', adimathome, ...
                  'Version', va, ...
                  'Revision', vb, ...
                  'VersionString', vc, ...
                  'NumDirDeriv', 0);

% vim:sts=3:
% Local Variables:
% mode: matlab
% End:
