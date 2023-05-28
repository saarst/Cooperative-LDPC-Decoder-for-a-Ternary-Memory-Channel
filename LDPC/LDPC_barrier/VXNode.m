classdef VXNode < Node
    %VNODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        channel_model_res 
        channel_model_ind 
        channel_symbol = [];
        channel_llr_res = [];
        channel_llr_ind = [];
        res_received_messages
        ind_received_messages
        res_neighbors = dictionary
        ind_neighbors = dictionary
        msg_sum_ind = nan
        msg_sum_ind_aux
        msg_sum_res = nan
        msg_sum_res_aux
    end
    
    methods
        function obj = VXNode(channel_model_ind, channel_model_res, name, ordering_key)
            arguments
                channel_model_ind = barrier_ind_llr(0.5, 0.5)
                channel_model_res = barrier_res_llr(0.5, 0.5)
                name = ""
                ordering_key = []
            end
            obj@Node(name,ordering_key);
            obj.channel_model_ind = channel_model_ind;
            obj.channel_model_res = channel_model_res;
        end
        
        function initialize(obj, channel_symbol)
            %CNODE Construct an instance of this class
            %   Detailed explanation goes here
            obj.channel_symbol = channel_symbol;
            obj.channel_llr_ind = obj.channel_model_ind(channel_symbol);
            obj.channel_llr_res = obj.channel_model_res(channel_symbol);
            obj.msg_sum_ind = 0;
            obj.msg_sum_ind_aux = 0;
            obj.msg_sum_res = 0;
            obj.msg_sum_res_aux = 0;
            obj.ind_received_messages = dictionary(obj.ind_neighbors.keys,zeros(size(obj.ind_neighbors.keys)));
            obj.res_received_messages = dictionary(obj.res_neighbors.keys,zeros(size(obj.res_neighbors.keys)));
        end

        function register_ind_neighbor(obj, neighbor)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.ind_neighbors(neighbor.uid) = neighbor;
        end

        function register_res_neighbor(obj, neighbor)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.res_neighbors(neighbor.uid) = neighbor;
        end

        function receive_res_messages(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            node_ids = keys(obj.res_neighbors);
            nodes = values(obj.res_neighbors);
            for i=1:length(node_ids)
                node_id = node_ids(i);
                node = nodes(i);
                obj.res_received_messages(node_id) = node.message(obj.uid);
            end
            node_msgs = values(obj.res_received_messages);
            obj.msg_sum_res = sum(node_msgs);
            obj.msg_sum_res_aux = sum(-log2(1+2*2.^(-node_msgs)));
        end

        function receive_ind_messages(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            node_ids = keys(obj.ind_neighbors);
            nodes = values(obj.ind_neighbors);
            for i=1:length(node_ids)
                node_id = node_ids(i);
                node = nodes(i);
                obj.ind_received_messages(node_id) = node.message(obj.uid);
            end
            node_msgs = values(obj.ind_received_messages);
            obj.msg_sum_ind = sum(node_msgs);
            obj.msg_sum_ind_aux = sum(log2(1+2*2.^node_msgs));
        end

        
        function msg = message(obj, requester_id, ind, res)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if res
                requester_msg = obj.res_received_messages(requester_id);
                msg = obj.channel_llr_res + obj.msg_sum_res + obj.msg_sum_ind_aux - requester_msg;
            elseif ind
                requester_msg = obj.ind_received_messages(requester_id);
                msg = obj.channel_llr_ind + obj.msg_sum_ind + obj.msg_sum_res_aux - requester_msg;
            end
        end

        function prob = estimate(obj)
            x = obj.channel_llr_res + obj.msg_sum_res + obj.msg_sum_ind_aux;
            y =  obj.channel_llr_ind + obj.msg_sum_ind + obj.msg_sum_res_aux;
            if 2^y == inf
                Pr0 = 1;
            else
                Pr0 = 2^y / (1+2^y);
            end

            Pr2 = 1 / (1+2^x);
            Pr1 = 1 - Pr0 -Pr2;
            prob = [Pr0, Pr1, Pr2];
        end
    end
end

