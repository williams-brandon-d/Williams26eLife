function upper_trace = get_upper_trace(current_trace,trace_moving_window)

    m_trace = movmean(current_trace,trace_moving_window);
    upper_trace = current_trace;
    % replace the part below moving average with moving average
    %idx = find(upper_trace<m_trace);
    %upper_trace(idx)=m_trace(idx);
    upper_trace = max(upper_trace, m_trace);
end