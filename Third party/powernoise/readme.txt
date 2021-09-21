This ZIP file contains software for Matlab for generating noise time
series whose power spectrum scales as a power law with frequency, i.e.
|P(f)|^2 = 1/f^alpha. Special cases include 1/f noise (alpha = 1) and
white noise (alpha = 0). The algorithm generates the appropriate Fourier
domain sequence, with power-law spectral magnitudes and randomised phases.
It then inverts this using the inverse FFT to generate the required time
series. Note that, in order to cope with the degeneracy at f = 0, it sets
the zero frequency component to an amplitude of 1. This guarantees power
law scaling across the whole frequency range (right down to 0Hz), but the
mean of the time series will not be exactly zero.

If you use this code for your research, please cite [1].

References:

[1] M.A. Little, P.E. McSharry, S.J. Roberts, D.A.E. Costello, I.M.
Moroz (2007), Exploiting Nonlinear Recurrence and Fractal Scaling
Properties for Voice Disorder Detection, BioMedical Engineering OnLine
2007, 6:23.

ZIP file contents:

powernoise.m - Matlab code for generating power law noise. Note that this
 requires the signal processing toolbox in order to perform the FFT/IFFT,
 although these are completely generic and could be substituted for a non-
 proprietary implementation. Typing 'help powernoise' shows instructions
 for the routine.
