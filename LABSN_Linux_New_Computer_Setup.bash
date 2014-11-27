#! /bin/bash -e
## Commands to be run when setting up a fresh system. If you intend to
## install Intel MKL, you should do so *BEFORE* running this script, and
## then set the "mkl" variable to "true" in order to compile against the
## MKL libraries: 
mkl=false
mkl_prefix=/opt/intel

## This script does *NOT* install MKL, MATLAB or Freesurfer. Information
## on MATLAB installation for LABS^N members is available on the lab
## wiki. Freesurfer's website has thorough instructions on installation.

## ## ## ## ## ##
##  DECISIONS  ##
## ## ## ## ## ##
## Here you decide whether you want to use Ubuntu repositories (most
## conservative and stable), pip / PPA (middle ground), or git (bleeding
## edge) when installing the various packages and prerequisites, and
## specify any other installation options. The comments tell you which
## choices are available and what they mean. In all cases you can also
## specify "none" (or the empty string) if you don't want it installed
## at all, but be aware that many of the early-listed items are
## prerequisites for items further down the list.

## Do you want both Python 2.x and Python 3.x versions of everything?
p2k=true
p3k=true

## Create a directory to house any custom builds. Rename if desired.
build_dir="~/Builds"
mkdir -p $build_dir

## HDF5 OPTIONS
## "serial", "openmpi", and "mpich" are all Ubuntu repository options,
## the latter two being parallel versions. If opting for parallel, 
## "openmpi" is recommended. Compiling from source is also possible, but
## not really necessary; you can compile against Intel MKL ("intel"), 
## OpenMPI ("source-mpi"), or the default system compilers ("system").
## TODO: Uses version 1.8.13 (current as of 2014-11-25). If not
## installing from repos, check for newer version. Make sure to get
## .tar.gz, not .tar.bz2
hdf="serial"
hdf_prefix="/opt"  # a sub-folder "hdf5" will be created here automatically
hdf_url="http://www.hdfgroup.org/ftp/HDF5/current/src/hdf5-1.8.13.tar.gz"

## OPEN MPI: Only necessary with HDF5 options "openmpi" or "source-mpi".
## Options are "intel" or "system" for the choice of compilers.
## TODO: Uses version 1.8.3 (current as of 2014-11-25). Check for newer
## version. Make sure to get .tar.gz and not .tar.bz2. 
mpi="system"
mpi_prefix="/usr/local"
mpi_url="http://www.open-mpi.org/software/ompi/v1.8/downloads/openmpi-1.8.3.tar.gz"

## NUMPY & SCIPY OPTIONS: "repo", "pip", "git", & "mkl". mkl implies git
numpy="repo"
scipy="repo"

## All of the following have the same choices: "repo", "pip", or "git".
## Note that scikit-learn does not have a separate python3 version in
## the repos, so the p2k and p3k options do not differ for that package.
## Also note that some users like to install Spyder from the repos first
## to get the icon set, menu integration, etc, and then later install
## from pip or git to get the latest features. If this is you, then set
## Spyder to "repo" here, then run the pip or git installation lines
## after this script is completed.
mpl="repo"    # MATPLOTLIB: best-of-breed scientific plotting in python
pd="repo"     # PANDAS: Python data analysis library
skl="repo"    # SCIKIT-LEARN: machine learning algorithms in python
sea="repo"    # SEABORN: data visualization package built atop matplotlib
svgu="repo"   # SVG Utils: python tools for combining & manipulating SVGs
spyder="repo" # SPYDER: Python IDE tailored to scientific users

## The following aren't available in the Ubuntu repos, so the only
## choices are "pip" or "git".
skc="pip"   # SCIKITS.CUDA: SciPy toolkit interface to NVIDIA's CUDA libraries
tdt="none"  # TDTPY:  Python wrappers for TDT's Active-X interface

## IMAGE PROCESSING APPS: inkscape, gimp, & image magick are repo-only,
## so just need a boolean for whether to install them or not:
ink=true
gimp=true
magick=true

