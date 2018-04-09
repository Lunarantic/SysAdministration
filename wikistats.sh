#!/bin/sh

help() {
	echo " -b           only print 'total bytes' stats"
	echo " -d <domain>  if not specified, default to 'en'"
	echo "             note: the special domain 'all' is also valid"
	echo " -f           only print 'most frequent' stats"
	echo " -h           print this help and exit"
	echo " -l           only print 'largest object' stats"
	echo " -r           only print 'requests per second' stats"
	echo " -u           only print 'unique objects' stats"
	exit 1
}

unique() {
	zgrep -c '^'$2 $1
}

frequent() {
	zgrep '^'$2 $1 | sort -nrk 3 | head -1 | cut -d' ' -f2
}

bytes() {
	zgrep '^'$2'[\. ]' $1 | cut -d' ' -f4 | awk '{sum += $1} END {print sum}'
}

reqpersec() {
	zgrep '^'$2 $1 | cut -d' ' -f3 | awk '{sum += $1} END {printf "%.2f\n", (sum/3600)}'
}

largest() {
	# copied awk code from professor's answer in mail; my method was not as this efficient
	zgrep '^'$2 $1 | awk '{s = $NF / $(NF - 1); if (s > l) { l = s; largest = $2; }} END { print largest; }'
}

flags=""
lang="en"
desc=""

while [ "$1" != "" ] ; do
	case $1 in
	"-h")	help ;;
	"-b")	flags=$flags" b" ;;
	"-f")	flags=$flags" f" ;;
    "-l")	flags=$flags" l" ;;
    "-r")	flags=$flags" r" ;;
    "-u")	flags=$flags" u" ;;
    "-d")	shift
		if [ "$1" = "all" ]; then
			lang=""
		else
			lang=$1
		fi ;;
	"-"*)	if [ ${#1} -le 2 ] ; then
			help
	    	fi
		    case $1 in
		        *h*) help
		    esac
		    case $1 in
		        *b*) flags=$flags" b"
		    esac
            case $1 in 
                *f*) flags=$flags" f"
            esac
            case $1 in 
                *l*) flags=$flags" l"
            esac
            case $1 in 
                *r*) flags=$flags" r"
            esac
            case $1 in 
                *u*) flags=$flags" u"
            esac
		case $1 in
		    *d*)	shift
			    if [ "$1" = "all" ]; then
				    lang=""
			    else
				    lang=$1
			    fi ;;
		    *b*)	;;
		    *f*)	;;
    		*l*)	;;
	    	*r*)	;;
		    *u*)	;;
		    *)	help
		esac
		desc="1" ;;
	*)
		filename=$1

		if [ "$flags" = "" ] ; then
			$flags="u f b r l"
			$desc="1"
		fi

		for f in $flags
		do
			case $f in
				*b*)	if [ "$desc" != "" ] ; then
						    echo -n "Total bytes transferred: "
				    	fi
				    	bytes $filename $lang ;;
				*f*)	if [ "$desc" != "" ] ; then
		    				echo -n "Most frequent object: "
			    		fi
		    			frequent $filename $lang ;;
				*l*)	if [ "$desc" != "" ] ; then
		    				echo -n "Largest object: "
		    			fi
		    			largest $filename $lang ;;
				*r*)	if [ "$desc" != "" ] ; then
		    				echo -n "Requests per second: "
		    			fi
		    			reqpersec $filename $lang ;;
				*u*)	if [ "$desc" != "" ] ; then
			    			echo -n "Unique objects: "
			    		fi
			    		unique $filename $lang ;;
				*)	help
			esac
		done
		exit
	esac
	shift
done

help
