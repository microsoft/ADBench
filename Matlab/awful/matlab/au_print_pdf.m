function au_print_pdf(varargin)
% AU_PRINT_PDF  Prettier print to PDF via EPS 
%               AU_PRINT_PDF('filename')

if nargin == 0
    %% Test
    clf
    plot(1:10, rand(1,10))
    au_print_pdf -noshow c:\tmp\au_print_pdf_test
    au_print_pdf c:\tmp\au_print_pdf_test1.pdf
    return
end

match = @(s, re) any(regexp(s, re, 'once'));

show = 1;

if nargin == 1
    fn = varargin{1};
elseif nargin == 2
    arg = varargin{1};
    if match(arg, '^-noshow$')
        show = 0;
    end
    fn = varargin{2};
else
    error('awful:badargs', 'Bad arg list')
end

if match(fn, '[^a-zA-Z0-9_./\]')
    error('awful:au_print_pdf', 'Not tested with unusual filenames')
end
if match(fn, '\.pdf$')
    fn = regexprep(fn, '.pdf$', '')
end

epsfile = [fn '.eps'];
print('-depsc2', epsfile);
if ~exist(epsfile, 'file')
   error('awful:noeps', 'EPS file not produced')
end 
unix(['epstopdf ' epsfile])
pdffile = [fn '.pdf'];
if ~exist(epsfile, 'file')
   error('awful:nopdf', 'PDF file not produced by epstopdf')
end 
if show
    unix(['start ' pdffile]);
end
