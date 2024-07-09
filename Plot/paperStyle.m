function paperStyle(hfig,n,p,Rind,Rres)
    figure(hfig);
    hax = gca;
    hax.FontSize = 16;
    hax.TickLabelInterpreter = 'latex';
    hax.Legend.Interpreter = 'latex';
    grid on;

    hax.Children(1).Marker = "+";
    hax.Children(1).MarkerSize = 5;
    hax.Children(1).LineWidth = 2;
    hax.Children(1).DisplayName = "Joint decoder (This paper)";

    hax.Children(2).Marker = "o";
    hax.Children(2).MarkerSize = 5;
    hax.Children(2).LineWidth = 2;
    hax.Children(2).DisplayName = "Two-step decoder (Prior work)";

    hax.Title.String = "$n="+string(n)+"$, "+...
        ...", $[s^{(1)},s^{(2)}]=[6,2]$, "+...
        "$R_{\Theta}="+sprintf("%.2f",Rind)+"$, $R_{\Lambda}="+sprintf("%.2f",Rres)+"$";
    hax.Title.Interpreter = 'latex';

    hax.XLabel.Interpreter = 'latex';
    hax.YLabel.Interpreter = 'latex';
    p_str = split(sprintf("%.0e",p),"e-0");
    hax.XLabel.String = "$q$ for $p="+p_str(1)+"\cdot10^{-"+p_str(2)+"}$";
    hax.YLabel.String = "Block Error Rate";