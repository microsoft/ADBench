function inputsC = inputMatrix2CellOfArguments(inputBlocks, funcArgs, independents)
  ndd = size(inputBlocks{1}, 2);
  
  inputsC = cell(length(funcArgs), 1);
  
  % handle non-indeps
  for k=1:length(funcArgs)
    if ~any(find(independents == k))
      inputsC{k} = repmat(funcArgs(k), [ndd 1]);
    end
  end

  % handle indeps
  if length(independents) == 1
    k=independents;
    narg = numel(funcArgs{k});
    inputsC{k} = mat2cell(inputBlocks{1}, narg, ones(ndd, 1)) .';
    szk = size(funcArgs{k});
    for j=1:ndd
      inputsC{k}{j} = reshape(inputsC{k}{j}, szk);
    end
  else
    offs = 1;
    for k=1:length(independents)
      narg = numel(funcArgs{independents(k)});
      inputsC{independents(k)} = mat2cell(inputBlocks{k}, narg, ones(ndd, 1)) .';
      szk = size(funcArgs{independents(k)});
      for j=1:ndd
        inputsC{independents(k)}{j} = reshape(inputsC{independents(k)}{j}, szk);
      end
      offs = offs + narg;
    end
  end
end
% $Id: inputMatrix2CellOfArguments.m 5100 2016-05-19 09:04:31Z willkomm $
