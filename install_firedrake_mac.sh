#!/bin/bash

################################################################################################
# FIREDRAKE INSTALLATION SCRIPT FOR MAC
# Installs firedrake using pip and other dependancies using pyenv inside homebrew. Outputs .bash_profile script which can be used to activate Firedrake or anaconda environments.
# Last updated: 08/04/25
# Created by: Dilaksan Thillaithevan & Ryan Murphy
################################################################################################

################################################################################################
# USAGE:
# 1. Place installation script (e.g. `install_firedrake_mac.sh`) in `$HOME`
# 2. OPTIONAL - Modify/create `requirements.txt` with additional pip modules to be installed (e.g. `jax`)
#    - By default the script will install the following modules:
#      	- `gmsh`
#     	- `meshio`
#     	- `h5py`
#     	- `matplotlib`
#     	- `siphash24`
# 3. Run `source install_firedrake_XXX.sh` in terminal - NOTE: you can also call `source install_firedrake_XXX.sh --env_name <your_chosen_env_name>` to specify a custom environment name or reinstall a previous installation.
# 	- This will install firedrake and its dependancies and any additional libraries
# 	- The firedrake environment will be created in `$HOME/pythonEnvironments/firedrake_DD_MM_YYYY`, this is where all the files will be placed
# 4. Ensure installation completed with no error messages. Carefully scroll through the output to make sure there are no errors, the script will complete even if errors occur!
# 5. A `.bash_profile` file should be added to your home directory
# 6. To activate the virtual environment run `source .bash_profile firedrake_DD_MM_YYYY`
#    - Note that the date will be fixed, so use the same date when activating on a future date!
#    - If you used `--env_name` option then use the environment name that you specified
# 8. When the firedrake venv is active you should see the terminal line should start with "(venv)" where venv is the name of your virtual environment (e.g. firedrake_01_01_2025)
# 9. To test firedrake has been installed correctly you can run `python -c 'import firedrake'` in the terminal, this should raise no errors

################################################################################################

################################################################################################
### GENERAL INSTALLATION NOTES:
# - Place the installation script in your home (`cd $HOME`) directory
# - Modify the top of the installation script
# - NOTE that Firedrake can take over an hour to install!

#  ### PETSc
#   - PETSc is installed inside `$PETSC_PATH` (`$HOME/pythonEnvironments`)
#   - This means the same PETSc build can be used for multiple Firedrake venv's and avoids the need for repeated PETSc rebuilding

# ### NOTES FOR INSTALLING IPOPT
# - To install IPOPT you need to download and unzip the conhsl.zip file and move it to your home directory

# ### NOTES FOR MAC
# - Firedrake does not currently work with Xcode 16 on Mac. You may need to downgrade your Xcode version to install correctly. Use the following steps:
# 	1. Go to [xcode releases](https://xcodereleases.com/)
#     2. Download version 15.4
#     3. Install xcode
#     4. Place xcode app in `/Applications` and rename app to `Xcode_15_4.app` (change 15_4 to version being used and ensure this matches the version set in installation script)
#     5. `sudo xcode-select --switch /path/to/downloaded/Xcode_15_4.app` (NOTE: path needs to be modified)

################################################################################################


################################################################################################
#### MAIN OPTIONS (MODIFY AS REQUIRED) ####
export INSTALL_PETSC=true
export INSTALL_IPOPT=true
export INSTALL_SPYDER=true
export REMOVE_OLD_PYENV=false
export INSTALL_PYENV_VERSION=false
export UPDATE_BREW=false
export XCODE_VERSION="15_4" # XCode version - Xcode should be in /Applications folder with the version as suffix e.g. "Xcode_15_4.app"
export INSTALL_PIP_LIBRARIES=true

#### ADDITIONAL PIP MODULES ####
pip_libraries=(
    "gmsh"
    "meshio"
    "h5py"
    "matplotlib"
    "siphash24"
)

#### MAIN DIRECTORIES (MODFIY AT OWN RISK) ####
export HOME_PATH="$HOME"
export PYTHON_ENVS_PATH="$HOME_PATH/pythonEnvironments"
export PETSC_PATH="$PYTHON_ENVS_PATH/PETSc"
export current_date=$(date +'%d_%m_%Y')
export ENV_NAME="firedrake_$current_date"
export BASH_PROFILE_NAME=".bash_profile"
export BASH_PROFILE_PATH="${PWD}/${BASH_PROFILE_NAME}"
export CWD=$PWD

