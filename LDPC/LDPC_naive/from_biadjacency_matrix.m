function g = from_biadjacency_matrix(H, channel_model)
    g = TannerGraph();
    [m,n] = size(H);
    for i=1:n
        g.add_v_node(channel_model, i,  "v" + string(i));
    end
    
    for j=1:m
        g.add_c_node(j, "c" + string(j));
        for i=1:n
            if H(j,i) == 1
                g.add_edges_by_name("v" + string(i),"c" + string(j));
            end
        end
    end

end

