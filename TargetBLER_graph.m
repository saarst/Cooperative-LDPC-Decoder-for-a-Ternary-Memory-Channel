function TargetBLER_graph(T, metadata, targetValue, mode)
    % mode should be nearest or any other.

    
    fig = figure;
    decoders = ["joint", "prior"];
    for decoderIdx=1:2
        decoder = decoders(decoderIdx);
        currT = T.(decoder);
        p = currT.p;
        y = zeros(size(p));
        q_lims = [currT.q_l, currT.q_h];
        target_lims = [currT.BLER_at_q_l, currT.BLER_at_q_h];
        for k=1:length(p)
            if isnan(target_lims(k,1)) && ~isnan(target_lims(k,2))
                y(k) = q_lims(k,2);
            elseif ~isnan(target_lims(k,1)) && isnan(target_lims(k,2))
                y(k) = q_lims(k,1);
            elseif isnan(target_lims(k,1)) && isnan(target_lims(k,2))
                disp("both BLERs are NaN");
                continue
            else
                if strcmp(mode,"nearest")
                    [error, index] = min(abs(log10(target_lims(k,:)) - log10(targetValue)));
                    y(k) = q_lims(k,index);
                else
                    y(k) = 10^interp1(log10(target_lims(k,:)), log10(q_lims(k,:)), log10(targetValue), mode,"extrap"); % interpolate in any mod (default nearest)
                end
            end
        end
        loglog(p,y,"LineWidth",2,"Marker","+")
        hold on
    end

    legend("Joint decoder (This paper)", "Two-step (prior work)",'Location','southwest');
    xlabel(sprintf("p for BLER=%E",targetValue));
    ylabel("q");
    grid on

    forPaper = true;
    if forPaper
        hax = gca;
        hax.FontSize = 16;
        hax.TickLabelInterpreter = 'latex';
        hax.Legend.Interpreter = 'latex';
        grid on;
    
        hax.Children(1).Marker = "+";
        hax.Children(1).MarkerSize = 5;
        hax.Children(1).LineWidth = 2;
    
        hax.Children(2).Marker = "o";
        hax.Children(2).MarkerSize = 5;
        hax.Children(2).LineWidth = 2;
    
        hax.Title.String = "$n="+string(metadata.n)+"$, "+...
            ...", $[s^{(1)},s^{(2)}]=[6,2]$, "+...
            "$R_{\Theta}="+sprintf("%.2f",metadata.actualRates(1))+"$, $R_{\Lambda}="+sprintf("%.2f",metadata.actualRates(2))+"$";
        hax.Title.Interpreter = 'latex';
    
        hax.XLabel.Interpreter = 'latex';
        hax.YLabel.Interpreter = 'latex';
        BLER_str = split(sprintf("%.0e",targetValue),"e-0");
        hax.XLabel.String = "$p$ for $BLER="+BLER_str(1)+"\cdot10^{-"+BLER_str(2)+"}$";
        hax.YLabel.String = "$q$";
    end






end