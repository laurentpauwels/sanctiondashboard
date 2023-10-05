##### IMPACT OF TRADE SANCTION  DASHBOARD ##### 
# See "Instructions" in Readme.rmd file

# Relevant packages
import numpy as np
import pandas as pd
import os
import timeit
start = timeit.default_timer()

# Add folders to path
io_outfolder = "./output/"
io_dtafolder = "./data/"


# DATA LOADING & PROCESSING

# Load ICIO21 data
icio21_data = np.load(io_dtafolder + "icio21_data.npy", allow_pickle=True)[()]
# ICIO21 Data
# Source: OECD-ICIO 2021 release data is downloaded at http://oe.cd/icio

# load parameter alpha (pre-calculated & required for approxResponse.m)
alpha_r = np.load(io_dtafolder + "alpha.npy", allow_pickle=True)[()]
# alpha Data 
# alpha = Labor Compensation / Value Addded (in national currency).
# This is constructed from WIOD Socio-Economic Accounts (2016 release)
# Source: https://www.rug.nl/ggdc/valuechain/wiod/wiod-2016-release
# See runConcordanceAlpha.m code to compute alpha and concordance between
# ICIO21 and WIOD SEA16.

# Choose value for PSI (required for approxResponse.m)
psi = 2.0

# Assigning variables
# This code iterates over each element in the array 
# and retrieves the string value by accessing code[0][0]. 
# The extracted string values are stored in a new array.
countries = np.array([code[0][0] for code in icio21_data["countries"]])
countrycode = np.array([code[0][0] for code in icio21_data["countrycode"]])
industries = np.array([code[0][0] for code in icio21_data["industries"]])
industrycode = np.array([code[0][0] for code in icio21_data["industrycode"]])
finalcat = np.array([code[0][0] for code in icio21_data["finalcat"]])
years = icio21_data["years"]

# IO Dataset Parameters
nind = industries.shape[0]  # # of industries
nctry = countries.shape[0]  # # of countries
nyrs = years.shape[0]  # # of years
nfinals = finalcat.shape[0]  # # final demand categories


# Z matrix with Z_ij^rs as a typical element.
PM = icio21_data["Z"]
# F matrix with F_ij^dr as a typical element (d = # final categories per ctry).
PF = icio21_data["F"]
# F matrix with F_ij^r (summing all final demand categories)
PF_nrxn = np.zeros((nind * nctry, nctry, nyrs))
for j in range(nctry):
    PF_nrxn[:, j, :] = np.sum(PF[:, j * nfinals : (j + 1) * nfinals, :], axis=1)

# Weights for aggregating Approximate Response
# Weight of each sector within its own country (sums to 1)
# Computing PVA (correct. net invent) in current USD.
PVA = np.squeeze(np.sum(PM, axis=1, keepdims=True)) \
+ np.squeeze(np.sum(PF, axis=1, keepdims=True)) \
- np.squeeze(np.sum(PM, axis=0, keepdims=True))
PVA[PVA < 0] = 0

va_ir = np.reshape(PVA,(nind, nctry, nyrs), order="F")
sum_va_ir = np.nansum(va_ir, axis=0, keepdims=True)
sum_replicated = np.tile(sum_va_ir, (nind, 1, 1))
wva_ctry = va_ir / sum_replicated
wva_ctry[np.isnan(wva_ctry)] = 0


# COUNTRIES - SECTORS - ACTIONS

# EU27 with GBR (UK)
eurwuk_iso3 = ["AUT", "BEL", "BGR", "HRV", "CYP", "CZE", "DNK", "EST",
               "FIN", "FRA", "DEU", "GRC", "HUN", "IRL", "ITA", "LVA",
               "LTU", "LUX", "MLT", "NLD", "POL", "PRT", "ROU", "SVK",
               "SVN", "ESP", "SWE", "GBR"]

# Country sanctioned: Russia & Country sanctioning: EU
rus = np.where(countrycode == "RUS")[0][0]
eur = np.where(np.isin(countrycode, eurwuk_iso3))[0]

# Focus sectors to ban
energy = np.where(np.core.defchararray.find(industrycode, "D05T06") != -1)[0]
petrol = np.where(np.core.defchararray.find(industrycode, "D19") != -1)[0]

# ban variables
ban_inyrs = np.where(years == 2018)[0]  # year of sanction
ban_oncty = rus  # Country sanctioned
ban_bycty = eur  # Country imposing sanctions
#ban_onind = np.concatenate((energy, petrol))  # Industry/ies sanctioned
ban_onind = energy  # Industry/ies sanctioned

# Sanctions on Russia: Value Chain Measures (HOT & SHOT)
# Russian Energy and Petroleum sanctioned
# Downstream Value Chain Impact for sanctioned country

def downstreamBan(Z, F, emb_i, emb_j, emb_r):
    NR = F.shape[0]
    N = F.shape[1]
    R = NR // N

    # Gross Output (PY)
    Y = np.maximum(np.squeeze(np.sum(Z, axis=1, keepdims=True)) + np.squeeze(np.sum(F, axis=1, keepdims=True)), 0)

    # Direct requirement
    A = Z / np.tile(Y, (Z.shape[0], 1))
    A[np.isinf(A)] = 0
    A[np.isnan(A)] = 0

