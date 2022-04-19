% This code was generated using ADiGator version 1.4
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

function obj = orbitTransferObj_ADiGatorJac(z)
global ADiGator_orbitTransferObj_ADiGatorJac
if isempty(ADiGator_orbitTransferObj_ADiGatorJac); ADiGator_LoadData(); end
Gator1Data = ADiGator_orbitTransferObj_ADiGatorJac.orbitTransferObj_ADiGatorJac.Gator1Data;
% ADiGator Start Derivative Computations
%User Line: % Computes the objective function of the problem
global psStuff nstates ncontrols maximize_mass 
%User Line: global
%User Line: %-----------------------------------------------------------------%
%User Line: %         Extract the constants used in the problem.              %
%User Line: %-----------------------------------------------------------------%
%User Line: % MU = CONSTANTS.MU; mdot = CONSTANTS.mdot; T = CONSTANTS.T;
%User Line: %-----------------------------------------------------------------%
%User Line: % Radau pseudospectral method quantities required:                %
%User Line: %   - Differentiation matrix (psStuff.D)                          %
%User Line: %   - Legendre-Gauss-Radau weights (psStuff.w)                    %
%User Line: %   - Legendre-Gauss-Radau points (psStuff.tau)                   %
%User Line: %-----------------------------------------------------------------%
D = psStuff.D;
%User Line: D = psStuff.D;
tau = psStuff.tau;
%User Line: tau = psStuff.tau;
w = psStuff.w;
%User Line: w = psStuff.w;
%User Line: %-----------------------------------------------------------------%
%User Line: % Decompose the NLP decision vector into pieces containing        %
%User Line: %    - the state                                                  %
%User Line: %    - the control                                                %
%User Line: %    - the initial time                                           %
%User Line: %    - the final time                                             %
%User Line: %-----------------------------------------------------------------%
cada1f1 = length(tau);
N.f = cada1f1 - 1;
%User Line: N = length(tau)-1;
cada1f1 = N.f + 1;
cada1f2 = nstates*cada1f1;
stateIndices.f = 1:cada1f2;
%User Line: stateIndices   = 1:nstates*(N+1);
cada1f1 = N.f + 1;
cada1f2 = nstates*cada1f1;
cada1f3 = cada1f2 + 1;
cada1f4 = N.f + 1;
cada1f5 = nstates*cada1f4;
cada1f6 = ncontrols*N.f;
cada1f7 = cada1f5 + cada1f6;
controlIndices.f = cada1f3:cada1f7;
%User Line: controlIndices = (nstates*(N+1)+1):(nstates*(N+1)+ncontrols*N);
cada1f1 = length(controlIndices.f);
cada1f2 = controlIndices.f(cada1f1);
t0Index.f = cada1f2 + 1;
%User Line: t0Index     = controlIndices(end)+1;
tfIndex.f = t0Index.f + 1;
%User Line: tfIndex     = t0Index+1;
stateVector.dz0 = z.dz0(Gator1Data.Index1);
stateVector.f = z.f(stateIndices.f);
%User Line: stateVector = z(stateIndices);
%User Line: % controlVector = z(controlIndices);
%User Line: % t0 = z(t0Index);
tf.dz0 = z.dz0(1031);
tf.f = z.f(tfIndex.f);
%User Line: tf = z(tfIndex);
%User Line: %-----------------------------------------------------------------%
%User Line: % Reshape the state and control parts of the NLP decision vector  %
%User Line: % to matrices of sizes (N+1) by nstates and (N+1) by ncontrols,   %
%User Line: % respectively.  The state is approximated at the N LGR points    %
%User Line: % plus the final point.  Thus, each column of the state vector is %
%User Line: % length N+1.  The LEFT-HAND SIDE of the defect constraints, D*X, %
%User Line: % uses the state at all of the points (N LGR points plus final    %
%User Line: % point).  The RIGHT-HAND SIDE of the defect constraints,         %
%User Line: % (tf-t0)F/2, uses the state and control at only the LGR points.  %
%User Line: % Thus, it is necessary to extract the state approximations at    %
%User Line: % only the N LGR points.  Finally, in the Radau pseudospectral    %
%User Line: % method, the control is approximated at only the N LGR points.   %
%User Line: %-----------------------------------------------------------------%
cada1f1 = N.f + 1;
statePlusEnd.dz0 = stateVector.dz0;
statePlusEnd.f = reshape(stateVector.f,cada1f1,nstates);
%User Line: statePlusEnd = reshape(stateVector,N+1,nstates);
cada1f1 = size(statePlusEnd.f,1);
cada1f2 = cada1f1 - 1;
cada1f3 = 1:cada1f2;
stateLGR.dz0 = statePlusEnd.dz0(Gator1Data.Index2);
stateLGR.f = statePlusEnd.f(cada1f3,:);
%User Line: stateLGR     = statePlusEnd(1:end-1,:);
%User Line: % control = reshape(controlVector,N,ncontrols);
%User Line: %-----------------------------------------------------------------%
%User Line: % Identify the components of the state column-wise from stateLGR. %
%User Line: %-----------------------------------------------------------------%
%User Line: % r      = stateLGR(:,1);
%User Line: % theta  = stateLGR(:,1);
%User Line: % vr     = stateLGR(:,3);
%User Line: % vtheta = stateLGR(:,4);
%User Line: % Cost Function
%User Line: % minizing time or maximizing mass
cadaconditional1 = maximize_mass;
%User Line: cadaconditional1 = maximize_mass;
    m.dz0 = statePlusEnd.dz0(Gator1Data.Index3);
    m.f = statePlusEnd.f(:,5);
    %User Line: m = statePlusEnd(:,5);
    cada1f1 = length(m.f);
    cada1f2dz0 = m.dz0(129);
    cada1f2 = m.f(cada1f1);
    J.dz0 = -cada1f2dz0;
    J.f = uminus(cada1f2);
    %User Line: J = -m(end);
    %User Line: J = tf;
obj.dz0 = J.dz0; obj.f = J.f;
%User Line: obj = J;
obj.dz0_size = 1031;
obj.dz0_location = Gator1Data.Index4;
end


function ADiGator_LoadData()
global ADiGator_orbitTransferObj_ADiGatorJac
ADiGator_orbitTransferObj_ADiGatorJac = load('orbitTransferObj_ADiGatorJac.mat');
return
end