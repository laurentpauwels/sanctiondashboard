function SHOT = upstreamBan(Z,F,emb_i,emb_j,emb_r)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Country/ies j imposes sanctions on country/ies i, sector(s) r.
% upstreamBan extract the (SHOT) upstream impact of sanctions (global 
% value chains), i.e. the impact on country/ies j of these sanctions
% Inputs:
%       Z     Double      intermediate input-output matrix (NRxNR) 
%       F     Double      Final demand (NRxN) matrix
%       emb_i Double      sanctioned country/ies
%       emb_r Double      sanctioned industry/ies
%       emb_j Double      country/ies sanctioning embi
% Output:
%       SHOT  Double      upstream sanctions' impact
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

NR = size(F,1);
N = size(F,2);
R = NR/N;

% Gross Output (PY) and Gross Value Added (PVA), both (NRx1)
Y = max(squeeze(sum(Z,2,'omitnan')) + squeeze(sum(F,2,'omitnan')),0);
VA = squeeze(sum(Z,2,'omitnan')) + squeeze(sum(F,2,'omitnan'))...
    - transpose(squeeze(sum(Z,1,'omitnan')));
VA(VA<0)=0;

% Allocation
B = Z ./ Y;
B(isinf(B)) = 0;
B(isnan(B)) = 0;

% Sanctions: Intermediate inputs
Bemb = reshape(B,R,N,R,N);
Bemb(emb_r,emb_i,:,emb_j) = 0;
Bemb = reshape(Bemb,R*N,R*N);

% SHOT
I = eye(R*N);
YB = (I-transpose(B))\VA;
SHOT_ijr = 1-(((I-transpose(Bemb))\VA)./YB);
SHOT_nr = reshape(SHOT_ijr,R,N);
SHOT = SHOT_nr(:,emb_j);
end
