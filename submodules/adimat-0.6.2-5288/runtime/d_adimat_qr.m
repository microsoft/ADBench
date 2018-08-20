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
% Flags: FORWARDMODE,  NOOPEROPTIM,
%   NOLOCALCSE,  NOGLOBALCSE,  NOPRESCALARFOLDING,
%   NOPOSTSCALARFOLDING,  NOCONSTFOLDMULT0,  FUNCMODE,
%   NOTMPCLEAR,  DUMP_XML,  PARSE_ONLY,
%   UNBOUND_ERROR
%
% Parameters:
%  - dependents=Q, R
%  - independents=A
%  - inputEncoding=ISO-8859-1
%  - output-mode: plain
%  - output-file: ad_out/d_adimat_qr.m
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
% Flags: FORWARDMODE,  NOOPEROPTIM,
%   NOLOCALCSE,  NOGLOBALCSE,  NOPRESCALARFOLDING,
%   NOPOSTSCALARFOLDING,  NOCONSTFOLDMULT0,  FUNCMODE,
%   NOTMPCLEAR,  DUMP_XML,  PARSE_ONLY,
%   UNBOUND_ERROR
%
% Parameters:
%  - dependents=Q, R
%  - independents=A
%  - inputEncoding=ISO-8859-1
%  - output-mode: plain
%  - output-file: ad_out/d_adimat_qr.m
%  - output-file-prefix: 
%  - output-directory: ad_out
%
% Functions in this file: d_adimat_qr, d_mk_householder_elim_vec_lapack
%

function [d_Q Q d_R R] = d_adimat_qr(d_A, A)
   [m n] = size(A);
   r = min(m, n);
   Q = eye(m);
   d_Q = d_zeros(Q);
   if m<=n && isreal(A)
      r = r - 1;
   end
   for k=1 : r
      [d_Pk Pk] = d_mk_householder_elim_vec_lapack(d_A(:, k : m, k), A(k : m, k), m);
      d_Q = adimat_opdiff_mult(d_Q, Q, d_Pk, Pk);
      Q = Q * Pk;
      d_A = adimat_opdiff_mult(adimat_opdiff_trans(d_Pk, Pk), Pk', d_A, A);
      A = Pk' * A;
   end
   [d_R R] = adimat_diff_triu(d_A, A);
end
% $Id: adimat_qr.m 3925 2013-10-14 12:09:14Z willkomm $

function [d_Pk Pk d_u u] = d_mk_householder_elim_vec_lapack(d_a, a, n)
   tolZ = eps;
   assert(iscolumn(a));
   d_tmpca2 = adimat_opdiff_emult_right(d_a(:, 1), a(1), 0);
   tmpca2 = a(1) .* 0;
   tmpda1 = eye(n);
   d_Pk = adimat_opdiff_sum(d_tmpca2, d_zeros(tmpda1));
   Pk = tmpda1 + tmpca2;
   k = length(a);
   d_na = adimat_diff_norm1(d_a, a);
   na = norm(a);
   if ~(k==1 && isreal(a)) && na~=0
      d_u = d_a;
      u = a;
      na_rest = norm(a(2 : end));
      if na>tolZ && na_rest~=0
         sa1 = sign(real(a(1)));
         if sa1 == 0
            sa1 = 1;
         end
         d_nu = adimat_opdiff_emult_left(sa1, d_na, na);
         nu = sa1 .* na;
         d_u(:, 1) = adimat_opdiff_sum(d_u(:, 1), d_nu);
         u(1) = u(1) + nu;
         d_tmpca1 = adimat_opdiff_sum(d_a(:, 1), d_nu);
         tmpca1 = a(1) + nu;
         d_u = adimat_opdiff_ediv(d_u, u, d_tmpca1, tmpca1);
         u = u ./ tmpca1;
         d_tmpca1 = adimat_opdiff_sum(d_a(:, 1), d_nu);
         tmpca1 = a(1) + nu;
         d_sigma = adimat_opdiff_ediv(d_tmpca1, tmpca1, d_nu, nu);
         sigma = tmpca1 ./ nu;
         d_tmpca3 = adimat_opdiff_emult(d_sigma, sigma, d_u, u);
         tmpca3 = sigma .* u;
         d_tmpca2 = adimat_opdiff_mult(d_tmpca3, tmpca3, adimat_opdiff_trans(d_u, u), u');
         tmpca2 = tmpca3 * u';
         tmpda1 = eye(k);
         d_Pksub = adimat_opdiff_sum(-d_tmpca2, d_zeros(tmpda1));
         Pksub = tmpda1 - tmpca2;
         tmpda2 = n - k + 1;
         tmpda1 = n - k + 1;
         d_Pk(:, tmpda1 : end, tmpda2 : end) = d_Pksub;
         Pk(tmpda1 : end, tmpda2 : end) = Pksub;
      end
   end
end
% $Id: mk_householder_elim_vec_lapack.m 4801 2014-10-08 12:28:59Z willkomm $
