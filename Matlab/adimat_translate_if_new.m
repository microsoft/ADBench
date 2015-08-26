function adimat_translate_if_new(func,independents)

is_reverse_mode = true; % fwd not implemented here

addpath('adimat-0.6.0-4971');
start_adimat
addpath('awful\matlab');

func_name = [func2str(func) '.m'];
if is_reverse_mode
    d_name = ['a_' func_name];
else
    d_name = ['d_' func_name];
end

a = dir(func_name);
func_age = datetime(a.date);
b = dir(d_name);
d_age = datetime(b.date);
if d_age < func_age
    if is_reverse_mode
        admTransform(func, admOptions('m', 'r','independents',independents));
    else
%         admTransform(@gmm_objective_vector_repmat, admOptions('m', 'r','independents', [1 2 3]));
    end
end