function write_script(script_fn,params,tasks_fns,tools,nruns_f,nruns_J)

ntasks = numel(tasks_fns);

targets = {};
for i=1:numel(tools)
    if sum(nruns_f(:,i) + nruns_J(:,i)) > 0 && tools(i).call_type < 3 % executables
        targets(end+1).name = tools(i).ext;
        targets(end).targets = {};
        
        if tools(i).call_type == 1 % theano
            cmd = tools(i).run_cmd;
            for j=1:ntasks
                if nruns_f(j,i)+nruns_J(j,i) > 0
                    cmd = [cmd ' ' sprintf('%s %i %i',...
                        tasks_fns{j},nruns_f(j,i),nruns_J(j,i))];
                end
            end
            targets(end).targets(end+1).name = [targets(end).name '_all'];
            targets(end).targets(end).cmd = cmd;
        
        else
            for j=1:ntasks
                if nruns_f(j,i)+nruns_J(j,i) > 0
                    
                    d = params{j}(1);
                    k = params{j}(2);
                    curr_dk = sprintf('d%ik%i',d,k);
                    
                    if tools(i).call_type == 0 % standard run
                        cmd = sprintf('%s %s %i %i',...
                            tools(i).run_cmd,tasks_fns{j},...
                            nruns_f(j,i),nruns_J(j,i));
                        
                    elseif tools(i).call_type == 2 % ceres
                        cmd = sprintf('%s%s.exe %s %i %i',...
                            tools(i).run_cmd,curr_dk,tasks_fns{j},...
                            nruns_f(j,i),nruns_J(j,i));
                    end
                    
                    targets(end).targets(end+1).name = ...
                        [targets(end).name '_' curr_dk];
                    targets(end).targets(end).cmd = cmd;
                end
            end
        end            
    end
end

fid = fopen(script_fn,'w');

fprintf(fid,'all:');
for i=1:numel(targets)
    fprintf(fid,' %s',targets(i).name);
end
fprintf(fid,'\r\n\r\n');

for i=1:numel(targets)
    fprintf(fid,'%s:',targets(i).name);
    for j=1:numel(targets(i).targets)
        fprintf(fid,' %s',targets(i).targets(j).name);
    end
    fprintf(fid,'\r\n\r\n');
end
fprintf(fid,'\r\n');

for i=1:numel(targets)
    for j=1:numel(targets(i).targets)
        fprintf(fid,'%s:\r\n\t%s',targets(i).targets(j).name,...
            targets(i).targets(j).cmd);
        fprintf(fid,'\r\n');
    end
end

fclose(fid);

% % batch
% ntasks = numel(tasks_fns);
% 
% fid = fopen(script_fn,'w');
% for i=1:numel(tools)
%     if tools(i).call_type < 3 % executables
%         if tools(i).call_type == 1 && sum(nruns_f(:,i) + nruns_J(:,i)) > 0 % theano
%             cmd = ['START /MIN /WAIT ' tools(i).run_cmd];
%             for j=1:ntasks
%                 if nruns_f(j,i)+nruns_J(j,i) > 0
%                     cmd = [cmd ' ' tasks_fns{j} ' '...
%                         num2str(nruns_f(j,i)) ' ' num2str(nruns_J(j,i))];
%                 end
%             end
%             fprintf(fid,[cmd '\r\n']);
%         else
%             for j=1:ntasks
%                 if nruns_f(j,i)+nruns_J(j,i) > 0
%                     if tools(i).call_type == 0 % standard run
%                         fprintf(fid,'START /MIN /WAIT %s %s %i %i\r\n',...
%                             tools(i).run_cmd,tasks_fns{j},...
%                             nruns_f(j,i),nruns_J(j,i));
%                     elseif tools(i).call_type == 2 % ceres
%                         d = params{j}(1);
%                         k = params{j}(2);
%                         fprintf(fid,'START /MIN /WAIT %sd%ik%i.exe %s %i %i\r\n',...
%                             tools(i).run_cmd,d,k,tasks_fns{j},...
%                             nruns_f(j,i),nruns_J(j,i));
%                     end
%                 end
%             end
%         end            
%     end
% end
% fclose(fid);

end