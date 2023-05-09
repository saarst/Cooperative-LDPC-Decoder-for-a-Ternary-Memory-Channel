classdef CNode < Node
    %CNODE Summary of this class goes here
    %   Detailed explanation goes here
    methods
        function initialize(obj)
            %CNODE Construct an instance of this class
            %   Detailed explanation goes here
            obj.received_messages = dictionary(obj.neighbors.keys,zeros(size(obj.neighbors.keys)));
        end
        
        function msg = message(obj, requester_id)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            node_entries = entries(obj.received_messages);
            node_entries(node_entries.Key == requester_id,:) = [];
            q = node_entries.Value;
            %%%%%%%%%%%%%%%% ask yuval about q=0 :
            msg = prod(sign(q))   *  phi(sum( phi(abs(q)) )); % r msg
        end
    end
end

