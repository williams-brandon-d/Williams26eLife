function fig = plotds(x,y,x_ds,y_ds)
    fig = figure;
    plot(x,y,'b.');
    hold on
    plot(x_ds,y_ds,'r.');
    legend('Original','Downsampled');
end