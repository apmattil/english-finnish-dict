#!/usr/bin/bash

# script to translate from fiwn-transls.tsv (http://www.ling.helsinki.fi/kieliteknologia/tutkimus/finnwordnet/download_files/fiwn_rels_fi-2.0.zip) to tab separated english \t finnish word format.
# e.g original format:
#    fi:n03899533	kinttupolku	en-3.0:n03899533	footpath	synonym
#    fi:n03899533    polku   en-3.0:n03899533        footpath        synonym
#  output format:
#    footpath        kinttupolku,polku
# output can then be used by tab2opf to generate opf file.

IN_FILE=$1
OUT_FILE=$2
TMP_FILE="${1}.tmp.txt"

if [ $# -lt 2 ]; then
    echo "provide input and output file as argument"
	exit 1
else
    echo "in file $IN_FILE"
fi

rm -f $TMP_FILE
rm -f $OUT_FILE


awk '
BEGIN{
  i = 0
  while(( getline line<"'"$IN_FILE"'") > 0 ) {
     n = split(line, A, "\t")
     #print "eka " n ":" A[1] "," A[2]
	 if (A[1] ~ /^fi\:+/) {
		n3 = split(A[2], fi, " ")
		if (fi[1] ~ /^[a-öA-Ö]/ && length(fi[1])>1) {
			# print "starts " A[1]
			if (A[3] ~ /en+/) {
				# print "en starts " A[3]
				n2 = split(A[4], eng, " ")
				#print "eng " n2 ":" eng[1]
				if (n2 > 1) {
					print "tupla englanti " line
				} else if (!(eng[1] ~ /^[a-zA-Z]/)) {
					print "non alpha englanti " line
				} else if (eng[1] == fi[1]) {
					print "same suomi englanti " line
				}
				else {
					++i
					kaannos[i][0] = A[2]
					kaannos[i][1] = A[4]
				}
			}
		}
		else {
			print "non alpha " n3 "-" fi[1] "; " line
		}
		delete A
		delete fi
		delete eng
	 }
	 # print line
  }
	for ( y in kaannos ) {
		print y ":" kaannos[y][1] "=" kaannos[y][0]
		print kaannos[y][1] "\t" kaannos[y][0] > "'"$TMP_FILE"'"
	}
	delete kaannos
}'
TMP_SORTED_FILE="${TMP_FILE}.sorted.txt"
rm -f ${TMP_SORTED_FILE}
echo "sort ${TMP_FILE} > ${TMP_SORTED_FILE}"
if [[ `sort -u ${TMP_FILE} > ${TMP_SORTED_FILE}` ]] ; then
	echo "sorting failed"
fi

awk '
BEGIN {
  i = 0
  while(( getline line<"'"$TMP_SORTED_FILE"'") > 0 ) {
		n = split(line, A, "\t")
		#print A[1] ":" A[2]
		++i
		kaannos[i][0] = A[1]
		kaannos[i][1] = A[2]
		#print kaannos[i][0] ":" kaannos[i][1]
	}
	
	z = 0
	for ( y = 1; y < i; ++y ) {
		++z
		new_kaannos[z][0] = kaannos[y][0]
		if ( y+1 <= i && kaannos[y][0] == kaannos[y+1][0] ) {
			#print "same " y ";" kaannos[y][0] "-" kaannos[y][1]
			for ( x = y; kaannos[x][0] == kaannos[x+1][0] ; ++x ) {
				#print "same " y ";" kaannos[y][0] "-" kaannos[y][1] ";" kaannos[y+1][0] "-" kaannos[y+1][1]
				#print "same " x ";" kaannos[x][0] "-" kaannos[x][1] ";" kaannos[x+1][1]
				if (new_kaannos[z][1] == "") {
					if (new_kaannos[z][0] == "copyright") {
						new_kaannos[z][1] = "Ari Mattila," kaannos[x][1]
					}
					else {
						new_kaannos[z][1] = kaannos[x][1]
					}
				}
				new_kaannos[z][1] = new_kaannos[z][1] "," kaannos[x+1][1]
				#print z ":" new_kaannos[z][0] "!" new_kaannos[z][1]
				++y
			}
		}
		else {
			new_kaannos[z][1] = kaannos[y][1]
		}
	}
	delete kaannos
	z = 0
	for ( a in new_kaannos) {
		++z
		print new_kaannos[z][0] "\t" new_kaannos[z][1] > "'"$OUT_FILE"'"
	}
}
'
