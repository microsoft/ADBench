function au_mfilename_test

au_test_regexp(au_mfilename, 'au_mfilename_test')
au_test_regexp(au_mfilename(-1), 'base workspace')
