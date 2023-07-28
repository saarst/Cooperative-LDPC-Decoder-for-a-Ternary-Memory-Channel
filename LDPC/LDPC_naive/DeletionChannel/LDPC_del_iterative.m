function [suc, vec, iters] = LDPC_del_iterative (H, vec)
    arguments
        H (:,:) 
        vec (1,:) 
    end
    iters = 0;
    if all(mod(H * vec',2) == zeros([size(H,1),1]))
        suc = true;
        return
    end

    suc = false;
    openCBs = 1:size(H,1);

    flag = 1;
    while(flag)
        flag = 0;
        iters = iters + 1;
        for i=1:numel(openCBs)
            currCB = openCBs(i);
            indices = find(H(currCB,:));
            solvable = sum(isnan(vec(indices)));
            if (solvable == 0)
                parity = mod(sum(vec(indices)), 2);
                if parity 
                    return
                else
                    openCBs(openCBs == currCB) = 0;
                end
            elseif (solvable == 1)
                flag = 1;
                vec(indices(isnan(vec(indices)))) = mod(sum(vec(indices),'omitnan'),2);
                openCBs(openCBs == currCB) = 0;
            else % solvable >1
                continue
            end
        end

        openCBs = openCBs(openCBs ~= 0);
        if isempty(openCBs)
            suc = true;
            assert(all(mod(H * vec',2) == zeros([size(H,1),1])));
            return
        end

    end
  
end
