#!/bin/bash

################################
# NOTE THIS IS NO LONGER THE RECOMMENDED METHOD FOR INSTALLING Firedrake ON Mac. USE install_firedrake_pip_mac.sh INSTEAD

# FIREDRAKE INSTALLATION SCRIPT FOR MAC
# Installs firedrake and other dependancies using pyenv inside homebrew. Outputs .bash_profile script which can be used to activate Firedrake or anaconda environments.
################################

################################
# USAGE:
# 1. Modify this file as required (i.e. chosing which libraries to install) and place in home directory (e.g. /Users/user_name/)
# 2. run "source install_firedrake_mac.sh" in terminal (without "")
#     - This will install firedrake and its dependancies and any additional libraries as listed below
#     - The firedrake environment will be created in pythonEnvironments/firedrake_DD_MM_YYYY, this is where all the files will be placed
# 3. Ensure installation completed, there should be no error messages. Carefully scroll through the output to make sure there are no errors, the script will complete even if errors occur!
# 4. a .bash_profile file should be added to your home directory
# 5. To activate the virtual environment run "source .bash_profile firedrake_DD_MM_YYYY" (note that the date will be fixed, so use the same date when activating on a future date!)
# 6. When the firedrake venv is active you should see the terminal line should start with (firdrake)
# 7. To test firedrake has been installed correctly you can run "python -c 'import firedrake'" in the terminal, this should raise no errors
################################

################################
# NOTES:
# Firedrake:
    # Firedrake does not currently work with Xcode 16 on Mac. You may need to downgrade your Xcode version to install correctly.
    # 1. Go to https://xcodereleases.com/
    # 2. Download version 15.4
    # 3. Install xcode
    # 4. Place xcode app in /Applications and rename app to Xcode_15_4.app
    # 5. sudo xcode-select --switch /path/to/downloaded/Xcode_15_4.app (NOTE: path needs to be modified)
# IPOPT:
    # To install IPOPT you need to download the conhsl.zip file and move it to your home directory.
################################


#### OPTIONS THAT CAN BE MODIFIED ####
export INSTALL_IPOPT=false
export INSTALL_SPYDER=false
export REMOVE_OLD_PYENV=false
export INSTALL_PYENV_VERSION=false
export UPDATE_BREW=false
export XCODE_VERSION="15_4" # XCode version - Xcode should be in /Applications folder with the version as suffix e.g. "Xcode_15_4.app"
export INSTALL_PIP_LIBRARIES=false

# Modules to be installed via pip (excl. cyipopt), these can be modified as needed
pip_libraries=(
    "gmsh"
    "meshio"
    "h5py"
    "smt"
    "git+https://github.com/pvigier/perlin-numpy"
    "torch"
    "matplotlib"
    "siphash24"
)


# MAIN DIRECTORIES
export HOME_PATH="$HOME"
export PYTHON_ENVS_PATH="$HOME_PATH/pythonEnvironments"

export current_date=$(date +'%d_%m_%Y')
export ENV_NAME="firedrake_$current_date"
export BASH_PROFILE_NAME=".bash_profile"

# Python version to be installed - does not need to be modified
export IPOPT_VERSION=3.12.11
export PY_version="3.10.14"



################################
# Installation functions
################################
install_firedrake() {

    cd $INSTALLATION_PATH

    # Remove previous firedrake install file
    if [ -d "firedrake-install" ]; then
        rm -rf firedrake-install
    fi
    curl -O https://raw.githubusercontent.com/firedrakeproject/firedrake/master/scripts/firedrake-install
    rm -rf "$VENV_NAME"
    echo "Installing Firedrake..."
    echo ""

    python firedrake-install --venv-name $VENV_NAME


    echo "------- END OF FIREDRAKE INSTALLATION!! -------\n\n"
    echo "------- SCROLL UP AND CHECK THERE ARE NO ERROR MESSAGES (WARNINGS ARE 'USUALLY' FINE TO IGNORE) -------\n\n"
}

install_ipopt() {

    cd $INSTALLATION_PATH
    echo "Downloading IPOPT....."
    curl -O https://www.coin-or.org/download/source/Ipopt/Ipopt-$IPOPT_VERSION.tgz
    tar -xvf Ipopt-$IPOPT_VERSION.tgz

    # copy HSL libraries
    cp -r $HOME_PATH/coinhsl $FULL_IPOPT_PATH/ThirdParty/HSL/coinhsl

    # append paths to .bash_profile
    echo 'export IPOPTDIR="$FULL_IPOPT_PATH"' >> ~/${BASH_PROFILE_NAME}
    echo 'export IPOPT_PATH="$FULL_IPOPT_PATH/build"' >> ~/${BASH_PROFILE_NAME}

    source ~/${BASH_PROFILE_NAME}

    # install ipopt
    mkdir $FULL_IPOPT_PATH/build
    cd $FULL_IPOPT_PATH/build
    echo "Installing IPOPT"
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

    echo "\n\nInstalling cyIPOPT"

    python setup.py build
    python setup.py install

}

