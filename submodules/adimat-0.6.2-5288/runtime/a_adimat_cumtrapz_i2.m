% Generated by ADiMat 0.6.0-4867
% © 2001-2008 Andre Vehreschild <vehreschild@sc.rwth-aachen.de>
% © 2009-2013 Johannes Willkomm <johannes.willkomm@sc.tu-darmstadt.de>
% RWTH Aachen University, 52056 Aachen, Germany
% TU Darmstadt, 64289 Darmstadt, Germany
% Visit us on the web at http://www.adimat.de/
% Report bugs to adimat-users@lists.sc.informatik.tu-darmstadt.de
%
%                             DISCLAIMER
% 
% ADiMat was prepared as part of an employment at the Institute for Scientific Computing,
% RWTH Aachen University, Germany and at the Institute for Scientific Computing,
% TU Darmstadt, Germany and is provided AS IS. 
% NEITHER THE AUTHOR(S), THE GOVERNMENT OF THE FEDERAL REPUBLIC OF GERMANY
% NOR ANY AGENCY THEREOF, NOR THE RWTH AACHEN UNIVERSITY, NOT THE TU DARMSTADT,
% INCLUDING ANY OF THEIR EMPLOYEES OR OFFICERS, MAKES ANY WARRANTY, EXPRESS OR IMPLIED,
% OR ASSUMES ANY LEGAL LIABILITY OR RESPONSIBILITY FOR THE ACCURACY, COMPLETENESS,
% OR USEFULNESS OF ANY INFORMATION OR PROCESS DISCLOSED, OR REPRESENTS THAT ITS USE
% WOULD NOT INFRINGE PRIVATELY OWNED RIGHTS.
%
% Flags: BACKWARDMODE,  NOOPEROPTIM,
%   NOLOCALCSE,  NOGLOBALCSE,  NOPRESCALARFOLDING,
%   NOPOSTSCALARFOLDING,  NOCONSTFOLDMULT0,  FUNCMODE,
%   NOTMPCLEAR,  DUMP_XML,  PARSE_ONLY,
%   UNBOUND_ERROR
%
% Parameters:
%  - dependents=z
%  - independents=b
%  - inputEncoding=ISO-8859-1
%  - output-mode: plain
%  - output-file: ad_out/a_adimat_cumtrapz_i2.m
%  - output-file-prefix: 
%  - output-directory: ad_out
% Generated by ADiMat 0.6.0-4867
% © 2001-2008 Andre Vehreschild <vehreschild@sc.rwth-aachen.de>
% © 2009-2013 Johannes Willkomm <johannes.willkomm@sc.tu-darmstadt.de>
% RWTH Aachen University, 52056 Aachen, Germany
% TU Darmstadt, 64289 Darmstadt, Germany
% Visit us on the web at http://www.adimat.de/
% Report bugs to adimat-users@lists.sc.informatik.tu-darmstadt.de
%
%                             DISCLAIMER
% 
% ADiMat was prepared as part of an employment at the Institute for Scientific Computing,
% RWTH Aachen University, Germany and at the Institute for Scientific Computing,
% TU Darmstadt, Germany and is provided AS IS. 
% NEITHER THE AUTHOR(S), THE GOVERNMENT OF THE FEDERAL REPUBLIC OF GERMANY
% NOR ANY AGENCY THEREOF, NOR THE RWTH AACHEN UNIVERSITY, NOT THE TU DARMSTADT,
% INCLUDING ANY OF THEIR EMPLOYEES OR OFFICERS, MAKES ANY WARRANTY, EXPRESS OR IMPLIED,
% OR ASSUMES ANY LEGAL LIABILITY OR RESPONSIBILITY FOR THE ACCURACY, COMPLETENESS,
% OR USEFULNESS OF ANY INFORMATION OR PROCESS DISCLOSED, OR REPRESENTS THAT ITS USE
% WOULD NOT INFRINGE PRIVATELY OWNED RIGHTS.
%
% Flags: BACKWARDMODE,  NOOPEROPTIM,
%   NOLOCALCSE,  NOGLOBALCSE,  NOPRESCALARFOLDING,
%   NOPOSTSCALARFOLDING,  NOCONSTFOLDMULT0,  FUNCMODE,
%   NOTMPCLEAR,  DUMP_XML,  PARSE_ONLY,
%   UNBOUND_ERROR
%
% Parameters:
%  - dependents=z
%  - independents=b
%  - inputEncoding=ISO-8859-1
%  - output-mode: plain
%  - output-file: ad_out/a_adimat_cumtrapz_i2.m
%  - output-file-prefix: 
%  - output-directory: ad_out
%
% Functions in this file: a_adimat_cumtrapz, rec_adimat_cumtrapz,
%  ret_adimat_cumtrapz, adimat_cumtrapz_uni1, a_adimat_cumtrapz_uni2,
%  rec_adimat_cumtrapz_uni2, ret_adimat_cumtrapz_uni2, adimat_cumtrapz_uni2,
%  a_adimat_cumtrapz_nonuni2, rec_adimat_cumtrapz_nonuni2, ret_adimat_cumtrapz_nonuni2,
%  adimat_cumtrapz_nonuni2, a_adimat_cumtrapz_nonuni3, rec_adimat_cumtrapz_nonuni3,
%  ret_adimat_cumtrapz_nonuni3, adimat_cumtrapz_nonuni3
%

