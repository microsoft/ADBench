function docStr = admStruct2XML(s, docName, encoding, omitXMLDecl, indent)
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
    
  docStr = [docStr sprintf('%s<%s>\n', indent, docName)];

  fns = fieldnames(s);
  
  for i=1:length(fns)
    fn = fns{i};
    val = s.(fn);
    if isstruct(val)
      substr = admStruct2XML(val, fn, encoding, true(), [indent ' ']);
      docStr = [docStr substr];
    elseif iscell(val)
      substr = admCell2XML(val, fn, encoding, true(), [indent ' ']);
      docStr = [docStr substr];
    else
     substr = admArray2XML(val, fn, encoding, true(), indent);
     docStr = [docStr substr];
    end
  end
  
  docStr = [docStr sprintf('%s</%s>\n', indent, docName)];

 % $Id: admStruct2XML.m 3218 2012-03-13 22:04:08Z willkomm $
 