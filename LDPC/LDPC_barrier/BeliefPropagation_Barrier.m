classdef BeliefPropagation_Barrier < handle
    %BELIEFPROPAGATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        H_res
        H_ind
        graph
        n
        maxIter
    end
    
    methods
        function obj = BeliefPropagation_Barrier(TannerGraph, H_ind, H_res, maxIter)
            %BELIEFPROPAGATION Construct an instance of this class
            %   Detailed explanation goes here
            obj.H_res = H_res;
            obj.H_ind = H_ind;
            obj.graph = TannerGraph;
            obj.n =  numEntries(TannerGraph.v_nodes);
            obj.maxIter = maxIter;
        end
        
        function [estimate, prob, suc, iter] = decode(obj, channel_word)
            estimate = [];
            prob = zeros(3,obj.n);
            assert(length(channel_word) == obj.n, "Incorrect block size");
            % initial step - step #1
            vnodes = obj.graph.v_nodes.values;
            ind_nodes = obj.graph.ind_nodes.values;
            res_nodes = obj.graph.res_nodes.values;

            for idx=1:obj.n
                vnodes(idx).initialize(channel_word(idx));
            end

            for idx=1:length(ind_nodes)
                ind_nodes(idx).initialize();
                ind_nodes(idx).receive_messages();
            end

            for idx=1:length(res_nodes)
                res_nodes(idx).initialize();
                res_nodes(idx).receive_messages();
            end



            for j=1:obj.maxIter
                % step 2
                for i=1:length(vnodes)
                    vnodes(i).receive_res_messages();
                    vnodes(i).receive_ind_messages();
                end
                
                % step 3
                for i=1:length(ind_nodes)
                    ind_nodes(i).receive_messages();
                end
                
                for i=1:length(res_nodes)
                    res_nodes(i).receive_messages();
                end

                % step 4
                for i=1:length(vnodes)
                    prob(:,i) = vnodes(i).estimate();
                end
                [~, estimated_trits] = max(prob);
                estimate = estimated_trits-1;
                estimated_res = estimate == 2;
                estimated_ind = estimate ~= 0;
                syndrome_ind = mod(obj.H_ind * estimated_ind',2);
                syndrome_res = mod(obj.H_res * estimated_res',2);
                suc = ~any([syndrome_ind, syndrome_res],'all');
                if suc && j >= 10
                    iter = j;
                    break
                end
            end
            if ~suc
                iter = obj.maxIter;
            end
        end
    end
end