function [a_b nr_z] = a_adimat_cumtrapz(a, b, c, a_z)
   z = 0;
   tmpba1 = 0;
   if nargin == 1
      tmpba1 = 1;
      adimat_push1(z);
      z = adimat_cumtrapz_uni1(a);
   elseif nargin == 2
      tmpba1 = 2;
      tmpba2 = 0;
      if isscalar(b)
         tmpba2 = 1;
         adimat_push1(z);
         z = rec_adimat_cumtrapz_uni2(a, b);
      else
         adimat_push1(z);
         z = rec_adimat_cumtrapz_nonuni2(a, b);
      end
      adimat_push1(tmpba2);
   else
      adimat_push1(z);
      z = rec_adimat_cumtrapz_nonuni3(a, b, c);
   end
   adimat_push1(tmpba1);
   nr_z = z;
   a_b = a_zeros1(b);
   if nargin < 4
      a_z = a_zeros1(z);
   end
   tmpba1 = adimat_pop1;
   if tmpba1 == 1
      z = adimat_pop1;
      a_z = a_zeros1(z);
   elseif tmpba1 == 2
      tmpba2 = adimat_pop1;
      if tmpba2 == 1
         [tmpadjc2] = ret_adimat_cumtrapz_uni2(a_z);
         z = adimat_pop1;
         a_b = adimat_adjsum(a_b, tmpadjc2);
         a_z = a_zeros1(z);
      else
         [tmpadjc2] = ret_adimat_cumtrapz_nonuni2(a_z);
         z = adimat_pop1;
         a_b = adimat_adjsum(a_b, tmpadjc2);
         a_z = a_zeros1(z);
      end
   else
      [tmpadjc2] = ret_adimat_cumtrapz_nonuni3(a_z);
      z = adimat_pop1;
      a_b = adimat_adjsum(a_b, tmpadjc2);
      a_z = a_zeros1(z);
   end
end

function z = rec_adimat_cumtrapz(a, b, c)
   z = 0;
   tmpba1 = 0;
   if nargin == 1
      tmpba1 = 1;
      adimat_push1(z);
      z = adimat_cumtrapz_uni1(a);
   elseif nargin == 2
      tmpba1 = 2;
      tmpba2 = 0;
      if isscalar(b)
         tmpba2 = 1;
         adimat_push1(z);
         z = rec_adimat_cumtrapz_uni2(a, b);
      else
         adimat_push1(z);
         z = rec_adimat_cumtrapz_nonuni2(a, b);
      end
      adimat_push1(tmpba2);
   else
      adimat_push1(z);
      z = rec_adimat_cumtrapz_nonuni3(a, b, c);
   end
   adimat_push(tmpba1, z, a, b);
   if nargin > 2
      adimat_push1(c);
   end
   adimat_push1(nargin);
end