#### Python version to be installed (MODFIY AT OWN RISK) ####
export IPOPT_VERSION=3.12.11
export PY_version="3.12.0"
################################################################################################

################################################################################################

################################
# Homebrew  & bash functions
################################
setup_homebrew() {
    echo '\n********************************************'
    echo "Setting up homebrew...."
    echo '********************************************'
    eval "$(/opt/homebrew/bin/brew shellenv)"

    if [[ $? != 0 ]] ; then
        # Install Homebrew
        echo 'brew not installed'
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        if [ "$UPDATE_BREW" = true ] ; then
            echo 'brew installed, updating installation'

            # Spyder update is incredibly slow and I am impatient..
            brew pin spyder

            brew update
            brew upgrade
            brew cleanup --prune=all
        fi
    fi
    echo '\n********************************************'
    echo "Homebrew setup complete!"
    echo '********************************************'
}

init_homebrew() {
    eval "$(/opt/homebrew/bin/brew shellenv)"
    export PYENV_ROOT="$HOME/.pyenv"
    command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
}

setup_bash_profile() {
    echo '\n********************************************'
    echo "Resetting bash_profile"
    echo '********************************************'
    
    cp $BASH_PROFILE_PATH ${BASH_PROFILE_PATH}_back_up_${current_date}
    truncate -s 0 $BASH_PROFILE_PATH

    # Add homebrew to bash_profile
    echo '\n********************************************'
    echo "Adding homebrew to bash profile"
    echo '********************************************'

    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> $BASH_PROFILE_PATH
    source $BASH_PROFILE_PATH
}

initialise_pyenv(){
    # Remove old pyenv
    if [ "$REMOVE_OLD_PYENV" = true ] ; then
        if [ -d "$HOME/.pyenv" ]; then
          echo "Removing existing pyenv installation"
          echo ""
          rm -rf $HOME/.pyenv
          brew uninstall pyenv
        fi

    fi

    if ! command -v pyenv &> /dev/null
    then
        echo "pyenv is not installed. Installing pyenv..."
        install_pyenv
    fi


    # Initialise pyenv
    export PYENV_ROOT="$HOME/.pyenv"
    command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"


    # Install python version
    if [ "$INSTALL_PYENV_VERSION" = true ] ; then
        echo "Installing python version $PY_version"
        echo ""
        pyenv install $PY_version
    fi

    # Set global pyenv to current python version
    echo "Setting pyenv versions to ${PY_version}"
    pyenv global $PY_version
    pyenv shell $PY_version
}


save_env_vars() {
    #### Save variables to file ####
    {
        echo "FULL_IPOPT_PATH=${FULL_IPOPT_PATH}"
        echo "XCODE_VERSION=${XCODE_VERSION}"
        echo "FIREDRAKE_PATH=$FIREDRAKE_PATH"
        echo "PYTHON_ENVS_PATH=$PYTHON_ENVS_PATH"
        echo "VENV_NAME=$VENV_NAME"
        echo "ENV_NAME=$ENV_NAME"
        echo "PETSC_DIR"="$PETSC_PATH/petsc"
    } > $INSTALLATION_PATH/variables.txt

}

