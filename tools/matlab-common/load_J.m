% Copyright (c) Microsoft Corporation.
% Licensed under the MIT license.

function [ J ] = load_J( fn )
%LOAD_J Summary of this function goes here
%   Detailed explanation goes here

fid = fopen(fn,'r');

rows = fscanf(fid,'%i',1);
cols = fscanf(fid,'%i',1);
J = fscanf(fid,'%lf',[cols rows])';

fclose(fid);

end

