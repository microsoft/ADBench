function au_yamlwrite(obj, fn)

if nargin == 0
  %% Test
  s1.a = 1;
  s1.b = 'now is \n''s winter';
  
  s2.s1(1) = s1;
  s2.s1(2).a=4;
  s2.s1(2).b='fred';
  s2.names = {'una', 'conor'};
  s2.mat = rand(2,3);
  s2.zzz = rand(0,0,3);
  s2.vec = [0,0,3];
  s2.cvec = [0,0,3]';
  
  s2
  disp('** JUST S2 ***')
  au_yamlwrite(s2);

  disp('** CELLS ***')
  au_yamlwrite({...
    s1, s2.s1(2), 3;
    1, 2, 3});

  return
end

if nargin < 2
  fid = 1;
elseif isnumeric(fn)
  fid = fn;
else
  fid = fopen(fn, 'wt');
end

fprintf(fid, '%% YAML 1.2\n');
send(obj, '', '');

if fid > 2
  fclose(fid);
end

  function send(obj, header, prefix)
    if isstruct(obj)
      fields = fieldnames(obj);
      if length(obj) <= 1
        lead = header;
        for k=1:length(fields)
          field = fields{k};
          send(obj.(field), [lead field ': '], [prefix '  ']);
          lead = prefix;
        end
      else
        fprintf(fid, '%s\n', header);
        for i=1:length(obj)
          send(obj(i), [prefix '- '], [prefix '  ']);
        end
      end
    elseif ischar(obj)
      fprintf(fid, '%s "%s"\n', header, obj);
    elseif iscell(obj);
      fprintf(fid, '%s !cell\n', header);
      fprintf(fid, '%s  sz: [%s ]\n', prefix, sprintf(' %d', size(obj)));
      fprintf(fid, '%s  elements:\n', prefix);
      for k=1:numel(obj)
        send(obj{k}, [prefix '  - '], [prefix '    ']);
      end
    elseif isnumeric(obj)
      sz = size(obj);
      if isequal(sz, [1 1])
        s = sprintf('%g', obj);
      elseif isequal(sz, [0 0])
        s = '[]';
      elseif sz(1) == 1 && numel(sz) == 2
        s = sprintf(', %g', obj(2:end));
        s = sprintf('[%g%s]', obj(1), s);
      elseif sz(2) == 1 && numel(sz) == 2
        s = sprintf(', %g', obj(2:end));
        s = sprintf('!cvec [%g%s]', obj(1), s);
      else
        ssz = sprintf(' %d', sz);
        s = sprintf(' %g', obj);
        s = sprintf('!mat { sz: [%s ],  data: [%s ] }', ssz, s);
      end
      fprintf(fid, '%s%s\n', header, s);
    end
  end
end
