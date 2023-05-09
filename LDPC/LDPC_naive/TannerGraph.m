classdef TannerGraph < handle
    %TANNERGRAPH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        v_nodes = dictionary
        c_nodes = dictionary
        edges = dictionary
    end
    
    methods
        function obj = TannerGraph()
            Node.count(-1);
        end
        
        function node = add_v_node(obj, channel_model, ordering_key, name)
            node = VNode(channel_model,name, ordering_key);
            obj.v_nodes(node.uid) = node;
        end

        function node = add_c_node(obj, ordering_key, name)
            node = CNode(name,ordering_key);
            obj.c_nodes(node.uid) = node;
        end

        function  add_edge(obj, vnode_uid, cnode_uid)
            assert(isKey(obj.v_nodes,vnode_uid), "vnode_uid is not in dict");
            assert(isKey(obj.c_nodes,cnode_uid), "cnode_uid is not in dict");
            obj.c_nodes(cnode_uid).register_neighbor(obj.v_nodes(vnode_uid));
            obj.v_nodes(vnode_uid).register_neighbor(obj.c_nodes(cnode_uid));
            obj.edges([vnode_uid,cnode_uid]) = 1;
        end 

        function add_edges_by_name(obj, vnode_name, cnode_name)
            vnodes_values = values(obj.v_nodes);
            vnodes_keys = keys(obj.v_nodes);
            v_uid = vnodes_keys(strcmp([vnodes_values.name], vnode_name));

            cnodes_values = values(obj.c_nodes);
            cnodes_keys = keys(obj.c_nodes);
            c_uid = cnodes_keys(strcmp([cnodes_values.name], cnode_name));

            obj.add_edge(v_uid, c_uid);
        end

    end
end

