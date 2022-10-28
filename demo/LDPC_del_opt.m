function [suc, result] = LDPC_del_opt (H, vec)
    arguments
        H (:,:) 
        vec (:,1) 
    end
    result = vec;
    suc = false;

    variables = 1:numel(vec); variables = variables(isnan(vec));
    nVariables = numel(variables);
    dict = dictionary(variables,1:nVariables);
    constraintsVec = zeros(nVariables,1);
    constraintsMat = [];

        for i=1:size(H,1)
            indices = find(H(i,:));
            isConstraint = sum(isnan(vec(indices)));
            if (isConstraint >= 1)
                constraintsVec(i) = mod(sum(vec(indices),'omitnan'),2);
                constraintsArray = zeros(1,nVariables); 
                constraintsArray(dict(indices)) = 1;
                constraintsMat = [constraintsMat; constraintsArray];
            end
        end

        [sol,vld] = gflineq(constraintsMat, constraintsVec);
        if ~vld
            return
        end
        vec(variables) = sol;
        if H * vec == zeros(size(vec))
            suc = true;
        end
end
