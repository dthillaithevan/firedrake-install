#!/bin/bash

################################
# FIREDRAKE INSTALLATION SCRIPT FOR LINUX
# Installs firedrake and other dependancies using pyenv. Outputs .bash_profile script which can be used to activate Firedrake
################################

################################
# USAGE:
# 1. Modify this file as required (i.e. chosing which libraries to install) and place in home directory
# 2. run "source install_firedrake_linux.sh" in terminal (without "") - NOTE: you can also call "source install_firedrake_linux.sh --environment_name your_chosen_env_name" to specifed a custom environment name
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
# IPOPT:
    # To install IPOPT you need to download the conhsl.zip file and move it to your home directory.
################################


#### OPTIONS THAT CAN BE MODIFIED ####
export INSTALL_IPOPT=true
export REMOVE_OLD_PYENV=false
export INSTALL_PYENV_VERSION=true
export INSTALL_PIP_LIBRARIES=true

# Modules to be installed via pip (excl. cyipopt), these can be modified as needed (once the venv has been created you can activate the venv and install new modules using pip install XXXX as needed)
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

# Python version to be installed - can be modified but don't unless you have a good reason to
export PY_version="3.9.2"

# IPOPT version - DO NOT CHANGE!
export IPOPT_VERSION=3.12.11

export current_date=$(date +'%d_%m_%Y')
export ENV_NAME="firedrake_$current_date"
export BASH_PROFILE_NAME=".bash_profile"


##########################################
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
    echo "Downloading IPOPT....."

    # download ipopt installation files
    curl -O https://www.coin-or.org/download/source/Ipopt/Ipopt-$IPOPT_VERSION.tgz
    tar -xvf Ipopt-$IPOPT_VERSION.tgz

    # copy HSL libraries
    cp -r $HOME_PATH/coinhsl $FULL_IPOPT_PATH/ThirdParty/HSL/coinhsl

    # append paths to .bash_profile
    echo 'export IPOPTDIR="$FULL_IPOPT_PATH"' >> ~/.bash_profile
    echo 'export IPOPT_PATH="$FULL_IPOPT_PATH/build"' >> ~/.bash_profile
    source ~/.bash_profile

    # install ipopt
    mkdir $FULL_IPOPT_PATH/build
    cd $FULL_IPOPT_PATH/build
    echo "Installing IPOPT"
    ../configure
    make
    make test
    make install
    cd $INSTALLATION_PATH
}

install_cyipopt() {
    cd $INSTALLATION_PATH

    echo "Downloading CYIPOPT....."
    wget https://files.pythonhosted.org/packages/75/ec/7694bde4de00f96f89cc3c9b0a05f49ae9a25e52a5b695d665866a6652c2/cyipopt-1.4.1.tar.gz
    tar -xvf cyipopt-1.4.1.tar.gz
    cd cyipopt-1.4.1/

    echo "Installing CYIPOPT....."
    python setup.py build
    python setup.py install
}

install_pyenv() {
    echo "Installing pyenv..."

    curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash

    # Add pyenv init to shell
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/${BASH_PROFILE_NAME}
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/${BASH_PROFILE_NAME}
    echo 'eval "$(pyenv init --path)"' >> ~/${BASH_PROFILE_NAME}
    echo 'eval "$(pyenv init -)"' >> ~/${BASH_PROFILE_NAME}

    # Reload shell
    source ~/${BASH_PROFILE_NAME}
}

build_pyenv_dependencies() {
    echo "Installing pyenv dependencies...."
    sudo apt update; sudo apt install build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev curl git \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
    llvm

    echo "------- Complete ------"
}

echo ''
echo "---------- Installing firedrake environment in ${INSTALLATION_PATH} ----------"
echo ''

cd $HOME_PATH

# Check if curl/git is installed and install if not
build_pyenv_dependencies

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
# Setup bash profile
################################
# Reset bash_profile
echo "Resetting bash_profile"
echo ""
cp ~/${BASH_PROFILE_NAME} ~/${BASH_PROFILE_NAME}_back_up_${current_date} # Creates back-up of current bash_profile
truncate -s 0 ~/${BASH_PROFILE_NAME}


