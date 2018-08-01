function au_test_end(tag)
% AU_TEST_END   Report test stats

global all_test_status

fprintf(1, 'au_test_end: %d test(s) passed\n', all_test_status.ok);
if all_test_status.failed > 0
    error('au_test_end:failed', '%d test(s) failed\n', all_test_status.failed);
end
