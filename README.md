# Bootstrap-Forecasting

This project provides a generalized framework for forecasting point-in-time probability distributions. 

A sample time-series is block-bootstrapped n-times (100 by default) using the Box-Cox and Loess-based decomposition method. The resulting matrix of n-time series, including the original, is then passed into a parallelized foreach loop which fits an ensemble model using the forecastHybrid package, and forecatss ahead h-steps. The outputs are stored in a list object.

Analysis can then be performed on the forecast distribution for each time period over the forecast horizon. This allows for an in-depth understanding of the
distribution of forecast risks, and allows the user to determine probabilites for particular outcomes within the distributions. 

This method can broadly be considered as a means of modelling uncertainty over a defined forecast horizon.