# Sanctions: Intermediate inputs
    #A_rshp = np.reshape(A, (R, N, R, N))
    A_emb  = A.copy()  # Create a copy to store the modified values
    for r in emb_r:
        for i in [emb_i]:  # Use emb_i as a single-element list
            for j in emb_j:
                A_emb[r+(i*R), (j*R):(j+1)*R] = 0

    # Sanctions: Final demand
    F_ijr0 = F.copy()
    for r in emb_r:
        for i in [emb_i]:
            for j in emb_j:
                F_ijr0[r+(i*R), j] = 0
    F_emb = np.sum(F_ijr0, axis=1)

    # HOT
    I = np.eye(R * N)
    YA = np.linalg.solve((I - A), np.sum(F, axis=1))
    HOT_ijr = 1 - (np.linalg.solve((I - A_emb), F_emb) / YA)
    HOT = HOT_ijr[emb_i*R:(emb_i+1)*R]

    return HOT

hot_downstream = downstreamBan(np.squeeze(PM[:, :, ban_inyrs]), 
                               np.squeeze(PF_nrxn[:, :, ban_inyrs]), 
                               ban_oncty, ban_bycty, ban_onind)

# Upstream Value Chain Impact for sanctioning countries
def upstreamBan(Z, F, emb_i, emb_j, emb_r):
    NR = F.shape[0]
    N = F.shape[1]
    R = NR // N
    
    # Gross Output (PY) and Gross Value Added (PVA), both (NRx1)
    Y = np.maximum(np.squeeze(np.sum(Z, axis=1, keepdims=True)) + np.squeeze(np.sum(F, axis=1, keepdims=True)), 0)
    VA = np.squeeze(np.sum(Z, axis=1, keepdims=True)) \
    + np.squeeze(np.sum(F, axis=1, keepdims=True)) \
    - np.squeeze(np.sum(Z, axis=0, keepdims=True))
    VA[VA < 0] = 0
    

    # Allocation
    # B will be a matrix of the same shape as Z, 
    # where each element in the i-th row of B is Z[i] 
    # divided by Y[i]
    B = Z / Y[:, np.newaxis]
    B[np.isinf(B)] = 0
    B[np.isnan(B)] = 0
    
    # Sanctions: Intermediate inputs
    Bemb  = B.copy()  # Create a copy to store the modified values
    for r in emb_r:
        for i in [emb_i]:  # Use emb_i as a single-element list
            for j in emb_j:
                Bemb[r+(i*R), (j*R):(j+1)*R] = 0

    
    # SHOT
    I = np.eye(R * N)
    YB = np.linalg.solve((I - np.transpose(B)), VA)
    SHOT_ijr = 1 - (np.linalg.solve((I - np.transpose(Bemb)), VA) / YB)
    SHOT = np.zeros((R, len(emb_j)))
    for jdx, j in enumerate(emb_j):  
        SHOT[:, jdx] = SHOT_ijr[j * R:(j + 1) * R]
    return SHOT

shot_upstream = upstreamBan(np.squeeze(PM[:, :, ban_inyrs]), 
                            np.squeeze(PF_nrxn[:, :, ban_inyrs]),
                            ban_oncty, ban_bycty, ban_onind)

# Sanctions on Russia: Approximate Responses on Russia (HOT) and Europe (SHOT)

def approxResponse(alpha, psi, hotshot):
    # Approximation constant
    prox_cst = (psi / (1 + psi)) * alpha
    
    # Approximation
    if hotshot.ndim == 1:  # hotshot has shape (45,)
        approx = prox_cst * hotshot
    elif hotshot.ndim == 2:  # hotshot has shape (45, 28)
        approx= prox_cst[:, np.newaxis] * hotshot
    
    return approx


# Approximate effects of Energy and Petroleum sanctions on Russia (HOT)
# Downstream (HOT) response: Russian sectors and Russia total impact (in %)
response_downstream_bysector = approxResponse(alpha_r, psi, hot_downstream) * 100
response_downstream_total = np.nansum(wva_ctry[:, rus, ban_inyrs] * response_downstream_bysector[:, np.newaxis], axis=0)


# Approximate effects of sanctions on EU (SHOT)
# Upstream (SHOT) response: EU countries & sectors and EU countries total (in %)
response_upstream_bysector = approxResponse(alpha_r, psi, shot_upstream) * 100
response_upstream_total = np.nansum(wva_ctry[:, eur, ban_inyrs] * response_upstream_bysector, axis=0)


## OUTPUT: Table with downstream impact and Table with upstream impact

table1 = np.column_stack((industries,response_downstream_bysector))
new_row1 = np.array(['Total Impact',str(response_downstream_total)])
table_downstream = np.vstack((table1, new_row1))
df_downstream = pd.DataFrame(table_downstream)
df_downstream.columns = ["Industries", "RUS"]
print(df_downstream)

table2 = np.column_stack((industries,response_upstream_bysector))
new_row2 = np.hstack(['Total Impact',response_upstream_total])
new_row2 = np.array([str(item) for item in new_row2])
table_upstream = np.vstack((table2, new_row2))
df_upstream = pd.DataFrame(table_upstream)
column_names = ["Industries"] + list(countrycode[ban_bycty])
df_upstream.columns = column_names
print(df_upstream)


# Save df_downstream to CSV file
df_downstream.to_csv(os.path.join("./output", "table_downstream.csv"), index=False)

# Save df_upstream to CSV file
df_upstream.to_csv(os.path.join("./output", "table_upstream.csv"), index=False)
stop = timeit.default_timer()

print('Time: ', stop - start)  