classdef Node < handle
    %NODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        uid
        name string
        ordering_key {mustBeNumeric} 
        neighbors = dictionary
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
            % obj.neighbors = dictionary;
        end
        
        function register_neighbor(obj, neighbor)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.neighbors(neighbor.uid) = neighbor;
        end

    end

    methods (Abstract)
        message(obj)
        initialize(obj)
    end
end