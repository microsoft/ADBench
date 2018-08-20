function r = admLastOptions(functionName, resultFunctionName, newOptions)
  functionFile = which(functionName);
  [dir, file, stem] = fileparts(functionFile);
  statusDirName = admStatusDir(functionFile);
  fname = [statusDirName '/' resultFunctionName '_admopts.mat'];
  fieldName = 'admopts';
  adiver = adimat_version(4);
  if nargin < 3
    r = struct();
    if exist(fname, 'file')
      if admLogLevel > 2
        fprintf(admLogFile(), 'Retrieving options from field %s in file\n %s.\n', ...
                fieldName, admShowFilename(fname));
      end
      try
        s = load('-mat', fname);
      catch
        fprintf(admLogFile(), 'Failed to load saved options file %s (file is corrupt).\n', admShowFilename(fname));
        return
      end
      if isfield(s, fieldName)
        if isfield(s, 'revision')
          if strcmp(s.revision, adiver)
            r = s.(fieldName);
          else
            fprintf(admLogFile(), 'The options were saved by ADiMat %s\n in saved options file %s,\n but this is ADiMat %s.\n', ...
                    s.revision, admShowFilename(fname), adiver);
            % warning('adimat:admLastOptions:savedValueFromDifferentRevision', ...
            %         'The options were saved by ADiMat %s in saved options file %s, but this is ADiMat %s', ...
            %         s.revision, fname, adiver);
          end
        else
          error('adimat:admLastOptions:noRevisionSaved', ...
                'The ADiMat revision number could not be found in saved options file %s.', admShowFilename(fname));
        end
      else
        error('adimat:admLastOptions:savedValueNotFound', ...
              'The variable %s was not found in saved options  file %s', ...
              fieldName, admShowFilename(fname));
      end
    else
%      fprintf(admLogFile(), 'No saved options file %s was found.\n', ...
%              s.revision, fname, adiver);
    end
  else
    if admIsOctave
      % Octave cannot save function handles to .mat files
      if isa(newOptions.admDiffFunction, 'function_handle')
        newOptions.admDiffFunction = func2str(newOptions.admDiffFunction);
      end
      if isa(newOptions.coloringFunction, 'function_handle')
        newOptions.coloringFunction = func2str(newOptions.coloringFunction);
      end
    end
    saveStr = struct(fieldName, newOptions, 'revision', adiver);
    if admLogLevel > 2
      fprintf(admLogFile(), 'Saving options to field %s in file\n %s.\n', ...
              fieldName, admShowFilename(fname));
    end
    save('-mat', fname, '-struct', 'saveStr');
  end

% $Id: admLastOptions.2.m 4523 2014-06-13 20:45:28Z willkomm $
