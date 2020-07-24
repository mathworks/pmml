classdef (Sealed) Server < matlab.mixin.SetGet
    %Server class implementing a PMML server in MATLAB
    
    % Copyright 2020 MathWorks Inc.
    
    properties
        Silent logical =false
    end %public properties
    properties ( Dependent )
        Models pmml.PMMLModel %Loaded models array
    end
    
    methods
        
        function res = addModel( obj , sParam , name , update )
            %addModel Adds a model to the server
            if nargin<4
                update = false;
            end
            
            if isstring(sParam)
                sParam = char(sParam);
            end
            if ~ischar(sParam)
                res = 'First parameter must be a char or a string';
                return
            end
            res = 'OK';
            removeTempfile = false;
            if strcmp(sParam(1:5),'<?xml')
                %is a string with an pmml format, create temp file
                try
                    tempFilename = tempname;
                    fidTempFile = fopen(tempFilename,'w');
                    fprintf(fidTempFile,'%s',sParam);
                    fclose(fidTempFile);
                    modelFilePath = tempFilename;
                    removeTempfile = true;
                catch e
                    res = sprintf('Server:addModel-Failed to create temporary file: %s', ...
                        e.message);
                end
            else
                % assume is a file path
                modelFilePath = sParam;
                if exist(modelFilePath,'file')~=2
                    res = sprintf(['Server:addModel:FileNotFound', ...
                        'File %s does not exist'],modelFilePath);
                end
            end
            pmmlReader = pmml.PMMLReader;
            pmmlReader = pmmlReader.readPMML(modelFilePath);
            model = pmmlReader.Model;
            pmmlModel = pmml.PMMLModel(model, pmmlReader.ModelParams);
            if nargin>2
                pmmlModel.Name = name;
            end
            conn = pmml.PersistenceService.getInstance.Connection;
            if isKey(conn,obj.ModelsTag) == false
                put(conn,obj.ModelsTag,pmmlModel)
                res = 'Model added';
                if ~obj.Silent
                    fprintf('Model %s added to server\n',name)
                end
            else
                models = get(conn,obj.ModelsTag);
                if ~any(ismember([models.Name],name))
                    models(end+1) = pmmlModel;
                    put(conn,obj.ModelsTag,models);
                    res = 'Model added';
                    if ~obj.Silent
                        fprintf('Model %s added to server\n',name)
                    end
                elseif update
                    idx = ismember([models.Name],name);
                    models(idx) = pmmlModel;
                    put(conn,obj.ModelsTag,models);
                    res = 'Model updated';
                    if ~obj.Silent
                        fprintf('Model %s updated in server\n',name)
                    end
                else
                    warning('Server:addModel:AlreadyInServer', ...
                        'Server running already with %s',name)
                    res = 'Warning:Model already in server';
                end
            end
            if removeTempfile
                delete(tempFilename)
            end
        end %addModel
        
        function result = executeModel( obj , modelName, data )
            %executeModel Executes a model with the  provided data
            assert(ischar(modelName))
            conn = pmml.PersistenceService.getInstance.Connection;
            models =  get(conn,obj.ModelsTag);
            modelNames = cellfun(@char,{models.Name},'UniformOutput',false);
            [ism, modelIndex] = ismember(modelNames, modelName);
            if ~any(ism)
                error('Server:executeModel','Model %s not found in server', ...
                        modelName)
            end
            model = models(logical(modelIndex));
            switch class(model)
                case 'pmml.PMMLModel'
                    result = score(model.Model,data);
                otherwise
                    error('Server:executeModel','Case %s not implemented', ...
                        class(model))
            end
        end %executeModel
        
        function reset( obj )
            conn = pmml.PersistenceService.getInstance.Connection;
            flag = clear(conn);
            if flag && ~obj.Silent
                %cache cleared
                fprintf('Cache reset\n')
            end
        end %reset
        
        function models = get.Models( obj )
            %get.Models Populates Models property
            conn = pmml.PersistenceService.getInstance.Connection;
            models = get(conn,obj.ModelsTag);
        end %get.Models
        
    end %methods
    
    methods ( Static )
        function obj = getInstance()
            %getInstance Returns the singleton instance of this class
            persistent g_obj
            if isempty(g_obj)
                g_obj = pmml.server.Server();
            end
            obj = g_obj;
        end %getInstance
        
    end %static methods
    
    properties ( Access = private )
        ModelsTag = 'Models';
    end %private properties
    
    methods ( Access = private )
        function obj = Server( )
            %make it private for singleton instance
        end % constructor
        

    end %private methods
end %Server class