function [ChannelOut] = BSCchannel(ChannelIn, Q, ChannelType, ChannelParameter)


    % Check inputs
    if length(size(ChannelIn))>2 || all(size(ChannelIn)~=1)
        error('Invalid "ChannelIn" size'); end

    if ChannelParameter<0, error('Invalid "ChannelParameter"'); end
    switch lower(ChannelType)
        case 'upto'
            if ChannelParameter > length(ChannelIn), error('Invalid "ChannelParameter"'); end
        case 'random'
            if  ChannelParameter>1 || ChannelParameter<0, error('Invalid "ChannelParameter"'); end
        otherwise
            error('Invalid "ChannelType"');
    end

    if any(ChannelIn>Q-1) || any(ChannelIn<0), error('Invalid symbol in "ChannelIn"'); end
    
    lenChannelIn = length(ChannelIn);
    
    % Apply channel to ChannelIn
    switch lower(ChannelType)
            
        case 'random' % every symbol flips with probability epsilon
            if ChannelParameter >1 || ChannelParameter <0
                error('Invalid "ChannelParameter"'); 
            end
            err = rand([1,lenChannelIn])<ChannelParameter;


    end
    ChannelOut = mod(ChannelIn + err,2);
end

