#!/bin/bash
#  ======================================================================
#  Import and pre-processing
#  ======================================================================

# Input block
INPBLK=qe.in
[ $# -eq 1 ] && INPBLK=$1

# Obtain the current directory
if [[ -n $PBS_O_WORKDIR ]]; then
	RUNENV=PBS
	HOMEDIR=$PBS_O_WORKDIR
	PPN=`wc -l $PBS_NODEFILE | awk '{print $1}'`
	VASP_PREFIX="aprun -n $PPN"
elif [[ -n $SLURM_SUBMIT_DIR ]]; then
	RUNENV=SLURM
	HOMEDIR=$SLURM_SUBMIT_DIR
	PPN=$SLURM_NPROCS
	VASP_PREFIX="mpirun -np $PPN"
else
	HOMEDIR="./"
	PPN=1
	RUNENV=
	VASP_PREFIX=
fi

cd $HOMEDIR
HOMEDIR=`pwd`
echo You start from the directory $HOMEDIR.

# Import functional scripts
. $HOMEDIR/$INPBLK
# Check the script folder. If not defined, use the current folder
if [ -z $SCRIPT_ROOT ]; then
	SCRIPT_ROOT="."
fi

# Load your modules
. $SCRIPT_ROOT/common.sh
. $SCRIPT_ROOT/pseudo.sh
. $SCRIPT_ROOT/relax.sh
#. $SCRIPT_ROOT/relax_z.sh
#. $SCRIPT_ROOT/scf.sh
#. $SCRIPT_ROOT/bands.sh
#. $SCRIPT_ROOT/dos.sh
#. $SCRIPT_ROOT/states.sh
#. $SCRIPT_ROOT/md.sh
#. $SCRIPT_ROOT/neb.sh

#  ======================================================================
#  Run, Forest, Run !
#  ======================================================================

count=0

# loop over POSCAR files
for file in $FILE; do
if [ -f $file ]; then
 
	RELAX_OK=0
	MD_OK=0
	SCF_OK=0
	BANDS_OK=0
	
	echo 
	echo $file_separator
	echo Processing $file ...
	echo $file_separator
	 
	# extract the poscar name from the POSCAR file
	posname=`echo $(basename $file)|awk 'BEGIN{FS="."}; {print $1}'`
	mkdir -p $posname
	cp $file $posname/POSCAR
	cd $posname
	 
	# construct POTCAR
	shopt -s nocasematch
	case $JOB in
		*"RELAX"*|*"RELAX_2D"*|*"MD"*|*"SCF"*|*"BANDS"*|*"GW"*|*"NEB"* ) 
		build_pseudo ;;
	esac
	shopt -u nocasematch
	 
	# reset variables according to $job
	reset_variables
	 
	# setting parallelism
	shopt -s nocasematch
	case $job in
		*"RELAX"*|"MD"|"SCF"|*"BANDS"*);; # TMP_NPAR=$NEED_TO_DEALT_WITH_LATER
	esac 
	shopt -u nocasematch
	
	# loop over the job sequence
	for job in $JOB; do
		shopt -s nocasematch
		case $job in
		  "RELAX"      ) run_relax    ;;
		  "MD"         ) run_md       ;;
		  "NEB"        ) run_neb      ;;
		  "SCF"        ) run_scf      ;;
		  "BANDS"      ) run_bands    ;;
		  "DOS"        ) run_dos      ;;
		  "STATES"     ) run_states   ;;
		  "GW"         ) ;;
		  *            ) unknown_job  ;;
		esac
		shopt -u nocasematch
	done
	 
	cd ..
	echo Done processing $file.
 
else
  echo Cannot find the poscar file $file. Skit it !
fi
count=$((count+1))
done

echo
echo Come back to the home directory $HOMEDIR
cd $HOMEDIR

