##
## Get and Clean Data - course assignment
## 
## Documentation inside and explanations in README.md
##

# Clear  the session data (I've seen )
rm(list = ls(all = TRUE))

library(readr)

fsep <- .Platform$file.sep

dataDir <- "./original/data"
unifiedFilesDir <- file.path(".", "merged")
avgXFileFilename <- file.path(unifiedFilesDir, "averaged_by_action_by_subject.rds")
bySignalAvgXFileFilename <- file.path(unifiedFilesDir, "averaged_by_action_by_subject_by_signal.rdsstr")

## Assumption : 
##   1. All data sets files exist
##   2. The script has at least read permnission to the input files and read/write permissions to the output files/directories
##
subDir <- file.path(unifiedFilesDir, "Inertial Signals")
dataSetNamePrefixes <- c("X_", "y_", "subject_", 
                        "Inertial Signals/total_acc_x_", "Inertial Signals/body_acc_x_", 
                        "Inertial Signals/body_gyro_x_",
                        "Inertial Signals/total_acc_y_", "Inertial Signals/body_acc_y_", 
                        "Inertial Signals/body_gyro_y_",
                        "Inertial Signals/total_acc_z_", "Inertial Signals/body_acc_z_", 
                        "Inertial Signals/body_gyro_z_")


## Assignment #1: Merge the training and the test sets to create one data set
##
## Each data set includes the files in dataSeFiles. The files need to be concatenated in pairs into the output files
mergeFile <- function (filename){
##  file_1 = read.table(filename, sep = "", dec=".", numerals = "no.loss", colClasses = "character")
  
  unifiedFile <- sprintf("%s%s%sunified.txt", unifiedFilesDir, fsep, filename)
  unlink(unifiedFile, recursive = FALSE, force = TRUE)
    
  type <- "train"
  trainFile <- sprintf("%s%s%s%s%s%s.txt", dataDir, fsep, type, fsep, filename, type)
  type <- "test"
  testFile <- sprintf("%s%s%s%s%s%s.txt", dataDir, fsep, type, fsep, filename, type)
  
  content <- read_file(trainFile)
  print(sprintf("INFO: Created <%s>", unifiedFile))
  write_file(content, unifiedFile, append = TRUE)
  rm(content)
  
  content <- read_file(testFile)
  write_file(content, unifiedFile, append = TRUE)
  rm(content)
  
  print(sprintf("INFO: Created <%s>", unifiedFile))
  unifiedFile
} 

mergeFiles <- function(x){
  unifiedFiles <- sapply(x, mergeFile)
}

## Create the unified directory if not exists. Also, delete the specific unified files (keep all lthe rest)
dir.create(subDir, recursive = TRUE, showWarnings = F)
if ( !file.exists(subDir)){
  print(sprintf("ERROR: Failed to delete and create and empty <%s> directory", unifiedFilesDir))
  stop()
}


print("Executing assignment #1: Merging all the files in the dataset")
print("=============================================================")
unifiedFiles <- mergeFiles(dataSetNamePrefixes)
print("")

print("Executing assignment #2: Extract only the neasurments on the mean std")
print("=====================================================================")
# Reading the unified measurments file.
filename = unifiedFiles["X_"]
XFile <- read.table(filename, sep = "", dec=".", numerals = "no.loss") ##, colClasses = "character")

# Extract the columns for mean and std from the code book
filename <- file.path(dataDir, "features.txt")
features <- read.table(filename, sep = "", dec=".", numerals = "no.loss", colClasses = "character")
features <- features$V2
# Create a logical vector indicating the positions of the mean and std values
means <- grepl("-mean\\(\\)", features)
stds <- grepl("-std\\(\\)", features)
stdMeanColumns = stds | means
# Extract the requested columns
XFile <- XFile[, stdMeanColumns]
print(sprintf("Extracted the columns into XFile, # rows: %d, # columns: %d", nrow(XFile), ncol(XFile)))
print("")

print("Executing assignment #3: Use descriptive activity names to name the activities")
print("==============================================================================")
# Reading the unified activities codes.
filename = unifiedFiles["y_"]
activityCodes <- read.table(filename, sep = "", colClasses = "character")
activityCodes <- activityCodes$V1
# Reading the activity labels
filename = file.path(dataDir, "activity_labels.txt")
activityLabels <- read.table(filename, sep = "", dec=".", numerals = "no.loss", colClasses = "character")

# Replace values
yLabels <- replace(activityCodes, TRUE, activityLabels[activityCodes, 2])

print("Modified activity codes to activity labels, head() and tail() below")
print(head(activityCodes))
print(head(yLabels))
print(" === ")
print(tail(activityCodes))
print(tail(yLabels))
print("")

print("Executing assignment #4: Label data set with descriptive variable names")
print("=======================================================================")
# Use the code book variable names. First filter the column names that were used
library(dplyr)
dFeatures <- tbl_df(features)
dFeatures <- filter(dFeatures, stdMeanColumns)
dFeatures <- dFeatures[["value"]]
names(XFile)<- dFeatures

print("Modified the column names of the data set with the names in the code bood. Names following follows:")
print(names(XFile))
print("")

print("Executing assignment #5: Create tidy data set with averages per subject and activity per variable")
print("=================================================================================================")
# Load the subjects data 
# Reading the unified activities codes.
filename = unifiedFiles["subject_"]
subjects <- read.table(filename, sep = "")
subjects <- subjects$V1
# Duplicate XFile
#library(rlang)
avgXFile <- XFile  #duplicate(XFile, shallow = FALSE)
signals <- names(XFile)
#rm(XFile)
# Add Subject and Activity columns
avgXFile <- cbind(avgXFile, Activity = yLabels)
avgXFile <- cbind(avgXFile, Subject = subjects)

avgXFile <- avgXFile %>% group_by(Activity, Subject) %>% summarise_all(mean)

write_rds(avgXFile, avgXFileFilename)
print(sprintf("Created a new data set: File: <%s> [cols: %d, rows: %d] : head for 2 columns following", 
              bySignalAvgXFileFilename, ncol(avgXFile), nrow(avgXFile)))
print(head(avgXFile %>% select("Subject", "Activity", "tBodyAccMag-mean()", "tBodyAccMag-std()"), n=20L))
print(sprintf("I believe the above addreses the assignment and is accessed via: <avgXFile>"))
print(sprintf("I added below one stage further where an observation is broken per signal <features_info.txt>"))

# Function to select only the columns that start with the signal name and the 2 grouping ones
f_selectFrefix <- function(x) {avgXFile %>% select("Subject", "Activity", starts_with(x))}
signals <- sub("-.*$", "", signals)
signals <- unique(signals)
# Apply on every signal
bySignalAvgXFile <- lapply(signals, f_selectFrefix)
# change the names of the list to be the signals
names(bySignalAvgXFile) <- signals
write_rds(bySignalAvgXFile, bySignalAvgXFileFilename)
print(sprintf("Created a new data set file: <%s> -- number of subtables: %d", 
              avgXFileFilename, length(names(bySignalAvgXFile))))
print("Perform: bySignalAvgXFile at the R prompt to see the content")
print("")