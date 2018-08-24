function [ncolors partition] = cpr(A)
% CPR    Computes a column partition of a matrix by the
%    Curtis-Powell-Reid approach.
%
%    PARTITION = CPR(A) computes a partition of a matrix with
%    a sparsity pattern A. More precisely, PARTITION(i)=k
%    is used to denote that column i has the color k.

% STCS 2007 at RWTH Aachen University
% 05/21/07 by M. Luelfesmann


% We are only interested in the nonzero pattern 
A = spones(A);

% Array for saving which column belongs to which column group
partition = zeros(1,size(A,2));
color = 0;

% All columns must belong to a column group
while any(partition==0)

    % Use the next column group
    color = color+1;

    % Search for columns which have not been colored, yet.
    indices = find(partition==0);

    % Add the first column to the column group
    testcol = A(:,indices(1));
    partition(indices(1)) = color;

    % Look for more columns which can be added to this column group
    for i = 2:length(indices)
        if (A(:,indices(i))'*testcol)==0
            testcol = testcol+A(:,indices(i));
            partition(indices(i)) = color;
        end
    end
end

ncolors = color;
