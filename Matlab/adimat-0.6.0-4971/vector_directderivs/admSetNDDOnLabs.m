% function r = admSetNDDOnLabs(ndd)
%
% This is a helper function to propagate the NDD to all labs. This
% is in a separate function because the Octave parser does not
% understand the spmd construct.
%
function admSetNDDOnLabs(ndd)
  % fprintf(admLogFile('main'), 'setting the NDD on all the labs\n');
  spmd
    option('ndd', ndd);
  end
% $Id: admSetNDDOnLabs.m 3696 2013-06-06 14:50:25Z willkomm $
