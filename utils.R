

## Function to compare floating-point numbers with a tolerance
is.nearly.equal <- function(x, value, tolerance = .Machine$double.eps^0.5) {
  abs(x - value) < tolerance
}

## Function to preprocess simulation results
prepare_model_data <- function(model_data){
  # take the prior in epoch_1 as the posterior in epoch_0
  epoch_0_data <- model_data %>% filter(epoch=="epoch_1", action=='Prior') %>% 
    mutate(epoch='epoch_0')
  
  processed_model_data <- rbind(epoch_0_data, model_data %>% filter(!(action=='Prior'))) %>%
    mutate(epoch = as.numeric(sub("epoch_", "", epoch))) %>%
    # subtract 0.5 from alpha_target_mean for better interpretability
    mutate(alpha_target_mean = as.numeric(alpha_target_mean - 0.5))
  
  model_data_long_beliefs <- gather(processed_model_data %>% select(!c("content_sd", "alpha_accuracy_sd", "alpha_target_sd")), 
                                    variable, belief, content, alpha_accuracy, alpha_target)
  model_data_long_belief_sds <- gather(processed_model_data %>% select(!c("content", "alpha_accuracy", "alpha_target")), 
                                       variable, belief_sd, content_sd, alpha_accuracy_sd, alpha_target_sd)
  model_data_long_belief_sds$variable <- recode(model_data_long_belief_sds$variable, 
                                                "content_sd"="content", "alpha_accuracy_sd"="alpha_accuracy", "alpha_target_sd"="alpha_target")
  model_data_long <- merge(model_data_long_beliefs, model_data_long_belief_sds, by=c("scenario", "condition", "epoch", "alpha0", "beta", "gamma", 
                                                                                     "ID", "content_mean", "content_variance",
                                                                                     "alpha_accuracy_mean", "alpha_accuracy_variance", 
                                                                                     "alpha_target_mean", "alpha_target_variance",
                                                                                     "action", "action_prob", "variable"))
  model_data_long$variable <- recode(model_data_long$variable, "alpha_accuracy"="Accuracy", "alpha_target"="Bias", "content"="Perspective truth")
  model_data_long$variable <- factor(model_data_long$variable, levels=c("Perspective truth", "Accuracy", "Bias"))
  
  return(model_data_long)
}

## Function to calculate belief polarization for each simulation and epoch
calculate_polarization <- function(model_data, differing_belief_col, shared_beliefs_cols){
  # calculate the difference between beliefs of two groups differing initially on only one belief while sharing everything else (i.e., merge_by_cols)
  belief_values <- sort(unique(model_data[[differing_belief_col]]), decreasing=TRUE)
  groups_dfs_list <- lapply(belief_values, function(x) model_data[model_data[[differing_belief_col]] == x, ])
  
  polarization_model_data <- merge(groups_dfs_list[[1]], groups_dfs_list[[2]], 
                                   by=c(shared_beliefs_cols, c("scenario", "condition", "alpha0", "beta", "gamma", "epoch", "action", "variable"))) %>%
    mutate(belief_polarization = belief.x - belief.y,
           absolute_belief_polarization = abs(belief_polarization))
  
  return(polarization_model_data)
}

###########################
### Plotting functions ####
###########################

plot_heatmaps <- function(data, var_name, fill_color, x_var, y_var, row_var, differing_belief, shared_belief){
  upper_limit <- 1.0
  if(var_name=="Bias"){
    upper_limit <- 0.55
  } else if(var_name=="Perspective truth"){
    upper_limit <- 0.65
  }
  
  # making heatmaps of var_name polarization as a function of x_var and y_var
  sub_fig <- ggplot(data %>% filter(variable==var_name), 
                    aes(x = factor(!!sym(x_var)), y = factor(!!sym(y_var)), fill=absolute_belief_polarization)) +
    geom_tile() + 
    scale_fill_gradient(low="white", high=fill_color,
                        limits = c(0, upper_limit), 
                        guide = guide_legend(title = "Belief \npolarization")) +
    # theme_ipsum() + 
    theme_bw() +
    theme(panel.border = element_blank(), 
          panel.grid.major = element_blank(), 
          axis.text = element_text(size = 16), 
          plot.title = element_text(size = 16, face = 'bold'), 
          axis.title = element_text(size=16, face = 'bold'),
          strip.text.y = element_text(size = 16),
          legend.text = element_text(size = 12), 
          legend.title = element_text(size = 14)) + 
    # scale_x_continuous(breaks = seq(from = floor(min(model_data_long$epoch)), to = ceiling(max(model_data_long$epoch)), by = 1)) + 
    # theme(text = element_text(size = 16), legend.key.width = unit(2, "cm")) +
    # axis_settings + 
    xlab(paste(differing_belief, "uncertainty")) +
    ylab(paste(shared_belief, "mean")) + 
    ggtitle(var_name) + 
    facet_grid(rows = vars(!!sym(row_var))) 
  
  return(sub_fig)
}

