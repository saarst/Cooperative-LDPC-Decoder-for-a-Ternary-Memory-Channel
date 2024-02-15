classdef CNode < Node
    %CNODE Summary of this class goes here
    %   Detailed explanation goes here

    properties
        msg_sum_phi_abs
        msg_prod_sign
        ind
        res
        messages_out = []
    end

    methods
        function initialize(obj, ind, res)
            %CNODE Construct an instance of this class
            %   Detailed explanation goes here
            obj.received_messages = zeros(size(obj.neighbors_ids));
            obj.messages_out = zeros(size(obj.neighbors_ids));
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
            nodes = obj.neighbors_nodes;
            for i=1:length(obj.neighbors_ids)
                if obj.ind
                    obj.received_messages(i) = nodes(i).ind_messages_out(obj.self_index_at_neighbors(i));
                elseif obj.res
                    obj.received_messages(i) = nodes(i).res_messages_out(obj.self_index_at_neighbors(i));
                else
                    obj.received_messages(i) = nodes(i).messages_out(obj.self_index_at_neighbors(i));
                end
            end
            obj.msg_sum_phi_abs  = sum(phi(abs(obj.received_messages)));
            obj.msg_prod_sign = prod(sign(obj.received_messages));
            % construct messages
            msg_prod_sign_aux = obj.msg_prod_sign ./ sign(obj.received_messages);
            msg_phi_sum_phi_abs = phi( obj.msg_sum_phi_abs - phi(abs(obj.received_messages)) );

            obj.messages_out = msg_prod_sign_aux .* msg_phi_sum_phi_abs;
        end
    end
end

