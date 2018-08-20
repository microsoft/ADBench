% function [r, newerList] = admCheckDeps(functionName)
%
% Check whether differentiated function file given by functionName
% needs to be regenerated. This is the case when one of its
% dependencies has changed. The dependencies are the original function
% and functions called by it (transitively).
%
% Return false() when functionName must be regenerated. This
% happens when:
%   
%   - the function functionName does not exist
%   - the path returned by which(functionName) does not exist
%   - the dependency list file does not exist
%   - one of the files listed in the dependency list is newer than
%   the file which(functionName)
%
function [r, newerList] = admCheckDeps(origFunctionName, functionName)
  if admLogLevel > 2
    fprintf(admLogFile('progress'), 'Checking dependencies of function %s\n', ...
            functionName);
  end
  r = false;
  newerList = { };
  
  if ~exist(functionName)
    fprintf(admLogFile, 'Function does not exist: %s\n', functionName);
    return
  end

  origFunctionFile = which(origFunctionName);
  functionFile = which(functionName);
  refDate = dir(functionFile);
  if isempty(refDate)
    fprintf(admLogFile, 'Function file does not exist: %s\n', functionFile);
    return
  end
  
  depList = admDepList(origFunctionFile);
%  fprintf(admLogFile, 'Dependency list is: %s\n', depList);
  
  if ~exist(depList)
    fprintf(admLogFile, 'Dependency list %s does not exist\n', depList);
    newerList = { functionFile };
    r = false;
    return
  end

%  s = dir(depList);
%  depListDate = s.datenum;
%  if depListDate < refDate.datenum
%    fprintf(admLogFile, 'The dependency list %s is older than given date\n', depList);
%    r = false;
%    return
%  end
  
  fid = fopen(depList);
  
  clist = admReadFileLines(fid);

  fclose(fid);

  r = length(clist) > 0;

  for i=1:length(clist)
    fName = clist{i};
    fFile = which(fName);
    s = dir(fFile);
    if admLogLevel > 2
      if i > 1
        fprintf(admLogFile('progress'), ', ');
      end
      fprintf(admLogFile('progress'), '%s', fName);
    end
    if s.datenum > refDate.datenum
      r = false;
      newerList = { newerList{:} s };
      if admLogLevel > 2
        fprintf(admLogFile('progress'), '*');
      end
    end
  end
  if admLogLevel > 2
    fprintf(admLogFile('progress'), '\n');
  end

  for i=1:length(newerList)
    s = newerList{i};
    fprintf(admLogFile, 'File %s is newer than %s: %s > %s\n', ... 
            s.name, refDate.name, s.date, refDate.date);
  end
  
% $Id: admCheckDeps.m 3021 2011-08-26 14:14:09Z willkomm $
