function g = from_2_biadjacency_matrices(symbolsPrior, H_ind, H_res ,channel_model_ind, channel_model_res, lowComplex)
    g = DoubleTannerGraph();
    [m,n] = size(H_ind);
    [k,l] = size(H_res);
    assert(n==l,"dimensions of H_ind and H_res does not match");
    for i=1:n
        g.add_v_node(symbolsPrior, channel_model_ind, channel_model_res, i,  "v" + string(i), lowComplex);
    end
    
    for j=1:m
        g.add_ind_node(j, "ind" + string(j));
        for i=1:n
            if H_ind(j,i) == 1
                g.add_ind_edges_by_name("v" + string(i),"ind" + string(j));
            end
        end
    end

    for j=1:k
        g.add_res_node(j, "res" + string(j));
        for i=1:n
            if H_res(j,i) == 1
                g.add_res_edges_by_name("v" + string(i),"res" + string(j));
            end
        end
    end

end

