function varargout=subsref(g, i)
%MADDERIV/SUBSREF Index into to derivative object
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

switch i(1).type
case '{}'
   if g.dims==1
      ind= i(1).subs{1};
      if size(i(1).subs,2)>1
         i(1).subs= i(1).subs{2:end};
      else
         i(1)=[];
      end
      if ischar(ind) && ind==':'
         if size(i, 2)> 0
            varargout= {subsref(g.deriv, i)};
         else
            varargout= mat2cell(g.deriv, ones(1,g.ndd(1))*g.sz(1), ...
                     ones(1,g.ndd(2))* g.sz(2));
         end
      elseif max(ind)<= g.ndd(2)
         numind= length(ind);
         index= (repmat(ind(:)- 1, 1, g.sz(2))* g.sz(2)+ ...
            repmat(1: g.sz(2), numind, 1))';
         index= index(:);
         if size(i, 2)> 0
            varargout= {subsref(g.deriv(:,index'), i)};
         else
            varargout= mat2cell(g.deriv(:,index'), g.sz(1), ...
                  ones(1, numind)* g.sz(2));
         end
      else
         error('Index %d out of range 1: %d', max(ind), g.ndd(2));
      end
   else
      if length(i(1).subs)<2
         error('Need two indices to address twodimensional derivative.');
      end
      ind= {i(1).subs{1:2}};
      if size(i(1).subs,2)>2
         i(1).subs= i(1).subs{3:end};
      else
         i(1)=[];
      end
      if ischar(ind{1}) && ind{1}==':'
         ind{1}= 1:(g.ndd(1)*g.sz(1));
      elseif max(ind{1})> g.ndd(1)
         error('First index %d out of range 1: %d', max(ind{1}), g.ndd(1));
      else
         ind{1}= repmat(ind{1}, 1, g.ndd(1))+ reshape(...
               repmat(((0:(g.ndd(1)-1))*g.sz(1))', 1, length(ind{1}))', 1,...
                  length(ind{1})* g.ndd(1));
      end
      if ischar(ind{2}) && ind{2}==':'
         ind{2}= 1: (g.ndd(2)*g.sz(2));
      elseif max(ind{2})>g.ndd(2)
         error('Second index %d out of range 1: %d', max(ind{2}), g.ndd(2));
      else
         ind{2}= repmat(ind{2}, 1, g.ndd(2))+ reshape(...
               repmat(((0:(g.ndd(2)-1))*g.sz(2))', 1, length(ind{2}))', 1,...
                  length(ind{2})* g.ndd(2));
      end
      if size(i, 2)> 0
         varargout= {subsref([g.deriv{ind{:}}], i)};
      else
         varargout= {g.deriv{ind{:}}};
      end
   end
case '()'
   res= g;
   inddim= size(i.subs, 2);
   switch inddim % Switch on the dimension of the index
      case 1
         if islogical(i.subs{1})
            % Replicate the logical index.
            res.deriv= g.deriv(repmat(i.subs{1}, g.ndd));
            % The result is a column vector, where all entries of 1st ndd,
            % 2nd ndd and so on are written successively in the vector
            % Now compute the number of entries in each dd; prod(g.ndd), 
            % because of support for second order derivatives.
            res.sz= [numel(res.deriv)./ (g.ndd(1).*g.ndd(2)), 1];
            % The result has the same orientation as g, if both g  and i.subs
            % are a vectors.
            if isvector(i.subs{1}) && (g.sz(1)==1) && (g.sz(2)>1)
              res.sz= [res.sz(2), res.sz(1)]; 
            end
            % Now fix the data accordingly.
            res.deriv= reshape(res.deriv, res.sz.* res.ndd);
            varargout{1}= res;
            return;
         else
            myfind= i.subs{1};
            sind= 1;
         end
      case 2
         myfind= i.subs{1};
         sind= i.subs{2};
      otherwise
         error('Dimension of index is restricted to two dimensions. Current index is %d dimensional.', inddim);
   end

   % Handle colon operator in second index.
   if isa(sind, 'char') && sind==':'
      sind= 1: g.sz(2);
	end

   % The length of the indexing vectors is needed often later on.
   lfind= prod(size(myfind));
   lsind= length(sind);
   % Handle colon operator in first index.
   colonfind= isa(myfind,'char') && myfind==':';
   if colonfind
      % This has to be treated differently for one and two indices.
		if inddim==2 
         lfind= g.sz(1);
		else
         lfind= prod(g.sz);
		end
      myfind= (1: lfind)';
    end
   
   % Set the size of the resulting object
   if inddim==2
      % Two indices. The length of each index gives the size of the result.
      res.sz= [lfind, lsind];
   elseif ~isvector(myfind) || ~(any(g.sz==1) && any(g.sz>1))
      % The index is not a vector or the source is not a vector.
      % The result than has the size of the index.
      res.sz= size(myfind);
   elseif g.sz(1)==1 && g.sz(2)>1 && ~colonfind
      % Index is vector, the source g is a row vector and the index is not 
      % the result of a colon-expression (':'), then the result object is a
      % row vector, too and has the length of the first index.
	   res.sz= [lsind, lfind];
   else
      % In all other cases the result is a column vector and has the 
      % length of the first index.
      res.sz= [lfind, lsind];
   end
   % Compute the base of each directional derivative.
   basefind= (0:prod(g.ndd)- 1).* prod(g.sz);
   % Replicate that base numel(index) times:
   basefind= basefind(ones(lfind*lsind,1), :);
   %  begin: repfind = repmat(myfind, g.ndd.* [1, lsind]);
   t1= ones(1, g.ndd(1));
   t2= (1: lfind)';
   t2= t2(:, ones(1, g.ndd(2)* lsind));
   myfind= myfind(:)';
   repfind= myfind(t1, t2);
   %  end: repfind = repmat(myfind, g.ndd.* [1, lsind]);
   %  begin: repsind = repmat(sind- 1, g.ndd.* [lfind, 1]);
   t2= (1: lsind)';
   t1= ones(1, g.ndd(1)* lfind);
   t2= t2(:, ones(1, g.ndd(2)));
   sind= ((sind(:)- 1).* g.sz(1))';
   repsind= sind(t1, t2);
   %  end: repsind = repmat(sind- 1, g.ndd.* [lfind, 1]);
   index= basefind(:)+ repfind(:)+ repsind(:);
   deriv= zeros(res.sz.* res.ndd); % Need to alloc the memory
   deriv(:)= g.deriv(index);
   res.deriv= cond_sparse(deriv);
   varargout{1}= res;
case '.'
   %res= madderiv(g);
   %i(1)=[];
   %res.deriv= subsref(g.deriv, i);
   %varargout{1}= res;
   error('madderiv/subsref for structure: Not supported, and should not need to be supported.');
otherwise
   error('Internal error.');
end

