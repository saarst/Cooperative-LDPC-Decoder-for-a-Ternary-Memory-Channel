classdef VNode < Node
    %VNODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        channel_model
        channel_symbol = [];
        channel_llr = [];
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
            obj.received_messages = dictionary(obj.neighbors.keys,zeros(size(obj.neighbors.keys)));
        end
        
        function msg = message(obj, requester_id)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            node_entries = entries(obj.received_messages);
            node_entries(node_entries.Key == requester_id,:) = [];
            r = node_entries.Value;
            %%%%%%%%%%%%%%%% ask yuval about q=0 :
            msg = obj.channel_llr + sum(r); % q msg
        end

        function bit = estimate(obj)
            node_values = values(obj.received_messages);
            bit = obj.channel_llr + sum(node_values);
        end
    end
end

