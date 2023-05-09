classdef DoubleTannerGraph < handle
    %TANNERGRAPH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        v_nodes = dictionary
        ind_nodes = dictionary
        res_nodes = dictionary
        ind_edges = dictionary
        res_edges = dictionary
    end
    
    methods
        function obj = DoubleTannerGraph()
            Node.count(-1);
        end
        
        function node = add_v_node(obj, channel_model_ind, channel_model_res, ordering_key, name)
            node = VXNode(channel_model_ind, channel_model_res, name, ordering_key);
            obj.v_nodes(node.uid) = node;
        end

        function node = add_ind_node(obj, ordering_key, name)
            node = CNode(name,ordering_key);
            obj.ind_nodes(node.uid) = node;
        end
        
        function node = add_res_node(obj, ordering_key, name)
            node = CNode(name,ordering_key);
            obj.res_nodes(node.uid) = node;
        end

        function  add_ind_edge(obj, vnode_uid, cnode_uid)
            assert(isKey(obj.v_nodes,vnode_uid), "vnode_uid is not in dict");
            assert(isKey(obj.ind_nodes,cnode_uid), "cnode_uid is not in dict");
            obj.ind_nodes(cnode_uid).register_neighbor(obj.v_nodes(vnode_uid));
            obj.v_nodes(vnode_uid).register_ind_neighbor(obj.ind_nodes(cnode_uid));
            obj.ind_edges(vnode_uid) = cnode_uid;
        end 

        function  add_res_edge(obj, vnode_uid, cnode_uid)
            assert(isKey(obj.v_nodes,vnode_uid), "vnode_uid is not in dict");
            assert(isKey(obj.res_nodes,cnode_uid), "cnode_uid is not in dict");
            obj.res_nodes(cnode_uid).register_neighbor(obj.v_nodes(vnode_uid));
            obj.v_nodes(vnode_uid).register_res_neighbor(obj.res_nodes(cnode_uid));
            obj.res_edges(vnode_uid) = cnode_uid;
        end 

        function add_ind_edges_by_name(obj, vnode_name, cnode_name)
            vnodes_values = values(obj.v_nodes);
            vnodes_keys = keys(obj.v_nodes);
            v_uid = vnodes_keys(strcmp([vnodes_values.name], vnode_name));

            cnodes_values = values(obj.ind_nodes);
            cnodes_keys = keys(obj.ind_nodes);
            c_uid = cnodes_keys(strcmp([cnodes_values.name], cnode_name));

            obj.add_ind_edge(v_uid, c_uid);
        end

        function add_res_edges_by_name(obj, vnode_name, cnode_name)
            vnodes_values = values(obj.v_nodes);
            vnodes_keys = keys(obj.v_nodes);
            v_uid = vnodes_keys(strcmp([vnodes_values.name], vnode_name));

            cnodes_values = values(obj.res_nodes);
            cnodes_keys = keys(obj.res_nodes);
            c_uid = cnodes_keys(strcmp([cnodes_values.name], cnode_name));

            obj.add_res_edge(v_uid, c_uid);
        end

    end
end