function a_b = ret_adimat_cumtrapz(a_z)
   tmpnargin = adimat_pop1;
   if tmpnargin > 2
      c = adimat_pop1;
   end
   [b a z] = adimat_pop;
   a_b = a_zeros1(b);
   if nargin < 1
      a_z = a_zeros1(z);
   end
   tmpba1 = adimat_pop1;
   if tmpba1 == 1
      z = adimat_pop1;
      a_z = a_zeros1(z);
   elseif tmpba1 == 2
      tmpba2 = adimat_pop1;
      if tmpba2 == 1
         [tmpadjc2] = ret_adimat_cumtrapz_uni2(a_z);
         z = adimat_pop1;
         a_b = adimat_adjsum(a_b, tmpadjc2);
         a_z = a_zeros1(z);
      else
         [tmpadjc2] = ret_adimat_cumtrapz_nonuni2(a_z);
         z = adimat_pop1;
         a_b = adimat_adjsum(a_b, tmpadjc2);
         a_z = a_zeros1(z);
      end
   else
      [tmpadjc2] = ret_adimat_cumtrapz_nonuni3(a_z);
      z = adimat_pop1;
      a_b = adimat_adjsum(a_b, tmpadjc2);
      a_z = a_zeros1(z);
   end
end

function z = adimat_cumtrapz_uni1(Y)
   dim = adimat_first_nonsingleton(Y);
   z = adimat_cumtrapz_uni2(Y, dim);
end

function [a_dim nr_z] = a_adimat_cumtrapz_uni2(Y, dim, a_z)
   tmpda1 = 0;
   tmpca3 = 0;
   tmpca2 = 0;
   tmpca1 = 0;
   z = 0;
   inds = 0;
   Y1 = 0;
   Y2 = 0;
   sy = 0;
   len = size(Y, dim);
   tmpba1 = 0;
   if len < 2
      tmpba1 = 1;
      adimat_push1(tmpda1);
      tmpda1 = size(Y);
      adimat_push1(z);
      z = zeros(tmpda1);
   else
      adimat_push1(inds);
      inds = repmat({':'}, [length(size(Y)) 1]);
      adimat_push_cell_index(inds, dim);
      inds{dim} = 1 : len-1;
      adimat_push1(Y1);
      Y1 = Y(inds{:});
      adimat_push_cell_index(inds, dim);
      inds{dim} = 2 : len;
      adimat_push1(Y2);
      Y2 = Y(inds{:});
      adimat_push1(tmpca3);
      tmpca3 = cumsum(Y2, dim);
      adimat_push1(tmpca2);
      tmpca2 = cumsum(Y1, dim);
      adimat_push1(tmpca1);
      tmpca1 = tmpca2 + tmpca3;
      adimat_push1(z);
      z = 0.5 .* tmpca1;
      adimat_push1(sy);
      sy = size(Y);
      adimat_push_index1(sy, dim);
      sy(dim) = 1;
      adimat_push1(tmpda1);
      tmpda1 = zeros(sy);
      adimat_push1(z);
      z = cat(dim, tmpda1, z);
   end
   adimat_push1(tmpba1);
   nr_z = z;
   [a_tmpca3 a_tmpca2 a_tmpca1 a_dim] = a_zeros(tmpca3, tmpca2, tmpca1, dim);
   if nargin < 3
      a_z = a_zeros1(z);
   end
   tmpba1 = adimat_pop1;
   if tmpba1 == 1
      z = adimat_pop1;
      a_z = a_zeros1(z);
      tmpda1 = adimat_pop1;
   else
      z = adimat_pop1;
      a_dim = adimat_adjsum(a_dim, a_cat(a_z, dim));
      tmpsa1 = a_z;
      a_z = a_zeros1(z);
      a_z = adimat_adjsum(a_z, a_cat(tmpsa1, dim, tmpda1, z));
      tmpda1 = adimat_pop1;
      sy = adimat_pop_index1(sy, dim);
      [sy z] = adimat_pop;
      a_tmpca1 = adimat_adjsum(a_tmpca1, adimat_adjred(tmpca1, 0.5 .* a_z));
      a_z = a_zeros1(z);
      tmpca1 = adimat_pop1;
      a_tmpca2 = adimat_adjsum(a_tmpca2, adimat_adjred(tmpca2, a_tmpca1));
      a_tmpca3 = adimat_adjsum(a_tmpca3, adimat_adjred(tmpca3, a_tmpca1));
      a_tmpca1 = a_zeros1(tmpca1);
      tmpca2 = adimat_pop1;
      a_tmpca2 = a_zeros1(tmpca2);
      tmpca3 = adimat_pop1;
      a_tmpca3 = a_zeros1(tmpca3);
      Y2 = adimat_pop1;
      inds = adimat_pop_cell_index(inds, dim);
      Y1 = adimat_pop1;
      inds = adimat_pop_cell_index(inds, dim);
      inds = adimat_pop1;
   end
