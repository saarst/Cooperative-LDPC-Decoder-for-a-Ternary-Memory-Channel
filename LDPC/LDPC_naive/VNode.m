classdef VNode < Node
    %VNODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        channel_model
        channel_symbol = [];
        channel_llr = [];
        msg_sum = [];
        messages_out = []
    end
    
    methods
        function obj = VNode(channel_model, name, ordering_key)
            arguments
                channel_model = bsc_llr(0.5)
                name = ""
                ordering_key = []
            end
            obj@Node(name,ordering_key);
            obj.channel_model = channel_model;
        end
        
        function initialize(obj, channel_symbol)
            %CNODE Construct an instance of this class
            %   Detailed explanation goes here
            obj.channel_symbol = channel_symbol;
            obj.channel_llr = obj.channel_model(channel_symbol);
            obj.msg_sum = 0;
            obj.received_messages = zeros(size(obj.neighbors_ids));
            obj.messages_out = obj.channel_llr * ones(size(obj.neighbors_ids));
        end
        
        function msg = message(obj, requester_id)
            requester_msg = obj.received_messages(requester_id);
            msg = obj.channel_llr + obj.msg_sum - requester_msg;
        end
        
        function receive_messages(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            nodes = obj.neighbors_nodes;
            for i=1:length(obj.neighbors_ids)
                obj.received_messages(i) = nodes(i).messages_out(obj.self_index_at_neighbors(i));
            end
            obj.msg_sum = sum(obj.received_messages);
            obj.messages_out =  obj.channel_llr + obj.msg_sum - obj.received_messages;
        end

        function bit = estimate(obj)
            bit = obj.channel_llr + obj.msg_sum;
        end
    end
end

