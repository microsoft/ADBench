%
% function r = adimat_opdiff_subsasgn(d_val, sel, rhs)
%
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_opdiff_subsasgn(d_val, sel, rhs)
  last = sel(end);
  r = d_val;
  if ~strcmp(last.type, '()')
    r = subsasgn(r, sel, rhs);
  else
    if isstruct(rhs)
      if isempty(r)
        r = repmat(struct(), 0, 0);
      end
      r = subsasgn(r, sel, rhs);
    else
      % last is ()-index

      if length(sel) > 1
        try 
          r = subsref(r, sel(1:end-1));
        catch
          r = [];
        end
      end

      if isempty(rhs)
        [ndd order nel] = size(r);
        resc = cell(ndd, order, 1);
        rsz = adimat_t_size(r);
        for d=1:ndd
          for o=1:order
            rd = reshape(r(d,o,:), rsz);
            rd = subsasgn(rd, last, []);
            resc{d, o} = reshape(rd, [1 1 size(rd)]);
          end
        end
      else
        [ndd order nel] = size(rhs);
        resc = cell(ndd, 1);
        rhssz = adimat_t_size(rhs);
        if isempty(r)
          for d=1:ndd
            for o=1:order
              rhsd = reshape(rhs(d,o,:), rhssz);
              rd = subsasgn([], last, rhsd);
              resc{d, o} = reshape(rd, [1 1 size(rd)]);
            end
          end
        else
          rsz = adimat_t_size(r);
          for d=1:ndd
            for o=1:order
              rd = reshape(r(d,o,:), rsz);
              rhsd = reshape(rhs(d,o,:), rhssz);
              rd = subsasgn(rd, last, rhsd);
              resc{d, o} = reshape(rd, [1 1 size(rd)]);
            end
          end
        end
      end
      r = cell2mat(resc);
    end

    % last is ()-index
    if length(sel) > 1
      r = subsasgn(d_val, sel(1:end-1), r);
    end

  end
  
% $Id: adimat_opdiff_subsasgn.m 3343 2012-07-24 16:15:16Z willkomm $