end

function z = rec_adimat_cumtrapz_uni2(Y, dim)
   tmpda1 = 0;
   tmpca3 = 0;
   tmpca2 = 0;
   tmpca1 = 0;
   z = 0;
   inds = 0;
   Y1 = 0;
   Y2 = 0;
   sy = 0;
   len = size(Y, dim);
   tmpba1 = 0;
   if len < 2
      tmpba1 = 1;
      adimat_push1(tmpda1);
      tmpda1 = size(Y);
      adimat_push1(z);
      z = zeros(tmpda1);
   else
      adimat_push1(inds);
      inds = repmat({':'}, [length(size(Y)) 1]);
      adimat_push_cell_index(inds, dim);
      inds{dim} = 1 : len-1;
      adimat_push1(Y1);
      Y1 = Y(inds{:});
      adimat_push_cell_index(inds, dim);
      inds{dim} = 2 : len;
      adimat_push1(Y2);
      Y2 = Y(inds{:});
      adimat_push1(tmpca3);
      tmpca3 = cumsum(Y2, dim);
      adimat_push1(tmpca2);
      tmpca2 = cumsum(Y1, dim);
      adimat_push1(tmpca1);
      tmpca1 = tmpca2 + tmpca3;
      adimat_push1(z);
      z = 0.5 .* tmpca1;
      adimat_push1(sy);
      sy = size(Y);
      adimat_push_index1(sy, dim);
      sy(dim) = 1;
      adimat_push1(tmpda1);
      tmpda1 = zeros(sy);
      adimat_push1(z);
      z = cat(dim, tmpda1, z);
   end
   adimat_push(tmpba1, inds, Y1, Y2, sy, len, tmpda1, tmpca3, tmpca2, tmpca1, z, Y, dim);
end

function a_dim = ret_adimat_cumtrapz_uni2(a_z)
   [dim Y z tmpca1 tmpca2 tmpca3 tmpda1 len sy Y2 Y1 inds] = adimat_pop;
   [a_tmpca3 a_tmpca2 a_tmpca1 a_dim] = a_zeros(tmpca3, tmpca2, tmpca1, dim);
   if nargin < 1
      a_z = a_zeros1(z);
   end
   tmpba1 = adimat_pop1;
   if tmpba1 == 1
      z = adimat_pop1;
      a_z = a_zeros1(z);
      tmpda1 = adimat_pop1;
   else
      z = adimat_pop1;
      a_dim = adimat_adjsum(a_dim, a_cat(a_z, dim));
      tmpsa1 = a_z;
      a_z = a_zeros1(z);
      a_z = adimat_adjsum(a_z, a_cat(tmpsa1, dim, tmpda1, z));
      tmpda1 = adimat_pop1;
      sy = adimat_pop_index1(sy, dim);
      [sy z] = adimat_pop;
      a_tmpca1 = adimat_adjsum(a_tmpca1, adimat_adjred(tmpca1, 0.5 .* a_z));
      a_z = a_zeros1(z);
      tmpca1 = adimat_pop1;
      a_tmpca2 = adimat_adjsum(a_tmpca2, adimat_adjred(tmpca2, a_tmpca1));
      a_tmpca3 = adimat_adjsum(a_tmpca3, adimat_adjred(tmpca3, a_tmpca1));
      a_tmpca1 = a_zeros1(tmpca1);
      tmpca2 = adimat_pop1;
      a_tmpca2 = a_zeros1(tmpca2);
      tmpca3 = adimat_pop1;
      a_tmpca3 = a_zeros1(tmpca3);
      Y2 = adimat_pop1;
      inds = adimat_pop_cell_index(inds, dim);
      Y1 = adimat_pop1;
      inds = adimat_pop_cell_index(inds, dim);
      inds = adimat_pop1;
   end
