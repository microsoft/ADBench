function inputsC = inputMatrix2CellOfArguments(inputs, funcArgs, independents)
  ndd = size(inputs, 2);
  
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
    inputsC{k} = mat2cell(inputs, narg, ones(ndd, 1)) .';
    szk = size(funcArgs{k});
    for j=1:ndd
      inputsC{k}{j} = reshape(inputsC{k}{j}, szk);
    end
  else
    offs = 1;
    for k=independents
      narg = numel(funcArgs{k});
      inBlock = inputs(offs:offs+narg-1, :);
      inputsC{k} = mat2cell(inBlock, narg, ones(ndd, 1)) .';
      szk = size(funcArgs{k});
      for j=1:ndd
        inputsC{k}{j} = reshape(inputsC{k}{j}, szk);
      end
      offs = offs + narg;
    end
  end
end
% $Id: inputMatrix2CellOfArguments.m 4584 2014-06-21 09:09:53Z willkomm $
