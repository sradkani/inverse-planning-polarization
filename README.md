# How rational inference about authority debunking can curtail, sustain or spread belief polarization

## Overview

This repository contains the code and configuration files for running simulations, processing the results and making plots for our paper. The simulations can be run in three contexts:

1. **Within-context simulations**
2. **Cross-topic generalization simulations**
3. **Supplementary material (Fig S7) simulations**

The code is designed to run on a cluster, and the simulation parameters are configured through JSON files inside the `general_config` folder.

## Repository Structure

### Main Simulation Files

- [submit_run_model.sh](https://github.com/sradkani/inverse-planning-polarization/blob/main/submit_run_model.sh): The primary file to submit a batch job to the cluster. This script calls `run_simulation_openmind.sh` to execute simulations for job arrays.
- [run_simulation_openmind.sh](https://github.com/sradkani/inverse-planning-polarization/blob/main/run_simulation_openmind.sh): This script retrieves simulation parameters from configuration files in the `general_config` folder. It sets up the simulation based on the `job_ID` and calls `main.wppl` to run the WebPPL model simulations. It saves results in the `results_Uaccuracy_Utarget` folder.
- [main.wppl](https://github.com/sradkani/inverse-planning-polarization/blob/main/main.wppl): The entry point for the WebPPL model simulations. 

### Configurations and Parameter Files

- [general_config](https://github.com/sradkani/inverse-planning-polarization/tree/main/general_config): This folder contains JSON files that store parameters for different simulation scenarios (e.g., prior distributions, action sequences, utilities).
- [array_ID_to_params.py](https://github.com/sradkani/inverse-planning-polarization/blob/main/array_ID_to_prams.py): This file saves the parameters for running each of the simulations, with a given ID. The results are saved in the `general_config` folder.
- [param_selection.ipynb](https://github.com/sradkani/inverse-planning-polarization/blob/main/param_selection.ipynb): This notebook is used for exploring the shape of the prior distributions and the corresponding parameters.

### Generalization and Supplementary Simulations

For **cross-topic generalization simulations**, the corresponding files with "generalization" in their name are used. The primary file to run the simulations is [submit_run_generalization_model.sh](https://github.com/sradkani/inverse-planning-polarization/blob/main/submit_run_generalization_model.sh).

For **supplementary material simulations**, the corresponding files with "supplementary" in their name are used. The primary file to run the simulations is [submit_run_model_supplementary.sh](https://github.com/sradkani/inverse-planning-polarization/blob/main/submit_run_model_supplementary.sh).

### Processing

- [process_model_simulations.py](https://github.com/sradkani/inverse-planning-polarization/blob/main/process_model_simulations.py): After all simulations have been run and saved, this script processes the simulation results and exports them into CSV files for analysis. This file is used for the within-context and supplementary simulations.
- [process_model_simulations_generalization.py](https://github.com/sradkani/inverse-planning-polarization/blob/main/process_model_simulations_generalization.py): This file is used for the cross-topic generalization simulations.

### Plotting

- [plots.R](https://github.com/sradkani/inverse-planning-polarization/blob/main/plots.R): This R script generates plots from the processed simulation results. The plots are saved in the `plots` folder.
- [utils.R](https://github.com/sradkani/inverse-planning-polarization/blob/main/utils.R): This file contains the functions used for making the plots.
