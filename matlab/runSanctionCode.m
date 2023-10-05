%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               IMPACT OF TRADE SANCTION  DASHBOARD                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% See "Instructions" in Readme.rmd file

%% Add folders to path
io_funfolder = fullfile('.', 'functions');
io_dtafolder = fullfile('.', 'data',filesep);

addpath(io_funfolder);
addpath(io_dtafolder);

%% DATA LOADING & PROCESSING

% Load ICIO21 data
load('./data/icio21_data.mat')
% ICIO21 Data
% Source: OECD-ICIO 2021 release data is downloaded at http://oe.cd/icio

% load parameter alpha (pre-calculated & required for approxResponse.m)
load('./data/alpha.mat')
% alpha Data 
% alpha = Labor Compensation / Value Addded (in national currency).
% This is constructed from WIOD Socio-Economic Accounts (2016 release)
% Source: https://www.rug.nl/ggdc/valuechain/wiod/wiod-2016-release
% See runConcordanceAlpha.m code to compute alpha and concordance between
% ICIO21 and WIOD SEA16.


%%%CHOOSE psi:
% Choose value for PSI (required for approxResponse.m):
psi = 2;

% IO Dataset Parameters:
nind = length(industries); % # of industries
ncty = length(countries); % # of countries
nyrs = length(years); % # of years
ncat  = length(finalcat); % # final demand categories

%Z matrix with Z_ij^rs as a typical element.
PM = Z;
%F matrix with F_ij^dr as a typical element (d = # final categories per ctry).
PF = F;
%F matrix with F_ij^r (summing all final demand categories)
PF_nrxn = zeros(nind*ncty,ncty,nyrs);
for j=1:ncty
    PF_nrxn(:,j,:) = sum(PF(:,(j-1)*ncat+1:j*ncat,:),2);
end

%%% Weights for aggregating Approximate Response,
% Weight of each sector within its own country (sums to 1)

% Computing PVA (correct. net invent) in current USD.
PVA = squeeze(sum(PM,2,'omitnan')) + squeeze(sum(PF,2,'omitnan')) - squeeze(sum(PM,1,'omitnan'));
PVA(PVA<0)=0;
va_ir = reshape(PVA, nind, ncty,nyrs);
wva_cty = va_ir./permute(repmat(squeeze(sum(va_ir,1,'omitnan'))',1,1,nind),[3 2 1]);
wva_cty(isnan(wva_cty)) = 0;


%% COUNTRIES - SECTORS - SACTIONS

% EU27 with GBR (UK)
eurwuk_iso3 = {'AUT', 'BEL', 'BGR', 'HRV', 'CYP', 'CZE', 'DNK', 'EST', ...
              'FIN', 'FRA', 'DEU', 'GRC', 'HUN', 'IRL', 'ITA', 'LVA', ...
              'LTU', 'LUX', 'MLT', 'NLD', 'POL', 'PRT', 'ROU', 'SVK', ...
              'SVN', 'ESP', 'SWE', 'GBR'}';

% Country sanctionned: Russia & Country sanctionning: EU
rus = find(matches(countrycode,{'RUS'}));
eur = find(matches(countrycode,eurwuk_iso3));

% Focus sectors to ban
energy = find(contains(industrycode,{'D05T06'}));
petrol = find(contains(industrycode,{'D19'}));
allsec = (1:nind);
% ban variables 
ban_inyrs = find(years==2018); %year of sanction
ban_oncty = rus; % Country sanctioned
ban_bycty = eur; % Country imposing sanctions
ban_onind = energy;% Industry/ies sanctioned

%% Sanctions on Russia: Value Chain Measures (HOT & SHOT)
% Russian Energy and Petroleum sanctioned
% Downstream Value Chain Impact for sanctioned country
hot_downstream = downstreamBan(PM(:,:,ban_inyrs),PF_nrxn(:,:,ban_inyrs),...
    ban_oncty,ban_bycty,ban_onind);
% Upstream Value Chain Impact for sanctioning countries
shot_upstream = upstreamBan(PM(:,:,ban_inyrs),PF_nrxn(:,:,ban_inyrs),...
    ban_oncty,ban_bycty,ban_onind);

%% Sanctions on Russia: Approximate Responses on Russia (HOT) and Europe (SHOT)

%%% Approximate effects of Energy and Petroleum sanctions on Russia (HOT)

% Downstream (HOT) response: Russian sectors and Russia total impact (in %)
response_downstream_bysector = approxResponse(alpha_r,psi,hot_downstream)*100;
response_downstream_total = squeeze(sum(wva_cty(:,rus,ban_inyrs).*(response_downstream_bysector),1,'omitnan'));

%%% Approximate effects of sanctions on EU (SHOT)

% Upstream (SHOT) response: EU countries & sectors and EU countries total (in %)
response_upstream_bysector = approxResponse(alpha_r,psi,shot_upstream)*100;
response_upstream_total = squeeze(sum(wva_cty(:,eur,ban_inyrs)...
    .*response_upstream_bysector,1,'omitnan'));


%% OUTPUT: Table with downstream impact and Table with upstream impact

table_downstream = [table(industries,response_downstream_bysector,...
    'VariableNames',["Industries", countrycode(ban_oncty)]);...
    {'Total Impact',response_downstream_total}];


table_upstream = [industries, array2table(response_upstream_bysector)];
namesofvars = ["industries", countrycode(ban_bycty)'];
table_upstream.Properties.VariableNames = namesofvars;
table_total = [{'Total Impact'},array2table(response_upstream_total)];
table_total.Properties.VariableNames = namesofvars;
table_upstream = [table_upstream; table_total];
clearvars table_total

writetable(table_downstream,'./output/table_downstream.csv');
writetable(table_upstream,'./output/table_upstream.csv');
