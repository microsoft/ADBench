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
        ndd = size(r, 1);
        resc = cell(ndd, 1);
        rsz = adimat_d_size(r);
        for d=1:ndd
          rd = reshape(r(d,:), rsz);
          rd = subsasgn(rd, last, []);
          resc{d} = reshape(rd, [1 size(rd)]);
        end
      else
        ndd = size(rhs, 1);
        resc = cell(ndd, 1);
        rhssz = adimat_d_size(rhs);
        if isempty(r)
          for d=1:ndd
            rhsd = reshape(rhs(d,:), rhssz);
            rd = subsasgn([], last, rhsd);
            resc{d} = reshape(rd, [1 size(rd)]);
          end
        else
          rsz = adimat_d_size(r);
          for d=1:ndd
            rd = reshape(r(d,:), rsz);
            rhsd = reshape(rhs(d,:), rhssz);
            rd = subsasgn(rd, last, rhsd);
            resc{d} = reshape(rd, [1 size(rd)]);
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
  
% $Id: adimat_opdiff_subsasgn_old.m 4355 2014-05-28 11:10:28Z willkomm $