## EXPYFUN DEPENDENCIES
## All of these have options "repo", "pip", or "git". For Pyglet, "git"
## is required for expyfun to work (and incidentally, for Pyglet "git"
## really means using pip to install the latest development tarball from
## the dev repo, which is a google code site, not GitHub). NumExpr is a
## dependency of PyTables, but PyTables is no longer a dependency of
## expyfun (it's been replaced by h5py), so those two default to not
## being installed at all. If you decide to install them anyway, "mkl"
## is also an option for numexpr, and implies "git".
joblib="repo"  # JOBLIB: python parallelization library
pyglet="pip"   # PYGLET: python audio / visual interface layer
numexpr="none"
pytables="none"

## EXPYFUN and MNEFUN: Both come from GitHub. Options are "user" or
## "dev"; choose "dev" if you are likely to modify / contribute to the
## codebase, in addition to using it to run your experiments / analysis.
## If you choose "dev", then you should first fork the project from the
## LABSN GitHub account into your own account, and enter your GitHub
## username below. The script will set up your local clone to track your
## fork as "origin", and will create a second remote "upstream" that 
## tracks the LABSN master.
github_username=""
expyfun="user"
mnefun="user"

## MNE PYTHON: core MNE analysis package. Options are "pip" or "git".
## If you want mne-python to use CUDA (and you should, if your computer
## has a good NVIDIA graphics card), there is a separate script to set
## that up, that you should run after this script succeeds.
mnepy="pip"

## R and JULIA: Statistical programming environments. Options for R are
## "repo" and "cran", with "cran" being recommended (runs through
## apt-get, but adds a new source to /etc/apt/sources.list). The 
## recommended IDE for R is RStudio, which currently serves up binaries
## from its own website rather than through the repos, so you need to
## provide the URL for the most current version here.  Options for Julia
## are "ppa", "git", and "mkl". mkl implies git. The PPA is run by a
## former LABS^N member, and so is not really a risk/unknown like some
## PPAs are. If you install the JuliaStudio IDE, make sure to update the
## URL and make sure it is compatible with the version of Julia you are
## installing. 
rlang="cran"
rstudio_url="http://download1.rstudio.org/rstudio-0.98.1091-amd64.deb"
julia="ppa"
#juliastudio_url="https://s3.amazonaws.com/cdn-common.forio.com/\
#julia-studio/0.4.4/julia-studio-linux-64-0.4.4.tar.gz"

## ## ## ## ## ## ##
## GENERAL SETUP  ##
## ## ## ## ## ## ##
## These are general prerequisites that any system should probably have.
## Repo versions are typically best here, although installing through
## pip is possible for the python-related ones, as shown in the
## commented-out lines below.
sudo apt-get update
sudo apt-get install default-jre build-essential git-core cmake bzip2 \
liblzo2-2 liblzo2-dev zlib1g zlib1g-dev libfreetype6-dev libpng-dev \
libxml2-dev libxslt1-dev
if [ $p2k = true ]; then
	sudo apt-get install cython python-nose python-coverage \
	python-setuptools python-pip
fi
if [ $p3k = true ]; then
	sudo apt-get install cython3 python3-nose python3-coverage \
	python3-setuptools python3-pip
fi
# pip install --user Cython nose coverage setuptools
# pip3 install --user Cython nose coverage setuptools

## ## ## ## ##
## OPEN MPI ##
## ## ## ## ##
if [ $hdf = "openmpi" ] || [ $hdf = "source-mpi" ]; then
	mpi_archive="${mpi_url##*/}"
	mpi_folder="${mpi_archive%.tar.gz}"
	cd
	wget "$mpi_url"
	tar -zxf "$mpi_archive"
	cd "$mpi_folder"
	if [ "$mpi" = "intel" ]; then
		flags="CC=icc CXX=icpc FC=ifort"
	fi
	./configure --prefix="$mpi_prefix" $flags
	make -j 6 all
	sudo bash
	make install
	## NOTE: the "sudo bash; make install" lines are equivalent to
	## "sudo make install", except this way the ~/.bashrc file gets
	## loaded first (which is not normally the case with sudo commands).
	## That way, the intel compiler dirs are on the path during install.
	rm "~/$mpi_archive"
	rm -Rf "~/$mpi_folder"
fi

