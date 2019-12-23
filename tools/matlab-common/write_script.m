% Copyright (c) Microsoft Corporation.
% Licensed under the MIT license.

function write_script(script_fn,params,dir_in,dir_out,...
    fns,tools,nruns_f,nruns_J,replicate_point)

if ~exist('replicate_point','var')
    replicate_point = false;
end

isgmm = (numel(params{1}) == 3);
isba = (numel(params{1}) == 6);
ishand = (numel(params{1}) == 1);

ntasks = numel(fns);

targets = {};
for i=1:numel(tools)
    if sum(nruns_f(:,i) + nruns_J(:,i)) > 0 && tools(i).call_type < 3 % executables
        targets(end+1).name = tools(i).ext;
        targets(end).targets = {};
        
        if tools(i).call_type == 1 % theano
            cmd = tools(i).run_cmd;
            for j=1:ntasks
                if nruns_f(j,i)+nruns_J(j,i) > 0
                    cmd = [cmd ' ' sprintf('%s %s %s %i %i',...
                        dir_in,...
                        dir_out,...
                        fns{j},...
                        nruns_f(j,i),...
                        nruns_J(j,i))];
                end
            end
            targets(end).targets(end+1).name = [targets(end).name '_all'];
            targets(end).targets(end).cmd = cmd;
        
        else
            for j=1:ntasks
                if nruns_f(j,i)+nruns_J(j,i) > 0
                    
                    if isgmm
                        params_str = sprintf('d%ik%i',...
                            params{j}(1),params{j}(2));
                    elseif isba || ishand
                        params_str = sprintf('%i',j);
                    end
                    args = sprintf('%s %s %s %i %i',...
                        dir_in,...
                        dir_out,...
                        fns{j},...
                        nruns_f(j,i),...
                        nruns_J(j,i));
                    
                    if tools(i).call_type == 0 % standard run
                        cmd = sprintf('%s %s',...
                            tools(i).run_cmd,args);
                        
                    elseif tools(i).call_type == 2 % ceres
                        cmd = sprintf('%s%s.exe %s',...
                            tools(i).run_cmd,params_str,args);
                    end
                    
                    targets(end).targets(end+1).name = ...
                        [targets(end).name '_' params_str];
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
        if replicate_point
            cmd = [targets(i).targets(j).cmd ' -rep'];
        else
            cmd = targets(i).targets(j).cmd;
        end
        fprintf(fid,'%s:\r\n\t%s',targets(i).targets(j).name,cmd);
        fprintf(fid,'\r\n');
    end
end

fclose(fid);

% % .bat file
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