function F=plobs_frame_maker(plot_data)
    n_frames=plot_data.n_frames;
    groups=plot_data.groups;
    for k=1:n_frames
        for i=1:length(groups)
           group=groups{i};
           subplot(group.subplot{:});
           plobs=group.plobs;
           for p=1:length(plobs)
               plobs{p}.get_plots();
               hold on
           end
           
           if iscell(group.legend)
                legend(group.legend{:});
           end
           if group.grid==true
               grid on
           end
           
           title(group.title);
           xlabel(group.xlabel);
           ylabel(group.ylabel);
           axis(group.axis);
        end
        
        F(k)=getframe(gcf);
        
        pause(plot_data.pause);
        if k~=n_frames
            clf('reset');
        end
        
    end    
end