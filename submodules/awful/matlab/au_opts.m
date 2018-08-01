function opts = au_opts(varargin)
% AU_OPTS  Easy option parsing
%          opts = AU_OPTS('FlagA=0', 'FlagB=3;Algo=foo', varargin{:})
%          is all you need to remember.   The defaults are listed first,
%          the varargs override them if necessary.   An existing opts
%          struct can be one of the args, and its fields are also added
%          with overwrite.
%          Any value beginning with a digit (or 'inf') is passed to str2double, 
%          any other is left as a string.  
%          To add more complex datatypes, use a struct.

if nargin == 0
    f=[1.2 2.3];
    a0.FlagA = 0;
    a0.FlagB = 3.1;
    a0.Algo = 'foo';
    a0.f = f;
    a0.g = 1;
    a1 = au_opts('FlagA=0;FlagB=3.1', 'Algo=foo;', struct('f', f, 'g', 1));
    au_test_equal a0 a1
    test.f= f;
    set_g.g = 1;
    a1 = au_opts('FlagA=0','FlagB=3.1', 'Algo=foo', test, set_g);
    au_test_equal a0 a1
    return
end

for k=1:length(varargin)
    opt = varargin{k};
    if ischar(opt)
        while true
            [n,e] = regexp(opt, '^(?<field>\w+)=(?<val>[^;]*)', 'names', 'end');
            opt = opt(e+2:end);
            if isempty(n)
                break
            end
            val= n(1).val;
            field = n(1).field;
            if ~isempty(regexp(val, '^[0-9]', 'once')) ||...
                    strcmpi(val, 'Inf')
                opts.(field) = str2double(val);
            else
                opts.(field) = val;
            end
        end
        if ~isempty(opt)
            error('Bad opts fragment [%s]', opt);
        end
    elseif isstruct(opt)
        for f=fieldnames(opt)'
            opts.(f{1}) = opt.(f{1});
        end
    end
    
end
