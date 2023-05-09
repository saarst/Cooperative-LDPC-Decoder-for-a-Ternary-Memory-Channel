function [decCodewordRM_Barrier, probs ,success, numIter] = MsgPasDecoder(ChannelOut, H_sys_ind, H_sys_res, p, q, MsgPasDecoderParams)
    channel_model_ind = barrier_ind_llr(p,q);
    channel_model_res = barrier_res_llr_2(p,q);
    tg = from_2_biadjacency_matrices(H_sys_ind, H_sys_res, channel_model_ind, channel_model_res);
    bp = BeliefPropagation_Barrier(tg, H_sys_ind, H_sys_res, MsgPasDecoderParams);
    [decCodewordRM_Barrier, probs, success, numIter] = bp.decode(ChannelOut);
end

