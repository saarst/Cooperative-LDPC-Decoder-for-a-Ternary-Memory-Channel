function BP = BuildBSCDecoder(H_sys, p, DecoderParams)
    Channel_model = bsc_llr(p);
    tg = from_biadjacency_matrix(H_sys, Channel_model);
    BP = BeliefPropagation(tg, H_sys, DecoderParams);
end

