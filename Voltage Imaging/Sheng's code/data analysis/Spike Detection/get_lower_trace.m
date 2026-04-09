
function lower_trace = get_lower_trace(current_trace,trace_moving_window)

    m_trace = movmean(current_trace,trace_moving_window);
    lower_trace = current_trace;
    % replace the part below moving average with moving average
    %idx = find(lower_trace>m_trace);
    %lower_trace(idx)=m_trace(idx);
    lower_trace = min(lower_trace, m_trace);
end