function au_test_result(ok)
% AU_TEST_RESULT   Report a test result, and update stats
%            AU_TEST_RESULT(OK) 
%           Not normally called by users: use au_test_equal etc instead. 

% awf, Sep14

global all_test_status

if isempty(all_test_status)
  au_test_begin('default')
end

if ok
  all_test_status.ok = all_test_status.ok + 1;
else
  all_test_status.failed = all_test_status.failed + 1;
end