update_bash_profile() {
    # delete contents of ~/.bash_profile
    truncate -s 0 $BASH_PROFILE_PATH

    echo 'deactivate
    conda deactivate

    export OMP_NUM_THREADS=1

    # export installation_path='$installation_path >> $BASH_PROFILE_PATH
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> $BASH_PROFILE_PATH


    echo 'if [ $# -eq 0 ];
    then
        echo "No argument supplied. Either specify "anaconda" or firedrake environment to be activated."
        echo "List of valid firedrake environments:"
        ls -w1 '"$PYTHON_ENVS_PATH"'
        exit 0

    else

        if [ $1 = "anaconda" ]
        then

            __conda_setup="$(/Users/dt718/anaconda3/bin/conda shell.zsh hook 2> /dev/null)"
            if [ $? -eq 0 ]; then
                eval "$__conda_setup"
            else
                if [ -f "$HOME_PATH/anaconda3/etc/profile.d/conda.sh" ]; then
                    . "$HOME_PATH/anaconda3/etc/profile.d/conda.sh"
                else
                    export PATH="$HOME_PATH/anaconda3/bin:$PATH"
                fi
            fi
            unset __conda_setup

        echo "anaconda paths activated"

        else

            eval "$(/opt/homebrew/bin/brew shellenv)"
            export PYENV_ROOT="$HOME/.pyenv"
            export PATH="$PYENV_ROOT/bin:$PATH"
            if command -v pyenv 1>/dev/null 2>&1; then
             eval "$(pyenv init -)"
            fi
    ' >> $BASH_PROFILE_PATH

    echo '
            source ${HOME}/pythonEnvironments/${1}/variables.txt
        ' >> $BASH_PROFILE_PATH

    echo '
            export PYOP2_CC=$FIREDRAKE_PATH/src/petsc/default/bin/mpicc
            export IPOPTDIR="${FULL_IPOPT_PATH}"
            export IPOPT_PATH="${FULL_IPOPT_PATH}/build"
            export PKG_CONFIG_PATH="${FULL_IPOPT_PATH}/build/lib64/pkgconfig:${FULL_IPOPT_PATH}/build/lib/pkgconfig:${FULL_IPOPT_PATH}/build/share/pkgcon$"
            export PATH="$PATH:${FULL_IPOPT_PATH}/build"
            export LD_LIBRARY_PATH="${FULL_IPOPT_PATH}/build/lib"
            export PETSC_DIR="${PETSC_PATH}/petsc"

            echo "firedrake paths activated"
            sudo xcode-select -switch /Applications/Xcode_${XCODE_VERSION}.app
            
            pyenv global $PY_version

            . $FIREDRAKE_PATH/bin/activate

            echo "Firedrake environment activated"

        fi

    fi' >> $BASH_PROFILE_PATH
}

make_paths() {
    # Create folder for python environments
    if [ ! -d "$PYTHON_ENVS_PATH" ]; then
        mkdir $PYTHON_ENVS_PATH
        cd $PYTHON_ENVS_PATH
    fi

    # Create environment folder
    cd $PYTHON_ENVS_PATH

    if [ ! -d "$ENV_NAME" ]; then
        mkdir $ENV_NAME
        cd $ENV_NAME
    else
        echo "Environment path ${INSTALLATION_PATH} already exists."
    fi

}

################################
# Installation functions
################################
install_firedrake() {
    echo '\n********************************************'
    echo "Starting Firedrake installation process...."
    echo '********************************************'

    cd $INSTALLATION_PATH

    if [ -d "$FIREDRAKE_PATH" ]; then
        # read -p "_install_firedrakeiredrake installation already exists. Do you want to overwrite it? (y/n): " choice
        echo -n "Firedrake installation already exists. Do you want to overwrite/upgrade it? (y/n): "
        read choice
        case "$choice" in
            y|Y )
                echo -n "Do you want to upgrade Firedrake? (y=upgrade, n=overwrite): "
                read choice
                case "$choice" in
                    y|Y )

                        echo "Updating Firedrake installation"

                        _update_firedrake

                        ;;
                    n|N )
                        echo "Overwriting Firedrake installation...."
                        _install_firedrake
                        ;;
                    * )
                        echo "Invalid input. Using existing Firedrake installation..."
                        ;;
                esac    

                ;;
            n|N )
                echo "Using existing Firedrake installation..."

                activate_firedrake

                ;;
            * )
                echo "Invalid input. Using existing Firedrake installation..."
                ;;
        esac
    else
        echo "No previous installation of Firedrake found."

        _install_firedrake

    fi

    echo '\n**********************************************'
    echo "Firedrake installation process completed!"
    echo '********************************************'
}

_update_firedrake() {

    export $(python3 firedrake-configure --show-env)
    export PETSC_DIR="$PETSC_PATH/petsc"
    pip install --upgrade git+https://github.com/firedrakeproject/firedrake.git

}

