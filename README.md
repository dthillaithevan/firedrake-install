# firedrake-install
This repository contains a collection of Bash scripts designed to simplify the installation of Firedrake on macOS and Linux systems.

**Last updated: 08/04/25**<br>
**Created by: Dilaksan Thillaithevan & Ryan Murphy** 

# Usage
1. Clone repo: `git clone https://github.com/dthillaithevan/firedrake-install`
2. `cd firedrake-install` 
3. OPTIONAL - Modify/create `requirements.txt` with additional pip modules to be installed (e.g. `jax`)
   - By default the script will install the following modules:
     	- `gmsh`
    	- `meshio`
    	- `h5py`
    	- `matplotlib`
    	- `siphash24`
4. OPTIONAL - Set options inside the installation script (e.g. INSTALL_IPOPT etc.). It is recommended that you set `UPDATE_BREW=true`, `INSTALL_PYENV_VERSION=true`
5. IPOPT - If installing IPOPT, unzip `coinhsl.zip' inside `firedrake-install` 
6. Run `source install_firedrake_XXX.sh` in terminal - NOTE: you can also call `source install_firedrake_XXX.sh --env_name <your_chosen_env_name>` to specify a custom environment name or reinstall a previous installation.
	- This will install firedrake and its dependancies and any additional libraries
	- The firedrake environment will be created in `$HOME/pythonEnvironments/firedrake_DD_MM_YYYY`, this is where all the files will be placed
   - A `.bash_profile` will be created inside `firedrake-install`. This will be used to activate your environment
7. Ensure installation completed with no error messages. Carefully scroll through the output to make sure there are no errors, the script will complete even if errors occur!
8. A `.bash_profile` file should now be added to `firedrake-install`
9. To activate the virtual environment run `cd firedrake-install` -> `source .bash_profile firedrake_DD_MM_YYYY` or `source firedrake-install/.bash_profile firedrake_DD_MM_YYYY`
   - Note that the date will be fixed, so use the same date when activating on a future date!
   - If you used `--env_name` option then use the environment name that you specified
10. When the firedrake venv is active you should see the terminal line should start with "(venv)" where venv is the name of your virtual environment (e.g. firedrake_01_01_2025)
11. To test firedrake has been installed correctly you can run `python -c 'import firedrake'` in the terminal, this should raise no errors


## Mac
`install_firedrake_mac.sh`
- Default installation script for Mac
- Uses pip to install firedrake and dependencies using homebrew

`OLD_install_firedrake_mac.sh`
- Older version of installation script that uses firedrake-install
- No longer recommended

## Linux
`install_firedrake_linux.sh` (has not been recently tested!)
- Default installation script for Mac
- Still uses firedrake-install so may no longer be functional

### GENERAL INSTALLATION NOTES:
- Place the installation script in your home (`cd $HOME`) directory
- Modify the top of the installation script
- NOTE that Firedrake can take over an hour to install!

 ### PETSc
  - PETSc is installed inside `$PETSC_PATH` (`$HOME/pythonEnvironments`)
  - This means the same PETSc build can be used for multiple Firedrake venv's and avoids the need for repeated PETSc rebuilding

### NOTES FOR INSTALLING IPOPT
- To install IPOPT you need to download and unzip the conhsl.zip file and move it to your home directory

### NOTES FOR MAC
- Firedrake does not currently work with Xcode 16 on Mac. You may need to downgrade your Xcode version to install correctly. Use the following steps:
	1. Go to [xcode releases](https://xcodereleases.com/)
    2. Download version 15.4
    3. Install xcode
    4. Place xcode app in `/Applications` and rename app to `Xcode_15_4.app` (change 15_4 to version being used and ensure this matches the version set in installation script)
    5. `sudo xcode-select --switch /path/to/downloaded/Xcode_15_4.app` (NOTE: path needs to be modified)
- You may need to download and install a later version of xcode to keep MacOS happy, but you can have this version installed alongside version 15.4.
