library(dplyr)
library(gridExtra)
library(tidyverse)
library(ggplot2)
library(ggpubr)
# library(hrbrthemes)


## Load the functions
source("utils.R")

###########################
## Within-Topic simulations
###########################

## Load the data and preprocess
model_data0 <- read.csv("results_Uaccuracy_Utarget/training_All/simulated_results_format0.csv", header = TRUE)
model_data_long <- prepare_model_data(model_data0)

polarization_model_data <- calculate_polarization(model_data_long, differing_belief_col="content_mean", 
                       shared_beliefs_cols = c("content_variance", "alpha_accuracy_mean", "alpha_accuracy_variance", 
                                               "alpha_target_mean", "alpha_target_variance"))

polarization_data_wide <- polarization_model_data %>% 
  filter(epoch == 5) %>%
  dplyr::select(c("epoch", "ID.y",
                  "content_variance", 
                  "alpha_accuracy_mean", "alpha_accuracy_variance", 
                  "alpha_target_mean", "alpha_target_variance", 
                  "variable", "absolute_belief_polarization")) %>%
  mutate(variable = case_when(
    variable == "Perspective truth" ~ "content",
    variable == "Accuracy" ~ "alpha_accuracy",
    variable == "Bias" ~ "alpha_target",
    TRUE ~ variable
  )) %>%
  pivot_wider(names_from = variable, values_from = absolute_belief_polarization, names_glue = "{variable}_polarization")

#################################################################
# Plot the relationship between polarization of different beliefs
#################################################################

fig2 <- plot_belief_polarization_relationship(polarization_data_wide, 
                                                "content_polarization", "alpha_accuracy_polarization", "alpha_target_polarization", 
                                                "grey10", "Perspective polarization", "Accuracy polarization", "Bias \npolarization")

ggsave(paste("plots/belief_polarization_relationships2", ".jpg", sep=""), fig2, width=6.5, height=5)
                                                
######################################
## Investigating individual conditions
######################################
### The two example settings:
# - convergence: certain about high accuracy and impartiality, uncertain content 
# - polarization: uncertain about somewhat-accuracy and impartiality, certain content
data <- model_data_long %>%
  filter(alpha_target_mean == 0, alpha_target_variance == 0.0025, 
         alpha_accuracy_mean == 0.8, alpha_accuracy_variance == 0.0025,
         content_variance == 0.0225)
fig1.1 <- plot_belief_evolution(data, "Convergence")

data <- model_data_long %>%
  filter(alpha_target_mean == 0, alpha_target_variance == 0.0625, 
         alpha_accuracy_mean == 0.5, alpha_accuracy_variance == 0.0625,
         content_variance == 0.0025)
fig1.2 <- plot_belief_evolution(data, "Polarization")

fig1 <- ggarrange(fig1.1, fig1.2, ncol=2, heights = c(5, 5), widths=c(5, 5))
ggsave(paste("plots/convergence_polarization_examples", ".jpg", sep=""), fig1, width=8, height=8)

## Interaction between accuracy value and content uncertainty
# Bias constant and somewhat-certain, high and low accuracy, high and low content uncertainty
data <- model_data_long %>%
  filter(alpha_target_mean == 0, alpha_target_variance == 0.0225, 
         alpha_accuracy_mean == 0.8, alpha_accuracy_variance == 0.0625,
         content_variance == 0.0025)
fig3.1 <- plot_belief_evolution(data, "High accuracy \nCertain perspective")

data <- model_data_long %>%
  filter(alpha_target_mean == 0, alpha_target_variance == 0.0225, 
         alpha_accuracy_mean == 0.8, alpha_accuracy_variance == 0.0625,
         content_variance == 0.0225)
fig3.2 <- plot_belief_evolution(data, "High accuracy \nUncertain perspective")

data <- model_data_long %>%
  filter(alpha_target_mean == 0, alpha_target_variance == 0.0225, 
         alpha_accuracy_mean == 0.2, alpha_accuracy_variance == 0.0625,
         content_variance == 0.0025)
fig3.3 <- plot_belief_evolution(data, "Low accuracy \nCertain perspective")

