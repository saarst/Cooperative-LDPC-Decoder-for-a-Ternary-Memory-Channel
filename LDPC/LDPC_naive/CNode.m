classdef CNode < Node
    %CNODE Summary of this class goes here
    %   Detailed explanation goes here

    properties
        msg_sum_phi_abs
        msg_prod_sign
        ind
        res
    end

    methods
        function initialize(obj, ind, res)
            %CNODE Construct an instance of this class
            %   Detailed explanation goes here
            obj.received_messages = dictionary(obj.neighbors.keys,zeros(size(obj.neighbors.keys)));
            obj.msg_sum_phi_abs = 0;
            obj.msg_prod_sign = 0;
            obj.ind = ind;
            obj.res = res;
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
            node_ids = keys(obj.neighbors);
            nodes = values(obj.neighbors);
            for i=1:length(node_ids)
                if obj.ind || obj.res
                    obj.received_messages(node_ids(i)) = nodes(i).message(obj.uid, obj.ind, obj.res);
                else
                    obj.received_messages(node_ids(i)) = nodes(i).message(obj.uid);
                end
            end
            node_msgs = values(obj.received_messages);
            obj.msg_sum_phi_abs  = sum(phi(abs(node_msgs)));
            obj.msg_prod_sign = prod(sign(node_msgs));
        end
    end
end

