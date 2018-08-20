function r = admConfirmTransmission()
  answer = admGetPref('confirmTransmission');
  if strcmp(answer, 'yes')
    r = true;
  end

% $Id: admConfirmTransmission.m 4092 2014-05-01 17:48:21Z willkomm $
