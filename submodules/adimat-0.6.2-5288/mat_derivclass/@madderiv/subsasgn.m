function g= subsasgn(g,index,varargin)
%MADDERIV/SUBSASGN Assign a value to the derivative object.
%
% MATLAB upto version 7.0.4.352 crashes reproducably when in g_a{index}
% length(index)>1
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!


switch index(1).type
case '{}'
   if g.dims==1
      if ischar(index(1).subs{1}) && index(1).subs{1}==':'
         if length(varargin)== g.ndd(2)
            g.deriv= [varargin{:}];
            g.sz= size(g.deriv)./ g.ndd;
         else
            error('In "g_a{:}= cellarray" the number of entries in the cellarray (curr.: %d) must match the number of directional derivatives in g_a (curr.: %d).', length(varargin), g.ndd(2));
         end
      elseif all(index(1).subs{1}<= g.ndd(2))
         ind= (index(1).subs{1}-1).*g.sz(2);
         ind= ind(:); % Column vector, do not use transpose above.
                      % ind(:) is guaranteed to be a col-vector, but
                      % arg{1} does not need to be.
         ind= ind(:,ones(1, g.sz(2)))'; % Replicate
         mat= (1:g.sz(2))';
         mat= mat(:,ones(1, length(index(1).subs{1}))); % Replicate
         if size(index(1).subs,2)==1 && length(index)==1
            g.deriv(:,ind(:)+ mat(:))= [varargin{:}];
         else
            index(1).subs= {index(1).subs{2:end}};
            if isempty(index(1).subs)
               index(1)= []; % Delete first entry if empty
            end
            g.deriv(:,ind(:)+mat(:))= subsasgn(g.deriv(:,ind(:)+mat(:)), ...
                  index, varargin{:});
         end
      else
         error('Index %d:%d out of range 1: %d', min(index(1).subs{1}), ...
               max(index(1).subs{1}), g.ndd(2));
      end
   else
      warning('g_a{i,j} for g_a.dim>1 not tested yet.');
      if size(index(1).subs,2)==2
         if all([index(1).subs{1:2}]<= [g.ndd(:)]')
            if size(index, 2)> 1
               g.deriv(index(1).subs{1}.*(1:g.sz(1)), index(1).subs{2}.*(1:g.sz(2)))= ...
                  subsasgn(g.deriv(index(1).subs{1}.*(1:g.sz(1)), index(1).subs{2}.*(1:g.sz(2))), index(2:end), varargin{:});
            else
               g.deriv(index(1).subs{1}.*(1:g.sz(1)), index(1).subs{2}.*(1:g.sz(2)))= varargin{:};
            end
         else
            error('Index %d,%d out of range 1: %d', index(1).subs{1}, index(1).subs{2}, g.ndd(1), g.ndd(2));
         end
      else
         if size(index(1).subs,2)<2
            error('Two-dimensional derivative objects have to be addressed using two indeces.');
         end
         ind1= index(1).subs{1}.*(1:g.sz(1));
         ind2= index(1).subs{2}.*(1:g.sz(2));
         index(1).subs= index(1).subs{3:end};
         g.deriv(ind1, ind2)= subsasgn (g.deriv(ind1, ind2), index, varargin{:});
      end
   end
case '()'
   inp= varargin{1};

   % True, if this assignment deletes entries from the deriv. obj.
   deletemode= isempty(inp);
   if deletemode
      % inp has to be a derivative object or empty. If it is empty,
      % then create an empty derivative object. Because either
      % varargin{1} or g is a derivative object to execute this method
      % we are save to assume, that in this case g is a deriv. obj. and
      % we do not need to access the default of the options.
      inp= madderiv(g.ndd, [], 'empty');
   elseif ~isa(inp, 'madderiv')
      % If inp is not empty and no derivative object we have a problem
      % to report.
      error('Right-hand side object has to be a derivative object.');
   end

   % The result has to be a derivative object.
   emptyg= ~isa(g, 'madderiv');
   if emptyg
      g= madderiv([], [], 'empty');
   end
   if g.dims==inp.dims
      if isequal(g.ndd, inp.ndd)
         inddim= size(index.subs,2);
         switch inddim % Switch on the dimension of the index
            case 1
               if islogical(index.subs{1})
                  if all(inp.sz==1) % The input adobject is a scalar
                     repinp= repmat(inp.deriv(:)', nnz(index.subs{1}), 1);
                     g.deriv(repmat(index.subs{1}, g.ndd))= repinp(:);
                  else
                     g.deriv(repmat(index.subs{1}, g.ndd))= inp.deriv;
                  end
                  return;
               else
                  myfind= index.subs{1};
                  sind= 1;
               end
            case 2
               myfind= index.subs{1};
               sind= index.subs{2};
            otherwise
               error('Dimension of index is restricted to two dimensions. Current index is %d dimensional.', inddim);
         end

        % Handle colon operator in second index.
         if isa(sind, 'char') && sind==':'
            if emptyg
               sind= 1: inp.sz(2);
            else
               sind= 1: g.sz(2);
            end
         end

         % The former size of g is needed later on.
         oldgsz= g.sz;

         % Handle colon operator in first index.
         colonfind= isa(myfind,'char') && myfind==':';
         if colonfind
            % This has to be treated differently for one and two indices.
            if inddim==2
               if emptyg
                  myfind= 1: inp.sz(1);
               else
                  myfind= 1: g.sz(1);
               end
            else
               if emptyg
                  myfing= 1: prod(inp.sz);
               else
                  myfind= 1: prod(g.sz);
               end
            end
         end

         % Compute the size of the resulting object
         if inddim==2 % old: ~ (inddim==1 && all(g.sz>1))
            g.sz= [max([myfind(:); g.sz(1)]), max([sind(:); g.sz(2)])];
         elseif g.sz(1)==1 || emptyg
            % If g is a row vector, a scalar or an empty object, but only
            % one index is present, then g grows rowwise, where 1 is the
            % smallest possible entry.
            g.sz= [max(1, g.sz(1)), max([1; myfind(:); g.sz(2)])];
            sind= myfind;
            myfind= 1;
         elseif g.sz(2)==1
            % A column vector may grow using single index, but a matrix
            % can not grow using a single index.
            g.sz= [max([myfind(:); g.sz(1)]), g.sz(2)];
         end

         % The length of the indexing vectors is needed often later on.
         lfind= prod(size(myfind));
         lsind= length(sind);

         % If the derivative object was not allocated, then do this now.
         if emptyg
            g.deriv=zeros(g.sz.*g.ndd);
         elseif any(oldgsz<g.sz)
            % The derivative object is growing...
            g.deriv=reshape(cat(1, cat(2, reshape(full(g.deriv), ...
                        [oldgsz g.ndd]), ...
                  zeros([oldgsz(1), g.sz(2)- oldgsz(2), g.ndd])), ...
                     zeros([g.sz(1)- oldgsz(1), g.sz(2), g.ndd])),...
                  g.sz.* g.ndd);
         end

         % Compute the base of each directional derivative.
         basefind= (0:prod(g.ndd)- 1).* prod(g.sz);
         % Replicate that base numel(index) times:
         basefind= basefind(ones(lfind* lsind,1), :);
         %  begin: repfind = repmat(find, g.ndd.* [1, lsind]);
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
         index_local= basefind(:)+ repfind(:)+ repsind(:);
         if deletemode
            % Delete data from the matrix (EXPERIMENTAL)
            g.deriv(index_local)= [];
            if lsind== g.sz(2)
               g.sz(1)= g.sz(1)- length(myfind);
            else
               g.sz(2)= g.sz(2)- length(sind);
            end
            g.deriv= reshape(g.deriv, g.ndd.* g.sz);
         else
            g.deriv(index_local)= inp.deriv(:);
         end
         g.deriv= cond_sparse(g.deriv);
      else
         error('Number of directional derivatives disagree (lhs(%dx%d)!=rhs(%dx%d)).', g.ndd(1), g.ndd(2), inp.ndd(1), inp.ndd(2));
      end
   else
      error('Dimensions of derivative objects mismatch lhs(%d)!=rhs(%d).', g.dims, inp.dims);
   end
case '.'
   if isa(varargin{1}, 'madderiv')
      if isa(g, 'madderiv')
         clear g;
         g= struct(index(1).subs, []);
      end
      if length(index)>1
         index_temp= index(1).subs;
         index(1)=[];
         g= subsasgn(g.(index_temp), index, varargin{:});
      else
         g.(index(1).subs)= varargin{1};
      end
   else
      error('Right-hand side object has to be a derivative object.');
   end
otherwise
   error('Internal error.');
end

% vim:sts=3:ts=3:sw=3:
