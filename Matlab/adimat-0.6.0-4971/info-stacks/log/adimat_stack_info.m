% function r = adimat_stack_info(label, func, a, b, c)
%
% Utility function being called by statements inserted into adjoint
% code when parameter printStackInfo is set. Feel free to replace or
% modify this function. You can also change the name of the function
% being called using parameter stackInfoFunction.
%
function r = adimat_stack_info(label, func, a, b, c);
  global adjoint_tic
  persistent lastStackSize lastTime
  persistent writeAmount readAmount
  persistent writeTime readTime
  if isempty(adjoint_tic), adjoint_tic = 0; end
  white = '                                                          ';
  toffs = toc(adjoint_tic);

  if isempty(lastStackSize)
    readAmount = 0;
    writeAmount = b;
    readTime = 0;
    writeTime = toffs;
    fprintf(admLogFile('stackInfo'), ['%.*sitems\t\tsize (MB)\ton disc ' ...
                        '(MB)\tspeed (MB/s)\twr (MB)\tavg wr ' ...
                        '(MB/s)\trd (MB)\trd sp (MB/s)\n'], 57, white);
  else
    type = '';
    t = tic;
    dt = toc(lastTime);
    if lastStackSize > b
      type = 'read';
      readAmount = readAmount + abs(lastStackSize - b);
      readTime = readTime + dt;
    else
      type = 'write';
      writeAmount = writeAmount + abs(lastStackSize - b);
      writeTime = writeTime + dt;
    end
  end
  msg = '';
  switch label
   case {'toppadihill', 'begin', 'end'};
    if ~isempty(lastStackSize)
      msg = sprintf('\t\t%.4g \t\t%.4g \t\t%.4g \t\t%.4g \t\t%.4g', ...
                    abs(b - lastStackSize) ./ 2.^20 ./ (dt), ...
                    (writeAmount ./ 2.^20), (writeAmount ./ 2.^20) ./ writeTime,...
                    (readAmount ./ 2.^20), (readAmount ./ 2.^20) ./ readTime);
    end
  end

  fprintf(admLogFile('stackInfo'), '% 5s %.15s: %.*s\tat %.4g s\t\t%d \t\t%6.4g \t\t%6.4g %s\n', ...
          label, func, max(25 - length(func) - length(label),0), white, toffs, a, b ./ 2^20, c ./ 2^20, msg);

  lastTime = tic;
  lastStackSize = b;
end

% $Id: adimat_stack_info_log.m 4250 2014-05-18 20:21:18Z willkomm $
