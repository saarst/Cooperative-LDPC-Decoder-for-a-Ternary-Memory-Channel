classdef Node < handle
    %NODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        uid
        name string
        ordering_key {mustBeNumeric} 
        neighbors_ids = []
        neighbors_nodes = []
        self_index_at_neighbors = [];
        received_messages
    end
    
    methods (Static)
        function out = count(data)
         persistent Var;
         if nargin
            Var = data;
         end
         if isempty(Var)
             Var = 0;
         else
            Var = Var + 1;
         end
         out = Var;
      end
   end


    methods
        function obj = Node(name,ordering_key)
            arguments
                name (1,1) = ""
                ordering_key  = []
            end
            %NODE Construct an instance of this class
            %   Detailed explanation goes here
            obj.uid = obj.count;
            if strcmp(name,"")
                obj.name = string(obj.uid);
            else
                obj.name = name;
            end

            if isempty(ordering_key)
                obj.ordering_key = obj.uid;
            else
                obj.ordering_key = ordering_key;
            end
        end
        
        function register_neighbor(obj, neighbor, self_index_at_neighbor)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.neighbors_ids = [obj.neighbors_ids ; neighbor.uid];
            obj.neighbors_nodes = [obj.neighbors_nodes ; neighbor];
            if self_index_at_neighbor > 0
                obj.self_index_at_neighbors = [obj.self_index_at_neighbors, self_index_at_neighbor];
            end
        end
        
        function nextIndex = next_index(obj)
            nextIndex = length(obj.neighbors_ids) + 1;
        end

    end

    methods (Abstract)
        initialize(obj)
    end
end