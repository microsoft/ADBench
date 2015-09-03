function adimat_translate_if_new(func,independents,do_forward_mode)

addpath('adimat-0.6.0-4971');
start_adimat
addpath('awful\matlab');

func_name = [func2str(func) '.m'];
if do_forward_mode
    d_name = ['d_' func_name];
else
    d_name = ['a_' func_name];
end

a = dir(func_name);
func_age = datetime(a.date);
b = dir(d_name);
d_age = datetime(b.date);
if isempty(b) || d_age < func_age
    if do_forward_mode
        admTransform(func, admOptions('m', 'f','independents',independents));
    else
        admTransform(func, admOptions('m', 'r','independents',independents));
    end
end