function [ChannelOut] = asymmchannel(ChannelIn,q,ChannelType,ChannelParameterUp,ChannelParameterDown)
% function [ChannelOut] = asymmchannel(ChannelIn,q,ChannelType,ChannelParameterUp,ChannelParameterDown)
% 
% ASYMMCHANNEL simulates the asymmetric all2one-one2all channel in various methods.
% 
% Input:
%   ChannelIn - A vector of symbols in channel input.
%   q - Alphabet size (symbols are 0,...,q-1).
%   ChannelType - Describes channel simulation method. Possible values:
%       upto - inserts up tp (ChannelParameterUp,ChannelParameterDown) errors.
%       random - inserts (up,down) errors with corresponding probabilities (ChannelParameterUp,ChannelParameterDown).
%   ChannelParameterUp - see description of ChannelType.
% 
% Output:
%   ChannelOut -  A vector of symbols in channel outut.
% 
% Written by Yuval Ben-Hur, 04/08/2021
% 

    % Check inputs
    if length(size(ChannelIn))>2 || all(size(ChannelIn)~=1)
        error('Invalid "ChannelIn" size'); end

    if any([ChannelParameterUp ChannelParameterDown]<0), error('Invalid "ChannelParameter"'); end
    switch lower(ChannelType)
        case 'upto'
            if sum([ChannelParameterUp ChannelParameterDown])>length(ChannelIn), error('Invalid "ChannelParameter"'); end
        case 'random'
            if any([ChannelParameterUp ChannelParameterDown]>1) || any([ChannelParameterUp ChannelParameterDown]<0), error('Invalid "ChannelParameter"'); end
        otherwise
            error('Invalid "ChannelType"');
    end

    if any(ChannelIn>q-1) || any(ChannelIn<0), error('Invalid symbol in "ChannelIn"'); end
    
    wChannelIn = sum(ChannelIn~=0); % # non-zero symbols
    lenChannelIn = length(ChannelIn);
    
    % Apply channel to ChannelIn
    switch lower(ChannelType)
        case 'upto'
            if any([ChannelParameterUp ChannelParameterDown]>lenChannelIn) || any([ChannelParameterUp ChannelParameterDown]<0)
                error('Invalid "ChannelParameter"');
            end
            if wChannelIn<lenChannelIn
                errUp = unique(randi([1,lenChannelIn-wChannelIn],[1,ChannelParameterUp]));
            else 
                errUp = [];
            end
            if wChannelIn>0
                errDown = unique(randi([1,wChannelIn],[1,ChannelParameterDown]));
            else
                errDown = [];
            end
            
        case 'random' % every symbol flips with probability epsilon
            if any([ChannelParameterUp ChannelParameterDown]>1) || any([ChannelParameterUp ChannelParameterDown]<0)
                error('Invalid "ChannelParameter"'); 
            end
            if wChannelIn<lenChannelIn
                errUp = rand([1,lenChannelIn-wChannelIn])<ChannelParameterUp;
            else 
                errUp = [];
            end
            if wChannelIn>0
                errDown = rand([1,wChannelIn])<ChannelParameterDown;
            else
                errDown = [];
            end

    end
    
    % Initialize ChannelOut
    ChannelOut = ChannelIn;

    % Insert errors in zero symbols
    zero2nonzero = find(ChannelIn==0);
    zero2nonzero = zero2nonzero(errUp);
    ChannelOut(zero2nonzero) = randi([1,q-1],[1,length(zero2nonzero)]); % error symbol is 0

    % Insert errors in non-zero symbols
    nonzero2zero = find(ChannelIn~=0);
    nonzero2zero = nonzero2zero(errDown);
    ChannelOut(nonzero2zero) = 0; % error symbol is 0

end

