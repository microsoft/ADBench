function retval = au_progressbar_ascii(tag, varargin)

% au_progressbar_ascii A function
%               au_progressbar_ascii('myfun', proportion)
%               will start the bar if it's not started
%               will stop it if proportion >= 1
%               au_progressbar_ascii('myfun', proportion, option, value...)
%               allows options to be set such as MIN_UPDATE_INTERVAL, 1(sec)
%
%               retval = 1 iff time since last report > MIN_UPDATE_INTERVAL

% Author: awf

if nargout > 0
  retval = 0;
end

global au_progressbar_ascii_data
if ~exist('au_progressbar_ascii_data', 'var')
  au_progressbar_ascii_data.xx = 0;
end

%% No arguments, test
if nargin == 0
  for k=1:20
    au_progressbar_ascii('k', (k-1)/20);
    pause(.1)
    au_progressbar_ascii('k', k/20);
  end
  
  for k=1:200
    au_progressbar_ascii('Big_K', (k-1)/200);
    pause(rand*.01);
    au_progressbar_ascii('Big_K', k/200);
  end
  
  return
end

%% Some arguments, first must be tag
if ~isstr(tag)
  error('expect first arg is tag');
end
% Second must be proportion
if nargin < 2
  error('no action');
end

% strip nonalphanumeric chars from tag
tag_title = tag;
%tag = mlp_stralpha(tag);

% Get any existing progressbar with this name
info = [];
if isfield(au_progressbar_ascii_data, tag)
  info = au_progressbar_ascii_data.(tag);
  if ~strcmp(tag_title, info.title)
    fprintf('au_progressbar_ascii: WARNING: tag has conflicting titles:\n')
    fprintf('  [%s]\n', tag_title);
    fprintf('  [%s]\n', info.title);
  end

  if ~isstruct(info)
    warning('dodgy info');
    info = [];
  else
    proportion = varargin{1};
    if ~ischar(proportion)
      if (proportion < info.last_proportion || proportion == 0)
        fprintf('au_progressbar_ascii: Restarting [%s]\n', tag);
        info = [];
      end
    end
  end
  % If info was zapped above, then remove it from the global
  if isempty(info)
    au_progressbar_ascii_data = rmfield(au_progressbar_ascii_data, tag);
  end
end

if isempty(info)
  % nonexistent progressbar, create one using tag
  info.timer = clock;
  info.last_update = info.timer;
  info.last_proportion = 0;
  info.begun = false;
  info.title = tag_title;
  % Min number of seconds between updates
  info.MIN_UPDATE_INTERVAL = .5;
  % find any variable assignments in varargin
  for k=1:length(varargin)-1
    if strcmp(varargin{k}, 'MIN_UPDATE_INTERVAL')
      info.MIN_UPDATE_INTERVAL = varargin{k+1};
    end
  end
  
  au_progressbar_ascii_data.(tag) = info;
end

%% Now we have a live progressbar, possibly newly created
%% stored in info, and in au_progressbar_ascii_data.(tag)
a1 = varargin{1};
if ~isstr(a1)
  % Normal case: It's a number, make progress.
  proportion = a1;
  
  if proportion > 1.0 - eps
    if info.begun
      fprintf('au_progressbar[%s]: done\n', info.title);
    end
    au_progressbar_ascii_data = rmfield(au_progressbar_ascii_data, tag);
    if nargout > 0
      retval = 1;
    end
    return
  end
  
  if proportion == 0
    au_progressbar_ascii_data.(tag) = info;
    if nargout > 0
      retval = 1;
    end
    return
  end
  
  %% au_progressbar_ascii('tag', 0.5) : update
  t_elapsed_since_last_update = etime(clock, info.last_update);
  if t_elapsed_since_last_update > info.MIN_UPDATE_INTERVAL
    % set retval to show this is time for an update
    if nargout > 0
      retval = 1;
    end
    
    if ~info.begun
      fprintf('au_progressbar[%s]: begin\n', info.title);
      info.begun = true;
    end
    
    t_elapsed = etime(clock, info.timer);
    t_remaining = t_elapsed/proportion - t_elapsed;
    if (proportion > 0.01) | (t_elapsed > 30)
      eta = datenum(info.timer) + (t_elapsed/proportion)/(24*3600);
      eta_s = datestr(eta, 0);
    else
      eta_s = 'waiting';
    end
    newtitle = sprintf('%s, eta %s [%s]', ...
      au_timestr(t_elapsed,1), ...
      au_timestr(t_remaining, 1), ...
      eta_s);
    %fprintf(' %s\n', au_timestr(t_remaining, 1));
    fprintf('au_progressbar[%s]: %s\n', info.title, newtitle);
    info.last_update = clock;
    info.last_proportion = proportion;
    info.MIN_UPDATE_INTERVAL = info.MIN_UPDATE_INTERVAL * 1.5;
    au_progressbar_ascii_data.(tag) = info;
  end
  return
end

%% We get here only in calls such as
% au_progressbar_ascii('tag', 'info');
switch a1
  case 'info'
    retval = info;
    
  case 'clear'
    au_progressbar_ascii(tag, 1);
  otherwise
    error
end
