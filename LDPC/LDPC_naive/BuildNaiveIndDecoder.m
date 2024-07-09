function BP = BuildNaiveIndDecoder(H_sys_ind, p, q, NaiveDecoderParams)
    Channel_model = bac_llr(p,q);
    % Channel_model = bac_llr(1e-4,0.5e-4);
    tg = from_biadjacency_matrix(H_sys_ind, Channel_model);
    BP = BeliefPropagation(tg, H_sys_ind, NaiveDecoderParams);
end

