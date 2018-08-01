function au_prmat(varargin)

% AU_PRMAT   Compact print of matrices.
%               PR(A,B,C,...);
%               Displays matrices in a compact 7-chars-per-column
%               format.   The format uses 'm' notation to save a char
%               for small numbers, so that -2.345e-12 gets more sigfigs:
%                   |-2.3e-12 -- won't fit (8 chars)
%                   | -2e-12| -- doesn't use all 7 chars
%                   |-23e-13| -- 7 chars, extra sigfig
%                   |-234m14| -- 7 chars, 2 extra sigfigs
%               Even in 5 chars, get extra sigfigs
%                   |  -23m7| -- 4 chars
%               Exact zeros are marked with 'o'
%               Printing concats horizontally (it's easy
%               to concat vertically just by repeat calling)

%               PR(A,B,C,..., ['colwidth', COLWIDTH]);
%               colwidth!=7 not well tested...

% Author: Andrew Fitzgibbon <awf@robots.ox.ac.uk>
% Date: 18 Nov 97

if nargin == 0
  au_prmat_test
  return
end

colwidth = 7;
mats = {};
k = 1;
while k <= nargin
    if ischar(varargin{k}) && strcmp(varargin{k}, 'colwidth')
        colwidth = varargin{k+1};
        k=k+1;
    else
        M = varargin{k};
        if isstruct(M)
            prstruct(M);
        else
            mats{end+1} = M;
        end
    end
    k = k + 1;
end
n = length(mats);
fmt = sprintf('%%%d', colwidth);

%columns = get(0, 'commandwindowsize');
%columns = columns(1);

if n==0
  return
end

sz(n,2)=0;
vmax = 0;
%vmin = inf;
for k=1:n
    M = mats{k};
    szk = size(M);
    if numel(szk) > 2
        error('Don''t handle multidimensional arrays')
    end
    
    sz(k,:) = szk;
    finitevals = abs(M(isfinite(M)));
    vmax = max(max(finitevals(:)), vmax);
end

% tol = vmax * 1e-12;
% elseif (abs(v - round(v)) < tol) && ... % integer
%                         abs(v) > .1 && abs(v) < 1e6  % < 1e6
%                    fprintf(1, [fmt 'd'], round(v));
                
for i = 1:max(sz(:,1))
    for k=1:n
        M = mats{k};
        [r,c] = size(M);
        if i > r
            fprintf(1, repmat(' ', 1, (1+colwidth)*c-1));
        else
            for j=1:c
                v = M(i,j);
                if v == 0
                    fprintf(1, [fmt 's'], 'o');
                elseif ~isfinite(v)
                    fprintf(1, [fmt '.1f'], v);
                elseif abs(v) >= 1e10
                    expo = floor(log10(abs(v)));
                    digs = num2str(expo<100);
                    s = sprintf(['%.' digs 'fe%d'],(v*10^-expo),expo);
                    fprintf(1, [fmt 's'], s);
                elseif abs(v) >= 1e4
                    iexpo = floor(log10(abs(v)));
                    expo = floor(iexpo/3)*3;
                    digs = num2str(iexpo-expo<2);
                    s = sprintf(['%.' digs 'fe%d'],v*10^-expo,expo);
                    fprintf(1, [fmt 's'], s);
                elseif abs(v) >= 1000
                    fprintf(1, [fmt '.1f'], v);
                elseif abs(v) >= 100
                    fprintf(1, [fmt '.2f'], v);
                elseif abs(v) > 10
                    fprintf(1, [fmt '.3f'], v);
                elseif abs(v) > 1e-2
                    fprintf(1, [fmt '.4f'], v);
                else
                    expo = floor(log10(abs(v)));
                    mant = v*10^-expo;
                    if expo>-10
                        digs='2';
                    elseif expo>=-97
                        mant = mant*100;
                        expo = expo-2;
                        digs = '0';
                    else
                        digs='0';
                    end
                    s = sprintf(['%.' digs 'fm%d'], mant,-expo);
                    
                    fprintf(1, [fmt 's'], s);
                end
                
                if j < c
                    fprintf(1, ' ');
                end
            end
        end
        if k < length(mats)
            fprintf(1, ' |');
        else
            fprintf(1, '\n');
        end
    end
end
