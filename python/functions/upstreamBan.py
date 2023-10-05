###########################################################################
# Country/ies j imposes sanctions on country/ies i, sector(s) r.
# upstreamBan extract the (SHOT) upstream impact of sanctions (global 
# value chains), i.e. the impact on country/ies j of these sanctions
# Inputs:
#       Z           intermediate input-output matrix (NRxNR) 
#       F           Final demand (NRxN) matrix
#       emb_i       sanctioned country/ies
#       emb_r       sanctioned industry/ies
#       emb_j       country/ies sanctionning embi
# Output:
#       SHOT        upstream sanctions' impact
###########################################################################

        
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