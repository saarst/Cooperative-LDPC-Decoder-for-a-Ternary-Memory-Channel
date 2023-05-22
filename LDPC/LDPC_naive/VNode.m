classdef VNode < Node
    %VNODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        channel_model
        channel_symbol = [];
        channel_llr = [];
        msg_sum = [];
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
            obj.received_messages = dictionary(obj.neighbors.keys,zeros(size(obj.neighbors.keys)));
        end
        
        function msg = message(obj, requester_id)
            requester_msg = obj.received_messages(requester_id);
            msg = obj.channel_llr + obj.msg_sum - requester_msg;
        end
        
        function receive_messages(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            node_entries = entries(obj.neighbors);
            for i=1:height(node_entries)
                node_id = node_entries{i,1};
                node = node_entries{i,2};
                obj.received_messages(node_id) = node.message(obj.uid);
            end
            node_msgs = entries(obj.received_messages);
            obj.msg_sum = sum(node_msgs.Value);
        end

        function bit = estimate(obj)
            node_values = values(obj.received_messages);
            bit = obj.channel_llr + sum(node_values);
        end
    end
end

