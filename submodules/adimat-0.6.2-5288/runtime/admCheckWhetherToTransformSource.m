function [doTransform] = admCheckWhetherToTransformSource(admOpts, functionName, resultFunctionName)
  doTransform = false();
  
  if admOpts.forceTransform ~= -1
    if admOpts.forceTransform == 1
      fprintf(admLogFile, 'Transformation is forced.\n');
      doTransform = true();
    elseif ~exist(resultFunctionName)
      fprintf(admLogFile, 'Differentiated function %s does not exist.\n', resultFunctionName);
      doTransform = true();
    else
      lastOpts = admLastOptions(functionName, resultFunctionName);
      if ~isempty(lastOpts)
        lastOpts = admRemoveNonTransformOptions(lastOpts);
      end
      admOptsStripped = admRemoveNonTransformOptions(admOpts);
      if ~isequal(lastOpts, admOptsStripped) || isempty(fieldnames(lastOpts))
        if isfield(lastOpts, 'admopts')
          fprintf(admLogFile, 'The options struct has changed.\n');
          if admLogLevel > 1
            diffStr = admStructDiff(lastOpts, admOptsStripped);
            fprintf(admLogFile, '%s', admStruct2XML(diffStr, 'admOptions'));
          end
        else
          fprintf(admLogFile, 'The last options struct is empty.\n');
        end
        doTransform = true();
      elseif admOpts.checkDependencies == 1
        depTime = tic;
        r = admCheckDeps(functionName, resultFunctionName);
        depTime = toc(depTime);
        if ~r
          doTransform = true();
        end
      end
    end
  else
%    fprintf(admLogFile(), 'Transformation is inhibited.\n');
  end

% $Id: admCheckWhetherToTransformSource.m 4581 2014-06-20 21:09:38Z willkomm $
