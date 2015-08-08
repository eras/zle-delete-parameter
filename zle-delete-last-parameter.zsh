# -*- mode: sh -*-

# Fails when there is a newline within the arguments

# Delete last parameter from the ZSH command line editor.
#
# Copyright (c) 2015 Erkki Seppälä
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# debug() {
#     echo "$@" >/dev/stderr
# }

# converts a string of parameters (ie: "a b c d\ 'e f'" has 4 parameters)
# to a list of the parameter begins, ends and contents
# output:
# begin1,end1,quotedcontents (unquote with (Q))
find-parameters() {
    local input=$1
    local -a fields
    #debug "input: $input"
    local idx
    local state=scanning
    local last_word=1
    function word_at() {
	local index="$1"
	fields[$(($#fields+1))]="$last_word $index ${(q)input[$last_word,$(($index-1))]}"
	last_word=$(($index + 1));
    }
    for idx in {1..$#input}; do
	#debug -n "'$input[$idx]' $state"
	case "$state,$input[$idx]" in
	    scanning,' ')
		word_at $idx
		;;
	    scanning,\')
		state=quote_single
		;;
	    quote_single,\')
		state=scanning
		;;
	    scanning,\\)
		state=quote_escape
                ;;
            quote_escape,*)
		state=scanning
		;;
	    scanning,\")
		state=quote_double
		;;
	    quote_double,\")
		state=scanning
		;;
	    quote_double,\\)
		state=quote_double_escape
                ;;
            quote_double_escape,*)
		state=quote_double
		;;
	esac
	#debug "-> $state"
    done
    word_at $(($#input+1))
    for idx in {1..$#fields}; do
    	echo "${fields[$idx]}"
    done
}

delete-last-parameter() {
    local input="$1"
    local -a begins
    local -a contents
    find-parameters "$input" |
	while read begin end str; do
	    begins[$(($#begins+1))]=$begin
	    contents[$(($#contents+1))]="${(Q)str}"
	    #debug begin="$begin" end="$end" str="$str"
	done

    # if the last word is empty, disregard it
    if [ -z "${contents[$#contents]}" ]; then
	begins=("${(@)begins[1,$#begins-1]}")
    fi

    # remove everything at and after the last parameter begins
    echo $input[1,$(($begins[$#begins]-1))]
}

test-delete-last-parameter() {
    echo $(delete-last-parameter "")_
    echo $(delete-last-parameter "he")_
    echo $(delete-last-parameter "he wo")_
    echo $(delete-last-parameter "he wo\ too")_
    echo $(delete-last-parameter "he 'wo\ too'")_
    echo $(delete-last-parameter "he 'wo\ too' \"lol\" ")_
    echo $(delete-last-parameter "he \"lo
l\" ")_
}

zle-delete-last-parameter() {
    BUFFER=$(delete-last-parameter $BUFFER)
}

zle -N delete-last-parameter zle-delete-last-parameter
bindkey '^[<' delete-last-parameter
