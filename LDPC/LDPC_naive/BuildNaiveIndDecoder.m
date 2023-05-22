function BP = BuildNaiveIndDecoder(H_sys_ind, p, q, NaiveDecoderParams)
    Channel_model = bac_llr(p,q);
    tg = from_biadjacency_matrix(H_sys_ind, Channel_model);
    BP = BeliefPropagation(tg, H_sys_ind, NaiveDecoderParams);
end

