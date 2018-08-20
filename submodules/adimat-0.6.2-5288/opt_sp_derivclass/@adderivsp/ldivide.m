function res= ldivide(s1, s2)
%ADDERIV/LDIVIDE Solve a matrix
%
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!


error('This operator is never emitted by ADiMat. Stop messing around in the automatically generated code!');

%if isa(s1, 'adderivsp')& isa(s2, 'adderiv')
   %ss1= size(s1.deriv, 1);
   %res.deriv= cell(ss1, 1);
   %for i= 1: ss1
      %res.deriv{i}= s1.grad{i}.\ s2.grad{i};
   %end
%elseif isa(s1, 'adderivsp')
   %ss1= size(s1.deriv, 1);
   %res.deriv= cell(ss1,1);
   %for i= 1: ss1
      %res.deriv{i}= s1.grad{i}.\ s2;
   %end
%else 
   %ss2= size(s2.deriv, 1);
   %res.deriv= cell(ss2,1);
   %for i= 1: ss2
      %res.deriv{i}= s1.\ s2.grad{i};
   %end
%end
%res= class(res, 'adderivsp');

