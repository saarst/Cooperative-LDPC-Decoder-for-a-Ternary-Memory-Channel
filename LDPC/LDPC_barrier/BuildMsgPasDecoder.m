function BP = BuildMsgPasDecoder(symbolsPrior, H_sys_ind, H_sys_res, p, q, maxIter, sequenceInd, sequenceRes,lowComplex)
    channel_model_ind = barrier_ind_llr(p, q, symbolsPrior);
    channel_model_res = barrier_res_llr(p, q, symbolsPrior);
    tg = from_2_biadjacency_matrices(symbolsPrior, H_sys_ind, H_sys_res, channel_model_ind, channel_model_res, lowComplex);
    BP = BeliefPropagation_Barrier(tg, H_sys_ind, H_sys_res, maxIter, sequenceInd, sequenceRes);
end

