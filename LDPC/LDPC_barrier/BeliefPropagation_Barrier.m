classdef BeliefPropagation_Barrier < handle
    %BELIEFPROPAGATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        H_res
        H_ind
        graph
        n
        maxIter
        sequenceInd
        sequenceRes
    end
    
    methods
        function obj = BeliefPropagation_Barrier(TannerGraph, H_ind, H_res, maxIter, sequenceInd, sequenceRes)
            obj.H_res = H_res;
            obj.H_ind = H_ind;
            obj.graph = TannerGraph;
            obj.n =  numEntries(TannerGraph.v_nodes);
            obj.maxIter = maxIter;
            obj.sequenceInd = sequenceInd;
            obj.sequenceRes = sequenceRes;
            
            %check in superPC !!!
            ind_nodes = obj.graph.ind_nodes.values;
            res_nodes = obj.graph.res_nodes.values;
            for idx=1:length(ind_nodes)
                ind_nodes(idx).initialize();
            end

            for idx=1:length(res_nodes)
                res_nodes(idx).initialize();
            end

        end
        
        function [estimate, prob, suc, iter] = decode(obj, channel_word)
            % Naive estimate
            iter = 0;
            prob = [];
            estimate = channel_word;
            estimated_res = estimate == 2;
            estimated_ind = estimate ~= 0;
            syndrome_ind = mod(obj.H_ind * estimated_ind',2);
            syndrome_res = mod(obj.H_res * estimated_res',2);
            suc = ~any([syndrome_ind; syndrome_res]);
            if suc 
                return
            end

            % Initializations
            prob = zeros(3,obj.n);
            assert(length(channel_word) == obj.n, "Incorrect block size");

            vnodes = obj.graph.v_nodes.values;
            ind_nodes = obj.graph.ind_nodes.values;
            res_nodes = obj.graph.res_nodes.values;

            for idx=1:obj.n
                vnodes(idx).initialize(channel_word(idx));
            end

            indCount = 0;
            resCount = 0;
            isLastSubsequenceInd = true;

            % Algorithm:
            for iter=1:obj.maxIter
                if indCount == 0 && resCount == 0
                    indCount = obj.sequenceInd;
                    resCount = obj.sequenceRes;
                end

                if indCount > 0
                    % indNodes receive messages:
                    for i=1:length(ind_nodes)
                        ind_nodes(i).receive_messages();
                    end
                    isLastSubsequenceInd = true;
                    indCount = indCount - 1;
                elseif resCount > 0
                    % resNodes receive messages:
                    for i=1:length(res_nodes)
                        res_nodes(i).receive_messages();
                    end
                    isLastSubsequenceInd = false;
                    resCount = resCount - 1;
                end

                % Vnodes receive messages:
                for i=1:length(vnodes)
                    prob(:,i) = vnodes(i).receive_and_estimate(isLastSubsequenceInd);
                end

                [~, estimated_trits] = max(prob);
                estimate = estimated_trits-1;
                estimated_res = estimate == 2;
                estimated_ind = estimate ~= 0;
                syndrome_ind = mod(obj.H_ind * estimated_ind',2);
                syndrome_res = mod(obj.H_res * estimated_res',2);
                suc = ~any([syndrome_ind; syndrome_res]);
                if suc 
                    break
                end

            end
        end
    end
end

