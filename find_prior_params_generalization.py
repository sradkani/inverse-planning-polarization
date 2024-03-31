import os
import json
import sys
import numpy as np
import pandas as pd
from scipy.stats import beta
import matplotlib.pyplot as plt


def fit_beta(dist_df):
    # dist_df is a dataframe with two columns: support and probs. We need to use the probs as weight over support values, to generate samples from the distribution
    # Generate samples
    # Removing 0 and 1 from the support
    filtered_support = dist_df[~dist_df['support'].isin([0, 1])]['support']
    filtered_probs = dist_df[~dist_df['support'].isin([0, 1])]['probs']
    filtered_probs = filtered_probs / filtered_probs.sum()  # Normalizing probabilities

    num_samples = 10000
    samples = np.random.choice(filtered_support, size=num_samples, p=filtered_probs)

    # Fit the beta distribution
    a, b, loc, scale = beta.fit(samples, floc=0, fscale=1)

    return samples, a, b, loc, scale

def plot_beta_fits(samples, a, b, loc, scale, var_name, log_dir):
    x = np.linspace(loc, loc+scale, 100)
    y = beta.pdf(x, a, b, loc, scale)

    # alpha_target is a beta distribution, but in the range [-0.5, 0.5], so we need to shift the beta samples and fit to [-0.5, 0.5] before plotting
    if var_name == "alpha_target": 
        samples = samples - 0.5
        x = x - 0.5

    plt.plot(x, y, 'r-', lw=2, label='fitted beta distribution')
    plt.hist(samples, density=True, bins=30, alpha=0.5, label='generated samples histogram')
    plt.legend()

    # save the plot in log_dir
    file_path = os.path.join(log_dir, f"{var_name}.png")
    plt.savefig(file_path)

    # Optionally, close the plot if you don't want it to show up in a notebook or GUI
    plt.close()
    

directory = sys.argv[1]
scenario = sys.argv[2]
simulation_condition = sys.argv[3]   
job_ID = sys.argv[4]   
last_epoch = sys.argv[5]  
last_action = sys.argv[6]

log_dir = f"{directory}/{scenario}/{simulation_condition}-generalization/ID_{job_ID}/epoch_1/config"
posterior_dir = f"{directory}/{scenario}/{simulation_condition}/ID_{job_ID}/epoch_{last_epoch}/posteriors/{last_action}"
file_names = [filename for filename in os.listdir(posterior_dir) if filename.startswith("alpha_")]

tmp_df = pd.DataFrame({'index': [], 'variable': [], 'beta_a': [], 'beta_b': []})
for fname in file_names: 
    var_name = "_".join(fname.split("_")[0:-3])

    # read the json posterior distribution files 
    dist_df = pd.read_json(f"{posterior_dir}/{fname}")
    
    # alpha_target is a beta distribution, but in the range [-0.5, 0.5], so we need to shift it to [0,1] before fitting the beta distribution to it
    if var_name == "alpha_target":
        dist_df['support'] = dist_df['support'] + 0.5
    
    # find the beta fit parameters
    samples, a, b, loc, scale = fit_beta(dist_df)

    # plot the beta fits to posterior samples and save the plots in log_dir
    
    plot_beta_fits(samples, a, b, loc, scale, var_name, log_dir)

    tmp_df = tmp_df.append({'index': 1, 'variable': var_name, 'beta_a': a, 'beta_b': b}, ignore_index=True)

# convert tmp_df from long to wide format
param_df = tmp_df.pivot(index='index', columns='variable', values=['beta_a', 'beta_b'])

# Flatten the columns and rename
param_df.columns = ['{}_{}'.format(val, var) for val, var in param_df.columns]

# Reset index if needed
param_df.reset_index(drop=True, inplace=True)

# Add the scenario and prior columns as the first and second columns
param_df['simulation'] = f"{simulation_condition}-generalization"
param_df.insert(0, 'simulation', param_df.pop('simulation'))
param_df['scenario'] = scenario
param_df.insert(0, 'scenario', param_df.pop('scenario'))

# Save the prior_params as json file
# convert the entire DataFrame to a list of dictionaries -- this ensures that even for a one-row dataframe the JSON output will always be enclosed in square brackets 
param_df_dict = param_df.to_dict(orient='records')

# open a file to write
with open(f"{log_dir}/prior_params.json", 'w') as file:
    # Convert the list of dictionaries to a formatted JSON string
    json_data = json.dumps(param_df_dict, indent=4)
    file.write(json_data)