end

function z = adimat_cumtrapz_uni2(Y, dim)
   tmpda1 = 0;
   tmpca3 = 0;
   tmpca2 = 0;
   tmpca1 = 0;
   z = 0;
   inds = 0;
   Y1 = 0;
   Y2 = 0;
   sy = 0;
   len = size(Y, dim);
   if len < 2
      tmpda1 = size(Y);
      z = zeros(tmpda1);
   else
      inds = repmat({':'}, [length(size(Y)) 1]);
      inds{dim} = 1 : len-1;
      Y1 = Y(inds{:});
      inds{dim} = 2 : len;
      Y2 = Y(inds{:});
      tmpca3 = cumsum(Y2, dim);
      tmpca2 = cumsum(Y1, dim);
      tmpca1 = tmpca2 + tmpca3;
      z = 0.5 .* tmpca1;
      sy = size(Y);
      sy(dim) = 1;
      tmpda1 = zeros(sy);
      z = cat(dim, tmpda1, z);
   end
end

function [a_Y nr_z] = a_adimat_cumtrapz_nonuni2(X, Y, dim, a_z)
   adimat_push1(dim);
   dim = adimat_first_nonsingleton(Y);
   z = rec_adimat_cumtrapz_nonuni3(X, Y, dim);
   nr_z = z;
   a_Y = a_zeros1(Y);
   if nargin < 4
      a_z = a_zeros1(z);
   end
   [tmpadjc2] = ret_adimat_cumtrapz_nonuni3(a_z);
   a_Y = adimat_adjsum(a_Y, tmpadjc2);
   dim = adimat_pop1;
end

function z = rec_adimat_cumtrapz_nonuni2(X, Y, dim)
   adimat_push1(dim);
   dim = adimat_first_nonsingleton(Y);
   z = rec_adimat_cumtrapz_nonuni3(X, Y, dim);
   adimat_push(z, X, Y);
   if nargin > 2
      adimat_push1(dim);
   end
   adimat_push1(nargin);
end

function a_Y = ret_adimat_cumtrapz_nonuni2(a_z)
   tmpnargin = adimat_pop1;
   if tmpnargin > 2
      dim = adimat_pop1;
   end
   [Y X z] = adimat_pop;
   a_Y = a_zeros1(Y);
   if nargin < 1
      a_z = a_zeros1(z);
   end
   [tmpadjc2] = ret_adimat_cumtrapz_nonuni3(a_z);
   a_Y = adimat_adjsum(a_Y, tmpadjc2);
   dim = adimat_pop1;
end

function z = adimat_cumtrapz_nonuni2(X, Y, dim)
   dim = adimat_first_nonsingleton(Y);
   z = adimat_cumtrapz_nonuni3(X, Y, dim);
end

