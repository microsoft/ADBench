function au_test_begin(tag)
% AU_TEST_BEGIN   Start a sequence of tests, and reset test stats

global all_test_status

if nargin == 0
  tag = au_mfilename(-1);
end

fprintf(1, 'au_test_begin: start sequence [%s]\n', tag);

status.ok = 0;
status.failed = 0;

all_test_status = status;