_install_petsc() {
    echo '\n********************************************************'
    echo "Installing PETSc"
    echo '************************************************************'
    echo "Installation path: $INSTALLATION_PATH/petsc"

    git clone --depth 1 --branch $(python3 $INSTALLATION_PATH/firedrake-configure --show-petsc-version) https://gitlab.com/petsc/petsc.git
    cd petsc

    python3 $INSTALLATION_PATH/firedrake-configure --show-petsc-configure-options | xargs -L1 ./configure

    make PETSC_DIR=$PETSC_PATH/petsc PETSC_ARCH=arch-firedrake-default all

    make check
    echo '\n********************************************'
    echo "PETSc installation process completed!"
    echo '********************************************'

}

update_petsc(){
    cd $PETSC_PATH/petsc
    git pull
    make
    make reconfigure
}

install_petsc() {

    if [ ! -d "$PETSC_PATH" ]; then
        mkdir $PETSC_PATH
    fi

    cd $PETSC_PATH

    if [ -d "petsc" ]; then
        echo -n "PETSc installation already exists. Do you want to overwrite it? (y/n): "
        read choice
        case "$choice" in
            y|Y )
                echo "Overwriting existing PETSc installation..."

                _install_petsc

                ;;
            n|N )
                echo "Using existing PETSc installation..."

                echo -n "Do you want to upgrade PETSc? (y=upgrade, n=dont upgrade): "

                case "$choice" in
                    y|Y )
                        echo "Updating PETSc"

                        update_petsc

                        ;;
                    n|N )
                        echo ""
                        ;;
                    * )
                        echo "Invalid input. Exiting PETSc upgrade."
                        ;;
                esac
                ;;
            * )
                echo "Invalid input. Using existing PETSc installation..."
                ;;
        esac
    else
        echo "No previous installation of PETSc found."

        _install_petsc

    fi
    

}

_install_firedrake() {
    # Uses pip install 
    cd $INSTALLATION_PATH

    # Remove previous firedrake install file
    if [ -d "firedrake-install" ]; then
        rm -rf firedrake-install
    fi

    # Get firedrake configure file
    curl -O https://raw.githubusercontent.com/firedrakeproject/firedrake/master/scripts/firedrake-configure

    rm -rf "$VENV_NAME"
    echo '\n************************'
    echo "Installing Firedrake..."
    echo '************************'

    echo '\n***************************************'
    echo "Installing Firedrake dependendices...."
    echo '***************************************'

    # Install dependencies via Homebrew
    brew install $(python3 firedrake-configure --show-system-packages)

    # Install/upgrade PETSc
    if [ "$INSTALL_PETSC" = true ] ; then
        install_petsc
    fi

    cd $INSTALLATION_PATH

    python3 -m venv $ENV_NAME
    . $FIREDRAKE_PATH/bin/activate

    export $(python3 firedrake-configure --show-env)
    export PETSC_DIR="$PETSC_PATH/petsc"

    pip cache remove petsc4py

    # Install firedrake
    pip install --no-binary h5py "firedrake @ git+https://github.com/firedrakeproject/firedrake.git#[test]"

    firedrake-check

    echo '\n*****************************************************'
    echo "------- END OF FIREDRAKE INSTALLATION!! -------\n\n"
    echo "------- SCROLL UP AND CHECK THERE ARE NO ERROR MESSAGES (WARNINGS ARE 'USUALLY' FINE TO IGNORE) -------\n\n"
    echo '*****************************************************\n'
}


_install_firedrake_old() {
    # Uses firedrake-install 
    cd $INSTALLATION_PATH

    # Remove previous firedrake install file
    if [ -d "firedrake-install" ]; then
        rm -rf firedrake-install
    fi
    curl -O https://raw.githubusercontent.com/firedrakeproject/firedrake/master/scripts/firedrake-install
    rm -rf "$VENV_NAME"
    echo '\n************************'
    echo "Installing Firedrake..."
    echo '************************'

    python firedrake-install --venv-name $VENV_NAME

    echo '\n*****************************************************'
    echo "------- END OF FIREDRAKE INSTALLATION!! -------\n\n"
    echo "------- SCROLL UP AND CHECK THERE ARE NO ERROR MESSAGES (WARNINGS ARE 'USUALLY' FINE TO IGNORE) -------\n\n"
    echo '*****************************************************\n'
}


