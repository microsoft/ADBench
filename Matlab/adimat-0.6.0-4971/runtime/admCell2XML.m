function docStr = admCell2XML(s, docName, encoding, omitXMLDecl, indent)
  if nargin < 2
    docName = 'a';
  end
  if nargin < 3
    encoding = 'utf-8';
  end
  if nargin < 4
    omitXMLDecl = true;
  end
  if nargin < 5
    indent = '';
  end
  
  docStr = '';
  if ~omitXMLDecl
    docStr = sprintf('<?xml version="1.0" encoding="%s"?>\n', encoding);
  end
    
  sz = size(s);
  
  docStr = [docStr sprintf('%s<%s type="cell">\n', indent, docName)];

  if ~isempty(s)
    docStr = [docStr sprintf('%s <size>\n', indent)];
    for i=1:length(sz)
      docStr = [docStr sprintf('%s  <dim>%d</dim>\n', indent, sz(i))];
    end
    docStr = [docStr sprintf('%s </size>\n', indent)];
  end
  
  fn = 'cell';
  
  for i=1:prod(sz)
    val = s{i};
    if isstruct(val)
      substr = admStruct2XML(val, fn, encoding, true(), [indent ' ']);
      docStr = [docStr substr];
    elseif iscell(val)
      substr = admCell2XML(val, fn, encoding, true(), indent);
      docStr = [docStr substr];
    else
      substr = admArray2XML(val, fn, encoding, true(), indent);
      docStr = [docStr substr];
    end
  end
  
  docStr = [docStr sprintf('%s</%s>\n', indent, docName)];

 % $Id: admCell2XML.m 3294 2012-05-30 11:30:18Z willkomm $
 