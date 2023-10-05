function approx = approxResponse(alpha,psi,hotshot)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Country/ies j imposes sanctions on country/ies i, sector(s) r.
% approxResponse calculate the downstream/upstream impact of sanctions on 
% real value added, i.e. the impact on country/ies j of these sanctions
% Inputs:
%       alpha   Double      labour shares (Rx1) 
%       psi     Double      Frisch Labour elasticity (scalar)
%       hotshot Double      Downstream/Upstream (HOT/SHOT) measure (NRx1)
%
% Output:
%       approx  Double      real value added response to sanctions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Approximation constant
prox_cst = (psi/(1+psi))*alpha;
% Approximation
approx = prox_cst.*hotshot;
end


