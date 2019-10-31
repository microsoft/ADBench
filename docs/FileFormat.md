# Input/Output files format

## GMM
### Input
  D k n</br>
  α<sub>1</sub></br>
    ...</br>
  α<sub>k</sub></br>
  μ<sub>1,1</sub> ... μ<sub>D,1</sub></br>
    ...</br>
  μ<sub>1,k</sub> ... μ<sub>D,k</sub></br>
  q<sub>1,1</sub> ... q<sub>D,1</sub> l<sub>1,1</sub> ... l<sub><sup>D(D-1)</sup>&frasl;<sub>2</sub>,1</sub></br>
    ...</br>
  q<sub>1,k</sub> ... q<sub>D,k</sub> l<sub>1,k</sub> ... l<sub><sup>D(D-1)</sup>&frasl;<sub>2</sub>,k</sub></br> 
  x<sub>1,1</sub> ... x<sub>D,1</sub></br>
    ...</br>
  x<sub>1,n</sub> ... x<sub>D,n</sub></br>
  γ m</br>
  
Definitions of all variables are given in the  [srajer-autodiff-screen.pdf](../../Documents/srajer-autodiff-screen.pdf), page 3.
Note that if replicate point mode is enabled the benchmark expects only a line containing x<sub>1,1</sub> ... x<sub>D,1</sub> and duplicates that point `n` times.

### Output

1. `..._F_...` file  
    Contains only the value of the function in the specified point. 
2. `..._J_...` file  
     v<sub>1</sub> ... v<sub>n</sub>      where v<sub>i</sub> are components of the objective gradient.
     
## BA
### Input
  n m p</br>
  p<sub>1</sub> ... p<sub>11</sub></br>
  x<sub>1</sub> x<sub>2</sub> x<sub>3</sub></br>
  w<sub>1</sub></br>
  feat<sub>1</sub> feat<sub>2</sub></br>

n,m,p are number of cams, points and observations.
Definitions of all other variables are given in the  [srajer-autodiff-screen.pdf](../../Documents/srajer-autodiff-screen.pdf), page 4.

### Output

1. `..._F_...` file  

    Reprojection error:</br>
    reproj_err<sub>1</sub></br>
    ...</br>
    reproj_err<sub>2*p</sub></br>
    Zach weight error:</br>
    w_err<sub>1</sub></br>
    ...</br>
    w_err<sub>p</sub></br>
2. `..._J_...` file

    This file contains sparse Jacobian of nrows * ncols size in the CSR format where ncols=2*p+p, nrows=11*n+3*m+p.
    It suggests the use of three one-dimensional arrays (`rows`,`cols`,`vals`).
     
      - `vals` holds all the nonzero entries of the Jacobian in the left-to-right top-to-bottom order.
      - `rows` is of length nrows + 1. It is defined recursively as follows:</br>
        `rows[0]` = 0</br>
	`rows[i]` = `rows[i-1]` + the number of nonzero elements on the i-1 string of the Jacobian
      - `cols[i]` contains the column index in the Jacobian of each element of `vals` and that's why it has the same size
      
     The resulting file looks as follows:</br>
     nrows ncols</br>
     rows_size</br>
     rows<sub>0</sub> ... rows<sub>rows_size-1</sub></br>
     cols_size</br>
     cols<sub>0</sub> ... cols<sub>cols_size-1</sub></br>
     vals<sub>0</sub> ... vals<sub>rows_size-1</sub></br>

## Hand
### Input
1. model/bones.txt
	Contains a list of lines where each line contains such parameters separated by ":" delimeter:
	- bone_name
	- bone_parent
	- base_relative<sub>1</sub> ... base_relative<sub>16</sub>
	- base_absolute<sub>1</sub> ... base_absolute<sub>16</sub>
2. model/vertices.txt
    Contains a list of lines where each line containts such parameters separated by ":" delimeter:
	- v<sub>1</sub> ... v<sub>3</sub>
	- dummy<sub>1</sub> ... dummy<sub>5</sub>
	- n
	- bone<sub>1</sub>:weight<sub>bone<sub>1</sub>,vert<sub>1</sub></sub>: ... :bone<sub>n</sub>:weight<sub>bone<sub>n</sub>,vert<sub>n</sub></sub>

3. model/triangles.txt
    Contains a list of lines:  
      - v<sub>1</sub>:v<sub>2</sub>:v<sub>3</sub>
 
 4. input.txt
    
      N  n_theta</br>
      correspondance<sub>1</sub> point<sub>1,1</sub> point<sub>1,2</sub> point<sub>1,3</sub></br>
        ...</br>
      correspondance<sub>N</sub> point<sub>N,1</sub> point<sub>N,2</sub> point<sub>N,3</sub></br>
      u<sub>1,1</sub> u<sub>1,2</sub></br>
        ...</br>
      u<sub>n_pts,1</sub> u<sub>N,2</sub></br>
      θ<sub>1</sub></br>
        ...</br>
      θ<sub>n_theta</sub></br>
   
Note that the benchmark expects "u" block only if complicated mode is enabled.

Definitions of all variables are given in the  [srajer-autodiff-screen.pdf](../../Documents/srajer-autodiff-screen.pdf), page 5.

### Output
1. `..._F_...` file  
     v<sub>1</sub> ... v<sub>n</sub>      where v<sub>i</sub> are components of the objective vector.
2. `..._J_...` file  

     j<sub>1,1</sub> ... j<sub>1,ncols</sub></br>
     ...</br>
     j<sub>nrows,1</sub> ... j<sub>nrows,ncols</sub></br>
    
    where ncols=(complicated ? 2 : 0) + n_theta, nrows=3*n_pts

## LSTM
### Input
  l c b</br>
  main_param<sub>1</sub> ... main_param<sub>2l4b</sub></br>
  extra_param<sub>1</sub> ... extra_param<sub>3b</sub> </br>
  state<sub>1</sub> ... state<sub>2lb</sub></br>
  seq<sub>1</sub> ... seq<sub>cb</sub> </br>

### Output

1. `..._F_...` file  
    Contains only the value of the function in the specified point. 
2. `..._J_...` file  
     v<sub>1</sub> ... v<sub>n</sub>      where v<sub>i</sub> are components of the objective gradient.