data <- model_data_long %>%
  filter(alpha_target_mean == 0, alpha_target_variance == 0.0225, 
         alpha_accuracy_mean == 0.2, alpha_accuracy_variance == 0.0625,
         content_variance == 0.0225)
fig3.4 <- plot_belief_evolution(data, "Low accuracy \nUncertain perspective")

fig3 <- ggarrange(fig3.1, fig3.2, fig3.3, fig3.4, ncol=4)

ggsave(paste("plots/accuracy_content_interaction", ".jpg", sep=""), fig3, width=17, height=9)

## Interaction between bias uncertainty and content uncertainty
# Accuracy constant and uncertain, bias in favor, high and low bias uncertainty, high and low content uncertainty
data <- model_data_long %>%
  filter(is.nearly.equal(alpha_target_mean, 0.3) , alpha_target_variance == 0.0025, 
         alpha_accuracy_mean == 0.5, alpha_accuracy_variance == 0.0625,
         content_variance == 0.0025)
fig4.1 <- plot_belief_evolution(data, "Certain bias \nCertain perspective")

data <- model_data_long %>%
  filter(is.nearly.equal(alpha_target_mean, 0.3), alpha_target_variance == 0.0025, 
         alpha_accuracy_mean == 0.5, alpha_accuracy_variance == 0.0625,
         content_variance == 0.0225)
fig4.2 <- plot_belief_evolution(data, "Certain bias \nUncertain perspective")

data <- model_data_long %>%
  filter(is.nearly.equal(alpha_target_mean, 0.3), alpha_target_variance == 0.0625, 
         alpha_accuracy_mean == 0.5, alpha_accuracy_variance == 0.0625,
         content_variance == 0.0025)
fig4.3 <- plot_belief_evolution(data, "Uncertain bias \nCertain perspective")

data <- model_data_long %>%
  filter(is.nearly.equal(alpha_target_mean, 0.3), alpha_target_variance == 0.0625, 
         alpha_accuracy_mean == 0.5, alpha_accuracy_variance == 0.0625,
         content_variance == 0.0225)
fig4.4 <- plot_belief_evolution(data, "Uncertain bias \nUncertain perspective")

fig4 <- ggarrange(fig4.1, fig4.2, fig4.3, fig4.4, ncol=4, heights = c(5, 5, 5, 5), widths=c(5, 5, 5, 5))

ggsave(paste("plots/bias_content_interaction", ".jpg", sep=""), fig4, width=17, height=9)

##############################
## Cross-Topic generalization
##############################

## Load the data and preprocess
generalization_model_data0 <- read.csv("results_Uaccuracy_Utarget/training_All/simulated_results_generalization_format0.csv", header = TRUE)
generalization_model_data_long <- prepare_model_data(generalization_model_data0)

generalization_polarization_model_data <- calculate_polarization(generalization_model_data_long, differing_belief_col="content_mean", 
                                                                 shared_beliefs_cols = c("content_variance", "alpha_accuracy_mean", 
                                                                                         "alpha_accuracy_variance", "alpha_target_mean", 
                                                                                         "alpha_target_variance"))

generalization_polarization_data_wide <- generalization_polarization_model_data %>% 
  filter(epoch == 5 | epoch==0) %>%
  dplyr::select(c("epoch", "ID.y",
                  "content_variance", 
                  "alpha_accuracy_mean", "alpha_accuracy_variance", 
                  "alpha_target_mean", "alpha_target_variance", 
                  "variable", "absolute_belief_polarization")) %>%
  mutate(variable = case_when(
    variable == "Perspective truth" ~ "content",
    variable == "Accuracy" ~ "alpha_accuracy",
    variable == "Bias" ~ "alpha_target",
    TRUE ~ variable
  )) %>%
  pivot_wider(names_from = variable, values_from = absolute_belief_polarization, names_glue = "{variable}_polarization")

