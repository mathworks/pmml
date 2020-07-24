classdef PersistenceService < matlab.mixin.SetGet
    %PersistenceService Provides the functionality to persist PMML data
    %                   across runs in MPS. Singleton class.
    
    % Copyright 2020 MathWorks Inc.
    
    properties ( SetAccess = private )
        Connection
        Control
    end
    
    methods
        function result = reset( obj )
            %reset Resets the server cleaning the DB
            try
                clear(obj.Connection); % cleans the Redis DB
                result = 'Success';
                fprintf('PersistenceService:Cache cleared\n')
            catch e
                warning('Server:reset:FailedReset', ...
                    'Failed to reset server: %s',e.message)
                result = 'Failed to reset server';
            end
        end %reset
    end
    
    methods ( Static )
        function obj = getInstance()
            %getInstance Returns the singleton instance
            persistent g_obj
            if isempty(g_obj)
                g_obj = pmml.PersistenceService;
            end
            obj = g_obj;
            if isempty(obj.Connection)
                obj.initialize()
            end
        end %getinstance
        
    end %static methods
    
    properties ( Access = private )
        CacheName = 'cachePMML'
        ConnectionName = 'connectionPMML'
        RedisPort = 4519 %port to use for Redis database

    end
    methods ( Access = private )
        function obj = PersistenceService()
        end %private constructor
        
        function initialize( obj )
            if isdeployed
                obj.Control = [];
            else
                try
                    ctrl = mps.cache.control('connectionPMML');
                catch e
                    ctrl = [];
                end
                if ~isempty(ctrl)
                    obj.Control = ctrl;
                    try
                        attach(obj.Control);
                    catch e
                         error('PersistenceService:initialize:NoConn', ...
                    'Unable to attach to connection %s',e.message)
                    end
                else
                    obj.Control = mps.cache.control(obj.ConnectionName,'Redis','Port', ...
                        obj.RedisPort);
                    try
                        start(obj.Control);
                    catch
                        attach(obj.Control);
                    end
                end
            end
            try
                obj.Connection = mps.cache.connect(obj.CacheName, ...
                    'Connection',obj.ConnectionName);
            catch e
                error('PersistenceService:initialize:NoConn', ...
                    'Unable to get connection %s',e.message)
            end
        end %initialize
    end
end %classdef PersistentService