function BP = BuildBSCDecoder(PCM, p, DecoderParams)
    Channel_model = bsc_llr(p);
    tg = from_biadjacency_matrix(PCM, Channel_model);
    BP = BeliefPropagation(tg, PCM, DecoderParams);
end

