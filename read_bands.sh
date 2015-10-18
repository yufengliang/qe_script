#!/bin/bash

# read the band structure from quantum espresso pw.x output

if [ $# -ne 1 ]; then
	echo "usage: $0 bands.out"
	exit
fi

file=$1

# kpoints

kstring="number of k points="
nk=$(grep "$kstring" $file | awk '{print $5}')

grep -A "$((nk+1))" "$kstring" $file | tail -n+3 | sed 's/),/ ),/' | awk '{print $5,$6,$7}' > kpoints.txt

# band energies

kequal="     k = "
nbnd=$(grep "number of Kohn-Sham states=" $file | awk '{print $NF}')

nline=$(echo "($nbnd-1)/8+1"|bc)

grep -A "$((nline+1))" "$kequal" $file | sed "/$kequal/d" | awk '
/--/ {printf "\n"; next}
{printf}
' > energies.txt
