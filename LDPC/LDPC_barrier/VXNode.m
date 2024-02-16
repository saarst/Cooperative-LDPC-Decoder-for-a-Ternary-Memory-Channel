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
        ind_messages_out = []
        res_messages_out = []
        res_neighbors_ids = []
        res_neighbors_nodes = []
        self_index_at_res_neighbors = []
        ind_neighbors_ids = []
        ind_neighbors_nodes = []
        self_index_at_ind_neighbors = []
        msg_sum_ind = nan
        msg_sum_ind_aux
        msg_sum_res = nan
        msg_sum_res_aux

        ind_self
        res_self
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
            obj.ind_self = 0;
            obj.msg_sum_res = 0;
            obj.msg_sum_res_aux = 0;
            obj.res_self = 0;
            obj.ind_received_messages = zeros(size(obj.ind_neighbors_ids));
            obj.res_received_messages = zeros(size(obj.res_neighbors_ids));
            obj.ind_messages_out = obj.channel_llr_ind * ones(size(obj.ind_neighbors_ids));
            obj.res_messages_out = obj.channel_llr_res * ones(size(obj.res_neighbors_ids));
        end

        function register_ind_neighbor(obj, neighbor, self_index_at_neighbor)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.ind_neighbors_ids = [obj.ind_neighbors_ids ; neighbor.uid];
            obj.ind_neighbors_nodes = [obj.ind_neighbors_nodes ; neighbor];
            if self_index_at_neighbor > 0
                obj.self_index_at_ind_neighbors = [obj.self_index_at_ind_neighbors, self_index_at_neighbor];
            end
        end

        function register_res_neighbor(obj, neighbor, self_index_at_neighbor)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.res_neighbors_ids = [obj.res_neighbors_ids ; neighbor.uid];
            obj.res_neighbors_nodes = [obj.res_neighbors_nodes ; neighbor];
            if self_index_at_neighbor > 0
                obj.self_index_at_res_neighbors = [obj.self_index_at_res_neighbors, self_index_at_neighbor];
            end
        end
        
        function nextIndex = next_ind_index(obj)
            nextIndex = length(obj.ind_neighbors_ids) + 1;
        end
        
        function nextIndex = next_res_index(obj)
            nextIndex = length(obj.res_neighbors_ids) + 1;
        end

        function prob = receive_and_estimate(obj, lastSubSequence)
            if strcmp(lastSubSequence, "res")
                %res
                for i=1:length(obj.res_neighbors_ids)
                    obj.res_received_messages(i) = obj.res_neighbors_nodes(i).messages_out(obj.self_index_at_res_neighbors(i));
                end
                obj.msg_sum_res = sum(obj.res_received_messages);
                obj.msg_sum_res_aux = sum(-log(0.5+exp(-obj.res_received_messages)));
            elseif strcmp(lastSubSequence, "ind")
                %ind
                for i=1:length(obj.ind_neighbors_ids)
                    obj.ind_received_messages(i) = obj.ind_neighbors_nodes(i).messages_out(obj.self_index_at_ind_neighbors(i));
                end
                obj.msg_sum_ind = sum(obj.ind_received_messages);
                obj.msg_sum_ind_aux = sum(log((1/3)+(2/3)*exp(obj.ind_received_messages)));
            end
            % update self messages
            obj.ind_self = obj.channel_llr_ind + obj.msg_sum_ind + obj.msg_sum_res_aux;
            obj.res_self = obj.channel_llr_res + obj.msg_sum_res + obj.msg_sum_ind_aux;
            % update out messages
            obj.ind_messages_out = obj.ind_self - obj.ind_received_messages;
            obj.res_messages_out = obj.res_self - obj.res_received_messages;
            %update probabilites
            Pr0 = 1 / (1+exp(-obj.ind_self));
            Pr2 = 1 / (1 + exp(obj.res_self));
            Pr1 = 1 - Pr0 - Pr2;

            prob = [Pr0, Pr1, Pr2];
        end

    end
end

