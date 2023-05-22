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
        end
        
        function [estimate, llr, suc] = decode(obj, channel_word)
            % Initializations:
            estimate = [];
            llr = zeros(1,obj.n);
            assert(length(channel_word) == obj.n, "Incorrect block size");
            vnodes = obj.graph.v_nodes.values;
            cnodes = obj.graph.c_nodes.values;

            for idx=1:obj.n
                vnodes(idx).initialize(channel_word(idx));
            end

            for idx=1:length(cnodes)
                cnodes(idx).initialize();
                cnodes(idx).receive_messages();
            end


            % Algorithm:
            for j=1:obj.maxIter
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
               
                % Vnodes receive messages:
                for i=1:length(vnodes)
                    vnodes(i).receive_messages();
                end
                
                % Cnodes receive messages:
                for i=1:length(cnodes)
                    cnodes(i).receive_messages();
                end

            end

        end
    end
end

