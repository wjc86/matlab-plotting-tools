classdef plottingObj < handle
    %plottingObj Basic object containing plotting params and values for a
    %scene actor
    %   This class is intended to streamline the plotting of time series
    %   data and bodies for 2D simulations. It is assumed that data has
    %   already been recorded, and this function facilitates plotting as
    %   playback.
    
    
    properties
        traj
        body
        traj_sz
        body_sz
        traj_dim
        body_dim
        traj_mode
        body_mode
        traj_iter
        body_iter
        traj_args
        body_args
        traj_plot
        body_plot
        
        body_mtrx_shape
        cycle_body
        cycle_traj
        
        contour_Matrix %only defined for 3D bodies
        contour_name
    end
    
    methods
        function obj = plottingObj(traj,varargin)
            %UNTITLED3 Construct an instance of this class
            %   Detailed explanation goes here

            %deal with default args
            p=inputParser; 
%             validScalarNum=@(x) isnumeric(x) && isscalar(x);
%             validScalarPosNum=@(x) isnumeric(x) && isscalar(x) && (x>0);
            addOptional(p,'traj',[]);
            addOptional(p,'body',[]);
            addOptional(p,'traj_mode','drag');
            addOptional(p,'body_mode','blank');
            
            addOptional(p,'traj_args',{'-'});
            addOptional(p,'body_args',{'-'});
            
            addOptional(p,'body_mtrx_shape',[]);
            
            addOptional(p,'cycle_body',false);
            addOptional(p,'cycle_traj',false);
            
            addOptional(p,'traj_default_auto_sz',2);
            addOptional(p,'time',-1);
            
            addOptional(p,'traj_name','Traj');
            addOptional(p,'body_name','Body');
       
            
            parse(p,traj,varargin{:});
            V=p.Results;
            
            obj.traj=V.traj;
            obj.body=V.body;
            obj.traj_sz=size(obj.traj);
            obj.body_sz=size(obj.body);
            obj.traj_dim=ndims(obj.traj);
            obj.body_dim=ndims(obj.body);
            obj.traj_mode=V.traj_mode;
            obj.body_mode=V.body_mode;
            obj.traj_args=V.traj_args;
            obj.body_args=V.body_args;
            obj.traj_iter=1;
            obj.body_iter=1;
            obj.body_mtrx_shape=V.body_mtrx_shape;
            obj.cycle_body=V.cycle_body;
            obj.cycle_traj=V.cycle_traj;
            
            obj.contour_Matrix=0;
            
            obj=obj.check_inputs();
            
            
            if strcmp(obj.body_mode,'blank')==1
                obj=obj.body_mode_from_size();
            end
            obj=obj.check_plotter_args();
            
        end
        
        
        function obj=check_inputs(obj)
            if isempty(obj.traj) && isempty(obj.body)
               warning('Both traj and body are empty; nothing will be plotted')
            end
            if ismember(obj.traj_sz(1),[0 2 3])==false
                throw(MException('plottingObj:data_size_err',sprintf('traj must have 2 or 3 rows, %d rows supplied',obj.traj_sz(1))));
            end
            if obj.traj_dim~=2
                throw(MException('plottingObj:data_size_err',sprintf('traj must have dimension 2, %d dimensions supplied',obj.traj_dim)));
            end
            if ismember(obj.body_sz(1),[0 2 3])==false
                throw(MException('plottingObj:data_size_err',sprintf('body must have 2 or 3 rows, %d rows supplied',obj.body_sz(1))));
            end
            if ismember(obj.body_dim,[2 3])==false
                throw(MException('plottingObj:data_size_err',sprintf('body must have dimension 2 or 3, %d dimensions supplied',obj.body_dim)));
            end
            if obj.body_sz(1)==3
               if isempty(obj.body_mtrx_shape)
                   if mod(sqrt(obj.body_sz(2)),1)==0
                      obj.body_mtrx_shape=[sqrt(obj.body_sz(2)), sqrt(obj.body_sz(2))];
                   else
                      throw(MException('plottingObj:data_size_err',sprintf('If body has leading size 3, either size 2 must be a square number, or kwarg body_mtrx_shape must be supplied')));
                   end
               end 
            end
            
            if obj.body_sz(1)==3 && mod(sqrt(obj.body_sz(2)),1)~=0
               if isempty(obj.body_mtrx_shape)
                   throw(MException('plottingObj:data_size_err',sprintf('If body has leading size 3, either size 2 must be a square number, or kwarg body_mtrx_shape must be supplied')));
               end
            end
        end
        
        function obj=body_mode_from_size(obj)
           if obj.body_sz(1)==3 %We have X,Y,Z---> can assume contour
               obj.body_mode='contour';
           elseif obj.body_sz(1)==2
               obj.body_mode='plot'; %with only X,Y, can choose plot of fill as default; plot has more common optional args.
           end
        end
        
        function obj=check_plotter_args(obj)
            if ~any(strcmp(obj.traj_args,'DisplayName'))
                obj.traj_args{end+1}='HandleVisibility';
                obj.traj_args{end+1}='off';
                
            end
            if ~any(strcmp(obj.body_args,'DisplayName'))
                obj.body_args{end+1}='HandleVisibility';
                obj.body_args{end+1}='off';
                
            
            end
        end
        
        function obj=reset_iters(obj)
           obj.traj_iter=1;
           obj.body_iter=1;
        end
        
        function obj=advance_traj_iter(obj)
           if obj.traj_iter<obj.traj_sz(2)
              obj.traj_iter=obj.traj_iter+1;
           elseif obj.cycle_traj==true
               obj.traj_iter=1;
           end
        end
        
        function obj=advance_body_iter(obj)
           if obj.body_iter<obj.body_sz(3)
              obj.body_iter=obj.body_iter+1;
           elseif obj.cycle_body==true
               obj.body_iter=1;
           end
        end
        
        %% Plotter
        function plts=get_plots(obj)
           if ~isempty(obj.body) 
               if strcmp(obj.body_mode,'contour')==1
                  obj=obj.bod_contour(obj.body_args);
               elseif strcmp(obj.body_mode,'plot')==1
                  obj=obj.bod_plot(obj.body_args); 
               elseif strcmp(obj.body_mode,'fill')==1
                  obj=obj.bod_fill(obj.body_args);
               end
           end
           
           hold on
           if ~isempty(obj.traj)
               if strcmp(obj.traj_mode,'plot')==1
                  obj=obj.full_plot(obj.traj_args); 
               elseif strcmp(obj.traj_mode,'drag')==1
                  obj=obj.drag_plot(obj.traj_args); 
               elseif strcmp(obj.traj_mode,'dot')==1
                  obj=obj.dot_plot(obj.traj_args);
               else
                  obj=obj.advance_traj_iter();
               end
           end
           
           hold off 
           
           plts={obj.traj_plot,obj.body_plot};
        end
        %% Traj Plot Prototypes
        
        function obj=full_plot(obj,varargin)
            p=inputParser;
            addOptional(p,'ax',gca());
            addOptional(p,'fig',gcf());
            parse(p,obj,varargin{:});
            V=p.Results;
            obj.traj_plot=plot(obj.traj(1,:),obj.traj(2,:),obj.traj_args{:});
        end
        
        function obj=drag_plot(obj,varargin)
            p=inputParser;
            addOptional(p,'ax',gca());
            addOptional(p,'fig',gcf());
            parse(p,obj,varargin{:});
            V=p.Results;
            obj.traj_plot=plot(obj.traj(1,1:obj.traj_iter),obj.traj(2,1:obj.traj_iter),obj.traj_args{:});
            obj=obj.advance_traj_iter();
        end
        
        function obj=dot_plot(obj,varargin)
            p=inputParser;
            addOptional(p,'ax',gca());
            addOptional(p,'fig',gcf());
            parse(p,obj,varargin{:});
            V=p.Results;
            obj.traj_plot=plot(obj.traj(1,obj.traj_iter),obj.traj(2,obj.traj_iter),obj.traj_args{:});
            obj=obj.advance_traj_iter();
        end
        
        %% Body Plot Prototypes
        
        function obj=bod_plot(obj,varargin)
            %plot_static_body Plot an unchanging body (2xS)
            %   Detailed explanation goes here
            p=inputParser;
            addOptional(p,'ax',gca());
            addOptional(p,'fig',gcf());
            parse(p,obj,varargin{:});
            V=p.Results;
            bod=obj.body(:,:,obj.body_iter);            
            if ~isempty(obj.traj)% is body translating?
                if obj.traj_sz(1)==3 % is body rotating ( we have rotation info if trajectory has x,y,theta)
                    theta=obj.traj(3,obj.traj_iter);
                    rotmat = [cos(theta) -sin(theta); sin(theta) cos(theta)];
                    
                    for i = 1:obj.body_sz(2)
                        bod(1:2,i)=rotmat*bod(1:2,i);
                    end
                end
                bod(1,:)=bod(1,:)+obj.traj(1,obj.traj_iter);
                bod(2,:)=bod(2,:)+obj.traj(2,obj.traj_iter);
                
            end
            obj.body_plot=plot(bod(1,:),bod(2,:),obj.body_args{:});
            if obj.body_dim==3
               obj=obj.advance_body_iter(); 
            end
        end
        
        
        function obj=bod_fill(obj,varargin)
            %plot_static_body Plot an unchanging body (2xS)
            %   Detailed explanation goes here
            p=inputParser;
            addOptional(p,'ax',gca());
            addOptional(p,'fig',gcf());
            parse(p,obj,varargin{:});
            V=p.Results;
            bod=obj.body(:,:,obj.body_iter);            
            if ~isempty(obj.traj)% is body translating?
                if obj.traj_sz(1)==3 % is body rotating ( we have rotation info if trajectory has x,y,theta)
                    theta=obj.traj(3,obj.traj_iter);
                    rotmat = [cos(theta) -sin(theta); sin(theta) cos(theta)];
                    
                    for i = 1:obj.body_sz(2)
                        bod(1:2,i)=rotmat*bod(1:2,i);
                    end
                end
                bod(1,:)=bod(1,:)+obj.traj(1,obj.traj_iter);
                bod(2,:)=bod(2,:)+obj.traj(2,obj.traj_iter);
                
            end
            obj.body_plot=fill(bod(1,:),bod(2,:),obj.body_args{:});
            if obj.body_dim==3
               obj=obj.advance_body_iter(); 
            end
        end
        
        function obj = bod_contour(obj,varargin)
            %plot_static_body Plot an unchanging body (2xS)
            %   Detailed explanation goes here
            p=inputParser;
            addOptional(p,'ax',gca());
            addOptional(p,'fig',gcf());
            parse(p,obj,varargin{:});
            V=p.Results;
            bod=obj.body(:,:,obj.body_iter);            
            if ~isempty(obj.traj)% is body translating?
                if obj.traj_sz(1)==3 % is body rotating ( we have rotation info if trajectory has x,y,theta)
                    theta=obj.traj(3,obj.traj_iter);
                    rotmat = [cos(theta) -sin(theta); sin(theta) cos(theta)];
                    
                    for i = 1:obj.body_sz(2)
                        bod(1:2,i)=rotmat*bod(1:2,i);
                    end
                end
                bod(1,:)=bod(1,:)+obj.traj(1,obj.traj_iter);
                bod(2,:)=bod(2,:)+obj.traj(2,obj.traj_iter);
                
            end
            X=reshape(bod(1,:),obj.body_mtrx_shape);
            Y=reshape(bod(2,:),obj.body_mtrx_shape);
            Z=reshape(bod(3,:),obj.body_mtrx_shape);
            [obj.contour_Matrix,obj.body_plot]=contour(X,Y,Z,obj.body_args{:});
            if obj.body_dim==3
               obj=obj.advance_body_iter(); 
            end
        end
        

        
        
        
    end
end

        