function [a_Y nr_z] = a_adimat_cumtrapz_nonuni3(X, Y, dim, a_z)
   tmpda1 = 0;
   tmpca5 = 0;
   tmpca4 = 0;
   tmpca3 = 0;
   tmpca2 = 0;
   tmpca1 = 0;
   z = 0;
   ndim = 0;
   D = 0;
   a = 0;
   b = 0;
   N = 0;
   sy1 = 0;
   inds = 0;
   Y1 = 0;
   Y2 = 0;
   len = size(Y, dim);
   tmpba1 = 0;
   if len < 2
      tmpba1 = 1;
      adimat_push1(tmpda1);
      tmpda1 = size(Y);
      adimat_push1(z);
      z = zeros(tmpda1);
   else
      adimat_push1(ndim);
      ndim = length(size(Y));
      adimat_push1(D);
      D = diff(X);
      adimat_push1(a);
      a = 0;
      adimat_push1(b);
      b = sum(D);
      adimat_push1(N);
      N = len;
      adimat_push1(D);
      D = reshape(D, [ones(1, dim - 1) len - 1 ones(1, ndim - dim)]);
      adimat_push1(sy1);
      sy1 = size(Y);
      adimat_push_index1(sy1, dim);
      sy1(dim) = 1;
      adimat_push1(D);
      D = repmat(D, sy1);
      adimat_push1(inds);
      inds = repmat({':'}, [length(size(Y)) 1]);
      adimat_push_cell_index(inds, dim);
      inds{dim} = 1 : len-1;
      adimat_push1(Y1);
      Y1 = Y(inds{:});
      adimat_push_cell_index(inds, dim);
      inds{dim} = 2 : len;
      adimat_push1(Y2);
      Y2 = Y(inds{:});
      adimat_push1(tmpca5);
      tmpca5 = Y2 .* D;
      adimat_push1(tmpca4);
      tmpca4 = cumsum(tmpca5, dim);
      adimat_push1(tmpca3);
      tmpca3 = Y1 .* D;
      adimat_push1(tmpca2);
      tmpca2 = cumsum(tmpca3, dim);
      adimat_push1(tmpca1);
      tmpca1 = tmpca2 + tmpca4;
      adimat_push1(z);
      z = 0.5 * tmpca1;
      adimat_push1(tmpda1);
      tmpda1 = zeros(sy1);
      adimat_push1(z);
      z = cat(dim, tmpda1, z);
   end
   adimat_push1(tmpba1);
   nr_z = z;
   [a_Y1 a_Y2 a_tmpca5 a_tmpca4 a_tmpca3 a_tmpca2 a_tmpca1 a_Y] = a_zeros(Y1, Y2, tmpca5, tmpca4, tmpca3, tmpca2, tmpca1, Y);
   if nargin < 4
      a_z = a_zeros1(z);
   end
   tmpba1 = adimat_pop1;
   if tmpba1 == 1
      z = adimat_pop1;
      a_z = a_zeros1(z);
      tmpda1 = adimat_pop1;
   else
      z = adimat_pop1;
      tmpsa1 = a_z;
      a_z = a_zeros1(z);
      a_z = adimat_adjsum(a_z, a_cat(tmpsa1, dim, tmpda1, z));
      [tmpda1 z] = adimat_pop;
      a_tmpca1 = adimat_adjsum(a_tmpca1, adimat_adjmultr(tmpca1, 0.5, a_z));
      a_z = a_zeros1(z);
      tmpca1 = adimat_pop1;
      a_tmpca2 = adimat_adjsum(a_tmpca2, adimat_adjred(tmpca2, a_tmpca1));
      a_tmpca4 = adimat_adjsum(a_tmpca4, adimat_adjred(tmpca4, a_tmpca1));
      a_tmpca1 = a_zeros1(tmpca1);
      tmpca2 = adimat_pop1;
      a_tmpca3 = adimat_adjsum(a_tmpca3, a_cumsum(a_tmpca2, 1, tmpca3, dim));
      a_tmpca2 = a_zeros1(tmpca2);
      tmpca3 = adimat_pop1;
      a_Y1 = adimat_adjsum(a_Y1, adimat_adjred(Y1, a_tmpca3 .* D));
      a_tmpca3 = a_zeros1(tmpca3);
      tmpca4 = adimat_pop1;
      a_tmpca5 = adimat_adjsum(a_tmpca5, a_cumsum(a_tmpca4, 1, tmpca5, dim));
      a_tmpca4 = a_zeros1(tmpca4);
      tmpca5 = adimat_pop1;
      a_Y2 = adimat_adjsum(a_Y2, adimat_adjred(Y2, a_tmpca5 .* D));
      a_tmpca5 = a_zeros1(tmpca5);
      Y2 = adimat_pop1;
      a_Y(inds{:}) = adimat_adjsum(a_Y(inds{:}), a_Y2);
      a_Y2 = a_zeros1(Y2);
      inds = adimat_pop_cell_index(inds, dim);
      Y1 = adimat_pop1;
      a_Y(inds{:}) = adimat_adjsum(a_Y(inds{:}), a_Y1);
      a_Y1 = a_zeros1(Y1);
      inds = adimat_pop_cell_index(inds, dim);
      [inds D] = adimat_pop;
      sy1 = adimat_pop_index1(sy1, dim);
      [sy1 D N b a D ndim] = adimat_pop;
   end