plot_belief_evolution_subfigs <- function(data, var_name, line_color, differing_belief_col){
  if(var_name=="Bias"){
    y_lim <- c(-0.6,0.6)
    x_label <- "Debunking actions"
    axis_settings <- theme(axis.text.x = element_text(angle = 0, hjust = 1),
                           axis.ticks.x = element_line())
  } else {
    y_lim <- c(-0.1,1.1)
    x_label <- ""
    # For other variables, hide x-axis ticks and labels
    axis_settings <- theme(axis.text.x = element_blank(),
                           axis.ticks.x = element_blank())
  }
  
  sub_fig <- ggplot(data %>% filter(variable==var_name), 
                    aes(x=epoch, y=belief)) +
    # plotting model data
    geom_hline(yintercept=0, linetype="dashed", color = "darkgrey") +
    geom_line(aes(group=factor(!!sym(differing_belief_col)), linetype=factor(!!sym(differing_belief_col))), linewidth=1, alpha=1, color=line_color) + 
    geom_ribbon(aes(ymin=belief-belief_sd, ymax=belief+belief_sd, group=factor(!!sym(differing_belief_col))), alpha=0.2, fill=line_color) +
    scale_linetype_manual(values=c("longdash", "solid", "dashed", "dotted")) + 
    scale_x_continuous(breaks = seq(from = floor(min(data$epoch)), to = ceiling(max(data$epoch)), by = 1)) + 
    theme_bw() + 
    theme(axis.text = element_text(size = 12), 
          plot.title = element_text(size = 16, face = 'bold'), 
          axis.title = element_text(size=16), 
          strip.text.y = element_text(size = 16),
          legend.key.width = unit(2, "cm")) +
    # axis_settings + 
    xlab(x_label) +
    ylab("Belief") + 
    ylim(c(y_lim[1],y_lim[2])) + 
    guides(fill="none", color="none", linetype="none") + 
    facet_grid(rows = vars(variable))
  
  return(sub_fig)
}

plot_belief_evolution <- function(data, title){
  subfig1 <- plot_belief_evolution_subfigs(data, "Perspective truth", "brown", "content_mean")
  subfig2 <- plot_belief_evolution_subfigs(data, "Accuracy", "blue3", "content_mean")
  subfig3 <- plot_belief_evolution_subfigs(data, "Bias", "grey30", "content_mean")
  
  title_plot1 <- ggplot() + 
    theme_void() + 
    annotate("text", x = 0, y = 0, label = title, size = 8, fontface = "bold")
  fig <- ggarrange(title_plot1, subfig1, subfig2, subfig3, nrow=4, heights = c(1.5, 5, 5, 5), widths=c(5, 5, 5, 6))
  return(fig)
}

plot_belief_polarization_relationship <- function(data, x_var, y_var, fill_var, fill_color, xlabel, ylabel, legend){
  # Prepare symbols for the variable names
  x_sym <- sym(x_var)
  y_sym <- sym(y_var)
  fill_sym <- sym(fill_var)
  
  # making scatter plot of x_var vs y_var polarization
  sub_fig <- ggplot(data, aes(x = !!x_sym, y = !!y_sym, color = !!fill_sym)) +
    geom_vline(xintercept=0.6, color="grey10", linetype="dashed") + 
    geom_point(size=3) + 
    scale_color_gradient(low = "grey90", high = fill_color,
                         limits = c(0, max(data[[fill_var]], na.rm = TRUE)),
                         guide = guide_legend(title = legend)) +
    theme_bw() +
    theme(panel.grid.major = element_blank(), 
          axis.text = element_text(size = 12), 
          plot.title = element_text(size = 16, face = 'bold'), 
          axis.title = element_text(size = 16, face = 'bold'),
          legend.title = element_text(size = 16, face = 'bold'),
          legend.text = element_text(size = 14)) + 
    xlab(xlabel) +
    ylab(ylabel)
  
  return(sub_fig)
}


 plot_generalization_polarization <- function(data, x_var, y_var, fill_var, fill_color, xlabel, ylabel, legend){
  # Prepare symbols for the variable names
  x_sym <- sym(x_var)
  y_sym <- sym(y_var)
  fill_sym <- sym(fill_var)
  
  # making scatter plot of x_var vs y_var polarization
  sub_fig <- ggplot(data, aes(x = !!x_sym, y = !!y_sym, color = !!fill_sym)) +
    geom_point(size=3) + 
    # geom_text(aes(label=ID.y), vjust = -0.5, size = 1.8, color="black") +       # Uncomment if you want to see the simulation IDs for each data point
    scale_color_gradient(low = "grey90", high = fill_color,
                         limits = c(0, max(data[[fill_var]], na.rm = TRUE)),
                         guide = guide_legend(title = legend)) +
    theme_bw() +
    theme(panel.grid.major = element_blank(), 
          axis.text = element_text(size = 14), 
          plot.title = element_text(size = 16, face = 'bold'), 
          axis.title = element_text(face = 'bold', size=14),
          legend.title = element_text(face='bold', size=14),
          legend.text = element_text(size = 14),) + 
    xlab(xlabel) +
    ylab(ylabel)
  
  return(sub_fig)
}