install_pyenv() {
    echo "Installing pyenv..."

    brew install pyenv

    # Add pyenv init to shell
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/${BASH_PROFILE_NAME}
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/${BASH_PROFILE_NAME}
    echo 'eval "$(pyenv init --path)"' >> ~/${BASH_PROFILE_NAME}
    echo 'eval "$(pyenv init -)"' >> ~/${BASH_PROFILE_NAME}

    # Reload shell
    source ~/${BASH_PROFILE_NAME}
}


### Prase command line argument
while [[ $# -gt 0 ]]; do
  case $1 in
    --environment_name)
      if [ -n "$2" ]; then
        ENV_NAME="$2"
        shift 2
      else
        echo "Error: --environment_name requires a non-empty argument"
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
export FIREDRAKE_PATH="$INSTALLATION_PATH/${VENV_NAME}"
export IPOPT_PATH="$INSTALLATION_PATH/ipopt"
export FULL_IPOPT_PATH=$IPOPT_PATH/Ipopt-${IPOPT_VERSION}


echo ''
echo "---------- Installing firedrake environment in ${INSTALLATION_PATH} ----------"
echo ''

cd $HOME_PATH

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

cd $INSTALLATION_PATH


################################
# Setup homebrew
################################
# Check if homebrew is installed - if not installs homebrew
echo "Setting up homebrew...."
eval "$(/opt/homebrew/bin/brew shellenv)"

if [[ $? != 0 ]] ; then
    # Install Homebrew
    echo 'brew not installed'
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    if [ "$UPDATE_BREW" = true ] ; then
        echo 'brew installed, updating installation'

        brew update
        brew upgrade
        brew cleanup --prune=all
    fi
fi
echo "Homebrew setup complete!\n"



################################
# Setup bash profile
################################
# Reset bash_profile
echo "Resetting bash_profile"
echo ""
cp ~/${BASH_PROFILE_NAME} ~/${BASH_PROFILE_NAME}_back_up_${current_date}
truncate -s 0 ~/${BASH_PROFILE_NAME}

# Add homebrew to bash_profile
echo "Adding homebrew to bash profile"
echo ""
(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/${BASH_PROFILE_NAME}
source ~/${BASH_PROFILE_NAME}


################################
# Setup pyenv
################################
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

################################
# Download & install firedrake
################################
echo "Starting Firedrake installation process...."

cd $INSTALLATION_PATH


if [ -d "$VENV_NAME" ]; then
    # read -p "Firedrake installation already exists. Do you want to overwrite it? (y/n): " choice
    echo -n "Firedrake installation already exists. Do you want to overwrite it? (y/n): "
    read choice
    case "$choice" in
        y|Y )
            echo "Overwriting existing Firedrake installation..."

            install_firedrake

            ;;
        n|N )
            echo "Using existing Firedrake installation..."
            ;;
        * )
            echo "Invalid input. Using existing Firedrake installation..."
            ;;
    esac
else
    echo "No previous installation of Firedrake found."

    install_firedrake

fi

echo "Firedrake installation process completed!\n\n"


echo "Activating Firedrake environment"
. $FIREDRAKE_PATH/bin/activate


# Reset homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
pyenv global $PY_version

################################
# Install ipopt
################################
if [ "$INSTALL_IPOPT" = true ] ; then
    echo "Starting IPOPT installation procedure......."
    echo ""
    # download ipopt installation files


    if [ ! -d "$HOME_PATH/coinhsl" ]; then
        echo "coinhsl directory is not present in ${HOME_PATH}. Ensure coinhsl is downloaded and added to ${HOME_PATH}.!!"
        exit 0
    fi

    if [ ! -d "${IPOPT_PATH}" ]; then
        mkdir $IPOPT_PATH
    fi

    cd $IPOPT_PATH


    if [ -d "$FULL_IPOPT_PATH" ]; then
        echo -n "\n\nIPOPT installation already exists. Do you want to overwrite it? (y/n): "
        read choice
        case "$choice" in
        y|Y )
            echo "Overwriting existing IPOPT installation..."

            install_ipopt

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

        install_ipopt

    fi

    # append paths to .bash_profile
    echo 'export IPOPT_PATH="${FULL_IPOPT_PATH}/build"' >> ~/${BASH_PROFILE_NAME}
    echo 'export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:${FULL_IPOPT_PATH}/build/lib64/pkgconfig:${FULL_IPOPT_PATH}/build/lib/pkgconfig:${FULL_IPOPT_PATH}/share/pkgconfig:${FULL_IPOPT_PATH}/build/lib/pkgconfig"' >> ~/${BASH_PROFILE_NAME}
    echo 'export PATH="$PATH:${FULL_IPOPT_PATH}/build"' >> ~/${BASH_PROFILE_NAME}
    echo 'export LD_LIBRARY_PATH="${FULL_IPOPT_PATH}/build/lib"' >> ~/${BASH_PROFILE_NAME}
    source ~/${BASH_PROFILE_NAME}

    eval "$(/opt/homebrew/bin/brew shellenv)"
    export PYENV_ROOT="$HOME/.pyenv"
    command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    pyenv global $PY_version
    . $FIREDRAKE_PATH/bin/activate

    echo "\n\nIPOPT INSTALLATION COMPLETE"

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