# Take the accuracy and bias polarization from epoch 0, and content polarization from epoch 5
generalization_polarization_data_wide <- merge(generalization_polarization_data_wide %>% 
                                  filter(epoch==0) %>%
                                  dplyr::select(c("content_variance", "ID.y",
                                                  "alpha_accuracy_mean", "alpha_accuracy_variance", 
                                                  "alpha_target_mean", "alpha_target_variance", 
                                                  "alpha_accuracy_polarization", "alpha_target_polarization")),
                                  generalization_polarization_data_wide %>% 
                                  filter(epoch==5) %>%
                                  dplyr::select(c("content_variance", "ID.y",
                                                  "alpha_accuracy_mean", "alpha_accuracy_variance", 
                                                  "alpha_target_mean", "alpha_target_variance", 
                                                  "content_polarization")),
                                by=c("content_variance", "ID.y",
                                     "alpha_accuracy_mean", "alpha_accuracy_variance", 
                                     "alpha_target_mean", "alpha_target_variance")) %>%
  dplyr::rename("initial_alpha_target_polarization" = "alpha_target_polarization",
                "initial_alpha_accuracy_polarization" = "alpha_accuracy_polarization")


####################################################
## The statistics on polarization of content beliefs
####################################################

final_content_polarization <- generalization_polarization_model_data %>% 
  filter(epoch==5, variable=="Perspective truth") %>%
  dplyr::select(c("absolute_belief_polarization"))
summary(final_content_polarization)

############################################################################################
## Relationship between polarization of beliefs about authority and new content polarization
############################################################################################

fig5 <- plot_generalization_polarization(generalization_polarization_data_wide, "initial_alpha_accuracy_polarization", "initial_alpha_target_polarization", "content_polarization", 
                     "brown", "Acquired \nAccuracy polarization", "Acquired \nBias polarization", "Perspective \npolarization")                                              

ggsave(paste("plots/generalization/belief_polarization_relationships", ".jpg", sep=""), fig5, width=6.5, height=5)                     
# ggsave(paste("plots/generalization/belief_polarization_relationships2", ".jpg", sep=""), fig5, width=6.5, height=5)

########################################
## Examples chosen from the scatter plot
########################################

# ID = 62
data <- generalization_model_data_long %>%
  filter(ID==62 | ID==62+243)
fig_ID62 <- plot_belief_evolution(data, "ID = 62")
ggsave(paste("plots/generalization/ID-62", ".jpg", sep=""), fig_ID62, width=4, height=8)

# ID = 76
data <- generalization_model_data_long %>%
  filter(ID==76 | ID==76+243)
fig_ID76 <- plot_belief_evolution(data, "ID = 76")
ggsave(paste("plots/generalization/ID-76", ".jpg", sep=""), fig_ID76, width=4, height=8)

# ID = 70
data <- generalization_model_data_long %>%
  filter(ID==70 | ID==70+243)
fig_ID70 <- plot_belief_evolution(data, "ID = 70")
ggsave(paste("plots/generalization/ID-70", ".jpg", sep=""), fig_ID70, width=4, height=8)

# ID = 133
data <- generalization_model_data_long %>%
  filter(ID==133 | ID==133+243)
fig_ID133 <- plot_belief_evolution(data, "ID = 133")
ggsave(paste("plots/generalization/ID-133", ".jpg", sep=""), fig_ID133, width=4, height=8)

# ID = 52
data <- generalization_model_data_long %>%
  filter(ID==52 | ID==52+243)
fig_ID52 <- plot_belief_evolution(data, "ID = 52")
ggsave(paste("plots/generalization/ID-52", ".jpg", sep=""), fig_ID52, width=4, height=8)


# ID = 80
data <- generalization_model_data_long %>%
  filter(ID==80 | ID==80+243)
fig_ID80 <- plot_belief_evolution(data, "ID = 80")
ggsave(paste("plots/generalization/ID-80", ".jpg", sep=""), fig_ID80, width=4, height=8)

# ID = 106
data <- generalization_model_data_long %>%
  filter(ID==106 | ID==106+243)
fig_ID106 <- plot_belief_evolution(data, "ID = 106")
ggsave(paste("plots/generalization/ID-106", ".jpg", sep=""), fig_ID106, width=4, height=8)

######################################################################################################
##################################### Supplementary figures ##########################################
######################################################################################################

#####################
## Plot the heat maps
#####################
## Find content, accuracy and target standard deviation from the variance
polarization_model_data <- polarization_model_data %>% 
  mutate(content_std = sqrt(content_variance), 
         alpha_accuracy_std = sqrt(alpha_accuracy_variance),
         alpha_target_std = sqrt(alpha_target_variance))

