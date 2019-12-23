% Copyright (c) Microsoft Corporation.
% Licensed under the MIT license.

function save_ba_instance( fn, cams, X, w, obs, n, m, p )
%SAVE_BA_INSTANCE format:
%           n m p
%           cam (row)
%           pt (row)
%           w
%           feat1 (row [x y])

fid = fopen(fn,'w');

if nargin < 6
    n = size(cams,2);
    m = size(X,2);
    p = size(obs,2);
end

fprintf(fid,'%i %i %i\r\n',n,m,p);

camIdx = obs(1,1);
ptIdx = obs(2,1);

for j=1:size(cams,1)
    fprintf(fid,'%f ',cams(j,camIdx));
end
fprintf(fid,'\r\n');

for j=1:size(X,1)
    fprintf(fid,'%f ',X(j,ptIdx));
end
fprintf(fid,'\r\n');

fprintf(fid,'%f ',w(1));
fprintf(fid,'\r\n');

fprintf(fid,'%f %f\r\n',obs(3,1),obs(4,1));

% for i=1:size(cams,2)
%     for j=1:size(cams,1)
%         fprintf(fid,'%f ',cams(j,i));
%     end
%     fprintf(fid,'\r\n');
% end
% 
% for i=1:size(X,2)
%     for j=1:size(X,1)
%         fprintf(fid,'%f ',X(j,i));
%     end
%     fprintf(fid,'\r\n');
% end
% 
% for i=1:size(w,2)
%     fprintf(fid,'%f ',w(i));
% end
% fprintf(fid,'\r\n');
% 
% for i=1:size(obs,2)
%     fprintf(fid,'%i %i\r\n',obs(1,i)-1,obs(2,i)-1); % switch to indxing from 0
% end
% 
% for i=1:size(obs,2)
%     fprintf(fid,'%f %f\r\n',obs(3,i),obs(4,i));
% end

fclose(fid);

end

