###########################################################################
# Country/ies j imposes sanctions on country/ies i, sector(s) r.
# downstreamBan extract the (HOT) downstream impact of sanctions (global 
# value chains), i.e. the impact on country/ies,sector(s) (i,r) of the sanctions
# Inputs:
#       Z           intermediate input-output matrix (NRxNR) 
#       F           Final demand (NRxN) matrix
#       emb_i       sanctioned country/ies
#       emb_r       sanctioned industry/ies
#       emb_j       country/ies sanctioning embi
# Output:
#       HOT         downstream sanctions' impact (embr x embi)
# Function equivalent to downstreamBan.m in MATLAB
###########################################################################

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
