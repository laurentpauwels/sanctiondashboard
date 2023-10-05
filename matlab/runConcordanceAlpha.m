%% DESCRIPTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% concordanceAlpha is the script that produces alpha_r set of parameters 
% (labour share) required for approximating the effects of sanctions
% on the Dashboard and as in the Imbs and Pauwels (2023, Economic Policy). 
% It runs the concordance between SEA6 and ICIO21.
% It requires to load WIOD Socio-Economic Accounts 2016 release.
% Refer to the Readme.md file for more details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Concordance between SEA16 and ICIO21, output = alpha_r

% load SEA16 data
load('./data/sea16_data.mat')

% Inserting NaN instead of absolute 0 or negative values:
VA(VA<0) = 0;
VA(sum(VA,2,'omitnan')==0) = NaN;
COMP(COMP<0) = NaN;
COMP(sum(COMP,2,'omitnan')==0) = NaN;

N = length(countrycode);
R = length(industrycode);

% Averaging over time and reshaping RxN
pvabar = reshape(squeeze(mean(VA,2, 'omitnan')),R,N); %PVA in millions of Nat Cur.
compbar = reshape(squeeze(mean(COMP,2, 'omitnan')),R,N);%COMP = Compensation of employees in millions of Nat Cur.

% Share of Labor:
alpha_1t2 = mean(compbar(1:2,:),1,'omitnan')./mean(pvabar(1:2,:),1,'omitnan');
alpha_3 = compbar(3,:)./pvabar(3,:);
alpha_4 = repmat(compbar(4,:),3,1)./repmat(pvabar(4,:),3,1);%3 times
alpha_5t7 = compbar(5:7,:)./pvabar(5:7,:);
alpha_8t9 = mean(compbar(8:9,:),1,'omitnan')./mean(pvabar(8:9,:),1,'omitnan');
alpha_10t21 = compbar(10:21,:)./pvabar(10:21,:);
alpha_22t23 = mean(compbar(22:23,:),1,'omitnan')./mean(pvabar(22:23,:),1,'omitnan');
alpha_24 = compbar(24,:)./pvabar(24,:);
alpha_25t26 = mean(compbar(25:26,:),1,'omitnan')./mean(pvabar(25:26,:),1,'omitnan');
alpha_27 = compbar(27,:)./pvabar(27,:);
alpha_28t30 = mean(compbar(28:30,:),1,'omitnan')./mean(pvabar(28:30,:),1,'omitnan');
alpha_31t36 = compbar(31:36,:)./pvabar(31:36,:);
alpha_37t38 = mean(compbar(37:38,:),1,'omitnan')./mean(pvabar(37:38,:),1,'omitnan');
alpha_39t40 = compbar(39:40,:)./pvabar(39:40,:);
alpha_41t43 = mean(compbar(41:43,:),1,'omitnan')./mean(pvabar(41:43,:),1,'omitnan');
alpha_44 = compbar(44,:)./pvabar(44,:);
alpha_45t49 = mean(compbar(45:49,:),1,'omitnan')./mean(pvabar(45:49,:),1,'omitnan');
alpha_50t54 = compbar(50:54,:)./pvabar(50:54,:);
alpha_54 = compbar(54,:)./pvabar(54,:);
alpha_55t56 = mean(compbar(55:56,:),1,'omitnan')./mean(pvabar(55:56,:),1,'omitnan');

alpha = [alpha_1t2;alpha_3;alpha_4;alpha_5t7;alpha_8t9;alpha_10t21;alpha_22t23;...
    alpha_24;alpha_25t26;alpha_27;alpha_28t30;alpha_31t36;alpha_37t38;alpha_39t40;...
    alpha_41t43;alpha_44;alpha_45t49;alpha_50t54;alpha_54;alpha_55t56];

alpha(alpha>1) = NaN;
alpha(alpha<=0) = NaN;

% Averaging share of labor over country-sector:
alpha_r = mean(alpha,2,'omitnan');

save('./data/alpha', 'alpha_r')

clearvars
