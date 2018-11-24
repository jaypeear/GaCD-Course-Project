# GaCD-Course-Project
Getting and Cleaning Data course Project

This document describes the files and the steps for making the data tidy.
The organization of the project and the structure of the files are detailed in cook_book.txt .


===========
Algorithm
===========
The code is in the file run_analysis.R.
Assumptions:
------------
   - All data sets files exist
   - The script has at least read permissions to the input files and read/write permissions to the output files/directories
   - The code is using library() calls to load libraries. It is assumed that the packages are installed (dplyr and rlang).

Stages:
-------
0. Preliminary stage -
   - Remove all objects from the R environment (saw some oddities, so clearing all variable in the environment)
   - Setup directory and file names. The files are assumed to be under the <original> directory
   - Create a list of all the file prefixes to process (line24)
1. Merge the training set:
   - Create the <merged> directory if does not exist. (lines 64-68)
   - Utility function <mergeFile> receiving a base file name filename, creates the test and the train
    file names in addition to the unified file name.
    - Delete the unified file (line 40)
    - Use read_file to read the train content and use write_file with no append option to write the content to the unified file
    - Use read_file to read the test content and use write_file with append option to write the content to the unified file
    - The code deletes the content read after writing in order  to reduce memory utilization.
2. Extract only the mean and std measurements : (lines 80 - 93)
      There were 33 avg() and 33 std() columns resulting in 66 columns of the original 561 columns.
    - Read content of the unified file for X_ - the name is stored in the unifiedFiles["X_"] entry.
      Use read.table(filename, sep = "", dec=".", numerals = "no.loss", colClasses = "character") to read.
    - Extract the names vector of the columns from the read object
    - Using grepl on the names vector create 2 logical vectors each having TRUE in the location for mean() and std()
      names location. Logical OR (|) the two vectors to get a Logical vector with TRUE at the position of main or std
    - Using [, <Logical vector>] get the data set with requested variables only
3. Use descriptive activity names for activities. (lines 99 - 107)
    - The file original/activity_labels include the translation between numbers and string description
    - Read the file using read_table as above and get a 2 column table for id and name
    - Read the activity codes that are store in the unified file "y_"  (unifiedFiles["y_"] entry)
    - Use replace() to replace the numbers in the activity codes in the y_ vector with the labels read (line107)
4. Label data with descriptive variable names. The columns get default Vx labels when read from file. Replace them with the
  measurement names that are used in the original data set will be used as column names (lines 120 - 124)
    - Use dplyr library. Create a tabl_df from the list of columns used in stage 2.
    - Extract the resulting names vector and load it to names(<dataset>)
5. Create a tidy dataset with averages by activity and subject per variable. (lines 134 - 148)
   The structure is a data table with 68 columns and 180 rows. The columns are 66 mean and std columns plus
   Activity and Subject grouping variables.
   180 rows as there are 30 subjects with 6 activities each.
    - Read the unified file for the subjects (unifiedFiles["subject_"] entry) into a vectors.
    - cbind() both the y_ vector (stage 3) and the subject_ vector (activity and subject data respectively)
      to the dataset.
    - Group the data by Activity and Subject using group_by()
    - Calculate the averages of the data groups using summarize_all(mean)
    - Write the output file using write_rds()
5. Addition. In here an additional optional file where an observation is reduced from all 66 variables to
   an observation per signal. E.g. per BodyGyro X/Y/Z, mean and std etc. So the structure a set of 17 such signals
   and a table of 180 rows X number of cols varies per signal. (lines 156 - 163)
    - Define a utility functions(x) that selects from the data set in 5 above the Activity and Subject columns
      in addition to the columns that start with the x parameter prefix.
    - Get the 66 column names into a vector. Remove the postfix starting at the first "-" using sub. Using
      unique() get only the prefixes of the column names.
    - Run lapply() on the vector and use the utility function to get the resulting dataset.
    - Replace the default names of the upper level columns with the prefixes
    - Write the file using write_rds()

====================
Loading the Datasets
====================
The datasets (2 options were provided) are under the directory merged and gave the .tds extension.
Loading into R is using read_rds("filename").

=====
Files
=====
The directory structure is the following
  ├── README.md   - Project metadata including explanation of the program to derive the datasets.
  ├── code_book.txt - Tidy dataset structure
  ├── merged - Merged data files from original/data/ test and train (assignment #1)
  │   ├── Inertial\ Signals
  │   │   ├── body_acc_x_unified.txt
  │   │   ├── body_acc_y_unified.txt
  │   │   ├── body_acc_z_unified.txt
  │   │   ├── body_gyro_x_unified.txt
  │   │   ├── body_gyro_y_unified.txt
  │   │   ├── body_gyro_z_unified.txt
  │   │   ├── total_acc_x_unified.txt
  │   │   ├── total_acc_y_unified.txt
  │   │   └── total_acc_z_unified.txt
  │   ├── X_unified.txt
  │   ├── averaged_by_action_by_subject.rds - Tidy data set - main for assignment #5
  │   ├── averaged_by_action_by_subject_by_signal.rds - Tidy data - an option for assignment #5
  │   ├── subject_unified.txt
  │   └── y_unified.txt
  ├── original - The original data provided
  │   ├── README.txt
  │   ├── activity_labels.txt
  │   ├── data
  │   │   ├── README.txt
  │   │   ├── activity_labels.txt
  │   │   ├── features.txt
  │   │   ├── features_info.txt
  │   │   ├── test
  │   │   │   ├── Inertial\ Signals
  │   │   │   │   ├── .......
  │   │   │   ├── X_test.txt
  │   │   │   ├── subject_test.txt
  │   │   │   └── y_test.txt
  │   │   └── train
  │   │       ├── Inertial\ Signals
  │   │       │   ├── ........
  │   │       ├── X_train.txt
  │   │       ├── subject_train.txt
  │   │       └── y_train.txt
  │   ├── features.txt
  │   └── features_info.txt
  └── run_analysis.R - The program to merge the data sets and derive the tidy datasets(s)