################################
# Setup pyenv
################################
# Remove old pyenv
if [ "$REMOVE_OLD_PYENV" = true ] ; then
    if [ -d "$HOME/.pyenv" ]; then
      echo "Removing existing pyenv installation"
      echo ""
      rm -rf $HOME/.pyenv
    fi

fi

# Install Pyenv if it is not already installed
if ! command -v pyenv &> /dev/null
then
    echo "pyenv is not installed. Installing pyenv..."
    install_pyenv
fi

# Initialise pyenv
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/${BASH_PROFILE_NAME}
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/${BASH_PROFILE_NAME}
echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n eval "$(pyenv init -)"\nfi' >> ~/${BASH_PROFILE_NAME}
source ~/${BASH_PROFILE_NAME}


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

        install_ipopt
    fi

    # append paths to .bash_profile
    echo 'export IPOPT_PATH="${FULL_IPOPT_PATH}/build"' >> ~/${BASH_PROFILE_NAME}
    echo 'export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:${FULL_IPOPT_PATH}/build/lib64/pkgconfig:${FULL_IPOPT_PATH}/build/lib/pkgconfig:${FULL_IPOPT_PATH}/share/pkgconfig:${FULL_IPOPT_PATH}/build/lib/pkgconfig"' >> ~/.bash_profile
    echo 'export PATH="$PATH:${FULL_IPOPT_PATH}/build"' >> ~/${BASH_PROFILE_NAME}
    echo 'export LD_LIBRARY_PATH="${FULL_IPOPT_PATH}/build/lib"' >> ~/${BASH_PROFILE_NAME}
    source ~/${BASH_PROFILE_NAME}

    echo "\n\n------- IPOPT INSTALLATION COMPLETE! -------\n\n"


    . $FIREDRAKE_PATH/bin/activate

    cd $INSTALLATION_PATH

    install_cyipopt


fi

if [ "$INSTALL_PIP_LIBRARIES" = true ] ; then

    . $FIREDRAKE_PATH/bin/activate

    pip install --upgrade pip

    echo "\n\nInstalling other pip modules"
    echo ""

    for lib in "${pip_libraries[@]}"; do
        echo "\n\nInstalling $lib..."
        pip3 install "${lib}"
    done
fi

pip install pre-commit


################################
# TESTING INSTALLATIONS
################################
echo ""
echo ""
echo "------ TESTING INSTALLATION -----"
echo "------ NO ERRORS SHOULD APPEAR BELOW! -----"
python -c "import firedrake;print('\n------Successfully Imported Firedrake------\n')"
if [ "$INSTALL_IPOPT" = true ] ; then
    python -c "import cyipopt;print('\n------Successfully Imported cyIPOPT------\n')"
fi



# deactivate Firedrake environment
deactivate


echo ""
echo ""
echo "------ UPDATING ${BASH_PROFILE_NAME} -----"

#### Save variables to file ####
{
  echo "FULL_IPOPT_PATH=${FULL_IPOPT_PATH}"
  echo "FIREDRAKE_PATH=$FIREDRAKE_PATH"
  echo "PYTHON_ENVS_PATH=$PYTHON_ENVS_PATH"
    echo "VENV_NAME=$VENV_NAME"
} > $INSTALLATION_PATH/variables.txt


# deactivate Firedrake environment
deactivate

cd $HOME_PATH

# delete contents of ~/.bash_profile
truncate -s 0 ~/${BASH_PROFILE_NAME}

echo '
deactivate
export OMP_NUM_THREADS=1' >> ~/.bash_profile

echo 'if [ $# -eq 0 ];
then
    echo "No argument supplied. Please specify a firedrake environment to be activated."
    echo "List of valid firedrake environments:"
    ls -w1 '"$PYTHON_ENVS_PATH"'
    exit 0
else
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

    pyenv global $PY_version
    . $FIREDRAKE_PATH/bin/activate
    echo "Firedrake environment activated"
fi' >> ~/${BASH_PROFILE_NAME}
