% function [r, asked] = admGetPref(name)
%
% This function retrieves user preference settings for the preference
% given by name.
%
% All preferences are in the preference group 'adimat'. To see all the
% currently set preferences use getpref('adimat'). To delete all the
% currently set preferences use rmpref('adimat'). On Octave you may
% have to delete the file .octave_prefs in your home directory.
%
% On Matlab the function uigetpref is used. 
%
% On Octave 3.6 or later the functions getpref, input and setpref are
% used together with input to read the user's answer.
%
% On Octave before 3.6 the user is asked every time. Users of Octave
% before 3.6 will probably want to modify this function to directly
% return their prefered answer.
%
% Currently the following preferences exist:
%
%  - pnormEven_p_useAbs
%  - missing_derivative_value
%  - confirmTransmission
%  - nonSquareSystemSolve
%
function [r, asked] = admGetPref(name)
  question = '???';
  title = 'Error: Unknown question';
  answers = {'yes', 'no'};
    
  switch name
   case 'pnormEven_p_useAbs'
    title = 'p-Norm computation for even p';
    question = 'norm(x, p) is evaluated for real x and even p. Do you want to apply abs() to x? If in doubt, say yes.';
    answers = {'yes', 'no'};
    
   case 'missing_derivative_value'
    title = 'missing derivative value';
    question = 'Some derivative is evaluated where none exists. What shall be used as the replacement value?';
    answers = {'0', 'NaN'};
    if admIsOctave()
      answers{end+1} = 'NA';
    end
   
   case 'confirmTransmission'
    question = 'Files will be sent to the ADiMat server. Do you agree?';
    title = 'Transmission Confirmation';
    answers = {'yes', 'no'};
   
   case 'nonSquareSystemSolve'
    question = ['The solving of a non-square linear system is differentiated. Do you want a faster|'...
                'or a more accurate solution? In the former case, the condition number of the system|'...
                'to solve for the derivatives will be the square of the original.'];
    title = 'Non-Square LS Solve';
    answers = {'fast', 'accurate'};
   
   otherwise
    error('adimat:admGetPref:invalidName', 'No such preference setting (%s) in ADiMat', name);
    
  end
  
  title = ['ADiMat: ' title];
  
  if exist('uigetpref')
    [r asked] = uigetpref('adimat', name, title, question, answers);
  
  else

    % Octave
    
    if admIsOctave(3.6)

      % Octave >= 3.6 has setpref etc.

      if ispref('adimat', name)
        r = getpref('adimat', name);
        asked = false;
        
      else
        
        asked = true;
        r = askQuestionOctave(title, question, answers);
        
        answer = input('Save answer for the future (yes or no): ', 's');
        if strcmpi(answer, 'yes')
          setpref('adimat', name, r);
        end
      
      end
        
    else
    
      asked = true;
      r = askQuestionOctave(title, question, answers);
     
    end
    
  end

end

function r = askQuestionOctave(title, question, answers)
  fprintf(1, '\n%s\n%s\n', title, question);
  anss = answers{1};
  for i=2:length(answers)-1
    anss = [anss, ', ', answers{i}];
  end
  if length(answers) > 2
    anss = [anss, ','];
  end
  anss = [anss, ' or ', answers{end}];
  while true
    answer = input(sprintf('Please answer %s: ', anss), 's');
    which = strcmp(lower(answers), lower(answer));
    if any(which)
      where = find(which);
      r = answers{where(1)};
      break;
    end
  end
end

% $Id: admGetPref.m 4142 2014-05-10 12:24:52Z willkomm $