end

function z = rec_adimat_cumtrapz_nonuni3(X, Y, dim)
   tmpda1 = 0;
   tmpca5 = 0;
   tmpca4 = 0;
   tmpca3 = 0;
   tmpca2 = 0;
   tmpca1 = 0;
   z = 0;
   ndim = 0;
   D = 0;
   a = 0;
   b = 0;
   N = 0;
   sy1 = 0;
   inds = 0;
   Y1 = 0;
   Y2 = 0;
   len = size(Y, dim);
   tmpba1 = 0;
   if len < 2
      tmpba1 = 1;
      adimat_push1(tmpda1);
      tmpda1 = size(Y);
      adimat_push1(z);
      z = zeros(tmpda1);
   else
      adimat_push1(ndim);
      ndim = length(size(Y));
      adimat_push1(D);
      D = diff(X);
      adimat_push1(a);
      a = 0;
      adimat_push1(b);
      b = sum(D);
      adimat_push1(N);
      N = len;
      adimat_push1(D);
      D = reshape(D, [ones(1, dim - 1) len - 1 ones(1, ndim - dim)]);
      adimat_push1(sy1);
      sy1 = size(Y);
      adimat_push_index1(sy1, dim);
      sy1(dim) = 1;
      adimat_push1(D);
      D = repmat(D, sy1);
      adimat_push1(inds);
      inds = repmat({':'}, [length(size(Y)) 1]);
      adimat_push_cell_index(inds, dim);
      inds{dim} = 1 : len-1;
      adimat_push1(Y1);
      Y1 = Y(inds{:});
      adimat_push_cell_index(inds, dim);
      inds{dim} = 2 : len;
      adimat_push1(Y2);
      Y2 = Y(inds{:});
      adimat_push1(tmpca5);
      tmpca5 = Y2 .* D;
      adimat_push1(tmpca4);
      tmpca4 = cumsum(tmpca5, dim);
      adimat_push1(tmpca3);
      tmpca3 = Y1 .* D;
      adimat_push1(tmpca2);
      tmpca2 = cumsum(tmpca3, dim);
      adimat_push1(tmpca1);
      tmpca1 = tmpca2 + tmpca4;
      adimat_push1(z);
      z = 0.5 * tmpca1;
      adimat_push1(tmpda1);
      tmpda1 = zeros(sy1);
      adimat_push1(z);
      z = cat(dim, tmpda1, z);
   end
   adimat_push(tmpba1, ndim, D, a, b, N, sy1, inds, Y1, Y2, len, tmpda1, tmpca5, tmpca4, tmpca3, tmpca2, tmpca1, z, X, Y);
   if nargin > 2
      adimat_push1(dim);
   end
   adimat_push1(nargin);
end