## ## ## ##
## HDF5  ##
## ## ## ##
if [ $hdf = "source-mpi" ] || [ $hdf = "intel" ] || [ $hdf = "system" ]
then
	hdf_archive=${hdf_url##*/}
	hdf_folder=${hdf_archive%.tar.gz}
	cd "$hdf_prefix"
	mkdir "hdf5"
	cd
	wget "$hdf_url"
	tar -zxf "$hdf_archive"
	cd "$hdf_folder"
	if [ $hdf = "source-mpi" ]; then
		export CC=mpicc
		flags="--disable-static"
	else  # $hdf = "intel" or "system"
		if [ $hdf = "intel" ]; then
			export CC=icc
			export F9X=ifort
			export CXX=icpc
		fi
		flags="--enable-fortran --enable-cxx --disable-static"
	fi
	./configure --prefix="$hdf_prefix/hdf5" $flags
	make -j -l6
	make check
	make install
	make check-install
	cd 
	rm "~/$hdf_archive"
	rm -Rf "~/$hdf_folder"
elif [ $hdf = "mpich" ]; then
	sudo apt-get install libhdf5-mpich2-7 libhdf5-mpich2-dev
elif [ $hdf = "openmpi" ]; then
	sudo apt-get install libhdf5-openmpi-7 libhdf5-openmpi-dev
elif [ $hdf = "serial" ]; then
	sudo apt-get install libhdf5-7 libhdf5-dev
fi

## ## ## ##
## NUMPY ##
## ## ## ##
if [ $numpy = "repo" ]; then
	if [ $p2k = true ]; then
		sudo apt-get install python-numpy
	fi
	if [ $p3k = true ]; then
		sudo apt-get install python3-numpy
	fi
elif [ $numpy = "pip" ]; then
	if [ $p2k = true ]; then
		pip install --user numpy
	fi
	if [ $p3k = true ]; then
		pip3 install --user numpy
	fi
elif [ $numpy = "git" ] || [ $numpy = "mkl" ]; then
	cd "$build_dir"
	git clone git@github.com:numpy/numpy.git
	cd numpy
	rm -Rf build  ## in case rebuilding
	if [ $numpy = "mkl" ]; then
		## generate site.cfg
		echo [mkl] > site.cfg
		echo library_dirs = "$mkl_prefix/mkl/lib/intel64" >> site.cfg
		echo include_dirs = "$mkl_prefix/mkl/include" >> site.cfg
		echo mkl_libs = mkl_rt >> site.cfg
		echo lapack_libs =   >> site.cfg
		flags="config --compiler=intelem build_clib --compiler=intelem \
		build_ext --compiler=intelem"
	else  # $numpy = "git"
		flags=""
	fi
	if [ $p2k = true ]; then
		python2 setup.py clean
		python2 setup.py $flags install --user
	fi
	if [ $p3k = true ]; then
		python3 setup.py clean
		python3 setup.py $flags install --user
	fi
fi

## ## ## ## ##
## NUMEXPR  ##
## ## ## ## ##
if [ $numexpr = "repo" ]; then
	if [ $p2k = true ]; then
		sudo apt-get install python-numexpr
	fi
	if [ $p3k = true ]; then
		sudo apt-get install python3-numexpr
	fi
elif [ $numexpr = "pip" ]; then
	if [ $p2k = true ]; then
		pip install --user numexpr
	fi
	if [ $p3k = true ]; then
		pip3 install --user numexpr
	fi
elif [ $numexpr = "git" ] || [ $numexpr = "mkl" ]; then
	cd "$build_dir"
	git clone git@github.com:pydata/numexpr.git
	cd numexpr
	rm -Rf build  ## in case rebuilding
	if [ $numexpr = "mkl" ]; then
		## generate site.cfg (same format as NumPy)
		echo [mkl] > site.cfg
		echo library_dirs = "$mkl_prefix/mkl/lib/intel64" >> site.cfg
		echo include_dirs = "$mkl_prefix/mkl/include" >> site.cfg
		echo mkl_libs = mkl_rt >> site.cfg
		echo lapack_libs =   >> site.cfg
	fi
	if [ $p2k = true ]; then
		python2 setup.py build
		python2 setup.py install --user
		#cd; python2 -c "import numexpr; numexpr.test()"
		#cd "$build_dir/numexpr"
	fi
	if [ $p3k = true ]; then
		python3 setup.py build
		python3 setup.py install --user
		#cd; python3 -c "import numexpr; numexpr.test()"
	fi
	## NOTE: numexpr.test() fails if run within $build_dir/numexpr,
	## hence the cd to $HOME first
fi

## ## ## ## ##
## PYTABLES ##
## ## ## ## ##
if [ $pytables = "repo" ]; then
	if [ $p2k = true ]; then
		sudo apt-get install python-tables python-tables-lib
	fi
	if [ $p3k = true ]; then
		sudo apt-get install python3-tables python3-tables-lib
	fi
elif [ $pytables = "pip" ]; then
	if [ $p2k = true ]; then
		pip install --user tables
	fi
	if [ $p3k = true ]; then
		pip3 install --user tables
	fi
elif [ $pytables = "git" ]; then
	cd "$build_dir"
	git clone git@github.com:PyTables/PyTables.git
	cd PyTables
	if [ $p2k = true ]; then
		make clean
		python2 setup.py build_ext --inplace
		python2 setup.py install --user
		#cd; python2 -c "import tables; tables.test()"
		#cd "$build_dir"/PyTables
	fi
	if [ $p3k = true ]; then
		make clean
		python3 setup.py build_ext --inplace
		python3 setup.py install --user
		#cd; python3 -c "import tables; tables.test()"
	fi
	## NOTE: tables.test() fails if run within $build_dir/PyTables,
	## hence the cd to $HOME first
fi

## ## ## ##
## SCIPY ##
## ## ## ##
if [ $scipy = "repo" ]; then
	if [ $p2k = true ]; then
		sudo apt-get install python-scipy
	fi
	if [ $p3k = true ]; then
		sudo apt-get install python3-scipy
	fi
elif [ $scipy = "pip" ]; then
	if [ $p2k = true ]; then
		pip install --user scipy
	fi
	if [ $p3k = true ]; then
		pip3 install --user scipy
	fi
elif [ $scipy = "git" ] || [ $scipy = "mkl" ]; then
	cd "$build_dir"
	git clone git@github.com:scipy/scipy.git
	cd scipy
	rm -Rf build  ## in case rebuilding
	if [ $scipy = "mkl" ]; then
		flags="config --compiler=intelem --fcompiler=intelem \
		build_clib --compiler=intelem --fcompiler=intelem build_ext \
		--compiler=intelem --fcompiler=intelem"
	else  # $scipy = "git"
		flags=""
	fi
	if [ $p2k = true ]; then
		python2 setup.py clean
		python2 setup.py $flags install --user
	fi
	if [ $p3k = true ]; then
		python3 setup.py clean
		python3 setup.py $flags install --user
	fi
fi

## ## ## ## ## ##
## MATPLOTLIB  ##
## ## ## ## ## ##
if [ $mpl = "repo" ]; then
	if [ $p2k = true ]; then
		sudo apt-get install python-matplotlib 
	fi
	if [ $p3k = true ]; then
		sudo apt-get install python3-matplotlib
	fi
elif [ $mpl = "pip" ]; then
	if [ $p2k = true ]; then
		pip install --user matplotlib
	fi
	if [ $p3k = true ]; then
		pip3 install --user matplotlib
	fi
elif [ $mpl = "git" ]; then
	cd "$build_dir"
	git clone git@github.com:matplotlib/matplotlib.git
	cd matplotlib
	if [ $p2k = true ]; then
		rm -Rf build
		python2 setup.py install --user 
	fi
	if [ $p3k = true ]; then
		rm -Rf build
		python3 setup.py install --user 
	fi
fi

## ## ## ## ##
##  PANDAS  ##
## ## ## ## ##
if [ $pd = "repo" ]; then
	if [ $p2k = true ]; then
		sudo apt-get install python-pandas python-pandas-lib
	fi
	if [ $p3k = true ]; then
		sudo apt-get install python3-pandas python3-pandas-lib
	fi
elif [ $pd = "pip" ]; then
	if [ $p2k = true ]; then
		pip install --user pandas
	fi
	if [ $p3k = true ]; then
		pip3 install --user pandas
	fi
elif [ $pd = "git" ]; then
	cd "$build_dir"
	git clone git@github.com:pydata/pandas.git
	cd pandas
	if [ $p2k = true ]; then
		rm -Rf build
		python2 setup.py install --user 
	fi
	if [ $p3k = true ]; then
		rm -Rf build
		python3 setup.py install --user 
	fi
fi

## ## ## ## ## ## ##
##  SCIKIT-LEARN  ##
## ## ## ## ## ## ##
if [ $skl = "repo" ]; then
	if [ $p2k = true ]; then
		sudo apt-get install python-sklearn python-sklearn-lib
	fi
	if [ $p3k = true ]; then
		## NOTE: no python3-* versions in repos (2014-11-25)
		sudo apt-get install python-sklearn python-sklearn-lib
	fi
elif [ $skl = "pip" ]; then
	if [ $p2k = true ]; then
		pip install --user scikit-learn
	fi
	if [ $p3k = true ]; then
		pip3 install --user scikit-learn
	fi
elif [ $skl = "git" ]; then
	cd "$build_dir"
	git clone git@github.com:scikit-learn/scikit-learn.git
	cd scikit-learn
	if [ $p2k = true ]; then
		rm -Rf build
		python2 setup.py install --user 
	fi
	if [ $p3k = true ]; then
		rm -Rf build
		python3 setup.py install --user 
	fi
fi

## ## ## ## ##
## SEABORN  ##
## ## ## ## ##
if [ $sea = "repo" ]; then
	if [ $p2k = true ]; then
		sudo apt-get install python-patsy python-statsmodels \
		python-statsmodels-lib python-seaborn
	fi
	if [ $p3k = true ]; then
		## NOTE: no p3k version of statsmodels in repo (2014-11-25)
		pip3 install --user statsmodels
		sudo apt-get install python3-patsy python3-seaborn
	fi
elif [ $sea = "pip" ]; then
	if [ $p2k = true ]; then
		pip install --user patsy statsmodels seaborn
	fi
	if [ $p3k = true ]; then
		pip3 install --user patsy statsmodels seaborn
	fi
elif [ $sea = "git" ]; then
	cd "$build_dir"
	git clone git@github.com:pydata/patsy.git
	git clone git@github.com:statsmodels/statsmodels.git
	git clone git@github.com:mwaskom/seaborn.git
	for name in patsy statsmodels seaborn; do
		cd "$build_dir/$name"
		if [ $p2k = true ]; then
			rm -Rf build
			python2 setup.py install --user
		fi
		if [ $p3k = true ]; then
			rm -Rf build
			python3 setup.py install --user
		fi
	done
fi

## ## ## ## ## ## ##
##  SCIKITS.CUDA  ##
## ## ## ## ## ## ##
if [ $skc = "pip" ]; then
	if [ $p2k = true ]; then
		pip install --user scikits.cuda
	fi
	if [ $p3k = true ]; then
		pip3 install --user scikits.cuda
	fi
elif [ $skc = "git" ]; then
	cd "$build_dir"
	git clone git@github.com:lebedov/scikits.cuda.git
	cd scikits.cuda
	if [ $p2k = true ]; then
		rm -Rf build
		python2 setup.py install --user 
	fi
	if [ $p3k = true ]; then
		rm -Rf build
		python3 setup.py install --user 
	fi
fi

## ## ## ##
## TDTPY ##
## ## ## ##
if [ $tdt = "pip" ]; then
	if [ $p2k = true ]; then
		pip install --user TDTPy
	fi
	if [ $p3k = true ]; then
		pip3 install --user TDTPy
	fi
elif [ $tdt = "git" ]; then
	cd "$build_dir"
	hg clone https://bitbucket.org/bburan/tdtpy
	cd tdtpy
	if [ $p2k = true ]; then
		rm -Rf build
		python2 setup.py install --user 
	fi
	if [ $p3k = true ]; then
		rm -Rf build
		python3 setup.py install --user 
	fi
fi

## ## ## ## ## ##
##  SVG UTILS  ##
## ## ## ## ## ##
if [ $svgu = "repo" ]; then
	if [ $p2k = true ]; then
		sudo apt-get install python-cairosvg python-cssselect
		pip install --user tinycss cairocffi svgutils
	fi
	if [ $p3k = true ]; then
		sudo apt-get install python3-cairosvg
		pip3 install --user tinycss cssselect cairocffi svgutils
	fi
elif [ $svgu = "pip" ]; then
	if [ $p2k = true ]; then
		pip install --user tinycss cssselect cairocffi cairosvg svgutils
	fi
	if [ $p3k = true ]; then
		pip3 install --user tinycss cssselect cairocffi cairosvg svgutils
	fi
elif [ $svgu = "git" ]; then
	cd "$build_dir"
	git clone git@github.com:SimonSapin/tinycss.git
	git clone git@github.com:SimonSapin/cssselect.git
	git clone git@github.com:SimonSapin/cairocffi.git
	git clone git@github.com:Kozea/CairoSVG.git
	git clone git@github.com:btel/svg_utils.git
	for name in tinycss cssseleect cairocffi CairoSVG svg_utils; do
		cd "$build_dir/$name"
		if [ $p2k = true ]; then
			rm -Rf build
			python2 setup.py install --user
		fi
		if [ $p3k = true ]; then
			rm -Rf build
			python3 setup.py install --user
		fi
	done
fi

## ## ## ## ## ## ## ## ## ## ## ##
## INKSCAPE, GIMP, IMAGE MAGICK  ##
## ## ## ## ## ## ## ## ## ## ## ##
if [ $ink = true ]; then
	sudo apt-get install inkscape
fi
if [ $gimp = true ]; then
	sudo apt-get install gimp
fi
if [ $magick = true ]; then
	sudo apt-get install libmagickwand-dev
fi

## ## ## ## ##
##  SPYDER  ##
## ## ## ## ##
if [ $spyder = "repo" ]; then
	if [ $p2k = true ]; then
		sudo apt-get install python-rope python-flake8 python-sphinx \
		pylint pyflakes python-sip python-qt4 spyder
	fi
	if [ $p3k = true ]; then
		sudo apt-get install python3-rope python3-flake8 \
		python3-sphinx pylint pyflakes python3-sip python3-pyqt4 spyder3
	fi
elif [ $spyder = "pip" ]; then
	if [ $p2k = true ]; then
		pip install --user rope flake8 sphinx pylint
	fi
	if [ $p3k = true ]; then
		pip3 install --user rope_py3k flake8 sphinx pylint
	fi
elif [ $spyder = "git" ]; then
	cd "$build_dir"
	hg clone https://spyderlib.googlecode.com/hg/ spyderlib
	cd spyderlib
	if [ $p2k = true ]; then
		rm -Rf build
		python2 setup.py install --user
	fi
	if [ $p3k = true ]; then
		rm -Rf build
		python3 setup.py install --user
	fi
	## to update spyder:
	# cd "$build_dir/spyder"
	# hg pull --update
	# python2 setup.py install --user
	# python3 setup.py install --user
fi

## ## ## ## ##
##  JOBLIB  ##
## ## ## ## ##
if [ $joblib = "repo" ]; then
	if [ $p2k = true ]; then
		sudo apt-get install python-joblib
	fi
	if [ $p3k = true ]; then
		sudo apt-get install python3-joblib
	fi
elif [ $joblib = "pip" ]; then
	if [ $p2k = true ]; then
		pip install --user joblib
	fi
	if [ $p3k = true ]; then
		pip3 install --user joblib
	fi
elif [ $joblib = "git" ]; then
	cd "$build_dir"
	git clone git@github.com:joblib/joblib.git
	cd joblib
	if [ $p2k = true ]; then
		rm -Rf build
		python2 setup.py install --user
	fi
	if [ $p3k = true ]; then
		rm -Rf build
		python3 setup.py install --user
	fi
fi

## ## ## ## ##
##  PYGLET  ##
## ## ## ## ##
if [ $pyglet = "repo" ]; then
	if [ $p2k = true ]; then
		sudo apt-get install python-pyglet
	fi
	if [ $p3k = true ]; then
		## no separate pk3 version
		sudo apt-get install python-pyglet
	fi
elif [ $pyglet = "pip" ]; then
	if [ $p2k = true ]; then
		pip install --user pyglet
	fi
	if [ $p3k = true ]; then
		pip3 install --user pyglet
	fi
elif [ $pyglet = "git" ]; then
	pip install --user --upgrade http://pyglet.googlecode.com/archive/tip.zip
fi

## ## ## ## ##
## EXPYFUN  ##
## ## ## ## ##
cd "$build_dir"
if [ $expyfun = "user" ]; then
	git clone git@github.com/LABSN/expyfun.git
	cd expyfun
	directive="install"
elif [ $expyfun = "dev" ]; then
	git clone git@github.com:$github_username/expyfun.git
	cd expyfun
	git remote add upstream git@github.com:LABSN/expyfun.git
	directive="develop"
fi
if [ $p2k = true ]; then
	python2 setup.py $directive --user
fi
if [ $p3k = true ]; then
	python3 setup.py $directive --user
fi

## ## ## ## ##
##  MNEFUN  ##
## ## ## ## ##
cd "$build_dir"
if [ $mnefun = "user" ]; then
	git clone git@github.com:LABSN/mnefun.git
	cd mnefun
	directive="install"
elif [ $mnefun = "dev" ]; then
	git clone git@github.com:$github_username/MNE.git
	cd expyfun
	git remote add upstream git@github.com:LABSN/mnefun.git
	directive="develop"
fi
if [ $p2k = true ]; then
	python2 setup.py $directive --user
fi
if [ $p3k = true ]; then
	python3 setup.py $directive --user
fi

## ## ## ## ## ##
## MNE-PYTHON  ##
## ## ## ## ## ##
if [ $mnepy = "pip" ]; then
	if [ $p2k = true ]; then
		pip install --user mne
	fi
	if [ $p3k = true ]; then
		pip3 install --user mne
	fi
elif [ $mnepy = "git" ]; then
	cd "$build_dir"
	git clone git@github.com:mne-tools/mne-python.git
	cd mne-python
	if [ $p2k = true ]; then
		python2 setup.py install --user
	fi
	if [ $p3k = true ]; then
		python3 setup.py install --user
	fi
fi

## ## ## ##
## JULIA ##
## ## ## ##
if [ $julia = "ppa" ]; then
	#codename=$(lsb_release -c -s)
	#sudo echo "deb http://ppa.launchpad.net/staticfloat/juliareleases/\
	#ubuntu $codename main" >> /etc/apt/sources.list
	#sudo echo "deb-src http://ppa.launchpad.net/staticfloat/\
	#juliareleases/ubuntu $codename main" >> /etc/apt/sources.list
	sudo add-apt-repository ppa:staticfloat/juliareleases
	sudo apt-get update
	sudo apt-get install julia
elif [ $julia = "git" ] || [ $julia = "mkl" ]; then
	cd "$build_dir"
	git clone git@github.com:JuliaLang/julia.git
	cd julia
	if [ $julia = "mkl" ]; then
		source "$mkl_prefix/mkl/bin/mklvars.sh" intel64 ilp64
		export MKL_INTERFACE_LAYER=ILP64
		echo USE_MKL = 1 >> Make.user
	fi
	make -j 6
	make testall
	echo export PATH="$(pwd):$PATH" >> ~/.bashrc
fi

# TODO: WIP progress marker. Code beyond this point not finished yet.

## ## ##
## R  ##
## ## ##
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
codename=$(lsb_release -c -s)
sudo echo "deb http://cran.fhcrc.org/bin/linux/ubuntu $codename/" >> \
/etc/apt/sources.list
sudo apt-get update
sudo apt-get install r-base r-base-dev
## Some (probably) useful packages to install from within R:
## install.packages(c('tidyr', 'devtools', 'ez', 'ggplot2',
## 'Hmisc', 'lme4', 'plyr', 'reshape', 'stringi', 'zoo'))

## ## ## ## ## ##
## NETWORKING  ##
## ## ## ## ## ##
sudo apt-get install openssh-server
	## TODO ##
	## First make sure you're getting a static IP (check network
	## settings for eth0). For added security, change port number to
	## something other than 22 in /etc/ssh/sshd_config, then access via:
	# ssh -p 1234 <username>@<hostname>.ilabs.uw.edu
	## (where 1234 is the port you chose)

## RUNNING FIREFOX THROUGH AN SSH TUNNEL
## This sets up a pseudo-VPN for browser traffic only (useful if, e.g.,
## you're in a foreign country that blocks some websites). To avoid
## changing these settings back and forth all the time, first set up a
## new Firefox profile by running "firefox -P" on the command line.
## Create a new profile with a sensible name like "ssh" or "tunnel".
## Start Firefox with that profile, then go to:
## "Preferences > Advanced > Network > Settings" and choose "Manual
## Proxy Configuration". Set your SOCKS host to 127.0.0.1, port 8080,
## use SOCKS v5, and check the "Remote DNS" box. Now you can run:
# ssh -C2qTnN -D 8080 <name>@<hostname>
## ...before you launch Firefox, and all your browser traffic will be
## routed through your <hostname> computer and encrypted. Don't forget
## to add the flag "-p 1234" to the ssh command if you've configured
## ssh to listen on a non-default port (as recommended above). Note that
## the Firefox profile editor allows you to select a default profile, so
## that can be an easy way to switch settings for the duration of your
## journey abroad, then switch back upon returning home. If you need to
## switch back and forth between tunnel and no tunnel on a regular
## basis, you can set your normal Firefox profile as the default, then
## use the following command to invoke the tunneled version (assuming
## the name of your proxied profile is "sshtunnel"):
#ssh -C2qTnN -D 8080 <name>@<hostname> & tunnelpid=$! && sleep 3 && firefox -P sshtunnel && kill $tunnelpid
## this will capture the PID of the SSH tunnel instance, and kill it
## when Firefox closes normally (you'll need to close it manually if
## Firefox crashes or is force-quit).

## XRDP: remote desktop server
sudo apt-get install xrdp
## Setting up your machine as a VPN server is a pain.
## see instructions here if you must do it anyway:
## http://openvpn.net/index.php/open-source/documentation/howto.html
## these commands will get you started...
# sudo apt-get install openvpn bridge-utils easy-rsa
# sudo cp -r /usr/share/easy-rsa /etc/openvpn/
# sudo chown -R $USER /etc/openvpn/easy-rsa
	## TODO ##
	## now edit /etc/openvpn/easy-rsa/vars
	## in particular, set VPN port to 2345 (or whatever you want)
	# cd /etc/openvpn/easy-rsa
	# . ./vars
	# ./clean-all
	# ./build-ca
	# ./build-key-server
	# ./build-key-pass MyClientCPUName
	# ./build-dh
	## move client keys to client machine
	## set up VPN autostart

## ## ## ## ##
## FIREWALL ##
## ## ## ## ##
## NOTE: you don't strictly NEED to set up a firewall, as *NIX is pretty
## careful about what it allows in. This is especially true if you set
## SSH to reject password-based connections and only use preshared keys.
## Nonetheless, if you want to set up a strong firewall, this is a good
## starting point:
## (port numbers should match what you set for SSH and VPN above)
# sudo iptables -A INPUT -p tcp --dport 1234 -j ACCEPT  # incoming SSH
# sudo iptables -A INPUT -p tcp --sport 1234 -j ACCEPT  # outgoing SSH
# sudo iptables -A INPUT -p udp -m udp --dport 2345 -j ACCEPT  # incoming VPN
# sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT  # incoming web traffic
## probably will also need a line for the default HTTPS port (and
## possibly others). Google is your friend here. Finally, add a line to
## reject everything not explicitly allowed above. You will need to save
## changes (again, see Google for different ways to do this) otherwise
## the settings will only last for the current login session.

## ## ## ##
## RAID  ##
## ## ## ##
sudo apt-get install mdadm
	## TODO ##
    ## This is an example only. Customize to suit your system.
	## This will create a RAID level=1 (mirror) at /dev/md0 comprising
	## n=2 physical drives (sdc and sdd)
	sudo mdadm --create /dev/md0 -l 1 -n 2 /dev/sdc1 /dev/sdd1
	## If the RAID had already been built previously:
	# sudo mdadm --assemble /dev/md0 /dev/sdc1 /dev/sdd1
## automount at startup (edit MOUNTPT as desired):
MOUNTPT="/media/raid"
sudo mkdir $MOUNTPT
UUID=sudo blkid /dev/md0 | cut -d '"' -f2
sudo echo "UUID=$UUID $MOUNTPT ext4 defaults 0 0" >> /etc/fstab
