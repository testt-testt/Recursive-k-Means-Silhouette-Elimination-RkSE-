# Recursive k-Means Silhouette Elimination (RkSE):
This code is developed with MATLAB to execute, test and evaluate the algorithm of Recursive k-means Elimination (RKSE).
Recursive k-means Silhouette Elimination (RkSE) is a new unsupervised feature selection algorithm to reduce dimensionality 
for various types of highly dimensional datasets. Where k-means clustering is applied recursively to select the cluster representative features, 
following a unique application of silhouette measure for each cluster and a user-defined threshold as the feature selection or elimination criteria. 

For a more detailed explanation of this algorithm (RkSE), how and why it is used? Please refer to the article written in the link below: 
https://www.preprints.org/manuscript/202008.0254/v1

If you are planning on using this algorithm or the code shown in here, please make sure to cite our paper as the following:
Mallak, A.; Fathi, M. Unsupervised Feature Selection Using Recursive k-Means Silhouette Elimination (RkSE): A Two-Scenario Case Study 
for Fault Classification of High-Dimensional Sensor Data. Preprints 2020, 2020080254 (doi: 10.20944/preprints202008.0254.v1).

Please note that RkSE is evaluated and tested in our previously mentioned research on a hydraulic test rig, multi sensor readings in two different fashions: 
(1) Reduce the dimensionality in a multivariate classification problem using various classifiers of different functionalities. 
(2) Classification of univariate data in a sliding window scenario, where RkSE is used as a window compression method, to reduce the window
dimensionality by selecting the best time points in a sliding window.
