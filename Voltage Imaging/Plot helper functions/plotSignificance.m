function plotSignificance(stats,xPos,xTickLabels,dataMax,scale)
% plot significance
sigValues = [0.05, 0.01, 0.001];

yLim = ylim;
yMax = yLim(end);
yRange = diff(yLim);
nPairs = size(stats.results,1);

hold on
for i = 1:nPairs
    pValue = stats.results{i,"P-value"};
    if pValue < sigValues(1)

        x1 = xPos(strcmp(cell2mat(stats.results{i,"Group A"}),xTickLabels));
        x2 = xPos(strcmp(cell2mat(stats.results{i,"Group B"}),xTickLabels));

%         switch cell2mat(stats.results{i,"Group A"})
%             case 'stellate'
%                 x1 = xPos(1);
%             case 'pyramidal'
%                 x1 = xPos(2);
%             case 'fast spiking'
%                 x1 = xPos(3);
%         end
% 
%         switch cell2mat(stats.results{i,"Group B"})
%             case 'stellate'
%                 x2 = xPos(1);
%             case 'pyramidal'
%                 x2 = xPos(2);
%             case 'fast spiking'
%                 x2 = xPos(3);
%         end   

        text_x = x1 + 0.5*abs((x2-x1));

        dist = abs(x2-x1);

        switch scale
            case 'linear'
                horz_line_height_min = dataMax + 0.2*(yMax - dataMax);
                 if dist == 3
                    horz_line_height = horz_line_height_min + 0.12*yRange;
                 elseif dist == 2
                    horz_line_height = horz_line_height_min + 0.06*yRange;
                 elseif dist == 1
                    horz_line_height = horz_line_height_min;
                 end
                 switch stats.sig
                     case 'exact'
                        text_y = horz_line_height + 0.04*yRange;
                     case 'symbol'
                        text_y = horz_line_height + 0.02*yRange;
                 end
            case 'log'
                horz_line_height_min = 10^( 0.2*( log10(yMax) - log10(dataMax) ) + log10(dataMax) );
                 if dist == 3
                    horz_line_height = 10^( 0.12*( log10(yMax) - log10(yLim(1)) ) + log10(horz_line_height_min) );
                 elseif dist == 2
                    horz_line_height = 10^( 0.06*( log10(yMax) - log10(yLim(1)) ) + log10(horz_line_height_min) );
                 elseif dist == 1
                    horz_line_height = horz_line_height_min;
                 end
                switch stats.sig
                    case 'exact'
                       text_y = 10^( 0.04*( log10(yMax) - log10(yLim(1)) ) + log10(horz_line_height) );
                    case 'symbol'
                       text_y = 10^( 0.02*( log10(yMax) - log10(yLim(1)) ) + log10(horz_line_height) );
                end

        end

        plot( [x1 x2],horz_line_height*ones(1,2),'-k','Linewidth',1.2 )
        
        switch stats.sig 
            case 'exact'
                text_string = sprintf('p = %.3g',pValue);
                pvaluefontsize = 10;
            case 'symbol'
                if pValue < sigValues(1) && pValue > sigValues(2)
                    text_string = '*';
                elseif pValue < sigValues(2) && pValue > sigValues(3)
                    text_string = '**';
                else 
                    text_string = '***';
                end
                pvaluefontsize = 20;
        end

        text_box = text( text_x, text_y, text_string);
        text_box.FontSize = pvaluefontsize;
        text_box.FontWeight = 'bold';
        text_box.HorizontalAlignment = "center";
    end

end

hold off

end
