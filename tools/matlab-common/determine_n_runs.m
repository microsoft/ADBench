% Copyright (c) Microsoft Corporation.
% Licensed under the MIT license.

function nruns = determine_n_runs(times_est)

nruns = zeros(size(times_est));
for i=1:numel(times_est)
    if times_est(i) < 5
        nruns(i) = 1000;
    elseif times_est(i) < 30
        nruns(i) = 100;
    elseif times_est(i) < 120
        nruns(i) = 10;
    elseif ~isinf(times_est(i))
        nruns(i) = 1; 
%         % it has already ran once - don't forget to move
%         % that result from time_est
%         nruns(i) = 0; 
    end
end

end