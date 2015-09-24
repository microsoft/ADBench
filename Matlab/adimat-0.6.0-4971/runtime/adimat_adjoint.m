% function r = adimat_adjoint(name)
%   get/set name of adjoint implementation
%
% adimat_adjoint('default')
%   - this uses the current adderiv implementation
%
% adimat_adjoint('scalar')
%   - this uses scalar adjoint (i.e. simple double objects of the same
%     size as the program values). You can only get one derivative direction
%     at a time
%
% adimat_adjoint('taylor')
%
% adimat_adjoint('taylor2')
%
% adimat_adjoint('taylor3')
%   - these are for use by admHessian, for the OO over RM approach to
%   compute the Hessian.
%
% adimat_adjoint(path)
%   - this simply calls addpath(path)
%
% see also a_zeros, g_zeros, adimat_stack
%
% Using octave, only the scalar adjoints are available.
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_adjoint(name)
  persistent adjointName;
  if nargin > 0
    adimathome = adimat_home;
    if ispc
      adimat_prefix = adimathome;
    else
      adimat_prefix = [ adimathome '/share/adimat'];
    end
    paths = { [adimat_prefix '/adjointclasses/scalar']
              [adimat_prefix '/adjointclasses/default']
              [adimat_prefix '/adjointclasses/taylor']
              [adimat_prefix '/adjointclasses/taylor2'] 
              [adimat_prefix '/adjointclasses/taylor3'] 
            };
    for k=1:length(paths)
      p1 = paths{k};
      if ~isempty(strfind(path, [p1 ':'])) ...
            || ~isempty(strfind(path, [p1 ';']))
        rmpath(p1);
      end
    end
    adjointName = name;
    switch name
      case {'default', 'scalar', 'taylor', 'taylor2', 'taylor3'}
       addpath([adimat_prefix '/adjointclasses/' name]);
     otherwise
      addpath(name);
    end
  else
    r = adjointName;
  end

% $Id: adimat_adjoint.m 4723 2014-09-19 12:12:09Z willkomm $
