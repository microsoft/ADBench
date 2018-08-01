function out = is_up_to_date(results_fn,tool_fn)

if ~exist(results_fn,'file')
    out = false;
    return
end

a = dir(results_fn);
results_age = datetime(a.date);

b = dir(tool_fn);
tool_age = datetime(b.date);

out = (tool_age < results_age);
