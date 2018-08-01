
%% Test au_mex.h

disp('mexing');
mex('au_mex_example_1.cxx');
mex('au_mex_example_2.cxx');

disp('testing');
A = rand(2,3);
B = rand(2,3);
O = au_mex_example_1(A, B);

au_test_equal O (A+B)

disp('testing example2<double>');
A = rand(2,3);
B = rand(2,3);
O = au_mex_example_2(A, B);

au_test_equal O (A+B)

disp('testing example2<uint8>');
A = randi(2,3, 'uint8');
B = randi(2,3, 'uint8');
O = au_mex_example_2(A, B);

au_test_equal O (A+B)

disp('testing example2<uint16> -- should fail');
au_test_should_fail('au_mex_example_2(uint16(8), uint16(9))');

%% Check for leaks
disp('Check for leaks...');
mex('au_mex_test_leak.cxx');
!tasklist /FI "imagename eq matlab.exe"
for k=1:10
    for j=1:10000
        au_mex_test_leak();
    end
    !tasklist /NH /FI "imagename eq matlab.exe"
end
disp('Done. If memory increased continually, report bug at awful.codeplex.com.');
