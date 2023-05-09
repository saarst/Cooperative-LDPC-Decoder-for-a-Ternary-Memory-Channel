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
            node_entries = entries(obj.res_neighbors);
            for i=1:height(node_entries)
                node_id = node_entries{i,1};
                node = node_entries{i,2};
                obj.res_received_messages(node_id) = node.message(obj.uid);
            end
            node_msgs = entries(obj.res_received_messages);
            obj.msg_sum_res = sum(node_msgs.Value);
            obj.msg_sum_res_aux = sum(-log2(1+2*2.^(-node_msgs.Value)));
        end

        function receive_ind_messages(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            node_entries = entries(obj.ind_neighbors);
            for i=1:height(node_entries)
                node_id = node_entries{i,1};
                node = node_entries{i,2};
                obj.ind_received_messages(node_id) = node.message(obj.uid);
            end
            node_msgs = entries(obj.ind_received_messages);
            obj.msg_sum_ind = sum(node_msgs.Value);
            obj.msg_sum_ind_aux = sum(log2(1+2*2.^node_msgs.Value));
        end

        
        function msg = message(obj, requester_id)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if isKey(obj.res_neighbors,requester_id)
                requester_msg = obj.res_received_messages(requester_id);
                % requester_msg_aux = log2(1+2*2^requester_msg);
                requester_msg_aux = requester_msg;
                if ~isnan(obj.msg_sum_res)
                    msg = obj.channel_llr_res + obj.msg_sum_res + obj.msg_sum_ind_aux - requester_msg_aux;
                else
                    msg = obj.channel_llr_res;
                end
            elseif isKey(obj.ind_neighbors,requester_id)
                requester_msg = obj.ind_received_messages(requester_id);
                % requester_msg_aux = -log2(1+2*2^(-requester_msg));
                requester_msg_aux = requester_msg;
                if ~isnan(obj.msg_sum_ind)
                    msg = obj.channel_llr_ind + obj.msg_sum_ind + obj.msg_sum_res_aux - requester_msg_aux;
                else 
                    msg = obj.channel_llr_ind;
                end

            end
        end

        function prob = estimate(obj)
            x = obj.channel_llr_res + obj.msg_sum_res + obj.msg_sum_ind_aux;
            y =  obj.channel_llr_ind + obj.msg_sum_ind + obj.msg_sum_res_aux;

            Pr2 = 1 / (1+2^x);
            Pr0 = 2^y / (1+2^y);
            Pr1 = 1 - Pr0 -Pr2;
            prob = [Pr0, Pr1, Pr2];
        end
    end
end

