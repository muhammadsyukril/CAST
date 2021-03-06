% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/aoa.R
\name{aoa}
\alias{aoa}
\title{Area of Applicability}
\usage{
aoa(
  newdata,
  model = NA,
  cl = NULL,
  train = NULL,
  weight = NA,
  variables = "all",
  thres = 0.95,
  folds = NULL
)
}
\arguments{
\item{newdata}{A RasterStack, RasterBrick or data.frame containing the data
the model was meant to make predictions for.}

\item{model}{A train object created with caret used to extract weights from (based on variable importance) as well as cross-validation folds}

\item{cl}{A cluster object e.g. created with doParallel. Should only be used if newdata is large.}

\item{train}{A data.frame containing the data used for model training. Only required when no model is given}

\item{weight}{A data.frame containing weights for each variable. Only required if no model is given.}

\item{variables}{character vector of predictor variables. if "all" then all variables
of the model are used or if no model is given then of the train dataset.}

\item{thres}{numeric vector of probability of DI in training data, with values in [0,1].}

\item{folds}{Numeric or character. Folds for cross validation. E.g. Spatial cluster affiliation for each data point.
Should be used if replicates are present. Only required if no model is given.}
}
\value{
A RasterStack or data.frame with the DI and AOA. AOA has values 0 (outside AOA) and 1 (inside AOA).
}
\description{
This function estimates the Dissimilarity Index (DI) and the derived
Area of Applicability (AOA) of spatial prediction models by
considering the distance of new data (i.e. a Raster Stack of spatial predictors
used in the models) in the predictor variable space to the data used for model
training. Predictors can be weighted in the ideal case based on the internal
variable importance of the machine learning algorithm used for model training.
}
\details{
The Dissimilarity Index (DI) and the corresponding Area of Applicability (AOA) are calculated.
If variables are factors, dummy variables are created prior to weighting and distance calculation.

Interpretation of results: If a location is very similar to the properties
of the training data it will have a low distance in the predictor variable space
(DI towards 0) while locations that are very different in their properties
will have a high DI.
To get the AOA, a threshold to the DI is applied based on the DI in the training data.
To calculate the DI in the training data, the minimum distance to an other training point
(if applicable: not located in the same CV fold) is considered.
See Meyer and Pebesma (2020) for the full documentation of the methodology.
}
\examples{
\dontrun{
library(sf)
library(raster)
library(caret)
library(viridis)
library(latticeExtra)

# prepare sample data:
dat <- get(load(system.file("extdata","Cookfarm.RData",package="CAST")))
dat <- aggregate(dat[,c("VW","Easting","Northing")],by=list(as.character(dat$SOURCEID)),mean)
pts <- st_as_sf(dat,coords=c("Easting","Northing"))
pts$ID <- 1:nrow(pts)
set.seed(100)
pts <- pts[1:30,]
studyArea <- stack(system.file("extdata","predictors_2012-03-25.grd",package="CAST"))[[1:8]]
trainDat <- extract(studyArea,pts,df=TRUE)
trainDat <- merge(trainDat,pts,by.x="ID",by.y="ID")

# visualize data spatially:
spplot(scale(studyArea))
plot(studyArea$DEM)
plot(pts[,1],add=TRUE,col="black")

# train a model:
set.seed(100)
variables <- c("DEM","NDRE.Sd","TWI")
model <- train(trainDat[,which(names(trainDat)\%in\%variables)],
trainDat$VW,method="rf",importance=TRUE,tuneLength=1,trControl=trainControl(method="cv",number=5))
print(model) #note that this is a quite poor prediction model
prediction <- predict(studyArea,model)
plot(varImp(model,scale=FALSE))

#...then calculate the AOA of the trained model for the study area:
AOA <- aoa(studyArea,model)
spplot(AOA$DI, col.regions=viridis(100),main="Dissimilarity Index")
#plot predictions for the AOA only:
spplot(prediction, col.regions=viridis(100),main="prediction for the AOA")+
spplot(AOA$AOA,col.regions=c("grey","transparent"))

####
# Calculating the AOA might be time consuming. Consider running it in parallel:
####
library(doParallel)
library(parallel)
cl <- makeCluster(4)
registerDoParallel(cl)
AOA <- aoa(studyArea,model,cl=cl)

####
#The AOA can also be calculated without a trained model.
#All variables are weighted equally in this case:
####
AOA <- aoa(studyArea,train=trainDat,variables=variables)
spplot(AOA$DI, col.regions=viridis(100),main="Dissimilarity Index")
spplot(AOA$AOA,main="Area of Applicability")
}
}
\references{
Meyer, H., Pebesma, E. (2020): Predicting into unknown space?
Estimating the area of applicability of spatial prediction models.
\url{https://arxiv.org/abs/2005.07939}
}
\author{
Hanna Meyer
}
