% function [Jac,Fun] = orbitTransferFun_Jac(z)
% 
% Jacobian wrapper file generated by ADiGator
% ©2010-2014 Matthew J. Weinstein and Anil V. Rao
% ADiGator may be obtained at https://sourceforge.net/projects/adigator/ 
% Contact: mweinstein@ufl.edu
% Bugs/suggestions may be reported to the sourceforge forums
%                    DISCLAIMER
% ADiGator is a general-purpose software distributed under the GNU General
% Public License version 3.0. While the software is distributed with the
% hope that it will be useful, both the software and generated code are
% provided 'AS IS' with NO WARRANTIES OF ANY KIND and no merchantability
% or fitness for any purpose or application.

function [Jac,Fun] = orbitTransferFun_Jac(z)
gator_z.f = z;
gator_z.dz0 = ones(1031,1);
C = orbitTransferFun_ADiGatorJac(gator_z);
Jac = sparse(C.dz0_location(:,1),C.dz0_location(:,2),C.dz0,769,1031);
Fun = C.f;
end