eval "$(/opt/homebrew/bin/brew shellenv)"
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
pyenv global $PY_version
. $FIREDRAKE_PATH/bin/activate

if [ "$INSTALL_PIP_LIBRARIES" = true ] ; then
    pip install --upgrade pip

    echo "\n\nInstalling other pip modules"
    echo ""

    for lib in "${pip_libraries[@]}"; do
        echo "\n\nInstalling $lib..."
        pip3 install "${lib}"
    done
fi

pip install pre-commit


if [ "$INSTALL_SPYDER" = true ] ; then
    #### Install spyder#####
    #### Does not work with XCode 15.
    #### If error is raised during pyqt5 installation download Xcode_14.3.1 from Apple website.
    #### Change Xcode.app to Xcode_14.3.1.app and move to Applications/ . Then start app and make sure Settings -> Locations is set to Xcode 14.3.1
    #### See - https://developer.apple.com/forums/thread/737863
    echo "Installing Spyder"
    echo ""
    pip3 install spyder
    # brew install qt5
    # export PATH="/opt/homebrew/opt/qt5/bin:$PATH"
    # python -m ensurepip --default-pip
    # pip install pyqt5-sip
    # pip install pyqt5 --config-settings --confirm-license= --verbose
    # pip install spyder
fi
###########################################################################################################

#### Save variables to file ####
{
  echo "FULL_IPOPT_PATH=${FULL_IPOPT_PATH}"
  echo "XCODE_VERSION=${XCODE_VERSION}"
  echo "FIREDRAKE_PATH=$FIREDRAKE_PATH"
  echo "PYTHON_ENVS_PATH=$PYTHON_ENVS_PATH"
    echo "VENV_NAME=$VENV_NAME"
} > $INSTALLATION_PATH/variables.txt


# deactivate Firedrake environment
deactivate

cd $HOME_PATH

# delete contents of ~/.bash_profile
truncate -s 0 ~/${BASH_PROFILE_NAME}



echo 'deactivate
conda deactivate

export OMP_NUM_THREADS=1
' >> ~/${BASH_PROFILE_NAME}


echo 'if [ $# -eq 0 ];
then
    echo "No argument supplied. Either specify "anaconda" or firedrake environment to be activated."
    echo "List of valid firedrake environments:"
    ls -w1 '"$PYTHON_ENVS_PATH"'
    exit 0

else

    else

        eval "$(/opt/homebrew/bin/brew shellenv)"
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        if command -v pyenv 1>/dev/null 2>&1; then
         eval "$(pyenv init -)"
        fi
' >> ~/${BASH_PROFILE_NAME}

echo '
        source ${HOME}/pythonEnvironments/${1}/variables.txt
    ' >> ~/${BASH_PROFILE_NAME}

echo '
        export PYOP2_CC=$FIREDRAKE_PATH/src/petsc/default/bin/mpicc
        export IPOPTDIR="${FULL_IPOPT_PATH}"
        export IPOPT_PATH="${FULL_IPOPT_PATH}/build"
        export PKG_CONFIG_PATH="${FULL_IPOPT_PATH}/build/lib64/pkgconfig:${FULL_IPOPT_PATH}/build/lib/pkgconfig:${FULL_IPOPT_PATH}/build/share/pkgcon$"
        export PATH="$PATH:${FULL_IPOPT_PATH}/build"
        export LD_LIBRARY_PATH="${FULL_IPOPT_PATH}/build/lib"

        echo "firedrake paths activated"
        sudo xcode-select -switch /Applications/Xcode_${XCODE_VERSION}.app

        pyenv global $PY_version

        . $FIREDRAKE_PATH/bin/activate

        echo "Firedrake environment activated"

    fi

fi' >> ~/${BASH_PROFILE_NAME}