## Accuracy-Content interaction 
data <- polarization_model_data %>%
  filter(alpha_target_mean == 0, alpha_target_variance == 0.0225, 
         epoch == 5)

figS3.1 <- plot_heatmaps(data, "Perspective truth", "brown", "content_std", "alpha_accuracy_mean", "alpha_accuracy_std", "Perspective truth", "Accuracy")
figS3.2 <- plot_heatmaps(data, "Accuracy", "steelblue4", "content_std", "alpha_accuracy_mean", "alpha_accuracy_std", "Perspective truth", "Accuracy")
figS3.3 <- plot_heatmaps(data, "Bias", "grey10", "content_std", "alpha_accuracy_mean", "alpha_accuracy_std", "Perspective truth", "Accuracy")

figS3 <- ggarrange(figS3.1, figS3.2, figS3.3, ncol=3, heights = c(5, 5, 5), widths=c(5, 5, 5))

ggsave(paste("plots/supplementary/accuracy_content_interaction", ".jpg", sep=""), figS3, width=15, height=8)

## Bias-Content interaction 
data <- polarization_model_data %>%
  filter(alpha_accuracy_mean == 0.5, alpha_accuracy_variance == 0.0625, 
         epoch == 5)

figS4.1 <- plot_heatmaps(data, "Perspective truth", "brown", "content_std", "alpha_target_mean", "alpha_target_std", "Perspective truth", "Bias")
figS4.2 <- plot_heatmaps(data, "Accuracy", "steelblue4", "content_std", "alpha_target_mean", "alpha_target_std", "Perspective truth", "Bias")
figS4.3 <- plot_heatmaps(data, "Bias", "grey10", "content_std", "alpha_target_mean", "alpha_target_std", "Perspective truth", "Bias")

figS4 <- ggarrange(figS4.1, figS4.2, figS4.3, ncol=3, heights = c(5, 5, 5), widths=c(5, 5, 5))

ggsave(paste("plots/supplementary/bias_content_interaction", ".jpg", sep=""), figS4, width=17, height=8)

######################################
## Investigating individual conditions
######################################

## Interaction between bias uncertainty and content uncertainty depends on bias value
# Accuracy constant and uncertain, bias against, high and low bias uncertainty, high and low content uncertainty
data <- model_data_long %>%
  filter(is.nearly.equal(alpha_target_mean, -0.3) , alpha_target_variance == 0.0025, 
         alpha_accuracy_mean == 0.5, alpha_accuracy_variance == 0.0625,
         content_variance == 0.0025)
figS2.1 <- plot_belief_evolution(data, "Certain bias \nCertain perspective")

data <- model_data_long %>%
  filter(is.nearly.equal(alpha_target_mean, -0.3), alpha_target_variance == 0.0025, 
         alpha_accuracy_mean == 0.5, alpha_accuracy_variance == 0.0625,
         content_variance == 0.0225)
figS2.2 <- plot_belief_evolution(data, "Certain bias \nUncertain perspective")

data <- model_data_long %>%
  filter(is.nearly.equal(alpha_target_mean, -0.3), alpha_target_variance == 0.0625, 
         alpha_accuracy_mean == 0.5, alpha_accuracy_variance == 0.0625,
         content_variance == 0.0025)
figS2.3 <- plot_belief_evolution(data, "Uncertain bias \nCertain perspective")

data <- model_data_long %>%
  filter(is.nearly.equal(alpha_target_mean, -0.3), alpha_target_variance == 0.0625, 
         alpha_accuracy_mean == 0.5, alpha_accuracy_variance == 0.0625,
         content_variance == 0.0225)
figS2.4 <- plot_belief_evolution(data, "Uncertain bias \nUncertain perspective")

figS2 <- ggarrange(figS2.1, figS2.2, figS2.3, figS2.4, ncol=4, heights = c(5, 5, 5, 5), widths=c(5, 5, 5, 5))

ggsave(paste("plots/supplementary/bias_content_interaction_bias_against", ".jpg", sep=""), figS2, width=17, height=9)






