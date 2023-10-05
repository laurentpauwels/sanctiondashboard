# Core Code for Sanction Impact Dashboard

## Introduction

This repository contains the core code that reproduces the computations of the online Dashboard https://exposure.trade. 

The code computes an empirical approximation to the costs of trade sanctions. The approximation is empirical, which means it does not rely on a calibrated model and therefore does not rely on a calibration of any elasticity of substitution. We extract from the historical patterns of trade the components that would be set to zero under an embargo. The share of these components in output represents the approximate impact of the sanction. Importantly, the approximation considers the indirect consequences of the embargo, in the sense that it incorporates the forgone activity corresponding to the linkages located downstream and upstream of the embargoed good. The core code of the dashboard reports the forgone value added at sector level, averaged up to the country level, for all parties involved in the trade sanction.


### Citation
If you use this project in your research, please consider citing the following paper:

	Imbs, Jean and Pauwels, Laurent, 2023, 'An Empirical Approximation of the Effects of Trade Sanctions with an Application to Russia', Economic Policy, Forthcoming.

For the complete replication files of the paper, please head to the [sanction repository](https://github.com/laurentpauwels/sanctionpaper).

### Licence
The software and programming provided (.m, .mat, .npy, and .ipynb files) is licensed under [GNU Affero General Public License v3.0](https://www.gnu.org/licenses/agpl-3.0.en.htmll). 

## Prerequisites 
### Software requirements
The software used for replications are:
 - MATLAB Version: 9.14.0.2206163 (R2023a)
 - Python 3.11.5 
	- os
	- zipfile
	- timeit
	- scipy
	- pandas (2.0.1)
	- numpy (1.24.3)

	For the full python requirements check *Requirements.txt* in the `/python` folder.
	
## Data

### Access
The processed data are available to download from the [Google Drive](https://drive.google.com/drive/folders/1_SH2RaFT4RN5Mwa2SYWzUfHm8LzAU2WK?usp=share_link) folders `/sanctiondashboard/matlab/data` and `/sanctiondashboard/python/data`. Make sure to place the downloaded `data` folder within the `matlab` and `python` folder respectively. 

### Sources
The data are from the following sources:

- OECD Inter-Country Input-Output (ICIO) data (November 2021, downloaded 2 July 2023) 
	- Source: OECD-ICIO 2021 release data is available at <http://oe.cd/icio>

- WIOD Socio-Economic Accounts (SEA) data (2016 release, downloaded 30 May 2023)
	- Source: <https://www.rug.nl/ggdc/valuechain/wiod/wiod-2016-release>

All the data parsing and preprocessing are done in MATLAB. In this repository, we provide the processed data as indicated above. 

### Cleaning
If you need access to the raw data manipulations, please head to [sanction repository](https://github.com/laurentpauwels/sanctions). It contains all the replication files for Imbs and Pauwels (2023, Economic Policy) including all data manipulations. 

Look for `matlab/processData.m` and the scripts that parse and pre-process the ICIO21 and SEA16 data (`processICIO21.m` and `processSEA16.m`). Processing the ICIO21 and WIOT16 data requires two functions (in `/matlab/functions`): `idExtract.m` and  `netInventCorrect.m`. 

NOTE: `matlab/scripts/convertMatlabStruc2data.m` converts *MATLAB v7.3* format ("structure data") to an updated format without structure for compatibility with other software. The `.mat` files provided here are not "structured".

### Provided
The processed ICIO21 data are stored into separate `icio21_data.mat` in `/matlab/data` and `icio21_data.npy` in `/python/data`. The datasets contain

1. the meta data, i.e., the information about the structure of the numerical data such as lists of 
	- countrycode, 
	- countries, 
	- industrycode, 
	- industries,
	- years (year coverage), 
	- finalcat (name of final demand categories in F), 

2. the numerical data contains the IO data in 
	- Z is the intermediate input-outputs (IO) for the above listed industries (R), countries (N), and years (T). Its structure is 3-dimensionsal: (NxR)x(NxR)xT. 
	- F is the final demand data for the same countries, industries and years. Its structure is 3-dimension: (NxR)x(NxC)xT. The columns are NxC where C are the number of final demand categories.

We also provide `alpha.mat` and `alpha.npy` which contains parameter `alpha_r` used in the code to approximate the real value added response to sanctions. It comes from WIOD SEA16 data which is available as `sea16_data.mat` in `/matlab/data`. It contains 16 variables covering the Socio-Economic indictors of WIOD. Note that the country, industry, and year coverage is not the same as ICIO21. See the `/matlab/doc/WIODvsICIO_Industries.xlsx` file for more information. `runConcordanceAlpha.m` is a script that runs the concordance so that the two database's country, industry, and year coverages match. The output of the script is  `alpha.mat`.
  
NOTE: MATLAB `.mat` files are converted to `.npy` data files with `convertMat.py`.


## Instructions


The MATLAB master file `runSanctionCode.m` and Python master file `runSanctionCode.py` computes the real value added impact of trade sanctions by a set of countries on another country's industries. For example the 27 EU countries (+UK) sanctioning Russian Energy products. The Downstream impact (response) is the real value added response of Russian sectors due to the sanctions. The Upstream impact (response) is the real value added response of the individual EU countries and sectors (+ UK) from imposing such sanctions with Russia. 

1. MATLAB requires the functions listed here: 
	- `downstreamBan.m` computes HOT for the downstream impact of trade sanctions on the country/ies-sector(s) sanctioned.
	- `upstreamBan.m` computes SHOT for the upstream impact of trade sanctions on the countries imposing the sanctions.
	- `approxResponse.m` calculates the approximate real value added response according to HOT or SHOT.

2. Python `runSanctionCode.py` code contains the same functions as in MATLAB but imbedded in the code as `def`. 

The output are two CSV files in the respective `/matlab/output` and `/python/output` folders. One file records the downstream approximate responses (`table_downstream.csv`) and the other the upstream approximate responses (`table_upstream.csv`). 


## References

OECD (2021), OECD Inter-Country Input-Output Database, http://oe.cd/icio.

Timmer, M. P., Dietzenbacher, E., Los, B., Stehrer, R. and de Vries, G. J. (2015), "An Illustrated User Guide to the World Input-Output Database: the Case of Global Automotive Production" , Review of International Economics, 23: 575-605

## Contact
Laurent Pauwels, email: <laurent.pauwels@nyu.edu> and <laurent.pauwels@sydney.edu.au>

