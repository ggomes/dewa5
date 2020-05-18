function [r] = irr_dewa(cf) 

coeff = roots(fliplr(cf)); % Find roots of polynomial
rates = (1./coeff) - 1; % Compute corresponding rates

% Rates are real-valued and positive
ind = find(rates > 0 & abs(imag(rates)) < 1e-6);

if isempty(ind)
    r = nan;
else
    r = rates(ind);
end

end

