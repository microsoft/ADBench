function refresh_files(data_dir,tool,fns)

ntasks = numel(fns);

postfix = ['_times_' tool.ext];
if tool.call_type < 3
    postfix = [postfix '.txt'];
    for j=1:ntasks
        fn = [data_dir fns{j} postfix];
        if exist(fn,'file')
            text=fileread(fn);
            fid = fopen(fn,'w');
            fprintf(fid,text);
            fclose(fid);
        end
    end
elseif tool.call_type >= 3
    postfix = ['gmm' postfix '.mat'];
    fn = [data_dir postfix];
    if exist(fn,'file')
        ld=load(fn);
        save(fn,'-struct','ld');
    end
end

end