install_ipopt() {
    if [ "$INSTALL_IPOPT" = true ] ; then
        echo "Starting IPOPT installation procedure......."
        echo "Installing IPOPT inside $IPOPT_PATH"
        echo ""
        # download ipopt installation files

        init_homebrew
        pyenv global $PY_version
        
        activate_firedrake
        
        if [ ! -d "$CWD/coinhsl" ]; then
            if [ ! -f "$CWD/coinhsl.zip" ]; then
                echo "coinhsl zip is not present in ${CWD}. Ensure coinhsl is downloaded and added to ${CWD}.!!"
                exit 0
            else
                echo "coinhsl zip is present in ${CWD} but you need to unzip this prior to installation."
                exit 0
            fi
            
        fi

        if [ ! -d "${IPOPT_PATH}" ]; then
            echo "Creating dir ${IPOPT_PATH}"
            mkdir $IPOPT_PATH
        fi

        cd $IPOPT_PATH

        if [ -d "$FULL_IPOPT_PATH" ]; then
            echo -n "\n\nIPOPT installation already exists. Do you want to overwrite it? (y/n): "
            read choice
            case "$choice" in
            y|Y )
                echo "Overwriting existing IPOPT installation..."

                _install_ipopt

                ;;
            n|N )
                echo "Using existing IPOPT installation..."
                ;;
            * )
                echo "Invalid input. Using existing IPOPT installation..."
                ;;
            esac
        else
            echo "\n\nNo previous installation of IPOPT found."

            echo "Downloading IPOPT....."

            _install_ipopt

        fi

        # append paths to .bash_profile
        echo 'export IPOPT_PATH="${FULL_IPOPT_PATH}/build"' >> $BASH_PROFILE_PATH
        echo 'export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:${FULL_IPOPT_PATH}/build/lib64/pkgconfig:${FULL_IPOPT_PATH}/build/lib/pkgconfig:${FULL_IPOPT_PATH}/share/pkgconfig:${FULL_IPOPT_PATH}/build/lib/pkgconfig"' >> $BASH_PROFILE_PATH
        echo 'export PATH="$PATH:${FULL_IPOPT_PATH}/build"' >> $BASH_PROFILE_PATH
        echo 'export LD_LIBRARY_PATH="${FULL_IPOPT_PATH}/build/lib"' >> $BASH_PROFILE_PATH
        source $BASH_PROFILE_PATH

        init_homebrew
        pyenv global $PY_version
        
        activate_firedrake

        echo '\n*******************************'
        echo "IPOPT INSTALLATION COMPLETE"
        echo '*******************************'

        cd $INSTALLATION_PATH

        if pip show "cyipopt" &> /dev/null; then

            echo -n "\n\ncyipopt is already installed in pip. Do you want to overwrite it? (y/n): "
            read choice
            case "$choice" in
                y|Y )

                    install_cyipopt

                    ;;
                n|N )
                    echo "Using existing cyipopt installation..."
                    ;;
                * )
                    echo "Invalid input. Using existing cyipopt installation..."
                    ;;
                esac
        else
            echo "\n\nNo previous installation of cyipopt found."

            install_cyipopt

        fi

    fi
}

_install_ipopt() {

    cd $INSTALLATION_PATH
    echo '\n***********************'
    echo "Downloading IPOPT....."
    echo '***********************'
    curl -O https://www.coin-or.org/download/source/Ipopt/Ipopt-$IPOPT_VERSION.tgz
    tar -xvf Ipopt-$IPOPT_VERSION.tgz

    # copy HSL libraries
    cp -r $CWD/coinhsl $FULL_IPOPT_PATH/ThirdParty/HSL/coinhsl

    # append paths to .bash_profile
    echo 'export IPOPTDIR="$FULL_IPOPT_PATH"' >> $BASH_PROFILE_PATH
    echo 'export IPOPT_PATH="$FULL_IPOPT_PATH/build"' >> $BASH_PROFILE_PATH

    source $BASH_PROFILE_PATH

    # install ipopt
    mkdir $FULL_IPOPT_PATH/build
    cd $FULL_IPOPT_PATH/build
    echo '\n***********************'
    echo "Installing IPOPT"
    echo '***********************'
    ../configure
    make
    make test
    make install
    cd ../..


}

