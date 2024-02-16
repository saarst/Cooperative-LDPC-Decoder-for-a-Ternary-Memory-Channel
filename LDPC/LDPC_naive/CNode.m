classdef CNode < Node
    %CNODE Summary of this class goes here
    %   Detailed explanation goes here

    properties
        msg_sum_phi_abs
        msg_prod_sign
        ind = false
        res = false
        messages_out = []
    end

    methods
        function initialize(obj)
            %CNODE Construct an instance of this class
            %   Detailed explanation goes here
            obj.received_messages = zeros(size(obj.neighbors_ids));
            obj.messages_out = zeros(size(obj.neighbors_ids));
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

