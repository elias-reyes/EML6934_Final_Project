function C = orbitTransferFun(z)

%-----------------------------------------------------------------%
% Objective and constraint functions for the orbit-raising        %
% problem.  This function is designed to be used with the NLP     %
% solver SNOPT.                                                   %
%-----------------------------------------------------------------%
%      DO NOT FOR ANY REASON ALTER THE LINE OF CODE BELOW!        %
global psStuff nstates ncontrols npaths CONSTANTS path_constraint maximize_mass%
%      DO NOT FOR ANY REASON ALTER THE LINE OF CODE ABOVE!        %
%-----------------------------------------------------------------%

%-----------------------------------------------------------------%
%         Extract the constants used in the problem.              %
%-----------------------------------------------------------------%
mu = CONSTANTS.MU;
ve = CONSTANTS.ve;
%-----------------------------------------------------------------%
% Radau pseudospectral method quantities required:                %
%   - Differentiation matrix (psStuff.D)                          %
%   - Legendre-Gauss-Radau weights (psStuff.w)                    %
%   - Legendre-Gauss-Radau points (psStuff.tau)                   %
%-----------------------------------------------------------------%
D = psStuff.D; tau = psStuff.tau; w = psStuff.w;

%-----------------------------------------------------------------%
% Decompose the NLP decision vector into pieces containing        %
%    - the state                                                  %
%    - the control                                                %
%    - the initial time                                           %
%    - the final time                                             %
%-----------------------------------------------------------------%
N              = length(tau)-1;
stateIndices   = 1:nstates*(N+1);
controlIndices = (nstates*(N+1)+1):(nstates*(N+1)+ncontrols*N);
t0Index        = controlIndices(end)+1;
tfIndex        = t0Index+1;
stateVector    = z(stateIndices);
controlVector  = z(controlIndices);
t0             = z(t0Index);
tf             = z(tfIndex);

%-----------------------------------------------------------------%
% Reshape the state and control parts of the NLP decision vector  %
% to matrices of sizes (N+1) by nstates and (N+1) by ncontrols,   %
% respectively.  The state is approximated at the N LGR points    %
% plus the final point.  Thus, each column of the state vector is %
% length N+1.  The LEFT-HAND SIDE of the defect constraints, D*X, %
% uses the state at all of the points (N LGR points plus final    %
% point).  The RIGHT-HAND SIDE of the defect constraints,         %
% (tf-t0)F/2, uses the state and control at only the LGR points.  %
% Thus, it is necessary to extract the state approximations at    %
% only the N LGR points.  Finally, in the Radau pseudospectral    %
% method, the control is approximated at only the N LGR points.   %
%-----------------------------------------------------------------%
statePlusEnd = reshape(stateVector,N+1,nstates);
stateLGR     = statePlusEnd(1:end-1,:);
control      = reshape(controlVector,N,ncontrols);

%-----------------------------------------------------------------%
% Identify the components of the state column-wise from stateLGR. % 
%-----------------------------------------------------------------%
r      = stateLGR(:,1);
theta  = stateLGR(:,2);
vr     = stateLGR(:,3);
vtheta = stateLGR(:,4);
m      = stateLGR(:,5);
if path_constraint
    u1 = control(:,1);
    u2 = control(:,2);
    u3 = control(:,3);
else
    u1 = control(:,1);
    u2 = 0;
    u3 = control(:,2);
end

%-----------------------------------------------------------------%
% Compute the right-hand side of the differential equations at    %
% the N LGR points.  Each component of the right-hand side is     %
% stored as a column vector of length N, that is each column has  %
% the form                                                        %
%                   [ f_i(x_1,u_1,t_1) ]                          %
%                   [ f_i(x_2,u_2,t_2) ]                          %
%                           .                                     %
%                           .                                     %
%                           .                                     %
%                   [ f_i(x_N,u_N,t_N) ]                          %
% where "i" is the right-hand side of the ith component of the    %
% vector field f.  It is noted that in MATLABB the calculation of %
% the right-hand side is vectorized.                              %
%-----------------------------------------------------------------%
rdot       = vr;
thetadot   = vtheta./r;
mdot       = -u3/ve;

a = u3./m;
if path_constraint
%     vrdot      = vtheta.^2./r - mu./r.^2 + u3.*u1./m;
%     vthetadot  = -vtheta.*vr./r + u3.*u2./m;
    vrdot      = vtheta.^2./r - mu./r.^2 + a.*u1;
    vthetadot  = -vtheta.*vr./r + a.*u2;
else
    vrdot      = vtheta.^2./r - mu./r.^2 + u3.*sin(u1)./m;
    vthetadot  = -vtheta.*vr./r + u3.*cos(u1)./m;
end

diffeqRHS = [rdot, thetadot, vrdot, vthetadot, mdot];

%-----------------------------------------------------------------%
% Compute the left-hand side of the defect constraints, recalling %
% that the left-hand side is computed using the state at the LGR  %
% points PLUS the final point.                                    %
%-----------------------------------------------------------------%
diffeqLHS = D*statePlusEnd;

%-----------------------------------------------------------------%
% Construct the defect constraints at the N LGR points.           %
% Remember that the right-hand side needs to be scaled by the     %
% factor (tf-t0)/2 because the rate of change of the state is     %
% being taken with respect to $\tau\in[-1,+1]$.  Thus, we have    %
% $dt/t\dau=(tf-t0)/2$.                                           %
%-----------------------------------------------------------------%
defects = diffeqLHS-(tf-t0)*diffeqRHS/2;

%-----------------------------------------------------------------%
% Construct the path constraints at the N LGR points.             %
% Reshape the path contraints into a column vector.               % 
%-----------------------------------------------------------------%
if path_constraint 
    paths = u1.^2 + u2.^2;
    paths = reshape(paths,N*npaths,1);
else
    paths = [];
end
% paths = u1.^2+u2.^2;



%-----------------------------------------------------------------%
% Reshape the defect contraints into a column vector.             % 
%-----------------------------------------------------------------%
defects = reshape(defects,N*nstates,1);


%-----------------------------------------------------------------%
% Construct the objective function plus constraint vector.        %
%-----------------------------------------------------------------%
if maximize_mass
    m = statePlusEnd(:,5);
    J = -m(end);
else
    J = tf;
end
C = [J;defects;paths];


