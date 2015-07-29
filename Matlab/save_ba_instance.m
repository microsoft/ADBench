function save_ba_instance( fn, cams, X, w, obs )
%SAVE_BA_INSTANCE format:
%           n m p
%           cam1 (row)
%           .
%           camn (row)
%           X1 (row)
%           .
%           Xm (row)
%           w1 w2 ... wp
%           obs1 (row [camIdx ptIdx])
%           .
%           obsp
%           feat1 (row [x y])
%           .
%           featp

fid = fopen(fn,'w');

fprintf(fid,'%i %i %i\r\n',size(cams,2),size(X,2),size(obs,2));

for i=1:size(cams,2)
    for j=1:size(cams,1)
        fprintf(fid,'%f ',cams(j,i));
    end
    fprintf(fid,'\r\n');
end

for i=1:size(X,2)
    for j=1:size(X,1)
        fprintf(fid,'%f ',X(j,i));
    end
    fprintf(fid,'\r\n');
end

for i=1:size(w,2)
    fprintf(fid,'%f ',w(i));
end
fprintf(fid,'\r\n');

for i=1:size(obs,2)
    fprintf(fid,'%i %i\r\n',obs(1,i)-1,obs(2,i)-1); % switch to indxing from 0
end

for i=1:size(obs,2)
    fprintf(fid,'%f %f\r\n',obs(3,i),obs(4,i));
end

fclose(fid);

end

