classdef CNode < Node
    %CNODE Summary of this class goes here
    %   Detailed explanation goes here

    properties
        msg_sum_phi_abs
        msg_prod_sign
    end

    methods
        function initialize(obj)
            %CNODE Construct an instance of this class
            %   Detailed explanation goes here
            obj.received_messages = dictionary(obj.neighbors.keys,zeros(size(obj.neighbors.keys)));
            obj.msg_sum_phi_abs = 0;
            obj.msg_prod_sign = 0;
        end
        
        function msg = message(obj, requester_id)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            requester_msg = obj.received_messages(requester_id);
            msg_prod_sign_aux = obj.msg_prod_sign / sign(requester_msg);
            msg_phi_sum_phi_abs = phi( obj.msg_sum_phi_abs - phi(abs(requester_msg)) );
            msg = msg_prod_sign_aux * msg_phi_sum_phi_abs; % r msg
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
            obj.msg_sum_phi_abs  = sum(phi(abs(node_msgs.Value)));
            obj.msg_prod_sign = prod(sign(node_msgs.Value));
        end
    end
end

