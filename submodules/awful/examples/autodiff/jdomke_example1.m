function y = jdomke_example1(x)

if nargin == 0
    %%
    syms x real
    y = jdomke_example1(x);
    au_ccode(diff(y,x))
    
    clear y
    return
end

  y = x;
  for i=1:100
    y = sin(x+y);
  
  end
end
