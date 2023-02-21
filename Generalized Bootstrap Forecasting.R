###############################################################################
#                                                                             #
#                       Generalized Bootstrap Forecasting                     #
#                                                                             #
###############################################################################
# Version: 1.0.0 "Pull Yourself Up"                                                            
# Created: 23 June 2021
# Authors: Andrew Kennedy
# Summary: Performs a block bootstrap of a simulated time series n-times 
#          (100 by default). This object is passed forward into a parallelized
#          foreach loop, where for each series, a hybridized time-series model
#          is fitted, and a h-step forward forecast is produced. The point-
#          estimates are stored. 
###############################################################################

############################### 0. Preamble ###################################


options(scipen = 999)

# requirements
packages = (
  c(
    "forecast",
    "forecastHybrid",
    "parallel",
    "doParallel",
    "foreach",
    "doSNOW",
    "tidyr"
    
  )
)



lapply(packages, 
       FUN = function(X) {
         do.call("require", 
                 list(X)) 
       }
)



############################ 1. Some Sample Data ################################
set.seed(101)

# Quarterly production of woollen yarn in Australia
data <- woolyrnq 

autoplot(data)


##### PointForecast - model evluation #####

################### 2, Select models for in-sample estimation ###################

models = "aenstfz"  # swap in/out individual letters

eval_model <- hybridModel(data,
                          models = models,
                          weights="equal",
                          errorMethod = "MAE",
                          horizonAverage = TRUE,
                          verbose = TRUE,
                          n.args = list(repeats = 5))


# Evaluate error                                                    
plot(eval_model)
accuracy(eval_model, individual = TRUE)   # Each model's error
accuracy(eval_model, individual = FALSE)  # ensemble error


# Point forecasts based on above model 
eval_forecast <- forecast::forecast(eval_model,
                                    level= 95, 
                                    fan =TRUE, 
                                    boot = FALSE)

plot(eval_forecast)
eval_forecast

# Once model combination is chosen, you are ready to move on to simulation


############################# 3. Bootstrap Lopp ###################################

### Once model combination is chosen, you are ready to move on to simulation
set.seed(101)

##### Simulation #####
nsim = 10       # number of forward steps for forecast (months)
h <- 100         # number of simulated data points for each future period

# Bootstrap data series h times
sim <- bld.mbb.bootstrap(data, h)

# Set up parallelizaion
nCores <- detectCores() - 1          # Best practice is to subtract one core to avoid crashes
cl <- parallel::makeCluster(nCores)
doParallel::registerDoParallel(cl)



fcasts <- list() #empty list

f<- foreach(i = 1:h,
            .export=c('spread'),
            .packages= c('forecastHybrid',
                         'forecast'
            )) %dopar% {
              fcasts[[i]] = data.frame(forecast::forecast(hybridModel(sim[[i]],
                                                                      models = models,
                                                                      weights="equal",
                                                                      errorMethod = "MAE",
                                                                      horizonAverage = TRUE,
                                                                      verbose = TRUE,
                                                                      parallel = FALSE,
                                                                      n.args = list(repeats = 5)),
                                                          level= 95, 
                                                          fan =FALSE, 
                                                          boot = FALSE))$Point.Forecast}


stopCluster(cl)





# Aggregation and Evaluation
forecasts <- matrix(unlist(f), nrow = h, byrow = TRUE)

# Extract Point Estimates
fcast_median <- apply(forecasts, 2, median)   
fcast_mean <- apply(forecasts, 2, mean)



# Full License quantity with forecast
full_series <- as.numeric(c(data[1:length(data)], fcast_median ))
plot(full_series, type = "l")


#####################################################################################