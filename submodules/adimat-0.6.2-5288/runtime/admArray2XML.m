function docStr = admArray2XML(val, docName, encoding, omitXMLDecl, indent)
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
    
  if isa(val, 'char')
    substr = val;
  elseif isa(val, 'function_handle')
    substr = func2str(val);
  else
    if numel(val) > 1
      substr = sprintf('<array>');
      substr = [substr sprintf('<dim>%d</dim>', size(val))];
      if issparse(val)
        [I J] = find(val);
        for i=1:length(I)
          substr = [substr sprintf('<e i="%d" j="%d">%g</e>', I(i), J(i), full(val(I(i), J(i))))];
        end
      else
        substr = [substr sprintf('<values>')];
        if isreal(val)
          valstr = sprintf('%.16g, ', val);
          valstr = valstr(1:end-2);
        else
          substr = [substr sprintf('<real>')];
          valstr = sprintf('%.16g, ', real(val));
          valstr = valstr(1:end-2);
          substr = [substr sprintf('</real>')];
          substr = [substr sprintf('<imag>')];
          valstr = sprintf('%.16g, ', imag(val));
          valstr = valstr(1:end-2);
          substr = [substr sprintf('</imag>')];
        end
        substr = [substr valstr sprintf('</values>')];
      end
      substr = [substr sprintf('</array>')];
    else
      if isreal(val)
        substr = sprintf('%.16g', val);
      else
        substr = sprintf('%.16g +%.16gi', real(val), imag(val));
      end
    end
  end
  docStr = [docStr sprintf('%s<%s>%s</%s>\n', [indent ' '], docName, substr, docName)];
  
 % $Id: admArray2XML.m 4807 2014-10-08 16:06:50Z willkomm $
 