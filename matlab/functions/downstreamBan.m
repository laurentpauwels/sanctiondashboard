function HOT = downstreamBan(Z,F,emb_i,emb_j,emb_r)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Country/ies j imposes sanctions on country/ies i, sector(s) r.
% downstreamBan extract the (HOT) downstream impact of sanctions (global 
% value chains), i.e. the impact on country/ies,sector(s) (i,r) of the sanctions
% Inputs:
%       Z     Double      intermediate input-output matrix (NRxNR) 
%       F     Double      Final demand (NRxN) matrix
%       emb_i Double      sanctioned country/ies
%       emb_r Double      sanctioned industry/ies
%       emb_j Double      country/ies sanctioning embi
% Output:
%       HOT  Double       downstream sanctions' impact (embr x embi)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

NR = size(F,1);
N = size(F,2);
R = NR/N;

% Gross Output (PY)
Y = max(squeeze(sum(Z,2,'omitnan')) + squeeze(sum(F,2,'omitnan')),0);

% Direct requirement
A = Z ./ transpose(Y);
A(isinf(A)) = 0;
A(isnan(A)) = 0;

% Sanctions: Intermediate inputs
A_emb = reshape(A,R,N,R,N);
A_emb(emb_r,emb_i,:,emb_j) = 0;
A_emb = reshape(A_emb,R*N,R*N);

% Sanctions: Final demand
F_ijr = reshape(F,R,N,N);
F_ijr0 = F_ijr;
F_ijr0(emb_r,emb_i,emb_j) = 0;
F_emb = squeeze(sum(reshape(F_ijr0,R*N,N),2,'omitnan'));

% HOT
I = eye(R*N);
YA = (I-A)\sum(F,2,'omitnan'); 
HOT_ijr = 1-(((I-A_emb)\F_emb)./YA);
HOT_nr = reshape(HOT_ijr,R,N);
HOT = HOT_nr(:,emb_i);
end
