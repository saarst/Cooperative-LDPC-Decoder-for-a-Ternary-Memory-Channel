classdef BeliefPropagation < handle
    %BELIEFPROPAGATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        H
        graph
        n
        maxIter
    end
    
    methods
        function obj = BeliefPropagation(TannerGraph, H, maxIter)
            %BELIEFPROPAGATION Construct an instance of this class
            %   Detailed explanation goes here
            obj.H = H;
            obj.graph = TannerGraph;
            obj.n =  numEntries(TannerGraph.v_nodes);
            obj.maxIter = maxIter;

            cnodes = obj.graph.c_nodes.values;
            for idx=1:length(cnodes)
                cnodes(idx).initialize();
            end

        end
        
        function [estimate, llr, suc, iter] = decode(obj, channel_word)
            % Initializations & check for 0 errors
            iter = 0;
            llr = [];
            estimate = channel_word;
            syndrome = mod(obj.H * estimate',2);
            suc = ~any(syndrome);
            if suc
                    return
            end
            % continue Initializations
            llr = zeros(1,obj.n);
            assert(length(channel_word) == obj.n, "Incorrect block size");
            vnodes = obj.graph.v_nodes.values;
            cnodes = obj.graph.c_nodes.values;

            for idx=1:obj.n
                vnodes(idx).initialize(channel_word(idx));
            end

            % Algorithm:
            for iter=1:obj.maxIter
                
                % Cnodes receive messages:
                for i=1:length(cnodes)
                    cnodes(i).receive_messages();
                end

                % Vnodes receive messages:
                for i=1:length(vnodes)
                    vnodes(i).receive_messages();
                end

                % Estimate:
                for i=1:length(vnodes)
                    llr(i) = vnodes(i).estimate();
                end
                estimate = llr < 0;
                syndrome = mod(obj.H * estimate',2);
                suc = ~any(syndrome);
                if suc
                    break
                end

            end

        end
    end
end