install_cyipopt() {

    cd $INSTALLATION_PATH

    pip uninstall cyipopt

    git clone git@github.com:mechmotum/cyipopt.git

    cd cyipopt
    echo '\n********************************************'
    echo "Installing cyIPOPT"
    echo '********************************************'

    python setup.py build
    python setup.py install
}

install_pyenv() {
    echo '\n********************************************'
    echo "Installing pyenv..."
    echo '********************************************'
    brew install pyenv

    # Add pyenv init to shell
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> $BASH_PROFILE_PATH
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> $BASH_PROFILE_PATH
    echo 'eval "$(pyenv init --path)"' >> $BASH_PROFILE_PATH
    echo 'eval "$(pyenv init -)"' >> $BASH_PROFILE_PATH

    # Reload shell
    source $BASH_PROFILE_PATH
}

activate_firedrake() {
    . $FIREDRAKE_PATH/bin/activate
}

install_additional_pip_modules() {

    if [ "$INSTALL_PIP_LIBRARIES" = true ] ; then
        echo "Upgrading pip..."
        pip install --upgrade pip

        echo -e "\n\nInstalling other pip modules"
        echo ""

        # Install from requirements.txt if it exists
        if [ -f "${HOME_PATH}/requirements.txt" ]; then
            echo '\n********************************************'
            echo "Installing from requirements.txt..."
            echo '********************************************'
            pip install -r $HOME_PATH/requirements.txt
        fi

        # Install individual libraries if any are specified
        for lib in "${pip_libraries[@]}"; do
            echo '\n********************************************'
            echo "Installing $lib..."
            echo '********************************************'
            pip3 install "${lib}"
        done
    fi

    pip install pre-commit
}

install_spyder() {
    if [ "$INSTALL_SPYDER" = true ] ; then
        #### Install spyder#####
        #### Does not work with XCode 15.
        #### If error is raised during pyqt5 installation download Xcode_14.3.1 from Apple website.
        #### Change Xcode.app to Xcode_14.3.1.app and move to Applications/ . Then start app and make sure Settings -> Locations is set to Xcode 14.3.1
        #### See - https://developer.apple.com/forums/thread/737863
        echo '\n*******************'
        echo "Installing Spyder"
        echo '*******************'
        pip3 install spyder
    fi
}

################################################################################################
# SCRIPT START
################################################################################################

### Prase command line argument
while [[ $# -gt 0 ]]; do
  case $1 in
    --env_name)
      if [ -n "$2" ]; then
        ENV_NAME="$2"
        shift 2
      else
        echo "Error: --env_name requires a non-empty argument"
        exit 1
      fi
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

export INSTALLATION_PATH="$PYTHON_ENVS_PATH/$ENV_NAME"
export VENV_NAME="firedrake"
export FIREDRAKE_PATH="$INSTALLATION_PATH/${ENV_NAME}"
export IPOPT_PATH="$INSTALLATION_PATH"
export FULL_IPOPT_PATH=$IPOPT_PATH/Ipopt-${IPOPT_VERSION}


echo '*******************************************************'
echo "---------- Installing firedrake environment ----------"
echo '*******************************************************'
echo 'Installation path: ${INSTALLATION_PATH}'

cd $HOME_PATH

make_paths 
cd $INSTALLATION_PATH

################################
# Initialise homebrew
################################
# Check if homebrew is installed - if not installs homebrew
setup_homebrew

################################
# Bash profile
################################
setup_bash_profile

################################
# Pyenv
################################
initialise_pyenv

# ################################
# # Download & install firedrake
# ################################
install_firedrake

echo "Activating Firedrake environment"
activate_firedrake

# Reset homebrew & init py version
init_homebrew
pyenv global $PY_version


################################
# Install Pip Modules
################################
activate_firedrake
install_additional_pip_modules

################################
# Install ipopt
################################
install_ipopt

init_homebrew
pyenv global $PY_version

activate_firedrake

################################
# Install Spyder
################################
install_spyder

###########################################################################################################
# END OF INSTALLATIONS
###########################################################################################################


###########################################################################################################
# UPDATE .bash_profile
###########################################################################################################
# Saves env vars to file so it can be read by .bash_profile
save_env_vars

# deactivate Firedrake environment
deactivate

cd $HOME_PATH

update_bash_profile
