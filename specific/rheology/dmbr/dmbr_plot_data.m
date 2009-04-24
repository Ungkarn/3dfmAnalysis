function v = dmbr_plot_data(dmbr_struct, params, selection, plot_opts)
% 3DFM function   
% Rheology
% last modified 03/21/08 (jcribb)
%  
%

    dmbr_constants;        
    
    figure_handle = plot_opts.figure_handle;
    
    table = dmbr_filter_table(dmbr_struct.raw.rheo_table, ...
                                 selection.beadID, ...
                                 selection.seqID, ...
                                 selection.voltage);
    
    if isempty(table)
        clf(figure_handle);
        figure(figure_handle);
        text(0.445,0.5, 'No Data.');
        return;
    end
        
    seq = table(:,SEQ);
    force = table(:,FORCE);

    t = table(:,TIME);

    % Process options to determine what to load
    if plot_opts.plot_smoothed    
        x = table(:,SX);
        y = table(:,SY);
        j = table(:,SJ);
       dx = table(:,SDX);
       dy = table(:,SDY);        
       dj = table(:,SDJ);
    else
        x = table(:,X);
        y = table(:,Y);
        j = table(:,J);
       dx = table(:,DX);
       dy = table(:,DY);        
       dj = table(:,DJ);
    end
    

    % neutralize
    t = t - t(1);
    x = x - x(1);
    y = y - y(1);    
    r = magnitude(x,y);
    dr = magnitude(dx, dy);
    
    if plot_opts.plotx;
          xdata  =  x;
         dxdata  = dx;       
    else
         xdata = zeros(length(x),1)*NaN;
        dxdata = zeros(length(x),1)*NaN;
    end

    if plot_opts.ploty;
         ydata =  y;
        dydata = dy;
    else
         ydata = zeros(length(y),1)*NaN;
        dydata = zeros(length(y),1)*NaN;
    end

    if plot_opts.plotr;
         rdata =  r;
        drdata = dr;
    else
        rdata  = zeros(length(r),1)*NaN;
        drdata = zeros(length(r),1)*NaN;
    end    

         xyr      = [  xdata,   ydata,   rdata];    
        dxyrdt    = [ dxdata,  dydata,  drdata];

    % computing the maximum shear rate experienced at the bead's surface
    max_shear_rate = shear_rate_max(dxyrdt, params.bead_radius * 1e-6);

    %
    if isfield(dmbr_struct, 'cap')
       cap_srate = dmbr_struct.cap.srate;
       cap_viscPa= dmbr_struct.cap.viscPa;
    end
    % computing the Weissenburg number as a function of shear rate and tau
    tau = params.tau;
    Wi = max_shear_rate .* tau;            

    % computing the instantaneous viscosity as a function of compliance
    visc = 1 ./ dj;

    
    % get things into nice plottable and mentally stable units
    xyr    = xyr     * 1e6;  % m -> um
    force  = force   * 1e12; % N -> pN
    dxyrdt = dxyrdt  * 1e6;   % m -> um           
        
                %     % VERY BAD.... injecting cone and plate data for DNA here...
                %     CAPpath = '\\nsrg-cs.cs.unc.edu\cribb\data\DNA\rheology\cone and plate\2006.11.20_AR-G2\';
                %     CAPfile = 'lambda_dna_shear_flow_data.csv';
                %     CAPdata = csvread([CAPpath CAPfile]);
                %     CAP_shear_rate = CAPdata(:,1);
                %     CAP_visc       = CAPdata(:,2);
    
    % handle the log/lin space choice
    if plot_opts.logspace;
        warning off MATLAB:log:logOfZero;
            t = log10(t);
            xyr = log10(xyr);
            dxyrdt = log10(dxyrdt);
            force = log10(force);
            max_shear_rate = log10(max_shear_rate);
            Wi = log10(Wi); 
            j = log10(j);
            visc = log10(visc);
            if isfield(dmbr_struct, 'cap')
               cap_srate = log10(cap_srate);
               cap_viscPa= log10(cap_viscPa);
            end
            dxyrdt    = log10(dxyrdt);
            dj   = log10(dj);
        warning on MATLAB:log:logOfZero;

        logstring1 = 'log_{10}( ';
        logstring2 = ' )';
    else
        logstring1 = '';
        logstring2 = '';
    end
    

    figure(plot_opts.figure_handle);

    switch plot_opts.plot_type

        case 'displacement'
            subplot(1,1,1);
            plot(t, xyr, '.');
            xlabel([logstring1 'time [s]' logstring2]);
            ylabel([logstring1 'displacement [\mum]' logstring2]);
            
        case 'disp/force'
            subplot(2,1,1);
            plot(t, xyr, '-');
            xlabel([logstring1 'time [s]' logstring2]);
            ylabel([logstring1 'displacement [\mum]' logstring2]);

            subplot(2,1,2);
            plot(t, force, '.')
            xlabel([logstring1 'time [s]' logstring2]);
            ylabel([logstring1 'force [pN]' logstring2])
        
        case 'velocity'
            subplot(1,1,1);
            plot(t, dxyrdt, '.');
            xlabel([logstring1 'time [s]' logstring2])
            ylabel([logstring1 'velocity [\mum/s]' logstring2]);
            title(['time window, size= ' num2str(params.scale,0)*mean(diff(t)) ' [s].']);            

        case 'max shear rate'                      
            subplot(1,1,1);
            plot(t, max_shear_rate, '.');
            xlabel([logstring1 'time [s]' logstring2]);
            ylabel([logstring1 'maximum shear rate [1/s]' logstring2]);

        case 'Weissenberg #'
            subplot(1,1,1);
            plot(t, Wi, '.');
            xlabel([logstring1 'time [s]' logstring2]);
            ylabel([logstring1 'Weissenberg Number' logstring2]);

        case 'compliance'
            subplot(1,1,1);
            plot(t, j, '.');
            xlabel([logstring1 'time [s]' logstring2]);
            ylabel([logstring1 'compliance, J [Pa^{-1}]' logstring2]);     
            
        case 'inst. viscosity'
            subplot(1,1,1);
            plot(t, visc, '.');
            xlabel([logstring1 'time [s]' logstring2])
            ylabel([logstring1 '\eta [Pa s]' logstring2]);
            title(['time window, size= ' num2str(params.scale,0)*mean(diff(t)) ' [s].']);            
            
        case 'strain thickening'
            subplot(1,1,1);
            plot(xyr, visc, '.');            
            xlabel([logstring1 'radial displacement [\mum]' logstring2]);
            ylabel([logstring1 'viscosity, \eta [Pa s]' logstring2]);

        case 'inst. viscosity vs. max shear rate'
            subplot(1,1,1);
            plot(max_shear_rate(:,3), visc, '.');
            hold on;
                text(max_shear_rate(1,3), visc(1,1), 'S', 'FontWeight', 'Demi');
                text(max_shear_rate(end,3), visc(end,1), 'E', 'FontWeight', 'Demi');
            hold off;
            
            if isfield(dmbr_struct, 'cap')
               hold on;
               plot(cap_srate, cap_viscPa, 'k-');
               hold off;
            end
                        
            xlabel([logstring1 'maximum shear rate [1/s]' logstring2]);
            ylabel([logstring1 'inst. viscosity [Pa s]' logstring2]);
            
            pause(0.1);
            
        case 'inst. viscosity vs. Weissenburg #'
            subplot(1,1,1);
            plot(Wi, visc, '.');
            xlabel([logstring1 'Weissenburg Number' logstring2]);
            ylabel([logstring1 'inst. viscosity [Pa s]' logstring2]);
            
    end
    
    pretty_plot;
    drawnow;

    v = 0;
    