function a_Y = ret_adimat_cumtrapz_nonuni3(a_z)
   tmpnargin = adimat_pop1;
   if tmpnargin > 2
      dim = adimat_pop1;
   end
   [Y X z tmpca1 tmpca2 tmpca3 tmpca4 tmpca5 tmpda1 len Y2 Y1 inds sy1 N b a D ndim] = adimat_pop;
   [a_Y1 a_Y2 a_tmpca5 a_tmpca4 a_tmpca3 a_tmpca2 a_tmpca1 a_Y] = a_zeros(Y1, Y2, tmpca5, tmpca4, tmpca3, tmpca2, tmpca1, Y);
   if nargin < 1
      a_z = a_zeros1(z);
   end
   tmpba1 = adimat_pop1;
   if tmpba1 == 1
      z = adimat_pop1;
      a_z = a_zeros1(z);
      tmpda1 = adimat_pop1;
   else
      z = adimat_pop1;
      tmpsa1 = a_z;
      a_z = a_zeros1(z);
      a_z = adimat_adjsum(a_z, a_cat(tmpsa1, dim, tmpda1, z));
      [tmpda1 z] = adimat_pop;
      a_tmpca1 = adimat_adjsum(a_tmpca1, adimat_adjmultr(tmpca1, 0.5, a_z));
      a_z = a_zeros1(z);
      tmpca1 = adimat_pop1;
      a_tmpca2 = adimat_adjsum(a_tmpca2, adimat_adjred(tmpca2, a_tmpca1));
      a_tmpca4 = adimat_adjsum(a_tmpca4, adimat_adjred(tmpca4, a_tmpca1));
      a_tmpca1 = a_zeros1(tmpca1);
      tmpca2 = adimat_pop1;
      a_tmpca3 = adimat_adjsum(a_tmpca3, a_cumsum(a_tmpca2, 1, tmpca3, dim));
      a_tmpca2 = a_zeros1(tmpca2);
      tmpca3 = adimat_pop1;
      a_Y1 = adimat_adjsum(a_Y1, adimat_adjred(Y1, a_tmpca3 .* D));
      a_tmpca3 = a_zeros1(tmpca3);
      tmpca4 = adimat_pop1;
      a_tmpca5 = adimat_adjsum(a_tmpca5, a_cumsum(a_tmpca4, 1, tmpca5, dim));
      a_tmpca4 = a_zeros1(tmpca4);
      tmpca5 = adimat_pop1;
      a_Y2 = adimat_adjsum(a_Y2, adimat_adjred(Y2, a_tmpca5 .* D));
      a_tmpca5 = a_zeros1(tmpca5);
      Y2 = adimat_pop1;
      a_Y(inds{:}) = adimat_adjsum(a_Y(inds{:}), a_Y2);
      a_Y2 = a_zeros1(Y2);
      inds = adimat_pop_cell_index(inds, dim);
      Y1 = adimat_pop1;
      a_Y(inds{:}) = adimat_adjsum(a_Y(inds{:}), a_Y1);
      a_Y1 = a_zeros1(Y1);
      inds = adimat_pop_cell_index(inds, dim);
      [inds D] = adimat_pop;
      sy1 = adimat_pop_index1(sy1, dim);
      [sy1 D N b a D ndim] = adimat_pop;
   end
end
% $Id: adimat_cumtrapz.m 4860 2015-02-07 13:49:39Z willkomm $

function z = adimat_cumtrapz_nonuni3(X, Y, dim)
   tmpda1 = 0;
   tmpca5 = 0;
   tmpca4 = 0;
   tmpca3 = 0;
   tmpca2 = 0;
   tmpca1 = 0;
   z = 0;
   ndim = 0;
   D = 0;
   a = 0;
   b = 0;
   N = 0;
   sy1 = 0;
   inds = 0;
   Y1 = 0;
   Y2 = 0;
   len = size(Y, dim);
   if len < 2
      tmpda1 = size(Y);
      z = zeros(tmpda1);
   else
      ndim = length(size(Y));
      D = diff(X);
      a = 0;
      b = sum(D);
      N = len;
      D = reshape(D, [ones(1, dim - 1) len - 1 ones(1, ndim - dim)]);
      sy1 = size(Y);
      sy1(dim) = 1;
      D = repmat(D, sy1);
      inds = repmat({':'}, [length(size(Y)) 1]);
      inds{dim} = 1 : len-1;
      Y1 = Y(inds{:});
      inds{dim} = 2 : len;
      Y2 = Y(inds{:});
      tmpca5 = Y2 .* D;
      tmpca4 = cumsum(tmpca5, dim);
      tmpca3 = Y1 .* D;
      tmpca2 = cumsum(tmpca3, dim);
      tmpca1 = tmpca2 + tmpca4;
      z = 0.5 * tmpca1;
      tmpda1 = zeros(sy1);
      z = cat(dim, tmpda1, z);
   end
end
% $Id: adimat_cumtrapz.m 4860 2015-02-07 13:49:39Z willkomm $
