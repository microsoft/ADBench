function cols_map = generate_colors()
    
cols_map = containers.Map;
cols_map('manual') = [230 159 0]/255; % orange 
cols_map('tapenade') = [0 .8 .8]; % cyan
cols_map('adolc') = [0 114 178]/255; % blue
cols_map('adept') = [0 0 0]; % black
cols_map('theano') = [220 208 66]/255; % dark yellow
cols_map('ceres') = [204 121 167]/255; % pink
cols_map('diffsharp') = [213 94 0]/255; % red-ish (vermilion)
cols_map('autograd') = [86 180 233]/255; % sky blue 
cols_map('adimat') = [0 158 115]/255; % bluish green
cols_map('mupad') = [.8 0 .8]; % magenta
cols_map('julia_f') = [0.6 0.5 0.1]; % brown

cols_map('finite_differences') = [0.5 0.5 0.5]; 

end