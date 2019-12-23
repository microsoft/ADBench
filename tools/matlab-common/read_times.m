% Copyright (c) Microsoft Corporation.
% Licensed under the MIT license.

function [times_f,times_J,up_to_date_mask] = ...
    read_times(data_dir,data_dir_est,fns,tools,problem_name)

ntasks = numel(fns);
ntools = numel(tools);

times_f = Inf(ntasks,ntools);
times_J = Inf(ntasks,ntools);
up_to_date_mask = false(ntasks,ntools);
for i=1:ntools
    postfix = ['_times_' tools(i).ext];
    if tools(i).call_type < 3
        postfix = [postfix '.txt'];
        for j=1:ntasks
            fn = [data_dir fns{j} postfix];
            if nargout >= 3
                up_to_date_mask(j,i) = is_up_to_date(fn,tools(i).exe);
            end
            if ~exist(fn,'file')
                fn = [data_dir_est fns{j} postfix];
            end
            if exist(fn,'file')
                fid = fopen(fn);
                times_f(j,i) = fscanf(fid,'%lf',1);
                times_J(j,i) = fscanf(fid,'%lf',1);
                fclose(fid);
            end
        end
    elseif tools(i).call_type >= 3
        postfix = [problem_name postfix '.mat'];
        fn = [data_dir postfix];
        if nargout >= 3
            up_to_date_mask(:,i) = is_up_to_date(fn,tools(i).exe);
        end
        if ~exist(fn,'file')
            fn = [data_dir_est postfix];
        end
        if exist(fn,'file')
            ld=load(fn);
            times_f(:,i) = ld.times_f;
            times_J(:,i) = ld.times_J;
        end
    end
end

end